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

    @Test("설정이 꺼져 있으면 smart quotes와 dashes를 적용하지 않음")
    func testTypedTextTransformRequiresAppSetting() {
        let quote = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: false,
            smartQuotesType: .yes,
            smartDashesType: .yes
        )
        let dash = KeyboardSmartInputPolicy.transformTypedText(
            "-",
            documentContextBeforeInput: "-",
            isSmartPunctuationEnabled: false,
            smartQuotesType: .yes,
            smartDashesType: .yes
        )

        #expect(quote == .init(deleteCount: 0, insertText: "\""))
        #expect(dash == .init(deleteCount: 0, insertText: "-"))
    }

    @Test("smart quotes는 trait yes에서만 적용")
    func testSmartQuotesRequireYesTrait() {
        let defaultResult = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .default,
            smartDashesType: .no
        )
        let noResult = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no
        )
        let yesResult = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )

        #expect(defaultResult.insertText == "\"")
        #expect(noResult.insertText == "\"")
        #expect(yesResult.insertText == "“")
    }

    @Test("double quote는 커서 앞 quote 개수가 짝수면 여는 따옴표, 홀수면 닫는 따옴표")
    func testDoubleQuoteUsesQuoteCount() {
        let opening = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "hello “world” ",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )
        let closing = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "hello “world",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )

        #expect(opening.insertText == "“")
        #expect(closing.insertText == "”")
    }

    @Test("single quote는 단어 내부 apostrophe를 우선하고 그 외에는 quote 개수를 사용")
    func testSingleQuoteUsesApostropheAndQuoteCount() {
        let apostrophe = KeyboardSmartInputPolicy.transformTypedText(
            "'",
            documentContextBeforeInput: "don",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )
        let opening = KeyboardSmartInputPolicy.transformTypedText(
            "'",
            documentContextBeforeInput: "say ‘hi’ ",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )
        let closing = KeyboardSmartInputPolicy.transformTypedText(
            "'",
            documentContextBeforeInput: "say ‘hi",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no
        )

        #expect(apostrophe.insertText == "’")
        #expect(opening.insertText == "‘")
        #expect(closing.insertText == "’")
    }

    @Test("smart dashes는 trait yes에서만 em dash와 ellipsis를 적용")
    func testSmartDashesRequireYesTrait() {
        let defaultDash = KeyboardSmartInputPolicy.transformTypedText(
            "-",
            documentContextBeforeInput: "-",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .default
        )
        let emDash = KeyboardSmartInputPolicy.transformTypedText(
            "-",
            documentContextBeforeInput: "-",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .yes
        )
        let ellipsis = KeyboardSmartInputPolicy.transformTypedText(
            ".",
            documentContextBeforeInput: "..",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .yes
        )

        #expect(defaultDash == .init(deleteCount: 0, insertText: "-"))
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
}
