//
//  KeyboardPresentationStatePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

public enum KeyboardPresentationStatePolicy {

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
    /// 후보 영역·undo/redo·클립보드 중 하나라도 쓸 수 있으면 바를 보여준다.
    /// 후보를 못 쓰는 이유가 설정 OFF인지 필드 차단인지는 구분하지 않는다.
    /// 텐키는 후보 이외의 기능도 쓰지 않으므로 그대로 숨긴다.
    static func shouldHideSuggestionBar(
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType?,
        currentKeyboard: SYKeyboardType,
        isUndoRedoEnabled: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        guard currentKeyboard != .tenKey else { return true }

        return !isSuggestionAreaUsable(
            isPredictiveTextEnabled: isPredictiveTextEnabled,
            autocorrectionType: autocorrectionType
        )
        && !isUndoRedoEnabled
        && !isClipboardHistoryEnabled
    }

    /// 앱 설정 미리보기에서 suggestion bar 자리를 잡을지 판단한다.
    ///
    /// 텍스트 필드와 현재 자판을 모르는 호출자를 위한 진입점이다.
    /// 미리보기 높이가 실제 키보드 높이와 어긋나지 않도록 같은 규칙을 위임해서 쓴다.
    public static func isSuggestionBarVisibleForSettingsPreview(
        isPredictiveTextEnabled: Bool,
        isUndoRedoEnabled: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        return !shouldHideSuggestionBar(
            isPredictiveTextEnabled: isPredictiveTextEnabled,
            // 미리보기는 특정 텍스트 필드에 붙지 않고 텐키로 전환되지도 않는다
            autocorrectionType: nil,
            currentKeyboard: .naratgeul,
            isUndoRedoEnabled: isUndoRedoEnabled,
            isClipboardHistoryEnabled: isClipboardHistoryEnabled
        )
    }

    /// suggestion bar 안의 후보 영역을 숨길지 판단한다.
    ///
    /// 바 자체가 숨겨졌으면 후보 영역도 숨김으로 본다.
    static func shouldHideSuggestionButtons(
        isSuggestionBarHidden: Bool,
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType?
    ) -> Bool {
        guard !isSuggestionBarHidden else { return true }

        return !isSuggestionAreaUsable(
            isPredictiveTextEnabled: isPredictiveTextEnabled,
            autocorrectionType: autocorrectionType
        )
    }

    /// 후보 영역을 쓸 수 있는 상태인지 판단한다. 설정이 켜져 있고 텍스트 필드가 막지 않아야 한다
    private static func isSuggestionAreaUsable(
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType?
    ) -> Bool {
        return isPredictiveTextEnabled && autocorrectionType != .no
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

    /// 바가 보일 때 클립보드 설정이 켜져 있으면 버튼을 표시한다
    static func shouldShowClipboardControl(
        isSuggestionBarHidden: Bool,
        isClipboardHistoryEnabled: Bool
    ) -> Bool {
        return !isSuggestionBarHidden && isClipboardHistoryEnabled
    }
}
