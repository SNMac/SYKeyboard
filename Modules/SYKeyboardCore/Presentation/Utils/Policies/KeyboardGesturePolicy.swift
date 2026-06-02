//
//  KeyboardGesturePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

enum KeyboardGesturePolicy {

    static func shouldAddTextInteractionGestures(
        isReturnButton: Bool,
        isSecondaryKeyButton: Bool,
        primaryKeyList: [String]
    ) -> Bool {
        return !isReturnButton
            && !isSecondaryKeyButton
            && primaryKeyList != [".com"]
    }

    static func shouldAddTextInteractionPanGesture(
        isDragToMoveCursorEnabled: Bool,
        isDeleteButton: Bool
    ) -> Bool {
        return isDragToMoveCursorEnabled || isDeleteButton
    }

    static func shouldAddTextInteractionLongPressGesture(
        selectedLongPressAction: LongPressAction,
        isDeleteButton: Bool
    ) -> Bool {
        return selectedLongPressAction != .disabled || isDeleteButton
    }

    static func shouldPerformRepeatInputOnLongPress(
        selectedLongPressAction: LongPressAction,
        isDeleteButton: Bool
    ) -> Bool {
        return selectedLongPressAction == .repeatInput || isDeleteButton
    }

    static func shouldPerformNumberInputOnLongPress(
        selectedLongPressAction: LongPressAction,
        isDeleteButton: Bool
    ) -> Bool {
        return selectedLongPressAction == .numberInput && !isDeleteButton
    }
}
