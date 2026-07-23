# 반복 삭제 Tick 처리 및 최종 리뷰 수정 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 반복 삭제의 실제 mutation 검증을 유지하면서 기존 timer 속도로 tick당 새 삭제를 정확히 한 번 수행하고, callback 없는 checkpoint와 선택 텍스트 삭제의 잘못된 Undo 기록을 막는다.

**Architecture:** `RepeatDeleteRequest`가 callback과 checkpoint를 서로 다른 확인 출처로 처리하고, 요청 시작 시 선택 텍스트도 함께 보관한다. 다음 timer tick은 pending 요청을 checkpoint로 먼저 완료하며, 완료된 경우 같은 tick에서 다음 요청과 삭제를 한 번만 시작한다. 확인할 수 없는 요청은 새 삭제 없이 기존 UI 해제 경로로 종료한다.

**Tech Stack:** Swift 5, UIKit `UIInputViewController`/`UITextDocumentProxy`, Combine `Timer`, Swift Testing, `xcodebuild`

## Global Constraints

- 지원 범위는 iOS 16+다.
- 반복 timer 간격 계산 `max(0.01, 0.10 - repeatRate)`은 변경하지 않는다.
- timer tick 하나가 새로 호출하는 삭제 동작은 최대 한 번이다.
- 삭제 가능한 동안 callback 도착 시점과 관계없이 매 timer tick에 삭제 동작 한 번을 유지한다.
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
- 현재 최종 검증 기준 commit: `b7458d0f`
- 후속 설계 commit: `3af5bd87`
- AGENTS 디버거 강제 지침 제거 commit: `239a1657`
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

`deleteAwaitingTextChange` 한 case에만 새 삭제를 연결하고 controller switch의 해당 case에 `repeatDeleteBackward()`가 한 번만 존재하도록 한다. 순수 action 테스트는 callback 시점과 무관하게 tick의 결과가 “새 삭제 한 번” 또는 “삭제 없음” 두 가지뿐임을 고정한다.

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

Result: `git diff 239a1657..HEAD --check`는 출력 없이 통과했고 `git status --short`도 출력이 없었다(`.superpowers/sdd`의 scratch/report 파일은 Git ignore 상태). `git diff --stat 239a1657..HEAD` 기준 변경 파일은 정책, base controller, 관련 테스트 3개, 이 계획 문서뿐이다. production 변경은 `KeyboardTextInteractionPolicy.swift`와 `BaseKeyboardViewController.swift`에만 있으며, 테스트 변경은 `KeyboardTextInteractionPolicyTests`의 동작 회귀와 두 기존 테스트 파일의 signature 인자 정합으로 한정된다. 범위 diff에서 timer interval (`max(0.01, 0.10 - repeatRate)`), redo 적용 함수, Firebase/광고/권한/번들 설정은 변경되지 않았고, `239a1657..HEAD` 이력은 Task 1/2와 Task 3 Step 1~3의 목적별 커밋으로 분리돼 있다.

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
