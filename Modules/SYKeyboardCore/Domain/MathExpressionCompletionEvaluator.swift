//
//  MathExpressionCompletionEvaluator.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/30/26.
//

import Foundation

struct MathExpressionCompletion: Equatable {
    let expressionText: String
    let displayText: String
    let insertText: String
}

enum MathExpressionCompletionEvaluator {
    static let maximumInputLength = 256
    private static let allowedExpressionCharacters = Set(
        "0123456789,.+-*/×⋅xX÷=()[]{}"
    )
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter
    }()
    private static let scientificFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 3
        return formatter
    }()

    static func completion(for text: String) -> MathExpressionCompletion? {
        guard text.last == "=" else { return nil }
        guard text.dropFirst(maximumInputLength).isEmpty else { return nil }

        for expressionText in expressionSuffixCandidates(beforeEqualIn: text) {
            if let completion = completion(forExpressionText: expressionText) {
                return completion
            }
        }

        return nil
    }
}

private extension MathExpressionCompletionEvaluator {
    static func completion(
        forExpressionText expressionText: String
    ) -> MathExpressionCompletion? {
        let expressionBody = String(expressionText.dropLast())
        guard !expressionBody.contains("=") else { return nil }
        guard !containsWhitespaceBetweenNumberComponents(expressionBody) else {
            return nil
        }

        var parser = MathExpressionParser(expressionBody)
        guard let value = parser.evaluate() else { return nil }

        guard let resultText = formattedResult(value) else { return nil }
        return MathExpressionCompletion(
            expressionText: expressionText,
            displayText: expressionText + resultText,
            insertText: resultText
        )
    }

    static var scientificNotationThreshold: Double {
        10_000_000_000
    }

    static func expressionSuffixCandidates(
        beforeEqualIn text: String
    ) -> [String] {
        let expressionText = expressionSuffix(beforeEqualIn: text)
        var candidates = [expressionText]

        appendLastLineCandidate(in: text, to: &candidates)
        appendWordEndingMultiplicationCandidate(
            expressionText: expressionText,
            originalText: text,
            to: &candidates
        )
        appendCandidateAfterPreviousResult(
            in: expressionText,
            to: &candidates
        )

        guard expressionText == String(text.drop { $0.isWhitespace }) else {
            return candidates
        }

        var index = expressionText.startIndex
        while index < expressionText.endIndex {
            guard expressionText[index] == " " else {
                index = expressionText.index(after: index)
                continue
            }

            let whitespaceStartIndex = index
            repeat {
                index = expressionText.index(after: index)
            } while index < expressionText.endIndex && expressionText[index] == " "

            guard whitespaceStartIndex > expressionText.startIndex,
                  index < expressionText.endIndex else {
                continue
            }

            let previousIndex = expressionText.index(before: whitespaceStartIndex)
            guard expressionText[previousIndex].isNumber,
                  expressionText[index].isNumber else {
                continue
            }

            let context = expressionText[..<index]
            guard context.allSatisfy({
                $0.isNumber || $0 == " "
            }) else {
                continue
            }

            candidates.append(String(expressionText[index...]))
        }

        return candidates
    }

    static func appendLastLineCandidate(
        in text: String,
        to candidates: inout [String]
    ) {
        guard let newlineIndex = text.lastIndex(where: { $0.isNewline }) else {
            return
        }

        let candidateStartIndex = text.index(after: newlineIndex)
        appendCandidate(text[candidateStartIndex...], to: &candidates)
    }

    static func appendWordEndingMultiplicationCandidate(
        expressionText: String,
        originalText: String,
        to candidates: inout [String]
    ) {
        guard expressionText.first == "x" || expressionText.first == "X",
              let expressionStartIndex = originalText.index(
                  originalText.endIndex,
                  offsetBy: -expressionText.count,
                  limitedBy: originalText.startIndex
              ),
              expressionStartIndex > originalText.startIndex else {
            return
        }

        let previousIndex = originalText.index(before: expressionStartIndex)
        guard originalText[previousIndex].isLetter,
              let whitespaceIndex = expressionText.firstIndex(
                  where: { $0.isWhitespace }
              ),
              let candidate = suffixAfterWhitespaceRun(
                  startingAt: whitespaceIndex,
                  in: expressionText
              ) else {
            return
        }

        appendCandidate(candidate, to: &candidates)
    }

