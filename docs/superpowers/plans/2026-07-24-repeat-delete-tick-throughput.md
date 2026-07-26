# 반복 삭제 Tick 처리 및 최종 리뷰 수정 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 반복 삭제의 실제 mutation 검증을 유지하면서 기존 timer 속도로 tick당 새 삭제를 정확히 한 번 수행하고, callback 없는 checkpoint와 선택 텍스트 삭제의 잘못된 Undo 기록을 막는다.

**Architecture:** `RepeatDeleteRequest`가 callback과 checkpoint를 서로 다른 확인 출처로 처리하고, 요청 시작 시 선택 텍스트도 함께 보관한다. 다음 timer tick은 pending 요청을 checkpoint로 먼저 완료하며, 완료된 경우 같은 tick에서 다음 요청과 삭제를 한 번만 시작한다. 확인할 수 없는 요청은 새 삭제 없이 기존 UI 해제 경로로 종료한다.

**Tech Stack:** Swift 5, UIKit `UIInputViewController`/`UITextDocumentProxy`, Combine `Timer`, Swift Testing, `xcodebuild`

## Global Constraints

- 지원 범위는 iOS 16+다.
- 반복 timer 간격 계산 `max(0.01, 0.10 - repeatRate)`은 변경하지 않는다.
- 이전 삭제를 callback 또는 checkpoint로 확인할 수 있고 삭제할 문자가 남은 정상 반복 상태에서는
  callback 도착 시점과 관계없이 매 timer tick에 새 삭제 동작을 정확히 한 번 호출한다.
- 어떤 상황에서도 timer tick 하나가 새 삭제 동작을 두 번 이상 호출하지 않는다.
- 문서 시작 또는 이전 삭제 확인 실패로 새 삭제를 호출하지 않은 tick은 삭제 횟수를 누적하지 않으며,
  이후 tick에서 보충 삭제를 두 번 호출하지 않는다.
- 삭제 확인 전에는 다음 삭제를 요청하지 않는다.
- callback 증거 없이 앞·뒤 문맥이 그대로인 checkpoint는 줄바꿈 삭제로 확정하지 않는다.
- 선택 텍스트 삭제는 요청 전 선택이 비어 있지 않고 확인 시 선택이 해제된 경우에만 확정한다.
- 실제로 확정된 삭제에만 반복 삭제 사운드·햅틱과 Undo mutation을 한 번 기록한다.
- 한글 조합 치환, 일반 문자, 줄바꿈, 문서 시작 UI 해제의 기존 의미를 유지한다.
- 각 Step 완료 시 이 문서의 checkbox와 실제 Result를 갱신하고 해당 Step만 별도 커밋한다.
- iOS 디버거 skill 사용을 전제로 하지 않는다.

---

## 사전 확인

- 기준 branch: `bug/#102-cursor-drag-newline-boundary`
- 설계 문서: `docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md`
- 기존 전체 구현 계획: `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`
- history compaction 전 최종 검증 기준 commit(현재 branch에서 unreachable): `b7458d0f`
- history compaction 전 후속 설계 commit(현재 branch에서 unreachable): `3af5bd87`
- history compaction 전 AGENTS 디버거 강제 지침 제거 commit(현재 branch에서 unreachable): `239a1657`
- 현재 확인된 최종 리뷰 차단 사항:
  1. unchanged checkpoint가 callback 증거 없이 phantom `"\n"` mutation을 만들 수 있다.
  2. 선택 텍스트 삭제를 suffix 치환으로 검증해 정상 삭제를 `.noDeletion`으로 버릴 수 있다.
  3. 늦은 callback을 다음 timer checkpoint에서 확정할 때 해당 tick이 새 삭제 없이 소비돼 체감 속도가 느려질 수 있다.

SDD preflight에서는 이 계획의 Task와 Global Constraints가 설계 문서 및 `AGENTS.md`와 충돌하지 않는지만 확인한다. 구현 시작 전에 작업 트리가 깨끗한지도 확인한다.

```sh
git status --short
git log --oneline -5
```

Expected: 미커밋 변경이 없고 HEAD가 이 계획 문서 커밋을 가리킨다.

---

### Task 1: callback/checkpoint 출처와 선택 삭제 확인

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md`

**Interfaces:**
- Produces: `RepeatDeleteConfirmationSource`
- Changes: `RepeatDeleteRequest.begin(context:selectedText:)`
- Changes: `RepeatDeleteRequest.completeAfterTextChange(isRepeatingInput:currentContext:currentSelectedText:)`
- Changes: `RepeatDeleteRequest.completeAtCheckpoint(currentContext:currentSelectedText:)`
- Preserves: `RepeatDeleteCaptureResult`, `RepeatDeleteCompletion`, `RepeatDeleteMutationDraft`

- [x] **Step 1: 확인 출처와 선택 삭제 회귀 테스트 작성 및 커밋**

`KeyboardTextInteractionPolicyTests`에 다음 테스트를 추가한다.

```swift
@Test("변경 없는 checkpoint는 줄바꿈 mutation을 만들지 않음")
func test반복삭제_변경없는Checkpoint_줄바꿈확정안함() {
    var request = RepeatDeleteRequest()
    let context = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
    request.begin(context: context, selectedText: nil)
    _ = request.capture(
        deletedText: "c",
        insertedText: "",
        reliability: .proxyContext
    )

    #expect(
        request.completeAtCheckpoint(
            currentContext: context,
            currentSelectedText: nil
        ) == nil
    )
    #expect(request.isPending)
}

