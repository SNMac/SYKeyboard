//
//  KeyboardHeightPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/1/26.
//

import CoreFoundation
import Testing

@testable import SYKeyboardCore

@Suite("키보드 높이 정책 검증")
struct KeyboardHeightPolicyTests {

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
