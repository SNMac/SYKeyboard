//
//  KeyboardSmartInputPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/30/26.
//

import UIKit

struct KeyboardSmartQuoteState: Equatable {
    private(set) var nextDoubleQuoteIsOpening = true
    private var singleQuoteInputCount = 0

    var nextSingleQuoteIsOpening: Bool {
        return (singleQuoteInputCount / 2).isMultiple(of: 2)
    }

    mutating func consume(_ transform: KeyboardSmartInputPolicy.TypedTextTransform) {
        switch transform.consumedQuoteKind {
        case .double:
            nextDoubleQuoteIsOpening.toggle()
        case .single:
            singleQuoteInputCount += 1
        case nil:
            break
        }
    }

    mutating func reset() {
        nextDoubleQuoteIsOpening = true
        singleQuoteInputCount = 0
    }
}

public enum KeyboardSmartQuoteRule {
    case koreanSystem
    case englishSystem
}

struct KeyboardSmartInputPolicy {

    struct TypedTextTransform: Equatable {
        enum QuoteKind {
            case double
            case single
        }

        let deleteCount: Int
        let insertText: String
        let consumedQuoteKind: QuoteKind?

        init(
            deleteCount: Int,
            insertText: String,
            consumedQuoteKind: QuoteKind? = nil
        ) {
            self.deleteCount = deleteCount
            self.insertText = insertText
            self.consumedQuoteKind = consumedQuoteKind
        }
    }

    static func transformTypedText(
        _ text: String,
        documentContextBeforeInput: String?,
        isSmartPunctuationEnabled: Bool,
        smartQuotesType: UITextSmartQuotesType,
        smartDashesType: UITextSmartDashesType,
        isDefaultSmartQuotesEnabled: Bool = true,
        quoteRule: KeyboardSmartQuoteRule = .koreanSystem,
        nextDoubleQuoteIsOpening: Bool = true,
        nextSingleQuoteIsOpening: Bool = true
    ) -> TypedTextTransform {
        let shouldApplySmartQuotes = shouldApplySmartQuotes(
            type: smartQuotesType,
            isDefaultSmartQuotesEnabled: isDefaultSmartQuotesEnabled
        )

        if let straightQuote = straightQuoteText(for: text),
           !isSmartPunctuationEnabled || !shouldApplySmartQuotes {
            return TypedTextTransform(deleteCount: 0, insertText: straightQuote)
        }

        guard isSmartPunctuationEnabled else {
            return TypedTextTransform(deleteCount: 0, insertText: text)
        }

        if shouldApplySmartQuotes,
           let smartQuote = smartQuoteText(
            for: text,
            documentContextBeforeInput: documentContextBeforeInput,
            quoteRule: quoteRule,
            nextDoubleQuoteIsOpening: nextDoubleQuoteIsOpening,
            nextSingleQuoteIsOpening: nextSingleQuoteIsOpening
           ) {
            return smartQuote
        }

        if smartDashesType != .no,
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
    static func shouldApplySmartQuotes(
        type: UITextSmartQuotesType,
        isDefaultSmartQuotesEnabled: Bool
    ) -> Bool {
        switch type {
        case .yes:
            return true
        case .no:
            return false
        default:
            return isDefaultSmartQuotesEnabled
        }
    }

    static func straightQuoteText(for text: String) -> String? {
        guard text.count == 1, let character = text.first else { return nil }

        if doubleQuoteCharacters.contains(character) {
            return "\""
        }

        if singleQuoteCharacters.contains(character) {
            return "'"
        }

        return nil
    }

    static func smartQuoteText(
        for text: String,
        documentContextBeforeInput: String?,
        quoteRule: KeyboardSmartQuoteRule,
        nextDoubleQuoteIsOpening: Bool,
        nextSingleQuoteIsOpening: Bool
    ) -> TypedTextTransform? {
        guard text.count == 1, let character = text.first else { return nil }

        if doubleQuoteCharacters.contains(character) {
            return TypedTextTransform(
                deleteCount: 0,
                insertText: doubleQuoteText(
                    documentContextBeforeInput: documentContextBeforeInput,
                    quoteRule: quoteRule,
                    nextDoubleQuoteIsOpening: nextDoubleQuoteIsOpening
                ),
                consumedQuoteKind: .double
            )
        }

        if singleQuoteCharacters.contains(character) {
            return TypedTextTransform(
                deleteCount: 0,
                insertText: singleQuoteText(
                    documentContextBeforeInput: documentContextBeforeInput,
                    quoteRule: quoteRule,
                    nextSingleQuoteIsOpening: nextSingleQuoteIsOpening
                ),
                consumedQuoteKind: .single
            )
        }

        return nil
    }

    static func doubleQuoteText(
        documentContextBeforeInput: String?,
        quoteRule: KeyboardSmartQuoteRule,
        nextDoubleQuoteIsOpening: Bool
    ) -> String {
        switch quoteRule {
        case .koreanSystem:
            return nextDoubleQuoteIsOpening ? "“" : "”"
        case .englishSystem:
            return shouldCloseDoubleQuote(after: documentContextBeforeInput?.last) ? "”" : "“"
        }
    }

    static func singleQuoteText(
        documentContextBeforeInput: String?,
        quoteRule: KeyboardSmartQuoteRule,
        nextSingleQuoteIsOpening: Bool
    ) -> String {
        switch quoteRule {
        case .koreanSystem:
            return nextSingleQuoteIsOpening ? "‘" : "’"
        case .englishSystem:
            return shouldCloseSingleQuote(after: documentContextBeforeInput?.last) ? "’" : "‘"
        }
    }

    static func shouldCloseDoubleQuote(after character: Character?) -> Bool {
        guard let character else { return false }
        return character.isLetter || character.isNumber || character == "“"
    }

    static func shouldCloseSingleQuote(after character: Character?) -> Bool {
        guard let character else { return false }
        return character.isLetter || character.isNumber || character == "‘"
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

    static let doubleQuoteCharacters: Set<Character> = ["\"", "“", "”"]

    static let singleQuoteCharacters: Set<Character> = ["'", "‘", "’"]
}