@Test("동일 문맥 textDidChange는 메시지 줄바꿈 삭제로 확정")
func test반복삭제_동일문맥Callback_줄바꿈확정() {
    var request = RepeatDeleteRequest()
    let context = KeyboardTextContextSnapshot(
        beforeInput: "다라",
        afterInput: "마바\n"
    )
    request.begin(context: context, selectedText: nil)
    _ = request.capture(
        deletedText: "라",
        insertedText: "",
        reliability: .proxyContext
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: context,
            currentSelectedText: nil
        ) == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ])
    )
}

@Test("선택 텍스트가 해제된 callback은 선택 삭제를 확정")
func test반복삭제_선택삭제_Callback확정() {
    var request = RepeatDeleteRequest()
    let context = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "다")
    let draft = RepeatDeleteMutationDraft(
        deletedText: "나",
        insertedText: "",
        reliability: .authoritative
    )
    request.begin(context: context, selectedText: "나")
    _ = request.capture(
        deletedText: draft.deletedText,
        insertedText: draft.insertedText,
        reliability: draft.reliability
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: context,
            currentSelectedText: nil
        ) == .mutations([draft])
    )
}

@Test("선택 텍스트가 유지되면 선택 삭제를 확정하지 않음")
func test반복삭제_선택유지_확정안함() {
    var request = RepeatDeleteRequest()
    let context = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "다")
    request.begin(context: context, selectedText: "나")
    _ = request.capture(
        deletedText: "나",
        insertedText: "",
        reliability: .authoritative
    )

    #expect(
        request.completeAtCheckpoint(
            currentContext: context,
            currentSelectedText: "나"
        ) == nil
    )
    #expect(request.isPending)
}
```

`KeyboardTextInteractionPolicyTests`, `HangeulCompositionStateTests`,
`KeyboardUndoRedoManagerTests`의 기존 모든 `begin`, `completeAfterTextChange`,
`completeAtCheckpoint` 호출에는 각각 실제 시나리오에 맞는 `selectedText: nil` 또는
`currentSelectedText: nil`을 명시한다. 아직 production signature를 바꾸지 않으므로 컴파일 실패가
예상된다.

Commit:

```sh
git add SYKeyboardTests/Domain/HangeulCompositionStateTests.swift \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift \
  docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "test: #102 - 반복 삭제 확인 출처와 선택 삭제 회귀"
```

Result: `git diff --check` 통과. 회귀 테스트와 기존 호출의 선택 상태 인자를 추가했으며, 집중 테스트 실행은 의도적으로 다음 RED 검증 Step에서 수행한다.

- [x] **Step 2: 집중 테스트 RED 확인 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: 새 `selectedText`/`currentSelectedText` 인자가 아직 없어 컴파일 실패한다. 실패가 새 회귀 테스트의 요구 사항 때문인지 확인하고 실제 오류 수와 대표 오류를 Result에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 최종 리뷰 RED 검증"
```

Result: iPhone 13 mini / iOS 16.0에서 지정한 `xcodebuild test`가 예상대로 컴파일 실패했다. 대표 오류는 `HangeulCompositionStateTests.swift:102:27: error: extra argument 'selectedText' in call` 및 `currentSelectedText`의 동일 오류이며, 실패한 build command는 5개였다. Firebase/Crashlytics run script가 매 빌드 실행된다는 기존 경고가 함께 출력됐다.

- [x] **Step 3: 확인 출처와 선택 상태 최소 구현 및 커밋**

`KeyboardTextInteractionPolicy.swift`에 확인 출처를 추가한다.

```swift
enum RepeatDeleteConfirmationSource: Equatable {
    case textDidChange
    case checkpoint
}
```

`RepeatDeleteRequest`는 요청 전 선택과 capture 전 callback 관찰값을 함께 보관한다.

```swift
private struct RepeatDeleteObservation {
    let context: KeyboardTextContextSnapshot
    let selectedText: String?
}

private var requestSelectedText: String?
private var callbackObservationBeforeCapture: RepeatDeleteObservation?

mutating func begin(
    context: KeyboardTextContextSnapshot,
    selectedText: String?
) {
    requestContext = context
    requestSelectedText = selectedText
    drafts.removeAll()
    callbackObservationBeforeCapture = nil
}
```

