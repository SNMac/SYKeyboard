//
//  KeyboardHeightPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

import CoreGraphics
import UIKit

public enum KeyboardHeightPolicy {

    struct Height {
        let keyboardViewHeight: CGFloat
        let keyboardHStackViewHeight: CGFloat
    }

    /// 세로 모드 숫자 행 높이. 키보드 높이 설정 최소값일 때의 글자 행 높이와 같다
    public static let portraitNumberRowHeight: CGFloat = letterRowHeight(
        keyboardAreaHeight: CGFloat(KeyboardLayoutFigure.keyboardHeightRange.lowerBound)
    )
    /// 가로 모드 숫자 행 높이. 자동완성 바가 보일 때의 가로 글자 행 높이와 같다.
    /// 바가 숨겨져 글자 행이 커져도 숫자 행은 이 값을 유지한다
    public static let landscapeNumberRowHeight: CGFloat = letterRowHeight(
        keyboardAreaHeight: KeyboardLayoutFigure.landscapeKeyboardHeight
        - KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing
    )

    /// 키 영역 높이에서 프레임 여백을 빼고 4행으로 나눈 글자 행 높이
    static func letterRowHeight(keyboardAreaHeight: CGFloat) -> CGFloat {
        (keyboardAreaHeight - KeyboardLayoutFigure.keyboardFrameSpacing) / 4
    }

    /// 화면 방향에 맞는 숫자 행 높이. 숫자 행이 없으면 0을 반환한다
    /// - Parameters:
    ///   - isEnabled: 숫자 행 설정 여부
    ///   - isPortrait: 세로 화면 여부
    public static func numberRowHeight(isEnabled: Bool, isPortrait: Bool) -> CGFloat {
        guard isEnabled else { return 0 }
        return isPortrait ? portraitNumberRowHeight : landscapeNumberRowHeight
    }

    static func height(
        keyboardSettingsHeight: CGFloat,
        landscapeKeyboardHeight: CGFloat,
        suggestionBarHeight: CGFloat,
        isSuggestionBarVisible: Bool,
        isPortrait: Bool,
        numberRowHeight: CGFloat = 0
    ) -> Height {
        let visibleSuggestionBarHeight = isSuggestionBarVisible ? suggestionBarHeight : 0

        if isPortrait {
            return Height(
                keyboardViewHeight: keyboardSettingsHeight + visibleSuggestionBarHeight + numberRowHeight,
                keyboardHStackViewHeight: keyboardSettingsHeight + numberRowHeight
            )
        } else {
            return Height(
                keyboardViewHeight: landscapeKeyboardHeight + numberRowHeight,
                keyboardHStackViewHeight: landscapeKeyboardHeight - visibleSuggestionBarHeight + numberRowHeight
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
