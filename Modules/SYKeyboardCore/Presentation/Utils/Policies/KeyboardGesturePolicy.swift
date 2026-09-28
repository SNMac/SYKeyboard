//
//  KeyboardGesturePolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 5/22/26.
//

import UIKit

enum KeyboardGesturePolicy {

    /// 삭제 pan을 멈춰 있어도 이어 가는 창 좌우 가장자리 구역 너비
    static let deletePanEdgeWidth: CGFloat = 20

    /// 가장자리 이어 가기 반복 간격 하한
    ///
    /// 줄 경계에서는 입력창 반영(실측 최대 약 25ms)을 기다려 판정한다. 가장자리 반복이 그보다 빠르면
    /// 경계마다 대기와 보류가 겹쳐 쌓이므로, 반복 속도 설정보다 우선해 50ms보다 짧아지지 않게 한다
    static let minimumDeletePanEdgeRepeatInterval: TimeInterval = 0.05

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

    /// 삭제 pan 위치가 창 가장자리 구역이면 이어 갈 방향을 반환합니다.
    ///
    /// 손가락이 베젤에 막혀 더 끌 수 없을 때 왼쪽 끝은 삭제, 오른쪽 끝은 복구를 계속하기 위한 판정입니다.
    static func deletePanEdgeDirection(locationX: CGFloat, containerWidth: CGFloat) -> PanDirection? {
        guard containerWidth > 0 else { return nil }

        if locationX <= deletePanEdgeWidth {
            return .left
        } else if locationX >= containerWidth - deletePanEdgeWidth {
            return .right
        }
        return nil
    }

    /// 가장자리 이어 가기 반복 간격을 반환합니다. 반복 속도 설정을 따르되 하한보다 짧아지지 않습니다.
    static func deletePanEdgeRepeatInterval(repeatRate: Double) -> TimeInterval {
        return max(
            KeyboardTextInteractionPolicy.repeatTimerInterval(repeatRate: repeatRate),
            minimumDeletePanEdgeRepeatInterval
        )
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