`completeAfterTextChange`는 `.textDidChange`, `completeAtCheckpoint`는 `.checkpoint`를 private `complete`에 전달한다. capture 전 callback도 `RepeatDeleteObservation`으로 저장하고 capture 뒤 `.textDidChange` 출처로 완료한다.

```swift
mutating func completeAfterTextChange(
    isRepeatingInput: Bool,
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> RepeatDeleteCompletion? {
    guard isRepeatingInput, let requestContext else { return nil }
    guard normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
    else { return nil }
    guard !drafts.isEmpty else {
        callbackObservationBeforeCapture = RepeatDeleteObservation(
            context: currentContext,
            selectedText: currentSelectedText
        )
        return nil
    }
    return complete(
        source: .textDidChange,
        currentContext: currentContext,
        currentSelectedText: currentSelectedText
    )
}

mutating func completeAtCheckpoint(
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> RepeatDeleteCompletion? {
    return complete(
        source: .checkpoint,
        currentContext: currentContext,
        currentSelectedText: currentSelectedText
    )
}
```

`capture`는 capture 전에 저장된 callback을 다음처럼 `.textDidChange` 출처로 소비한다.

```swift
if let observation = callbackObservationBeforeCapture,
   let completion = complete(
    source: .textDidChange,
    currentContext: observation.context,
    currentSelectedText: observation.selectedText
   ) {
    return .completion(completion)
}
```

private `complete`는 callback과 checkpoint 모두에서 요청 전후 `afterInput`이 같은지 먼저 검사한 뒤
`confirmedDrafts`에 source와 선택 상태를 전달한다.

```swift
guard normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
else { return nil }
```

선택 삭제는 다른 authoritative 치환보다 먼저 분기한다.

```swift
if let requestSelectedText, !requestSelectedText.isEmpty {
    guard normalized(currentSelectedText).isEmpty,
          normalized(requestContext.beforeInput) == normalized(currentContext.beforeInput),
          normalized(requestContext.afterInput) == normalized(currentContext.afterInput),
          drafts.count == 1,
          drafts[0].reliability == .authoritative,
          drafts[0].deletedText == requestSelectedText,
          drafts[0].insertedText.isEmpty
    else { return [] }
    return drafts
}
```

proxy 후보가 일반 suffix 삭제가 아닌 동일 앞 문맥 줄바꿈으로 확정되는 조건에는 `source == .textDidChange`를 추가한다. 빈 앞 문맥에서 직전 줄 문맥이 나타나는 경우는 checkpoint에서도 관찰 가능한 변경이므로 유지한다.

`BaseKeyboardViewController`는 요청 시작, callback, checkpoint마다 현재 `textDocumentProxy.selectedText`를 전달한다.

```swift
func beginRepeatDeleteRequest() {
    repeatDeleteRequest.begin(
        context: currentTextContextSnapshot(),
        selectedText: textDocumentProxy.selectedText
    )
}
```

`consume()`은 `requestSelectedText`와 `callbackObservationBeforeCapture`도 초기화한다.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "fix: #102 - 반복 삭제 callback과 선택 상태 검증"
```

Result: `git diff --check` 통과. callback/checkpoint 출처와 요청·callback 선택 상태를 `RepeatDeleteRequest`에 전달하고, controller의 시작·callback·checkpoint에서 `textDocumentProxy.selectedText`를 제공했다. 집중 테스트 실행은 다음 GREEN 검증 Step에서 수행한다.

- [x] **Step 4: 집중 테스트 GREEN 확인 및 커밋**

Step 2와 같은 `xcodebuild test` 명령을 실행한다.

Expected: `KeyboardTextInteractionPolicyTests` 전체 통과. callback 동일 문맥 줄바꿈은 유지되고, 동일 문맥 checkpoint는 nil이며, 선택 해제만 선택 삭제를 확정한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 확인 출처 GREEN 검증"
```

Result: iPhone 13 mini / iOS 16.0에서 지정한 `xcodebuild test`가 통과했다. `KeyboardTextInteractionPolicyTests` 26개 중 26개 통과, 실패 0개, skip 0개였다. 다중 일치 simulator 대상 선택 경고, Firebase/Crashlytics run script 매 빌드 실행 경고, AppIntents metadata extraction skipped 경고는 기존 빌드 환경 출력이다.

---

### Task 2: 기존 속도의 tick당 단일 삭제 유지

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md`

**Interfaces:**
- Changes: `RepeatDeleteAction.deleteAwaitingTextChange(previousCompletion:)`
- Produces: `RepeatDeleteRequest.actionForNextTick(currentContext:currentSelectedText:)`
- Consumes: Task 1의 출처별 checkpoint와 선택 상태 확인
- Preserves: timer interval과 `repeatDeleteBackward()` 구현

- [x] **Step 1: 다음 tick action 회귀 테스트 작성 및 커밋**

다음 세 테스트를 추가한다.

```swift
@Test("pending이 없으면 다음 tick은 완료 기록 없이 삭제 한 번 준비")
func test반복삭제_다음Tick_새삭제준비() {
    var request = RepeatDeleteRequest()

    #expect(
        request.actionForNextTick(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "가", afterInput: ""),
            currentSelectedText: nil
        ) == .deleteAwaitingTextChange(previousCompletion: nil)
    )
}

