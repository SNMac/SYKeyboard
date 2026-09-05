//
//  KeyboardPresentationStatePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

enum KeyboardPresentationStatePolicy {

    /// 한 손 키보드 최소 폭을 현재 가용 폭 안으로 제한한 값
    ///
    /// 최소 폭 제약은 required로 유지해야 `UIStackView`의 내부 제약에 밀려 무시되지 않는다.
    /// 다만 회전 도중처럼 가용 폭이 설정 폭보다 좁아지면 required 제약이 충돌하므로,
    /// 상수를 가용 폭까지 낮춰 충돌 없이 "가능하면 설정 폭 이상"을 만족시킨다.
    static func oneHandedKeyboardMinimumWidth(
        configuredWidth: CGFloat,
        availableWidth: CGFloat
    ) -> CGFloat {
        return min(configuredWidth, max(0, availableWidth))
    }

    static func isReturnButtonEnabled(
        enablesReturnKeyAutomatically: Bool,
        documentContextBeforeInput: String?,
        selectedText: String?,
        documentContextAfterInput: String?
    ) -> Bool {
        guard enablesReturnKeyAutomatically else { return true }

        return documentContextBeforeInput?.isEmpty == false
        || selectedText?.isEmpty == false
        || documentContextAfterInput?.isEmpty == false
    }

    static func shouldHideSuggestionBar(
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType?,
        currentKeyboard: SYKeyboardType
    ) -> Bool {
        return !isPredictiveTextEnabled
        || autocorrectionType == .no
        || currentKeyboard == .tenKey
    }

    static func shouldShowMathResults(
        isSettingEnabled: Bool,
        isHostCompletionAllowed: Bool
    ) -> Bool {
        return isSettingEnabled && isHostCompletionAllowed
    }

    static func shouldShowUndoRedoControls(
        isSuggestionBarHidden: Bool,
        isUndoRedoFeatureAvailable: Bool
    ) -> Bool {
        return !isSuggestionBarHidden && isUndoRedoFeatureAvailable
    }

    static func isUndoRedoFeatureAvailable(
        isPredictiveTextEnabled: Bool,
        isUndoRedoEnabled: Bool
    ) -> Bool {
        return isPredictiveTextEnabled && isUndoRedoEnabled
    }
}
