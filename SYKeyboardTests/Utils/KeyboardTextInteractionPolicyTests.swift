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

    @Test("앞 문맥이 비고 문서에 텍스트가 남거나 이번 드래그에서 지운 글자가 있으면 pan boundary 요청")
    func testDeletePanBoundaryRequestPolicy() {
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                hasDeletedInCurrentPan: false,
                documentContextBeforeInput: nil,
                selectedText: nil
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                hasDeletedInCurrentPan: false,
                documentContextBeforeInput: "",
                selectedText: ""
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: false,
                hasDeletedInCurrentPan: false,
                documentContextBeforeInput: "",
                selectedText: nil
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                hasDeletedInCurrentPan: false,
                documentContextBeforeInput: "가",
                selectedText: nil
            ) == false
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: true,
                hasDeletedInCurrentPan: false,
                documentContextBeforeInput: "",
                selectedText: "선택"
            ) == false
        )
        // 줄 단위 문맥 입력창은 마지막 줄을 다 지우면 앞 줄이 남아도 hasText가 false다
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: false,
                hasDeletedInCurrentPan: true,
                documentContextBeforeInput: nil,
                selectedText: nil
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: false,
                hasDeletedInCurrentPan: true,
                documentContextBeforeInput: "가",
                selectedText: nil
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

    @Test("pan boundary에서 아무것도 지우지 못한 resolution만 효과를 건너뛰고 선행 no-op left를 버림")
    func testMutationResolutionEffects() {
        let noDeletionAtPanBoundary = DeleteMutationResolution(
            completion: .noDeletion,
            origin: .panBoundary,
            shouldPlayFeedback: false
        )
        let newlineAtPanBoundary = DeleteMutationResolution(
            completion: .mutations([
                RepeatDeleteMutationDraft(deletedText: "\n", insertedText: "", reliability: .authoritative)
            ]),
            origin: .panBoundary,
            shouldPlayFeedback: true
        )
        let nonNewlineAtPanBoundary = DeleteMutationResolution(
            completion: .mutations([
                RepeatDeleteMutationDraft(deletedText: "가", insertedText: "", reliability: .authoritative)
            ]),
            origin: .panBoundary,
            shouldPlayFeedback: true
        )
        let noDeletionAtTouchDown = DeleteMutationResolution(
            completion: .noDeletion,
            origin: .touchDown,
            shouldPlayFeedback: false
        )

        #expect(
            KeyboardTextInteractionPolicy.mutationResolutionEffects(noDeletionAtPanBoundary)
            == DeleteMutationResolutionEffects(
                restorableCharacters: [],
                appliesMutationEffects: false,
                discardsLeadingNoOpPanLeft: true,
                settlesBeforeResumingPan: false
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.mutationResolutionEffects(newlineAtPanBoundary)
            == DeleteMutationResolutionEffects(
                restorableCharacters: ["\n"],
                appliesMutationEffects: true,
                discardsLeadingNoOpPanLeft: false,
                settlesBeforeResumingPan: true
            )
        )
        // pan 경계 확정은 "\n" 한 건으로 확정된 경우에만 기록·피드백을 적용한다
        #expect(
            KeyboardTextInteractionPolicy.mutationResolutionEffects(nonNewlineAtPanBoundary)
            == DeleteMutationResolutionEffects(
                restorableCharacters: [],
                appliesMutationEffects: false,
                discardsLeadingNoOpPanLeft: false,
                settlesBeforeResumingPan: false
            )
        )
        #expect(
            KeyboardTextInteractionPolicy.mutationResolutionEffects(noDeletionAtTouchDown)
            == DeleteMutationResolutionEffects(
                restorableCharacters: [],
                appliesMutationEffects: true,
                discardsLeadingNoOpPanLeft: false,
                settlesBeforeResumingPan: false
            )
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
            ) == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "\n",
                    insertedText: "",
                    reliability: .authoritative
                )
            ])
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

    @Test("shift 짝 보조 키: 쿼티는 모든 키가 대소문자로 짝지어짐")
    func testShiftPairSecondaryKeyList_쿼티() {
        let primary: [[[[String]]]] = [
            [[["q"], ["w"]], [["a"]]],
            [[["Q"], ["W"]], [["A"]]]
        ]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [
            [[["Q"], ["W"]], [["A"]]],
            [[["q"], ["w"]], [["a"]]]
        ])
    }

    @Test("shift 짝 보조 키: 두벌식은 쌍자음·ㅒㅖ 자리만 짝이 생기고 나머지는 보조 키 없음")
    func testShiftPairSecondaryKeyList_두벌식() {
        let primary: [[[[String]]]] = [
            [[["ㅂ"], ["ㅛ"], ["ㅐ"]], [["ㅁ"]]],
            [[["ㅃ"], ["ㅛ"], ["ㅒ"]], [["ㅁ"]]]
        ]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [
            [[["ㅃ"], [], ["ㅒ"]], [[]]],
            [[["ㅂ"], [], ["ㅐ"]], [[]]]
        ])
    }

    @Test("shift 짝 보조 키: 층이 2개가 아니면 보조 키 없이 같은 모양 반환")
    func testShiftPairSecondaryKeyList_층불일치() {
        let primary: [[[[String]]]] = [[[["q"], ["w"]]]]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [[[[], []]]])
    }
}

