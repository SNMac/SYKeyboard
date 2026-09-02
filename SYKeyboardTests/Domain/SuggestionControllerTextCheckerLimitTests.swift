//
//  SuggestionControllerTextCheckerLimitTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("TextChecker 조회 limit 검증")
struct SuggestionControllerTextCheckerLimitTests {

    @Test("입력 중 TextChecker는 후보 슬롯 수를 limit으로 받음")
    func test입력중TextChecker는_후보슬롯수를limit으로받음() {
        let checker = RecordingPredictiveTextProvider(results: ["hello", "help", "helmet"])
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeController(checker: checker, lexiconEntries: [])
        controller.delegate = delegate

        controller.updateSuggestions(for: "hel")

        #expect(checker.receivedLimits == [2])
        #expect(delegate.updates.last?.currentWord == "hel")
        #expect(delegate.updates.last?.suggestions == ["hello", "help"])
    }

    @Test("lexicon이 슬롯을 다 채우면 TextChecker를 조회하지 않음")
    func testLexicon이슬롯을다채우면_TextChecker를조회하지않음() {
        let checker = RecordingPredictiveTextProvider(results: ["hello"])
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeController(
            checker: checker,
            lexiconEntries: [
                TextReplacementEntry(userInput: "hel", documentText: "first"),
                TextReplacementEntry(userInput: "hel", documentText: "second")
            ]
        )
        controller.delegate = delegate

        controller.updateSuggestions(for: "hel")

        #expect(checker.callCount == 0)
        #expect(delegate.updates.last?.suggestions == ["first", "second"])
    }

    private func makeController(
        checker: RecordingPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> SuggestionController {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let controller = SuggestionController(language: "en-US", engineFactory: factory)
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return controller
    }
}

private final class RecordingPredictiveTextProvider: PredictiveTextProvider {
    private let results: [String]
    private(set) var callCount = 0
    private(set) var receivedLimits: [Int] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        callCount += 1
        return results
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        callCount += 1
        receivedLimits.append(limit)
        return Array(results.prefix(limit))
    }

    func learn(word: String) {}
}

private final class StubLexiconSuggestionProvider: LexiconSuggestionProviding {
    private let entries: [TextReplacementEntry]
    var hasLoadedLexicon: Bool { true }

    init(entries: [TextReplacementEntry]) {
        self.entries = entries
    }

    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry] {
        entries.filter { $0.userInput.lowercased() == lowercasedWord }
    }

    func suggestions(for baseText: String) -> [String] {
        let currentWord = baseText.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
        return textReplacementEntries(matching: currentWord.lowercased()).map(\.documentText)
    }

    func learn(word: String) {}
}

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}
}

private final class RecordingSuggestionControllerDelegate: SuggestionControllerDelegate {
    struct Update: Equatable {
        let currentWord: String?
        let suggestions: [String]
    }

    private(set) var updates: [Update] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
    }
}
