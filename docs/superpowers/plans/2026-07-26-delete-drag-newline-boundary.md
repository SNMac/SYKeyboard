# 삭제 드래그 줄바꿈 경계 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Messages에서 삭제 버튼 왼쪽 드래그가 줄바꿈을 임시 삭제하고 오른쪽 드래그가 정확히 복구하며, 문서 시작의 반복 삭제는 손을 뗄 때까지 버튼의 눌린 UI를 유지한다.

**Architecture:** `RepeatDeleteRequest`와 `DeleteMutationLifecycle`에 pan boundary origin과 `newline` 기대값을 추가해 실제 callback/checkpoint 뒤에만 줄바꿈 mutation을 확정한다. `DeleteInteractionCoordinator`는 확인 대기 중 pan과 pan stop을 기존 generation FIFO에 보존하고, `BaseKeyboardViewController`는 확인된 줄바꿈을 FIFO drain 전에 임시 복구 버퍼에 넣는다.

**Tech Stack:** Swift 5, UIKit `UIInputViewController`/`UITextDocumentProxy`, Swift Testing, `xcodebuild`

## Global Constraints

- 지원 범위는 iOS 16+다.
- 반복 삭제 timer 간격 `max(0.01, 0.10 - repeatRate)`은 변경하지 않는다.
- 일반 문자와 한글 조합 문자의 기존 동기 delete drag 경로를 유지한다.
- 줄바꿈은 callback 또는 관찰 가능한 checkpoint로 확인된 경우에만 Undo와 임시 복구 버퍼에 기록한다.
- 문서 시작의 무효 delete drag는 mutation, 복구 문자, 사운드, 햅틱 또는 보충 삭제를 만들지 않는다.
- 확인 대기 중 touchDown, pan 방향, pan stop의 도착 순서를 유지한다.
- 반복 삭제가 문서 시작에 도달하면 timer와 추가 피드백만 중단하고 실제 gesture 종료 전 버튼 UI를 강제로 해제하지 않는다.
- `selectionWillChange(_:)`/`selectionDidChange(_:)`에 의존하지 않는다.
- Firebase, 광고, entitlement, bundle identifier 및 provisioning 설정을 변경하지 않는다.
- 사용자 소유 `.gitignore` 변경은 모든 Step과 commit에서 제외한다.
- 각 Step은 실제 변경과 해당 검증을 끝낸 직후 문서 Result를 갱신하고 별도 커밋한다.
- Messages 실제 입력 화면과 물리 사운드·햅틱은 자동 검증으로 통과 처리하지 않는다.

---

## 사전 확인

- 기준 branch: `bug/#102-cursor-drag-newline-boundary`
- 승인 설계: `docs/superpowers/specs/2026-07-26-delete-drag-newline-boundary-design.md`
- 기존 coordinator 설계: `docs/superpowers/specs/2026-07-25-delete-interaction-coordinator-design.md`
- 기존 coordinator 계획: `docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md`
- 구현 시작 기준 commit: 이 계획 문서 commit

Run:

```sh
git status --short
git log --oneline -5
```

Expected: 사용자 소유 `.gitignore` 외에 미커밋 변경이 없고 HEAD가 이 계획 문서 commit을 가리킨다.

---

### Task 1: Pan boundary lifecycle과 generation FIFO

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md`

**Interfaces:**
- Produces: `RepeatDeleteBoundaryExpectation.newline`
- Produces: `DeleteMutationOrigin.panBoundary`
- Changes: `RepeatDeleteRequest.begin(context:selectedText:boundaryExpectation:)` with default `nil`
- Produces: `DeleteMutationLifecycle.beginPanBoundary(context:selectedText:)`
- Produces: `DeleteMutationLifecycle.finishPanBoundary(currentContext:currentSelectedText:)`
- Produces: `DeleteInteractionCoordinator.beginPanBoundaryMutation(inputIdentifier:)`
- Changes: `DeleteInteractionCoordinator.resolve(_:discardingLeadingNoOpPanLeft:)`

- [x] **Step 1: Pan boundary lifecycle와 FIFO 실패 테스트 작성 및 커밋**

`KeyboardTextInteractionPolicyTests.swift`에 다음 회귀를 추가한다. 기대값은 production helper로 계산하지
않고 literal `"\n"`과 event 순서로 검증한다.

```swift
@Test("pan boundary 동일 문맥 callback은 줄바꿈 mutation을 확정")
func testPanBoundarySameContextCallbackConfirmsNewline() {
    var lifecycle = DeleteMutationLifecycle()
    let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "라마바")

    #expect(
        lifecycle.beginPanBoundary(
            context: context,
            selectedText: nil
        ) == .started
    )
    #expect(
        lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        ) == .awaitingTextChange
    )

    #expect(
        lifecycle.completeAfterTextChange(
            currentContext: context,
            currentSelectedText: nil
        ) == .resolved(
            DeleteMutationResolution(
                completion: .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: "\n",
                        insertedText: "",
                        reliability: .authoritative
                    )
                ]),
                origin: .panBoundary,
                shouldPlayFeedback: true
            )
        )
    )
}

