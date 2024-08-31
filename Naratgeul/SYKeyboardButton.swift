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

enum GestureState {
    case pressing
    case longPressing
    case dragStart
}

struct SYKeyboardButton: View {
    @EnvironmentObject var options: SYKeyboardOptions
    @State private var curGestureState: GestureState?
    @State private var isCursorMovable: Bool = false
    @State private var dragStartWidth: Double = 0.0
    @Environment(\.colorScheme) var colorScheme
    
    var text: String?
    var systemName: String?
    let primary: Bool
    
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
                    // 일정 거리 이상 드래그 -> 커서 이동 활성화
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if dragWidthDiff < -30 || dragWidthDiff > 30 {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                    }
                }
            }
        }
        if isCursorMovable {  // 커서 이동 활성화 됐을 때
            // 일정 거리 드래그 할때마다 한칸씩 커서를 드래그한 방향으로 이동
            let dragWidthDiff = value.translation.width - dragStartWidth
            if dragWidthDiff < -10 {
                print("Drag to left")
                dragStartWidth = value.translation.width
                if let isMoved = options.delegate?.dragToLeft() {
                    if isMoved {
                        Feedback.shared.playHaptics()
                    }
                }
            } else if dragWidthDiff > 10 {
                print("Drag to right")
                dragStartWidth = value.translation.width
                if let isMoved = options.delegate?.dragToRight() {
                    if isMoved {
                        Feedback.shared.playHaptics()
                    }
                }
            }
        }
    }
    
    private func dragOnEnded() {  // 버튼 뗐을 때
        if !isCursorMovable {
            // 드래그가 일정 거리 이하일 경우 무시하고 글자가 입력되도록 함
            onRelease?()
        }
        curGestureState = nil
        options.curPressedButton = nil
    }
    
    private func longPressOnChanged() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        curGestureState = .pressing
        onPress()
    }
    
    private func longPressOnEnded() {  // 버튼을 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        curGestureState = .longPressing
        onLongPress?()
    }
    
    private func seqDragOnEnded() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        onLongPressFinished?()
        curGestureState = nil
        options.curPressedButton = nil
    }
    
    var body: some View {
        Button(action: {}) {
            if systemName != nil {
                Image(systemName: systemName!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: 20))
                    .foregroundColor(Color(uiColor: UIColor.label))
                    .background(
                        primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
                    )
                    .clipShape(.rect(cornerRadius: 5))
            } else if text != nil {
                if text == "123" || text == "#+=" || text == "한글" {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: 18))
                        .foregroundColor(Color(uiColor: UIColor.label))
                        .background(
                            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
                        )
                        .clipShape(.rect(cornerRadius: 5))
                } else {
                    Text(text!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: 22))
                        .foregroundColor(Color(uiColor: UIColor.label))
                        .background(
                            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
                        )
                        .clipShape(.rect(cornerRadius: 5))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
            // 버튼 드래그 할 때 호출
                .onChanged { value in
                    print("DragGesture() onChanged")
                    if curGestureState != nil {
                        dragOnChanged(value: value)
                    }
                }
            
            // 버튼 뗐을 때
                .onEnded({ _ in
                    print("DragGesture() onEnded")
                    if curGestureState != nil {
                        dragOnEnded()
                    }
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.4)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged({ _ in
                    print("LongPressGesture() onChanged")
//                    longPressOnChanged()
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
            
            // 버튼을 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
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
        .opacity(curGestureState == .pressing || curGestureState == .longPressing ? 0.5 : 1.0)
    }
}