    static func appendCandidateAfterPreviousResult(
        in expressionText: String,
        to candidates: inout [String]
    ) {
        let expressionBody = expressionText.dropLast()
        guard let previousEqualIndex = expressionBody.lastIndex(of: "=") else {
            return
        }

        let resultStartIndex = expressionBody.index(after: previousEqualIndex)
        guard resultStartIndex < expressionBody.endIndex,
              let whitespaceIndex = expressionBody[resultStartIndex...]
                  .firstIndex(where: { $0.isWhitespace }) else {
            return
        }

        let resultToken = expressionBody[resultStartIndex..<whitespaceIndex]
        guard isMathResultToken(resultToken),
              let candidate = suffixAfterWhitespaceRun(
                  startingAt: whitespaceIndex,
                  in: expressionText
              ) else {
            return
        }

        appendCandidate(candidate, to: &candidates)
    }

    static func isMathResultToken(_ token: Substring) -> Bool {
        guard token.contains(where: { $0.isNumber }) else { return false }

        return token.enumerated().allSatisfy { offset, character in
            character.isNumber
                || character == "."
                || character == ","
                || (offset == 0 && character == "-")
        }
    }

    static func suffixAfterWhitespaceRun(
        startingAt whitespaceIndex: String.Index,
        in text: String
    ) -> Substring? {
        var index = whitespaceIndex
        while index < text.endIndex, text[index].isWhitespace {
            index = text.index(after: index)
        }

        guard index < text.endIndex else { return nil }
        return text[index...]
    }

    static func appendCandidate(
        _ candidate: Substring,
        to candidates: inout [String]
    ) {
        let text = String(candidate.drop(while: { $0.isWhitespace }))
        guard !text.isEmpty, !candidates.contains(text) else { return }
        candidates.append(text)
    }

    static func expressionSuffix(beforeEqualIn text: String) -> String {
        let reversedSuffix = text.reversed().prefix {
            allowedExpressionCharacters.contains($0) || $0.isWhitespace
        }
        let suffix = String(reversedSuffix.reversed())

        return String(suffix.drop { $0.isWhitespace })
    }

    static func containsWhitespaceBetweenNumberComponents(
        _ expression: String
    ) -> Bool {
        var previousNonWhitespace: Character?
        var hasWhitespaceAfterPrevious = false

        for character in expression {
            if character.isWhitespace {
                if previousNonWhitespace != nil {
                    hasWhitespaceAfterPrevious = true
                }
                continue
            }

            if hasWhitespaceAfterPrevious,
               let previousNonWhitespace,
               isNumberComponent(previousNonWhitespace),
               isNumberComponent(character) {
                return true
            }

            previousNonWhitespace = character
            hasWhitespaceAfterPrevious = false
        }

        return false
    }

    static func isNumberComponent(_ character: Character) -> Bool {
        return character.isNumber || character == "." || character == ","
    }

    static func formattedResult(_ value: Double) -> String? {
        guard value.isFinite else { return nil }

        if abs(value) >= scientificNotationThreshold {
            return scientificResult(value)
        }

        return decimalResult(value)
    }

    static func decimalResult(_ value: Double) -> String? {
        let roundedValue = (value * 1000).rounded() / 1000
        let normalizedValue = roundedValue == 0 ? 0.0 : roundedValue

        return decimalFormatter.string(from: NSNumber(value: normalizedValue))
    }

    static func scientificResult(_ value: Double) -> String? {
        var exponent = Int(floor(log10(abs(value))))
        let divisor = pow(10, Double(exponent))
        var mantissa = value / divisor
        mantissa = (mantissa * 1000).rounded() / 1000

        if abs(mantissa) >= 10 {
            mantissa /= 10
            exponent += 1
        }

        guard let mantissaText = scientificFormatter.string(
            from: NSNumber(value: mantissa)
        ),
              let exponentText = superscriptText(for: exponent) else {
            return nil
        }

        return "\(mantissaText)×10\(exponentText)"
    }

