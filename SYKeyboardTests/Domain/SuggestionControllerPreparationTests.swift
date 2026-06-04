//
//  SuggestionControllerPreparationTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/4/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 지연 준비 검증")
struct SuggestionControllerPreparationTests {

    @Test("자동완성 설정 활성화만으로 예측 엔진을 생성하지 않음")
    func test자동완성설정활성화만으로_예측엔진을생성하지않음() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )

        controller.isPredictiveTextEnabled = true

        #expect(factory.textCheckerCreationCount == 0)
        #expect(factory.nGramCreationCount == 0)
        #expect(factory.lexiconCreationCount == 0)
    }

    @Test("예측 엔진 준비는 자동완성이 켜진 경우 한 번만 수행")
    func test예측엔진준비는_자동완성이켜진경우_한번만수행() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )

        controller.preparePredictiveEnginesIfNeeded()
        #expect(factory.textCheckerCreationCount == 0)
        #expect(factory.nGramCreationCount == 0)

        controller.isPredictiveTextEnabled = true
        controller.preparePredictiveEnginesIfNeeded()
        controller.preparePredictiveEnginesIfNeeded()

        #expect(factory.textCheckerCreationCount == 1)
        #expect(factory.nGramCreationCount == 1)
    }

    @Test("lexicon 준비는 자동완성이나 텍스트 대치가 켜진 경우 한 번만 수행")
    func testLexicon준비는_자동완성이나텍스트대치가켜진경우_한번만수행() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )

        controller.prepareLexiconEngineIfNeeded()
        #expect(factory.lexiconCreationCount == 0)

        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()
        controller.prepareLexiconEngineIfNeeded()

        #expect(factory.lexiconCreationCount == 1)
    }

    @Test("필드별 일시 중단 해제 후 첫 후보 갱신에서 예측 엔진을 준비")
    func test필드별일시중단해제후_첫후보갱신에서예측엔진을준비() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )

        controller.isPredictiveTextEnabled = true
        controller.isSuspended = true
        controller.updateSuggestions(for: "ㅎ")

        #expect(factory.textCheckerCreationCount == 0)
        #expect(factory.nGramCreationCount == 0)
        #expect(factory.lexiconCreationCount == 0)

        controller.isSuspended = false
        controller.updateSuggestions(for: "ㅎ")

        #expect(factory.textCheckerCreationCount == 1)
        #expect(factory.nGramCreationCount == 1)
        #expect(factory.lexiconCreationCount == 1)
    }
}

private final class CountingSuggestionEngineFactory {

    // MARK: - Properties

    private(set) var lexiconCreationCount = 0
    private(set) var textCheckerCreationCount = 0
    private(set) var nGramCreationCount = 0

    // MARK: - Internal Methods

    func makeFactory() -> SuggestionControllerEngineFactory {
        SuggestionControllerEngineFactory(
            makeLexiconEngine: { [weak self] in
                self?.lexiconCreationCount += 1
                return LexiconPredictiveTextEngine()
            },
            makeTextCheckerEngine: { [weak self] _ in
                self?.textCheckerCreationCount += 1
                return StubPredictiveTextProvider()
            },
            makeNGramEngine: { [weak self] _ in
                self?.nGramCreationCount += 1
                return StubNGramPredictiveTextProvider()
            }
        )
    }
}

private final class StubPredictiveTextProvider: PredictiveTextProvider {
    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
}

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding {
    var currentSentenceWordsCount: Int { recordedWords.count }

    private var recordedWords: [String] = []

    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {
        recordedWords.append(word)
    }
    func endSentence() {
        recordedWords.removeAll()
    }
    func removeLastWord() {
        _ = recordedWords.popLast()
    }
    func resetSentenceBuffer() {
        recordedWords.removeAll()
    }
    func saveToDisk() {}
}
