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
        documentContextAfterInput: String?
    ) -> Bool {
        guard enablesReturnKeyAutomatically else { return true }

        let hasTextBeforeInput = documentContextBeforeInput?.isEmpty == false
        let hasTextAfterInput = documentContextAfterInput?.isEmpty == false
        return hasTextBeforeInput || hasTextAfterInput
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
}
