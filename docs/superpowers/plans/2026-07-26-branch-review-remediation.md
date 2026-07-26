# 브랜치 리뷰 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `기타`를 제외한 브랜치 리뷰 지적 사항을 수정하고, released repeat 뒤 새 삭제 입력을 보존하며 중복·무효·오해 소지 테스트를 제거한다.

**Architecture:** repeat mutation도 `DeleteInteractionCoordinator` generation에 등록해 `DeleteMutationLifecycle`과 대기 상태를 일치시킨다. 테스트 정리는 각 테스트가 실제 production 분기 하나를 검증하도록 책임을 좁히고, 테스트 안에서 controller 순서를 재작성한 harness 검증은 제거한다.

**Tech Stack:** Swift 5, Swift Testing, UIKit, Xcode 16+, XcodeBuildMCP, iPhone 13 mini / iOS 16.0

## Global Constraints

- 현재 브랜치 `bug/#102-cursor-drag-newline-boundary`에서 작업한다.
- 리뷰의 `기타` 항목인 `.gitignore`, AGENTS, 계획 이력, Messages 수동 검증은 수정하지 않는다.
- 반복 입력 timer 간격, feedback 시점, Undo/Redo grouping 의미를 변경하지 않는다.
- Firebase, 광고, entitlement, bundle identifier를 변경하지 않는다.
- production 변경은 실패하는 회귀 테스트를 먼저 확인한 뒤 최소 구현한다.
- 각 Task는 focused 검증과 계획 체크박스 갱신을 포함한 독립 커밋으로 끝낸다.
- 최종 검증은 `SYKeyboard` 전체 테스트와 `HangeulKeyboard`, `EnglishKeyboard` build를 iPhone 13 mini / iOS 16.0에서 실행한다.

## 실행 기준선

- 2026-07-26, XcodeBuildMCP, `SYKeyboard`, iPhone 13 mini / iOS 16.0
- `-parallel-testing-enabled NO`
- 329 tests passed, failed 0, skipped 0
- 외부 Meta/FBAudienceNetwork `.pcm` 경로 경고가 있었으며 test failure는 없었다.

---

### Task 1: released repeat의 다음 delete touchDown 보존

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Test: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `DeleteInteractionCoordinator.currentGeneration`, `resolve(_:)`, `DeleteMutationLifecycle.beginRepeat`
- Produces: `DeleteInteractionCoordinator.beginRepeatMutation(inputIdentifier:) -> DeleteInteractionGeneration?`

- [x] **Step 1: 실패하는 회귀 테스트 작성**

`DeleteInteractionCoordinatorTests`에 production coordinator와 lifecycle을 함께 사용하는 테스트를 추가한다.

```swift
@Test("released repeat 확인 전 다음 touchDown은 late callback 뒤 한 번 replay")
func testReleasedRepeatQueuesNextTouchDownUntilLateCallback() throws {
    var coordinator = DeleteInteractionCoordinator()
    var lifecycle = DeleteMutationLifecycle()
    let nextButton = DeleteButton(keyboard: .dubeolsik)
    let before = KeyboardTextContextSnapshot(beforeInput: "가나", afterInput: "")
    let after = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")

    let pendingGeneration = coordinator.beginRepeatMutation(inputIdentifier: nil)
    let generation = try #require(pendingGeneration)
    #expect(lifecycle.beginRepeat(context: before, selectedText: nil) == .started)
    _ = lifecycle.capture(
        deletedText: "나",
        insertedText: "",
        reliability: .proxyContext
    )
    lifecycle.finishRepeatTracking()

    #expect(
        coordinator.beginTouchDown(button: nextButton, inputIdentifier: nil) == .enqueued
    )
    let outcome = lifecycle.completeAfterTextChange(
        currentContext: after,
        currentSelectedText: nil
    )
    guard case .resolved = outcome else {
        Issue.record("released repeat가 late callback에서 확정되지 않음")
        return
    }
    let didResolve = coordinator.resolve(generation)
    #expect(didResolve)
    guard case .touchDown(let replayed)? = coordinator.nextReadyEvent() else {
        Issue.record("보류된 다음 touchDown이 replay되지 않음")
        return
    }
    #expect(ObjectIdentifier(replayed as AnyObject) == ObjectIdentifier(nextButton))
    #expect(coordinator.nextReadyEvent() == nil)
}
```