@Test("pan boundary 빈 문맥에서 직전 줄이 나타나면 줄바꿈 mutation을 확정")
func testPanBoundaryPreviousLineContextConfirmsNewline() {
    var lifecycle = DeleteMutationLifecycle()
    let requestContext = KeyboardTextContextSnapshot(beforeInput: nil, afterInput: "라마바")
    _ = lifecycle.beginPanBoundary(context: requestContext, selectedText: nil)
    _ = lifecycle.capture(
        deletedText: "",
        insertedText: "",
        reliability: .proxyContext
    )

    #expect(
        lifecycle.finishPanBoundary(
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "가나다",
                afterInput: "라마바"
            ),
            currentSelectedText: nil
        ) == DeleteMutationResolution(
            completion: .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "\n",
                    insertedText: "",
                    reliability: .authoritative
                )
            ]),
            origin: .panBoundary,
            shouldPlayFeedback: true
        )
    )
}

@Test("released pan boundary 동일 checkpoint는 noDeletion")
func testReleasedPanBoundarySameCheckpointIsNoDeletion() {
    var lifecycle = DeleteMutationLifecycle()
    let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "가나다")
    _ = lifecycle.beginPanBoundary(context: context, selectedText: nil)
    _ = lifecycle.capture(
        deletedText: "",
        insertedText: "",
        reliability: .proxyContext
    )

    #expect(
        lifecycle.finishPanBoundary(
            currentContext: context,
            currentSelectedText: nil
        ) == DeleteMutationResolution(
            completion: .noDeletion,
            origin: .panBoundary,
            shouldPlayFeedback: false
        )
    )
}

@Test("pan boundary 확인 전 이벤트는 FIFO이고 noDeletion은 앞쪽 left만 폐기")
func testPanBoundaryFIFOAndNoOpLeftDiscard() throws {
    var coordinator = DeleteInteractionCoordinator()

    #expect(coordinator.enqueuePan(.left) == .performNow)
    let generation = try #require(
        coordinator.beginPanBoundaryMutation(inputIdentifier: nil)
    )
    #expect(coordinator.isWaitingForResolution)
    #expect(coordinator.enqueuePan(.left) == .enqueued)
    #expect(coordinator.enqueuePan(.left) == .enqueued)
    #expect(coordinator.enqueuePan(.right) == .enqueued)
    #expect(coordinator.enqueuePan(.left) == .enqueued)
    #expect(coordinator.enqueuePanStop() == .enqueued)

    #expect(
        coordinator.resolve(
            generation,
            discardingLeadingNoOpPanLeft: true
        )
    )
    guard case .pan(.right)? = coordinator.nextReadyEvent() else {
        Issue.record("선행 no-op left 뒤 right가 먼저 재생되지 않음")
        return
    }
    guard case .pan(.left)? = coordinator.nextReadyEvent() else {
        Issue.record("right 뒤의 유효 left가 보존되지 않음")
        return
    }
    guard case .panStop? = coordinator.nextReadyEvent() else {
        Issue.record("pan stop 순서가 보존되지 않음")
        return
    }
}
```

기존 `DeleteMutationResolution` literal에는 실제 요청 종류에 맞춰
`origin: .touchDown` 또는 `origin: .repeatTick`을 명시한다. 아직 production 타입과 signature가 없으므로
compile RED가 예상된다.

Verification:

```sh
git diff --check
```

Commit:

```sh
git add SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "test: #102 - 삭제 드래그 줄바꿈 경계 회귀"
```

Result: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`에 pan boundary callback/checkpoint 및 FIFO 회귀 4개와 기존 resolution origin 기대값을 추가했다. `git diff --check`는 exit 0으로 통과했다. 변경 범위는 테스트와 이 계획 문서이며 사용자 소유 `.gitignore`는 제외했다.

