//
//  DeleteInteractionCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing

@testable import SYKeyboardCore

@MainActor
@Suite("Delete interaction coordinator")
struct DeleteInteractionCoordinatorTests {

    @Test("released touchDown callback 누락 뒤 다음 단일 탭은 이전 요청을 확정하고 한 번 실행")
    func testReleasedTouchDownMissingCallbackRecoversOnNextTap() throws {
        var coordinator = DeleteInteractionCoordinator()
        var lifecycle = DeleteMutationLifecycle()
        let button = DeleteButton(keyboard: .dubeolsik)
        let beforeDeletion = KeyboardTextContextSnapshot(beforeInput: "1 1 ", afterInput: "")
        let afterDeletion = KeyboardTextContextSnapshot(beforeInput: "1 1", afterInput: "")
        let expectedDraft = RepeatDeleteMutationDraft(
            deletedText: " ",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(coordinator.beginTouchDown(button: button, inputIdentifier: nil) == .performNow)
        #expect(lifecycle.beginTouchDown(context: beforeDeletion, selectedText: nil) == .started)
        #expect(
            lifecycle.capture(
                deletedText: expectedDraft.deletedText,
                insertedText: expectedDraft.insertedText,
                reliability: expectedDraft.reliability
            ) == .awaitingTextChange
        )
        #expect(
            lifecycle.finishTouchDown(
                currentContext: beforeDeletion,
                currentSelectedText: nil
            ) == nil
        )
        #expect(lifecycle.isPending)

