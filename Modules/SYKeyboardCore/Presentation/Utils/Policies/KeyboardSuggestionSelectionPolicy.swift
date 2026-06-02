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

    static func suggestionUpdateAction(
        isPredictiveTextEnabled: Bool,
        selectedText: String?,
        inputBuffer: String
    ) -> SuggestionUpdateAction {
        guard isPredictiveTextEnabled else { return .none }

        if let selectedText, !selectedText.isEmpty {
            if selectedText.contains(where: { $0.isWhitespace }) {
                return .clear
            }
            return .update(selectedText)
        }

        return .update(inputBuffer)
    }
}
