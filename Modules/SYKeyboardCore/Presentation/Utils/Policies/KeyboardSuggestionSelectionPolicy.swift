//
//  KeyboardSuggestionSelectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

enum KeyboardSuggestionSelectionPolicy {

    enum SuggestionUpdateAction: Equatable {
        case none
        case update(String)
        case clear
    }

    static func shouldInsertLeadingSpaceBeforeNGramSuggestion(inputBuffer: String) -> Bool {
        return !inputBuffer.isEmpty && inputBuffer.last?.isWhitespace != true
    }

    static func currentWordForConfirmation(inputBuffer: String) -> String {
        return inputBuffer.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
    }

    static func shouldLoadLexicon(
        isTextReplacementEnabled: Bool,
        isPredictiveTextEnabled: Bool
    ) -> Bool {
        return isTextReplacementEnabled || isPredictiveTextEnabled
    }

    static func shouldStartLexiconLoadBeforeFirstAppearance(
        isTextReplacementEnabled: Bool
    ) -> Bool {
        return isTextReplacementEnabled
    }

    static func shouldUpdateInitialSuggestionsAfterDeferredPreparation(
        shouldPreparePredictiveEngines: Bool
    ) -> Bool {
        return shouldPreparePredictiveEngines
    }

    static func shouldUpdateSuggestionsOnTextDidChange(
        isPrimaryCursorDragging: Bool
    ) -> Bool {
        return !isPrimaryCursorDragging
    }

    static func limitedDocumentContextBeforeInput(_ context: String?) -> String {
        guard let context else { return "" }
        return String(context.suffix(KeyboardTextContextNavigator.maximumCursorRestoreDistance))
    }

    static func mathExpressionDetectionText(
        selectedText: String?,
        inputBuffer: String,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        }
        if !inputBuffer.isEmpty {
            return inputBuffer
        }
        return limitedDocumentContextBeforeInput(documentContextBeforeInput)
    }

    static func textReplacementRestoreDeleteCount(
        documentText: String,
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> Int? {
        guard !documentText.isEmpty else { return nil }
        if selectedText?.isEmpty == false { return nil }

        if let deleteCount = restoreDeleteCount(
            in: inputBuffer,
            documentText: documentText
        ) {
            return deleteCount
        }

        guard inputBuffer.isEmpty,
              let documentContextBeforeInput else { return nil }

        return restoreDeleteCount(
            in: documentContextBeforeInput,
            documentText: documentText
        )
    }

    static func suggestionUpdateAction(
        isPredictiveTextEnabled: Bool,
        selectedText: String?,
        inputBuffer: String
    ) -> SuggestionUpdateAction {
        guard isPredictiveTextEnabled else { return .none }

        if let selectedText, !selectedText.isEmpty {
            if selectedText.contains(where: { $0.isWhitespace }),
               MathExpressionCompletionEvaluator.completion(
                   for: selectedText
               ) == nil {
                return .clear
            }
            return .update(selectedText)
        }

        return .update(inputBuffer)
    }

}

private extension KeyboardSuggestionSelectionPolicy {

    static func restoreDeleteCount(
        in text: String,
        documentText: String
    ) -> Int? {
        return text.hasSuffix(documentText) ? documentText.count : nil
    }
}
