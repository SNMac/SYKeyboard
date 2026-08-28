//
//  KeyboardColumnWidthPolicyTests.swift
//  SYKeyboardTests
//

import Testing
import CoreFoundation

@testable import SYKeyboardCore

@Suite("4열 격자 열 너비 정책")
struct KeyboardColumnWidthPolicyTests {
    private static let tolerance: CGFloat = 0.0001

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let letter = KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.0)
        let function = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.0)

        #expect(abs(letter - 0.25) < Self.tolerance)
        #expect(abs(function - 0.25) < Self.tolerance)
    }

    @Test("기본 배율에서 기능 열 안의 한영 전환 버튼 몫은 기존 상수와 같은 폭을 만든다")
    func testLanguageSwitchShareMatchesExistingConstantAtDefaultMultiplier() {
        let functionColumn = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.0)
        let width = functionColumn * KeyboardLayoutFigure.languageSwitchButtonFunctionColumnShare

        #expect(abs(width - KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < Self.tolerance)
    }

    @Test("글자 열 3개와 기능 열의 합은 항상 1이다")
    func testColumnRatiosAlwaysSumToOne() {
        for step in 0...20 {
            let multiplier = 1.0 + Double(step) * 0.01
            let total = 3 * KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: multiplier)
            + KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

            #expect(abs(total - 1.0) < Self.tolerance)
        }
    }

    @Test("배율을 올리면 글자 열이 넓어지고 기능 열이 좁아진다")
    func testHigherMultiplierWidensLetterColumns() {
        #expect(abs(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.2) - 0.3) < Self.tolerance)
        #expect(abs(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.2) - 0.1) < Self.tolerance)
        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.2)
                > KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.0))
        #expect(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.2)
                < KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.0))
    }

    @Test("범위 밖 배율은 허용 범위로 잘린다")
    func testMultiplierIsClampedToRange() {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange

        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 0.5)
                == KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: range.lowerBound))
        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 5.0)
                == KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: range.upperBound))
        #expect(range.lowerBound == 1.0)
        #expect(range.upperBound == 1.2)
    }
}
