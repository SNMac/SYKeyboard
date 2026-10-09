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

    @Test("설정 off나 quote trait no에서는 straight quote로 정규화하고, smart dashes는 설정 off나 trait no에서 적용하지 않음",
          arguments: [
            // (text, before, enabled, quotes, dashes, expected)
            // 설정이 꺼져 있으면 smart quotes는 straight quote로 정규화하고 dashes는 적용하지 않음
            ("“", "", false, UITextSmartQuotesType.yes, UITextSmartDashesType.yes,
             KeyboardSmartInputPolicy.TypedTextTransform(deleteCount: 0, insertText: "\"")),
            ("‘", "", false, .yes, .yes, .init(deleteCount: 0, insertText: "'")),
            ("-", "-", false, .yes, .yes, .init(deleteCount: 0, insertText: "-")),
            // smart quotes trait이 no이면 표시용 quote도 straight quote로 삽입
            ("“", "", true, .no, .no, .init(deleteCount: 0, insertText: "\"")),
            ("’", "", true, .no, .no, .init(deleteCount: 0, insertText: "'")),
            ("‘", "", true, .no, .no, .init(deleteCount: 0, insertText: "'")),
            // smart dashes는 trait default 또는 yes에서 em dash와 ellipsis를 적용하고 no에서만 적용하지 않음
            ("-", "-", true, .no, .default, .init(deleteCount: 1, insertText: "—")),
            (".", "..", true, .no, .default, .init(deleteCount: 2, insertText: "…")),
            ("-", "-", true, .no, .no, .init(deleteCount: 0, insertText: "-")),
            ("-", "-", true, .no, .yes, .init(deleteCount: 1, insertText: "—")),
            (".", "..", true, .no, .yes, .init(deleteCount: 2, insertText: "…"))
          ])
    func testTypedTextTransform(
        text: String,
        before: String,
        enabled: Bool,
        quotes: UITextSmartQuotesType,
        dashes: UITextSmartDashesType,
        expected: KeyboardSmartInputPolicy.TypedTextTransform
    ) {
        #expect(transform(text, before: before, enabled: enabled, quotes: quotes, dashes: dashes) == expected)
    }

    @Test("smart quotes는 trait default면 키보드별 default 해석을 따르고 trait yes면 항상 적용",
          arguments: [
            // (text, quotes, defaultQuotes, insertText)
            // 키보드별 default 해석이 enabled이면 default에서 적용
            ("\"", UITextSmartQuotesType.default, true, "“"),
            // 키보드별 default 해석이 disabled이면 default에서 straight quote로 삽입
            ("“", .default, false, "\""),
            // trait no는 키보드별 default 해석이 enabled여도 straight quote
            ("“", .no, true, "\""),
            // trait yes는 키보드별 default 해석이 disabled여도 적용
            ("\"", .yes, false, "“")
          ])
    func testSmartQuotesTraitAndKeyboardDefaultPolicy(
        text: String,
        quotes: UITextSmartQuotesType,
        defaultQuotes: Bool,
        insertText: String
    ) {
        #expect(transform(text, quotes: quotes, defaultQuotes: defaultQuotes).insertText == insertText)
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

    @Test("single·double quote의 여닫음은 quote 규칙과 커서 앞 문맥으로 정하고 curly quote 입력도 같은 규칙으로 정규화",
          arguments: [
            // (text, before, rule, nextOpening, insertText)
            // 한국어 single quote는 가장 최근 여는 따옴표 뒤 내용 유무로 여닫음을 결정
            ("'", String?.none, KeyboardSmartQuoteRule.koreanSystem, true, "‘"),
            ("'", "한글", .koreanSystem, true, "‘"),
            ("'", "‘", .koreanSystem, true, "‘"),
            ("'", "‘‘", .koreanSystem, true, "‘"),
            ("'", "‘한글", .koreanSystem, true, "’"),
            ("'", "‘ ", .koreanSystem, true, "’"),
            ("'", "‘!", .koreanSystem, true, "’"),
            ("'", "‘한글’", .koreanSystem, true, "‘"),
            // 영어 single quote는 커서 앞 문맥으로 여닫는 따옴표를 결정
            ("'", "don", .englishSystem, true, "’"),
            ("'", "‘", .englishSystem, true, "’"),
            ("'", "’", .englishSystem, true, "‘"),
            ("'", " ", .englishSystem, true, "‘"),
            // 영어 double quote는 커서 앞 문맥으로 여닫는 따옴표를 결정
            ("\"", "1", .englishSystem, true, "”"),
            ("\"", "“", .englishSystem, true, "”"),
            ("\"", "”", .englishSystem, true, "“"),
            ("\"", ".", .englishSystem, true, "“"),
            // symbol 키보드의 curly quote 입력도 smart quote 대상으로 정규화
            ("’", "", .koreanSystem, true, "‘"),
            ("’", "‘한글", .koreanSystem, true, "’"),
            ("“", "", .koreanSystem, true, "“"),
            ("“", "", .koreanSystem, false, "”")
          ])
    func testQuoteOpeningClosingByContext(
        text: String,
        before: String?,
        rule: KeyboardSmartQuoteRule,
        nextOpening: Bool,
        insertText: String
    ) {
        #expect(transform(text, before: before, rule: rule, nextOpening: nextOpening).insertText == insertText)
    }

    @Test("여는 큰따옴표를 소비하면 다음 큰따옴표는 닫는 따옴표")
    func testConsumingOpeningDoubleQuoteMakesNextOneClosing() {
        var state = KeyboardSmartQuoteState()

        let first = transform("\"", before: nil, nextOpening: state.nextDoubleQuoteIsOpening)
        state.consume(first)

        #expect(state.nextDoubleQuoteIsOpening == false)

        let second = transform("\"", before: nil, nextOpening: state.nextDoubleQuoteIsOpening)

        #expect(first.insertText == "“")
        #expect(second.insertText == "”")
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