@Test("pending이 checkpoint에서 확정되면 같은 tick에 다음 삭제 준비")
func test반복삭제_다음Tick_이전확정후새삭제준비() {
    var request = RepeatDeleteRequest()
    let draft = RepeatDeleteMutationDraft(
        deletedText: "나",
        insertedText: "",
        reliability: .proxyContext
    )
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: "가나", afterInput: ""),
        selectedText: nil
    )
    _ = request.capture(
        deletedText: draft.deletedText,
        insertedText: draft.insertedText,
        reliability: draft.reliability
    )

    #expect(
        request.actionForNextTick(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "가", afterInput: ""),
            currentSelectedText: nil
        ) == .deleteAwaitingTextChange(previousCompletion: .mutations([draft]))
    )
    #expect(request.isPending == false)
}

@Test("pending 변경을 확인할 수 없으면 다음 tick은 새 삭제 없이 종료")
func test반복삭제_다음Tick_확인실패시종료() {
    var request = RepeatDeleteRequest()
    let context = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
    request.begin(context: context, selectedText: nil)
    _ = request.capture(
        deletedText: "가",
        insertedText: "",
        reliability: .proxyContext
    )

    #expect(
        request.actionForNextTick(
            currentContext: context,
            currentSelectedText: nil
        ) == .finishWithoutDeletion
    )
    #expect(request.isPending)
}
```

`deleteAwaitingTextChange` 한 case에만 새 삭제를 연결하고 controller switch의 해당 case에
`repeatDeleteBackward()`가 한 번만 존재하도록 한다. 순수 action 테스트는 이전 삭제를 확인할 수 있는
정상 반복 상태에서 새 삭제가 정확히 한 번 발생하고, 문서 시작 또는 확인 실패에서는 새 삭제가 없으며,
어느 경우에도 한 tick에서 두 번 발생하거나 다음 tick으로 횟수가 누적되지 않음을 고정한다.

Commit:

```sh
git add SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "test: #102 - 반복 삭제 tick당 단일 호출 회귀"
```

Result: `git diff --check` 통과. 다음 tick의 pending 없음, checkpoint 확정, checkpoint 확인 실패를 검증하는 회귀 테스트 3개를 추가했다. RED/GREEN 집중 테스트는 Step 2와 Step 4의 지정 명령에서 각각 수행한다.

- [x] **Step 2: 다음 tick action RED 확인 및 커밋**

Task 1 Step 2의 집중 테스트 명령을 실행한다.

Expected: `actionForNextTick` 및 associated value가 있는 `deleteAwaitingTextChange(previousCompletion:)`이 없어 컴파일 실패한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick 속도 RED 검증"
```

Result: iPhone 13 mini / iOS 16.0에서 지정한 XcodeBuildMCP 집중 테스트가 예상대로 컴파일 실패했다. 실패는 8개였고, 대표 오류는 `KeyboardTextInteractionPolicyTests.swift:110:13: value of type 'RepeatDeleteRequest' has no member 'actionForNextTick'`이며, 아직 associated value가 없는 `deleteAwaitingTextChange(previousCompletion:)` 문맥에서 파생된 `nil requires a contextual type` 오류도 확인됐다.

- [x] **Step 3: 같은 tick 완료 후 새 삭제 최소 구현 및 커밋**

`RepeatDeleteAction`을 다음처럼 변경한다.

```swift
enum RepeatDeleteAction: Equatable {
    case deleteAwaitingTextChange(previousCompletion: RepeatDeleteCompletion?)
    case finishWithoutDeletion
}
```

`RepeatDeleteRequest`에 다음 메서드를 추가한다.

```swift
mutating func actionForNextTick(
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> RepeatDeleteAction {
    guard isPending else {
        return .deleteAwaitingTextChange(previousCompletion: nil)
    }
    guard let completion = completeAtCheckpoint(
        currentContext: currentContext,
        currentSelectedText: currentSelectedText
    ) else {
        return .finishWithoutDeletion
    }
    return .deleteAwaitingTextChange(previousCompletion: completion)
}
```

`performRepeatTextInteraction(for:)`와 `performInitialRepeatDeleteTextInteraction(for:)`는 현재 문맥으로 action을 한 번 계산한다.

