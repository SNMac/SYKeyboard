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

    @Test("슬라이더 정수 범위는 배율 범위와 일치한다")
    func testPercentRangeMatchesMultiplierRange() {
        let percent = KeyboardLayoutFigure.letterColumnWidthPercentRange
        let multiplier = KeyboardLayoutFigure.letterColumnWidthMultiplierRange

        #expect(percent.lowerBound == 100)
        #expect(percent.upperBound == 115)
        #expect(abs(percent.lowerBound / 100 - multiplier.lowerBound) < 0.0001)
        #expect(abs(percent.upperBound / 100 - multiplier.upperBound) < 0.0001)
    }

    @Test("슬라이더 파생 바인딩은 전 구간에서 값을 잃지 않고 왕복한다")
    func testSliderBindingRoundTripsAcrossWholeRange() {
        let percentRange = KeyboardLayoutFigure.letterColumnWidthPercentRange

        for step in 0...Int(percentRange.upperBound - percentRange.lowerBound) {
            let percent = percentRange.lowerBound + Double(step)

            // set: 슬라이더가 준 정수 퍼센트 -> 저장할 배율
            let multiplier = KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: percent)
            // get: 저장된 배율 -> 슬라이더가 표시할 정수 퍼센트
            let roundTripped = KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: multiplier)

            #expect(abs(roundTripped - percent) < 0.0001)
            // 실수 step에서 상한에 닿지 못하던 버그의 회귀 방지: 정수로 정확히 떨어져야 한다
            #expect(roundTripped == roundTripped.rounded())
            #expect(percentRange.contains(roundTripped))
        }
    }

    @Test("상한 배율은 슬라이더 상한 퍼센트로 정확히 표시된다")
    func testUpperBoundMultiplierMapsToUpperBoundPercent() {
        let multiplierRange = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        let percentRange = KeyboardLayoutFigure.letterColumnWidthPercentRange

        // 실수 step 시절 상한에 닿지 못해 115 대신 114에서 멈추던 지점이다
        #expect(KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: multiplierRange.upperBound)
                == percentRange.upperBound)
        #expect(KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: percentRange.upperBound)
                == multiplierRange.upperBound)
    }
}