    static func superscriptText(for exponent: Int) -> String? {
        let characters: [Character: Character] = [
            "-": "⁻",
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
        ]

        let result = String(String(exponent).compactMap { characters[$0] })
        return result.count == String(exponent).count ? result : nil
    }
}

private struct MathExpressionParser {
    private static let maximumNestingDepth = 16

    private let characters: [Character]
    private var index = 0
    private var hasBinaryOperator = false
    private var nestingDepth = 0

    init(_ expression: String) {
        characters = expression.compactMap { character -> Character? in
            guard !character.isWhitespace else { return nil }

            switch character {
            case "×", "⋅", "x", "X":
                return "*"
            case "÷":
                return "/"
            default:
                return character
            }
        }
    }

    mutating func evaluate() -> Double? {
        guard !characters.isEmpty else { return nil }
        guard let value = parseExpression() else { return nil }
        guard index == characters.count else { return nil }
        guard hasBinaryOperator else { return nil }
        guard value.isFinite else { return nil }

        return value
    }
}

private extension MathExpressionParser {
    mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }

        while let current = peek(), current == "+" || current == "-" {
            hasBinaryOperator = true
            index += 1
            guard let nextValue = parseTerm() else { return nil }
            let result = current == "+" ? value + nextValue : value - nextValue
            guard result.isFinite else { return nil }
            value = result
        }

        return value
    }

    mutating func parseTerm() -> Double? {
        guard var value = parseFactor() else { return nil }

        while let current = peek(), current == "*" || current == "/" {
            hasBinaryOperator = true
            index += 1
            guard let nextValue = parseFactor() else { return nil }

            if current == "*" {
                let result = value * nextValue
                guard result.isFinite else { return nil }
                value = result
            } else {
                guard nextValue != 0 else { return nil }
                let result = value / nextValue
                guard result.isFinite else { return nil }
                value = result
            }
        }

        return value
    }

    mutating func parseFactor() -> Double? {
        if index == 0, peek() == "-" {
            index += 1
            guard let value = parsePrimary() else { return nil }
            let result = -value
            return result.isFinite ? result : nil
        }

        if peek() == "+" || peek() == "-" {
            return nil
        }

        return parsePrimary()
    }

    mutating func parsePrimary() -> Double? {
        if let closingBracket = closingBracket(for: peek()) {
            guard nestingDepth < Self.maximumNestingDepth else { return nil }
            nestingDepth += 1
            defer { nestingDepth -= 1 }

            index += 1
            guard let value = parseExpression() else { return nil }
            guard peek() == closingBracket else { return nil }
            index += 1
            return value.isFinite ? value : nil
        }

        return parseNumber()
    }

    mutating func parseNumber() -> Double? {
        let integerStartIndex = index

        while let current = peek(), current.isNumber || current == "," {
            index += 1
        }

        let integerText = String(characters[integerStartIndex..<index])
        let hasIntegerPart = !integerText.isEmpty
        if hasIntegerPart {
            guard isValidIntegerText(integerText) else { return nil }
        } else {
            guard peek() == "." else { return nil }
        }

        var numberText = hasIntegerPart
            ? integerText.replacingOccurrences(of: ",", with: "")
            : "0"

        if peek() == "." {
            numberText.append(".")
            index += 1

            let fractionalStartIndex = index

            while let current = peek(), current.isNumber {
                numberText.append(current)
                index += 1
            }

            if !hasIntegerPart && fractionalStartIndex == index {
                return nil
            }
        }

        if numberText.last == "." {
            numberText.removeLast()
        }

        guard let value = Double(numberText),
              value.isFinite else { return nil }
        return value
    }

    func isValidIntegerText(_ text: String) -> Bool {
        let groups = text.split(separator: ",", omittingEmptySubsequences: false)
        guard !groups.isEmpty,
              groups.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else {
            return false
        }

        guard groups.count > 1 else { return true }
        guard (1...3).contains(groups[0].count) else { return false }
        return groups.dropFirst().allSatisfy { $0.count == 3 }
    }

    func peek() -> Character? {
        guard index < characters.count else { return nil }
        return characters[index]
    }

    func closingBracket(for character: Character?) -> Character? {
        switch character {
        case "(":
            return ")"
        case "[":
            return "]"
        case "{":
            return "}"
        default:
            return nil
        }
    }
}
