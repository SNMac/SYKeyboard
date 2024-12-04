//
//  iOS18_NaratgeulButton.swift
//  Naratgeul
//
//  Created by 서동환 on 9/22/24.
//

import SwiftUI

struct iOS18_NaratgeulButton: View {
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
    
    
    // MARK: - Basic of Gesture Method
    private func onReleased() {  // 버튼 뗐을 때
        if nowGesture == .pressing {
            onRelease?()
        }
        nowGesture = .released
        state.ios18_nowPressedButton = nil
        
        if state.isSelectingInputType {
            if let selectedInputType = state.selectedInputType {
                state.currentInputType = selectedInputType
                state.selectedInputType = nil
            }
            state.isSelectingInputType = false
        }
        if state.isSelectingOneHandType {
            if let selectedOneHandType = state.selectedOneHandType {
                state.currentOneHandType = selectedOneHandType
                currentOneHandType = selectedOneHandType.rawValue
                state.selectedOneHandType = nil
            }
            state.isSelectingOneHandType = false
        }
    }
    
    private func onLongPressReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        onLongPressRelease?()
        state.ios18_nowPressedButton = nil
    }
    
    private func onPressing() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressing
        onPress()
    }
    
    private func onLongPressing() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressing
        onLongPress?()
    }
    
    private func onDragging(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if nowGesture != .dragging {  // 드래그 시작
            dragStartWidth = value.translation.width
            nowGesture = .dragging
        }
        
        if primary {  // 글자 버튼
            // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
            let dragDiff = value.translation.width - dragStartWidth
            if dragDiff < -cursorMoveWidth {
                print("iOS18_NaratgeulButton) Drag to left")
                dragStartWidth = value.translation.width
                if let isMoved = state.delegate?.dragToLeft() {
                    if isMoved {
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
            } else if dragDiff > cursorMoveWidth {
                print("iOS18_NaratgeulButton) Drag to right")
                dragStartWidth = value.translation.width
                if let isMoved = state.delegate?.dragToRight() {
                    if isMoved {
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
            }
            
        } else if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            let dragXLocation = value.location.x
            let dragYLocation = value.location.y
            
            if state.currentInputType == .hangeul {  // 한글 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if dragXLocation >= position.minX && dragXLocation <= position.maxX && dragYLocation < position.minY {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        sequencedDragOnChanged(value: value)
                    }
                }
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                        if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
                            state.isSelectingInputType = true
                        }
                    }
                    if state.isSelectingInputType {
                        if state.selectedInputType != .number && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                            state.selectedInputType = .number
                            Feedback.shared.playHapticByForce(style: .light)
                        } else if state.selectedInputType != .hangeul && dragXLocation > state.inputTypeButtonPosition[1].minX {
                            state.selectedInputType = .hangeul
                            Feedback.shared.playHapticByForce(style: .light)
                        }
                    }
                }
                
            } else if state.currentInputType == .number {  // 숫자 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if dragXLocation >= position.minX && dragXLocation <= position.maxX && dragYLocation < position.minY {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        sequencedDragOnChanged(value: value)
                    }
                }
                if !state.isSelectingInputType && !state.isSelectingOneHandType {
                    // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                    if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
                        state.isSelectingInputType = true
                    }
                }
                if state.isSelectingInputType {
                    if state.selectedInputType != .symbol && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                        state.selectedInputType = .symbol
                        Feedback.shared.playHapticByForce(style: .light)
                    } else if state.selectedInputType != .number && dragXLocation > state.inputTypeButtonPosition[1].minX {
                        state.selectedInputType = .number
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
                
            } else if state.currentInputType == .symbol {  // 기호 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 위쪽으로 드래그 -> 한손 키보드 변경
                        if dragXLocation >= position.minX && dragXLocation <= position.maxX && dragYLocation < position.minY {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        sequencedDragOnChanged(value: value)
                    }
                }
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 오른쪽으로 드래그 -> 다른 자판으로 변경
                        if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation > position.maxX {
                            state.isSelectingInputType = true
                        }
                    }
                    if state.isSelectingInputType {
                        if state.selectedInputType != .number && dragXLocation >= state.inputTypeButtonPosition[0].maxX {
                            state.selectedInputType = .number
                            Feedback.shared.playHapticByForce(style: .light)
                        } else if state.selectedInputType != .symbol && dragXLocation < state.inputTypeButtonPosition[0].maxX {
                            state.selectedInputType = .symbol
                            Feedback.shared.playHapticByForce(style: .light)
                        }
                    }
                }
            }
        }
    }
    
    private func onSequencedDragging(value: DragGesture.Value) {
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .sequencedDragging {  // 드래그 시작
                nowGesture = .sequencedDragging
            }
            
            let dragXLocation = value.location.x
            let dragYLocation = value.location.y
            
            if state.isSelectingOneHandType {
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
            } else {
                if state.currentInputType == .hangeul {  // 한글 자판
                    if isNumberKeyboardTypeEnabled {
                        if !state.isSelectingInputType && !state.isSelectingOneHandType {
                            // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                            if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
                                state.isSelectingInputType = true
                            }
                        }
                        if state.isSelectingInputType {
                            if state.selectedInputType != .number && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                                state.selectedInputType = .number
                                Feedback.shared.playHapticByForce(style: .light)
                            } else if state.selectedInputType != .hangeul && dragXLocation > state.inputTypeButtonPosition[1].minX {
                                state.selectedInputType = .hangeul
                                Feedback.shared.playHapticByForce(style: .light)
                            }
                        }
                    }
                    
                } else if state.currentInputType == .number {  // 숫자 자판
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 버튼 왼쪽으로 드래그 -> 다른 자판으로 변경
                        if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation < position.minX {
                            state.isSelectingInputType = true
                        }
                    }
                    if state.isSelectingInputType {
                        if state.selectedInputType != .symbol && dragXLocation <= state.inputTypeButtonPosition[1].minX {
                            state.selectedInputType = .symbol
                            Feedback.shared.playHapticByForce(style: .light)
                        } else if state.selectedInputType != .number && dragXLocation > state.inputTypeButtonPosition[1].minX {
                            state.selectedInputType = .number
                            Feedback.shared.playHapticByForce(style: .light)
                        }
                    }
                    
                } else if state.currentInputType == .symbol {  // 기호 자판
                    if isNumberKeyboardTypeEnabled {
                        if !state.isSelectingInputType && !state.isSelectingOneHandType {
                            // 버튼 오른쪽으로 드래그 -> 다른 자판으로 변경
                            if dragYLocation >= position.minY && dragYLocation <= position.maxY && dragXLocation > position.maxX {
                                state.isSelectingInputType = true
                            }
                        }
                        if state.isSelectingInputType {
                            if state.selectedInputType != .number && dragXLocation >= state.inputTypeButtonPosition[0].maxX {
                                state.selectedInputType = .number
                                Feedback.shared.playHapticByForce(style: .light)
                            } else if state.selectedInputType != .symbol && dragXLocation < state.inputTypeButtonPosition[0].maxX {
                                state.selectedInputType = .symbol
                                Feedback.shared.playHapticByForce(style: .light)
                            }
                        }
                    }
                }
            }
            
        } else if systemName == "return.left" {  // 리턴 버튼
            let dragXLocation = value.location.x
            let dragYLocation = value.location.y
            
            if dragXLocation < position.minX || dragXLocation > position.maxX
                || dragYLocation < position.minY || dragYLocation > position.maxY {
                nowGesture = .released
                state.ios18_nowPressedButton = nil
            }
        }
    }
    
    
    // MARK: - Snippet of Gesture Method
    private func dragGestureOnChange(value: DragGesture.Value) {
        if nowGesture != .released {
            onDragging(value: value)
        }
    }
    
    private func dragGestureOnEnded() {
        if nowGesture == .longPressing {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleased()
        }
    }
    
    private func onLongPressGesturePerform() {
        if nowGesture != .released {
            onLongPressing()
        }
    }
    
    private func onLongPressGestureOnPressingTrue() {
        var isOnPressingAvailable: Bool = true
        
        if state.isSelectingInputType {
            state.isSelectingInputType = false
            isOnPressingAvailable = false
        }
        if state.isSelectingOneHandType {
            state.isSelectingOneHandType = false
            isOnPressingAvailable = false
        }
        
        if state.ios18_nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.ios18_nowPressedButton?.nowGesture {
            case .pressing:
                state.ios18_nowPressedButton?.onReleased()
            case .longPressing:
                state.ios18_nowPressedButton?.onLongPressReleased()
            case .dragging:
                state.ios18_nowPressedButton?.onReleased()
            case .sequencedDragging:
                state.ios18_nowPressedButton?.onReleased()
            default:
                break
            }
        }
        
        if isOnPressingAvailable {
            state.ios18_nowPressedButton = self
            onPressing()
        }
    }
    
    private func onLongPressGestureOnPressingFalse() {
        if nowGesture == .longPressing {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleased()
        }
    }
    
    private func sequencedDragOnChanged(value: DragGesture.Value) {
        if nowGesture != .released {
            onSequencedDragging(value: value)
        }
    }
    
    
    // MARK: - iOS18_NaratgeulButton
    var body: some View {
        let dragGesture = DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
        // 버튼 드래그 할 때 호출
            .onChanged { value in
                print("iOS18_NaratgeulButton) DragGesture() onChanged")
                dragGestureOnChange(value: value)
            }
        
        // 드래그 뗐을 때
            .onEnded({ _ in
                print("iOS18_NaratgeulButton) DragGesture() onEnded")
                dragGestureOnEnded()
            })
        
        let sequencedDragGesture = LongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth)
        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
            .onEnded({ _ in
                print("iOS18_NaratgeulButton) LongPressGesture() onEnded")
                onLongPressGesturePerform()
            })
        
            .sequenced(before: DragGesture(minimumDistance: 10, coordinateSpace: .global))
        // 버튼 길게 누르고 드래그시 호출
            .onChanged({ value in
                switch value {
                case .first(_):
                    break
                case .second(_, let dragValue):
                    if let value = dragValue {
                        print("iOS18_NaratgeulButton) LongPressGesture()->DragGesture() onChanged")
                        sequencedDragOnChanged(value: value)
                    }
                }
            })
        
        // Image 버튼들
        if systemName != nil {
            if systemName == "return.left" {  // 리턴 버튼
                if state.returnButtonType == ._default {
                    Image(systemName: "return.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                    
                } else if state.returnButtonType == ._continue || state.returnButtonType == .next {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                    
                } else if state.returnButtonType == .go || state.returnButtonType == .send {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                    
                } else {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                }
                
            } else if systemName == "space" {  // 스페이스 버튼
                Image(systemName: "space")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
                
            } else if systemName == "delete.left" {
                Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? "delete.left.fill" : "delete.left")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
                
            } else {  // 그 외 버튼
                Image(systemName: systemName!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
            
            // Text 버튼들
        } else if text != nil {
            if text == "!#1" {  // 한글 자판
                Text("!#1")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .monospaced()
                    .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
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
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .highPriorityGesture(sequencedDragGesture)
                    .gesture(dragGesture)
            } else if text == "한글" {
                if state.currentInputType == .symbol {  // 기호 자판
                    Text("한글")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
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
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                } else if state.currentInputType == .number {  // 숫자 자판
                    Text("한글")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(content: {
                            Color.clear
                                .onGeometryChange(for: CGRect.self) { geometry in
                                    return geometry.frame(in: .global)
                                } action: { newValue in
                                    position = newValue
                                }
                        })
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
                        .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                            print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(sequencedDragGesture)
                        .gesture(dragGesture)
                }
                
            } else if text == "\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)" {
                Text("\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .monospaced()
                    .font(.system(size: textSize - 2))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            } else if text == ".com" {
                Text(".com")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            } else if text == "@_twitter" {
                Text("@")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            } else if text == "#_twitter" {
                Text("#")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            } else {
                Text(text!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: keyTextSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(content: {
                        Color.clear
                            .onGeometryChange(for: CGRect.self) { geometry in
                                return geometry.frame(in: .global)
                            } action: { newValue in
                                position = newValue
                            }
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("iOS18_NaratgeulButton) onLongPressGesture()->perform: longPressing released")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("iOS18_NaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
        }
    }
}
