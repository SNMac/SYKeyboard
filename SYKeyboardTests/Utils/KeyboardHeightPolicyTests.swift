//
//  KeyboardHeightPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/1/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("키보드 높이 정책 검증")
struct KeyboardHeightPolicyTests {

    @Test("orientation이 unknown이면 bounds 비율로 세로 화면을 판단")
    func testUnknownOrientation_bounds세로비율_fallback() {
        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: .unknown,
            fallbackBounds: CGRect(x: 0, y: 0, width: 430, height: 932)
        )

        #expect(isPortrait)
    }

    @Test("orientation이 unknown이면 iPhone portrait trait 조합을 세로 화면으로 판단")
    func testUnknownOrientation_iPhonePortraitTrait세로판단() {
        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: .unknown,
            fallbackBounds: CGRect(x: 0, y: 0, width: 932, height: 430),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )

        #expect(isPortrait)
    }

    @Test("orientation이 unknown이면 일반 iPhone landscape trait 조합을 가로 화면으로 판단")
    func testUnknownOrientation_iPhoneCompactLandscapeTrait가로판단() {
        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: .unknown,
            fallbackBounds: CGRect(x: 0, y: 0, width: 430, height: 932),
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        )

        #expect(isPortrait == false)
    }

    @Test("orientation이 unknown이면 Max 계열 iPhone landscape trait 조합을 가로 화면으로 판단")
    func testUnknownOrientation_iPhoneRegularLandscapeTrait가로판단() {
        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: .unknown,
            fallbackBounds: CGRect(x: 0, y: 0, width: 430, height: 932),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )

        #expect(isPortrait == false)
    }

    @Test("orientation을 사용하지 않는 환경에서는 trait 조합을 우선 사용")
    func testOrientation미사용환경_trait조합우선() {
        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: .portrait,
            usesOrientation: false,
            fallbackBounds: CGRect(x: 0, y: 0, width: 430, height: 932),
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        )

        #expect(isPortrait == false)
    }

    @Test("세로 화면에서는 키보드 높이에 suggestion bar 높이를 더하고 hstack 높이는 설정값을 유지")
    func test세로화면_높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 260,
            landscapeKeyboardHeight: 220,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: true
        )

        #expect(height.keyboardViewHeight == 304)
        #expect(height.keyboardHStackViewHeight == 260)
    }

    @Test("세로 화면에서 suggestion bar가 숨겨지면 keyboard view와 hstack 높이가 설정값과 같음")
    func test세로화면_suggestionBar숨김_높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 260,
            landscapeKeyboardHeight: 220,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: false,
            isPortrait: true
        )

        #expect(height.keyboardViewHeight == 260)
        #expect(height.keyboardHStackViewHeight == 260)
    }

    @Test("가로 화면에서는 keyboard view 높이를 고정하고 hstack에서 suggestion bar 높이를 뺌")
    func test가로화면_높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 260,
            landscapeKeyboardHeight: 220,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: false
        )

        #expect(height.keyboardViewHeight == 220)
        #expect(height.keyboardHStackViewHeight == 176)
    }

    @Test("가로 화면에서 suggestion bar가 숨겨지면 keyboard view와 hstack 높이가 고정값과 같음")
    func test가로화면_suggestionBar숨김_높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 260,
            landscapeKeyboardHeight: 220,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: false,
            isPortrait: false
        )

        #expect(height.keyboardViewHeight == 220)
        #expect(height.keyboardHStackViewHeight == 220)
    }

    // MARK: - 숫자 행

    @Test("키보드 높이 설정 범위는 190...290")
    func test키보드높이범위() {
        #expect(KeyboardLayoutFigure.keyboardHeightRange == 190...290)
    }

    @Test("숫자 행 높이는 세로 46.5, 가로 35로 고정")
    func test숫자행높이_고정값() {
        #expect(KeyboardHeightPolicy.portraitNumberRowHeight == 46.5)
        #expect(KeyboardHeightPolicy.landscapeNumberRowHeight == 35)
    }

    @Test("숫자 행 설정이 꺼져 있으면 숫자 행 높이는 0")
    func test숫자행_설정꺼짐() {
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: false, isPortrait: true) == 0)
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: false, isPortrait: false) == 0)
    }

    @Test("숫자 행 설정이 켜져 있으면 자판 종류와 상관없이 방향별 숫자 행 높이를 반환")
    func test숫자행_방향별높이() {
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, isPortrait: true) == 46.5)
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, isPortrait: false) == 35)
    }

    @Test("세로 화면 숫자 행은 설정 높이와 자동완성 바 위에 더함")
    func test세로화면_숫자행높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: true,
            numberRowHeight: 46.5
        )

        #expect(height.keyboardViewHeight == 330.5)
        #expect(height.keyboardHStackViewHeight == 286.5)
    }

    @Test("가로 화면 숫자 행은 고정 높이 188 위에 더하고 자동완성 바는 기존처럼 뺌")
    func test가로화면_숫자행높이계산() {
        let visible = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: false,
            numberRowHeight: 35
        )
        #expect(visible.keyboardViewHeight == 223)
        #expect(visible.keyboardHStackViewHeight == 179)

        let hidden = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: false,
            isPortrait: false,
            numberRowHeight: 35
        )
        #expect(hidden.keyboardViewHeight == 223)
        #expect(hidden.keyboardHStackViewHeight == 223)
    }
}