- [x] **Step 2: RED 확인**

XcodeBuildMCP의 `SYKeyboard` scheme에서 다음 focused test를 실행한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: `beginRepeatMutation` 부재로 build/test 실패.

- [x] **Step 3: coordinator에 repeat generation 시작 구현**

`beginPanBoundaryMutation`의 공통 generation 시작 규칙을 private helper로 추출하고 repeat API에서도 사용한다.

```swift
mutating func beginRepeatMutation(
    inputIdentifier: ObjectIdentifier?
) -> DeleteInteractionGeneration? {
    return beginMutation(inputIdentifier: inputIdentifier)
}

mutating func beginPanBoundaryMutation(
    inputIdentifier: ObjectIdentifier?
) -> DeleteInteractionGeneration? {
    return beginMutation(inputIdentifier: inputIdentifier)
}

private mutating func beginMutation(
    inputIdentifier: ObjectIdentifier?
) -> DeleteInteractionGeneration? {
    // 기존 beginPanBoundaryMutation의 generation 생성·식별자·waiting 규칙
}
```

- [x] **Step 4: controller가 lifecycle보다 coordinator를 먼저 시작**

`beginRepeatDeleteRequest()`가 두 상태 머신을 함께 시작하고 불일치 시 함께 취소하도록 변경한다.

```swift
func beginRepeatDeleteRequest() -> DeleteMutationStartResult {
    guard deleteInteractionCoordinator.beginRepeatMutation(
        inputIdentifier: currentTextInputIdentifier
    ) != nil else {
        return .awaitingPreviousMutation
    }

    let result = deleteMutationLifecycle.beginRepeat(
        context: currentTextContextSnapshot(),
        selectedText: textDocumentProxy.selectedText
    )
    guard result == .started else {
        cancelPendingDeleteInteractions()
        return result
    }
    return .started
}
```

- [x] **Step 5: GREEN과 인접 lifecycle 검증**

Task 1 focused suite와 `DeleteMutationLifecycleTests`를 실행한다. Expected: 모두 통과.

- [x] **Step 6: 계획 결과 기록 및 커밋**

이 Task의 체크박스를 완료하고 실제 테스트 결과를 Task 아래에 기록한다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "fix: #102 - 반복 삭제 후 다음 삭제 입력 보존"
```

**실행 결과**

- RED: `beginRepeatMutation` 부재로 예상한 compile failure를 확인했다.
- 첫 GREEN 시도: Swift Testing macro 내부 mutating 호출 제한으로 compile failure가 발생해 호출
  결과를 지역 변수로 분리했다.
- 최종 GREEN: `DeleteInteractionCoordinatorTests`와 `DeleteMutationLifecycleTests` 41개 통과,
  실패·skip 0.

### Task 2: request와 callback 완전 중복 테스트 통합

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `RepeatDeleteRequest`
- Produces: 중복 없이 일반 문자, 동일 문맥 줄바꿈, 권위 치환을 각각 한 번 검증하는 policy suite

- [x] **Step 1: 삭제 전 policy suite 기준선 확인**

`KeyboardTextInteractionPolicyTests`를 focused 실행한다. Expected: 통과.

- [x] **Step 2: 중복 함수 제거와 assertion 병합**

다음 함수는 더 이른 동일 시나리오 테스트로 assertion을 병합한 뒤 제거한다.

```swift
// Remove:
test삭제Mutation_Pending요청_Callback확정()
test반복삭제_동일문맥Callback_줄바꿈확정()
test반복삭제_권위치환_예상문맥일치()
```

`test반복삭제_일반문자Callback_후보확정()`에는 callback 전 `request.isPending`과 callback 후
`request.isPending == false` assertion을 남긴다.

- [x] **Step 3: focused GREEN 확인**

`KeyboardTextInteractionPolicyTests`를 다시 실행한다. Expected: 제거된 3개를 제외한 suite 통과.

- [x] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - 삭제 요청 중복 검증 통합"
```