```swift
let action = repeatDeleteRequest.actionForNextTick(
    currentContext: currentTextContextSnapshot(),
    currentSelectedText: textDocumentProxy.selectedText
)
switch action {
case .deleteAwaitingTextChange(let previousCompletion):
    processRepeatDeleteCompletion(previousCompletion)
    beginRepeatDeleteRequest()
    repeatDeleteBackward()
case .finishWithoutDeletion:
    finishRepeatDeleteWithoutDeletion(for: button)
}
```

첫 반복 삭제에서 기존 한글 조합 처리를 유지해야 하므로 `repeatDeleteBackward()` 대신 기존처럼 `performTextInteraction(for:)`를 호출하되, 해당 case 안의 새 삭제 호출은 한 번만 둔다.

`finishRepeatDeleteWithoutDeletion(for:)`은 action 계산에서 checkpoint를 이미 수행했으므로 다시 완료를 시도하지 않고 `.noDeletion` 소비, 버튼 UI 해제, 반복 상태 종료만 수행한다. 버튼 release 경로의 `completeRepeatDeleteAtCurrentContext()`는 callback 없는 마지막 성공을 보존하기 위해 유지한다.

기존 `KeyboardTextInteractionPolicy.repeatDeleteAction(hasPendingRequest:)`는 사용처와 테스트를 제거한다. timer 생성과 `repeatTimerInterval`은 수정하지 않는다.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "fix: #102 - 반복 삭제 tick당 단일 호출 속도 유지"
```

Result: `git diff --check` 통과. Step 2 RED에서 요구한 `actionForNextTick`과 completion-associated action을 최소 구현했고, 두 controller 반복 삭제 경로가 checkpoint 완료 처리 뒤 새 삭제를 한 번만 시작하도록 변경했다. 기존 정책 helper와 회귀 테스트를 제거했으며, timer 간격과 `repeatDeleteBackward()` 구현은 변경하지 않았다. GREEN 집중 테스트는 Step 4에서 수행한다.

- [x] **Step 4: 집중 테스트 GREEN 확인 및 커밋**

Task 1 Step 2의 집중 테스트 명령을 실행한다.

Expected: 전체 집중 테스트 통과. pending 성공은 `.deleteAwaitingTextChange(previousCompletion:)`, pending 실패는 `.finishWithoutDeletion`, pending 없음은 nil completion을 반환한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick 속도 GREEN 검증"
```

Result: XcodeBuildMCP로 iPhone 13 mini / iOS 16.0에서 지정한 집중 테스트를 실행해 27개 통과, 0개 실패, 0개 skip을 확인했다. pending 성공은 `.deleteAwaitingTextChange(previousCompletion:)`, pending 실패는 `.finishWithoutDeletion`, pending 없음은 nil completion을 반환한다. Meta/Buck 의존성의 누락된 `.pcm` 파일 경고 26개가 출력됐지만 테스트 결과에는 영향을 주지 않았다.

---

### Task 3: 전체 회귀와 변경 범위 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md`

- [x] **Step 1: 전체 테스트 실행 및 결과 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 테스트 실패 0건. 실행한 실제 Simulator 기기명과 OS, 테스트 개수, 기존 외부 의존성 경고 여부를 Result에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick 전체 테스트 검증"
```

Result: XcodeBuildMCP로 iPhone 13 mini / iOS 16.0 (UDID `CBD992D3-5364-4F69-AC5F-0077ADF1A292`)에서 전체 테스트를 실행했다. 286개 통과, 0개 실패, 0개 skip (45.0초)이며 test action은 성공했다. XcodeBuildMCP의 이번 실행 요약에는 외부 의존성 경고가 출력되지 않았다. 다만 Task 2 집중 테스트에서 확인된 Meta/Buck 의존성의 누락된 `.pcm` 파일 경고 26개는 기존 환경 경고로 남아 있다. 리뷰 보강으로 위에 적힌 정확한 `xcodebuild test` 명령도 실행했고, 해당 `.xcresult`는 같은 iPhone 13 mini / iOS 16.0에서 286개 통과, 0개 실패, 0개 skip, exit 0을 기록했다. 명령 출력에는 다중 일치 destination 선택 경고, AppIntents metadata extraction skipped 경고, Firebase/Crashlytics run script가 매 빌드 실행된다는 기존 note가 있었다.

- [x] **Step 2: 한글·영문 extension 빌드 및 결과 커밋**

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

Expected: 두 scheme 모두 `BUILD SUCCEEDED`. 실제 대상과 경고를 Result에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick extension 빌드 검증"
```