        let recoveredResolution = lifecycle.completeReleasedTouchDownAtCheckpoint(
            currentContext: afterDeletion,
            currentSelectedText: nil
        )
        #expect(
            recoveredResolution == DeleteMutationResolution(
                completion: .mutations([expectedDraft]),
                origin: .touchDown,
                shouldPlayFeedback: false
            )
        )
        #expect(
            lifecycle.completeAfterTextChange(
                currentContext: afterDeletion,
                currentSelectedText: nil
            ) == .noResolution
        )

        let generation = try #require(coordinator.currentGeneration)
        let didResolve = coordinator.resolve(generation)
        #expect(didResolve)
        #expect(coordinator.beginTouchDown(button: button, inputIdentifier: nil) == .performNow)
        #expect(lifecycle.beginTouchDown(context: afterDeletion, selectedText: nil) == .started)
    }

    @Test("released touchDown checkpoint 문맥이 불확실하면 다음 단일 탭을 보류")
    func testReleasedTouchDownUnconfirmedCheckpointKeepsNextTapEnqueued() {
        var coordinator = DeleteInteractionCoordinator()
        var lifecycle = DeleteMutationLifecycle()
        let button = DeleteButton(keyboard: .dubeolsik)
        let staleContext = KeyboardTextContextSnapshot(beforeInput: "1 1 ", afterInput: "")

        #expect(coordinator.beginTouchDown(button: button, inputIdentifier: nil) == .performNow)
        #expect(lifecycle.beginTouchDown(context: staleContext, selectedText: nil) == .started)
        #expect(
            lifecycle.capture(
                deletedText: " ",
                insertedText: "",
                reliability: .proxyContext
            ) == .awaitingTextChange
        )
        #expect(
            lifecycle.finishTouchDown(
                currentContext: staleContext,
                currentSelectedText: nil
            ) == nil
        )

        #expect(
            lifecycle.completeReleasedTouchDownAtCheckpoint(
                currentContext: staleContext,
                currentSelectedText: nil
            ) == nil
        )
        #expect(coordinator.beginTouchDown(button: button, inputIdentifier: nil) == .enqueued)
        #expect(lifecycle.isPending)
    }

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
            coordinator.beginTouchDown(
                button: nextButton,
                inputIdentifier: nil
            ) == .enqueued
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

    @Test("panStop 뒤 late callback이 줄바꿈을 확정한 후 tracking을 종료")
    func testPanStopBeforeLateCallbackConfirmsNewlineAndFinishesTracking() {
        var harness = DeleteInteractionStateHarness()
        let requestContext = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "라마바")

        let didBeginBoundary = harness.beginPanBoundary(context: requestContext)
        let stopDisposition = harness.enqueuePanStop()
        let releaseResolution = harness.lifecycle.finishPanBoundary(
            currentContext: requestContext,
            currentSelectedText: nil
        )
        #expect(didBeginBoundary)
        #expect(stopDisposition == .enqueued)
        #expect(releaseResolution == nil)
        #expect(harness.lifecycle.isPending)
        #expect(harness.coordinator.isWaitingForResolution)

        let outcome = harness.completeAfterTextChange(
            context: KeyboardTextContextSnapshot(
                beforeInput: "가나다",
                afterInput: "라마바"
            )
        )
        harness.process(outcome)
        harness.drain { harness, event in
            guard case .panStop = event else {
                Issue.record("late callback 뒤 panStop 이외 이벤트가 재생됨")
                return
            }
            harness.panFinishCount += 1
        }

        #expect(harness.tempDeletedCharacters == ["\n"])
        #expect(harness.panFinishCount == 1)
        #expect(harness.lifecycle.isPending == false)
        #expect(harness.coordinator.currentGeneration == nil)
        #expect(harness.coordinator.isWaitingForResolution == false)
    }

    @Test("문서 시작 panStop no-op은 후속 checkpoint에서 coordinator를 정리")
    func testDocumentStartPanStopNoOpCheckpointCleansCoordinator() {
        var harness = DeleteInteractionStateHarness()
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "가나다")

        let didBeginBoundary = harness.beginPanBoundary(context: context)
        let stopDisposition = harness.enqueuePanStop()
        let releaseResolution = harness.lifecycle.finishPanBoundary(
            currentContext: context,
            currentSelectedText: nil
        )
        #expect(didBeginBoundary)
        #expect(stopDisposition == .enqueued)
        #expect(releaseResolution == nil)

        let resolution = harness.lifecycle.completeAtCheckpoint(
            currentContext: context,
            currentSelectedText: nil
        )
        #expect(
            resolution == DeleteMutationResolution(
                completion: .noDeletion,
                origin: .panBoundary,
                shouldPlayFeedback: false
            )
        )
        if let resolution {
            harness.process(.resolved(resolution))
        }
        harness.drain { harness, event in
            guard case .panStop = event else {
                Issue.record("no-op checkpoint 뒤 panStop 이외 이벤트가 재생됨")
                return
            }
            harness.panFinishCount += 1
        }

        #expect(harness.panFinishCount == 1)
        #expect(harness.lifecycle.isPending == false)
        #expect(harness.coordinator.currentGeneration == nil)
        #expect(harness.coordinator.isWaitingForResolution == false)
    }

    @Test("문서 시작 no-op pan 경계가 확정되면 보류된 선행 left는 버리고 right부터 재생")
    func testNoOpPanBoundaryResolutionDiscardsLeadingLeftThroughHarness() {
        var harness = DeleteInteractionStateHarness()
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "가나다")

        let didBeginBoundary = harness.beginPanBoundary(context: context)
        let dispositions = [
            harness.enqueuePan(.left),
            harness.enqueuePan(.right),
            harness.enqueuePan(.left),
            harness.enqueuePanStop()
        ]
        let releaseResolution = harness.lifecycle.finishPanBoundary(
            currentContext: context,
            currentSelectedText: nil
        )
        #expect(didBeginBoundary)
        #expect(dispositions == [.enqueued, .enqueued, .enqueued, .enqueued])
        #expect(releaseResolution == nil)

        let resolution = harness.lifecycle.completeAtCheckpoint(
            currentContext: context,
            currentSelectedText: nil
        )
        #expect(resolution?.completion == .noDeletion)
        if let resolution {
            harness.process(.resolved(resolution))
        }
        harness.drain { _, _ in }

        #expect(harness.observedEvents == ["pan:right", "pan:left", "panStop"])
        #expect(harness.coordinator.currentGeneration == nil)
    }

    @Test("pan boundary 확인 전 이벤트는 FIFO이고 noDeletion은 앞쪽 left만 폐기")
    func testPanBoundaryFIFOAndNoOpLeftDiscard() throws {
        var coordinator = DeleteInteractionCoordinator()

        #expect(coordinator.enqueuePan(.left) == .performNow)
        let pendingGeneration = coordinator.beginPanBoundaryMutation(inputIdentifier: nil)
        let generation = try #require(pendingGeneration)
        #expect(coordinator.isWaitingForResolution)
        #expect(coordinator.enqueuePan(.left) == .enqueued)
        #expect(coordinator.enqueuePan(.left) == .enqueued)
        #expect(coordinator.enqueuePan(.right) == .enqueued)
        #expect(coordinator.enqueuePan(.left) == .enqueued)
        #expect(coordinator.enqueuePanStop() == .enqueued)

        let didResolve = coordinator.resolve(
            generation,
            discardingLeadingNoOpPanLeft: true
        )
        #expect(didResolve)
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

    @Test("pan과 stop 뒤의 touchDown을 도착 순서대로 재생")
    func testFIFOOrder() throws {
        var coordinator = DeleteInteractionCoordinator()
        let first = DeleteButton(keyboard: .dubeolsik)
        let second = DeleteButton(keyboard: .dubeolsik)

        #expect(coordinator.beginTouchDown(button: first, inputIdentifier: nil) == .performNow)
        #expect(coordinator.enqueuePan(.left) == .enqueued)
        #expect(coordinator.enqueuePanStop() == .enqueued)
        #expect(coordinator.beginTouchDown(button: second, inputIdentifier: nil) == .enqueued)

        let generation = try #require(coordinator.currentGeneration)
        let didResolve = coordinator.resolve(generation)
        #expect(didResolve)

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
        let button = DeleteButton(keyboard: .dubeolsik)
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
        let button = DeleteButton(keyboard: .dubeolsik)
        let firstInput = DeleteButton(keyboard: .dubeolsik)
        let secondInput = DeleteButton(keyboard: .dubeolsik)
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
        let first = DeleteButton(keyboard: .dubeolsik)
        var second: DeleteButton? = DeleteButton(keyboard: .dubeolsik)
        weak var weakSecond: DeleteButton?
        weakSecond = second
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
        let first = DeleteButton(keyboard: .dubeolsik)
        let second = DeleteButton(keyboard: .dubeolsik)
        _ = coordinator.beginTouchDown(button: first, inputIdentifier: nil)
        _ = coordinator.beginTouchDown(button: second, inputIdentifier: nil)
        _ = coordinator.enqueuePan(.right)
        let generation = try #require(coordinator.currentGeneration)
        let didResolve = coordinator.resolve(generation)
        #expect(didResolve)

        guard case .touchDown? = coordinator.nextReadyEvent() else {
            Issue.record("첫 replay event가 touchDown이 아님")
            return
        }
        #expect(coordinator.isWaitingForResolution)
        #expect(coordinator.nextReadyEvent() == nil)
        let didReplayResolve = coordinator.resolve(generation)
        #expect(didReplayResolve)
        guard case .pan(let direction)? = coordinator.nextReadyEvent(),
              case .right = direction else {
            Issue.record("touchDown resolution 뒤 right pan이 열리지 않음")
            return
        }
    }

    @Test("pan-stop-touchDown 뒤 replay pan 취소는 새 pan cleanup을 정확히 한 번 요청")
    func testReplayedPanAfterStopReactivatesCleanupOwnership() throws {
        var coordinator = DeleteInteractionCoordinator()
        let first = DeleteButton(keyboard: .dubeolsik)
        let second = DeleteButton(keyboard: .dubeolsik)
        _ = coordinator.beginTouchDown(button: first, inputIdentifier: nil)
        _ = coordinator.enqueuePan(.left)
        _ = coordinator.enqueuePanStop()
        _ = coordinator.beginTouchDown(button: second, inputIdentifier: nil)
        _ = coordinator.enqueuePan(.right)
        let generation = try #require(coordinator.currentGeneration)

        let didResolveFirstRequest = coordinator.resolve(generation)
        #expect(didResolveFirstRequest)
        guard case .pan(.left)? = coordinator.nextReadyEvent() else {
            Issue.record("첫 replay event가 left pan이 아님")
            return
        }
        guard case .panStop? = coordinator.nextReadyEvent() else {
            Issue.record("두 번째 replay event가 panStop이 아님")
            return
        }
        guard case .touchDown? = coordinator.nextReadyEvent() else {
            Issue.record("세 번째 replay event가 touchDown이 아님")
            return
        }
        let didResolveSecondRequest = coordinator.resolve(generation)
        #expect(didResolveSecondRequest)
        guard case .pan(.right)? = coordinator.nextReadyEvent() else {
            Issue.record("네 번째 replay event가 right pan이 아님")
            return
        }

        #expect(coordinator.cancel().shouldFinishPanTracking)
        #expect(coordinator.cancel().shouldFinishPanTracking == false)
    }

    @Test("non-delete mutation 경계는 lifecycle과 coordinator를 함께 취소")
    func testNonDeleteMutationBoundaryCancelsLifecycleAndCoordinator() {
        var harness = DeleteInteractionStateHarness()
        let button = DeleteButton(keyboard: .dubeolsik)
        let context = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
        _ = harness.beginTouchDown(button: button, context: context)
        _ = harness.capture(deletedText: "가")
        #expect(harness.enqueuePan(.left) == .enqueued)

        harness.cancelForDirectNonDeleteMutation()
        let lateOutcome = harness.completeAfterTextChange(
            context: KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        )
        harness.process(lateOutcome)
        harness.drain { _, _ in
            Issue.record("취소된 pan이 재생됨")
        }

        #expect(harness.lifecycle.isPending == false)
        #expect(harness.coordinator.currentGeneration == nil)
        #expect(harness.observedEvents.isEmpty)
        #expect(harness.panFinishCount == 1)
    }

    @Test("focus 변경 뒤 늦은 callback은 새 입력 대상을 mutate하지 않음")
    func testFocusChangeDoesNotMutateNewInputIdentifier() {
        var harness = DeleteInteractionStateHarness()
        let button = DeleteButton(keyboard: .dubeolsik)
        let firstInput = DeleteButton(keyboard: .dubeolsik)
        let secondInput = DeleteButton(keyboard: .dubeolsik)
        let context = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
        _ = harness.beginTouchDown(
            button: button,
            inputIdentifier: ObjectIdentifier(firstInput),
            context: context
        )
        _ = harness.capture(deletedText: "가")
        #expect(harness.enqueuePan(.left) == .enqueued)

        harness.cancelForInputIdentifierChange(to: ObjectIdentifier(secondInput))
        #expect(
            harness.beginTouchDown(
                button: button,
                inputIdentifier: ObjectIdentifier(secondInput),
                context: KeyboardTextContextSnapshot(beforeInput: "새", afterInput: "")
            ) == .performNow
        )

        let lateOutcome = harness.completeAfterTextChange(
            context: KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        )
        harness.process(lateOutcome)
        harness.drain { _, _ in
            Issue.record("이전 focus callback이 새 입력 대상 queue를 열었음")
        }

        #expect(lateOutcome == .noResolution)
        #expect(harness.coordinator.isWaitingForResolution)
        #expect(harness.observedEvents.isEmpty)
    }

}

