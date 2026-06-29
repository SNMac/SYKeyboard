//
//  KeyboardSmartInputPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/30/26.
//

import UIKit

struct KeyboardSmartInputPolicy {

    struct TypedTextTransform: Equatable {
        let deleteCount: Int
        let insertText: String
    }

    static func transformTypedText(
        _ text: String,
        documentContextBeforeInput: String?,
        isSmartPunctuationEnabled: Bool,
        smartQuotesType: UITextSmartQuotesType,
        smartDashesType: UITextSmartDashesType
    ) -> TypedTextTransform {
        guard isSmartPunctuationEnabled else {
            return TypedTextTransform(deleteCount: 0, insertText: text)
        }

        if smartQuotesType == .yes,
           let smartQuote = smartQuoteText(
            for: text,
            documentContextBeforeInput: documentContextBeforeInput
           ) {
            return TypedTextTransform(deleteCount: 0, insertText: smartQuote)
        }

        if smartDashesType == .yes,
           let smartDash = smartDashTransform(
            for: text,
            documentContextBeforeInput: documentContextBeforeInput
           ) {
            return smartDash
        }

        return TypedTextTransform(deleteCount: 0, insertText: text)
    }

    static func smartInsertDeleteLeadingSpacePrefix(
        textBeforeInsertion: String,
        isSmartPunctuationEnabled: Bool,
        smartInsertDeleteType: UITextSmartInsertDeleteType
    ) -> String {
        guard isSmartPunctuationEnabled,
              smartInsertDeleteType != .no,
              !textBeforeInsertion.isEmpty,
              textBeforeInsertion.last?.isWhitespace != true else {
            return ""
        }

        return " "
    }
}

private extension KeyboardSmartInputPolicy {
    static func smartQuoteText(
        for text: String,
        documentContextBeforeInput: String?
    ) -> String? {
        switch text {
        case "\"":
            return isEvenQuoteCount(
                in: documentContextBeforeInput,
                quoteCharacters: ["\"", "“", "”"]
            ) ? "“" : "”"
        case "'":
            if isWordInternalApostropheContext(documentContextBeforeInput) {
                return "’"
            }

            return isEvenQuoteCount(
                in: documentContextBeforeInput,
                quoteCharacters: ["'", "‘", "’"]
            ) ? "‘" : "’"
        default:
            return nil
        }
    }

    static func smartDashTransform(
        for text: String,
        documentContextBeforeInput: String?
    ) -> TypedTextTransform? {
        switch text {
        case "-" where documentContextBeforeInput?.last == "-":
            return TypedTextTransform(deleteCount: 1, insertText: "—")
        case "." where documentContextBeforeInput?.hasSuffix("..") == true:
            return TypedTextTransform(deleteCount: 2, insertText: "…")
        default:
            return nil
        }
    }

    static func isEvenQuoteCount(
        in text: String?,
        quoteCharacters: Set<Character>
    ) -> Bool {
        let count = text?.reduce(0) { partialResult, character in
            partialResult + (quoteCharacters.contains(character) ? 1 : 0)
        } ?? 0

        return count.isMultiple(of: 2)
    }

    static func isWordInternalApostropheContext(_ text: String?) -> Bool {
        guard let previousCharacter = text?.last else { return false }
        return previousCharacter.isLetter || previousCharacter.isNumber
    }
}