private final class RepeatInputIdentity {}

private extension KeyboardTextInteractionPolicyTests {
    func expectRepeatTimerInterval(repeatRate: Double, expected: Double) {
        let interval = KeyboardTextInteractionPolicy.repeatTimerInterval(repeatRate: repeatRate)

        #expect(abs(interval - expected) < 0.0001)
    }

    // MARK: - 삭제 드래그 경계 상태

    private func makeBoundaryGeneration() -> DeleteInteractionGeneration {
        var coordinator = DeleteInteractionCoordinator()
        return coordinator.beginPanBoundaryMutation(inputIdentifier: nil)!
    }

    @Test("경계 요청을 보내기 전 대기 중에는 오른쪽 팬과 팬 종료만 대기를 취소")
    func testDeletePanBoundaryState_보내기전취소대상() {
        var state = DeletePanBoundaryState()
        #expect(state.shouldCancelPendingBeforeSend(on: .pan(direction: .right)) == false)

        state.beginPending(generation: makeBoundaryGeneration())

        #expect(state.shouldCancelPendingBeforeSend(on: .pan(direction: .right)))
        #expect(state.shouldCancelPendingBeforeSend(on: .panStop))
        #expect(state.shouldCancelPendingBeforeSend(on: .pan(direction: .left)) == false)
    }

    @Test("경계 대기는 대기를 시작한 generation에만 해당")
    func testDeletePanBoundaryState_다른generation() {
        var coordinator = DeleteInteractionCoordinator()
        let first = coordinator.beginPanBoundaryMutation(inputIdentifier: nil)!
        coordinator.resolve(first)
        let second = coordinator.beginPanBoundaryMutation(inputIdentifier: nil)!
        #expect(first != second)

        var state = DeletePanBoundaryState()
        state.beginPending(generation: first)

        #expect(state.isPending(generation: first))
        #expect(state.isPending(generation: second) == false)
    }

    @Test("보내기 전 대기를 취소하면 이번 드래그에서는 경계를 막고, 모델을 다시 채워 끝내면 막지 않음")
    func testDeletePanBoundaryState_대기종료() {
        var cancelled = DeletePanBoundaryState()
        cancelled.beginPending(generation: makeBoundaryGeneration())
        cancelled.cancelPending()
        #expect(cancelled.pendingGeneration == nil)
        #expect(cancelled.isBlocked)

        var refilled = DeletePanBoundaryState()
        refilled.beginPending(generation: makeBoundaryGeneration())
        refilled.finishPendingWithoutRequest()
        #expect(refilled.pendingGeneration == nil)
        #expect(refilled.isBlocked == false)
    }

    @Test("입력창 문맥 대기는 한 번만 시작하고, 요청을 보낸 뒤의 대기 시간 초과는 무시")
    func testDeletePanBoundaryState_문맥대기() {
        var state = DeletePanBoundaryState()
        let waitBeforePending = state.beginSyncWait()
        #expect(waitBeforePending == nil)

        state.beginPending(generation: makeBoundaryGeneration())
        let waitID = state.beginSyncWait()
        let secondWaitID = state.beginSyncWait()
        #expect(waitID != nil)
        #expect(secondWaitID == nil)
        #expect(state.isCurrentSyncWait(waitID!))

        _ = state.didSendRequest()
        #expect(state.isCurrentSyncWait(waitID!) == false)
    }

    @Test("보낸 경계 요청의 시간 초과는 확정되지 않은 가장 최근 요청에만 적용되고 경계를 막음")
    func testDeletePanBoundaryState_요청시간초과() {
        let newline = DeleteMutationResolution(
            completion: .mutations([
                RepeatDeleteMutationDraft(deletedText: "\n", insertedText: "", reliability: .authoritative)
            ]),
            origin: .panBoundary,
            shouldPlayFeedback: true
        )
        var state = DeletePanBoundaryState()
        state.beginPending(generation: makeBoundaryGeneration())
        let firstID = state.didSendRequest()
        state.didResolve(newline)
        let resolvedTimedOut = state.requestDidTimeOut(firstID)
        #expect(resolvedTimedOut == false)
        #expect(state.isBlocked == false)

        state.beginPending(generation: makeBoundaryGeneration())
        let secondID = state.didSendRequest()
        let staleTimedOut = state.requestDidTimeOut(firstID)
        let currentTimedOut = state.requestDidTimeOut(secondID)
        #expect(staleTimedOut == false)
        #expect(currentTimedOut)
        #expect(state.isBlocked)
    }

    @Test("경계 요청이 삭제 없음으로 확정되면 경계를 막고 줄바꿈 확정이면 막지 않음")
    func testDeletePanBoundaryState_확정() {
        var noDeletion = DeletePanBoundaryState()
        noDeletion.didResolve(
            DeleteMutationResolution(completion: .noDeletion, origin: .panBoundary, shouldPlayFeedback: false)
        )
        #expect(noDeletion.isBlocked)

        var touchDown = DeletePanBoundaryState()
        touchDown.didResolve(
            DeleteMutationResolution(completion: .noDeletion, origin: .touchDown, shouldPlayFeedback: false)
        )
        #expect(touchDown.isBlocked == false)
    }

