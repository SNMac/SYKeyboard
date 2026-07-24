# Delete Interaction Coordinator 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 삭제 mutation 검증을 유지하면서 보류된 delete touchDown·pan·pan stop을 generation 단위 FIFO로 처리하고, 정상 반복 상태에서는 매 timer tick마다 새 delete를 정확히 한 번 수행한다.

**Architecture:** `RepeatDeleteRequest`와 `DeleteMutationLifecycle`은 실제 삭제 확인만 담당하고, 새 `DeleteInteractionCoordinator`가 입력 대상과 보류 이벤트의 순서·generation·취소를 담당한다. `BaseKeyboardViewController`는 coordinator가 반환한 이벤트만 기존 semantic hook 경로로 실행하며, lifecycle의 명시적 resolution만 같은 generation의 FIFO를 다시 연다.

**Tech Stack:** Swift 5, UIKit `UIInputViewController`/`UITextDocumentProxy`, Combine `Timer`, Swift Testing, `xcodebuild`

## Global Constraints

- 지원 범위는 iOS 16+다.
- 반복 timer 간격 계산 `max(0.01, 0.10 - repeatRate)`은 변경하지 않는다.
- 이전 삭제를 callback 또는 checkpoint로 확인할 수 있고 삭제할 문자가 남은 정상 반복 상태에서는 callback 도착 시점과 관계없이 매 timer tick에 새 삭제 동작을 정확히 한 번 호출한다.
- 어떤 상황에서도 timer tick 하나가 새 삭제 동작을 두 번 이상 호출하지 않는다.
- 문서 시작 또는 이전 삭제 확인 실패로 새 삭제를 호출하지 않은 tick은 삭제 횟수를 누적하지 않으며, 이후 tick에서 보충 삭제를 두 번 호출하지 않는다.
- 삭제 확인 전에는 다음 삭제를 요청하지 않는다.
- callback 증거 없이 앞·뒤 문맥이 그대로인 checkpoint는 줄바꿈 삭제로 확정하지 않는다.
- 선택 텍스트 삭제는 요청 전 선택이 비어 있지 않고 확인 시 선택이 해제된 경우에만 확정한다.
- 실제로 확정된 삭제에만 반복 삭제 사운드·햅틱과 Undo mutation을 한 번 기록한다.
- 보류 이벤트는 touchDown, pan 방향, pan stop의 실제 도착 순서를 유지한다.
- non-delete 입력, 관련 없는 callback 취소, non-nil `inputIdentifier` 변경, `viewWillDisappear(_:)`, 일반 repeat tracking stop은 generation과 FIFO를 함께 폐기한다.
- 취소된 generation의 pan cleanup은 정확히 한 번만 수행하고, 늦은 resolution은 새 입력 대상에서 mutation을 만들지 않는다.
- replay touchDown은 strong target으로 `textInteractionWillPerform(button:)`과 `textInteractionDidPerform(button:)`을 포함한 기존 전체 semantic 경로를 실행한다.
- 한글 조합 치환, suggestion replacement, temporary delete buffer, Undo/Redo grouping, English timer, Hangeul immediate repeat의 기존 의미를 유지한다.
- `selectionWillChange(_:)`/`selectionDidChange(_:)`에 의존하지 않는다.
- Firebase, 광고, entitlement, bundle identifier 및 provisioning 설정을 변경하지 않는다.
- 각 Step은 코드·테스트·문서와 해당 검증이 모두 끝난 직후에만 체크하고, 그 Step의 변경만 별도 커밋한다.
- Messages 실제 입력 화면 8개 항목과 물리 사운드·햅틱은 자동 검증으로 통과 처리하지 않는다.

## 사전 확인

- 기준 branch: `bug/#102-cursor-drag-newline-boundary`
- 승인된 설계: `docs/superpowers/specs/2026-07-25-delete-interaction-coordinator-design.md`
- 원래 처리량 계획: `docs/superpowers/plans/2026-07-24-repeat-delete-tick-throughput.md`
- 구현 시작 기준 commit: 이 계획 문서 commit
- 사용자 소유 `.gitignore` 변경은 모든 Step과 commit에서 제외한다.

Run:

```sh
git status --short
git log --oneline -5
```

Expected: `.gitignore` 외에 미커밋 변경이 없고 HEAD가 이 계획 문서 commit을 가리킨다.

---

