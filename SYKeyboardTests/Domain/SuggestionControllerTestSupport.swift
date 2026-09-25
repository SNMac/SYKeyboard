//
//  SuggestionControllerTestSupport.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Foundation

@testable import SYKeyboardCore

// MARK: - Engine stubs

/// 후보를 돌려주지 않는 TextChecker 자리 stub
final class StubPredictiveTextProvider: PredictiveTextProvider {
    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
}

/// 주입한 텍스트 대치 항목만 돌려주는 lexicon stub
final class StubLexiconSuggestionProvider: LexiconSuggestionProviding {
    private let entries: [TextReplacementEntry]
    var hasLoadedLexicon: Bool { true }

    init(entries: [TextReplacementEntry] = []) {
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

/// 디스크를 쓰지 않는 n-gram stub. 로딩 완료 시점과 저장 횟수를 테스트가 직접 제어·관찰한다
final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding, @unchecked Sendable {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { recordedWords.count }

    private(set) var saveCount = 0
    private(set) var queriedPreferredScripts: [PredictiveTextScript?] = []
    private var recordedWords: [String] = []
    private var loadedSuggestions: [String]
    /// 선호 문자 종류별 결과. 없으면 `loadedSuggestions`를 돌려준다
    var resultsByPreferredScript: [PredictiveTextScript: [String]] = [:]
    /// 입력 중 단어 완성 조회에 돌려줄 결과. 앞에서부터 `limit`개만 돌려준다
    var completionResults: [String] = []
    /// 입력 중 단어 완성 조회에 받은 인자
    private(set) var completionQueries: [CompletionQuery] = []

    struct CompletionQuery: Equatable {
        let typedWord: String
        let previousWord: String?
        let limit: Int
    }

    init(results: [String] = []) {
        self.loadedSuggestions = results
    }

    func suggestions(for baseText: String) -> [String] { loadedSuggestions }
    func learn(word: String) {}

    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] {
        queriedPreferredScripts.append(preferredScript)
        if let preferredScript, let results = resultsByPreferredScript[preferredScript] {
            return results
        }
        return loadedSuggestions
    }

    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String] {
        completionQueries.append(CompletionQuery(typedWord: typedWord, previousWord: previousWord, limit: limit))
        return Array(completionResults.prefix(limit))
    }

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

    func removeWord(_ word: String) {}

    func completeLoad(suggestions: [String]) {
        loadedSuggestions = suggestions
        onLoadCompleted?()
    }
}

extension SuggestionControllerEngineFactory {
    /// 실제 엔진(App Group 디스크 로드, `UITextChecker`)을 만들지 않는 factory
    static var stub: SuggestionControllerEngineFactory {
        SuggestionControllerEngineFactory(
            makeLexiconEngine: { StubLexiconSuggestionProvider() },
            makeTextCheckerEngine: { _ in StubPredictiveTextProvider() },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
    }
}

/// 엔진 생성 횟수와 언어를 기록하는 factory
final class CountingSuggestionEngineFactory {

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

// MARK: - Delegate

final class RecordingSuggestionControllerDelegate: SuggestionControllerDelegate {
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

// MARK: - Waiting

/// main queue에 이미 들어간 작업이 끝날 때까지 기다린다
func waitForMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}
