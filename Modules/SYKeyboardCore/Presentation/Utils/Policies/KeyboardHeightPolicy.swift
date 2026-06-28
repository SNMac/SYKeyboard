//
//  KeyboardHeightPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

import CoreGraphics
import UIKit

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

    static func isPortrait(
        orientation: UIInterfaceOrientation,
        usesOrientation: Bool = true,
        fallbackBounds: CGRect,
        horizontalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        verticalSizeClass: UIUserInterfaceSizeClass = .unspecified
    ) -> Bool {
        if !usesOrientation {
            return isPortrait(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            ) ?? (fallbackBounds.height >= fallbackBounds.width)
        }

        switch orientation {
        case .portrait, .portraitUpsideDown:
            return true
        case .landscapeLeft, .landscapeRight:
            return false
        case .unknown:
            if let traitIsPortrait = isPortrait(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            ) {
                return traitIsPortrait
            }

            return fallbackBounds.height >= fallbackBounds.width
        @unknown default:
            return fallbackBounds.height >= fallbackBounds.width
        }
    }

    private static func isPortrait(
        horizontalSizeClass: UIUserInterfaceSizeClass,
        verticalSizeClass: UIUserInterfaceSizeClass
    ) -> Bool? {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .regular):
            return true
        case (.compact, .compact), (.regular, .compact):
            return false
        default:
            return nil
        }
    }
}