- [x] **Step 2: Pan boundary 집중 테스트 RED 확인 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: `beginPanBoundary`, `DeleteMutationOrigin.panBoundary`,
`beginPanBoundaryMutation` 또는 새 `resolve` 인자가 없어 compile failure. 대표 오류와 exit code를
Result에 기록한다. sandbox/CoreSimulator/cache 오류면 같은 명령을 권한 있는 환경에서 재실행해 코드
RED와 환경 실패를 구분한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "docs: #102 - 삭제 드래그 줄바꿈 lifecycle RED 검증"
```

Result: iPhone 13 mini / iOS 16.0 destination으로 실행했다. 기본 sandbox 재실행은 CoreSimulatorService 및 ModuleCache 권한 오류(exit 74)였고, 권한 있는 동일 명령은 코드 RED(exit 65)로 `DeleteMutationLifecycle.beginPanBoundary`/`finishPanBoundary`, `DeleteInteractionCoordinator.beginPanBoundaryMutation`, `DeleteMutationResolution.origin`, `resolve(_:discardingLeadingNoOpPanLeft:)` 부재를 확인했다.

- [x] **Step 3: Pan boundary lifecycle와 coordinator 최소 구현 및 커밋**

`KeyboardTextInteractionPolicy.swift`에 다음 origin과 기대값을 추가한다.

```swift
enum RepeatDeleteBoundaryExpectation: Equatable {
    case newline
}

enum DeleteMutationOrigin: Equatable {
    case touchDown
    case repeatTick
    case panBoundary
}

struct DeleteMutationResolution: Equatable {
    let completion: RepeatDeleteCompletion
    let origin: DeleteMutationOrigin
    let shouldPlayFeedback: Bool
}
```

`RepeatDeleteRequest.begin`은 기존 호출을 유지하는 다음 signature로 바꾸고, expectation을 요청과 함께
저장한 뒤 `consume()`에서 해제한다.

```swift
mutating func begin(
    context: KeyboardTextContextSnapshot,
    selectedText: String?,
    boundaryExpectation: RepeatDeleteBoundaryExpectation? = nil
)
```

`confirmedDrafts`의 일반 candidate 판정이 실패한 뒤 다음 규칙을 적용한다.

```swift
if boundaryExpectation == .newline {
    let isSameLineCallback = source == .textDidChange && currentBefore == before
    let isEmptyToPreviousLine = before.isEmpty && !currentBefore.isEmpty
    guard isSameLineCallback || isEmptyToPreviousLine else { return [] }

    return [
        RepeatDeleteMutationDraft(
            deletedText: "\n",
            insertedText: "",
            reliability: .authoritative
        )
    ]
}
```

`DeleteMutationLifecycle.RequestKind`에 `.panBoundary`와 `.releasedPanBoundary`를 추가한다.
`finishPanBoundary`가 mutation이나 `.noDeletion`을 확정하지 못하면 released로 전환해 늦은 callback을
기다린다. `isReleasedRequest`와 callback cancellation 규칙에 이 case를 포함한다. `resolve`는 request
kind를 origin으로 매핑하고 pan boundary mutation에만 `shouldPlayFeedback == true`를 반환한다.

```swift
mutating func beginPanBoundary(
    context: KeyboardTextContextSnapshot,
    selectedText: String?
) -> DeleteMutationStartResult