**실행 결과**

- 정리 전 `KeyboardTextInteractionPolicyTests` 29개 통과.
- 일반 문자 callback 테스트에 pending 전·후 assertion을 병합하고 동일 시나리오 3개를 제거했다.
- 정리 후 26개 통과, 실패·skip 0.

### Task 3: coordinator cancellation 중복 테스트 통합

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `DeleteInteractionCoordinator.cancel()`
- Produces: queue 폐기와 pan cleanup 단일 소유권을 직접 검증하는 한 테스트

- [x] **Step 1: 유지할 direct coordinator 테스트 확인**

`testCancelClearsQueueAndFinishesPanOnce()`가 첫 cancel은 `true`, 두 번째 cancel은 `false`,
`nextReadyEvent()`는 nil임을 확인하는지 읽고 focused suite를 실행한다.

- [x] **Step 2: harness 중복 테스트 제거**

```swift
// Remove:
testCancelledGenerationFinishesPanExactlyOnce()
```

- [x] **Step 3: focused GREEN 확인**

`DeleteInteractionCoordinatorTests`를 실행한다. Expected: 통과.

- [x] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - coordinator 취소 중복 검증 통합"
```

**실행 결과**

- 정리 전 `DeleteInteractionCoordinatorTests` 19개 통과.
- 두 번 취소와 pan cleanup 단일 소유권은 direct coordinator 테스트로 유지했다.
- harness 중복 1개 제거 후 18개 통과, 실패·skip 0.

### Task 4: Undo/Redo manager의 중복·무효 반복 삭제 테스트 제거

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `KeyboardUndoRedoManager`
- Produces: manager 자체 grouping과 edit 변환만 검증하는 suite

- [x] **Step 1: manager suite 기준선 확인**

`KeyboardUndoRedoManagerTests`를 focused 실행한다. Expected: 통과.

- [x] **Step 2: 다른 lifecycle 통합 검증과 겹치는 함수 제거**

```swift
// Remove:
test반복삭제_커서드래그후전체삭제_원문복원()
test반복삭제_문서시작무효요청_Undo없음()
```

첫 함수의 삭제 순서·grouped Undo는
`DeleteMutationLifecycleTests.testTouchDownProxy후보불일치_전체반복삭제_UndoRedo()`가 실제
lifecycle resolution을 통해 검증한다. 두 번째 함수의 no-op은
`testReleasedRepeatNoDeletionDoesNotRecordFeedbackOrUndo()`가 lifecycle resolution을 manager
기록 경계까지 전달해 검증한다.

- [x] **Step 3: focused GREEN 확인**

`KeyboardUndoRedoManagerTests`와 `DeleteMutationLifecycleTests`를 실행한다. Expected: 모두 통과.

- [x] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - 반복 삭제 manager 중복 검증 제거"
```

**실행 결과**

- 정리 전 `KeyboardUndoRedoManagerTests` 22개 통과.
- hard-coded 전체 삭제 배열 검증과 lifecycle 결과를 manager에 전달하지 않는 no-op 검증을 제거했다.
- 정리 후 manager 20개와 `DeleteMutationLifecycleTests` 22개, 총 42개 통과, 실패·skip 0.

### Task 5: Hangeul suite에 잘못 배치된 request 테스트 정리

