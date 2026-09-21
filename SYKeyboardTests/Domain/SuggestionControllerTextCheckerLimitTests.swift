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
    func test입력중TextChecker는_후보슬롯수를limit으로받음() async {
        let checker = RecordingPredictiveTextProvider(results: ["hello", "help", "helmet"])
        let delegate = RecordingSuggestionControllerDelegate()
        let harness = makeController(checker: checker, lexiconEntries: [])
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.receivedLimits == [9])
        #expect(delegate.updates.last?.currentWord == "hel")
        #expect(delegate.updates.last?.suggestions == ["hello", "help", "helmet"])
    }

    @Test("lexicon이 슬롯을 다 채우면 TextChecker를 조회하지 않음")
    func testLexicon이슬롯을다채우면_TextChecker를조회하지않음() async {
        let checker = RecordingPredictiveTextProvider(results: ["hello"])
        let delegate = RecordingSuggestionControllerDelegate()
        let documentTexts = (1...9).map { "entry\($0)" }
        let harness = makeController(
            checker: checker,
            lexiconEntries: documentTexts.map {
                TextReplacementEntry(userInput: "hel", documentText: $0)
            }
        )
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.callCount == 0)
        #expect(delegate.updates.last?.suggestions == documentTexts)
    }

    @Test("입력 중 후보는 9칸까지 차되 현재 단어와 중복을 제외")
    func test입력중후보는_9칸까지차되_현재단어와중복을제외() async {
        // TextChecker 결과는 limit으로 잘리지만 lexicon 결과는 잘리지 않는다.
        // 현재 단어 "hel"과 "hello"의 대소문자 중복을 lexicon 쪽에 두어 제외를 확인한다
        let checker = RecordingPredictiveTextProvider(
            results: (1...9).map { "help\($0)" }
        )
        let delegate = RecordingSuggestionControllerDelegate()
        let harness = makeController(
            checker: checker,
            lexiconEntries: ["hel", "hello", "Hello", "world"].map {
                TextReplacementEntry(userInput: "hel", documentText: $0)
            }
        )
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        let suggestions = delegate.updates.last?.suggestions ?? []
        #expect(checker.receivedLimits == [9])
        #expect(suggestions.count == 9)
        #expect(suggestions.contains("hel") == false)
        #expect(suggestions.contains("Hello") == false)
        #expect(suggestions == ["hello", "world",
                                "help1", "help2", "help3", "help4",
                                "help5", "help6", "help7"])
    }

    private struct Harness {
        let controller: SuggestionController
        let queue: DispatchQueue
    }

    private func makeController(
        checker: RecordingPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.textchecker.limit")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, queue: queue)
    }
}

private final class RecordingPredictiveTextProvider: PredictiveTextProvider, @unchecked Sendable {
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