mutating func finishPanBoundary(
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> DeleteMutationResolution?
```

`finishPanBoundary`는 pan boundary 요청에만 동작한다. 먼저 `completeAtCheckpoint`를 시도하고, mutation이
없으면 `completeWithoutDeletionIfProven`을 시도해 `.noDeletion`을 반환한다.

Coordinator는 live 또는 replay pan이 boundary delete를 시작할 때 현재 generation을 waiting으로 만든다.

```swift
mutating func beginPanBoundaryMutation(
    inputIdentifier: ObjectIdentifier?
) -> DeleteInteractionGeneration?

mutating func resolve(
    _ generation: DeleteInteractionGeneration,
    discardingLeadingNoOpPanLeft: Bool = false
) -> Bool
```

새 generation이 필요하면 증가 ID와 input identifier를 만들고, 기존 ready generation이면 같은 ID를
유지한다. 이미 waiting이거나 기존 non-nil owner와 새 non-nil identifier가 다르면 `nil`을 반환한다.
`discardingLeadingNoOpPanLeft`가 true이면 FIFO의 맨 앞에 연속된 `.pan(.left)`만 제거한 뒤 ready로
전환한다.

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: 관련 suite 전체 통과, 실패·skip 0개. parallel hang이면 해당 PID만 종료한 뒤
`-parallel-testing-enabled NO`를 추가해 재실행하고 두 결과를 기록한다.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "fix: #102 - 삭제 드래그 줄바꿈 lifecycle"
```

Result: `RepeatDeleteBoundaryExpectation.newline`, pan boundary/released lifecycle, origin mapping, feedback policy 및 generation FIFO 선행 left 폐기를 구현했다. `#require`/`#expect` macro 안의 mutating coordinator 호출은 Swift compile 오류가 되어 local 변수로 분리했다. 권한 있는 `xcodebuild -quiet test` 집중 실행은 iPhone 13 mini / iOS 16.0에서 총 36개 통과, 실패 0, skip 0이었다.

---

### Task 2: Controller 임시 복구와 문서 시작 UI

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md`

**Interfaces:**
- Consumes: Task 1의 `DeleteMutationOrigin.panBoundary`
- Consumes: Task 1의 `beginPanBoundary`/`finishPanBoundary`
- Consumes: Task 1의 coordinator waiting/resolve API
- Produces: `KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(hasText:documentContextBeforeInput:)`
- Produces: `KeyboardTextInteractionPolicy.temporaryDeletedCharactersForConfirmedPanBoundary(_:)`
- Changes: `BaseKeyboardViewController.performDeleteButtonPanDeleteIfPossible()`
- Changes: `BaseKeyboardViewController.finishRepeatDeleteWithoutDeletion()`

- [x] **Step 1: Controller 경계 정책과 gesture 종료 회귀 테스트 작성 및 커밋**

`KeyboardTextInteractionPolicyTests.swift`에 다음 정책 및 통합 회귀를 추가한다.

```swift
@Test("앞 문맥이 비고 문서에 텍스트가 남으면 pan boundary 요청")
func testDeletePanBoundaryRequestPolicy() {
    #expect(
        KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
            hasText: true,
            documentContextBeforeInput: nil
        )
    )
    #expect(
        KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
            hasText: true,
            documentContextBeforeInput: ""
        )
    )
    #expect(
        KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
            hasText: false,
            documentContextBeforeInput: ""
        ) == false
    )
    #expect(
        KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
            hasText: true,
            documentContextBeforeInput: "가"
        ) == false
    )
}

@Test("확인된 pan boundary 줄바꿈만 임시 복구 문자로 반환")
func testConfirmedPanBoundaryRestoreCharacters() {
    let newlineResolution = DeleteMutationResolution(
        completion: .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ]),
        origin: .panBoundary,
        shouldPlayFeedback: true
    )
    let noDeletionResolution = DeleteMutationResolution(
        completion: .noDeletion,
        origin: .panBoundary,
        shouldPlayFeedback: false
    )

    #expect(
        KeyboardTextInteractionPolicy
            .temporaryDeletedCharactersForConfirmedPanBoundary(newlineResolution)
        == ["\n"]
    )
    #expect(
        KeyboardTextInteractionPolicy
            .temporaryDeletedCharactersForConfirmedPanBoundary(noDeletionResolution)
        .isEmpty
    )
}

