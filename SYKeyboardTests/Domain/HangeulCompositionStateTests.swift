//
//  HangeulCompositionStateTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/3/26.
//

import Testing

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@Suite("한글 조합 상태 전이 검증")
struct HangeulCompositionStateTests {

    @Test("입력 결과는 committed와 composing buffer에 반영됨")
    func test입력상태전이() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        let first = state.input("ㄷ", using: processor)
        let second = state.input("ㅗ", using: processor)
        let third = state.input("ㄴ", using: processor)

        #expect(first.proxyEdit == .insert("ㄷ"))
        #expect(second.proxyEdit == .replace(deleteCount: 1, insertText: "도"))
        #expect(third.proxyEdit == .replace(deleteCount: 1, insertText: "돈"))
        #expect(state.committedBuffer == "")
        #expect(state.composingBuffer == "돈")
        #expect(state.text == "돈")
        #expect(state.lastInputText == "ㄴ")
    }

    @Test("스페이스 조합 확정은 committed를 보호 상태로 전환함")
    func test스페이스확정보호() {
        var state = HangeulCompositionState()
        let processor = CheonjiinProcessor(automata: HangeulAutomata())

        _ = state.input("ㅅ", using: processor)
        _ = state.input("ㅅ", using: processor)
        _ = state.input("ㅣ", using: processor)
        _ = state.input("ㆍ", using: processor)
        _ = state.input("ㄱ", using: processor)
        let space = state.space(using: processor)

        #expect(space.proxyEdit == .none)
        #expect(state.committedBuffer == "학")
        #expect(state.composingBuffer == "")
        #expect(state.isCommittedProtected)
        #expect(state.lastInputText == nil)
    }

    @Test("삭제는 composing과 consumed committed를 함께 반영함")
    func test삭제상태전이() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        _ = state.input("ㄷ", using: processor)
        _ = state.input("ㅏ", using: processor)
        _ = state.input("ㄹ", using: processor)
        _ = state.input("ㄱ", using: processor)

        let delete = state.delete(using: processor)

        #expect(delete.proxyEdit == .replace(deleteCount: 1, insertText: "달"))
        #expect(state.committedBuffer == "")
        #expect(state.composingBuffer == "달")
        #expect(state.lastInputText == nil)
    }

    @Test("반복 삭제 종료 후 committed 마지막 한글을 composing으로 끌어옴")
    func test반복삭제후끌어오기() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        _ = state.input("ㄷ", using: processor)
        _ = state.input("ㅗ", using: processor)
        _ = state.input("ㄴ", using: processor)
        _ = state.repeatInsert(using: processor)

        let delete = state.repeatDelete(using: processor)
        let finish = state.finishRepeatDelete(using: processor)

        #expect(delete.proxyEdit == .delete(count: 1))
        #expect(finish?.proxyEdit == .replace(deleteCount: 1, insertText: "돈"))
        #expect(state.committedBuffer == "")
        #expect(state.composingBuffer == "돈")
    }

    @Test("빈 한글 조합 상태의 경계 반복 삭제는 줄바꿈 확인을 shared undo 기록에 전달")
    func test빈조합상태_경계반복삭제_줄바꿈Undo전달() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())
        var request = RepeatDeleteRequest()

        let delete = state.repeatDelete(using: processor)
        request.begin(
            context: KeyboardTextContextSnapshot(
                beforeInput: nil,
                afterInput: "한글"
            ),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        let completion = request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "앞줄",
                afterInput: "한글"
            ),
            currentSelectedText: nil
        )

        #expect(delete.proxyEdit == .delete(count: 1))
        #expect(captureResult == .awaitingTextChange)
        #expect(state.committedBuffer.isEmpty)
        #expect(state.composingBuffer.isEmpty)
        #expect(
            completion == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "\n",
                    insertedText: "",
                    reliability: .authoritative
                )
            ])
        )
    }

    @Test("한글 반복 삭제 치환 mutation은 callback 확인 뒤 한 번만 유지")
    func test한글반복삭제_치환Mutation_Callback확인() {
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

        let completion = request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: ""),
            currentSelectedText: nil
        )

        #expect(
            completion == .mutations([
                RepeatDeleteMutationDraft(
                    deletedText: "한",
                    insertedText: "하",
                    reliability: .authoritative
                )
            ])
        )
        #expect(request.completeWithoutDeletion() == nil)
    }

    @Test("delete touchDown 후 pan 삭제는 복구 문자를 한 번만 기록함")
    func testDeleteTouchDown후Pan복구중복방지() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        _ = state.input("ㄷ", using: processor)
        _ = state.input("ㅗ", using: processor)
        _ = state.input("ㄴ", using: processor)

        let touchDown = state.deleteButtonTouchDown(using: processor)
        let panDelete = state.deleteButtonPanDelete(using: processor)

        #expect(touchDown.deletedCharacter == "돈")
        #expect(touchDown.transition.proxyEdit == .replace(deleteCount: 1, insertText: "도"))
        #expect(panDelete?.character == "도")
        #expect(panDelete?.shouldRestore == false)
        #expect(state.temporaryDeletedCharacters == ["돈"])
    }

    @Test("delete touchDown 경계 기록은 controller 삭제 흐름의 첫 pan 복구 정책을 보존함")
    func testDeleteTouchDown경계기록_첫Pan복구정책() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ", "ㅏ"].forEach {
            _ = state.input($0, using: processor)
        }

        state.beginDeleteButtonTouchDown()
        let delete = state.delete(using: processor)
        state.endDeleteButtonTouchDown()
        let panDelete = state.deleteButtonPanDelete(using: processor)

        #expect(delete.proxyEdit == .replace(deleteCount: 1, insertText: "고"))
        #expect(state.temporaryDeletedCharacters.isEmpty)
        #expect(panDelete?.character == "고")
        #expect(panDelete?.shouldRestore == false)
    }

    @Test("delete pan 종료는 임시 복구 상태만 초기화함")
    func testDeletePan종료_임시복구상태초기화() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        state.setDeleteDragState(
            committed: "가",
            composing: "",
            deletedCharacters: ["나"],
            shouldSkipNextDeletePanRestore: true,
            nextDeletePanRestoreReplacement: "다"
        )

        state.finishDeleteButtonPan()

        #expect(state.committedBuffer == "가")
        #expect(state.composingBuffer == "")
        #expect(state.temporaryDeletedCharacters.isEmpty)
        #expect(state.deleteButtonPanRestoreLast(using: processor) == nil)
    }
}
