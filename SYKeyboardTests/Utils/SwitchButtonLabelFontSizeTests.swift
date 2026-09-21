//
//  SwitchButtonLabelFontSizeTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("전환 버튼 라벨 크기")
struct SwitchButtonLabelFontSizeTests {
    private static let fullSize: CGFloat = 8.0

    @Test("세로 모드 키 크기에서는 기본 크기를 유지한다")
    func testPortraitKeepsFullSize() {
        // 임계값(40) 이상이면 어떤 크기든 상한을 유지하는지 보는 순수 함수 검증값이다.
        // 실제 세로 배경 높이는 4x4 56pt, 쿼티 52pt다 (testPortraitBackgroundHeightsKeepFullSize 참고)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 44) - Self.fullSize) < 0.01)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 33.0, keyHeight: 40) - Self.fullSize) < 0.01)
    }

    @Test("실제 세로 모드 배경 크기에서도 기본 크기를 유지한다")
    func testPortraitBackgroundHeightsKeepFullSize() {
        // 기본 keyboardHeight(240)에서 세로 모드 행 높이는 60pt.
        // 세로 4x4 배경: 60 - insetDy 2 * 2 = 56, 세로 쿼티 배경: 60 - insetDy 4 * 2 = 52
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 42.75, keyHeight: 56) - Self.fullSize) < 0.01)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 33, keyHeight: 52) - Self.fullSize) < 0.01)
    }

    @Test("가로 모드 낮은 키에서는 높이에 비례해 줄인다")
    func testLandscapeShrinksWithHeight() {
        // 순수 함수 임계값 검증값이다. 실제 가로 모드 배경 높이는 행 높이 36pt 기준으로
        // 4x4 36 - 2 * 2 = 32, 쿼티 36 - 4 * 2 = 28에 더 가깝다
        let fourByFour = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 31)
        let qwerty = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 27)

        #expect(abs(fourByFour - Self.fullSize * 31 / 40) < 0.01)
        #expect(abs(qwerty - Self.fullSize * 27 / 40) < 0.01)
        #expect(qwerty < fourByFour)
        #expect(fourByFour < Self.fullSize)
    }

    @Test("좁은 키에서는 너비 기준 축소가 그대로 유지된다")
    func testNarrowKeyStillShrinksByWidth() {
        // 한 손 키보드처럼 좁은 키는 높이가 넉넉해도 너비 때문에 줄어야 한다
        let narrow = SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 44)

        #expect(abs(narrow - Self.fullSize * 20 / 25) < 0.01)
        #expect(narrow < Self.fullSize)
    }

    @Test("너비와 높이 중 좁은 쪽이 결과를 결정한다")
    func testUsesSmallerOfWidthAndHeightRule() {
        // 너비 20 -> 6.4, 높이 27 -> 5.4. 더 작은 5.4가 나와야 한다
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 27) - Self.fullSize * 27 / 40) < 0.01)
    }

    @Test("크기가 0이면 기본 크기로 되돌린다")
    func testNonPositiveSizeFallsBackToFullSize() {
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 0, keyHeight: 44) == Self.fullSize)
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 0) == Self.fullSize)
    }

    @Test("세로 모드 높이에서는 너비 사다리를 그대로 유지한다")
    func testPrimaryLabelKeepsWidthLadderInPortrait() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 49.6, keyHeight: 56) == 16)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 40, keyHeight: 56) == 14)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 36, keyHeight: 56) == 12)
    }

    @Test("슬라이더 최소값의 세로 모드 높이(39.5)는 줄지 않는다")
    func testPrimaryLabelNotReducedAtSliderMinimumPortraitHeight() {
        // 39.5는 keyboardHeight 슬라이더 최하단(190), 쿼티 계열, insetDy 4에서 나오는
        // 가장 작은 세로 모드 배경 높이다
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 39.5) == 16)
    }

    @Test("가로 모드 높이에서는 한 단계 낮춘 크기를 쓴다")
    func testPrimaryLabelDropsOneRungInLandscape() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 49.6, keyHeight: 32) == 14)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 40, keyHeight: 32) == 12)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 36, keyHeight: 32) == 10)
    }

    @Test("임계값 36은 포함되지 않고, 그 아래인 35.9는 낮춘다")
    func testPrimaryLabelThresholdIsExclusive() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 36) == 16)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 35.9) == 14)
    }

    @Test("높이가 0 이하면 사다리 크기로 되돌린다")
    func testPrimaryLabelFallsBackToLadderForNonPositiveHeight() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 0) == 16)
    }
}
