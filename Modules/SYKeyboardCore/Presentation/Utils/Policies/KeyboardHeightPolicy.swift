//
//  KeyboardHeightPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

import CoreGraphics
import UIKit

public enum KeyboardHeightPolicy {

    public struct Height {
        public let keyboardViewHeight: CGFloat
        public let keyboardHStackViewHeight: CGFloat
    }

    /// 세로 모드 숫자 행 최소 높이. 키보드 높이 설정 최소값일 때의 글자 행 높이와 같다
    public static let portraitNumberRowHeight: CGFloat = letterRowHeight(
        keyboardAreaHeight: CGFloat(KeyboardLayoutFigure.keyboardHeightRange.lowerBound)
    )
    /// 세로 모드 숫자 행이 글자 행 증가폭 중 따라 커지는 비율.
    /// 1보다 작게 둬 숫자 행이 항상 글자 행보다 낮은 보조 행으로 보이게 한다
    static let portraitNumberRowGrowthRatio: CGFloat = 0.5
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

    /// 화면 방향에 맞는 숫자 행 높이. 숫자 행이 없으면 0을 반환한다.
    ///
    /// 세로 모드는 키보드 높이 설정을 따라 최소 높이에서 글자 행 증가폭의 일부만큼 커진다.
    /// 가로 모드는 높이 설정이 적용되지 않으므로 고정값이다
    /// - Parameters:
    ///   - isEnabled: 숫자 행 설정 여부
    ///   - usesPortraitHeight: 세로 높이 규칙 적용 여부. iPhone Duo 안쪽 화면은 가로여도 `true`다
    ///   - keyboardSettingsHeight: 키보드 높이 설정값
    public static func numberRowHeight(
        isEnabled: Bool,
        usesPortraitHeight: Bool,
        keyboardSettingsHeight: CGFloat
    ) -> CGFloat {
        guard isEnabled else { return 0 }
        guard usesPortraitHeight else { return landscapeNumberRowHeight }

        let letterRowGrowth = letterRowHeight(keyboardAreaHeight: keyboardSettingsHeight) - portraitNumberRowHeight
        return portraitNumberRowHeight + letterRowGrowth * portraitNumberRowGrowthRatio
    }

    public static func height(
        keyboardSettingsHeight: CGFloat,
        landscapeKeyboardHeight: CGFloat,
        suggestionBarHeight: CGFloat,
        isSuggestionBarVisible: Bool,
        usesPortraitHeight: Bool,
        numberRowHeight: CGFloat = 0
    ) -> Height {
        let visibleSuggestionBarHeight = isSuggestionBarVisible ? suggestionBarHeight : 0

        if usesPortraitHeight {
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

    public static func usesPortraitHeight(
        orientation: UIInterfaceOrientation,
        usesOrientation: Bool = true,
        fallbackBounds: CGRect,
        horizontalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        verticalSizeClass: UIUserInterfaceSizeClass = .unspecified
    ) -> Bool {
        if !usesOrientation {
            return traitUsesPortraitHeight(
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
            if let usesPortraitHeight = traitUsesPortraitHeight(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            ) {
                return usesPortraitHeight
            }

            return fallbackBounds.height >= fallbackBounds.width
        @unknown default:
            return fallbackBounds.height >= fallbackBounds.width
        }
    }

    /// 설정 앱 화면의 size class로 실제 키보드와 같은 높이 규칙을 고른다. iPhone Duo 안쪽 화면은 가로여도 세로 높이 규칙이다.
    /// iPhone의 size class는 항상 정해져 있다. 정해지지 않았으면 세로 높이 규칙을 쓴다
    public static func usesPortraitHeight(
        horizontalSizeClass: UIUserInterfaceSizeClass,
        verticalSizeClass: UIUserInterfaceSizeClass
    ) -> Bool {
        traitUsesPortraitHeight(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) ?? true
    }

    /// 시스템이 키보드를 요청한 높이보다 키웠을 때 키 영역에 줄 높이.
    ///
    /// iPhone Duo 안쪽 화면을 반쯤 펼친 세로에서 시스템은 키보드 높이 제약(우선순위 999)을 덮어써 키보드를 키운다.
    /// 키 영역은 아래에 붙어 있어 그대로 두면 자동완성 바 위에 빈 띠가 남으므로 늘어난 만큼 키 영역에 더한다.
    ///
    /// 안쪽 화면(regular×regular)에서 높이가 안정됐을 때만 더한다. 올라오는 동안, 회전·접기 전환 중,
    /// 높이를 다시 요청한 직후에는 시스템이 잠깐씩 다른 높이를 주므로 거기에 맞추면 키 행이 늘었다 줄어든다.
    /// 다른 기기는 지금까지처럼 요청한 높이를 쓴다
    static func keyAreaHeight(
        requestedKeyAreaHeight: CGFloat,
        requestedKeyboardHeight: CGFloat,
        actualKeyboardHeight: CGFloat,
        isHeightSettled: Bool,
        horizontalSizeClass: UIUserInterfaceSizeClass,
        verticalSizeClass: UIUserInterfaceSizeClass
    ) -> CGFloat {
        guard isHeightSettled,
              horizontalSizeClass == .regular,
              verticalSizeClass == .regular else { return requestedKeyAreaHeight }

        return requestedKeyAreaHeight + max(0, actualKeyboardHeight - requestedKeyboardHeight)
    }

    private static func traitUsesPortraitHeight(
        horizontalSizeClass: UIUserInterfaceSizeClass,
        verticalSizeClass: UIUserInterfaceSizeClass
    ) -> Bool? {
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .regular):
            return true
        case (.compact, .compact), (.regular, .compact):
            return false
        case (.regular, .regular):
            // iPhone Duo 안쪽 화면. iOS 기본 키보드처럼 방향과 관계없이 세로 높이 규칙을 쓴다.
            // 키보드 window는 키보드 영역만이라 bounds 비율로 넘기면 항상 가로로 판정된다
            return true
        default:
            return nil
        }
    }
}
