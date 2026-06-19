//
//  KeyboardPresentationStatePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

enum KeyboardPresentationStatePolicy {

    static func isReturnButtonEnabled(
        enablesReturnKeyAutomatically: Bool,
        documentContextBeforeInput: String?,
        selectedText: String?,
        documentContextAfterInput: String?
    ) -> Bool {
        guard enablesReturnKeyAutomatically else { return true }

        let hasTextBeforeInput = documentContextBeforeInput?.isEmpty == false
        let hasSelectedText = selectedText?.isEmpty == false
        let hasTextAfterInput = documentContextAfterInput?.isEmpty == false
        return hasTextBeforeInput || hasSelectedText || hasTextAfterInput
    }

    static func shouldHideSuggestionBar(
        isPredictiveTextEnabled: Bool,
        autocorrectionType: UITextAutocorrectionType,
        currentKeyboard: SYKeyboardType
    ) -> Bool {
        return !isPredictiveTextEnabled
        || autocorrectionType == .no
        || currentKeyboard == .tenKey
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
