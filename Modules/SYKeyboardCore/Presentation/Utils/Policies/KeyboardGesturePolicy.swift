//
//  KeyboardGesturePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

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

    static func shouldPlayCursorDragHapticOnTextDidChange(
        isPrimaryCursorDragging: Bool,
        pendingRequestContext: KeyboardTextContextSnapshot?,
        currentContext: KeyboardTextContextSnapshot
    ) -> Bool {
        guard isPrimaryCursorDragging,
              let pendingRequestContext else { return false }

        return normalizedContext(pendingRequestContext.beforeInput)
            != normalizedContext(currentContext.beforeInput)
        || normalizedContext(pendingRequestContext.afterInput)
            != normalizedContext(currentContext.afterInput)
    }

    static func configureSystemGestureForEdgeTouch(_ gesture: UIGestureRecognizer) {
        gesture.delaysTouchesBegan = false
        gesture.delaysTouchesEnded = false
        gesture.cancelsTouchesInView = false

        if gesture is UIScreenEdgePanGestureRecognizer {
            gesture.isEnabled = false
        }
    }
}

private extension KeyboardGesturePolicy {
    static func normalizedContext(_ context: String?) -> String {
        return context ?? ""
    }
}
