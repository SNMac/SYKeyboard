//
//  HangeulKeyboardInputAdapterTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing

@testable import HangeulKeyboardCore

@Suite("한글 입력 어댑터")
struct HangeulKeyboardInputAdapterTests {

    @Test("입력과 삭제는 기존 composition transition을 반환")
    func testInputAndDeleteTransitions() {
        let adapter = HangeulKeyboardInputAdapter(selectedKeyboard: .dubeolsik)

        let input = adapter.input("ㄱ")
        let delete = adapter.delete()

        #expect(input.proxyEdits == [.insert("ㄱ")])
        #expect(delete.proxyEdits == [.replace(deleteCount: 1, insertText: "")])
    }

    @Test("언어 전환 종료는 문서 edit 없이 조합 상태를 초기화")
    func testFinishForLanguageChangeKeepsDocumentText() {
        let adapter = HangeulKeyboardInputAdapter(selectedKeyboard: .dubeolsik)
        _ = adapter.input("ㄱ")

        adapter.finishForLanguageChange()

        #expect(adapter.shouldDeferUndoRedoCommit == false)
        #expect(adapter.isCompositionOngoing == false)
    }
}
