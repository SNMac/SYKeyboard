//
//  SYKeyboardButton.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 12/20/22.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - KeyboardButton.swift
//

import SwiftUI
import Combine

enum Gestures {
    case released
    case pressing
    case longPressing
    case dragging
}

struct SYKeyboardButton: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = 30.0
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = 5.0
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @State var nowGesture: Gestures = .released
    @State private var dragStartWidth: Double = 0.0
    
    var text: String?
    var systemName: String?
    let primary: Bool
    
    var geometry: GeometryProxy
    
    let imageSize: CGFloat = 20
    let textSize: CGFloat = 18
    let keyTextSize: CGFloat = 22
    
    var onPress: () -> Void
    var onRelease: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressFinished: (() -> Void)?
    
    private func sequencedDragOnChanged(value: DragGesture.Value) {
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                nowGesture = .dragging
            }
            
            let dragXLocation = value.location.x
            let dragYLocation = value.location.y
            // 특정 방향으로 일정 거리 초과 드래그 -> 한손 키보드 변경
            if state.isSelectingOneHandType {
                if state.selectedOneHandType != .left && (dragXLocation > state.oneHandButtonMinXPosition[0] && dragXLocation < state.oneHandButtonMinXPosition[1]
                                                          && dragYLocation > state.oneHandButtonMinYPosition[0] && dragYLocation < state.oneHandButtonMaxYPosition[0]) {
                    state.selectedOneHandType = .left
                    Feedback.shared.playHapticByForce(style: .light)
                } else if state.selectedOneHandType != .center && (dragXLocation >= state.oneHandButtonMinXPosition[1] && dragXLocation <= state.oneHandButtonMaxXPosition[1]
                                                                   && dragYLocation >= state.oneHandButtonMinYPosition[1] && dragYLocation <= state.oneHandButtonMaxYPosition[1]) {
                    state.selectedOneHandType = .center
                    Feedback.shared.playHapticByForce(style: .light)
                } else if state.selectedOneHandType != .right && (dragXLocation > state.oneHandButtonMaxXPosition[1] && dragXLocation < state.oneHandButtonMaxXPosition[2]
                                                                  && dragYLocation > state.oneHandButtonMinYPosition[2] && dragYLocation < state.oneHandButtonMaxYPosition[2]) {
                    state.selectedOneHandType = .right
                    Feedback.shared.playHapticByForce(style: .light)
                } else if dragXLocation < state.oneHandButtonMinXPosition[0] || dragXLocation > state.oneHandButtonMaxXPosition[2]
                            || dragYLocation < state.oneHandButtonMinYPosition[0] || dragYLocation > state.oneHandButtonMaxYPosition[2] {
                    state.selectedOneHandType = state.currentOneHandType
                }
            }
        }
    }
    
    private func dragOnChanged(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        let rawInputTypeActiveDragXPos = geometry.size.width / 4
        let inputTypeActiveDragXPos_hanNum = geometry.frame(in: .global).minX + rawInputTypeActiveDragXPos * 3
        let inputTypeActiveDragXPos_sym = geometry.frame(in: .global).minX + rawInputTypeActiveDragXPos
        let oneHandActiveDragYPos = state.keyboardHeight / 4 * 3
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                nowGesture = .dragging
            }
            
            let dragXLocation = value.location.x
            let dragYLocation = value.location.y
            if state.currentInputType == .hangeul {  // 한글 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 위쪽으로 키보드 높이 1/4 초과 드래그 -> 한손 키보드 변경
                        if dragYLocation < oneHandActiveDragYPos {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        if state.isSelectingOneHandType {
                            sequencedDragOnChanged(value: value)
                        }
                    }
                }
                
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 왼쪽으로 키보드 너비 3/4 초과 드래그 -> 다른 자판으로 변경
                        if dragXLocation < inputTypeActiveDragXPos_hanNum {
                            state.isSelectingInputType = true
                        }
                    }
                    if state.isSelectingInputType {
                        if state.selectedInputType != .number && dragXLocation <= state.inputTypeButtonMinXPosition[1] {
                            state.selectedInputType = .number
                            Feedback.shared.playHapticByForce(style: .light)
                        } else if state.selectedInputType != .hangeul && dragXLocation > state.inputTypeButtonMinXPosition[1] {
                            state.selectedInputType = .hangeul
                            Feedback.shared.playHapticByForce(style: .light)
                        }
                    }
                }
                
                
            } else if state.currentInputType == .number {  // 숫자 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 위쪽으로 키보드 높이 1/4 초과 드래그 -> 한손 키보드 변경
                        if dragYLocation < oneHandActiveDragYPos {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        if state.isSelectingOneHandType {
                            sequencedDragOnChanged(value: value)
                        }
                    }
                }
                
                if !state.isSelectingInputType && !state.isSelectingOneHandType {
                    // 왼쪽으로 키보드 너비 3/4 초과 드래그 -> 다른 자판으로 변경
                    if dragXLocation < inputTypeActiveDragXPos_hanNum {
                        state.isSelectingInputType = true
                    } else if dragYLocation < oneHandActiveDragYPos {
                        state.isSelectingOneHandType = true
                    }
                }
                if state.isSelectingInputType {
                    if state.selectedInputType != .symbol && dragXLocation <= state.inputTypeButtonMinXPosition[1] {
                        state.selectedInputType = .symbol
                        Feedback.shared.playHapticByForce(style: .light)
                    } else if state.selectedInputType != .number && dragXLocation > state.inputTypeButtonMinXPosition[1] {
                        state.selectedInputType = .number
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
                
                
            } else if state.currentInputType == .symbol {  // 기호 자판
                if isOneHandTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 위쪽으로 키보드 높이 1/4 초과 드래그 -> 한손 키보드 변경
                        if dragYLocation < oneHandActiveDragYPos {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingOneHandType {
                        if state.isSelectingOneHandType {
                            sequencedDragOnChanged(value: value)
                        }
                    }
                }
                
                if isNumberKeyboardTypeEnabled {
                    if !state.isSelectingInputType && !state.isSelectingOneHandType {
                        // 오른쪽으로 키보드 너비 1/4 초과 드래그 -> 다른 자판으로 변경
                        if dragXLocation > inputTypeActiveDragXPos_sym {
                            state.isSelectingInputType = true
                        } else if dragYLocation < oneHandActiveDragYPos {
                            state.isSelectingOneHandType = true
                        }
                    }
                    if state.isSelectingInputType {
                        if state.selectedInputType != .number && dragXLocation >= state.inputTypeButtonMaxXPosition[0] {
                            state.selectedInputType = .number
                            Feedback.shared.playHapticByForce(style: .light)
                        } else if state.selectedInputType != .symbol && dragXLocation < state.inputTypeButtonMaxXPosition[0] {
                            state.selectedInputType = .symbol
                            Feedback.shared.playHapticByForce(style: .light)
                        }
                    }
                }
            }
            
            
            
        } else if primary {  // 글자 버튼
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            }
            
            // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
            let dragDiff = value.translation.width - dragStartWidth
            if dragDiff < -cursorMoveWidth {
                print("Drag to left")
                dragStartWidth = value.translation.width
                if let isMoved = state.delegate?.dragToLeft() {
                    if isMoved {
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
            } else if dragDiff > cursorMoveWidth {
                print("Drag to right")
                dragStartWidth = value.translation.width
                if let isMoved = state.delegate?.dragToRight() {
                    if isMoved {
                        Feedback.shared.playHapticByForce(style: .light)
                    }
                }
            }
        }
    }
    
    private func dragOnEnded() {  // 버튼 뗐을 때
        if nowGesture != .dragging {
            // 드래그 했을 경우 onRelease 실행 X
            onRelease?()
        }
        nowGesture = .released
        state.nowPressedButton = nil
        state.isSelectingInputType = false
        if let targetInputType = state.selectedInputType {
            state.selectedInputType = nil
            state.currentInputType = targetInputType
        }
    }
    
    private func longPressOnChanged() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressing
        onPress()
    }
    
    private func longPressOnEnded() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressing
        onLongPress?()
    }
    
    private func seqDragOnEnded() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        onLongPressFinished?()
        state.nowPressedButton = nil
    }
    
    var body: some View {
        Button(action: {}) {
            // Image 버튼들
            if systemName != nil {
                // 리턴 버튼
                if systemName == "return.left" {
                    if state.returnButtonType == ._default {
                        Image(systemName: "return.left")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: imageSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == ._continue || state.returnButtonType == .next {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if state.returnButtonType == .go || state.returnButtonType == .send {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    } else {
                        Text(state.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    
                    // 스페이스 버튼
                } else if systemName == "space" {
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                        .clipShape(.rect(cornerRadius: 5))
                    
                    // 삭제 버튼
                } else if systemName == "delete.left" {
                    Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? "delete.left.fill" : "delete.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else {
                    Image(systemName: systemName!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton") )
                        .clipShape(.rect(cornerRadius: 5))
                }
                
                // Text 버튼들
            } else if text != nil {
                if text == "!#1" {
                    // 한글 자판
                    Text("!#1")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .monospaced()
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Image(systemName: state.isSelectingInputType ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                        })
                        .overlay(alignment: .topTrailing, content: {
                            HStack(spacing: 1) {
                                if isOneHandTypeEnabled {
                                    Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.down.fill" : "arrowtriangle.down")
                                }
                            }
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 1))
                        })
                } else if text == "한글" {
                    // 기호 자판
                    if state.currentInputType == .symbol {
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumberKeyboardTypeEnabled {
                                        Text("123")
                                        Image(systemName: state.isSelectingInputType ? "arrowtriangle.right.fill" : "arrowtriangle.right")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 9))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 1))
                            })
                            .overlay(alignment: .topLeading, content: {
                                HStack(spacing: 1) {
                                    if isOneHandTypeEnabled {
                                        Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.down.fill" : "arrowtriangle.down")
                                    }
                                }
                                .font(.system(size: 9))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 1, leading: 1, bottom: 0, trailing: 0))
                            })
                    } else if state.currentInputType == .number {
                        // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
                                HStack(spacing: 1) {
                                    Image(systemName: state.isSelectingInputType ? "arrowtriangle.left.fill" : "arrowtriangle.left")
                                    Text("!#1")
                                }
                                .monospaced()
                                .font(.system(size: 9))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 1, bottom: 1, trailing: 0))
                            })
                            .overlay(alignment: .topTrailing, content: {
                                HStack(spacing: 1) {
                                    if isOneHandTypeEnabled {
                                        Image(systemName: state.isSelectingOneHandType ? "arrowtriangle.down.fill" : "arrowtriangle.down")
                                    }
                                }
                                .font(.system(size: 9))
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
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else if text == "@_twitter" {
                    Text("@")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else if text == "#_twitter" {
                    Text("#")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: keyTextSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                }
            }
        }
        .compositingGroup()
        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
        .gesture(
            DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global)
            // 버튼 드래그 할 때 호출
                .onChanged { value in
                    print("DragGesture() onChanged")
                    if nowGesture != .released {
                        dragOnChanged(value: value)
                    }
                }
            
            // 버튼 뗐을 때
                .onEnded({ _ in
                    print("DragGesture() onEnded")
                    if nowGesture != .released {
                        dragOnEnded()
                    }
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: state.longPressTime, maximumDistance: cursorActiveWidth)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged({ _ in
                    print("LongPressGesture() onChanged")
                    if state.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
                        switch state.nowPressedButton?.nowGesture {
                        case .pressing:
                            state.nowPressedButton?.dragOnEnded()
                        case .longPressing:
                            state.nowPressedButton?.seqDragOnEnded()
                        case .dragging:
                            state.nowPressedButton?.dragOnEnded()
                        default:
                            break
                        }
                    }
                    state.nowPressedButton = self
                    longPressOnChanged()
                })
            
            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                .onEnded({ _ in
                    print("LongPressGesture() onEnded")
                    if nowGesture != .released {
                        longPressOnEnded()
                    }
                })
            
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            // 버튼 길게 누르고 드래그시 호출
                .onChanged({ value in
                    print("LongPressGesture()->DragGesture() onChanged")
                    switch value {
                    case .first(_):
                        break
                    case .second(_, let dragValue):
                        if let value = dragValue {
                            sequencedDragOnChanged(value: value)
                        }
                    }
                })
            
            // 버튼 길게 눌렀다가 뗐을 때 호출
                .onEnded({ _ in
                    print("LongPressGesture()->DragGesture() onEnded")
                    if nowGesture != .released {
                        seqDragOnEnded()
                    }
                })
        )
    }
}
