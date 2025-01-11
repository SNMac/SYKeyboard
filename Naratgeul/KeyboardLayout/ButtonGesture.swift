//
//  ButtonGesture.swift
//  Naratgeul
//
//  Created by 서동환 on 1/11/25.
//

import SwiftUI
import OSLog

enum ButtonState {
    case pressed
    case longPressed
    case drag
    case longPressedDrag
    case released
}

enum DragDirection {
    case up
    case left
    case right
    case down
}

final class Gestures {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "ButtonGestures")
    
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    
    @State var nowState: ButtonState = .released
    @State var dragStartWidth: Double = 0.0
    
    // MARK: - Gesture Methods
    func checkPressed() -> Bool {
        return nowState == .pressed || nowState == .longPressed || nowState == .longPressedDrag ? true : false
    }
    
    func moveCursor(dragGestureValue: DragGesture.Value) {
        // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
        let dragDiff = dragGestureValue.translation.width - dragStartWidth
        if dragDiff < -cursorMoveWidth {
            os_log("NaratgeulButton) Drag to left", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToLeft() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        } else if dragDiff > cursorMoveWidth {
            os_log("NaratgeulButton) Drag to right", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToRight() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        }
    }
    
    func checkDraggingInsideButton(dragGestureValue: DragGesture.Value, position: CGRect) -> Bool {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        if dragXLocation >= position.minX && dragXLocation <= position.maxX
            && dragYLocation >= position.minY && dragYLocation <= position.maxY {
            return true
        }
        return false
    }
    
    func checkDraggingDirection(dragGestureValue: DragGesture.Value, position: CGRect) -> DragDirection {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        if dragXLocation >= position.minX && dragXLocation <= position.maxX && dragYLocation < position.minY {
            return .up
        } else if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
            return .left
        } else if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation > position.maxX {
            return .right
        } else {
            return .down
        }
    }
}
