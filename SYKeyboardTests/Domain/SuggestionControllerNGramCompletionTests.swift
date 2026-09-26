//
//  SuggestionControllerNGramCompletionTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("입력 중 NGram 단어 완성 후보 병합 검증")
struct SuggestionControllerNGramCompletionTests {

    @Test("입력 중 후보는 lexicon, NGram 완성 최대 3개, TextChecker 순으로 중복 없이 병합")
    func test입력중후보는_lexicon_NGram완성최대3개_TextChecker순으로_중복없이병합() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "키보", documentText: "키보드 단축어")],
            checkerResults: ["키보드", "키보이"]
        )
        harness.nGram.completionResults = ["키보드", "키보드로", "키보드를", "키보드에서"]

        harness.controller.updateSuggestions(for: "키보")

        #expect(harness.delegate.updates.last == .init(
            currentWord: "키보",
            suggestions: ["키보드 단축어", "키보드", "키보드로", "키보드를"]
        ))

        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last == .init(
            currentWord: "키보",
            suggestions: ["키보드 단축어", "키보드", "키보드로", "키보드를", "키보이"]
        ))
        #expect(harness.nGram.completionQueries == [.init(typedWord: "키보", previousWord: nil, limit: 3)])
    }

    @Test("바로 앞 단어를 bigram 문맥으로 넘김")
    func test바로앞단어를_bigram문맥으로넘김() async {
        let harness = makeHarness()

        harness.controller.updateSuggestions(for: "날")
        harness.controller.updateSuggestions(for: "오늘 날")
        await harness.finishTextChecker()

        #expect(harness.nGram.completionQueries == [
            .init(typedWord: "날", previousWord: nil, limit: 3),
            .init(typedWord: "날", previousWord: "오늘", limit: 3)
        ])
    }

    @Test("한글과 영문이 섞인 단어는 단어 전체를 완성 후보로 대치")
    func test한글과영문이섞인단어는_단어전체를_완성후보로대치() async {
        let harness = makeHarness()
        harness.nGram.completionResults = ["SY키보드"]

        harness.controller.updateSuggestions(for: "오늘 SY키")
        let result = harness.controller.selectSuggestion(at: 0, baseText: "오늘 SY키")
        await harness.finishTextChecker()

        #expect(harness.nGram.completionQueries == [.init(typedWord: "SY키", previousWord: "오늘", limit: 3)])
        #expect(result?.deleteCount == 3)
        #expect(result?.insertText == "SY키보드")
    }

    @Test("입력 중 NGram 완성 후보는 길게 눌러 삭제할 수 있음")
    func test입력중NGram완성후보는_길게눌러삭제할수있음() async {
        let harness = makeHarness()
        harness.nGram.completionResults = ["키보드"]

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()

        // 0번 버튼은 현재 단어라 완성 후보는 1번 버튼이다
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "키보드")
    }

    @Test("NGram 로딩이 끝나면 입력 중 후보에 완성 후보를 채움")
    func testNGram로딩이끝나면_입력중후보에_완성후보를채움() async {
        let harness = makeHarness()

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()
        #expect(harness.delegate.updates.last == .init(currentWord: "키보", suggestions: []))

        harness.nGram.completionResults = ["키보드"]
        harness.nGram.completeLoad(suggestions: [])
        await waitForMainQueue()
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last == .init(currentWord: "키보", suggestions: ["키보드"]))
    }

    @Test("lexicon과 NGram 완성이 9칸을 채우면 TextChecker를 조회하지 않음")
    func testLexicon과NGram완성이_9칸을채우면_TextChecker를조회하지않음() async {
        let harness = makeHarness(
            lexiconEntries: (1...6).map { TextReplacementEntry(userInput: "키보", documentText: "단축어\($0)") },
            checkerResults: ["키보이"]
        )
        harness.nGram.completionResults = ["키보드", "키보드로", "키보드를"]

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()

        #expect(harness.checker.calledBaseTexts == [])
        #expect(harness.delegate.updates.last?.suggestions.count == 9)
    }

    @Test("한/A 전환은 입력 중 NGram 완성 후보를 다시 조회하지 않음")
    func test한A전환은_입력중NGram완성후보를_다시조회하지않음() async {
        let harness = makeHarness(nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage)
        harness.nGram.completionResults = ["SY키보드"]
        harness.controller.updateSuggestions(for: "SY키")
        await harness.finishTextChecker()
        let updateCount = harness.delegate.updates.count

        harness.controller.updateLanguage(to: "en-US")
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.count == updateCount)
        #expect(harness.nGram.completionQueries.count == 1)
        #expect(harness.controller.currentMode == .typing)
    }

    // MARK: - Harness

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let nGram: StubNGramPredictiveTextProvider
        let checker: RecordingTextCheckerProvider
        let queue: DispatchQueue

        /// 대기 중인 TextChecker 조회와 그 결과 반영까지 끝낸다
        func finishTextChecker() async {
            queue.sync {}
            await waitForMainQueue()
        }
    }

    private func makeHarness(
        lexiconEntries: [TextReplacementEntry] = [],
        checkerResults: [String] = [],
        nGramLanguage: String? = nil
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let checker = RecordingTextCheckerProvider(results: checkerResults)
        let nGram = StubNGramPredictiveTextProvider()
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in nGram }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.ngramcompletion")
        let controller = SuggestionController(
            language: "ko-KR",
            nGramLanguage: nGramLanguage,
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

/// 주입한 후보를 돌려주고 조회한 텍스트를 기록하는 TextChecker stub
private final class RecordingTextCheckerProvider: PredictiveTextProvider, @unchecked Sendable {
    private let results: [String]
    private(set) var calledBaseTexts: [String] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        calledBaseTexts.append(baseText)
        return Array(results.prefix(limit))
    }

    func learn(word: String) {}
}
