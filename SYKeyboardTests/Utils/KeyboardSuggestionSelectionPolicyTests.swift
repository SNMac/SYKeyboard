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

    @Test("자동완성 갱신 동작은 설정과 선택 텍스트 상태에 따라 결정")
    func test자동완성갱신동작() {
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: false,
                selectedText: "hello",
                inputBuffer: "input"
            ) == .none
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello",
                inputBuffer: "input"
            ) == .update("hello")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello world",
                inputBuffer: "input"
            ) == .clear
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello\nworld",
                inputBuffer: "input"
            ) == .clear
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "",
                inputBuffer: "input"
            ) == .update("input")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: nil,
                inputBuffer: "input"
            ) == .update("input")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: nil,
                inputBuffer: ""
            ) == .update("")
        )
    }

    @Test("textDidChange 자동완성 갱신은 primary 커서 드래그 중에는 건너뜀")
    func testTextDidChange자동완성갱신조건() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldUpdateSuggestionsOnTextDidChange(
                isPrimaryCursorDragging: false
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldUpdateSuggestionsOnTextDidChange(
                isPrimaryCursorDragging: true
            ) == false
        )
    }

    @Test("후보 선택 기준 텍스트는 입력 버퍼가 비어 있으면 커서 앞 문맥을 사용")
    func test후보선택기준텍스트() {
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionSelectionBaseText(
                inputBuffer: "동",
                documentContextBeforeInput: "동해"
            ) == "동"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionSelectionBaseText(
                inputBuffer: "",
                documentContextBeforeInput: "동해"
            ) == "동해"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionSelectionBaseText(
                inputBuffer: "",
                documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("lexicon은 텍스트 대치나 자동완성 중 하나라도 켜진 경우 로드")
    func testLexicon로딩조건() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldLoadLexicon(
                isTextReplacementEnabled: true,
                isPredictiveTextEnabled: false
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldLoadLexicon(
                isTextReplacementEnabled: false,
                isPredictiveTextEnabled: true
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldLoadLexicon(
                isTextReplacementEnabled: false,
                isPredictiveTextEnabled: false
            ) == false
        )
    }

    @Test("텍스트 대치용 lexicon은 첫 표시 전 로드를 시작")
    func test텍스트대치용Lexicon은_첫표시전로드를시작() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldStartLexiconLoadBeforeFirstAppearance(
                isTextReplacementEnabled: true
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldStartLexiconLoadBeforeFirstAppearance(
                isTextReplacementEnabled: false
            ) == false
        )
    }

    @Test("지연 준비 후 초기 후보 갱신은 예측 엔진을 준비한 경우에만 수행")
    func test지연준비후_초기후보갱신조건() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldUpdateInitialSuggestionsAfterDeferredPreparation(
                shouldPreparePredictiveEngines: true
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldUpdateInitialSuggestionsAfterDeferredPreparation(
                shouldPreparePredictiveEngines: false
            ) == false
        )
    }

    @Test("대치 복구는 입력 버퍼가 비어도 커서 앞 컨텍스트로 최근 대치 결과를 찾음")
    func test대치복구컨텍스트Fallback() {
        #expect(
            KeyboardSuggestionSelectionPolicy.textReplacementRestoreDeleteCount(
                documentText: "♡",
                inputBuffer: "",
                documentContextBeforeInput: "♡",
                selectedText: nil
            ) == 1
        )
    }

    @Test("대치 복구는 대치 뒤 공백이 있으면 수행하지 않음")
    func test대치복구TrailingSpace() {
        #expect(
            KeyboardSuggestionSelectionPolicy.textReplacementRestoreDeleteCount(
                documentText: "♡",
                inputBuffer: "♡ ",
                documentContextBeforeInput: "♡ ",
                selectedText: nil
            ) == nil
        )
    }

    @Test("선택 텍스트가 있으면 대치 복구보다 선택 삭제를 우선함")
    func test대치복구선택텍스트제외() {
        #expect(
            KeyboardSuggestionSelectionPolicy.textReplacementRestoreDeleteCount(
                documentText: "♡",
                inputBuffer: "",
                documentContextBeforeInput: "♡",
                selectedText: "♡"
            ) == nil
        )
    }
}
