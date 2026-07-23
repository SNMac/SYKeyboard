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

        #expect(
            request.completeAfterTextChange(
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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

    @Test("권위 치환은 요청 문맥에 mutation을 적용한 결과와 일치할 때만 확정")
    func test반복삭제_권위치환_예상문맥일치() {
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
            request.completeAfterTextChange(
                isRepeatingInput: true,
                currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: ""),
                currentSelectedText: nil
            ) == .mutations([draft])
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
                currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: "라"),
                currentSelectedText: nil
            ) == nil
        )
        #expect(request.isPending)
    }

    @Test("반복 입력이 끝난 callback은 확정하지 않음")
    func test반복삭제_IsRepeatingInputFalse_확정안함() {
        var request = RepeatDeleteRequest()
        request.begin(
            context: KeyboardTextContextSnapshot(beforeInput: "마바", afterInput: ""),
            selectedText: nil
        )
        _ = request.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )

        #expect(
            request.completeAfterTextChange(
                isRepeatingInput: false,
                currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: ""),
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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
                isRepeatingInput: true,
                currentContext: deletedContext,
                currentSelectedText: nil
            ) != nil
        )
        #expect(
            request.completeAfterTextChange(
                isRepeatingInput: true,
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
                isRepeatingInput: true,
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

private extension KeyboardTextInteractionPolicyTests {
    func expectRepeatTimerInterval(repeatRate: Double, expected: Double) {
        let interval = KeyboardTextInteractionPolicy.repeatTimerInterval(repeatRate: repeatRate)

        #expect(abs(interval - expected) < 0.0001)
    }
}
