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

        // 즉시 전달과 TextChecker 전달 두 번이 있었는지 먼저 고정해야
        // 비동기 전달이 사라져도 통과하는 단언이 되지 않는다
        #expect(harness.delegate.updates.count == 2)
        #expect(harness.delegate.updateIsMainThread.last == true)
    }

    @Test("연속 입력 중에는 TextChecker 결과 도착 전 직전 TextChecker 후보를 유지")
    func test연속입력중에는_TextChecker결과도착전_직전TextChecker후보를유지() async {
        let checker = GatedPredictiveTextProvider(results: [
            "he": ["hey"],
            "hel": ["hello", "help"]
        ])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "he")
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()
        #expect(harness.delegate.updates.last == .init(currentWord: "he", suggestions: ["hey"]))

        // 다음 글자를 입력한 직후에는 새 조회가 끝나지 않았지만 빈 후보를 그리지 않는다
        harness.controller.updateSuggestions(for: "hel")
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["hey"]))

        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["hello", "help"]))
    }

    @Test("n-gram 후보는 입력 중 모드로 넘어올 때 유지하지 않음")
    func testNGram후보는_입력중모드로넘어올때_유지하지않음() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello", "help"]])
        let harness = makeHarness(
            checker: checker,
            lexiconEntries: [],
            nGramResults: ["next"]
        )

        harness.controller.updateSuggestions(for: "")
        #expect(harness.delegate.updates.last == .init(currentWord: nil, suggestions: ["next"]))

        harness.controller.updateSuggestions(for: "hel")
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: []))

        // 대기 중인 조회를 풀어 큐 스레드를 남기지 않는다
        checker.gate.signal()
        harness.queue.sync {}
    }

    @Test("큐에 쌓인 낡은 요청은 조회를 건너뜀")
    func test큐에쌓인_낡은요청은_조회를건너뜀() async {
        let checker = GatedPredictiveTextProvider(results: [
            "he": ["hey"],
            "hel": ["hello", "help"]
        ])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        // 큐를 먼저 잡아 두 요청이 모두 쌓인 뒤 실행되게 한다
        let blocker = DispatchSemaphore(value: 0)
        harness.queue.async { blocker.wait() }

        harness.controller.updateSuggestions(for: "he")
        harness.controller.updateSuggestions(for: "hel")

        blocker.signal()
        // 낡은 요청은 gate 앞에서 반환되므로 살아 있는 요청 하나만 signal하면 된다
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.calledBaseTexts == ["hel"])
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["hello", "help"]))
    }

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let queue: DispatchQueue
    }

    private func makeHarness(
        checker: GatedPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry],
        nGramResults: [String] = []
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider(results: nGramResults) }
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
    /// 실제로 조회가 시작된 텍스트. 낡은 요청이 건너뛰어졌는지 확인한다
    private(set) var calledBaseTexts: [String] = []
    private let results: [String: [String]]

    init(results: [String: [String]]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        calledBaseTexts.append(baseText)
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

    private let results: [String]

    init(results: [String] = []) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] { results }
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
