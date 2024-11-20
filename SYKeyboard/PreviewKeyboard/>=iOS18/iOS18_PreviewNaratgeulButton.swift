//
//  iOS18_PreviewNaratgeulButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

struct iOS18_PreviewNaratgeulButton: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = GlobalValues.defaultLongPressSpeed
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = true
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    
    @State var nowGesture: Gestures = .released
    @State private var dragStartWidth: Double = 0.0
    
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
        if nowGesture != .dragging {
            // 드래그 했을 경우 onRelease 실행 X
            onRelease?()
        }
        nowGesture = .released
        state.ios18_nowPressedButton = nil
    }
    
    private func onLongPressReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        onLongPressRelease?()
        nowGesture = .released
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
        if primary {  // 글자 버튼
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            }
            
            // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동(햅틱 피드백)
            let dragDiff = value.translation.width - dragStartWidth
            if dragDiff < -cursorMoveWidth {
                print("Swift6_PreviewNaratgeulButton) Drag to left")
                dragStartWidth = value.translation.width
                Feedback.shared.playHapticByForce(style: .light)
            } else if dragDiff > cursorMoveWidth {
                print("Swift6_PreviewNaratgeulButton) Drag to right")
                dragStartWidth = value.translation.width
                Feedback.shared.playHapticByForce(style: .light)
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
        if nowGesture != .released {
            onReleased()
        }
    }
    
    private func onLongPressGesturePerform() {
        if nowGesture != .released {
            onLongPressing()
        }
    }
    
    private func onLongPressGestureOnPressingTrue() {
        if state.ios18_nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.ios18_nowPressedButton?.nowGesture {
            case .pressing:
                state.ios18_nowPressedButton?.onReleased()
            case .longPressing:
                state.ios18_nowPressedButton?.onLongPressReleased()
            case .dragging:
                state.ios18_nowPressedButton?.onReleased()
            default:
                break
            }
        }
        state.ios18_nowPressedButton = self
        onPressing()
    }
    
    private func onLongPressGestureOnPressingFalse() {
        if nowGesture == .longPressing {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleased()
        }
    }
    
    
    // MARK: - Swift6_PreviewNaratgeulButton
    var body: some View {
        let longPressTime = 1.0 - longPressSpeed
        
        let dragGesture = DragGesture(minimumDistance: cursorActiveWidth)
        // 버튼 드래그 할 때 호출
            .onChanged { value in
                print("Swift6_PreviewNaratgeulButton) DragGesture() onChanged")
                dragGestureOnChange(value: value)
            }
        
        // 드래그 뗐을 때
            .onEnded({ _ in
                print("Swift6_PreviewNaratgeulButton) DragGesture() onEnded")
                dragGestureOnEnded()
            })
        
        // Image 버튼들
        if systemName != nil {
            // 리턴 버튼
            if systemName == "return.left" {
                Image(systemName: "return.left")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
                
                // 스페이스 버튼
            } else if systemName == "space" {
                Image(systemName: "space")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
            
            // Text 버튼들
        }  else if text != nil {
            if text == "!#1" {
                // 한글 자판
                Text("!#1")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .monospaced()
                    .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
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
                    .onLongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->perform: longPressing")
                        onLongPressGesturePerform()
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: pressing")
                            onLongPressGestureOnPressingTrue()
                        } else {
                            // 버튼 뗐을 때
                            print("Swift6_PreviewNaratgeulButton) onLongPressGesture()->onPressingChanged: released")
                            onLongPressGestureOnPressingFalse()
                        }
                    }
                    .gesture(dragGesture)
            }
        }
    }
}
