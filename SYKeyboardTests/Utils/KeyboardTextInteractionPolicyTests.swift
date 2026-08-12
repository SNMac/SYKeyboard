//
//  KeyboardTextInteractionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/1/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 텍스트 상호작용 정책 검증")
struct KeyboardTextInteractionPolicyTests {

    @Test("보조키 입력은 요청되었고 보조키가 있을 때만 수행")
    func test보조키입력조건() {
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: true,
                secondaryKey: "1"
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: false,
                secondaryKey: "1"
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: true,
                secondaryKey: nil
            ) == false
        )
    }

    @Test("단일 삭제 임시 저장 문자는 선택 텍스트를 역순으로 우선 사용")
    func test단일삭제임시저장문자() {
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: "abc",
                documentContextBeforeInput: "가나다"
            ) == "cba"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: "",
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: nil,
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                selectedText: nil,
                documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("앞 문맥이 비고 문서에 텍스트가 남으면 pan boundary 요청")
    func testDeletePanBoundaryRequestPolicy() {
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                documentContextBeforeInput: nil,
                selectedText: nil
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                documentContextBeforeInput: "",
                selectedText: ""
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: false,
                documentContextBeforeInput: "",
                selectedText: nil
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                documentContextBeforeInput: "가",
                selectedText: nil
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                documentContextBeforeInput: "",
                selectedText: "선택"
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
        let nonNewlineResolution = DeleteMutationResolution(
            completion: .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "가",
                    insertedText: "",
                    reliability: .authoritative
                )
            ]),
            origin: .panBoundary,
            shouldPlayFeedback: true
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
        #expect(
            KeyboardTextInteractionPolicy
                .temporaryDeletedCharactersForConfirmedPanBoundary(nonNewlineResolution)
            .isEmpty
        )
    }

    @Test("단일 삭제 기록 문자는 비어 있지 않은 선택 텍스트를 원문으로 우선 사용")
    func test단일삭제기록문자() {
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: "abc",
                documentContextBeforeInput: "가나다"
            ) == "abc"
        )
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: "",
                documentContextBeforeInput: "가나다"
            ) == "다"
        )
        #expect(
            KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: nil,
                documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("같은 입력 대상의 반복 tick과 식별 불가능한 기존 경로는 계속 수행")
    func test반복입력_같은입력대상_계속수행() {
        let input = RepeatInputIdentity()
        let inputIdentifier = ObjectIdentifier(input)

        #expect(
            KeyboardTextInteractionPolicy.shouldContinueRepeatInput(
                startedInputIdentifier: inputIdentifier,
                currentInputIdentifier: inputIdentifier
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldContinueRepeatInput(
                startedInputIdentifier: nil,
                currentInputIdentifier: inputIdentifier
            )
        )
    }

    @Test("반복 입력 시작 뒤 입력 대상이 바뀌면 stale tick을 중단")
    func test반복입력_입력대상변경_staleTick중단() {
        let startedInput = RepeatInputIdentity()
        let currentInput = RepeatInputIdentity()

        #expect(
            KeyboardTextInteractionPolicy.shouldContinueRepeatInput(
                startedInputIdentifier: ObjectIdentifier(startedInput),
                currentInputIdentifier: ObjectIdentifier(currentInput)
            ) == false
        )
    }

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

    @Test("일반 문자 반복 삭제는 callback에서 후보 문자를 확정")
    func test반복삭제_일반문자Callback_후보확정() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "마바", afterInput: ""),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        #expect(captureResult == .awaitingTextChange)
        #expect(request.isPending)

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: ""),
                currentSelectedText: nil
            ) == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "바",
                    insertedText: "",
                    reliability: .proxyContext
                )
            ])
        )
        #expect(request.isPending == false)
    }

    @Test("capture 전 callback 문맥은 capture 완료 결과로 전달")
    func test반복삭제_Capture전Callback_Capture에서완료() {
        var request = RepeatDeleteRequest()
        let draft = RepeatDeleteMutationDraft(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
            selectedText: nil
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: ""),
                currentSelectedText: nil
            ) == nil
        )
        #expect(
            request.capture(
                deletedText: draft.deletedText,
                insertedText: draft.insertedText,
                reliability: draft.reliability
            ) == .completion(.mutations([draft]))
        )
        #expect(request.isPending == false)
    }

    @Test("늦은 callback의 변경은 다음 timer checkpoint에서 확정")
    func test반복삭제_다음TimerTick_Checkpoint확정() {
        var request = RepeatDeleteRequest()
        let draft = RepeatDeleteMutationDraft(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "마바", afterInput: ""),
            selectedText: nil
        )

        #expect(
            request.capture(
                deletedText: draft.deletedText,
                insertedText: draft.insertedText,
                reliability: draft.reliability
            ) == .awaitingTextChange
        )
        #expect(
            request.completeAtCheckpoint(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: ""),
                currentSelectedText: nil
            ) == .mutations([draft])
        )
    }

    @Test("callback 없는 변경은 버튼 release checkpoint에서 확정")
    func test반복삭제_버튼Release_Checkpoint확정() {
        var request = RepeatDeleteRequest()
        let draft = RepeatDeleteMutationDraft(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
            selectedText: nil
        )

        #expect(
            request.capture(
                deletedText: draft.deletedText,
                insertedText: draft.insertedText,
                reliability: draft.reliability
            ) == .awaitingTextChange
        )
        #expect(
            request.completeAtCheckpoint(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: ""),
                currentSelectedText: nil
            ) == .mutations([draft])
        )
    }

    @Test("메시지 앱 줄 단위 문맥이 그대로면 proxy 후보 대신 줄바꿈 확정")
    func test반복삭제_메시지동일앞문맥_줄바꿈확정() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "다라", afterInput: "마바\n"),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "라",
            insertedText: "",
            reliability: .proxyContext
        )
        #expect(captureResult == .awaitingTextChange)

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: "다라",
                    afterInput: "마바\n"
                ),
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

    @Test("빈 앞 문맥에서 직전 줄 문맥이 나타나면 줄바꿈 확정")
    func test반복삭제_빈앞문맥에서직전줄노출_줄바꿈확정() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: nil, afterInput: "마바\n"),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        #expect(captureResult == .awaitingTextChange)

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: "다라",
                    afterInput: "마바\n"
                ),
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

    @Test("조합 치환 mutation은 callback 확인 뒤 원형 유지")
    func test반복삭제_권위있는조합치환_원형유지() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )
        #expect(captureResult == .awaitingTextChange)

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: ""),
                currentSelectedText: nil
            ) == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "한",
                    insertedText: "하",
                    reliability: .authoritative
                )
            ])
        )
    }

    @Test("권위 치환 뒤 앞 문맥이 그대로면 확정하지 않음")
    func test반복삭제_권위치환_변경없는앞문맥_확정안함() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
            selectedText: nil
        )
        _ = request.capture(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.isPending)
    }

    @Test("권위 치환 뒤 예상과 다른 앞 문맥이면 확정하지 않음")
    func test반복삭제_권위치환_불일치앞문맥_확정안함() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: ""),
            selectedText: nil
        )
        _ = request.capture(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "호", afterInput: ""),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.isPending)
    }

    @Test("뒤 문맥이 바뀐 callback은 확정하지 않음")
    func test반복삭제_변경된AfterInput_확정안함() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "마바", afterInput: "다"),
            selectedText: nil
        )
        _ = request.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: "라"),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.isPending)
    }

    @Test("pending 요청이 없으면 callback과 checkpoint 모두 확정하지 않음")
    func test반복삭제_요청없음_확정안함() {
        var request = RepeatDeleteRequest()
        let currentContext = KeyboardTextContextSnapshot(beforeInput: "마", afterInput: "")

        #expect(
            request.completeAfterTextChange(
                currentContext: currentContext,
                currentSelectedText: nil
            ) == nil
        )
        #expect(
            request.completeAtCheckpoint(
                currentContext: currentContext,
                currentSelectedText: nil
            ) == nil
        )
    }

    @Test("nil과 빈 문자열 차이만 있는 문맥은 삭제로 확정하지 않음")
    func test반복삭제_NilEmpty문맥차이만있음_확정안함() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: nil, afterInput: nil),
            selectedText: nil
        )
        _ = request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(beforeInput: "", afterInput: ""),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.completeWithoutDeletion() == .noDeletion)
    }

    @Test("반복 삭제 확인 성공은 mutation을 한 번만 완료")
    func test반복삭제_확인성공_mutation한번만완료() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(
                beforeInput: nil,
                afterInput: "다"
            ),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        #expect(captureResult == .awaitingTextChange)
        let deletedContext = KeyboardTextContextSnapshot(
            beforeInput: "가나",
            afterInput: "다"
        )

        #expect(
            request.completeAfterTextChange(
                currentContext: deletedContext,
                currentSelectedText: nil
            ) != nil
        )
        #expect(
            request.completeAfterTextChange(
                currentContext: deletedContext,
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.completeWithoutDeletion() == nil)
        #expect(request.isPending == false)
    }

    @Test("반복 삭제 확인 무효 요청은 삭제 없음으로 한 번만 완료")
    func test반복삭제_확인무효요청_삭제없음한번만완료() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(
                beforeInput: nil,
                afterInput: ""
            ),
            selectedText: nil
        )

        #expect(request.completeWithoutDeletion() == .noDeletion)
        #expect(request.completeWithoutDeletion() == nil)
        #expect(
            request.completeAfterTextChange(
                currentContext: KeyboardTextContextSnapshot(
                    beforeInput: "가",
                    afterInput: ""
                ),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.isPending == false)
    }

    @Test("반복 입력 타이머 간격은 최소값 아래로 내려가지 않음")
    func test반복입력타이머간격최소값() {
        expectRepeatTimerInterval(repeatRate: 0.05, expected: 0.05)
        expectRepeatTimerInterval(repeatRate: 0.09, expected: 0.01)
        expectRepeatTimerInterval(repeatRate: 0.10, expected: 0.01)
        expectRepeatTimerInterval(repeatRate: 0.20, expected: 0.01)
    }
}

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

    @Test("일반 tap release의 미확인 요청은 다음 입력 전에 정리")
    func testTouchDown_일반TapRelease_다음입력전Pending정리() {
        var lifecycle = DeleteMutationLifecycle()
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        lifecycle.beginTouchDown(context: context, selectedText: nil)
        _ = lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )

        _ = lifecycle.finishTouchDown(
            currentContext: context,
            currentSelectedText: nil
        )
        lifecycle.prepareForNonDeleteEdit()

        #expect(lifecycle.isPending == false)
        #expect(
            lifecycle.completeAfterTextChange(
                currentContext: context,
                currentSelectedText: nil
            ) == .noResolution
        )
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
        let context = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        #expect(
            lifecycle.beginTouchDown(context: context, selectedText: nil)
            == .started
        )
        _ = lifecycle.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        _ = lifecycle.finishTouchDown(
            currentContext: context,
            currentSelectedText: nil
        )

        lifecycle.prepareForNonDeleteEdit()
        let insertionOutcome = lifecycle.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "a", afterInput: ""),
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
    func testReleasedRequestUnrelatedCallbackCancelsGeneration() {
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
        var harness = DeleteInteractionIntegrationHarness()
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

private final class RepeatInputIdentity {}

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

private extension KeyboardTextInteractionPolicyTests {
    func expectRepeatTimerInterval(repeatRate: Double, expected: Double) {
        let interval = KeyboardTextInteractionPolicy.repeatTimerInterval(repeatRate: repeatRate)

        #expect(abs(interval - expected) < 0.0001)
    }
}

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
        var harness = DeleteInteractionIntegrationHarness()
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

        #expect(harness.temporaryDeletedCharacters == ["\n"])
        #expect(harness.panFinishCount == 1)
        #expect(harness.lifecycle.isPending == false)
        #expect(harness.coordinator.currentGeneration == nil)
        #expect(harness.coordinator.isWaitingForResolution == false)
    }

    @Test("문서 시작 panStop no-op은 후속 checkpoint에서 coordinator를 정리")
    func testDocumentStartPanStopNoOpCheckpointCleansCoordinator() {
        var harness = DeleteInteractionIntegrationHarness()
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
        var harness = DeleteInteractionIntegrationHarness()
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
        var harness = DeleteInteractionIntegrationHarness()
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

@MainActor
private struct DeleteInteractionIntegrationHarness {
    var coordinator = DeleteInteractionCoordinator()
    var lifecycle = DeleteMutationLifecycle()
    var observedDispositions: [DeleteInteractionDisposition] = []
    var observedEvents: [String] = []
    var observedOutcomes: [DeleteMutationCallbackOutcome] = []
    var temporaryDeletedCharacters: [Character] = []
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
            temporaryDeletedCharacters.append(
                contentsOf: KeyboardTextInteractionPolicy
                    .temporaryDeletedCharactersForConfirmedPanBoundary(resolution)
            )
            guard let generation = coordinator.currentGeneration else { return }
            _ = coordinator.resolve(generation)
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
        guard let result = coordinator.cancelIfInputIdentifierChanged(to: inputIdentifier) else {
            return
        }
        lifecycle.cancel()
        finishPanIfNeeded(result)
    }

    mutating func cancel() {
        lifecycle.cancel()
        finishPanIfNeeded(coordinator.cancel())
    }

    mutating func drain(
        handle: (inout DeleteInteractionIntegrationHarness, PendingDeleteInteractionEvent) -> Void
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
