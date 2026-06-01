//
//  KeyboardSuggestionSelectionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/1/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 자동완성 선택 정책 검증")
struct KeyboardSuggestionSelectionPolicyTests {

    @Test("n-gram 후보 앞 공백은 입력 버퍼가 비어 있지 않고 공백으로 끝나지 않을 때만 삽입")
    func testNGram후보앞공백삽입조건() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                inputBuffer: "hello"
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                inputBuffer: ""
            ) == false
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                inputBuffer: "hello "
            ) == false
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                inputBuffer: "hello\n"
            ) == false
        )
    }

    @Test("현재 단어 확정 대상은 입력 버퍼의 마지막 비공백 덩어리")
    func test현재단어확정대상() {
        #expect(
            KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
                inputBuffer: "hello world"
            ) == "world"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
                inputBuffer: "hello world "
            ) == "world"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
                inputBuffer: "hello\nworld"
            ) == "world"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
                inputBuffer: "   "
            ) == ""
        )
    }
}