/// `DeleteMutationLifecycleTests`의 통합 시나리오도 함께 쓰므로 파일 밖에서 보이게 둔다
@MainActor
/// `DeleteInteractionCoordinator`와 `DeleteMutationLifecycle`을 VC와 같은 순서로 묶어 돌리는 조합 상태 harness.
///
/// proxy·피드백·undo 기록은 없다. resolution의 효과와 취소 경계는 VC와 같은 production policy
/// (`KeyboardTextInteractionPolicy.mutationResolutionEffects`, `DeleteInteraction*Boundary`)로 계산한다
struct DeleteInteractionStateHarness {
    var coordinator = DeleteInteractionCoordinator()
    var lifecycle = DeleteMutationLifecycle()
    var observedDispositions: [DeleteInteractionDisposition] = []
    var observedEvents: [String] = []
    var observedOutcomes: [DeleteMutationCallbackOutcome] = []
    /// VC의 `tempDeletedCharacters`에 해당
    var tempDeletedCharacters: [Character] = []
    /// production이 pan tracking 종료를 요구한 횟수(`shouldFinishPanTracking`과 재생된 panStop)
    var panFinishCount = 0

    private var isDraining = false

    mutating func beginTouchDown(
        button: any TextInteractable,
        inputIdentifier: ObjectIdentifier? = nil,
        context: KeyboardTextContextSnapshot
    ) -> DeleteInteractionDisposition {
        let disposition = coordinator.beginTouchDown(
            button: button,
            inputIdentifier: inputIdentifier
        )
        observedDispositions.append(disposition)
        if disposition == .performNow {
            _ = lifecycle.beginTouchDown(context: context, selectedText: nil)
        }
        return disposition
    }

