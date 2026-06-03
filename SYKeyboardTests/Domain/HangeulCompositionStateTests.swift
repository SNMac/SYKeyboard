//
//  HangeulCompositionStateTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/3/26.
//

import Testing

@testable import HangeulKeyboardCore

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
