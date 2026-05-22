//
//  KeyboardGesturePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

enum KeyboardGesturePolicy {

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
