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

    @Test("자동완성 후보 삭제 길게 누르기 시간은 0.5초")
    func test자동완성후보삭제_길게누르기시간은_0점5초() {
        #expect(KeyboardSuggestionSelectionPolicy.removalLongPressDuration == 0.5)
    }

    @Test("n-gram 후보 앞 공백은 기준 텍스트가 비어 있지 않고 공백으로 끝나지 않을 때만 삽입")
    func testNGram후보앞공백삽입조건() {
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                baseText: "hello"
            )
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                baseText: ""
            ) == false
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                baseText: "hello "
            ) == false
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
                baseText: "hello\n"
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
                baseText: "input"
            ) == .none
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello",
                baseText: "input"
            ) == .update("hello")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello world",
                baseText: "input"
            ) == .clear
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "3 + 1 =",
                baseText: "input"
            ) == .update("3 + 1 =")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "hello\nworld",
                baseText: "input"
            ) == .clear
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: "",
                baseText: "input"
            ) == .update("input")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: nil,
                baseText: "input"
            ) == .update("input")
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
                isPredictiveTextEnabled: true,
                selectedText: nil,
                baseText: ""
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

    @Test("커서 앞 문맥 제한은 nil을 빈 문자열로 처리하고 256자 suffix만 유지")
    func test커서앞문맥제한_nil과길이제한() {
        let droppedPrefix = String(repeating: "가", count: 3)
        let retainedContext = String(repeating: "나", count: KeyboardTextContextNavigator.maximumCursorRestoreDistance)

        #expect(KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(nil) == "")
        #expect(
            KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(droppedPrefix + retainedContext)
            == retainedContext
        )
    }

    @Test("수식 탐지 텍스트는 선택과 세션 입력을 우선하고 둘 다 없을 때만 커서 문맥을 사용")
    func test수식탐지텍스트는_선택과세션입력을우선하고_둘다없을때만커서문맥을사용() {
        #expect(
            KeyboardSuggestionSelectionPolicy.mathExpressionDetectionText(
                selectedText: "3+1=",
                inputBuffer: "4+1=",
                documentContextBeforeInput: "5+1="
            ) == "3+1="
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.mathExpressionDetectionText(
                selectedText: nil,
                inputBuffer: "4+1=",
                documentContextBeforeInput: "5+1="
            ) == "4+1="
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.mathExpressionDetectionText(
                selectedText: nil,
                inputBuffer: "",
                documentContextBeforeInput: "hello 5+1="
            ) == "hello 5+1="
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

    @Test("일반 후보 기준 텍스트는 버퍼가 비면 커서 앞 문맥, 있으면 앞 문맥과 버퍼")
    func test일반후보기준텍스트() {
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: "가나 가"
            ) == "가나 가"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: "가나 가", inputBuffer: "방", documentContextBeforeInput: "무시됨"
            ) == "가나 가방"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "안녕", documentContextBeforeInput: nil
            ) == "안녕"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("일반 후보 기준 텍스트는 줄바꿈을 넘지 않음")
    func test일반후보기준텍스트는_줄바꿈을넘지않음() {
        // 리턴은 학습에서 문장 끝이라, 윗줄 단어를 다음 단어 예측 문맥으로 쓰지 않는다
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: "안녕\n"
            ) == ""
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: "안녕\n가"
            ) == "가"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: "안녕\n", inputBuffer: "가", documentContextBeforeInput: nil
            ) == "가"
        )
    }

    @Test("일반 후보 기준 텍스트는 앞 문맥과 버퍼를 합쳐 끝 256자로 제한")
    func test일반후보기준텍스트는_끝256자로제한() {
        let leading = String(repeating: "a", count: 300)
        let base = KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
            leadingContext: leading, inputBuffer: "b", documentContextBeforeInput: nil
        )

        #expect(base.count == 256)
        #expect(base.hasSuffix("ab"))
    }

    @Test("앞 문맥이 공백이 아닌 글자로 끝날 때만 버퍼 첫 단어를 조각으로 판정")
    func test조각판정() {
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가"))
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가나 ") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가나\n") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext(nil) == false)
    }

    @Test("학습용 버퍼는 앞 글자에 붙은 첫 조각을 뺌")
    func test학습용버퍼는_앞조각을뺌() {
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방 가방 ", isAttachedToLeadingContext: true) == " 가방 ")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방", isAttachedToLeadingContext: true) == "")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer(" 가방", isAttachedToLeadingContext: true) == " 가방")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방 가방", isAttachedToLeadingContext: false) == "방 가방")
    }

    @Test("교체가 버퍼보다 길면 넘친 글자 수만큼 앞 문맥 끝을 자름")
    func test교체뒤앞문맥() {
        // 버퍼가 빈 상태의 교체: `가|`에서 `가방` 탭
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("가", inputBufferCount: 0, deleteCount: 1) == ""
        )
        // 일부 넘침: 앞 문맥 `가` + 버퍼 `방`에서 `가방끈` 탭
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("나 가", inputBufferCount: 1, deleteCount: 2) == "나 "
        )
        // 넘치지 않음: 한글 조합 교체
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("나 가", inputBufferCount: 2, deleteCount: 1) == "나 가"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement(nil, inputBufferCount: 0, deleteCount: 3) == nil
        )
    }
}
