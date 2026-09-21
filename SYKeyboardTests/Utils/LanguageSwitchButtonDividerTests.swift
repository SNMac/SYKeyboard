//
//  LanguageSwitchButtonDividerTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("한영 전환 버튼 글자·구분선 굵기")
struct LanguageSwitchButtonLabelMetricsTests {

    @Test("한/영 글자 크기는 기본값을 넘지 않고 좁은 버튼에서 줄어듦")
    func testLanguageSwitchLabelFontShrinksOnNarrowKey() {
        let maximum: CGFloat = 14.0

        // 일반 폭(390pt / 10열 = 39pt)에서는 기본 크기를 유지
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 39, maximum: maximum) == maximum)
        // 한 손 키보드 최소 폭(300pt / 10열 = 30pt)에서는 줄어듦
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum) < maximum)
        // 좁을수록 더 작아짐
        #expect(
            LanguageSwitchButton.labelFontSize(forKeyWidth: 24, maximum: maximum)
            < LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum)
        )
        // 레이아웃 전 폭이 0이어도 기본 크기로 떨어짐
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 0, maximum: maximum) == maximum)
    }

    @Test("구분선 두께는 글자 크기에 비례")
    func testDividerLineWidthScalesWithFontSize() {
        let maximum: CGFloat = 14.0
        let wideFont = LanguageSwitchButton.labelFontSize(forKeyWidth: 39, maximum: maximum)
        let narrowFont = LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum)

        // 기본 글자 크기에서 기존 두께 1.5를 유지
        #expect(abs(LanguageSwitchButton.dividerLineWidth(forFontSize: maximum) - 1.5) < 0.01)
        // 글자가 줄면 구분선도 함께 얇아짐
        #expect(
            LanguageSwitchButton.dividerLineWidth(forFontSize: narrowFont)
            < LanguageSwitchButton.dividerLineWidth(forFontSize: wideFont)
        )
        // 글자 크기와의 비율은 폭과 무관하게 일정
        #expect(
            abs(LanguageSwitchButton.dividerLineWidth(forFontSize: narrowFont) / narrowFont
                - LanguageSwitchButton.dividerLineWidth(forFontSize: wideFont) / wideFont) < 0.001
        )
    }
}