Result: XcodeBuildMCP로 iPhone 13 mini / iOS 16.0 (UDID `CBD992D3-5364-4F69-AC5F-0077ADF1A292`)에서 `HangeulKeyboard`와 `EnglishKeyboard`를 각각 빌드했고 둘 다 성공했다 (`HangeulKeyboard` 8.7초, `EnglishKeyboard` 5.2초). `HangeulKeyboard` 빌드에는 Meta/Buck 외부 의존성의 누락된 `.pcm` 파일 경고 26개가 출력됐으며, `EnglishKeyboard` 빌드에는 경고가 출력되지 않았다. 리뷰 보강으로 위에 적힌 두 정확한 `xcodebuild build` 명령을 같은 대상에서 실행했다. 기본 샌드박스 실행은 CoreSimulatorService·SwiftPM/clang cache의 `Operation not permitted` 환경 오류로 실패했으며, 각각 동일 명령을 권한 있는 환경에서 재실행해 exit 0 및 `** BUILD SUCCEEDED **`를 확인했다. 두 명령에는 다중 일치 destination 선택 경고와 Firebase/Crashlytics run script note가 있었고, Hangeul build에는 기존 Meta/Buck 누락 `.pcm` 경고 26개와 AppIntents metadata extraction skipped 경고도 출력됐다.

- [x] **Step 3: 사용자 수동 검증 항목 기록 및 커밋**

다음 항목은 사용자가 Messages 앱의 실제 SY키보드에서 확인한다.

1. `가나\n다라\n마바\n` 입력 후 키보드 드래그로 줄 사이를 왕복한다.
2. 맨 끝에서 삭제 버튼을 길게 눌러 전부 삭제한다.
3. 삭제 가능한 동안 속도가 중간에 절반으로 느려지거나 두 글자씩 빨라지지 않는지 확인한다.
4. 한 timer cadence에 대응해 한 번씩만 삭제되는지 확인한다.
5. SY키보드 undo 한 번으로 원문이 정확히 복구되는지 확인한다.
6. redo 한 번으로 복구된 전체 문자열이 다시 삭제되는지 확인한다.
7. 선택 텍스트를 길게 누른 삭제의 첫 동작으로 지운 뒤 undo/redo가 정확한지 확인한다.
8. 문서 시작에서는 추가 삭제·추가 피드백 없이 버튼 UI가 해제되는지 확인한다.

자동 검증하지 않은 항목은 성공으로 기록하지 않고 `사용자 검증 대기`로 남긴다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick 수동 검증 항목"
```

Result: 사용자 검증 대기. 이 Step에서는 Messages 앱의 실제 SY키보드를 자동화하거나 통과로 처리하지 않았다. 아래 8개 항목(줄 사이 드래그 왕복, 끝까지 길게 삭제, 삭제 속도, tick당 한 번 삭제, undo, redo, 선택 삭제 undo/redo, 문서 시작 UI/피드백 해제)은 사용자가 실제 기기에서 확인해야 한다. 따라서 체감 속도, 실제 Undo/Redo, 사운드·햅틱 동작은 아직 검증되지 않았다.

- [x] **Step 4: 최종 범위와 이력 검토 및 커밋**

Run:

```sh
git diff 239a1657..HEAD --check
git status --short
git log --oneline --reverse 239a1657..HEAD
git diff --stat 239a1657..HEAD
```

Expected:

- production 변경은 정책과 base controller에 한정된다.
- 동작 회귀 테스트는 `KeyboardTextInteractionPolicyTests`에 추가되고, 변경된 signature를 사용하는
  `HangeulCompositionStateTests`와 `KeyboardUndoRedoManagerTests`는 인자만 맞춘다.
- 계획 결과는 매 Step별 커밋으로 분리된다.
- timer interval, redo 적용 함수, Firebase/광고/권한/번들 설정은 변경되지 않는다.
- 공백 오류와 미커밋 변경이 없다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md
git commit -m "docs: #102 - 반복 삭제 tick 최종 변경 범위 검증"
```

Historical Result: history compaction 전 `git diff 239a1657..HEAD --check`는 출력 없이 통과했고
`git status --short`도 출력이 없었다. 당시 `.superpowers/sdd/task-1-confirmed-undo-report.md`는
`.gitignore`의 `*` 규칙과 별개로 이미 추적 중이었으므로 “scratch/report 파일은 Git ignore 상태”라는
기존 설명은 부정확했다. 해당 보고서는 2026-07-25 최종 리뷰 수정에서 index와 tree에서 제거했다.
`239a1657..HEAD` 범위와 이 문단의 당시 HEAD는 history compaction 후 현재 branch에서 재현 가능한
범위가 아니라 historical execution evidence다.

#### Task 3 Review Fix

Check: Step 1·2의 도구 수준 결과만으로는 브리프가 요구한 정확한 shell command 증거가 부족하다는 리뷰를 반영했다. `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`는 exit 0 및 286개 통과/0개 실패/0개 skip, `HangeulKeyboard`와 `EnglishKeyboard`의 같은 destination `xcodebuild build` 명령은 각각 권한 있는 재실행에서 exit 0 및 `** BUILD SUCCEEDED **`였다. 두 build의 기본 샌드박스 실패는 CoreSimulatorService·SwiftPM/clang cache 권한 오류로, 코드 실패와 구분했다.

---

## 완료 조건

