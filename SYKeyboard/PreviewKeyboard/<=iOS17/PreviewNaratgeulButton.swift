//
//  PreviewNaratgeulButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import SwiftUI
import OSLog

enum Gestures {
    case released
    case pressing
    case longPressing
    case dragging
}

struct PreviewNaratgeulButton: View {
    let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "Preview")
    
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = GlobalValues.defaultLongPressSpeed
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = GlobalValues.defaultCursorActiveWidth
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = GlobalValues.defaultCursorMoveWidth
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = true
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    
    @State private var nowGesture: Gestures = .released
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
        state.nowPressedButton = nil
    }
    
    private func onLongPressReleased() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        nowGesture = .released
        onLongPressRelease?()
        state.nowPressedButton = nil
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
                os_log("PreviewNaratgeulButton) Drag to left", log: log, type: .debug)
                dragStartWidth = value.translation.width
                Feedback.shared.playHapticByForce(style: .light)
            } else if dragDiff > cursorMoveWidth {
                os_log("PreviewNaratgeulButton) Drag to right", log: log, type: .debug)
                dragStartWidth = value.translation.width
                Feedback.shared.playHapticByForce(style: .light)
            }
        }
    }
    
    
    // MARK: - Snippet of Gesture Method
    private func sequencedDragOnEnded() {
        if nowGesture == .longPressing {
            onLongPressReleased()
        } else if nowGesture != .released {
            onReleased()
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
    
    private func longPressGestureOnChanged() {
        if state.ios18_nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch state.nowPressedButton?.nowGesture {
            case .pressing:
                state.nowPressedButton?.onReleased()
            case .longPressing:
                state.nowPressedButton?.onLongPressReleased()
            case .dragging:
                state.nowPressedButton?.onReleased()
            default:
                break
            }
        }
        state.nowPressedButton = self
        onPressing()
    }
    
    private func longPressGestureOnEnded() {
        if nowGesture != .released {
            onLongPressing()
        }
    }
    
    
    // MARK: - PreviewNaratgeulButton
    var body: some View {
        let longPressTime = 1.0 - longPressSpeed
        
        Button(action: {}) {
            if systemName != nil {
                // 리턴 버튼
                if systemName == "return.left" {
                    Image(systemName: "return.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    // 스페이스 버튼
                } else if systemName == "space" {
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    // 그 외 버튼
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
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
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
                    os_log("PreviewNaratgeulButton) DragGesture() onChanged: dragging", log: log, type: .debug)
                    dragGestureOnChange(value: value)
                }
            
            // 버튼 뗐을 때
                .onEnded({ _ in
                    os_log("PreviewNaratgeulButton) DragGesture() onEnded: dragging", log: log, type: .debug)
                    dragGestureOnEnded()
                })
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded({ _ in
                    os_log("PreviewNaratgeulButton) DragGesture() onChanged: released", log: log, type: .debug)
                    dragGestureOnEnded()
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: longPressTime, maximumDistance: cursorActiveWidth)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged({ _ in
                    os_log("PreviewNaratgeulButton) LongPressGesture() onChanged: pressing", log: log, type: .debug)
                    longPressGestureOnChanged()
                })
            
            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                .onEnded({ _ in
                    os_log("PreviewNaratgeulButton) LongPressGesture() onEnded: longPressing", log: log, type: .debug)
                    longPressGestureOnEnded()
                })
            
                .sequenced(before: DragGesture(minimumDistance: cursorActiveWidth, coordinateSpace: .global))
            // 버튼 길게 누르고 드래그시 호출
                .onChanged({ value in
                    switch value {
                    case .first(_):
                        break
                    case .second(_, let dragValue):
                        if let _ = dragValue {
                            os_log("PreviewNaratgeulButton) LongPressGesture()->DragGesture() onChanged: sequencedDragging", log: log, type: .debug)
                        }
                    }
                })
            
            // 버튼 길게 눌렀다가 뗐을 때 호출
                .onEnded({ _ in
                    os_log("PreviewNaratgeulButton) LongPressGesture()->DragGesture() onEnded: sequencedDragging released", log: log, type: .debug)
                    sequencedDragOnEnded()
                })
        )
    }
}
