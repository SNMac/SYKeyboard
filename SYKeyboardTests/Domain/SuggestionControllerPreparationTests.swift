//
//  SuggestionControllerPreparationTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/4/26.
//

import Foundation
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

    @Test("language 전환은 이전 ngram을 저장하고 새 엔진을 지연 생성")
    func testLanguageChangeSavesOldEngineAndDefersNewCreation() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.isPredictiveTextEnabled = true
        controller.preparePredictiveEnginesIfNeeded()
        let koreanEngine = factory.lastNGramProvider

        controller.updateLanguage(to: "en-US")

        #expect(koreanEngine?.saveCount == 1)
        #expect(factory.nGramLanguages == ["ko-KR"])
        controller.preparePredictiveEnginesIfNeeded()
        #expect(factory.nGramLanguages == ["ko-KR", "en-US"])
        #expect(factory.textCheckerLanguages == ["ko-KR", "en-US"])
    }

    @MainActor
    @Test("현재 language 전환 요청은 엔진과 후보를 유지")
    func testCurrentLanguageUpdateDoesNotResetEnginesOrSuggestions() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.updateSuggestions(for: "", selectedText: nil, mathExpressionText: "")
        let koreanEngine = factory.lastNGramProvider
        koreanEngine?.completeLoad(suggestions: ["오늘"])
        await waitForMainQueue()
        let updateCount = delegate.updates.count

        controller.updateLanguage(to: "ko-KR")
        controller.preparePredictiveEnginesIfNeeded()

        #expect(koreanEngine?.saveCount == 0)
        #expect(factory.nGramLanguages == ["ko-KR"])
        #expect(factory.textCheckerLanguages == ["ko-KR"])
        #expect(delegate.updates.count == updateCount)
        #expect(controller.nGramSuggestionText(at: 0) == "오늘")
    }

    @Test("이전 language load callback은 새 후보를 갱신하지 않음")
    func testStaleLanguageLoadCallbackIsIgnored() {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.updateSuggestions(for: "", selectedText: nil, mathExpressionText: "")
        let koreanEngine = factory.lastNGramProvider

        controller.updateLanguage(to: "en-US")
        let updateCount = delegate.updates.count
        koreanEngine?.completeLoad(suggestions: ["오래된 후보"])

        #expect(delegate.updates.count == updateCount)
    }

    @Test("background 이전 language load callback은 언어 전환 뒤 후보를 재갱신하지 않음")
    func testBackgroundStaleLanguageLoadCallbackIsIgnoredAfterLanguageChange() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.updateSuggestions(for: "", selectedText: nil, mathExpressionText: "")
        let koreanEngine = factory.lastNGramProvider
        let completionReturned = DispatchSemaphore(value: 0)

        let updateCount = await MainActor.run {
            DispatchQueue.global(qos: .userInitiated).async {
                koreanEngine?.completeLoad(suggestions: ["오래된 후보"])
                completionReturned.signal()
            }
            #expect(completionReturned.wait(timeout: .now() + 1) == .success)

            controller.updateLanguage(to: "en-US")
            controller.updateSuggestions(for: "", selectedText: nil, mathExpressionText: "")
            return delegate.updates.count
        }

        await Task.yield()
        await waitForMainQueue()

        await MainActor.run {
            #expect(delegate.updates.count == updateCount)
            #expect(delegate.updates.last?.suggestions == [])
        }
    }

    @Test("n-gram 로딩 완료 후 마지막 후보 갱신을 다시 수행")
    func testNGram로딩완료후_마지막후보갱신을다시수행() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "")
        #expect(delegate.updates.last?.suggestions == [])

        factory.lastNGramProvider?.completeLoad(suggestions: ["오늘", "내일"])
        await waitForMainQueue()

        #expect(delegate.updates.last?.currentWord == nil)
        #expect(delegate.updates.last?.suggestions == ["오늘", "내일"])
    }

    @Test("n-gram 로딩 완료 callback이 background에서 호출되어도 후보 갱신은 main에서 수행")
    func testNGram로딩완료Callback_background호출_main갱신() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "")
        let provider = factory.lastNGramProvider

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                provider?.completeLoad(suggestions: ["오늘", "내일"])
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }
        }

        #expect(delegate.updates.last?.suggestions == ["오늘", "내일"])
        #expect(delegate.updateIsMainThread.last == true)
    }

    @Test("후보 초기화 후 n-gram 로딩 완료는 마지막 후보를 다시 갱신하지 않음")
    func test후보초기화후_NGram로딩완료_후보갱신없음() {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = SuggestionController(
            language: "ko-KR",
            engineFactory: factory.makeFactory()
        )
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "")
        controller.clearSuggestions()
        let updateCountAfterClear = delegate.updates.count

        factory.lastNGramProvider?.completeLoad(suggestions: ["오늘", "내일"])

        #expect(delegate.updates.count == updateCountAfterClear)
        #expect(delegate.updates.last?.suggestions == [])
    }
}

private final class CountingSuggestionEngineFactory {

    // MARK: - Properties

    private(set) var lexiconCreationCount = 0
    private(set) var textCheckerCreationCount = 0
    private(set) var nGramCreationCount = 0
    private(set) var textCheckerLanguages: [String] = []
    private(set) var nGramLanguages: [String] = []
    private(set) var nGramProviders: [StubNGramPredictiveTextProvider] = []
    private(set) var lastNGramProvider: StubNGramPredictiveTextProvider?

    // MARK: - Internal Methods

    func makeFactory() -> SuggestionControllerEngineFactory {
        SuggestionControllerEngineFactory(
            makeLexiconEngine: { [weak self] in
                self?.lexiconCreationCount += 1
                return LexiconPredictiveTextEngine()
            },
            makeTextCheckerEngine: { [weak self] language in
                self?.textCheckerCreationCount += 1
                self?.textCheckerLanguages.append(language)
                return StubPredictiveTextProvider()
            },
            makeNGramEngine: { [weak self] language in
                self?.nGramCreationCount += 1
                self?.nGramLanguages.append(language)
                let provider = StubNGramPredictiveTextProvider()
                self?.nGramProviders.append(provider)
                self?.lastNGramProvider = provider
                return provider
            }
        )
    }
}

private final class StubPredictiveTextProvider: PredictiveTextProvider {
    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
}

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding, @unchecked Sendable {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { recordedWords.count }
    private(set) var saveCount = 0

    private var recordedWords: [String] = []
    private var loadedSuggestions: [String] = []

    func suggestions(for baseText: String) -> [String] { loadedSuggestions }
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
    func saveToDisk() {
        saveCount += 1
    }
    func completeLoad(suggestions: [String]) {
        loadedSuggestions = suggestions
        onLoadCompleted?()
    }
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