@MainActor
@Suite("한영 전환 버튼 구분선 기울기")
struct LanguageSwitchButtonDividerTests {
    /// `dividerHalfExtents`가 만드는 사선의 각도(도)
    private static func angleInDegrees(forKeySize size: CGSize) -> CGFloat {
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)
        return atan2(extents.height, extents.width) * 180 / .pi
    }

    @Test("세로 모드 배경 크기에서는 비율 그대로 나온다")
    func testPortraitExtentsMatchRatiosExactly() {
        // 기본 keyboardHeight(240)에서 세로 모드 행 높이는 60pt.
        // 세로 modifier 배경은 globe 숨김 42.75×56, globe 표시 26.5×56이며
        // 원래 각도(50.0°, 62.5°)가 이미 45° 이상이라 비율 그대로 나와야 한다(회귀 가드)
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56)] {
            let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

            #expect(abs(extents.width - size.width * 0.22) < 0.001)
            #expect(abs(extents.height - size.height * 0.20) < 0.001)
        }
    }

    @Test("각도는 45도 아래로 내려가지 않는다")
    func testAngleNeverGoesBelow45Degrees() {
        // 세로 modifier 배경(42.75×56, 26.5×56), 가로 modifier 배경(행 높이 36pt에서
        // 42.75×32, 26.5×32), 그리고 극단적으로 좁거나 넓은 키(20×60, 200×27)까지
        // 포함해 45° 바닥이 지켜지는지 확인한다
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56),
                     CGSize(width: 42.75, height: 32), CGSize(width: 26.5, height: 32),
                     CGSize(width: 20, height: 60), CGSize(width: 200, height: 27),
                     CGSize(width: 49.6, height: 32)] {
            #expect(Self.angleInDegrees(forKeySize: size) >= 45 - 0.01)
        }
    }

    @Test("가로 모드처럼 낮고 넓은 키는 45도로 잘리되, 너비·높이 예산 중 더 작은 쪽에 맞춘다")
    func testWideShortKeyIsClampedTo45Degrees() {
        // 가로 모드 globe 숨김 배경(42.75×32)은 원래 각도가 34.2°라 45°보다 누우므로 잘린다.
        // 세로 예산에 1.5배(다음 테스트의 dividerClampedHeightBoost)를 줘도 너비 예산(42.75 * 0.22)이
        // 더 작아 너비가 상한이 된다
        let widthBound = CGSize(width: 42.75, height: 32)
        let widthBoundExtents = LanguageSwitchButton.dividerHalfExtents(forKeySize: widthBound)

        #expect(abs(widthBoundExtents.width - 42.75 * 0.22) < 0.01)
        #expect(abs(widthBoundExtents.height - 42.75 * 0.22) < 0.01)

        // 실제 랜드스케이프 한/영 배경(49.6×32)은 반대로 세로 예산(32 * 0.20 * 1.5)이 더 작아
        // 세로 예산이 상한이 된다
        // 회귀 가드: dividerClampedHeightBoost 도입 전에는 반길이가 32 * 0.20(=6.4)까지만 잘려
        // 획이 세로 모드(25.0pt)보다 훨씬 짧은 18.1pt로 뭉툭해 보였다
        let heightBound = CGSize(width: 49.6, height: 32)
        let heightBoundExtents = LanguageSwitchButton.dividerHalfExtents(forKeySize: heightBound)

        #expect(abs(heightBoundExtents.width - 32 * 0.20 * 1.5) < 0.01)
        #expect(abs(heightBoundExtents.height - 32 * 0.20 * 1.5) < 0.01)
    }

    @Test("이미 45도 이상인 키는 그대로 유지된다")
    func testKeyAboveThresholdIsUntouched() {
        // 가로 모드 globe 표시 배경(26.5×32)은 원래 각도가 47.7°로 이미 45° 이상이라 바뀌지 않는다
        let size = CGSize(width: 26.5, height: 32)
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

        #expect(abs(extents.width - 26.5 * 0.22) < 0.001)
        #expect(abs(extents.height - 32 * 0.20) < 0.001)
    }

    @Test("반길이는 너비·높이 비율 박스를 넘지 않고, 획은 키 안에 머문다")
    func testHalfExtentsStayInsideRatioBox() {
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56),
                     CGSize(width: 42.75, height: 32), CGSize(width: 26.5, height: 32),
                     CGSize(width: 20, height: 60), CGSize(width: 200, height: 27)] {
            let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

            #expect(extents.width <= size.width * 0.22 + 0.001)
            // 클램프 분기는 세로 예산에 dividerClampedHeightBoost(1.5)를 곱한 값까지 쓴다
            #expect(extents.height <= size.height * 0.20 * 1.5 + 0.001)
            #expect(extents.width > 0)
            #expect(extents.height > 0)
            // 확대된 획이라도 키 경계를 넘어서는 안 된다
            #expect(extents.height * 2 < size.height)
            #expect(extents.width * 2 < size.width)
        }
    }

    @Test("크기가 0이면 반길이도 0이다")
    func testZeroSizeYieldsZeroExtents() {
        #expect(LanguageSwitchButton.dividerHalfExtents(forKeySize: .zero) == .zero)
    }

    @Test("낮은 키에서도 두 글자가 버튼 안에 남는다")
    func testLabelsStayInsideShortKey() throws {
        let button = LanguageSwitchButton(mode: .hangeul)
        // 가로 모드 쿼티 키에 가까운 크기
        button.frame = CGRect(x: 0, y: 0, width: 39, height: 35)
        button.layoutIfNeeded()

        let labels = button.subviews.compactMap { $0 as? UILabel }.filter { $0.text == "한" || $0.text == "A" }
        #expect(labels.count == 2)

        for label in labels {
            #expect(label.frame.minX >= -0.5)
            #expect(label.frame.minY >= -0.5)
            #expect(label.frame.maxX <= button.bounds.width + 0.5)
            #expect(label.frame.maxY <= button.bounds.height + 0.5)
        }
    }
}
