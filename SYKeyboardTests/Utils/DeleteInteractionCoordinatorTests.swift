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

}
