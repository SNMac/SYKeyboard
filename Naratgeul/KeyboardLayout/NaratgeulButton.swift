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

enum Gestures {
    case pressing
    case longPressing
    case dragging
    case longPressedDragging
    case released
}

enum DragDirection {
    case up
    case left
    case right
    case down
}

struct NaratgeulButton: View {
    let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "NaratgeulButton")
    
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    
    @State var nowGesture: Gestures = .released
    @State private var dragStartWidth: Double = 0.0
    @State private var position: CGRect = .zero
    
    var text: String?
    var systemName: String?
    let primary: Bool
    
    let imageSize: CGFloat = 20
    let textSize: CGFloat = 18
    let keyTextSize: CGFloat = 22
    
    var onPress: () -> Void
    var onRelease: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressRelease: (() -> Void)?
    
    // MARK: - Gesture Execution Methods
    private func onPressing() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressing
        onPress()
    }
    
    private func onLongPressing() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressing
        onLongPress?()
    }
    
    private func onDragging(DragGestureValue: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowGesture != .dragging {  // 드래그 시작
            dragStartWidth = DragGestureValue.translation.width
            nowGesture = .dragging
        }
        
        if primary {  // 글자 입력 버튼 드래그 -> 커서 이동
            moveCursor(DragGestureValue: DragGestureValue)
            
        } else if text == "!#1" || text == "한글" {  // 자판 전환 버튼 드래그 -> 자판 or 한손 모드 변경
            if state.currentInputType == .hangeul {  // 한글 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if checkDraggingDirection(DragGestureValue: DragGestureValue) == .up {
                            state.isSelectingOneHandType = true
                        }
                    }
                }
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                        if checkDraggingDirection(DragGestureValue: DragGestureValue) == .left {
                            state.isSelectingInputType = true
                        }
                    }
                }
                
            } else if state.currentInputType == .number {  // 숫자 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if checkDraggingDirection(DragGestureValue: DragGestureValue) == .up {
                            state.isSelectingOneHandType = true
                        }
                    }
                }
                if !state.isSelectingInputType && !state.isSelectingOneHandType {
                    // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                    if checkDraggingDirection(DragGestureValue: DragGestureValue) == .left {
                        state.isSelectingInputType = true
                    }
                }
                
            } else if state.currentInputType == .symbol {  // 기호 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if checkDraggingDirection(DragGestureValue: DragGestureValue) == .up {
                            state.isSelectingOneHandType = true
                        }
                    }
                }
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 오른쪽으로 드래그 -> 다른 자판으로 변경
                        if checkDraggingDirection(DragGestureValue: DragGestureValue) == .right {
                            state.isSelectingInputType = true
                        }
                    }
                }
            }
            
            if state.isSelectingOneHandType {
                selectingOneHandType(DragGestureValue: DragGestureValue)
            }
            
            if state.isSelectingInputType {
                selectingInputType(DragGestureValue: DragGestureValue)
            }
        }
    }
    
    private func onLongPressedDragging(DragGestureValue: DragGesture.Value) {
        if nowGesture != .longPressedDragging {  // 드래그 시작
            nowGesture = .longPressedDragging
        }
        
        if systemName == "return.left" {  // 리턴 버튼
            if !checkDraggingInsideButton(DragGestureValue: DragGestureValue) {
                nowGesture = .released
                state.nowPressedButton = nil
            }
        }
        
        if state.isSelectingOneHandType {
            selectingOneHandType(DragGestureValue: DragGestureValue)
        }
        
        if state.isSelectingInputType {
            selectingInputType(DragGestureValue: DragGestureValue)
        }
    }
    
    private func onReleasing() {  // 버튼 뗐을 때
        if nowGesture == .pressing {
            onRelease?()
        }
        nowGesture = .released
        state.nowPressedButton = nil
        
        if let selectedInputType = state.selectedInputType {
            state.currentInputType = selectedInputType
            state.selectedInputType = nil
        }
        state.isSelectingInputType = false
        
        if let selectedOneHandType = state.selectedOneHandType {
            state.currentOneHandType = selectedOneHandType
            currentOneHandType = selectedOneHandType.rawValue
            state.selectedOneHandType = nil
        }
        state.isSelectingOneHandType = false
    }
    
    private func onLongPressReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        if let onLongPressRelease {
            onLongPressRelease()
        } else {
            onRelease?()
        }
        state.nowPressedButton = nil
    }
    
    // MARK: - Gesture Recognization Methods
    private func gesturePressing() {
        var isOnPressingAvailable: Bool = true
        
        if state.isSelectingInputType {
            state.isSelectingInputType = false
            isOnPressingAvailable = false
        }
        if state.isSelectingOneHandType {
            state.isSelectingOneHandType = false
            isOnPressingAvailable = false
        }
        
        if state.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.nowPressedButton?.nowGesture {
            case .pressing:
                state.nowPressedButton?.onReleasing()
            case .longPressing:
                state.nowPressedButton?.onLongPressReleased()
            case .dragging:
                state.nowPressedButton?.onReleasing()
            default:
                break
            }
        }
        
        if isOnPressingAvailable {
            state.nowPressedButton = self
            onPressing()
        }
    }
    
    private func gestureLongPressing() {
        if nowGesture == .pressing {
            onLongPressing()
        }
    }
    
    private func gestureDragging(DragGestureValue: DragGesture.Value) {
        if nowGesture == .pressing || nowGesture == .dragging {
            onDragging(DragGestureValue: DragGestureValue)
        }
    }
    
    private func gestureLongPressedDragging(DragGestureValue: DragGesture.Value) {
        if nowGesture == .longPressing || nowGesture == .longPressedDragging {
            onLongPressedDragging(DragGestureValue: DragGestureValue)
        }
    }
    
    private func gestureReleasing() {
        if nowGesture == .longPressing || nowGesture == .longPressedDragging {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleasing()
        }
    }
    
    // MARK: - Gesture UI Interaction Methods
    private func checkPressing() -> Bool {
        return nowGesture == .pressing || nowGesture == .longPressing || nowGesture == .longPressedDragging ? true : false
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
            if let isMoved = state.delegate?.dragToLeft() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        } else if dragDiff > cursorMoveWidth {
            os_log("NaratgeulButton) Drag to right", log: log, type: .debug)
            dragStartWidth = DragGestureValue.translation.width
            if let isMoved = state.delegate?.dragToRight() {
                if isMoved {
                    Feedback.shared.playHapticByForce(style: .light)
                }
            }
        }
    }
    
    private func checkDraggingDirection(DragGestureValue: DragGesture.Value) -> DragDirection {
        let dragXLocation = DragGestureValue.location.x
        let dragYLocation = DragGestureValue.location.y
        
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
    
    private func selectingOneHandType(DragGestureValue: DragGesture.Value) {
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            let dragXLocation = DragGestureValue.location.x
            let dragYLocation = DragGestureValue.location.y
            
            // 특정 방향으로 일정 거리 초과 드래그 -> 한손 키보드 변경
            if state.selectedOneHandType != .left
                && dragXLocation >= state.oneHandButtonPosition[0].minX && dragXLocation < state.oneHandButtonPosition[1].minX
                && dragYLocation >= state.oneHandButtonPosition[0].minY && dragYLocation <= state.oneHandButtonPosition[0].maxY {
                state.selectedOneHandType = .left
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandType != .center
                        && dragXLocation >= state.oneHandButtonPosition[1].minX && dragXLocation <= state.oneHandButtonPosition[1].maxX
                        && dragYLocation >= state.oneHandButtonPosition[1].minY && dragYLocation <= state.oneHandButtonPosition[1].maxY {
                state.selectedOneHandType = .center
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandType != .right
                        && dragXLocation > state.oneHandButtonPosition[1].maxX && dragXLocation <= state.oneHandButtonPosition[2].maxX
                        && dragYLocation >= state.oneHandButtonPosition[2].minY && dragYLocation <= state.oneHandButtonPosition[2].maxY {
                state.selectedOneHandType = .right
                Feedback.shared.playHapticByForce(style: .light)
            } else if dragXLocation < state.oneHandButtonPosition[0].minX || dragXLocation > state.oneHandButtonPosition[2].maxX
                        || dragYLocation < state.oneHandButtonPosition[0].minY || dragYLocation > state.oneHandButtonPosition[2].maxY {
                state.selectedOneHandType = state.currentOneHandType
            }
        }
    }
    
    private func selectingInputType(DragGestureValue: DragGesture.Value) {
        let dragXLocation = DragGestureValue.location.x
        
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
                            .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == .continue || state.returnButtonType == .next {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == .go || state.returnButtonType == .send {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(checkPressing() ? Color(uiColor: UIColor.label) : Color.white)
                            .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    } else {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(checkPressing() ? Color(uiColor: UIColor.label) : Color.white)
                            .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    
                    
                } else if systemName == "space" {  // 스페이스 버튼
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
                } else if systemName == "delete.left" {  // 삭제 버튼
                    Image(systemName: checkPressing() ? "delete.left.fill" : "delete.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    
                } else {
                    Image(systemName: systemName!)  // 그 외 버튼
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton") )
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
                        .background(checkPressing() || state.isSelectingOneHandType || state.isSelectingInputType ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Image(systemName: state.isSelectingInputType ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9, weight: state.isSelectingInputType ? .bold : .regular))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 0) {
                                if isOneHandTypeEnabled {
                                    Image(systemName: state.isSelectingOneHandType ? "keyboard.fill" : "keyboard")
                                    Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                }
                            }
                            .font(.system(size: 9, weight: state.isSelectingOneHandType ? .bold : .regular))
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
                            .background(checkPressing() || state.isSelectingOneHandType || state.isSelectingInputType ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumberKeyboardTypeEnabled {
                                        Text("123")
                                        Image(systemName: state.isSelectingInputType ? "arrowtriangle.right.fill" : "arrowtriangle.right")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.isSelectingInputType ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 1))
                            })
                            .overlay(alignment: .topLeading, content: {
                                HStack(spacing: 0) {
                                    if isOneHandTypeEnabled {
                                        Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                        Image(systemName: state.isSelectingOneHandType ? "keyboard.fill" : "keyboard")
                                    }
                                }
                                .font(.system(size: 9, weight: state.isSelectingOneHandType ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                            })
                        
                    } else if state.currentInputType == .number {  // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressing() || state.isSelectingOneHandType || state.isSelectingInputType ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
                                HStack(spacing: 1) {
                                    Image(systemName: state.isSelectingInputType ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("!#1")
                                }
                                .monospaced()
                                .font(.system(size: 9, weight: state.isSelectingInputType ? .bold : .regular))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                            })
                            .overlay(alignment: .topTrailing, content: {
                                HStack(spacing: 0) {
                                    if isOneHandTypeEnabled {
                                        Image(systemName: state.isSelectingOneHandType ? "keyboard.fill" : "keyboard")
                                        Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.up.fill" : "arrowtriangle.up")
                                    }
                                }
                                .font(.system(size: 9, weight: state.isSelectingOneHandType ? .bold : .regular))
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
                        .background(checkPressing() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else if text == "@_twitter" {
                    Text("@")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else if text == "#_twitter" {
                    Text("#")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                } else {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: keyTextSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(checkPressing() ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
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
                    gesturePressing()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth)
            // 버튼 길게 눌렀을 때
                .onEnded({ _ in
                    os_log("NaratgeulButton) simultaneously_LongPressGesture() onEnded: longPressing", log: log, type: .debug)
                    gestureLongPressing()
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
                            gestureLongPressedDragging(DragGestureValue: value)
                        }
                    }
                })
                .exclusively(before: DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
                             // 버튼 드래그 할 때
                    .onChanged({ value in
                        os_log("NaratgeulButton) exclusively_DragGesture() onChanged: dragging", log: log, type: .debug)
                        gestureDragging(DragGestureValue: value)
                    })
                             // 버튼 드래그 한 뒤 뗐을 때
                    .onEnded({ _ in
                        os_log("NaratgeulButton) exclusively_DragGesture() onEnded: dragging", log: log, type: .debug)
                        gestureReleasing()
                    })
                            )
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
            // 버튼 뗐을 때
                .onEnded({ _ in
                    os_log("NaratgeulButton) DragGesture() onEnded: released", log: log, type: .debug)
                    gestureReleasing()
                })
        )
    }
}