### Task 1: Generation 단위 FIFO coordinator

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md`

**Interfaces:**
- Consumes: `TextInteractable`, `PanDirection`, `ObjectIdentifier`
- Produces: `DeleteInteractionGeneration`
- Produces: `DeleteInteractionDisposition`
- Produces: `PendingDeleteInteractionEvent`
- Produces: `DeleteInteractionCancellationResult`
- Produces: `DeleteInteractionCoordinator`

Coordinator의 public-to-module 계약은 다음 이름과 signature를 사용한다.

```swift
struct DeleteInteractionGeneration: Equatable {
    fileprivate let rawValue: UInt64
}

enum DeleteInteractionDisposition: Equatable {
    case performNow
    case enqueued
}

enum PendingDeleteInteractionEvent {
    case touchDown(button: any TextInteractable)
    case pan(direction: PanDirection)
    case panStop
}

struct DeleteInteractionCancellationResult: Equatable {
    let shouldFinishPanTracking: Bool
}

struct DeleteInteractionCoordinator {
    private(set) var currentGeneration: DeleteInteractionGeneration?
    private(set) var isWaitingForResolution: Bool

    mutating func beginTouchDown(
        button: any TextInteractable,
        inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionDisposition

    mutating func enqueuePan(_ direction: PanDirection) -> DeleteInteractionDisposition
    mutating func enqueuePanStop() -> DeleteInteractionDisposition

    @discardableResult
    mutating func resolve(_ generation: DeleteInteractionGeneration) -> Bool

    mutating func nextReadyEvent() -> PendingDeleteInteractionEvent?
    mutating func cancel() -> DeleteInteractionCancellationResult

    mutating func cancelIfInputIdentifierChanged(
        to inputIdentifier: ObjectIdentifier?
    ) -> DeleteInteractionCancellationResult?
}
```

`nextReadyEvent()`가 `.touchDown`을 반환할 때는 controller hook보다 먼저
`isWaitingForResolution == true`가 되어야 한다. `cancel()`은 queue와 strong target을 원자적으로
해제하고, 미완료 pan tracking이 있던 첫 호출에서만 `shouldFinishPanTracking == true`를 반환한다.

- [x] **Step 1: FIFO·generation·strong target 회귀 테스트 작성 및 커밋**

`KeyboardTextInteractionPolicyTests.swift`에 아래 suite를 추가해 다섯 시나리오를 실제 case pattern
matching으로 검증한다.

```swift
@MainActor
@Suite("Delete interaction coordinator")
struct DeleteInteractionCoordinatorTests {

@Test("pan과 stop 뒤의 touchDown을 도착 순서대로 재생")
func testFIFOOrder() {
    var coordinator = DeleteInteractionCoordinator()
    let first = DeleteButton(keyboard: .hangeul)
    let second = DeleteButton(keyboard: .hangeul)

    #expect(coordinator.beginTouchDown(button: first, inputIdentifier: nil) == .performNow)
    #expect(coordinator.enqueuePan(.left) == .enqueued)
    #expect(coordinator.enqueuePanStop() == .enqueued)
    #expect(coordinator.beginTouchDown(button: second, inputIdentifier: nil) == .enqueued)

    let generation = try #require(coordinator.currentGeneration)
    #expect(coordinator.resolve(generation))

    guard case .pan(let direction)? = coordinator.nextReadyEvent(),
          case .left = direction else {
        Issue.record("첫 이벤트가 left pan이 아님")
        return
    }
    guard case .panStop? = coordinator.nextReadyEvent() else {
        Issue.record("두 번째 이벤트가 panStop이 아님")
        return
    }
    guard case .touchDown(let replayed)? = coordinator.nextReadyEvent() else {
        Issue.record("세 번째 이벤트가 touchDown이 아님")
        return
    }
    #expect(ObjectIdentifier(replayed as AnyObject) == ObjectIdentifier(second))
    #expect(coordinator.isWaitingForResolution)
    #expect(coordinator.nextReadyEvent() == nil)
}

@Test("취소는 queue를 비우고 pan cleanup을 한 번만 요청")
func testCancelClearsQueueAndFinishesPanOnce() {
    var coordinator = DeleteInteractionCoordinator()
    let button = DeleteButton(keyboard: .hangeul)
    _ = coordinator.beginTouchDown(button: button, inputIdentifier: nil)
    _ = coordinator.enqueuePan(.left)
    _ = coordinator.enqueuePanStop()

    #expect(coordinator.cancel().shouldFinishPanTracking)
    #expect(coordinator.cancel().shouldFinishPanTracking == false)
    #expect(coordinator.nextReadyEvent() == nil)
}

@Test("입력 대상 변경은 이전 generation resolution을 거부")
func testInputIdentifierChangeRejectsOldGeneration() throws {
    var coordinator = DeleteInteractionCoordinator()
    let button = DeleteButton(keyboard: .hangeul)
    let firstInput = DeleteButton(keyboard: .hangeul)
    let secondInput = DeleteButton(keyboard: .hangeul)
    _ = coordinator.beginTouchDown(
        button: button,
        inputIdentifier: ObjectIdentifier(firstInput)
    )
    _ = coordinator.enqueuePan(.left)
    let generation = try #require(coordinator.currentGeneration)

    let cancellation = coordinator.cancelIfInputIdentifierChanged(
        to: ObjectIdentifier(secondInput)
    )

    #expect(cancellation?.shouldFinishPanTracking == true)
    #expect(coordinator.resolve(generation) == false)
    #expect(coordinator.nextReadyEvent() == nil)
}

@Test("보류 touchDown target은 취소 전까지 강하게 유지")
func testQueuedTouchDownRetainsTargetUntilCancel() {
    var coordinator = DeleteInteractionCoordinator()
    let first = DeleteButton(keyboard: .hangeul)
    var second: DeleteButton? = DeleteButton(keyboard: .hangeul)
    weak var weakSecond = second
    _ = coordinator.beginTouchDown(button: first, inputIdentifier: nil)
    _ = coordinator.beginTouchDown(button: second!, inputIdentifier: nil)

    second = nil
    #expect(weakSecond != nil)
    _ = coordinator.cancel()
    #expect(weakSecond == nil)
}

@Test("replay touchDown resolution 전 동기 재진입은 다음 event를 열지 않음")
func testReplayTouchDownBlocksSynchronousReentry() throws {
    var coordinator = DeleteInteractionCoordinator()
    let first = DeleteButton(keyboard: .hangeul)
    let second = DeleteButton(keyboard: .hangeul)
    _ = coordinator.beginTouchDown(button: first, inputIdentifier: nil)
    _ = coordinator.beginTouchDown(button: second, inputIdentifier: nil)
    _ = coordinator.enqueuePan(.right)
    let generation = try #require(coordinator.currentGeneration)
    #expect(coordinator.resolve(generation))

    guard case .touchDown? = coordinator.nextReadyEvent() else {
        Issue.record("첫 replay event가 touchDown이 아님")
        return
    }
    #expect(coordinator.isWaitingForResolution)
    #expect(coordinator.nextReadyEvent() == nil)
    #expect(coordinator.resolve(generation))
    guard case .pan(let direction)? = coordinator.nextReadyEvent(),
          case .right = direction else {
        Issue.record("touchDown resolution 뒤 right pan이 열리지 않음")
        return
    }
}
}
```

아직 production 타입이 없으므로 compile RED를 의도한다. 테스트와 이 계획의 Result만 stage한다.

Commit:

```sh
git add SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "test: #102 - 삭제 상호작용 coordinator 회귀"
```

Result: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`에 `DeleteInteractionCoordinatorTests` 5개를 추가했다. 현재 `SYKeyboardType`에 없는 brief의 `.hangeul` fixture는 기존 한글 keyboard case인 `.dubeolsik`으로 맞췄다. `git diff --check` 통과. 테스트 실행은 Step 2에서 의도된 compile RED로 확인한다.

- [x] **Step 2: Coordinator 집중 테스트 RED 확인 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: `DeleteInteractionCoordinator`, `DeleteInteractionDisposition` 등 새 타입 부재에 따른 compile
failure. 대표 오류와 exit code를 Result에 기록한다. sandbox/CoreSimulator/cache 오류라면 같은 명령을
권한 있는 환경에서 재실행해 코드 RED와 환경 실패를 분리한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "docs: #102 - 삭제 상호작용 coordinator RED 검증"
```

Result: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests`를 실행했다. iPhone 13 mini / iOS 16.0(arm64)에서 exit code 65로 compile RED를 확인했다. 대표 오류는 `Cannot find 'DeleteInteractionCoordinator' in scope`이며, 이 부재에서 파생한 `nil`/`PanDirection` contextual type 오류도 함께 발생했다. sandbox 환경에서도 CoreSimulator/cache 오류 없이 동일한 코드 RED를 재현했으므로 권한 있는 재실행은 불필요했다.

- [x] **Step 3: Coordinator 최소 구현과 집중 GREEN 및 커밋**

`KeyboardTextInteractionPolicy.swift`에서 coordinator는 하나의 FIFO 배열만 보류 이벤트 저장소로
사용한다. touchDown count, pan array, pan stop flag처럼 이벤트 종류별 저장소를 만들지 않는다.

구현 규칙:

1. `idle`의 touchDown은 새 증가 generation과 owner identifier를 만들고 `.performNow`.
2. active generation의 touchDown/pan/pan stop은 FIFO 끝에 추가하고 `.enqueued`.
3. `resolve(currentGeneration)`만 queue를 열며, 다른 generation 또는 cancel된 generation은 `false`.
4. `.touchDown` dequeue는 event를 반환하기 전에 다시 waiting으로 전환한다.
5. queue가 비고 waiting도 아니면 generation과 owner를 해제한다.
6. owner가 nil일 때 처음 관찰한 non-nil identifier를 owner로 채우고, 기존 non-nil owner와 새 non-nil
   identifier가 다를 때 focus 변경으로 취소한다.
7. cancellation은 queue, generation, owner, target을 함께 해제하고 pan cleanup 신호를 한 번만 반환한다.
8. live 또는 queued pan을 받으면 pan tracking을 active로 기록하고, `panStop`을 즉시 처리하거나 FIFO에서
   꺼낼 때 inactive로 바꿔 이후 cancellation이 cleanup을 중복 요청하지 않게 한다.

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: coordinator suite 5개 통과, 실패·skip 0개. 기본 parallel 실행이 cloned Simulator 진단에서
멈추면 해당 프로세스를 종료하고 `-parallel-testing-enabled NO`를 추가한 동일 범위로 재검증하며 두
결과를 모두 기록한다.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "fix: #102 - 삭제 상호작용 generation FIFO"
```

Result: `xcodebuild -quiet test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests`를 실행했다. sandbox 재실행은 CoreSimulator/cache 권한 오류로 중단됐고, 권한 있는 환경에서 iPhone 13 mini / iOS 16.0(arm64)로 5개 coordinator 테스트가 모두 통과했다(exit code 0). cloned Simulator 진단에서 멈추지 않아 `-parallel-testing-enabled NO` fallback은 사용하지 않았다.

---

### Task 2: Controller와 lifecycle 통합

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md`
- Modify: `/private/tmp/sykeyboard-final-review-fix-report.md` (검증 보고서, commit 제외)

**Interfaces:**
- Consumes: Task 1의 `DeleteInteractionCoordinator`
- Changes: `DeleteMutationLifecycle.completeAfterTextChange(...)`
- Produces: `DeleteMutationCallbackOutcome`
- Produces: `BaseKeyboardViewController.cancelPendingDeleteInteractions()`
- Produces: `BaseKeyboardViewController.drainPendingDeleteInteractionsIfPossible()`
- Removes: `DeleteMutationLifecycle.deferredTouchDownCount`
- Removes: `DeleteMutationLifecycle.beginDeferredTouchDown(...)`
- Removes: `BaseKeyboardViewController.deferredDeleteButton`
- Removes: `BaseKeyboardViewController.pendingDeletePanDirections`
- Removes: `BaseKeyboardViewController.isDeleteButtonPanStopPending`

Lifecycle callback의 취소를 controller가 잃지 않도록 optional resolution을 아래 outcome으로 바꾼다.

```swift
enum DeleteMutationCallbackOutcome: Equatable {
    case noResolution
    case resolved(DeleteMutationResolution)
    case cancelled
}

mutating func completeAfterTextChange(
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> DeleteMutationCallbackOutcome
```

Controller의 coordinator 연동 helper 계약:

```swift
func cancelPendingDeleteInteractions()
func processDeleteMutationCallbackOutcome(_ outcome: DeleteMutationCallbackOutcome)
func resolvePendingDeleteInteractionsIfNeeded()
func drainPendingDeleteInteractionsIfPossible()
```

`cancelPendingDeleteInteractions()`는 coordinator cancellation 결과의 cleanup 신호가 `true`일 때만
overlay 숨김, `tempDeletedCharacters.removeAll()`, `deleteButtonPanDidStop()`을 실행한다.

- [x] **Step 1: 취소 전파·hook·cadence 통합 회귀 테스트 작성 및 커밋**

기존 `DeleteMutationLifecycleTests` 호출을 새 callback outcome에 맞게 갱신하고 다음 회귀를 추가한다.

```swift
@Test("released 요청의 관련 없는 callback은 cancelled outcome")
func testReleasedRequestUnrelatedCallbackCancelsGeneration() {
    var lifecycle = DeleteMutationLifecycle()
    let request = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
    _ = lifecycle.beginTouchDown(context: request, selectedText: nil)
    _ = lifecycle.capture(deletedText: "가", insertedText: "", reliability: .proxyContext)
    lifecycle.finishRepeatTracking()

    #expect(
        lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "새 입력"),
            currentSelectedText: nil
        ) == .cancelled
    )
}
```

Coordinator와 lifecycle을 함께 사용하는 test-local harness로 아래를 고정한다.

- `testNonDeleteBoundaryDoesNotReplayQueuedPan`
- `testViewStopDoesNotReplayQueuedPan`
- `testFocusChangeDoesNotMutateNewInputIdentifier`
- `testCancelledGenerationFinishesPanExactlyOnce`
- `testDeferredTouchDownRunsWillBodyDidHooksInOrder`
- `testSynchronousCallbackDoesNotOvertakeFIFO`

timer cadence 회귀는 action 하나를 새 delete 호출 수로 매핑해 다음 세 경우를 명시한다.

```swift
@Test("정상 반복 tick은 정확히 한 번이고 예외 tick은 누적하지 않음")
func testRepeatTickExactSingleDeleteContract() {
    func invocationCount(_ action: RepeatDeleteAction) -> Int {
        switch action {
        case .deleteAwaitingTextChange:
            return 1
        case .finishWithoutDeletion:
            return 0
        }
    }

    let before = KeyboardTextContextSnapshot(beforeInput: "가나", afterInput: "")
    let after = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")

    var idle = RepeatDeleteRequest()
    let idleTick = idle.actionForNextTick(
        currentContext: before,
        currentSelectedText: nil
    )

    var confirmed = RepeatDeleteRequest()
    confirmed.begin(context: before, selectedText: nil)
    _ = confirmed.capture(
        deletedText: "나",
        insertedText: "",
        reliability: .proxyContext
    )
    let confirmedTick = confirmed.actionForNextTick(
        currentContext: after,
        currentSelectedText: nil
    )

    var unconfirmed = RepeatDeleteRequest()
    unconfirmed.begin(context: before, selectedText: nil)
    _ = unconfirmed.capture(
        deletedText: "나",
        insertedText: "",
        reliability: .proxyContext
    )
    let exceptionalTick = unconfirmed.actionForNextTick(
        currentContext: before,
        currentSelectedText: nil
    )
    _ = unconfirmed.completeWithoutDeletion()
    let laterIndependentTick = unconfirmed.actionForNextTick(
        currentContext: before,
        currentSelectedText: nil
    )

    #expect(invocationCount(idleTick) == 1)
    #expect(invocationCount(confirmedTick) == 1)
    #expect(invocationCount(exceptionalTick) == 0)
    #expect(invocationCount(laterIndependentTick) == 1)
    #expect(
        [idleTick, confirmedTick, exceptionalTick, laterIndependentTick]
            .allSatisfy { invocationCount($0) <= 1 }
    )
}
```

test-local harness는 production 로직을 복제하지 않고 coordinator disposition/event와 lifecycle outcome을
기록하는 spy closure만 사용한다. raw `performDeleteButtonTextInteraction()` fallback을 기대하는 테스트는
두지 않는다.

Commit:

```sh
git add SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "test: #102 - 삭제 상호작용 통합 경계 회귀"
```

Result: 기존 `DeleteMutationLifecycleTests`의 callback 기대를
`DeleteMutationCallbackOutcome`의 `.noResolution`, `.resolved`, `.cancelled`로 갱신하고,
lifecycle 내부 deferred touchDown 저장소에 의존하던 테스트 2개를 coordinator 통합 경계 테스트로
대체했다. `testReleasedRequestUnrelatedCallbackCancelsGeneration`,
`testNonDeleteBoundaryDoesNotReplayQueuedPan`, `testViewStopDoesNotReplayQueuedPan`,
`testFocusChangeDoesNotMutateNewInputIdentifier`,
`testCancelledGenerationFinishesPanExactlyOnce`,
`testDeferredTouchDownRunsWillBodyDidHooksInOrder`,
`testSynchronousCallbackDoesNotOvertakeFIFO`,
`testRepeatTickExactSingleDeleteContract`를 추가했다. test-local harness는 실제
`DeleteInteractionCoordinator` disposition/event와 `DeleteMutationLifecycle` outcome을 사용하고,
semantic hook 및 pan cleanup만 배열/횟수 spy로 기록한다. raw delete body fallback 기대는 없다.
`git diff --check`는 통과했다.

- [x] **Step 2: Controller 통합 집중 테스트 RED 확인 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: `DeleteMutationCallbackOutcome` 부재 또는 기존 optional API와 새 outcome 기대 불일치로 compile
failure. 대표 오류와 exit code를 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "docs: #102 - 삭제 상호작용 통합 RED 검증"
```

Result: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard
-destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
-only-testing:SYKeyboardTests/DeleteMutationLifecycleTests
-only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests`를 실행했다.
iPhone 13 mini / iOS 16.0(arm64)에서 exit code 65의 compile RED를 확인했다. 대표 오류는
`Cannot find type 'DeleteMutationCallbackOutcome' in scope`이며 `SYKeyboardTests` module emission이
실패했다. sandbox/cache/CoreSimulator 오류 없이 의도한 코드 RED가 발생해 권한 있는 재실행은 하지
않았다.

- [x] **Step 3: Lifecycle outcome과 controller FIFO 통합 GREEN 및 커밋**

`DeleteMutationLifecycle`:

- `deferredTouchDownCount`와 `beginDeferredTouchDown`을 제거한다.
- callback 처리 결과를 `.noResolution`, `.resolved`, `.cancelled`로 구분한다. active request가 없거나
  callback-before-capture 관찰만 저장한 경우는 `.noResolution`이며 cancellation과 혼용하지 않는다.
- 관련 없는 released callback과 명시적 cancel은 stale request를 남기지 않는다.
- mutation/noDeletion 판정, repeat feedback 판정, timer action은 변경하지 않는다.

`BaseKeyboardViewController`:

- 세 개의 분리 저장소 `deferredDeleteButton`, `pendingDeletePanDirections`,
  `isDeleteButtonPanStopPending`을 하나의 `deleteInteractionCoordinator`로 교체한다.
- delete touchDown은 coordinator의 `.performNow`에서 lifecycle request를 mutation 전에 시작하고,
  `.enqueued`에서는 즉시 반환한다.
- replay touchDown은 strong target으로 `textInteractionWillPerform` → 기존 delete body →
  `textInteractionDidPerform`을 실행하며 raw body fallback은 만들지 않는다.
- pan과 pan stop은 `.performNow`일 때만 즉시 실행하고 `.enqueued`는 drain까지 기다린다.
- lifecycle의 positive mutation/noDeletion resolution만 현재 generation을 resolve한다.
- callback `.cancelled`, non-delete 입력, non-nil input identifier 변경, `viewWillDisappear`, 기본
  `stopRepeatInputTracking()`에서 lifecycle과 coordinator를 함께 취소한다.
- `preservingTouchDown: true`는 late callback 대기를 유지하므로 취소하지 않는다.
- drain guard와 dequeue-before-hook waiting 전환으로 동기 callback 재진입 순서를 보존한다.
- `finishDeleteButtonPanTracking()`은 coordinator가 반환한 cleanup 신호 또는 live pan stop에서만 호출한다.

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: 두 suite 전체 통과, 실패·skip 0개. parallel hang이면 Task 1과 같은 non-parallel fallback을
사용하고 두 결과를 기록한다.

Commit:

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "fix: #102 - 삭제 상호작용 순서와 취소 경계"
```

Result: `DeleteMutationCallbackOutcome`을 추가해 callback-before-capture/active request 없음은
`.noResolution`, positive mutation/noDeletion은 `.resolved`, 관련 없는 released callback은
`.cancelled`로 구분했다. lifecycle의 deferred touchDown count/API를 제거하고 controller의 분리된
touchDown/pan/pan-stop 저장소를 `DeleteInteractionCoordinator` 하나로 교체했다. replay touchDown은
strong target으로 will-body-did hook을 모두 실행하며, hook 전 dequeue/waiting 전환과 drain guard로
동기 callback FIFO를 보존한다. non-delete, input identifier 변경, view stop, 일반 repeat stop은
lifecycle/coordinator를 함께 취소하고 coordinator cleanup 신호가 `true`일 때만 overlay,
temporary buffer, pan-stop hook을 정리한다. timer interval과 `RepeatDeleteRequest`의 cadence 판정은
변경하지 않았다.

`xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard
-destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
-only-testing:SYKeyboardTests/DeleteMutationLifecycleTests
-only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests`는 iPhone 13 mini / iOS 16.0(arm64)에서
exit code 0, `TEST SUCCEEDED`였다. `.xcresult` 기준 27개 통과, 실패·skip 0개이며
`DeleteMutationCallbackOutcome` 세 분기와 cadence 회귀를 포함한다. 기본 parallel 실행은 멈추지 않아
fallback을 사용하지 않았다. `.xcresult` summary의 sandbox 읽기는 권한 오류가 발생해 동일한 read-only
명령만 권한 있는 환경에서 재실행했다.

- [x] **Step 4: 전체 테스트 검증 및 커밋**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 suite 통과. 기본 parallel 실행이 cloned Simulator 진단에서 멈추면
`-parallel-testing-enabled NO`를 추가해 재실행한다. sandbox/cache/CoreSimulator 오류가 나면 권한 있는
환경에서 동일 명령을 재실행한다. 최초 실패와 최종 결과를 모두 Result와
`/private/tmp/sykeyboard-final-review-fix-report.md`에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "docs: #102 - 삭제 상호작용 전체 테스트 검증"
```

Result: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard
-destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 fresh 실행했다. iPhone 13 mini /
iOS 16.0(arm64)에서 exit code 0, `TEST SUCCEEDED`였고 `.xcresult` 기준 36 suites, 313개 테스트
전체 통과, 실패·skip 0개였다. 기본 parallel 실행이 cloned Simulator에서 멈추지 않아
`-parallel-testing-enabled NO` fallback은 사용하지 않았다. xcodebuild 자체의
sandbox/cache/CoreSimulator 실패는 없었다. `.xcresult` summary는 sandbox 내부 읽기 권한 오류가
있어 동일한 read-only `xcresulttool` 집계 명령만 권한 있는 환경에서 실행했다. 최초 결과와 집계는
`/private/tmp/sykeyboard-final-review-fix-report.md`에도 기록했다.

- [x] **Step 5: 양쪽 extension 빌드 검증 및 커밋**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 scheme 모두 `BUILD SUCCEEDED`. sandbox/cache/CoreSimulator 오류는 권한 있는 동일 명령으로
재실행해 환경 실패와 코드 실패를 구분한다. 결과를 계획과
`/private/tmp/sykeyboard-final-review-fix-report.md`에 기록한다.

Commit:

```sh
git add docs/superpowers/plans/2026-07-26-delete-interaction-coordinator.md
git commit -m "docs: #102 - 삭제 상호작용 extension 빌드 검증"
```

Result: iPhone 13 mini / iOS 16.0(arm64)을 대상으로 두 scheme을 검증했다.
`HangeulKeyboard` sandbox 실행은 CoreSimulatorService 연결과 SwiftPM/clang cache
`Operation not permitted`로 exit code 74였고, 권한 있는 환경에서 동일 명령을 재실행해 exit code 0,
`BUILD SUCCEEDED`를 확인했다. `EnglishKeyboard`도 sandbox에서 같은 환경 오류로 exit code 74였으며,
권한 있는 동일 명령은 exit code 0, `BUILD SUCCEEDED`였다. 최초 환경 실패와 두 최종 빌드 결과를
`/private/tmp/sykeyboard-final-review-fix-report.md`에 기록했다.

### Fix Round 1: Suggestion·Undo/Redo 직접 편집 경계와 noDeletion 피드백

- [x] Suggestion 선택과 Undo/Redo 직접 편집 전에 lifecycle/coordinator 공통 cancellation boundary 적용
- [x] released repeat `.noDeletion`의 feedback·Undo 미기록 회귀 추가
- [x] focused lifecycle/coordinator 및 전체 `SYKeyboard` 테스트 재검증

Result: `DeleteInteractionNonDeleteMutationBoundary`를 production 정책으로 추가하고 controller의 기존
`cancelPendingDeleteInteractions()`가 이 정책을 사용하게 했다. SuggestionBar 선택 entry와
`performUndo()`/`performRedo()` entry는 실제 proxy 편집 전에 공통 경계를 호출한다. 이 경계는 pending
lifecycle capture와 coordinator generation/FIFO를 함께 폐기하며 기존 Undo/Redo manager 자체는
변경하지 않는다. `DeleteMutationLifecycle.resolve`의 repeat feedback은 completion이 실제
`.mutations`인 경우로 제한해 released repeat `.noDeletion`은 queue resolution만 수행한다.

RED focused 명령은
`xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination
'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
-only-testing:SYKeyboardTests/DeleteMutationLifecycleTests
-only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests`였다. 첫 실행은 exit code 65,
`Cannot find 'DeleteInteractionNonDeleteMutationBoundary' in scope` compile RED였다. boundary seam만
추가한 두 번째 기본 parallel 실행에서는
`testReleasedRepeatNoDeletionDoesNotRecordFeedbackOrUndo`가 실제 assertion RED를 냈고, cloned
Simulator가 result finalization에서 멈춰 실행을 종료했다. Undo/Redo 회귀의 최초 실패는 production
오류가 아니라 기존 manager가 `updateLastRedoTargetContext` 호출 전 redo target을 `nil`로 유지하는
계약을 테스트가 잘못 기대한 것이어서 해당 literal만 기존 계약에 맞췄다.

GREEN focused sandbox 실행은 CoreSimulatorService/SwiftPM/clang cache 권한 오류로 exit code 74였다.
동일 명령에 `-parallel-testing-enabled NO`를 추가해 권한 있는 환경에서 재실행했고 iPhone 13 mini /
iOS 16.0(arm64)에서 exit code 0, `TEST SUCCEEDED`, 2 suites / 30 tests 전체 통과,
실패·skip 0개였다. fresh 전체 명령
`xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination
'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`은 기본 parallel로 exit code 0,
`TEST SUCCEEDED`였고 `.xcresult` 기준 316 tests passed, 실패·skip 0개였다.

### Final Review Fix Wave: active callback 취소와 replay pan cleanup

- [x] active `.touchDown`/`.repeatTick`이 mutation capture 뒤 관련 없는 `textDidChange(_:)`를 받으면
  `.cancelled`로 lifecycle과 generation/FIFO를 함께 정리
- [x] callback-before-capture observation과 정상 delete resolution 보존
- [x] `pan → panStop → touchDown → pan` FIFO에서 마지막 replay pan이 cleanup 소유권을 다시 활성화
- [x] lifecycle/coordinator focused 및 fresh 전체 테스트, 양쪽 extension 빌드 재검증

Fix base는 `62a80a58b9d851bceea1f6eff51405dc84db47ff`다. RED focused 실행은 test-only
actor/mutating macro compile 오류를 먼저 바로잡은 뒤 iPhone 13 mini / iOS 16.0에서 실제 동작 실패를
확인했다. 2 suites / 32 tests 중 새 active callback 회귀는 `.noResolution`, 남은 generation,
pan cleanup 미실행으로 실패했고, 교차 pan-session 회귀는 cancellation의
`shouldFinishPanTracking == false`로 실패했다. 실패 실행은 assertions 출력 뒤 Xcode result
finalization이 멈춰 해당 PID만 종료했다.

production에서는 capture된 draft 존재 여부를 lifecycle에 노출하고 active request의 확인 실패만
명시적으로 취소한다. capture 전 callback은 기존 observation 경로를 유지하고, 정상 mutation과
released no-deletion 처리는 기존 resolution 순서를 유지한다. coordinator는 queued `.pan`을 실제
dequeue할 때 `isPanTrackingActive`를 다시 `true`로 설정한다.

GREEN focused 권한 실행은 iPhone 13 mini / iOS 16.0(arm64)에서 exit code 0,
`TEST SUCCEEDED`, 2 suites / 32 tests passed, 실패·skip 0개였다. fresh 전체 기본 parallel 실행도
exit code 0, `TEST SUCCEEDED`였고 `.xcresult` 기준 318 tests passed, 실패·skip 0개였다.
`HangeulKeyboard`와 `EnglishKeyboard`의 sandbox build는 CoreSimulatorService와 SwiftPM/clang
cache 권한 오류로 각각 exit code 74였고, 권한 있는 동일 destination build는 각각 exit code 0,
`BUILD SUCCEEDED`였다.

---

## 완료 조건

- 보류 touchDown, pan 방향, pan stop이 실제 도착 순서대로 재생된다.
- replay touchDown이 strong target과 전체 base/Hangeul semantic hook을 사용한다.
- 취소된 queue가 non-delete 입력, 새 focus, 화면 재진입 뒤 재생되지 않는다.
- pan cleanup이 취소 generation당 정확히 한 번 실행된다.
- 늦은 resolution이 취소 generation이나 새 입력 대상의 FIFO를 열지 않는다.
- 동기 callback 재진입이 현재 touchDown보다 다음 event를 먼저 실행하지 않는다.
- 정상 반복 상태에서 매 timer tick마다 새 delete가 정확히 한 번 발생한다.
- 문서 시작·확인 실패 tick은 delete 0회이며 다음 tick 보충 실행이 없다.
- 어느 timer tick에서도 새 delete가 두 번 이상 발생하지 않는다.
- 기존 lifecycle 집중 테스트와 전체 `SYKeyboard` 테스트가 통과한다.
- `HangeulKeyboard`와 `EnglishKeyboard`가 빌드된다.
- Messages 8개 항목과 실제 사운드·햅틱은 사용자가 확인하기 전까지 `검증 대기`로 남는다.

## 수동 검증 대기

자동 검증 완료 뒤에도 다음 항목을 통과로 표시하지 않는다.

1. Messages 여러 줄에서 delete drag 좌우 왕복
2. 한글·영문에서 문서 끝까지 long delete
3. 삭제 가능한 동안 기존 cadence와 동일한 체감 속도
4. 정상 반복 상태에서 timer tick당 실제 delete 한 번
5. Undo 원문 복원
6. Redo 재삭제
7. 선택 텍스트 삭제 Undo/Redo
8. 문서 시작에서 버튼 UI, 사운드, 햅틱 종료
