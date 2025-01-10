//
//  PreviewNaratgeulButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import SwiftUI
import OSLog

enum Gestures {
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

struct PreviewNaratgeulButton: View {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "Preview")
    
    @EnvironmentObject private var state: PreviewNaratgeulState
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = GlobalValues.defaultLongPressSpeed
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = true
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    
    @State private var nowGesture: Gestures = .released
    @State private var dragStartWidth: Double = 0.0
    @State private var position: CGRect = .zero
    
    private let imageSize: CGFloat = 20
    private let textSize: CGFloat = 18
    private let keyTextSize: CGFloat = 22
    
    var text: String?
    var systemName: String?
    let primary: Bool
    
    var onPress: () -> Void
    var onRelease: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressRelease: (() -> Void)?
    
    // MARK: - Gesture Execution Methods
    private func onPressed() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressed
        onPress()
    }
    
    private func onLongPressed() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressed
        onLongPress?()
    }
    
    private func onDrag(DragGestureValue: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowGesture != .drag {  // 드래그 시작
            dragStartWidth = DragGestureValue.translation.width
            nowGesture = .drag
        }
        
        if primary {  // 글자 입력 버튼 드래그 -> 커서 이동
            moveCursor(DragGestureValue: DragGestureValue)
        }
    }
    
    private func onLongPressedDrag(DragGestureValue: DragGesture.Value) {
        if nowGesture != .longPressedDrag {  // 드래그 시작
            nowGesture = .longPressedDrag
        }
        
        if systemName == "return.left" {  // 리턴 버튼
            if !checkDraggingInsideButton(DragGestureValue: DragGestureValue) {
                nowGesture = .released
                state.nowPressedButton = nil
            }
        }
    }
    
    private func onReleased() {  // 버튼 뗐을 때
        if nowGesture == .pressed {
            onRelease?()
        }
        nowGesture = .released
        state.nowPressedButton = nil
    }
    
    private func onLongPressedReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        if let onLongPressRelease {
            onLongPressRelease()
        } else {
            onRelease?()
        }
        state.nowPressedButton = nil
    }
    
    // MARK: - Gesture Recognization Methods
    private func gesturePressed() {
        var isOnPressingAvailable: Bool = true
        
        if state.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.nowPressedButton?.nowGesture {
            case .pressed:
                state.nowPressedButton?.onReleased()
            case .longPressed:
                state.nowPressedButton?.onLongPressedReleased()
            case .drag:
                state.nowPressedButton?.onReleased()
            default:
                break
            }
        }
        
        if isOnPressingAvailable {
            state.nowPressedButton = self
            onPressed()
        }
    }
    
    private func gestureLongPressed() {
        if nowGesture == .pressed {
            onLongPressed()
        }
    }
    
    private func gestureDrag(DragGestureValue: DragGesture.Value) {
        if nowGesture == .pressed || nowGesture == .drag {
            onDrag(DragGestureValue: DragGestureValue)
        }
    }
    
    private func gestureLongPressedDrag(DragGestureValue: DragGesture.Value) {
        if nowGesture == .longPressed || nowGesture == .longPressedDrag {
            onLongPressedDrag(DragGestureValue: DragGestureValue)
        }
    }
    
    private func gestureReleased() {
        if nowGesture == .longPressed || nowGesture == .longPressedDrag {
            onLongPressedReleased()
        } else if nowGesture != .released {
            onReleased()
        }
    }
    
    // MARK: - Gesture UI Interaction Methods
    private func checkPressed() -> Bool {
        return nowGesture == .pressed || nowGesture == .longPressed || nowGesture == .longPressedDrag ? true : false
    }
    
    private func checkDraggingInsideButton(DragGestureValue: DragGesture.Value) -> Bool {
        let dragXLocation = DragGestureValue.location.x
        let dragYLocation = DragGestureValue.location.y
        
        if dragXLocation >= position.minX && dragXLocation <= position.maxX
            && dragYLocation >= position.minY && dragYLocation <= position.maxY {
            return true
        }
        return false
    }
    
    private func moveCursor(DragGestureValue: DragGesture.Value) {
        // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
        let dragDiff = DragGestureValue.translation.width - dragStartWidth
        if dragDiff < -cursorMoveWidth {
            os_log("NaratgeulButton) Drag to left", log: log, type: .debug)
            dragStartWidth = DragGestureValue.translation.width
            Feedback.shared.playHapticByForce(style: .light)
        } else if dragDiff > cursorMoveWidth {
            os_log("NaratgeulButton) Drag to right", log: log, type: .debug)
            dragStartWidth = DragGestureValue.translation.width
            Feedback.shared.playHapticByForce(style: .light)
        }
    }
    
    // MARK: - NaratgeulButton
    var body: some View {
        let longPressTime = 1.0 - longPressSpeed
        
        Button(action: {}) {
            // Image 버튼들
            if systemName != nil {
                if systemName == "return.left" {  // 리턴 버튼
                    Image(systemName: "return.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
                } else if systemName == "space" {  // 스페이스 버튼
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
                } else if systemName == "delete.left" {  // 삭제 버튼
                    Image(systemName: checkPressed() ? "delete.left.fill" : "delete.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
                } else {
                    Image(systemName: systemName!)  // 그 외 버튼
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton") )
                        .clipShape(.rect(cornerRadius: 5))
                }
                
                // Text 버튼들
            } else if text != nil {
                if text == "!#1" {  // 한글 자판
                    Text("!#1")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .monospaced()
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Image(systemName: "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 0) {
                                if isOneHandTypeEnabled {
                                    Image(systemName: "keyboard")
                                    Image(systemName: "arrowtriangle.up")
                                }
                            }
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                        })
                    
                } else {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: keyTextSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                }
            }
        }
        .compositingGroup()
        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
        .overlay(content: {
            Color.clear
                .onGeometryChange(for: CGRect.self) { geometry in
                    return geometry.frame(in: .global)
                } action: { newValue in
                    position = newValue
                }
        })
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0)
                .onEnded({ _ in
                    // 버튼 눌렀을 때
                    os_log("NaratgeulButton) LongPressGesture() onEnded: pressing", log: log, type: .debug)
                    gesturePressed()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth)
            // 버튼 길게 눌렀을 때
                .onEnded({ _ in
                    os_log("NaratgeulButton) simultaneously_LongPressGesture() onEnded: longPressing", log: log, type: .debug)
                    gestureLongPressed()
                })
                .sequenced(before: DragGesture(minimumDistance: 10, coordinateSpace: .global))
            // 버튼 길게 누르고 드래그시 호출
                .onChanged({ value in
                    switch value {
                    case .first(_):
                        break
                    case .second(_, let dragValue):
                        if let value = dragValue {
                            os_log("NaratgeulButton) LongPressGesture()->DragGesture() onChanged: longPressedDragging", log: log, type: .debug)
                            gestureLongPressedDrag(DragGestureValue: value)
                        }
                    }
                })
                .exclusively(before: DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
                             // 버튼 드래그 할 때
                    .onChanged({ value in
                        os_log("NaratgeulButton) exclusively_DragGesture() onChanged: dragging", log: log, type: .debug)
                        gestureDrag(DragGestureValue: value)
                    })
                             // 버튼 드래그 한 뒤 뗐을 때
                    .onEnded({ _ in
                        os_log("NaratgeulButton) exclusively_DragGesture() onEnded: dragging", log: log, type: .debug)
                        gestureReleased()
                    })
                            )
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
            // 버튼 뗐을 때
                .onEnded({ _ in
                    os_log("NaratgeulButton) DragGesture() onEnded: released", log: log, type: .debug)
                    gestureReleased()
                })
        )
    }
}
