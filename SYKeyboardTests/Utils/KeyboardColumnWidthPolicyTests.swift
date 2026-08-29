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

    @Test("글자 열 3개와 기능 열의 합은 항상 1이다")
    func testColumnRatiosAlwaysSumToOne() {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        // 상한 밖은 clamp돼 같은 값을 반복 검증할 뿐이므로 허용 범위 안만 돈다
        let lastStep = Int(((range.upperBound - range.lowerBound) * 100).rounded())

        for step in 0...lastStep {
            let multiplier = range.lowerBound + Double(step) * 0.01
            let total = 3 * KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: multiplier)
            + KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

            #expect(abs(total - 1.0) < Self.tolerance)
        }
    }

    @Test("배율을 올리면 글자 열이 넓어지고 기능 열이 좁아진다")
    func testHigherMultiplierWidensLetterColumns() {
        #expect(abs(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.15) - 0.2875) < Self.tolerance)
        #expect(abs(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.15) - 0.1375) < Self.tolerance)
        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.15)
                > KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.0))
        #expect(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.15)
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
        #expect(range.upperBound == 1.15)
    }

    @Test("슬라이더 정수 범위는 배율 범위와 일치하고 스텝 수가 정수로 떨어진다")
    func testPercentRangeMatchesMultiplierRangeWithWholeSteps() {
        let percent = KeyboardLayoutFigure.letterColumnWidthPercentRange
        let multiplier = KeyboardLayoutFigure.letterColumnWidthMultiplierRange

        #expect(percent.lowerBound == 100)
        #expect(percent.upperBound == 115)
        // 실수 step은 부동소수점 오차로 상한에 닿지 못한다. 정수 step은 정확히 떨어져야 한다
        #expect((percent.upperBound - percent.lowerBound).truncatingRemainder(dividingBy: 1) == 0)
        // 정수 범위를 100으로 나누면 배율 범위와 같아야 한다
        #expect(abs(percent.lowerBound / 100 - multiplier.lowerBound) < 0.0001)
        #expect(abs(percent.upperBound / 100 - multiplier.upperBound) < 0.0001)
    }
}