- unchanged checkpoint가 phantom 줄바꿈 mutation을 만들지 않는다.
- callback 기반 동일 줄 문맥의 실제 줄바꿈 삭제는 계속 확정된다.
- 선택 텍스트 삭제가 Undo/Redo history와 피드백에 한 번 반영된다.
- callback이 늦어도 삭제 가능한 동안 기존 timer 간격마다 새 삭제 동작 한 번을 수행한다.
- timer tick 하나가 새 삭제 동작을 두 번 호출하지 않는다.
- 문서 시작 또는 확인 실패에서는 새 삭제 없이 반복 입력과 버튼 UI를 종료한다.
- 집중 테스트와 전체 테스트가 통과한다.
- `HangeulKeyboard`와 `EnglishKeyboard`가 빌드된다.
- 수동 검증 전에는 Messages 앱의 체감 속도, 실제 Undo/Redo, 사운드·햅틱을 완료로 표현하지 않는다.

---

## 2026-07-25 History Compaction 및 최종 리뷰 수정 기록

사용자 요청에 따른 history compaction으로 compaction 전 Step commit과 범위는 현재 branch에서
unreachable이다. 위에 남은 해당 SHA와 범위는 당시 실행 순서를 설명하는 historical execution evidence이며,
현재 이력 검증 기준으로 사용하지 않는다. compaction 직전 최종 commit `46990093`과 compaction 후
`afb74ad4`의 tree는 모두 `406ac51d160781c2ba9bad3b9429ba8881693b6d`로 동일함을 확인했다.

현재 branch에서 도달 가능한 task-level commit은 다음 8개다.

| 순서 | Commit | 내용 |
|---|---|---|
| 1 | `a046505b` | 반복 삭제 mutation 계획과 실행 기준 정리 |
| 2 | `0f747742` | 반복 삭제 mutation 확인 상태 추가 |
| 3 | `d676e881` | 반복 삭제 요청과 callback undo 검증 |
| 4 | `8e3a4aab` | 반복 삭제 실제 mutation 최종 검증 |
| 5 | `d05cad5e` | 반복 삭제 tick 처리 설계 및 계획 |
| 6 | `dbf5d89f` | 반복 삭제 callback과 선택 상태 검증 |
| 7 | `b73f0e7e` | 반복 삭제 tick당 단일 호출 속도 유지 |
| 8 | `afb74ad4` | 반복 삭제 tick 최종 검증 |

최종 리뷰 수정은 실제 controller/proxy harness가 없는 테스트 구조를 고려해 controller가 직접 사용하는
최소 production 정책 `DeleteMutationLifecycle`을 추출해 검증한다. `.touchDown` 요청을 mutation 전에
시작하고 `textDidChange`/checkpoint 확인을 `isRepeatingInput`과 분리하며, 일반 tap release는 확인되지
않은 touchDown 요청을 정리한다. touchDown의 기존 피드백은 그대로 두고, 확인된 repeat tick만 추가
피드백을 요청한다. timer interval `max(0.01, 0.10 - repeatRate)`, 삭제 가능한 정상 반복 상태에서
tick당 정확히 한 번의 새 삭제, 어느 tick에서도 두 번 이상 삭제하지 않는 계약은 변경하지 않는다.

Messages의 한글·영문 8개 수동 항목은 이번 자동 회귀 테스트로 통과 처리하지 않는다. 실제 SY키보드에서의
원문 복원, Redo, 체감 cadence, 버튼 해제, 사운드·햅틱 확인은 계속 `사용자 검증 대기`다.

자동 검증은 iPhone 13 mini / iOS 16.0에서 수행했다. 신규 lifecycle 집중 테스트는 첫 RED에서
`DeleteMutationLifecycle`/`DeleteMutationResolution` 부재로 예상한 컴파일 실패(exit 65)를 확인했다.
최종 diff review가 발견한 release-before-callback race에는
`discardReleasedTouchDown`/`awaitingPreviousMutation` 부재를 확인하는 추가 RED(exit 65)를 거쳤다.
release된 요청의 callback 조정, 확인 전 English timer/Hangeul 즉시 전환 대기, 일반 release 정리를
포함한 최종 GREEN 7개가 통과했다. 전체 suite는 293개 통과, 실패·skip 0개였다. 두 extension build의
기본 sandbox 실행은 CoreSimulatorService와 SwiftPM/clang cache 권한 오류로 실패했고, 같은 명령의
권한 있는 재실행에서 `HangeulKeyboard`와 `EnglishKeyboard` 모두 `BUILD SUCCEEDED`를 확인했다.

### 2026-07-25 최종 재리뷰 Cycle 4 수정

재리뷰에서 확인된 release race를 보완해 pending repeat tick은 gesture 종료 시
`releasedRepeatTick`으로 전환한다. unchanged newline checkpoint가 즉시 확정되지 않아도 이후
`textDidChange(_:)`가 실제 mutation, grouped Undo/Redo, repeat feedback 한 번을 확정한다. 관련 없는
callback이 실패하면 released request를 소비해 stale 상태를 남기지 않는다.

