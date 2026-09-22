//
//  DeleteMutationLifecycleTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("삭제 mutation lifecycle 검증")
struct DeleteMutationLifecycleTests {

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

    @Test("pan boundary callback 시 선택 텍스트가 생기면 줄바꿈 추론을 취소")
    func testPanBoundaryCallbackSelectionCancelsNewlineInference() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "라마바")
        _ = lifecycle.beginPanBoundary(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            lifecycle.completeAfterTextChange(
                currentContext: context,
                currentSelectedText: "선택"
            ) == .cancelled
        )
        #expect(lifecycle.isPending == false)
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

    @Test("released pan boundary는 후속 checkpoint에서 noDeletion")
    func testReleasedPanBoundaryLaterCheckpointIsNoDeletion() {
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
            ) == nil
        )
        #expect(lifecycle.isPending)
        #expect(
            lifecycle.completeAtCheckpoint(
                currentContext: context,
                currentSelectedText: nil
            ) == DeleteMutationResolution(
                completion: .noDeletion,
                origin: .panBoundary,
                shouldPlayFeedback: false
            )
        )
        #expect(lifecycle.isPending == false)
    }

    @Test("touchDown capture 후 callback은 반복 상태 전에도 줄바꿈을 확정")
    func testTouchDown_Capture후Callback_줄바꿈확정() {
        var lifecycle = DeleteMutationLifecycle()
        lifecycle.beginTouchDown(
            context: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            selectedText: nil
        )

        let captureResult = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        let outcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )

        #expect(captureResult == .awaitingTextChange)
        #expect(
            outcome
            == .resolved(
                DeleteMutationResolution(
                completion: .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: "\n",
                        insertedText: "",
                        reliability: .authoritative
                    )
                ]),
                origin: .touchDown,
                shouldPlayFeedback: false
                )
            )
        )
        #expect(lifecycle.isPending == false)
    }

    @Test("touchDown callback 후 capture도 줄바꿈을 한 번만 확정")
    func testTouchDown_Callback후Capture_줄바꿈확정() {
        var lifecycle = DeleteMutationLifecycle()
        lifecycle.beginTouchDown(
            context: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            selectedText: nil
        )

        let callbackOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )
        let captureResult = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        let duplicateOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )

        #expect(callbackOutcome == .noResolution)
        #expect(
            captureResult
            == .completion(
                DeleteMutationResolution(
                    completion: .mutations([
                        RepeatDeleteMutationDraft(
                            deletedText: "\n",
                            insertedText: "",
                            reliability: .authoritative
                        )
                    ]),
                    origin: .touchDown,
                    shouldPlayFeedback: false
                )
            )
        )
        #expect(duplicateOutcome == .noResolution)
        #expect(lifecycle.isPending == false)
    }

    @Test("tap release가 callback보다 먼저 와도 실제 줄바꿈 삭제를 보존")
    func testTouchDown_Release후Callback_줄바꿈확정() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        lifecycle.beginTouchDown(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )

        let releaseResolution = lifecycle.finishTouchDown(
            currentContext: context,
            currentSelectedText: nil
        )

        #expect(releaseResolution == nil)
        #expect(lifecycle.isPending == true)
        #expect(
            lifecycle.completeAfterTextChange(
                currentContext: context,
                currentSelectedText: nil
            )
            == .resolved(
                DeleteMutationResolution(
                completion: .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: "\n",
                        insertedText: "",
                        reliability: .authoritative
                    )
                ]),
                origin: .touchDown,
                shouldPlayFeedback: false
                )
            )
        )
        #expect(lifecycle.isPending == false)
    }

    @Test("문서 시작점 tap release는 callback 없이 삭제 없음으로 확정")
    func testTouchDown_문서시작점Release_삭제없음확정() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: nil, afterInput: "")
        #expect(
            lifecycle.beginTouchDown(context: context, selectedText: nil)
            == .started
        )
        _ = lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )

        let resolution = lifecycle.finishTouchDown(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "", afterInput: nil),
            currentSelectedText: ""
        )

        #expect(
            resolution
            == DeleteMutationResolution(
                completion: .noDeletion,
                origin: .touchDown,
                shouldPlayFeedback: false
            )
        )
        #expect(lifecycle.isPending == false)

        var noDraftLifecycle = DeleteMutationLifecycle()
        _ = noDraftLifecycle.beginTouchDown(context: context, selectedText: nil)
        #expect(
            noDraftLifecycle.finishTouchDown(
                currentContext: context,
                currentSelectedText: nil
            )?.completion == .noDeletion
        )
        #expect(noDraftLifecycle.isPending == false)

        var lineBoundaryLifecycle = DeleteMutationLifecycle()
        let lineBoundaryContext = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        _ = lineBoundaryLifecycle.beginTouchDown(
            context: lineBoundaryContext,
            selectedText: nil
        )
        #expect(
            lineBoundaryLifecycle.finishTouchDown(
                currentContext: lineBoundaryContext,
                currentSelectedText: nil
            ) == nil
        )
        #expect(lineBoundaryLifecycle.isPending)
    }

    @Test("문서 시작점 long press는 한글 즉시 경로와 영문 timer 경로를 모두 종료")
    func testLongPress_문서시작점_즉시와Timer경로종료() {
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")

        var hangeulLifecycle = DeleteMutationLifecycle()
        _ = hangeulLifecycle.beginTouchDown(context: context, selectedText: nil)
        _ = hangeulLifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            hangeulLifecycle.actionForNextRepeat(
                currentContext: context,
                currentSelectedText: nil
            ) == .finishWithoutDeletion
        )
        #expect(
            hangeulLifecycle.completeWithoutDeletion()
            == .noDeletion
        )
        #expect(hangeulLifecycle.isPending == false)

        var englishLifecycle = DeleteMutationLifecycle()
        _ = englishLifecycle.beginTouchDown(context: context, selectedText: nil)
        _ = englishLifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        _ = englishLifecycle.finishTouchDown(
            currentContext: context,
            currentSelectedText: nil
        )

        #expect(
            englishLifecycle.actionForNextRepeat(
                currentContext: context,
                currentSelectedText: nil
            ) == .finishWithoutDeletion
        )
        _ = englishLifecycle.completeWithoutDeletion()
        #expect(englishLifecycle.isPending == false)
    }

    @Test("문서 시작점이어도 비어 있지 않은 proxy 후보는 늦은 callback을 기다림")
    func testTouchDown_문서시작점_비어있지않은후보는대기() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        _ = lifecycle.beginTouchDown(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            lifecycle.finishTouchDown(
                currentContext: context,
                currentSelectedText: nil
            ) == nil
        )
        #expect(
            lifecycle.actionForNextRepeat(
                currentContext: context,
                currentSelectedText: nil
            ) == .awaitingPreviousMutation
        )
        #expect(lifecycle.isPending)
    }

    @Test("영문 long press는 release 전환 뒤 늦은 callback을 기다렸다가 timer repeat를 시작")
    func test영문_Release후늦은Callback_TimerRepeat전환() {
        var lifecycle = DeleteMutationLifecycle()
        lifecycle.beginTouchDown(
            context: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            selectedText: nil
        )
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        _ = lifecycle.finishTouchDown(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )
        let waitingTickAction = lifecycle.actionForNextRepeat(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )
        let touchDownResolution = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        ).resolution
        let deletingTickAction = lifecycle.actionForNextRepeat(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            currentSelectedText: nil
        )
        lifecycle.beginRepeat(
            context: KeyboardTextContextSnapshot(beforeInput: "바", afterInput: ""),
            selectedText: nil
        )
        let repeatCapture = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        let repeatResolution = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "", afterInput: ""),
            currentSelectedText: nil
        ).resolution

        #expect(touchDownResolution?.shouldPlayFeedback == false)
        #expect(waitingTickAction == .awaitingPreviousMutation)
        #expect(deletingTickAction == .deleteAwaitingTextChange(previousResolution: nil))
        #expect(repeatCapture == .awaitingTextChange)
        #expect(repeatResolution?.shouldPlayFeedback == true)
        #expect(
            repeatResolution?.completion
            == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "바",
                    insertedText: "",
                    reliability: .proxyContext
                )
            ])
        )
    }

    @Test("한글 long press는 늦은 callback 전 즉시 전환에서 요청을 버리지 않음")
    func test한글_늦은Callback전즉시Repeat전환() {
        var lifecycle = DeleteMutationLifecycle()
        lifecycle.beginTouchDown(
            context: KeyboardTextContextSnapshot(beforeInput: "돈", afterInput: ""),
            selectedText: nil
        )
        let touchDownCapture = lifecycle.capture(
            deletedText: "돈",
            insertedText: "도",
            reliability: .authoritative
        )
        let immediateWaitingAction = lifecycle.actionForNextRepeat(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "돈", afterInput: ""),
            currentSelectedText: nil
        )
        lifecycle.finishRepeatTracking()
        let touchDownOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "도", afterInput: ""),
            currentSelectedText: nil
        )
        let immediateDeletingAction = lifecycle.actionForNextRepeat(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "도", afterInput: ""),
            currentSelectedText: nil
        )
        lifecycle.beginRepeat(
            context: KeyboardTextContextSnapshot(beforeInput: "도", afterInput: ""),
            selectedText: nil
        )
        let repeatCapture = lifecycle.capture(
            deletedText: "도",
            insertedText: "ㄷ",
            reliability: .authoritative
        )
        let repeatResolution = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "ㄷ", afterInput: ""),
            currentSelectedText: nil
        ).resolution

        #expect(touchDownCapture == .awaitingTextChange)
        #expect(immediateWaitingAction == .awaitingPreviousMutation)
        #expect(
            touchDownOutcome
            == .resolved(
                DeleteMutationResolution(
                completion: .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: "돈",
                        insertedText: "도",
                        reliability: .authoritative
                    )
                ]),
                origin: .touchDown,
                shouldPlayFeedback: false
                )
            )
        )
        #expect(immediateDeletingAction == .deleteAwaitingTextChange(previousResolution: nil))
        #expect(repeatCapture == .awaitingTextChange)
        #expect(repeatResolution?.shouldPlayFeedback == true)
        #expect(
            repeatResolution?.completion
            == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "도",
                    insertedText: "ㄷ",
                    reliability: .authoritative
                )
            ])
        )
    }

    @Test("repeat tick release 뒤 늦은 callback은 줄바꿈을 한 번 확정하고 grouped Undo와 Redo에 포함")
    func testRepeatTick_Release후Callback_줄바꿈확정과GroupedUndoRedo() {
        var lifecycle = DeleteMutationLifecycle()
        var manager = KeyboardUndoRedoManager()
        let context = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        manager.record(deletedText: "다", insertedText: "", targetContext: nil)
        lifecycle.beginRepeat(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )

        let releaseResolution = lifecycle.completeAtCheckpoint(
            currentContext: context,
            currentSelectedText: nil
        )
        lifecycle.finishRepeatTracking()
        let callbackOutcome = lifecycle.completeAfterTextChange(
            currentContext: context,
            currentSelectedText: nil
        )
        let duplicateOutcome = lifecycle.completeAfterTextChange(
            currentContext: context,
            currentSelectedText: nil
        )
        record(callbackOutcome.resolution, in: &manager)

        #expect(releaseResolution == nil)
        #expect(
            callbackOutcome
            == .resolved(
                DeleteMutationResolution(
                completion: .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: "\n",
                        insertedText: "",
                        reliability: .authoritative
                    )
                ]),
                origin: .repeatTick,
                shouldPlayFeedback: true
                )
            )
        )
        #expect(duplicateOutcome == .noResolution)
        #expect(lifecycle.isPending == false)
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "\n다"))
        #expect(manager.redo() == KeyboardUndoRedoEdit(deleteCount: 2, insertText: ""))
    }

    @Test("released repeat tick은 unrelated callback 실패 뒤 stale 요청을 남기지 않음")
    func testRepeatTick_Release후UnrelatedCallback_Pending정리() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        lifecycle.beginRepeat(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        lifecycle.finishRepeatTracking()

        let unrelatedOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "바",
                afterInput: "새 입력"
            ),
            currentSelectedText: nil
        )
        let staleOutcome = lifecycle.completeAfterTextChange(
            currentContext: context,
            currentSelectedText: nil
        )

        #expect(unrelatedOutcome == .cancelled)
        #expect(staleOutcome == .noResolution)
        #expect(lifecycle.isPending == false)
    }

    @Test("released touchDown 뒤 non-delete long press는 stale 삭제 요청을 먼저 정리")
    func testTouchDown_Release후NonDeleteLongPress_입력Capture분리() {
        var lifecycle = DeleteMutationLifecycle()
        // 문맥이 아직 삭제를 반영하지 않은 상태로 손을 떼야 요청이 released로 남는다.
        // 빈 문맥과 빈 draft는 finishTouchDown이 삭제 없음으로 바로 끝내 정리할 요청이 없다
        let context = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        #expect(
            lifecycle.beginTouchDown(context: context, selectedText: nil)
            == .started
        )
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        #expect(
            lifecycle.finishTouchDown(
                currentContext: context,
                currentSelectedText: nil
            ) == nil
        )
        #expect(lifecycle.isPending)

        lifecycle.prepareForNonDeleteEdit()
        #expect(lifecycle.isPending == false)
        let insertionOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "바a", afterInput: ""),
            currentSelectedText: nil
        )
        let insertionCapture = lifecycle.capture(
            deletedText: "",
            insertedText: "a",
            reliability: .authoritative
        )

        #expect(insertionOutcome == .noResolution)
        #expect(insertionCapture == nil)
        #expect(lifecycle.isPending == false)
    }

    @Test("released touchDown 확인 전 delete pan은 대기하고 늦은 callback 뒤 grouped Undo와 Redo에 포함")
    func testTouchDown_Release후DeletePan_늦은Callback뒤GroupedUndoRedo() {
        var lifecycle = DeleteMutationLifecycle()
        var manager = KeyboardUndoRedoManager()
        let lineBoundaryContext = KeyboardTextContextSnapshot(beforeInput: "바", afterInput: "")
        _ = lifecycle.beginTouchDown(context: lineBoundaryContext, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        _ = lifecycle.finishTouchDown(
            currentContext: lineBoundaryContext,
            currentSelectedText: nil
        )

        #expect(
            lifecycle.actionForDeletePan(
                currentContext: lineBoundaryContext,
                currentSelectedText: nil
            ) == .awaitingPreviousMutation
        )
        let initialResolution = lifecycle.completeAfterTextChange(
            currentContext: lineBoundaryContext,
            currentSelectedText: nil
        ).resolution
        record(initialResolution, in: &manager)
        #expect(initialResolution?.shouldPlayFeedback == false)

        #expect(
            lifecycle.actionForDeletePan(
                currentContext: lineBoundaryContext,
                currentSelectedText: nil
            ) == .perform(previousResolution: nil)
        )
        manager.record(deletedText: "바", insertedText: "", targetContext: nil)

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "바\n"))
        #expect(manager.redo() == KeyboardUndoRedoEdit(deleteCount: 2, insertText: ""))
    }

    @Test("첫 proxy 후보가 달라도 전체 반복 삭제 Undo와 Redo는 실제 줄바꿈을 사용")
    func testTouchDownProxy후보불일치_전체반복삭제_UndoRedo() {
        var lifecycle = DeleteMutationLifecycle()
        var manager = KeyboardUndoRedoManager()
        let mutations = [
            (before: "바", candidate: "바", after: "바", expected: "\n"),
            (before: "마바", candidate: "바", after: "마", expected: "바"),
            (before: "마", candidate: "마", after: "", expected: "마"),
            (before: "", candidate: "", after: "다라", expected: "\n"),
            (before: "다라", candidate: "라", after: "다", expected: "라"),
            (before: "다", candidate: "다", after: "", expected: "다"),
            (before: "", candidate: "", after: "가나", expected: "\n"),
            (before: "가나", candidate: "나", after: "가", expected: "나"),
            (before: "가", candidate: "가", after: "", expected: "가")
        ]

        for (index, mutation) in mutations.enumerated() {
            let requestContext = KeyboardTextContextSnapshot(
                beforeInput: mutation.before,
                afterInput: ""
            )
            if index == 0 {
                lifecycle.beginTouchDown(context: requestContext, selectedText: nil)
            } else {
                let action = lifecycle.actionForNextRepeat(
                    currentContext: requestContext,
                    currentSelectedText: nil
                )
                #expect(action == .deleteAwaitingTextChange(previousResolution: nil))
                lifecycle.beginRepeat(context: requestContext, selectedText: nil)
            }

            _ = lifecycle.capture(
                deletedText: mutation.candidate,
                insertedText: "",
                reliability: .proxyContext
            )
            let resolution = lifecycle.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: mutation.after,
                    afterInput: ""
                ),
                currentSelectedText: nil
            ).resolution
            #expect(
                resolution?.completion
                == .mutations([
                    RepeatDeleteMutationDraft(
                        deletedText: mutation.expected,
                        insertedText: "",
                        reliability: mutation.expected == "\n" ? .authoritative : .proxyContext
                    )
                ])
            )
            record(resolution, in: &manager)
        }

        #expect(
            manager.undo()
            == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "가나\n다라\n마바\n")
        )
        #expect(manager.redo() == KeyboardUndoRedoEdit(deleteCount: 9, insertText: ""))
    }

    @Test("released 요청의 관련 없는 callback은 cancelled outcome")
    func testReleasedRequestUnrelatedCallbackIsCancelledOutcome() {
        var lifecycle = DeleteMutationLifecycle()
        let request = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
        _ = lifecycle.beginTouchDown(context: request, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "가",
            insertedText: "",
            reliability: .proxyContext
        )
        lifecycle.finishRepeatTracking()

        #expect(
            lifecycle.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: "가",
                    afterInput: "새 입력"
                ),
                currentSelectedText: nil
            ) == .cancelled
        )
    }

    @MainActor
    @Test("active captured 요청의 관련 없는 callback은 generation과 FIFO를 취소")
    func testActiveCapturedRequestUnrelatedCallbackCancelsGeneration() {
        var harness = DeleteInteractionStateHarness()
        let button = DeleteButton(keyboard: .dubeolsik)
        let request = KeyboardTextContextSnapshot(beforeInput: "가", afterInput: "")
        _ = harness.beginTouchDown(button: button, context: request)
        _ = harness.capture(deletedText: "가")
        #expect(harness.enqueuePan(.left) == .enqueued)

        let outcome = harness.completeAfterTextChange(
            context: KeyboardTextContextSnapshot(
                beforeInput: "가",
                afterInput: "외부 변경"
            )
        )
        harness.process(outcome)
        harness.drain { _, _ in
            Issue.record("active context mismatch 뒤 stale FIFO가 재생됨")
        }

        #expect(outcome == .cancelled)
        #expect(harness.coordinator.currentGeneration == nil)
        #expect(harness.observedEvents.isEmpty)
        #expect(harness.panFinishCount == 1)
    }

    @Test("released repeat의 noDeletion은 feedback과 Undo를 기록하지 않음")
    func testReleasedRepeatNoDeletionDoesNotRecordFeedbackOrUndo() throws {
        var lifecycle = DeleteMutationLifecycle()
        var manager = KeyboardUndoRedoManager()
        let emptyContext = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        _ = lifecycle.beginRepeat(context: emptyContext, selectedText: nil)
        lifecycle.finishRepeatTracking()

        let outcome = lifecycle.completeAfterTextChange(
            currentContext: emptyContext,
            currentSelectedText: nil
        )
        let resolution = try #require(outcome.resolution)
        record(resolution, in: &manager)

        #expect(resolution.completion == .noDeletion)
        #expect(resolution.shouldPlayFeedback == false)
        #expect(manager.undo() == nil)
    }

}

private extension DeleteMutationCallbackOutcome {
    var resolution: DeleteMutationResolution? {
        guard case .resolved(let resolution) = self else { return nil }
        return resolution
    }
}

private extension DeleteMutationLifecycleTests {
    func record(
        _ resolution: DeleteMutationResolution?,
        in manager: inout KeyboardUndoRedoManager
    ) {
        guard case .mutations(let drafts) = resolution?.completion else { return }
        for draft in drafts {
            manager.record(
                deletedText: draft.deletedText,
                insertedText: draft.insertedText,
                targetContext: nil
            )
        }
    }
}
