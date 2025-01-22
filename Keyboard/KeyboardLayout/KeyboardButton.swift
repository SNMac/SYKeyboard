//
//  KeyboardButton.swift
//  Keyboard
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
    case inside
    case up
    case left
    case right
    case down
}

struct KeyboardButton: View {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard.Keyboard", category: "KeyboardButton")
    
    @EnvironmentObject private var state: KeyboardState
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("isNumericKeyboardTypeEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isNumericKeyboardTypeEnabled = true
    @AppStorage("isOneHandKeyboardEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOneHandKeyboardEnabled = true
    @AppStorage("currentOneHandKeyboard", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandKeyboard = 1
    
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
        var executeOnPressed: Bool = true
        
        if state.activeKeyboardSelectOverlay {
            forceExitInputTypeSelect()
            executeOnPressed = false
        }
        
        if state.activeOneHandKeyboardSelectOverlay {
            forceExitOneHandKeyboardSelect()
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
            case .longPressedDrag:
                state.nowPressedButton?.onLongPressedReleased()
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
    
    // MARK: - Gesture Execution Methods
    private func onPressed() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowState = .pressed
        onPress()
    }
    
    private func onLongPressed() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowState = .longPressed
        if text == "!#1" || text == "한글" {
            if isOneHandKeyboardEnabled {
                activateOneHandKeyboardSelect()
            }
        } else {
            onLongPress?()
        }
    }
    
    private func onDrag(dragGestureValue: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowState != .drag {
            nowState = .drag  // 드래그 시작
            dragStartWidth = dragGestureValue.translation.width
        }
        
        if primary {  // 글자 입력 버튼 드래그 -> 커서 이동
            moveCursor(dragGestureValue: dragGestureValue)
            
        } else if systemName == "return.left" {  // 리턴 버튼
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
            
        } else if text == "!#1" || text == "한글" {  // 자판 전환 버튼 드래그 -> 자판 or 한손 키보드 변경
            if state.activeKeyboardSelectOverlay {
                selectInputType(dragGestureValue: dragGestureValue)
            } else if state.activeOneHandKeyboardSelectOverlay {
                selectOneHandKeyboard(dragGestureValue: dragGestureValue)
            } else {
                checkDraggingForOverlayActivation(dragGestureValue: dragGestureValue)
            }
        }
    }
    
    private func onLongPressedDrag(dragGestureValue: DragGesture.Value) {
        if nowState != .longPressedDrag {
            nowState = .longPressedDrag  // 드래그 시작
        }
        
        if systemName == "return.left" {  // 리턴 버튼
            if checkDraggingDirection(dragGestureValue: dragGestureValue) != .inside {
                initButtonState()
            }
        } else if text == "!#1" || text == "한글" {
            if state.activeKeyboardSelectOverlay {
                selectInputType(dragGestureValue: dragGestureValue)
            } else if state.activeOneHandKeyboardSelectOverlay {
                selectOneHandKeyboard(dragGestureValue: dragGestureValue)
            } else {
                checkDraggingForOverlayActivation(dragGestureValue: dragGestureValue)
            }
        }
    }
    
    private func onReleased() {  // 버튼 뗐을 때
        if nowState == .pressed {
            if !checkOverlayActive() {
                onRelease?()
            }
        }
        applyInputType()
        applyOneHandKeyboard()
        
        initButtonState()
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
        applyInputType()
        if nowState == .longPressedDrag {
            applyOneHandKeyboard()
        }
        
        initButtonState()
    }
    
    // MARK: - Input Type Select Methods
    private func activateInputTypeSelect() {
        state.activeKeyboardSelectOverlay = true
    }
    
    private func selectInputType(dragGestureValue: DragGesture.Value) {
        let dragXLocation = dragGestureValue.location.x
        
        if state.currentKeyboard == .hangeul {
            if state.selectedKeyboard != .numeric && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                state.selectedKeyboard = .numeric
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedKeyboard != .hangeul && dragXLocation > state.inputTypeButtonPosition[1].minX {
                state.selectedKeyboard = .hangeul
                Feedback.shared.playHapticByForce(style: .light)
            }
            
        } else if state.currentKeyboard == .numeric {
            if state.selectedKeyboard != .symbol && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                state.selectedKeyboard = .symbol
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedKeyboard != .numeric && dragXLocation > state.inputTypeButtonPosition[1].minX {
                state.selectedKeyboard = .numeric
                Feedback.shared.playHapticByForce(style: .light)
            }
            
        } else if state.currentKeyboard == .symbol {
            if state.selectedKeyboard != .numeric && dragXLocation >= state.inputTypeButtonPosition[0].maxX {
                state.selectedKeyboard = .numeric
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedKeyboard != .symbol && dragXLocation < state.inputTypeButtonPosition[0].maxX {
                state.selectedKeyboard = .symbol
                Feedback.shared.playHapticByForce(style: .light)
            }
        }
    }
    
    private func applyInputType() {
        if let selectedKeyboard = state.selectedKeyboard {
            state.currentKeyboard = selectedKeyboard
            state.activeKeyboardSelectOverlay = false
            state.selectedKeyboard = nil
        }
    }
    
    private func forceExitInputTypeSelect() {
        state.activeKeyboardSelectOverlay = false
        state.selectedKeyboard = nil
    }
    
    // MARK: - One Hand Mode Select Methods
    private func activateOneHandKeyboardSelect() {
        state.selectedOneHandKeyboard = state.currentOneHandKeyboard
        state.activeOneHandKeyboardSelectOverlay = true
        Feedback.shared.playHaptic(style: .light)
    }
    
    private func selectOneHandKeyboard(dragGestureValue: DragGesture.Value) {
        let dragXLocation = dragGestureValue.location.x
        let dragYLocation = dragGestureValue.location.y
        
        // 특정 방향으로 일정 거리 초과 드래그 -> 한 손 키보드 변경
        if state.selectedOneHandKeyboard != .left
            && dragXLocation >= state.oneHandButtonPosition[0].minX && dragXLocation < state.oneHandButtonPosition[1].minX
            && dragYLocation >= state.oneHandButtonPosition[0].minY && dragYLocation <= state.oneHandButtonPosition[0].maxY {
            state.selectedOneHandKeyboard = .left
            Feedback.shared.playHapticByForce(style: .light)
        } else if state.selectedOneHandKeyboard != .center
                    && dragXLocation >= state.oneHandButtonPosition[1].minX && dragXLocation <= state.oneHandButtonPosition[1].maxX
                    && dragYLocation >= state.oneHandButtonPosition[1].minY && dragYLocation <= state.oneHandButtonPosition[1].maxY {
            state.selectedOneHandKeyboard = .center
            Feedback.shared.playHapticByForce(style: .light)
        } else if state.selectedOneHandKeyboard != .right
                    && dragXLocation > state.oneHandButtonPosition[1].maxX && dragXLocation <= state.oneHandButtonPosition[2].maxX
                    && dragYLocation >= state.oneHandButtonPosition[2].minY && dragYLocation <= state.oneHandButtonPosition[2].maxY {
            state.selectedOneHandKeyboard = .right
            Feedback.shared.playHapticByForce(style: .light)
        } else if dragXLocation < state.oneHandButtonPosition[0].minX || dragXLocation > state.oneHandButtonPosition[2].maxX
                    || dragYLocation < state.oneHandButtonPosition[0].minY || dragYLocation > state.oneHandButtonPosition[2].maxY {
            state.selectedOneHandKeyboard = state.currentOneHandKeyboard
        }
    }
    
    private func applyOneHandKeyboard() {
        if let selectedOneHandKeyboard = state.selectedOneHandKeyboard {
            state.currentOneHandKeyboard = selectedOneHandKeyboard
            currentOneHandKeyboard = selectedOneHandKeyboard.rawValue
            state.activeOneHandKeyboardSelectOverlay = false
            state.selectedOneHandKeyboard = nil
        }
    }
    
    private func forceExitOneHandKeyboardSelect() {
        state.activeOneHandKeyboardSelectOverlay = false
        state.selectedOneHandKeyboard = nil
    }
    
    // MARK: - Basic Methods
    private func moveCursor(dragGestureValue: DragGesture.Value) {
        // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
        let dragDiff = dragGestureValue.translation.width - dragStartWidth
        if dragDiff < -cursorMoveWidth {
            os_log("Move cursor to left", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToLeft() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        } else if dragDiff > cursorMoveWidth {
            os_log("Move cursor to right", log: log, type: .debug)
            dragStartWidth = dragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToRight() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
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
    
    private func checkOverlayActive() -> Bool {
        return state.activeKeyboardSelectOverlay || state.activeOneHandKeyboardSelectOverlay
    }
    
    private func checkDraggingForOverlayActivation(dragGestureValue: DragGesture.Value) {
        if !checkOverlayActive() {
            switch checkDraggingDirection(dragGestureValue: dragGestureValue) {
            case .inside:
                break
            case .up:  // 버튼 위쪽으로 드래그
                if isOneHandKeyboardEnabled {
                    activateOneHandKeyboardSelect()
                } else {
                    initButtonState()
                }
            case .left:  // 버튼 왼쪽으로 드래그
                if state.currentKeyboard == .hangeul || state.currentKeyboard == .numeric {  // 한글 or 숫자 자판
                    if isNumericKeyboardTypeEnabled {
                        activateInputTypeSelect()  // 다른 자판으로 변경
                    } else {
                        initButtonState()
                    }
                }
            case .right:  // 버튼 오른쪽으로 드래그
                if state.currentKeyboard == .symbol {  // 기호 자판
                    if isNumericKeyboardTypeEnabled {
                        activateInputTypeSelect()  // 다른 자판으로 변경
                    } else {
                        initButtonState()
                    }
                }
            case .down:  // 버튼 아래쪽으로 드래그
                initButtonState()
            }
        }
    }
    
    // MARK: - KeyboardButton
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
                        .background(checkPressed() || checkOverlayActive() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumericKeyboardTypeEnabled {
                                    Image(systemName: state.activeKeyboardSelectOverlay ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9, weight: state.activeKeyboardSelectOverlay ? .bold : .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 0) {
                                if isOneHandKeyboardEnabled {
                                    Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "keyboard.fill" : "keyboard")
                                    Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                }
                            }
                            .font(.system(size: 9, weight: state.activeOneHandKeyboardSelectOverlay ? .bold : .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                        })
                    
                } else if text == "한글" {
                    if state.currentKeyboard == .symbol {  // 기호 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() || checkOverlayActive() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumericKeyboardTypeEnabled {
                                        Text("123")
                                        Image(systemName: state.activeKeyboardSelectOverlay ? "arrowtriangle.right.fill" : "arrowtriangle.right")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.activeKeyboardSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 1))
                            })
                            .overlay(alignment: .topLeading, content: {
                                HStack(spacing: 0) {
                                    if isOneHandKeyboardEnabled {
                                        Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                        Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "keyboard.fill" : "keyboard")
                                    }
                                }
                                .font(.system(size: 9, weight: state.activeOneHandKeyboardSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                            })
                        
                    } else if state.currentKeyboard == .numeric {  // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() || checkOverlayActive() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
                                HStack(spacing: 1) {
                                    Image(systemName: state.activeKeyboardSelectOverlay ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("!#1")
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.activeKeyboardSelectOverlay ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                            })
                            .overlay(alignment: .topTrailing, content: {
                                HStack(spacing: 0) {
                                    if isOneHandKeyboardEnabled {
                                        Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "keyboard.fill" : "keyboard")
                                        Image(systemName: state.activeOneHandKeyboardSelectOverlay ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                    }
                                }
                                .font(.system(size: 9, weight: state.activeOneHandKeyboardSelectOverlay ? .bold : .regular))
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
                    os_log("LongPressGesture() onEnded: pressed", log: log, type: .debug)
                    gesturePressed()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth)
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
                .exclusively(before: DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
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
