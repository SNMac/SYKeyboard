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

    @Test("빈 한글 조합 상태의 반복 삭제는 proxy delete만 요청")
    func test빈조합상태_반복삭제() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        let delete = state.repeatDelete(using: processor)

        #expect(delete.proxyEdit == .delete(count: 1))
        #expect(state.committedBuffer.isEmpty)
        #expect(state.composingBuffer.isEmpty)
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
        #expect(panDelete?.character == "고")
        #expect(panDelete?.shouldRestore == false)
    }

    @Test("delete pan 종료는 touchDown 경계 기록을 지워 다음 pan 삭제가 화면 글자를 그대로 복구 대상으로 삼음")
    func testDeletePan종료_touchDown경계기록초기화() {
        var state = HangeulCompositionState()
        let processor = DubeolsikProcessor(automata: HangeulAutomata())

        // '동해물고' → touchDown 삭제로 '동해묽'. 경계 기록은 다음 pan 복구 글자를 '물'로 바꾸도록 남는다
        ["ㄷ", "ㅗ", "ㅇ", "ㅎ", "ㅐ", "ㅁ", "ㅜ", "ㄹ", "ㄱ", "ㅗ"].forEach {
            _ = state.input($0, using: processor)
        }
        state.beginDeleteButtonTouchDown()
        _ = state.delete(using: processor)
        state.endDeleteButtonTouchDown()
        #expect(state.text == "동해묽")

        state.finishDeleteButtonPan()
        let panDelete = state.deleteButtonPanDelete(using: processor)

        #expect(state.text == "동해")
        #expect(panDelete?.character == "묽")
        #expect(panDelete?.shouldRestore == true)
    }
}
