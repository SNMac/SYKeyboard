//
//  FakeSuggestionService.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import UIKit

@testable import SYKeyboardCore

/// `SuggestionService` 호출을 기록하고 미리 정한 값을 돌려준다. Coordinator 테스트 전용
final class FakeSuggestionService: SuggestionService {

    // MARK: - Stubbed Values

    var currentMode: SuggestionMode = .typing
    var mathResultActionResult: MathResultSuggestionAction?
    var nGramSuggestionTextResult: String?
    var selectSuggestionResult: (deleteCount: Int, insertText: String)?
    var removableSuggestionTextResult: String?
    var removableBarIndices = IndexSet()
    var sentenceWordsSnapshotResult: [String] = []
    var textReplacementPreviewSuggestionIndexResult: Int?

    // MARK: - Records

    private(set) var calls: [String] = []
    private(set) var learnedWords: [String] = []
    private(set) var recordedWords: [String] = []
    private(set) var removedWords: [String] = []
    private(set) var endedSentences: [(inputBuffer: String, sentenceWords: [String])] = []
    private(set) var selectSuggestionArguments: [(index: Int, baseText: String, textReplacementBaseText: String)] = []
    private(set) var mathResultActionArguments: [(index: Int, selectedText: String?)] = []

    // MARK: - SuggestionService

    weak var delegate: SuggestionControllerDelegate?
    var isPredictiveTextEnabled = true
    var isTextReplacementEnabled = true
    var isShowMathResultsEnabled = true
    var isSuspended = false

    func updateLanguage(to language: String) { calls.append("updateLanguage(\(language))") }
    func preparePredictiveEnginesIfNeeded() { calls.append("preparePredictiveEnginesIfNeeded") }
    func releaseInactiveLanguageEngines() { calls.append("releaseInactiveLanguageEngines") }
    func prepareLexiconEngineIfNeeded() { calls.append("prepareLexiconEngineIfNeeded") }
    func loadLexicon(from inputViewController: UIInputViewController) { calls.append("loadLexicon") }

    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String,
        textReplacementBaseText: String
    ) {
        calls.append("updateSuggestions(\(baseText))")
    }

    func updateSuggestionsAfterNGramSelection(baseText: String, textReplacementBaseText: String) {
        calls.append("updateSuggestionsAfterNGramSelection(\(baseText), \(textReplacementBaseText))")
    }

    func clearSuggestions() { calls.append("clearSuggestions") }

    func selectSuggestion(
        at index: Int,
        baseText: String,
        textReplacementBaseText: String
    ) -> (deleteCount: Int, insertText: String)? {
        selectSuggestionArguments.append((index, baseText, textReplacementBaseText))
        calls.append("selectSuggestion(\(index), \(baseText))")
        return selectSuggestionResult
    }

    func nGramSuggestionText(at index: Int) -> String? {
        calls.append("nGramSuggestionText(\(index))")
        return nGramSuggestionTextResult
    }

    func removableSuggestionText(atBarIndex index: Int) -> String? {
        calls.append("removableSuggestionText(\(index))")
        return removableSuggestionTextResult
    }

    func invalidateLearnedWordsCache() { calls.append("invalidateLearnedWordsCache") }
    func removeSuggestionWord(_ word: String) { removedWords.append(word) }

    func mathResultAction(at index: Int, selectedText: String?) -> MathResultSuggestionAction? {
        mathResultActionArguments.append((index, selectedText))
        calls.append("mathResultAction(\(index))")
        return mathResultActionResult
    }

    func textReplacementPreviewSuggestionIndex(baseText: String) -> Int? {
        calls.append("textReplacementPreviewSuggestionIndex(\(baseText))")
        return textReplacementPreviewSuggestionIndexResult
    }

    func learnWord(_ word: String) { learnedWords.append(word) }
    func recordWord(_ word: String) { recordedWords.append(word) }
    func endSentence(inputBuffer: String) { endedSentences.append((inputBuffer, [])) }
    func sentenceWordsSnapshot() -> [String] { sentenceWordsSnapshotResult }
    func endSentence(inputBuffer: String, restoringSentenceWords sentenceWords: [String]) {
        endedSentences.append((inputBuffer, sentenceWords))
    }
    func saveNGramData() { calls.append("saveNGramData") }
    func recordUncommittedWords(from inputBuffer: String) { calls.append("recordUncommittedWords(\(inputBuffer))") }
    func removeLastRecordedWord() { calls.append("removeLastRecordedWord") }
    func resetSentenceBuffer() { calls.append("resetSentenceBuffer") }

    func attemptTextReplacement(
        baseText: String,
        documentContextBeforeInput: String?
    ) -> (deleteCount: Int, insertText: String)? {
        calls.append("attemptTextReplacement(\(baseText))")
        return nil
    }

    func attemptRestoreReplacement(
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> (deleteCount: Int, insertText: String)? {
        calls.append("attemptRestoreReplacement(\(inputBuffer))")
        return nil
    }

    func clearIgnoredShortcut() { calls.append("clearIgnoredShortcut") }
    func clearReplacementHistory() { calls.append("clearReplacementHistory") }
}
