//
//  Swift6_NaratgeulButton.swift
//  Naratgeul
//
//  Created by 서동환 on 9/22/24.
//

import SwiftUI

struct Swift6_NaratgeulButton: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = 20.0
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = 5.0
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @State var nowGesture: Gestures = .released
    @State private var isCursorMovable: Bool = false
    @State private var dragStartWidth: Double = 0.0
    
    @GestureState var isLongPressed = false
    
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
    
    // MARK: - Basic of Gesture Method
    private func onSequenceDragging(value: DragGesture.Value) {
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
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
        }
    }
    
    private func onDragging(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        let rawActiveDragWidth = geometry.size.width / 4
        let hanNumActiveDragWidth = geometry.frame(in: .global).minX + rawActiveDragWidth * 3
        let symActiveDragWidth = geometry.frame(in: .global).minX + rawActiveDragWidth
        if text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
                    let dragXLocation = value.location.x
                    if state.currentInputType == .hangeul {  // 한글 자판
                        if isNumberKeyboardTypeEnabled {
                            // 왼쪽으로 키보드 너비 3/4 초과 드래그 -> 다른 자판으로 변경
                            if !state.isSelectingInputType && dragXLocation < hanNumActiveDragWidth {
                                state.isSelectingInputType = true
                            }
                            if state.isSelectingInputType {
                                if state.selectedInputType != .number && dragXLocation < state.inputTypeButtonMinXPosition[1] {
                                    state.selectedInputType = .number
                                    Feedback.shared.playHapticByForce(style: .light)
                                } else if state.selectedInputType != .hangeul && dragXLocation >= state.inputTypeButtonMinXPosition[1] {
                                    state.selectedInputType = .hangeul
                                    Feedback.shared.playHapticByForce(style: .light)
                                }
                            }
                        } else {
                            isCursorMovable = true
                        }
                        
                        
                    } else if state.currentInputType == .number {  // 숫자 자판
                        // 왼쪽으로 키보드 너비 3/4 초과 드래그 -> 다른 자판으로 변경
                        if !state.isSelectingInputType && dragXLocation < hanNumActiveDragWidth {
                            state.isSelectingInputType = true
                        }
                        if state.isSelectingInputType {
                            if state.selectedInputType != .symbol && dragXLocation < state.inputTypeButtonMinXPosition[0] {
                                state.selectedInputType = .symbol
                                Feedback.shared.playHapticByForce(style: .light)
                            } else if state.selectedInputType != .number && dragXLocation >= state.inputTypeButtonMinXPosition[1] {
                                state.selectedInputType = .number
                                Feedback.shared.playHapticByForce(style: .light)
                            }
                        }
                        
                        
                    } else if state.currentInputType == .symbol {  // 기호 자판
                        if isNumberKeyboardTypeEnabled {
                            // 오른쪽으로 키보드 너비 1/4 초과 드래그 -> 다른 자판으로 변경
                            if !state.isSelectingInputType && dragXLocation > symActiveDragWidth {
                                state.isSelectingInputType = true
                            }
                            if state.isSelectingInputType {
                                if state.selectedInputType != .number && dragXLocation > state.inputTypeButtonMaxXPosition[0] {
                                    state.selectedInputType = .number
                                    Feedback.shared.playHapticByForce(style: .light)
                                } else if state.selectedInputType != .symbol && dragXLocation <= state.inputTypeButtonMaxXPosition[0] {
                                    state.selectedInputType = .symbol
                                    Feedback.shared.playHapticByForce(style: .light)
                                }
                            }
                        } else {
                            isCursorMovable = true
                        }
                    }
                }
            }
            
        } else if primary {  // 글자 버튼
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
                    // 일정 거리 초과 드래그 -> 커서 이동 활성화
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if dragWidthDiff < -cursorActiveWidth || dragWidthDiff > cursorActiveWidth {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                    }
                }
            }
            if isCursorMovable {  // 커서 이동 활성화 됐을 때
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
    }
    
    private func onReleased() {  // 버튼 뗐을 때
        if !isCursorMovable {
            // 드래그를 일정 거리에 못미치게 했을 경우(터치 오차) 무시하고 글자가 입력되도록 함
            onRelease?()
        }
        isCursorMovable = false
        nowGesture = .released
        state.swift6_nowPressedButton = nil
        state.isSelectingInputType = false
        if let targetInputType = state.selectedInputType {
            state.selectedInputType = nil
            state.currentInputType = targetInputType
        }
    }
    
    private func onPressing() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressing
        onPress()
    }
    
    private func onLongPressing() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressing
        onLongPress?()
    }
    
    private func onLongPressReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        onLongPressFinished?()
        state.swift6_nowPressedButton = nil
    }
    
    // MARK: - Snippet of Gesture Method
    private func sequencedDragOnChanged(value: DragGesture.Value) {
        if nowGesture != .released {
            onSequenceDragging(value: value)
        }
    }
    
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
        if state.swift6_nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.swift6_nowPressedButton?.nowGesture {
            case .pressing:
                state.swift6_nowPressedButton?.onReleased()
            case .longPressing:
                state.swift6_nowPressedButton?.onLongPressReleased()
            case .dragging:
                state.swift6_nowPressedButton?.onReleased()
            default:
                break
            }
        }
        state.swift6_nowPressedButton = self
        onPressing()
    }
    
    private func onLongPressGestureOnPressingFalse() {
        if nowGesture == .longPressing || nowGesture == .dragging {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleased()
        }
    }
    
    // MARK: - Swift6_NaratgeulButton
    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 0, coordinateSpace: .global)
        // 버튼 드래그 할 때 호출
            .onChanged { value in
                print("DragGesture() onChanged")
                dragGestureOnChange(value: value)
            }
        
        // 드래그 뗐을 때
            .onEnded({ _ in
                print("DragGesture() onEnded")
                dragGestureOnEnded()
            })
        
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
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            onLongPressGesturePerform()
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .gesture(dragGesture)
                    
                } else if state.returnButtonType == ._continue || state.returnButtonType == .next {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            onLongPressGesturePerform()
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .gesture(dragGesture)
                    
                } else if state.returnButtonType == .go || state.returnButtonType == .send {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            onLongPressGesturePerform()
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .gesture(dragGesture)
                    
                } else {
                    Text(state.returnButtonType.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            onLongPressGesturePerform()
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .gesture(dragGesture)
                }
                
                // 스페이스 버튼
            } else if systemName == "space" {
                Image(systemName: "space")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
                
                // 그 외 버튼
            } else if systemName == "delete.left" {
                Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? "delete.left.fill" : "delete.left")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            } else {
                Image(systemName: systemName!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
            
            // Text 버튼들
        } else if text != nil {
            // 한글 자판
            if text == "!#1" {
                Text("!#1")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .monospaced()
                    .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .overlay(alignment: .bottomLeading, content: {
                        HStack(spacing: 1) {
                            if isNumberKeyboardTypeEnabled {
                                Image(systemName: "arrowtriangle.left.fill")
                                Text("123")
                            }
                        }
                        .monospaced()
                        .font(.system(size: 9))
                        .foregroundStyle(Color(uiColor: .label))
                        .backgroundStyle(Color(uiColor: .clear))
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 0))
                    })
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        print("onLongPressGesture()->perform: longPressing")
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .highPriorityGesture(
                        LongPressGesture(minimumDuration: state.longPressTime)
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            .onEnded({ _ in
                                print("LongPressGesture() onEnded")
                                onLongPressGesturePerform()
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
                    )
                    .gesture(dragGesture)
            } else if text == "한글" {
                if state.currentInputType == .symbol {
                    // 기호 자판
                    Text("한글")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(alignment: .bottomTrailing, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Text("123")
                                    Image(systemName: "arrowtriangle.right.fill")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 2))
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            print("onLongPressGesture()->perform: longPressing")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: state.longPressTime)
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                                .onEnded({ _ in
                                    print("LongPressGesture() onEnded")
                                    onLongPressGesturePerform()
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
                        )
                        .gesture(dragGesture)
                } else if state.currentInputType == .number {
                    // 숫자 자판
                    Text("한글")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: state.needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                Image(systemName: "arrowtriangle.left.fill")
                                Text("!#1")
                            }
                            .monospaced()
                            .font(.system(size: 9))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 0))
                        })
                        .onLongPressGesture(minimumDuration: state.longPressTime) {
                            print("onLongPressGesture()->perform: longPressing")
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                onLongPressGestureOnPressingTrue()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                onLongPressGestureOnPressingFalse()
                            }
                        }
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: state.longPressTime)
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                                .onEnded({ _ in
                                    print("LongPressGesture() onEnded")
                                    onLongPressGesturePerform()
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
                        )
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
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: state.longPressTime) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
        }
    }
}
