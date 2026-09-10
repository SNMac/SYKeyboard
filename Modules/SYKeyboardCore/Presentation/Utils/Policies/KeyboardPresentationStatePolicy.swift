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

    /// suggestion bar 전체를 숨길지 판단한다.
    ///
    /// `autocorrectionType == .no`이면 후보는 못 쓰지만 undo/redo나 클립보드는 여전히 쓸 수 있으므로,
    /// 둘 중 하나라도 켜져 있으면 바를 유지하고 후보 영역만 비운다.
    /// 텐키는 후보 이외의 기능도 쓰지 않으므로 그대로 숨긴다.
    static func shouldHideSuggestionBar(
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType?,
        currentKeyboard: SYKeyboardType,
        isUndoRedoEnabled: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        guard isPredictiveTextEnabled, currentKeyboard != .tenKey else { return true }
        guard autocorrectionType == .no else { return false }

        return !isUndoRedoEnabled && !isClipboardHistoryEnabled
    }

    /// suggestion bar 안의 후보 영역만 숨길지 판단한다.
    static func shouldHideSuggestionButtons(autocorrectionType: UITextAutocorrectionType?) -> Bool {
        return autocorrectionType == .no
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

    /// suggestion bar가 보일 때는 자동완성이 켜져 있으므로 클립보드 설정만 추가로 본다
    static func shouldShowClipboardControl(
        isSuggestionBarHidden: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        return !isSuggestionBarHidden && isClipboardHistoryEnabled
    }
}
