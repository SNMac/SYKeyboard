//
//  LanguageSwitchButtonLabelMetricsTests.swift
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