@Test("확인된 줄바꿈을 FIFO right 전에 복구 버퍼에 저장")
func testConfirmedNewlineIsBufferedBeforeRightReplay() {
    var harness = DeleteInteractionIntegrationHarness()
    let requestContext = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "라마바")

    #expect(harness.beginPanBoundary(context: requestContext))
    #expect(harness.enqueuePan(.right) == .enqueued)
    #expect(harness.enqueuePanStop() == .enqueued)

    let outcome = harness.completeAfterTextChange(
        context: KeyboardTextContextSnapshot(
            beforeInput: "가나다",
            afterInput: "라마바"
        )
    )
    harness.process(outcome)
    harness.drain { harness, event in
        switch event {
        case .pan(.right):
            guard let restored = harness.temporaryDeletedCharacters.popLast() else {
                Issue.record("right replay 전에 줄바꿈 복구 문자가 저장되지 않음")
                return
            }
            harness.restoredCharacters.append(restored)
        case .panStop:
            harness.panFinishCount += 1
        default:
            Issue.record("예상하지 않은 replay event")
        }
    }

    #expect(harness.restoredCharacters == ["\n"])
    #expect(harness.panFinishCount == 1)
}
```

`DeleteInteractionIntegrationHarness.process(_:)`는 production policy가 반환한 confirmed pan boundary
문자를 coordinator resolve 전에 `temporaryDeletedCharacters`에 추가하도록 확장한다.

`TextInteractionGestureControllerTests.swift`에는 long press begin부터 실제 end 전까지 `DeleteButton`의
`isGesturing == true`이고 `.ended` 처리 뒤 false가 되는 기존 gesture 소유권 회귀를 추가한다. 이 테스트는
문서 시작 종료 코드가 버튼을 조기에 변경하지 않아야 하는 controller 계약의 반대편 경계를 고정한다.

아직 새 policy API가 없으므로 집중 suite는 compile RED가 예상된다.

Verification:

```sh
git diff --check
```

Commit:

```sh
git add SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift \
  docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "test: #102 - 삭제 드래그 줄바꿈 복구와 버튼 UI 회귀"
```

Result: `KeyboardTextInteractionPolicyTests`에 policy 2개와 coordinator 통합 1개, `TextInteractionGestureControllerTests`에 gesture 소유권 1개를 추가했다. 두 파일의 `@Test`는 각각 66개와 9개이며, `git diff --check` 결과는 exit 0이다.

- [x] **Step 2: Controller 통합 집중 테스트 RED 확인 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests \
  -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests
```

Expected: `shouldRequestDeletePanBoundary` 또는
`temporaryDeletedCharactersForConfirmedPanBoundary` 부재로 compile failure. 대표 오류와 exit code를
Result에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "docs: #102 - 삭제 드래그 controller 통합 RED 검증"
```

Result: iPhone 13 mini / iOS 16.0 destination에서 집중 suite를 실행해 코드 RED(exit 65)를 확인했다. 대표 실패는 `KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary` 및 `temporaryDeletedCharactersForConfirmedPanBoundary` 부재다. 테스트 scaffolding은 Swift Testing mutating macro 제한과 실제 `deleteText()`의 empty draft capture 순서를 반영해 Step 1 커밋에 포함했다.

- [x] **Step 3: Controller 줄바꿈 요청·복구와 버튼 UI 최소 구현 및 커밋**

`KeyboardTextInteractionPolicy`에 두 pure policy를 구현한다.

```swift
static func shouldRequestDeletePanBoundary(
    hasText: Bool,
    documentContextBeforeInput: String?
) -> Bool {
    return hasText && normalized(documentContextBeforeInput).isEmpty
}

static func temporaryDeletedCharactersForConfirmedPanBoundary(
    _ resolution: DeleteMutationResolution
) -> [Character] {
    guard resolution.origin == .panBoundary,
          case .mutations(let drafts) = resolution.completion
    else { return [] }

    return drafts.flatMap { $0.deletedText.reversed() }
}
```

실제 구현에서는 file-private normalization helper를 사용하거나 같은 의미를 직접 표현해도 되지만,
`nil`과 `""`은 동일하게 처리한다.

`BaseKeyboardViewController`는 기존 `deleteButtonPanDeleteText`가 문자를 반환하면 현재 동기 경로를
그대로 실행한다. nil이면 policy를 확인하고 다음 순서로 경계 삭제를 시작한다.

1. `deleteInteractionCoordinator.beginPanBoundaryMutation(inputIdentifier:)`
2. `deleteMutationLifecycle.beginPanBoundary(context:selectedText:)`
3. `deleteText()` 정확히 한 번

세 상태 준비가 끝난 뒤에만 proxy를 변경해 동기 callback 재진입에서도 coordinator와 lifecycle이
waiting 상태가 되게 한다. 시작 실패 시 두 상태를 함께 취소하고 proxy를 변경하지 않는다.

`processDeleteMutationResolution(_:)`은 confirmed pan boundary 문자를 `tempDeletedCharacters`에 먼저
추가한 뒤 Undo 기록, feedback, coordinator resolve와 drain을 실행한다. `.panBoundary/.noDeletion`이면
`discardingLeadingNoOpPanLeft: true`, 나머지는 false로 resolve한다.

`deleteButtonPanStopped(_:)`가 waiting generation에 stop을 enqueue한 경우
`deleteMutationLifecycle.finishPanBoundary(...)` checkpoint를 실행하고 resolution이 있으면 같은
processing 경로로 전달한다.

`finishRepeatDeleteWithoutDeletion(for:)`에서 `button.isGesturing = false`를 제거하고 parameter가
불필요해지면 `finishRepeatDeleteWithoutDeletion()`로 바꾼다. timer와 repeat lifecycle 정리는
유지하며 pressed button 또는 gesture controller를 강제로 release하지 않는다.

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests \
  -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

Expected: 관련 suite 전체 통과, 실패·skip 0개.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "fix: #102 - 삭제 드래그 줄바꿈 임시 복구"
```

