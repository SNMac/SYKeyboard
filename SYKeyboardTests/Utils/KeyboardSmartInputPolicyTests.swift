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
        let doubleQuote = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: false,
            smartQuotesType: .yes,
            smartDashesType: .yes
        )
        let singleQuote = KeyboardSmartInputPolicy.transformTypedText(
            "‘",
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

        #expect(doubleQuote == .init(deleteCount: 0, insertText: "\""))
        #expect(singleQuote == .init(deleteCount: 0, insertText: "'"))
        #expect(dash == .init(deleteCount: 0, insertText: "-"))
    }

    @Test("smart quotes는 키보드별 default 해석이 enabled이면 default에서 적용")
    func testSmartQuotesDefaultEnabledByKeyboardPolicy() {
        let defaultResult = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .default,
            smartDashesType: .no,
            isDefaultSmartQuotesEnabled: true
        )

        #expect(defaultResult.insertText == "“")
    }

    @Test("smart quotes는 키보드별 default 해석이 disabled이면 default에서 straight quote로 삽입")
    func testSmartQuotesDefaultDisabledByKeyboardPolicy() {
        let defaultResult = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .default,
            smartDashesType: .no,
            isDefaultSmartQuotesEnabled: false
        )

        #expect(defaultResult.insertText == "\"")
    }

    @Test("smart quotes는 trait yes에서 항상 적용하고 no에서만 적용하지 않음")
    func testSmartQuotesExplicitTraitsOverrideKeyboardDefaultPolicy() {
        let noResult = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no,
            isDefaultSmartQuotesEnabled: true
        )
        let yesResult = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            isDefaultSmartQuotesEnabled: false
        )

        #expect(noResult.insertText == "\"")
        #expect(yesResult.insertText == "“")
    }

    @Test("smart quotes trait이 no이면 표시용 quote도 straight quote로 삽입")
    func testSmartQuotesNoTraitNormalizesDisplayQuotesToStraightQuotes() {
        let doubleQuote = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no
        )
        let closingSingleQuote = KeyboardSmartInputPolicy.transformTypedText(
            "’",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no
        )
        let openingSingleQuote = KeyboardSmartInputPolicy.transformTypedText(
            "‘",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no
        )

        #expect(doubleQuote == .init(deleteCount: 0, insertText: "\""))
        #expect(closingSingleQuote == .init(deleteCount: 0, insertText: "'"))
        #expect(openingSingleQuote == .init(deleteCount: 0, insertText: "'"))
    }

    @Test("double quote는 다음 입력 상태에 따라 여는 따옴표나 닫는 따옴표를 삽입")
    func testDoubleQuoteUsesNextOpeningState() {
        let first = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: nil,
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: true
        )
        let second = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: nil,
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: false
        )

        #expect(first.insertText == "“")
        #expect(first.consumedQuoteKind == .double)
        #expect(second.insertText == "”")
        #expect(second.consumedQuoteKind == .double)
    }

    @Test("single quote는 apostrophe 예외 없이 다음 입력 상태에 따라 여는 따옴표나 닫는 따옴표를 삽입")
    func testSingleQuoteUsesNextOpeningState() {
        let firstAfterWord = KeyboardSmartInputPolicy.transformTypedText(
            "'",
            documentContextBeforeInput: "don",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextSingleQuoteIsOpening: true
        )
        let second = KeyboardSmartInputPolicy.transformTypedText(
            "'",
            documentContextBeforeInput: nil,
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextSingleQuoteIsOpening: false
        )

        #expect(firstAfterWord.insertText == "‘")
        #expect(firstAfterWord.consumedQuoteKind == .single)
        #expect(second.insertText == "’")
        #expect(second.consumedQuoteKind == .single)
    }

    @Test("symbol 키보드의 curly quote 입력도 smart quote 대상으로 정규화")
    func testCurlyQuoteInputIsNormalizedBeforeTransform() {
        let openingSingle = KeyboardSmartInputPolicy.transformTypedText(
            "’",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextSingleQuoteIsOpening: true
        )
        let closingSingle = KeyboardSmartInputPolicy.transformTypedText(
            "’",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextSingleQuoteIsOpening: false
        )
        let openingDouble = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: true
        )
        let closingDouble = KeyboardSmartInputPolicy.transformTypedText(
            "“",
            documentContextBeforeInput: "",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: false
        )

        #expect(openingSingle.insertText == "‘")
        #expect(closingSingle.insertText == "’")
        #expect(openingDouble.insertText == "“")
        #expect(closingDouble.insertText == "”")
    }

    @Test("quote 상태는 삭제 시 되돌리지 않고 다음 입력에 닫는 따옴표를 사용")
    func testQuoteStateIsNotRevertedByDelete() {
        var state = KeyboardSmartQuoteState()

        let first = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: nil,
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: state.nextDoubleQuoteIsOpening,
            nextSingleQuoteIsOpening: state.nextSingleQuoteIsOpening
        )
        state.consume(first)

        let secondAfterDelete = KeyboardSmartInputPolicy.transformTypedText(
            "\"",
            documentContextBeforeInput: nil,
            isSmartPunctuationEnabled: true,
            smartQuotesType: .yes,
            smartDashesType: .no,
            nextDoubleQuoteIsOpening: state.nextDoubleQuoteIsOpening,
            nextSingleQuoteIsOpening: state.nextSingleQuoteIsOpening
        )

        #expect(first.insertText == "“")
        #expect(secondAfterDelete.insertText == "”")
    }

    @Test("smart dashes는 trait default 또는 yes에서 em dash와 ellipsis를 적용하고 no에서만 적용하지 않음")
    func testSmartDashesTreatDefaultAsYes() {
        let defaultDash = KeyboardSmartInputPolicy.transformTypedText(
            "-",
            documentContextBeforeInput: "-",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .default
        )
        let defaultEllipsis = KeyboardSmartInputPolicy.transformTypedText(
            ".",
            documentContextBeforeInput: "..",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .default
        )
        let noDash = KeyboardSmartInputPolicy.transformTypedText(
            "-",
            documentContextBeforeInput: "-",
            isSmartPunctuationEnabled: true,
            smartQuotesType: .no,
            smartDashesType: .no
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
}