    @Test("드래그를 다시 시작하면 막힘과 대기를 풀지만 이전 요청의 시간 초과는 되살리지 않음")
    func testDeletePanBoundaryState_초기화() {
        var state = DeletePanBoundaryState()
        state.beginPending(generation: makeBoundaryGeneration())
        let requestID = state.didSendRequest()
        state.cancelPending()

        state.reset()

        let timedOutAfterReset = state.requestDidTimeOut(requestID)
        #expect(state.isBlocked == false)
        #expect(state.pendingGeneration == nil)
        #expect(timedOutAfterReset == false)
    }

    // MARK: - 삭제 드래그 문맥 모델

    @Test("삭제 드래그 모델은 시작 문맥 끝에서 글자를 떼고 복구하면 다시 붙임")
    func testDeletePanTextModel_떼고붙이기() {
        var model = DeletePanTextModel(beforeInput: "가나\n다")

        #expect(model.lastCharacter == "다")
        #expect(model.removeLast() == "다")
        #expect(model.removeLast() == "\n")
        #expect(model.lastCharacter == "나")

        model.append("\n")
        model.append("다")

        #expect(model.lastCharacter == "다")
        #expect(model.remainingText.isEmpty == false)
    }

    @Test("삭제 드래그 모델은 시작 문맥이 없거나 다 떼면 바닥남")
    func testDeletePanTextModel_바닥남() {
        var model = DeletePanTextModel(beforeInput: nil)
        #expect(model.remainingText.isEmpty)
        #expect(model.lastCharacter == nil)
        #expect(model.removeLast() == nil)

        model = DeletePanTextModel(beforeInput: "가")
        _ = model.removeLast()
        #expect(model.remainingText.isEmpty)
    }

    @Test("삭제 드래그 모델은 처음 읽은 문맥을 떼고 붙여도 그대로 보관")
    func testDeletePanTextModel_시작문맥보관() {
        var model = DeletePanTextModel(beforeInput: "가나")
        _ = model.removeLast()
        model.append("다")

        #expect(model.sourceText == "가나")
        #expect(model.remainingText == "가다")
    }

    @Test("모델이 바닥났을 때 입력창 앞 문맥이 비었으면 경계를 물음")
    func testDeletePanExhaustedContext_경계요청() {
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "ㄱㄱㄱㄱㄱㄱ",
                documentContextBeforeInput: nil
            ) == .requestBoundary
        )
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "ㄱㄱㄱㄱㄱㄱ",
                documentContextBeforeInput: ""
            ) == .requestBoundary
        )
    }

    // 실기기 03:00:54: `ㄱ` 6개를 지웠는데 입력창이 아직 `ㄱㄱㄱㄱ`를 보냄
    @Test("앞 문맥이 방금 지운 모델 글자의 앞부분으로 끝나면 입력창이 따라오기를 기다림")
    func testDeletePanExhaustedContext_낡은문맥() {
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "ㄱㄱㄱㄱㄱㄱ",
                documentContextBeforeInput: "ㄱㄱㄱㄱ"
            ) == .awaitSync
        )
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "가나다",
                documentContextBeforeInput: "라마\n가나"
            ) == .awaitSync
        )
    }

    // 실기기 03:18:45: 처음 문맥이 앞 줄 없이 `⏎ㄹ…`이었고, 다 지운 뒤 실제 앞 줄 `ㄱ…`이 보임
    @Test("앞 문맥이 지운 모델 글자와 이어지지 않으면 실제 앞 줄로 보고 모델을 다시 채움")
    func testDeletePanExhaustedContext_앞줄() {
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "\nㄹㄹㄹ",
                documentContextBeforeInput: "ㄱㄱㄱㄱ"
            ) == .refill
        )
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "",
                documentContextBeforeInput: "가"
            ) == .refill
        )
    }

    @Test("같은 글자가 이어져 실제 앞 문맥과 낡은 문맥을 구분할 수 없으면 기다림으로 판정")
    func testDeletePanExhaustedContext_구분불가() {
        #expect(
            KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
                sourceText: "ㄱㄱㄱ",
                documentContextBeforeInput: "ㄱㄱㄱㄱㄱ"
            ) == .awaitSync
        )
    }

    @Test("삭제 드래그 경계 요청은 마지막 편집 뒤 50ms가 지나야 보냄",
          arguments: [
            (0.0, 0.05),
            (0.02, 0.03),
            (0.05, 0.0),
            (0.2, 0.0)
          ])
    func testDeletePanBoundaryDelay(_ elapsed: Double, _ expected: Double) {
        #expect(
            abs(KeyboardTextInteractionPolicy.deletePanBoundaryDelay(elapsedSinceLastEdit: elapsed) - expected)
                < 0.000_001
        )
    }
}