    mutating func beginPanBoundary(
        context: KeyboardTextContextSnapshot
    ) -> Bool {
        guard coordinator.beginPanBoundaryMutation(inputIdentifier: nil) != nil else {
            return false
        }
        guard lifecycle.beginPanBoundary(context: context, selectedText: nil) == .started else {
            _ = coordinator.cancel()
            lifecycle.cancel()
            return false
        }
        _ = lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        return true
    }

    mutating func capture(deletedText: String) -> DeleteMutationCaptureResult? {
        return lifecycle.capture(
            deletedText: deletedText,
            insertedText: "",
            reliability: .proxyContext
        )
    }

    mutating func enqueuePan(_ direction: PanDirection) -> DeleteInteractionDisposition {
        let disposition = coordinator.enqueuePan(direction)
        observedDispositions.append(disposition)
        return disposition
    }

    mutating func enqueuePanStop() -> DeleteInteractionDisposition {
        let disposition = coordinator.enqueuePanStop()
        observedDispositions.append(disposition)
        return disposition
    }

    mutating func completeAfterTextChange(
        context: KeyboardTextContextSnapshot
    ) -> DeleteMutationCallbackOutcome {
        let outcome = lifecycle.completeAfterTextChange(
            currentContext: context,
            currentSelectedText: nil
        )
        observedOutcomes.append(outcome)
        return outcome
    }

