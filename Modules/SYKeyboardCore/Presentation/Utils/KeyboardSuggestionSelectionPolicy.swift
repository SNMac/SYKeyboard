//
//  KeyboardSuggestionSelectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

enum KeyboardSuggestionSelectionPolicy {

    static func shouldInsertLeadingSpaceBeforeNGramSuggestion(inputBuffer: String) -> Bool {
        return !inputBuffer.isEmpty && inputBuffer.last?.isWhitespace != true
    }

    static func currentWordForConfirmation(inputBuffer: String) -> String {
        return inputBuffer.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
    }
}
