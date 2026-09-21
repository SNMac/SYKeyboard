//
//  KeyboardSmartInputPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/30/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("Smart Punctuation 입력 정책")
struct KeyboardSmartInputPolicyTests {

    @Test("설정이 꺼져 있으면 smart quotes는 straight quote로 정규화하고 dashes는 적용하지 않음")
    func testTypedTextTransformRequiresAppSetting() {
        let doubleQuote = transform("“", enabled: false, dashes: .yes)
        let singleQuote = transform("‘", enabled: false, dashes: .yes)
        let dash = transform("-", before: "-", enabled: false, dashes: .yes)

        #expect(doubleQuote == .init(deleteCount: 0, insertText: "\""))
        #expect(singleQuote == .init(deleteCount: 0, insertText: "'"))
        #expect(dash == .init(deleteCount: 0, insertText: "-"))
    }

    @Test("smart quotes는 키보드별 default 해석이 enabled이면 default에서 적용")
    func testSmartQuotesDefaultEnabledByKeyboardPolicy() {
        let defaultResult = transform("\"", quotes: .default)

        #expect(defaultResult.insertText == "“")
    }

    @Test("smart quotes는 키보드별 default 해석이 disabled이면 default에서 straight quote로 삽입")
    func testSmartQuotesDefaultDisabledByKeyboardPolicy() {
        let defaultResult = transform("“", quotes: .default, defaultQuotes: false)

        #expect(defaultResult.insertText == "\"")
    }

    @Test("smart quotes는 trait yes에서 항상 적용하고 no에서만 적용하지 않음")
    func testSmartQuotesExplicitTraitsOverrideKeyboardDefaultPolicy() {
        let noResult = transform("“", quotes: .no)
        let yesResult = transform("\"", defaultQuotes: false)

        #expect(noResult.insertText == "\"")
        #expect(yesResult.insertText == "“")
    }

    @Test("smart quotes trait이 no이면 표시용 quote도 straight quote로 삽입")
    func testSmartQuotesNoTraitNormalizesDisplayQuotesToStraightQuotes() {
        let doubleQuote = transform("“", quotes: .no)
        let closingSingleQuote = transform("’", quotes: .no)
        let openingSingleQuote = transform("‘", quotes: .no)

        #expect(doubleQuote == .init(deleteCount: 0, insertText: "\""))
        #expect(closingSingleQuote == .init(deleteCount: 0, insertText: "'"))
        #expect(openingSingleQuote == .init(deleteCount: 0, insertText: "'"))
    }

    @Test("double quote는 다음 입력 상태에 따라 여는 따옴표나 닫는 따옴표를 삽입")
    func testDoubleQuoteUsesNextOpeningState() {
        let first = transform("\"", before: nil)
        let second = transform("\"", before: nil, nextOpening: false)

        #expect(first.insertText == "“")
        #expect(first.consumedQuoteKind == .double)
        #expect(second.insertText == "”")
        #expect(second.consumedQuoteKind == .double)
    }

    @Test("한국어 single quote는 가장 최근 여는 따옴표 뒤 내용 유무로 여닫음을 결정")
    func testKoreanSingleQuoteUsesContentAfterOpeningQuote() {
        let contexts: [String?] = [nil, "한글", "‘", "‘‘", "‘한글", "‘ ", "‘!", "‘한글’"]
        let results = contexts.map {
            transform("'", before: $0).insertText
        }

        #expect(results == ["‘", "‘", "‘", "‘", "’", "’", "’", "‘"])
    }

    @Test("영어 single quote는 커서 앞 문맥으로 여닫는 따옴표를 결정")
    func testEnglishSingleQuoteUsesPrecedingContext() {
        let afterLetter = transform("'", before: "don", rule: .englishSystem)
        let afterOpeningSingleQuote = transform("'", before: "‘", rule: .englishSystem)
        let afterClosingSingleQuote = transform("'", before: "’", rule: .englishSystem)
        let afterWhitespace = transform("'", before: " ", rule: .englishSystem)

        #expect(afterLetter.insertText == "’")
        #expect(afterOpeningSingleQuote.insertText == "’")
        #expect(afterClosingSingleQuote.insertText == "‘")
        #expect(afterWhitespace.insertText == "‘")
    }

