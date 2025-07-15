//
//  PreviewKeyboardButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
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
    case inside
    case up
    case left
    case right
    case down
}

struct PreviewKeyboardButton: View {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "PreviewKeyboardButton")
    
    @EnvironmentObject private var state: PreviewKeyboardState
    @AppStorage(UserDefaultsKeys.longPressDuration, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var longPressDuration = DefaultValues.longPressDuration
    @AppStorage(UserDefaultsKeys.cursorActiveDistance, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var cursorActiveDistance = DefaultValues.cursorActiveDistance
    @AppStorage(UserDefaultsKeys.cursorMoveInterval, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var cursorMoveInterval = DefaultValues.cursorMoveInterval
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    @AppStorage(UserDefaultsKeys.isNumericKeypadEnabled, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var isNumericKeypadEnabled = DefaultValues.isNumericKeypadEnabled
    @AppStorage(UserDefaultsKeys.isOneHandedKeyboardEnabled, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var isOneHandedKeyboardEnabled = DefaultValues.isOneHandedKeyboardEnabled
    
    @State var nowState: ButtonState = .released
    
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
    
    // MARK: - Gesture Recognization Methods
    
    private func gesturePressed() {
        if state.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.nowPressedButton?.nowState {
            case .pressed:
                state.nowPressedButton?.onReleased()
            case .longPressed:
                state.nowPressedButton?.onLongPressedReleased()
            case .drag:
                state.nowPressedButton?.onReleased()
            case .longPressedDrag:
                state.nowPressedButton?.onLongPressedReleased()
            default:
                break
            }
        }
        
        state.nowPressedButton = self
        onPressed()
    }
    
    private func gestureLongPressed() {
        if nowState == .pressed {
            onLongPressed()
        }
    }
    
    private func gestureDrag(dragGestureValue: DragGesture.Value) {
        if nowState == .pressed || nowState == .drag {
            onDrag(dragGestureValue: dragGestureValue)
        }
    }
    
    private func gestureLongPressedDrag(dragGestureValue: DragGesture.Value) {
        if nowState == .longPressed || nowState == .longPressedDrag {
            onLongPressedDrag(dragGestureValue: dragGestureValue)
        }
    }
    
    private func gestureReleased() {
        if nowState == .longPressed || nowState == .longPressedDrag {
            onLongPressedReleased()
        } else if nowState != .released {
            onReleased()
        }
    }
    
    // MARK: - Gesture Execution Methods
    
    private func onPressed() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowState = .pressed
        onPress()
    }
    
    private func onLongPressed() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowState = .longPressed
        onLongPress?()
    }
    
    private func onDrag(dragGestureValue: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowState != .drag {  // 드래그 시작
            dragStartWidth = dragGestureValue.translation.width
            nowState = .drag
        }
        
        if primary {  // 글자 입력 버튼 드래그 -> 커서 이동
            moveCursor(dragGestureValue: dragGestureValue)
        } else if systemName == "return.left" {  // 리턴 버튼
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
        } else if text == "!#1" || text == "한글" {
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
        }
    }
    
    private func onLongPressedDrag(dragGestureValue: DragGesture.Value) {
        if nowState != .longPressedDrag {  // 드래그 시작
            nowState = .longPressedDrag
        }
        
        if systemName == "return.left" {  // 리턴 버튼
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
        } else if text == "!#1" || text == "한글" {
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
        }
    }
    
    private func onReleased() {  // 버튼 뗐을 때
        if nowState == .pressed {
            onRelease?()
        }
        initButtonState()
    }
    
    private func onLongPressedReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowState = .released
        if let onLongPressRelease {
            onLongPressRelease()
        } else {
            onRelease?()
        }
        initButtonState()
    }
    
    // MARK: - Basic Methods
    
    private func moveCursor(dragGestureValue: DragGesture.Value) {
        // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
        let dragDiff = dragGestureValue.translation.width - dragStartWidth
        if dragDiff < -cursorMoveInterval {
            os_log("Move cursor to left", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            FeedbackManager.shared.playHapticByForce(style: .light)
        } else if dragDiff > cursorMoveInterval {
            os_log("Move cursor to right", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            FeedbackManager.shared.playHapticByForce(style: .light)
        }
    }
    
    private func checkDraggingDirection(dragGestureValue: DragGesture.Value) -> DragDirection {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        if dragXLocation >= position.minX && dragXLocation <= position.maxX
            && dragYLocation >= position.minY && dragYLocation <= position.maxY {
            return .inside
        } else if dragXLocation >= position.minX && dragXLocation <= position.maxX && dragYLocation < position.minY {
            return .up
        } else if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
            return .left
        } else if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation > position.maxX {
            return .right
        } else {
            return .down
        }
    }
    
    // MARK: - Other Methods
    
    private func initButtonState() {
        nowState = .released
        state.nowPressedButton = nil
    }
    
    private func checkPressed() -> Bool {
        return nowState == .pressed || nowState == .longPressed || nowState == .longPressedDrag ? true : false
    }
    
    // MARK: - PreviewKeyboardButton
    
    var body: some View {
        let longPressDuration = 1.0 - longPressDuration
        
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
                if text == "!#1" {  // 한글 키보드
                    Text("!#1")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumericKeypadEnabled {
                                    Image(systemName: "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 0) {
                                if isOneHandedKeyboardEnabled {
                                    Image(systemName: "keyboard")
                                    Image(systemName: "arrowtriangle.up")
                                }
                            }
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                        })
                    
                    
                    // 글자 버튼
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
                    os_log("LongPressGesture() onEnded: pressed", log: log, type: .debug)
                    gesturePressed()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: longPressDuration, maximumDistance: cursorActiveDistance)
            // 버튼 길게 눌렀을 때
                .onEnded({ _ in
                    os_log("simultaneous_LongPressGesture() onEnded: longPressed", log: log, type: .debug)
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
                            os_log("LongPressGesture()->DragGesture() onChanged: longPressedDrag", log: log, type: .debug)
                            gestureLongPressedDrag(dragGestureValue: value)
                        }
                    }
                })
                .exclusively(before: DragGesture(minimumDistance: cursorActiveDistance, coordinateSpace: .global)
                             // 버튼 드래그 할 때
                    .onChanged({ value in
                        os_log("exclusively_DragGesture() onChanged: drag", log: log, type: .debug)
                        gestureDrag(dragGestureValue: value)
                    })
                            )
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
            // 버튼 뗐을 때
                .onEnded({ _ in
                    os_log("DragGesture() onEnded: released", log: log, type: .debug)
                    gestureReleased()
                })
        )
    }
}