    mutating func process(_ outcome: DeleteMutationCallbackOutcome) {
        switch outcome {
        case .noResolution:
            return
        case .resolved(let resolution):
            let effects = KeyboardTextInteractionPolicy.mutationResolutionEffects(resolution)
            tempDeletedCharacters.append(contentsOf: effects.restorableCharacters)
            guard let generation = coordinator.currentGeneration else { return }
            _ = coordinator.resolve(
                generation,
                discardingLeadingNoOpPanLeft: effects.discardsLeadingNoOpPanLeft
            )
        case .cancelled:
            cancel()
        }
    }

    mutating func cancelForDirectNonDeleteMutation() {
        finishPanIfNeeded(
            DeleteInteractionNonDeleteMutationBoundary.cancel(
                lifecycle: &lifecycle,
                coordinator: &coordinator
            )
        )
    }

    mutating func cancelForInputIdentifierChange(to inputIdentifier: ObjectIdentifier?) {
        guard let result = DeleteInteractionInputChangeBoundary.cancelIfInputIdentifierChanged(
            to: inputIdentifier,
            lifecycle: &lifecycle,
            coordinator: &coordinator
        ) else { return }
        finishPanIfNeeded(result)
    }

    mutating func cancel() {
        lifecycle.cancel()
        finishPanIfNeeded(coordinator.cancel())
    }

    mutating func drain(
        handle: (inout DeleteInteractionStateHarness, PendingDeleteInteractionEvent) -> Void
    ) {
        guard !isDraining else { return }

        isDraining = true
        defer { isDraining = false }
        while let event = coordinator.nextReadyEvent() {
            record(event)
            handle(&self, event)
        }
    }

    mutating func record(_ event: PendingDeleteInteractionEvent) {
        switch event {
        case .touchDown:
            observedEvents.append("touchDown")
        case .pan(let direction):
            observedEvents.append("pan:\(String(describing: direction))")
        case .panStop:
            observedEvents.append("panStop")
        }
    }

    private mutating func finishPanIfNeeded(_ result: DeleteInteractionCancellationResult) {
        guard result.shouldFinishPanTracking else { return }
        panFinishCount += 1
    }
}
