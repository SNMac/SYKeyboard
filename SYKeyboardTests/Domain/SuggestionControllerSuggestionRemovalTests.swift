//
//  SuggestionControllerSuggestionRemovalTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 후보 삭제 판정·실행 검증")
struct SuggestionControllerSuggestionRemovalTests {

    @Test("n-gram 모드는 바 인덱스의 후보 단어를 삭제 대상으로 반환")
    func testNGram모드는_바인덱스의후보단어를_삭제대상으로반환() {
        let harness = makeHarness(nGramResults: ["오늘", "날씨", "좋다"])

        harness.controller.updateSuggestions(for: "")

        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == "오늘")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "날씨")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 3) == nil)
    }

    @Test("n-gram 후보를 삭제하면 엔진에서 지우고 후보를 다시 전달")
    func testNGram후보를삭제하면_엔진에서지우고_후보를다시전달() {
        let harness = makeHarness(nGramResults: ["오늘", "날씨", "좋다"])
        harness.controller.updateSuggestions(for: "")

        harness.controller.removeSuggestionWord("날씨")

        #expect(harness.nGram.removedWords == ["날씨"])
        #expect(harness.checker.unlearnedWords == [])
        #expect(harness.delegate.updates.last?.suggestions == ["오늘", "좋다"])
    }

    @Test("입력 중에는 현재 단어와 미학습 TextChecker 후보를 삭제 대상에서 제외")
    func test입력중에는_현재단어와미학습TextChecker후보를_삭제대상에서제외() async {
        let harness = makeHarness(
            checkerResults: ["hello", "help"],
            learnedWords: ["help"]
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == ["hello", "help"])
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 2) == "help")
    }

    @Test("학습한 TextChecker 후보를 삭제하면 unlearn하고 후보에서 뺌")
    func test학습한TextChecker후보를삭제하면_unlearn하고_후보에서뺌() async {
        let harness = makeHarness(
            checkerResults: ["hello", "help"],
            learnedWords: ["help"]
        )
        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        harness.controller.removeSuggestionWord("help")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.checker.unlearnedWords == ["help"])
        #expect(harness.nGram.removedWords == ["help"])
        #expect(harness.delegate.updates.last?.suggestions == ["hello"])
    }

    @Test("텍스트 대치 후보는 삭제 대상이 아님")
    func test텍스트대치후보는_삭제대상이아님() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "hel", documentText: "first")]
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == ["first"])
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
    }

    @Test("수식 후보는 삭제 대상이 아님")
    func test수식후보는_삭제대상이아님() {
        let harness = makeHarness(nGramResults: ["오늘"])

        harness.controller.updateSuggestions(for: "3 - 1 =")

        #expect(harness.controller.currentMode == .mathExpression)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 2) == nil)
    }

    @Test("n-gram 후보 선택 직후 예측을 삭제해도 예측 모드를 유지")
    func testNGram후보선택직후_예측을삭제해도_예측모드를유지() {
        let harness = makeHarness(nGramResults: ["좋다", "맑음"])
        harness.controller.updateSuggestionsAfterNGramSelection(inputBuffer: "오늘 날씨")

        harness.controller.removeSuggestionWord("좋다")

        #expect(harness.controller.currentMode == .nGram)
        #expect(harness.delegate.updates.last == .init(currentWord: nil, suggestions: ["맑음"]))
    }

    @Test("입력 중 10칸에서도 바 인덱스가 후보 배열의 앞 한 칸만큼 밀림")
    func test입력중10칸에서도_바인덱스가_앞한칸만큼밀림() async {
        let checkerResults = (1...9).map { "help\($0)" }
        let harness = makeHarness(
            checkerResults: checkerResults,
            learnedWords: Set(checkerResults)
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == checkerResults)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "help1")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 9) == "help9")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 10) == nil)
    }

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let nGram: RemovableNGramStub
        let checker: LearnedWordCheckerStub
        let queue: DispatchQueue
    }

    private func makeHarness(
        nGramResults: [String] = [],
        checkerResults: [String] = [],
        learnedWords: Set<String> = [],
        lexiconEntries: [TextReplacementEntry] = []
    ) -> Harness {
        let nGram = RemovableNGramStub(results: nGramResults)
        let checker = LearnedWordCheckerStub(results: checkerResults, learnedWords: learnedWords)
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in nGram }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.removal")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        let delegate = RecordingSuggestionControllerDelegate()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, delegate: delegate, nGram: nGram, checker: checker, queue: queue)
    }
}

private final class RemovableNGramStub: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    private var results: [String]
    private(set) var removedWords: [String] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] { results }
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] { results }
    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}

    func removeWord(_ word: String) {
        removedWords.append(word)
        results.removeAll { $0 == word }
    }
}

/// `UITextChecker` 전역 사전 대신 학습 여부를 주입해 판정 분기를 확인한다
private final class LearnedWordCheckerStub: PredictiveTextProvider, @unchecked Sendable {
    private var results: [String]
    private let learnedWords: Set<String>
    private(set) var unlearnedWords: [String] = []

    init(results: [String], learnedWords: Set<String>) {
        self.results = results
        self.learnedWords = learnedWords
    }

    func suggestions(for baseText: String) -> [String] { results }
    func learn(word: String) {}

    func canUnlearn(word: String) -> Bool {
        learnedWords.contains(word)
    }

    func unlearn(word: String) {
        guard learnedWords.contains(word) else { return }
        unlearnedWords.append(word)
        results.removeAll { $0 == word }
    }
}
