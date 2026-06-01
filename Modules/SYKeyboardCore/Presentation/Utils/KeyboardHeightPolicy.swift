//
//  KeyboardHeightPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

import CoreGraphics

enum KeyboardHeightPolicy {

    struct Height {
        let keyboardViewHeight: CGFloat
        let keyboardHStackViewHeight: CGFloat
    }

    static func height(
        keyboardSettingsHeight: CGFloat,
        landscapeKeyboardHeight: CGFloat,
        suggestionBarHeight: CGFloat,
        isSuggestionBarVisible: Bool,
        isPortrait: Bool
    ) -> Height {
        let visibleSuggestionBarHeight = isSuggestionBarVisible ? suggestionBarHeight : 0

        if isPortrait {
            return Height(
                keyboardViewHeight: keyboardSettingsHeight + visibleSuggestionBarHeight,
                keyboardHStackViewHeight: keyboardSettingsHeight
            )
        } else {
            return Height(
                keyboardViewHeight: landscapeKeyboardHeight,
                keyboardHStackViewHeight: landscapeKeyboardHeight - visibleSuggestionBarHeight
            )
        }
    }
}
