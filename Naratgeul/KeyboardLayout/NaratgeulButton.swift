//
//  NaratgeulButton.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 12/20/22.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - KeyboardButton.swift
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

struct NaratgeulButton: View {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "NaratgeulButton")
    
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandModeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandModeEnabled = true
    @AppStorage("currentOneHandMode", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandMode = 1
    
    @State var nowState: ButtonState = .released
    @State var dragStartWidth: Double = 0.0
    @State var position: CGRect = .zero
    
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
        nowState = .pressed
        onPress()
    }
    
    private func onLongPressed() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowState = .longPressed
        if text == "!#1" || text == "한글" {
            if isOneHandModeEnabled {
                activateOneHandModeSelect()
            }
        } else {
            onLongPress?()
        }
    }
    
    private func onDrag(dragGestureValue: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowState != .drag {  // 드래그 시작
            nowState = .drag
            dragStartWidth = dragGestureValue.translation.width
        }
        
        if primary {  // 글자 입력 버튼 드래그 -> 커서 이동
            moveCursor(dragGestureValue: dragGestureValue)
            
        } else if text == "!#1" || text == "한글" {  // 자판 전환 버튼 드래그 -> 자판 or 한손 모드 변경
            if state.activeInputTypeSelectOverlay {
                selectInputType(dragGestureValue: dragGestureValue)
            } else if isNumberKeyboardTypeEnabled {
                checkDraggingForInputTypeOverlayActivation(dragGestureValue: dragGestureValue)
            }
            
            if state.activeOneHandModeSelectOverlay {
                selectOneHandMode(dragGestureValue: dragGestureValue)
            } else if isOneHandModeEnabled {
                checkDraggingForOneHandModeSelectActivation(dragGestureValue: dragGestureValue, position: position)
            }
        }
    }
    
    private func onLongPressedDrag(dragGestureValue: DragGesture.Value) {
        if nowState != .longPressedDrag {  // 드래그 시작
            nowState = .longPressedDrag
        }
        
        if systemName == "return.left" {  // 리턴 버튼
            if !checkDraggingInsideButton(dragGestureValue: dragGestureValue) {
                nowState = .released
                state.nowPressedButton = nil
            }
        } else if text == "!#1" || text == "한글" {
            if isOneHandModeEnabled && !state.activeOneHandModeSelectOverlay {
                activateOneHandModeSelect()
            } else if isNumberKeyboardTypeEnabled {
                checkDraggingForInputTypeOverlayActivation(dragGestureValue: dragGestureValue)
            }
        }
        
        if state.activeInputTypeSelectOverlay {
            selectInputType(dragGestureValue: dragGestureValue)
        }
        
        if state.activeOneHandModeSelectOverlay {
            selectOneHandMode(dragGestureValue: dragGestureValue)
        }
    }
    
    private func onReleased() {  // 버튼 뗐을 때
        if nowState == .pressed || nowState == .drag {
            if !checkOverlayActive() {
                onRelease?()
            }
        }
        state.nowPressedButton = nil
        nowState = .released
        
        applyInputType()
        applyOneHandMode()
    }
    
    private func onLongPressedReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        if nowState == .longPressed || nowState == .longPressedDrag {
            if !checkOverlayActive() {
                if let onLongPressRelease {
                    onLongPressRelease()
                } else {
                    onRelease?()
                }
            }
        }
        state.nowPressedButton = nil
        nowState = .released
    }
    
    // MARK: - Gesture Recognization Methods
    private func checkPressed() -> Bool {
        return nowState == .pressed || nowState == .longPressed || nowState == .longPressedDrag ? true : false
    }
    
    private func gesturePressed() {
        var executeOnPressed: Bool = true
        
        if state.activeInputTypeSelectOverlay {
            forceExitInputTypeSelect()
            executeOnPressed = false
        }
        
        if state.activeOneHandModeSelectOverlay {
            forceExitOneHandModeSelect()
            executeOnPressed = false
        }
        
        if state.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.nowPressedButton?.nowState {
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
        
        if executeOnPressed {
            state.nowPressedButton = self
            onPressed()
        }
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
    
    // MARK: - Basic Gestures
    func checkDraggingInsideButton(dragGestureValue: DragGesture.Value) -> Bool {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        if dragXLocation >= position.minX && dragXLocation <= position.maxX
            && dragYLocation >= position.minY && dragYLocation <= position.maxY {
            return true
        }
        return false
    }
    
    func checkDraggingDirection(dragGestureValue: DragGesture.Value) -> DragDirection {
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
    
    // MARK: - Input Type Select Method
    func checkDraggingForInputTypeOverlayActivation(dragGestureValue: DragGesture.Value) {
        if !checkOverlayActive() {
            if state.currentInputType == .hangeul {  // 한글 자판
                // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .left {
                    activateInputTypeSelect()
                }
                
            } else if state.currentInputType == .number {  // 숫자 자판
                // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .left {
                    activateInputTypeSelect()
                }
                
            } else if state.currentInputType == .symbol {  // 기호 자판
                // 버튼 오른쪽으로 드래그 -> 다른 자판으로 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .right {
                    activateInputTypeSelect()
                }
            }
        }
    }
    
    func activateInputTypeSelect() {
        state.activeInputTypeSelectOverlay = true
    }
    
    func selectInputType(dragGestureValue: DragGesture.Value) {
        let dragXLocation = dragGestureValue.location.x
        
        if state.currentInputType == .hangeul {
            if state.selectedInputType != .number && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                state.selectedInputType = .number
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedInputType != .hangeul && dragXLocation > state.inputTypeButtonPosition[1].minX {
                state.selectedInputType = .hangeul
                Feedback.shared.playHapticByForce(style: .light)
            }
            
        } else if state.currentInputType == .number {
            if state.selectedInputType != .symbol && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                state.selectedInputType = .symbol
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedInputType != .number && dragXLocation > state.inputTypeButtonPosition[1].minX {
                state.selectedInputType = .number
                Feedback.shared.playHapticByForce(style: .light)
            }
            
        } else if state.currentInputType == .symbol {
            if state.selectedInputType != .number && dragXLocation >= state.inputTypeButtonPosition[0].maxX {
                state.selectedInputType = .number
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedInputType != .symbol && dragXLocation < state.inputTypeButtonPosition[0].maxX {
                state.selectedInputType = .symbol
                Feedback.shared.playHapticByForce(style: .light)
            }
        }
    }
    
    func applyInputType() {
        if let selectedInputType = state.selectedInputType {
            state.currentInputType = selectedInputType
            state.activeInputTypeSelectOverlay = false
            state.selectedInputType = nil
        }
    }
    
    func forceExitInputTypeSelect() {
        state.activeInputTypeSelectOverlay = false
        state.selectedInputType = nil
    }
    
    // MARK: - One Hand Mode Select Method
    func checkDraggingForOneHandModeSelectActivation(dragGestureValue: DragGesture.Value, position: CGRect) {
        if !checkOverlayActive() {
            if state.currentInputType == .hangeul {  // 한글 자판
                // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .up {
                    activateOneHandModeSelect()
                }
                
            } else if state.currentInputType == .number {  // 숫자 자판
                // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .up {
                    activateOneHandModeSelect()
                }
                
            } else if state.currentInputType == .symbol {  // 기호 자판
                // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                if checkDraggingDirection(dragGestureValue: dragGestureValue) == .up {
                    activateOneHandModeSelect()
                }
            }
        }
    }
    
    func activateOneHandModeSelect() {
        state.selectedOneHandMode = state.currentOneHandMode
        state.activeOneHandModeSelectOverlay = true
        Feedback.shared.playHaptic(style: .light)
    }
    
    func selectOneHandMode(dragGestureValue: DragGesture.Value) {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        // 특정 방향으로 일정 거리 초과 드래그 -> 한손 키보드 변경
        if state.selectedOneHandMode != .left
            && dragXLocation >= state.oneHandButtonPosition[0].minX && dragXLocation < state.oneHandButtonPosition[1].minX
            && dragYLocation >= state.oneHandButtonPosition[0].minY && dragYLocation <= state.oneHandButtonPosition[0].maxY {
            state.selectedOneHandMode = .left
            Feedback.shared.playHapticByForce(style: .light)
        } else if state.selectedOneHandMode != .center
                    && dragXLocation >= state.oneHandButtonPosition[1].minX && dragXLocation <= state.oneHandButtonPosition[1].maxX
                    && dragYLocation >= state.oneHandButtonPosition[1].minY && dragYLocation <= state.oneHandButtonPosition[1].maxY {
            state.selectedOneHandMode = .center
            Feedback.shared.playHapticByForce(style: .light)
        } else if state.selectedOneHandMode != .right
                    && dragXLocation > state.oneHandButtonPosition[1].maxX && dragXLocation <= state.oneHandButtonPosition[2].maxX
                    && dragYLocation >= state.oneHandButtonPosition[2].minY && dragYLocation <= state.oneHandButtonPosition[2].maxY {
            state.selectedOneHandMode = .right
            Feedback.shared.playHapticByForce(style: .light)
        } else if dragXLocation < state.oneHandButtonPosition[0].minX || dragXLocation > state.oneHandButtonPosition[2].maxX
                    || dragYLocation < state.oneHandButtonPosition[0].minY || dragYLocation > state.oneHandButtonPosition[2].maxY {
            state.selectedOneHandMode = state.currentOneHandMode
        }
    }
    
    func applyOneHandMode() {
        if let selectedOneHandMode = state.selectedOneHandMode {
            state.currentOneHandMode = selectedOneHandMode
            currentOneHandMode = selectedOneHandMode.rawValue
            state.activeOneHandModeSelectOverlay = false
            state.selectedOneHandMode = nil
        }
    }
    
    func forceExitOneHandModeSelect() {
        state.activeOneHandModeSelectOverlay = false
        state.selectedOneHandMode = nil
    }
    
    // MARK: - Other Methods
    private func checkOverlayActive() -> Bool {
        return state.activeInputTypeSelectOverlay || state.activeOneHandModeSelectOverlay
    }
    
    func moveCursor(dragGestureValue: DragGesture.Value) {
        // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
        let dragDiff = dragGestureValue.translation.width - dragStartWidth
        if dragDiff < -cursorMoveWidth {
            os_log("Gestures) Drag to left", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToLeft() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        } else if dragDiff > cursorMoveWidth {
            os_log("Gestures) Drag to right", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToRight() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        }
    }
    
    // MARK: - NaratgeulButton
    var body: some View {
        Button(action: {}) {
            // Image 버튼들
            if systemName != nil {
                if systemName == "return.left" {  // 리턴 버튼
                    if state.returnButtonType == .default {
                        Image(systemName: "return.left")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: imageSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == .continue || state.returnButtonType == .next {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == .go || state.returnButtonType == .send {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(checkPressed() ? Color(uiColor: UIColor.label) : Color.white)
                            .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    } else {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(checkPressed() ? Color(uiColor: UIColor.label) : Color.white)
                            .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    
                    
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
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() || state.activeOneHandModeSelectOverlay || state.activeInputTypeSelectOverlay ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Image(systemName: state.activeInputTypeSelectOverlay ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9, weight: state.activeInputTypeSelectOverlay ? .bold : .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 0) {
                                if isOneHandModeEnabled {
                                    Image(systemName: state.activeOneHandModeSelectOverlay ? "keyboard.fill" : "keyboard")
                                    Image(systemName: state.activeOneHandModeSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                }
                            }
                            .font(.system(size: 9, weight: state.activeOneHandModeSelectOverlay ? .bold : .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                        })
                    
                } else if text == "한글" {
                    if state.currentInputType == .symbol {  // 기호 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() || state.activeOneHandModeSelectOverlay || state.activeInputTypeSelectOverlay ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumberKeyboardTypeEnabled {
                                        Text("123")
                                        Image(systemName: state.activeInputTypeSelectOverlay ? "arrowtriangle.right.fill" : "arrowtriangle.right")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.activeInputTypeSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 1))
                            })
                            .overlay(alignment: .topLeading, content: {
                                HStack(spacing: 0) {
                                    if isOneHandModeEnabled {
                                        Image(systemName: state.activeOneHandModeSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                        Image(systemName: state.activeOneHandModeSelectOverlay ? "keyboard.fill" : "keyboard")
                                    }
                                }
                                .font(.system(size: 9, weight: state.activeOneHandModeSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                            })
                        
                    } else if state.currentInputType == .number {  // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() || state.activeOneHandModeSelectOverlay || state.activeInputTypeSelectOverlay ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
                                HStack(spacing: 1) {
                                    Image(systemName: state.activeInputTypeSelectOverlay ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("!#1")
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.activeInputTypeSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                            })
                            .overlay(alignment: .topTrailing, content: {
                                HStack(spacing: 0) {
                                    if isOneHandModeEnabled {
                                        Image(systemName: state.activeOneHandModeSelectOverlay ? "keyboard.fill" : "keyboard")
                                        Image(systemName: state.activeOneHandModeSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                    }
                                }
                                .font(.system(size: 9, weight: state.activeOneHandModeSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                            })
                    }
                    
                } else if text == "\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)" {
                    Text("\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .monospaced()
                        .font(.system(size: textSize - 2))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else if text == ".com" {
                    Text(".com")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else if text == "@_twitter" {
                    Text("@")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else if text == "#_twitter" {
                    Text("#")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
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
                    os_log("NaratgeulButton) LongPressGesture() onEnded: pressing", log: log, type: .debug)
                    gesturePressed()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth)
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
                            gestureLongPressedDrag(dragGestureValue: value)
                        }
                    }
                })
                .exclusively(before: DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
                             // 버튼 드래그 할 때
                    .onChanged({ value in
                        os_log("NaratgeulButton) exclusively_DragGesture() onChanged: dragging", log: log, type: .debug)
                        gestureDrag(dragGestureValue: value)
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

extension NaratgeulButton {
    
}
