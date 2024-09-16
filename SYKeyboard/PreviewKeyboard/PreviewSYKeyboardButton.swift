//
//  PreviewSYKeyboardButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import SwiftUI

enum GestureState {
    case pressing
    case longPressing
    case dragStart
}

struct PreviewSYKeyboardButton: View {
    @EnvironmentObject var options: PreviewSYKeyboardOptions
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = 0.6
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    @State private var curGestureState: GestureState?
    @State private var isCursorMovable: Bool = false
    @State private var dragStartWidth: Double = 0.0
    @State private var isButtonDisable: Bool = false
    
    var text: String?
    var systemName: String?
    let primary: Bool
    
    let imageSize: CGFloat = 20
    let textSize: CGFloat = 18
    let keyTextSize: CGFloat = 22
    
    var onPress: () -> Void
    var onRelease: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressFinished: (() -> Void)?
    
    private func dragOnChanged(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if primary {  // 글자 버튼에서만 드래그 가능
            if curGestureState != .dragStart {  // 드래그 시작
                dragStartWidth = value.translation.width
                curGestureState = .dragStart
            } else {  // 드래그 중
                if !isCursorMovable {
                    // 일정 거리 초과/미만 드래그 -> 커서 이동 활성화
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if dragWidthDiff < -20 || dragWidthDiff > 20 {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                    }
                }
            }
        }
        if isCursorMovable {  // 커서 이동 활성화 됐을 때
            // 일정 거리 초과/미만 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
            let dragDiff = value.translation.width - dragStartWidth
            if dragDiff < -5 {
                print("Drag to left")
                dragStartWidth = value.translation.width
                Feedback.shared.playHaptics()
                
            } else if dragDiff > 5 {
                print("Drag to right")
                dragStartWidth = value.translation.width
                Feedback.shared.playHaptics()
            }
        }
    }
    
    private func dragOnEnded() {  // 버튼 뗐을 때
        if !isCursorMovable {
            // 드래그를 일정 거리에 못미치게 했을 경우(터치 오차) 무시하고 글자가 입력되도록 함
            onRelease?()
        }
        isCursorMovable = false
        curGestureState = nil
        options.curPressedButton = nil
    }
    
    private func longPressOnChanged() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        curGestureState = .pressing
        onPress()
    }
    
    private func longPressOnEnded() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        curGestureState = .longPressing
        onLongPress?()
    }
    
    private func seqDragOnEnded() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        onLongPressFinished?()
        curGestureState = nil
        options.curPressedButton = nil
    }
    
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
                        .background(curGestureState == .pressing || curGestureState == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    // 스페이스 버튼
                } else if systemName == "space" {
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(curGestureState == .pressing || curGestureState == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else if systemName == "space_SymbolView" {
                    Image(systemName: "space")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(curGestureState == .pressing || curGestureState == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                    
                    // 그 외 버튼
                } else {
                    Image(systemName: curGestureState == .pressing || curGestureState == .longPressing ? systemName! + ".fill" : systemName!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(curGestureState == .pressing || curGestureState == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                }
                
                // Text 버튼들
            } else if text != nil {
                if text == "123" || text == "#+=" || text == "한글" {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                } else {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: keyTextSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(curGestureState == .pressing || curGestureState == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
            // 버튼 뗐을 때
                .onEnded({ _ in
                    print("DragGesture() onEnded")
                    if curGestureState != nil {
                        dragOnEnded()
                    }
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: longPressTime)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged({ _ in
                    print("LongPressGesture() onChanged")
                    if options.curPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
                        switch options.curPressedButton?.curGestureState {
                        case .pressing:
                            options.curPressedButton?.dragOnEnded()
                        case .longPressing:
                            options.curPressedButton?.seqDragOnEnded()
                        case .dragStart:
                            options.curPressedButton?.dragOnEnded()
                        default:
                            break
                        }
                    }
                    options.curPressedButton = self
                    longPressOnChanged()
                })
            
            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                .onEnded({ _ in
                    print("LongPressGesture() onEnded")
                    if curGestureState != nil {
                        longPressOnEnded()
                    }
                })
            
            // 버튼 길게 눌렀다가 뗐을 때 호출
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded({ _ in
                    print("LongPressGesture()->DragGesture() onEnded")
                    if curGestureState != nil {
                        seqDragOnEnded()
                    }
                })
        )
    }
}
