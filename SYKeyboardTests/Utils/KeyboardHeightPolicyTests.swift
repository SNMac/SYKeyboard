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
}