**Files:**
- Modify: `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `HangeulCompositionState.repeatDelete(using:)`
- Produces: Hangeul state 결과만 검증하는 빈 상태 테스트

- [x] **Step 1: Hangeul suite 기준선 확인**

`HangeulCompositionStateTests`를 focused 실행한다. Expected: 통과.

- [x] **Step 2: 빈 state 테스트를 state 책임으로 축소**

기존 `test빈조합상태_경계반복삭제_줄바꿈Undo전달()`을 다음 의미로 변경한다.

```swift
@Test("빈 한글 조합 상태의 반복 삭제는 proxy delete만 요청")
func test빈조합상태_반복삭제() {
    var state = HangeulCompositionState()
    let processor = DubeolsikProcessor(automata: HangeulAutomata())

    let delete = state.repeatDelete(using: processor)

    #expect(delete.proxyEdit == .delete(count: 1))
    #expect(state.committedBuffer.isEmpty)
    #expect(state.composingBuffer.isEmpty)
}
```

- [x] **Step 3: Hangeul state를 사용하지 않는 권위 치환 테스트 제거**

```swift
// Remove:
test한글반복삭제_치환Mutation_Callback확인()
```

동일 `"한" → "하"` 요청은 policy suite의
`test반복삭제_권위있는조합치환_원형유지()`가 유지한다.

- [x] **Step 4: focused GREEN 확인**

`HangeulCompositionStateTests`와 `KeyboardTextInteractionPolicyTests`를 실행한다. Expected: 통과.

- [x] **Step 5: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Domain/HangeulCompositionStateTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - 한글 상태와 삭제 요청 검증 분리"
```

**실행 결과**

- 정리 전 `HangeulCompositionStateTests` 9개 통과.
- 빈 state 테스트는 실제 `proxyEdit`과 state buffer만 검증하도록 축소하고, Hangeul state를 사용하지
  않는 권위 치환 request 테스트 및 불필요한 `SYKeyboardCore` import를 제거했다.
- 정리 후 Hangeul state 8개와 policy 26개, 총 34개 통과, 실패·skip 0.

### Task 6: 이름만 다른 non-delete harness 테스트 정리

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `DeleteInteractionNonDeleteMutationBoundary.cancel`
- Produces: 공통 cancellation boundary의 lifecycle·coordinator 결과를 직접 검증하는 한 테스트

- [x] **Step 1: 공통 boundary assertion 강화**

`testNonDeleteBoundaryDoesNotReplayQueuedPan()`을 harness 전용 이름 대신 production boundary 계약으로
이름을 바꾸고 다음 결과를 직접 확인한다.

```swift
#expect(harness.lifecycle.isPending == false)
#expect(harness.coordinator.currentGeneration == nil)
#expect(harness.observedEvents.isEmpty)
#expect(harness.panFinishCount == 1)
```

helper는 `DeleteInteractionNonDeleteMutationBoundary.cancel`을 호출하는 하나만 남긴다.

- [x] **Step 2: 같은 helper와 독립 manager를 결합한 테스트 제거**

```swift
// Remove:
testSuggestionDirectEditBoundaryPreservesOwnUndo()
testUndoRedoDirectEditBoundaryPreservesHistory()
testViewStopDoesNotReplayQueuedPan()
```

사용하지 않게 된 `cancelForNonDeleteBoundary`, `cancelForViewStop` helper를 제거한다.

- [x] **Step 3: focused GREEN 확인**

`DeleteInteractionCoordinatorTests`와 `KeyboardUndoRedoManagerTests`를 실행한다. Expected: 통과.