Result: 문서 시작 pan boundary 요청, confirmed 줄바꿈 선행 복구 버퍼 저장, noDeletion 선행 left 폐기, pan stop checkpoint와 gesture controller의 버튼 UI 소유권 유지를 구현했다. 기본 sandbox 실행은 CoreSimulatorService·SwiftPM cache 권한 오류(exit 74)였고, 권한 있는 직렬 집중 GREEN은 iPhone 13 mini / iOS 16.0에서 총 86개 통과, 실패 0, skip 0이었다.

---

### Task 3: 전체 회귀, extension 빌드와 수동 검증 상태

**Files:**
- Modify: `docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md`
- Modify: `docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md`

**Interfaces:**
- Consumes: Task 1과 Task 2의 최종 production/test 상태
- Produces: fresh 전체 테스트와 양쪽 extension build 증거
- Produces: 수정된 Messages 수동 검증 계약

- [x] **Step 1: Fresh 전체 테스트 실행, 결과 기록 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 테스트 통과, 실패·skip 0개. sandbox/CoreSimulator/cache 오류면 같은 명령을
`require_escalated`로 재실행한다. parallel cloned Simulator가 멈추면 해당 PID만 종료하고
`-parallel-testing-enabled NO`를 추가한 fresh 실행으로 검증한다.

문서 Result에는 실제 기기명, OS, 총 테스트 수, 실패·skip, exit code와 sandbox/권한 실행 여부를
구분해 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "docs: #102 - 삭제 드래그 줄바꿈 전체 테스트 검증"
```

Result: 기본 sandbox에서 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 fresh 실행했다. 잠긴 연결 물리 기기의 `DTDKRemoteDeviceConnection` 경고는 있었지만, 명시 destination인 iPhone 13 mini / iOS 16.0 (arm64)에서 exit code 0, `TEST SUCCEEDED`였다. 기본 parallel 실행은 cloned Simulator에서 멈추지 않아 `-parallel-testing-enabled NO` fallback을 사용하지 않았다. 결과 번들 `Test-SYKeyboard-2026.07.26_20-55-54-+0900.xcresult` 집계는 sandbox 읽기 권한 오류(exit 64)가 있어 동일한 read-only `xcresulttool` 명령을 권한 있는 환경에서 재실행했고, 총 326개 통과, 실패 0, skip 0, expected failure 0을 확인했다.

- [x] **Step 2: 한글·영문 extension build 실행, 결과 기록 및 커밋**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 build 모두 exit code 0, `BUILD SUCCEEDED`. sandbox 오류면 각각 같은 명령을 권한 있는
환경에서 재실행하고 결과를 구분한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md
git commit -m "docs: #102 - 삭제 드래그 줄바꿈 extension 빌드 검증"
```

Result: 두 scheme 모두 iPhone 13 mini / iOS 16.0 (arm64) simulator destination으로 fresh build했다. `HangeulKeyboard` 기본 sandbox 실행은 CoreSimulatorService 연결 및 SwiftPM/clang ModuleCache 권한 오류로 exit 74였고, 권한 있는 동일 명령은 exit code 0, `BUILD SUCCEEDED`였다. `EnglishKeyboard` 기본 sandbox 실행도 같은 CoreSimulatorService 및 SwiftPM/clang ModuleCache 권한 오류로 exit 74였고, 권한 있는 동일 명령은 exit code 0, `BUILD SUCCEEDED`였다.

- [x] **Step 3: 수동 검증 계약 갱신, 변경 범위 검토 및 커밋**

`docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md`의 수동 검증 대기를 다음 의미로
갱신한다.

1. Messages 여러 줄에서 delete drag가 줄바꿈을 넘어 왼쪽 삭제되고 오른쪽 왕복에서 원문 복구
2. 한글·영문에서 문서 끝까지 long delete
3. 삭제 가능한 동안 기존 cadence와 동일한 체감 속도
4. 정상 반복 상태에서 timer tick당 실제 delete 한 번
5. Undo 원문 복원
6. Redo 재삭제
7. 선택 텍스트 삭제 Undo/Redo
8. 문서 시작에서 손을 누르는 동안 버튼 UI 유지, 손을 떼면 강조·gesture 해제
9. 문서 시작 도달 뒤 추가 사운드·햅틱 없음

Run:

```sh
git diff --check
git status --short
git diff --stat HEAD~8..HEAD
git log --oneline -12
```

Expected: `.gitignore` 외 미커밋 변경 없음, 계획 밖 파일 없음, 각 Step commit과 Result가 실제 실행과
일치한다. 실제 Messages/물리 기기 항목은 `사용자 검증 대기`로 남긴다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-drag-newline-boundary.md \
  docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "docs: #102 - 삭제 드래그 줄바꿈 수동 검증 계약"
```

Result: coordinator 계획의 수동 검증 대기를 brief의 9개 항목으로 갱신했고, Messages 실제 입력과 물리 사운드·햅틱은 사용자 검증 대기로 남겼다. 커밋 직전 `git diff --check`는 exit 0이었다. `git status --short`의 미커밋 범위는 사용자 소유 `.gitignore`와 이 Step의 두 계획 문서뿐이었다. `git diff --stat HEAD~8..HEAD`는 Task 1·2의 `KeyboardTextInteractionPolicy.swift`, `BaseKeyboardViewController.swift`, 두 관련 테스트와 newline-boundary 계획 문서만 보였고, `git log --oneline -12`에서 Step 1·2 문서 커밋(`2fc1ad4`, `06076ba`)과 선행 Task 1·2 커밋을 확인했다. Step 3 커밋 뒤 최종 worktree도 별도 확인한다.

---

## 완료 조건

- Messages의 삭제 드래그가 줄바꿈을 넘어가고 오른쪽 드래그로 정확히 복구된다.
- 확인된 줄바꿈만 임시 복구 버퍼와 Undo history에 한 번 기록된다.
- 확인 대기 중 pan과 pan stop의 FIFO 순서가 유지된다.
- 문서 시작 무효 pan은 mutation, 복구 문자, 추가 피드백 또는 보충 삭제를 만들지 않는다.
- 반복 삭제는 문서 시작에서 멈추지만 손을 떼기 전 버튼 UI를 강제로 해제하지 않는다.
- 손을 떼면 기존 gesture controller가 버튼 강조와 gesture 상태를 해제한다.
- 관련 집중 테스트와 전체 `SYKeyboard` 테스트가 통과한다.
- `HangeulKeyboard`와 `EnglishKeyboard`가 빌드된다.
- Messages 실제 입력과 물리 사운드·햅틱은 사용자가 확인하기 전까지 검증 대기로 남는다.

## 최종 리뷰 보완 및 재검증

- 최종 전체 리뷰에서 callback 시점 선택 텍스트와 pan stop 선행 시 늦은 callback 처리 두 항목을
  확인했다.
- `63e10e13`에서 회귀 테스트를 추가했고, `1687d1b7`에서 callback의 선택 상태 확인과
  generation-safe 후속 checkpoint를 구현했다.
- 수정 전 집중 테스트는 40개 중 4개가 실패했고, 수정 뒤 같은 40개와 관련 5개 suite 89개가 모두
  통과했다.
- 최종 재리뷰는 두 항목이 모두 해소됐고 새 Critical/Important 문제가 없다고 판정했다.
- 현재 HEAD의 XcodeBuildMCP 직렬 전체 테스트는 iPhone 13 mini / iOS 16.0에서 329개 통과,
  실패 0, skip 0이었다.
- 같은 destination에서 `HangeulKeyboard`와 `EnglishKeyboard`의 최종 simulator build가 모두
  성공했다.
- Messages 실제 입력과 물리 사운드·햅틱 9개 항목은 계속 사용자 검증 대기다.