    @Test("영어 double quote는 커서 앞 문맥으로 여닫는 따옴표를 결정")
    func testEnglishDoubleQuoteUsesPrecedingContext() {
        let afterNumber = transform("\"", before: "1", rule: .englishSystem)
        let afterOpeningDoubleQuote = transform("\"", before: "“", rule: .englishSystem)
        let afterClosingDoubleQuote = transform("\"", before: "”", rule: .englishSystem)
        let afterPunctuation = transform("\"", before: ".", rule: .englishSystem)

        #expect(afterNumber.insertText == "”")
        #expect(afterOpeningDoubleQuote.insertText == "”")
        #expect(afterClosingDoubleQuote.insertText == "“")
        #expect(afterPunctuation.insertText == "“")
    }

    @Test("symbol 키보드의 curly quote 입력도 smart quote 대상으로 정규화")
    func testCurlyQuoteInputIsNormalizedBeforeTransform() {
        let openingSingle = transform("’")
        let closingSingle = transform("’", before: "‘한글")
        let openingDouble = transform("“")
        let closingDouble = transform("“", nextOpening: false)

        #expect(openingSingle.insertText == "‘")
        #expect(closingSingle.insertText == "’")
        #expect(openingDouble.insertText == "“")
        #expect(closingDouble.insertText == "”")
    }

    @Test("quote 상태는 삭제 시 되돌리지 않고 다음 입력에 닫는 따옴표를 사용")
    func testQuoteStateIsNotRevertedByDelete() {
        var state = KeyboardSmartQuoteState()

        let first = transform("\"", before: nil, nextOpening: state.nextDoubleQuoteIsOpening)
        state.consume(first)

        let secondAfterDelete = transform("\"", before: nil, nextOpening: state.nextDoubleQuoteIsOpening)

        #expect(first.insertText == "“")
        #expect(secondAfterDelete.insertText == "”")
    }

    @Test("smart dashes는 trait default 또는 yes에서 em dash와 ellipsis를 적용하고 no에서만 적용하지 않음")
    func testSmartDashesTreatDefaultAsYes() {
        let defaultDash = transform("-", before: "-", quotes: .no, dashes: .default)
        let defaultEllipsis = transform(".", before: "..", quotes: .no, dashes: .default)
        let noDash = transform("-", before: "-", quotes: .no)
        let emDash = transform("-", before: "-", quotes: .no, dashes: .yes)
        let ellipsis = transform(".", before: "..", quotes: .no, dashes: .yes)

        #expect(defaultDash == .init(deleteCount: 1, insertText: "—"))
        #expect(defaultEllipsis == .init(deleteCount: 2, insertText: "…"))
        #expect(noDash == .init(deleteCount: 0, insertText: "-"))
        #expect(emDash == .init(deleteCount: 1, insertText: "—"))
        #expect(ellipsis == .init(deleteCount: 2, insertText: "…"))
    }

    @Test("smart insert/delete는 설정 on이고 trait이 default 또는 yes일 때만 앞 공백을 보정")
    func testSmartInsertDeleteSpacingPolicy() {
        #expect(KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: "hello",
            isSmartPunctuationEnabled: true,
            smartInsertDeleteType: .default
        ) == " ")
        #expect(KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: "hello",
            isSmartPunctuationEnabled: true,
            smartInsertDeleteType: .yes
        ) == " ")
        #expect(KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: "hello",
            isSmartPunctuationEnabled: true,
            smartInsertDeleteType: .no
        ) == "")
        #expect(KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: "hello ",
            isSmartPunctuationEnabled: true,
            smartInsertDeleteType: .yes
        ) == "")
        #expect(KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: "hello",
            isSmartPunctuationEnabled: false,
            smartInsertDeleteType: .yes
        ) == "")
    }

    // MARK: - Helper

    /// 테스트마다 달라지는 인자만 드러나도록 나머지는 가장 흔한 값으로 채운다
    private func transform(
        _ text: String,
        before: String? = "",
        enabled: Bool = true,
        quotes: UITextSmartQuotesType = .yes,
        dashes: UITextSmartDashesType = .no,
        defaultQuotes: Bool = true,
        rule: KeyboardSmartQuoteRule = .koreanSystem,
        nextOpening: Bool = true
    ) -> KeyboardSmartInputPolicy.TypedTextTransform {
        KeyboardSmartInputPolicy.transformTypedText(
            text,
            documentContextBeforeInput: before,
            isSmartPunctuationEnabled: enabled,
            smartQuotesType: quotes,
            smartDashesType: dashes,
            isDefaultSmartQuotesEnabled: defaultQuotes,
            quoteRule: rule,
            nextDoubleQuoteIsOpening: nextOpening
        )
    }
}