- [x] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - non-delete 경계 검증 단일화"
```

**실행 결과**

- 공통 production cancellation boundary 테스트에 lifecycle pending 해제와 coordinator generation 폐기
  assertion을 추가했다.
- 같은 helper에 suggestion·Undo/Redo manager를 독립적으로 결합한 2개와 view stop 별칭 1개,
  사용하지 않는 helper 2개를 제거했다.
- coordinator 15개와 manager 20개, 총 35개 통과, 실패·skip 0.

### Task 7: production을 재작성한 harness 검증 제거

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: direct coordinator FIFO·reentry tests
- Produces: production보다 테스트 구현을 검증하는 hook·순서 assertion이 없는 coordinator suite

- [x] **Step 1: direct production 정책 검증의 대체 범위 확인**

다음 direct coordinator 테스트가 각각 FIFO와 재진입 gate를 검증하는지 확인한다.

```swift
testFIFOOrder()
testReplayTouchDownBlocksSynchronousReentry()
```

- [x] **Step 2: 수동 순서 재작성 테스트 제거**

```swift
// Remove:
testConfirmedNewlineIsBufferedBeforeRightReplay()
testDeferredTouchDownRunsWillBodyDidHooksInOrder()
testSynchronousCallbackDoesNotOvertakeFIFO()
```

사용하지 않게 된 harness의 `hookTrace`, `restoredCharacters`를 제거한다.

- [x] **Step 3: focused GREEN 확인**

`DeleteInteractionCoordinatorTests`를 실행한다. Expected: 통과.

- [x] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - 수동 controller 순서 검증 제거"
```

**실행 결과**

- FIFO 순서는 `testFIFOOrder()`, replay gate는
  `testReplayTouchDownBlocksSynchronousReentry()`의 production coordinator 호출로 유지했다.
- controller의 줄바꿈 buffer·semantic hook·재진입 순서를 harness에서 직접 재작성한 3개와 사용하지
  않는 trace 상태 2개를 제거했다.
- `DeleteInteractionCoordinatorTests` 12개 통과, 실패·skip 0.

### Task 8: tautological repeat tick 테스트 제거

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: `RepeatDeleteRequest.actionForNextTick`
- Produces: 실제 action state를 직접 비교하는 기존 테스트만 유지

- [ ] **Step 1: 대체 테스트 확인**

다음 기존 테스트가 idle, confirmed, unconfirmed tick의 실제 enum 결과를 직접 비교하는지 확인한다.

```swift
test반복삭제_다음Tick_새삭제준비()
test반복삭제_다음Tick_이전확정후새삭제준비()
test반복삭제_다음Tick_확인실패시종료()
```

- [ ] **Step 2: 로컬 0/1 매핑으로 자기 자신을 검증하는 함수 제거**

```swift
// Remove:
testRepeatTickExactSingleDeleteContract()
```

- [ ] **Step 3: focused GREEN 확인**

`DeleteMutationLifecycleTests`와 `KeyboardTextInteractionPolicyTests`를 실행한다. Expected: 통과.

- [ ] **Step 4: 계획 결과 기록 및 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "test: #102 - 반복 tick 자기검증 테스트 제거"
```

### Task 9: 전체 회귀 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-26-branch-review-remediation.md`

**Interfaces:**
- Consumes: Tasks 1-8의 production·test 변경
- Produces: 실제 test/build 결과가 기록된 완료 계획

- [ ] **Step 1: diff와 작업 범위 확인**

```sh
git status --short
git diff --check HEAD~8..HEAD
git diff --stat 52e47130..HEAD
```

Expected: 계획된 production, test, docs 파일만 변경되고 whitespace 오류 없음.

- [ ] **Step 2: 전체 test 실행**

XcodeBuildMCP에서 `SYKeyboard` scheme, iPhone 13 mini / iOS 16.0,
`-parallel-testing-enabled NO`로 전체 테스트를 실행한다. Expected: 실패·skip 0.

- [ ] **Step 3: HangeulKeyboard build**

XcodeBuildMCP default scheme을 `HangeulKeyboard`로 바꾸고 simulator build를 실행한다.
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: EnglishKeyboard build**

XcodeBuildMCP default scheme을 `EnglishKeyboard`로 바꾸고 simulator build를 실행한다.
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: 계획에 실제 결과 기록 및 검증 커밋**

실제 테스트 수, build 결과, 외부 dependency 경고를 이 Task 아래에 기록하고 체크박스를 완료한다.

```sh
git add docs/superpowers/plans/2026-07-26-branch-review-remediation.md
git commit -m "docs: #102 - 브랜치 리뷰 수정 검증 결과 기록"
```