새 delete touchDown과 repeat request 시작은 기존 pending request가 있으면
`.awaitingPreviousMutation`을 반환하므로 이전 요청을 덮어쓰거나 새 삭제를 실행하지 않는다.
non-delete tap/long press는 edit 전에 lifecycle에서 released 요청을 정리하며, capture도 released
request에 새 mutation을 추가하지 않는다. initial feedback과 Hangeul/English 흐름은 유지하고,
timer interval `max(0.01, 0.10 - repeatRate)`, 삭제 가능한 정상 반복 상태에서 tick당 정확히 한 번의
새 삭제, 어느 tick에서도 두 번 이상 삭제하지 않는 계약은 변경하지 않았다.

production 수정 전 정확한 lifecycle 집중 명령은 새 start/gating 계약 부재로 exit 65,
`** TEST FAILED **`, 3개 failed build commands를 반환했다. callback-before-capture self-review
회귀도 `prepareForNonDeleteEdit` 부재로 예상 RED를 확인했다. 최종 focused GREEN은 lifecycle 테스트
11개 통과다.

최종 전체 `SYKeyboard` suite는 iPhone 13 mini / iOS 16.0에서 297개 통과, 실패·skip·expected failure
0개였다. 같은 대상의 `HangeulKeyboard`와 `EnglishKeyboard` build는 모두
`** BUILD SUCCEEDED **`였다. Messages 한글·영문 8개 수동 항목과 실제 cadence, 버튼 해제,
Undo/Redo UI, 사운드·햅틱은 계속 `사용자 검증 대기`다.

### 2026-07-25 최종 재리뷰 Cycle 5 수정

callback 없는 문서 시작 최초 삭제는 선택 영역 없음, 요청 전·후 빈 문맥, unchanged 현재 문맥,
없거나 빈 draft라는 제한된 증거가 모두 있을 때만 `.noDeletion`으로 끝낸다. empty 현재 문맥이라도
요청 전 문맥이 nonempty인 줄 경계와 nonempty proxy 후보는 계속 기다린다. proxy suffix 비교 전
`before.hasSuffix(candidate.deletedText)`를 확인해 빈 문자열의 `dropLast`가 nonempty 후보를 성공으로
오인하지 않게 했다. 확정된 no-op은 Hangeul 즉시 long press와 English timer에서
`.finishWithoutDeletion`으로 소비되어 새 delete, timer, 버튼 상태를 남기지 않는다.

앞의 released 삭제가 아직 모호한 상태에서 새 delete touchDown 또는 delete pan이 오면 앞 요청을
덮어쓰지 않는다. 두 번째 tap은 deferred intent로, pan 방향은 pending queue로 보존하고, 앞 요청의
late callback 또는 checkpoint 조정 뒤 현재 문맥에서 각각 한 번만 수행한다. deferred tap은 원래
버튼의 `textInteractionWillPerform`/`textInteractionDidPerform`와 기존 삭제 본문을 거치되 최초
touchDown feedback을 다시 재생하지 않는다. pan은 명시적 `actionForDeletePan` boundary를 통과한 뒤
진행하며 최초 줄바꿈과 pan mutation을 같은 grouped Undo/Redo 단위에 보존한다. timer interval
`max(0.01, 0.10 - repeatRate)`과 확인된 repeat mutation당 피드백 한 번 계약은 변경하지 않았다.

production 수정 전 다음 정확한 focused 명령은 `.deferred`, `beginDeferredTouchDown`,
`actionForDeletePan` 부재의 예상 컴파일 실패로 exit 65, `** TEST FAILED **`를 반환했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests
```

기존 11개 regression을 유지하면서 Cycle 5의 5개를 추가했다. 기본 병렬 focused GREEN은 cloned
Simulator 결과 정리 중 `simctl diagnose --timeout=600`에서 멈춰 관련 `xcodebuild` process만
종료했고, 동일 코드·대상의 `-parallel-testing-enabled NO` 재실행에서 16개 모두 통과, exit 0,
`** TEST SUCCEEDED **`를 확인했다.

최종 전체 suite 역시 non-parallel 안정화 옵션으로 새로 실행해 35 suites, 302 tests, 실패 0,
exit 0, `** TEST SUCCEEDED **`였다. iPhone 13 mini / iOS 16.0의 `HangeulKeyboard`와
`EnglishKeyboard` build는 기본 sandbox의 CoreSimulator·SwiftPM/clang cache 접근 실패(exit 74) 후
동일 명령의 권한 있는 재실행에서 각각 exit 0, `** BUILD SUCCEEDED **`였다. Messages 실제
SY키보드의 8개 수동 항목과 체감 cadence, 버튼 해제, Undo/Redo UI, 사운드·햅틱은 계속
`사용자 검증 대기`다.
