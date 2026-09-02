//
//  SuggestionControllerAsyncTextCheckerTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("TextChecker 비동기 조회 검증")
struct SuggestionControllerAsyncTextCheckerTests {

    @Test("입력 중에는 lexicon 결과를 즉시 전달하고 TextChecker 결과를 뒤이어 전달")
    func test입력중에는_lexicon결과를즉시전달하고_TextChecker결과를뒤이어전달() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello", "help"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [
            TextReplacementEntry(userInput: "hel", documentText: "Helsinki")
        ])

        harness.controller.updateSuggestions(for: "hel")
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["Helsinki"]))

        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["Helsinki", "hello"]))
    }

    @Test("새 입력이 들어오면 이전 입력의 TextChecker 결과는 버림")
    func test새입력이들어오면_이전입력의TextChecker결과는버림() async {
        let checker = GatedPredictiveTextProvider(results: [
            "he": ["hey"],
            "hel": ["hello", "help"]
        ])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "he")
        harness.controller.updateSuggestions(for: "hel")

        checker.gate.signal()
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["hello", "help"]))
        #expect(harness.delegate.updates.contains { $0.suggestions == ["hey"] } == false)
    }

    @Test("일시 중단되면 진행 중이던 TextChecker 결과는 반영하지 않음")
    func test일시중단되면_진행중이던TextChecker결과는_반영하지않음() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello", "help"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "hel")
        harness.controller.isSuspended = true

        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: nil, suggestions: []))
    }

    @Test("TextChecker 결과 전달은 main 스레드에서 수행")
    func testTextChecker결과전달은_main스레드에서수행() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "hel")
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updateIsMainThread.last == true)
    }

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let queue: DispatchQueue
    }

    private func makeHarness(
        checker: GatedPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.textchecker")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        let delegate = RecordingSuggestionControllerDelegate()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, delegate: delegate, queue: queue)
    }
}

/// `gate.signal()`이 올 때까지 조회를 막아 결과 도착 순서를 테스트가 제어한다
private final class GatedPredictiveTextProvider: PredictiveTextProvider, @unchecked Sendable {
    let gate = DispatchSemaphore(value: 0)
    private let results: [String: [String]]

    init(results: [String: [String]]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        gate.wait()
        return Array((results[baseText] ?? []).prefix(limit))
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
    private(set) var updateIsMainThread: [Bool] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
        updateIsMainThread.append(Thread.isMainThread)
    }
}

private func waitForMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}
