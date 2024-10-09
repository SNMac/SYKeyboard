//
//  PreviewNaratgeulButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import SwiftUI

enum Gestures {
    case released
    case pressing
    case longPressing
    case dragging
}

struct PreviewNaratgeulButton: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = 0.6
    @AppStorage("cursorActiveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorActiveWidth = 20.0
    @AppStorage("cursorMoveWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var cursorMoveWidth = 20.0
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @State private var nowGesture: Gestures = .released
    @State private var isCursorMovable: Bool = false
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
    var onLongPressFinished: (() -> Void)?
    
    private func dragOnChanged(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if text == "123" || text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    // 특정 방향으로 일정 거리 초과 드래그 -> 다른 자판으로 변경
                    if state.currentInputType == .hangeul {  // 한글 자판
                        if isNumberKeyboardTypeEnabled {
                            if dragWidthDiff < -30 && state.selectedInputType != .number {
                                state.isSelectingInputType = true
                                state.selectedInputType = .number
                                Feedback.shared.playHaptic(style: .medium)
                            } else if state.isSelectingInputType && state.selectedInputType != .symbol && (dragWidthDiff > -25 && dragWidthDiff < -5) {
                                state.selectedInputType = .symbol
                                Feedback.shared.playHaptic(style: .medium)
                            } else if state.isSelectingInputType && state.selectedInputType != .hangeul && dragWidthDiff > 0 {
                                state.selectedInputType = .hangeul
                                Feedback.shared.playHaptic(style: .medium)
                            }
                        } else {
                            isCursorMovable = true
                        }
                    } else if state.currentInputType == .number {  // 숫자 자판
                        if dragWidthDiff < -30 && state.selectedInputType != .symbol {
                            state.isSelectingInputType = true
                            state.selectedInputType = .symbol
                            Feedback.shared.playHaptic(style: .medium)
                        } else if state.isSelectingInputType && state.selectedInputType != .hangeul && (dragWidthDiff > -25 && dragWidthDiff < -5) {
                            state.selectedInputType = .hangeul
                            Feedback.shared.playHaptic(style: .medium)
                        } else if state.isSelectingInputType && state.selectedInputType != .number && dragWidthDiff > 0 {
                            state.selectedInputType = .number
                            Feedback.shared.playHaptic(style: .medium)
                        }
                    } else if state.currentInputType == .symbol {  // 기호 자판
                        if isNumberKeyboardTypeEnabled {
                            if dragWidthDiff > 30 && state.selectedInputType != .number {
                                state.isSelectingInputType = true
                                state.selectedInputType = .number
                                Feedback.shared.playHaptic(style: .medium)
                            } else if state.isSelectingInputType && state.selectedInputType != .hangeul && (dragWidthDiff < 25 && dragWidthDiff > 5) {
                                state.selectedInputType = .hangeul
                                Feedback.shared.playHaptic(style: .medium)
                            } else if state.selectedInputType != .symbol && dragWidthDiff < 0 {
                                state.selectedInputType = .symbol
                                Feedback.shared.playHaptic(style: .medium)
                            }
                        } else {
                            isCursorMovable = true
                        }
                    }
                }
            }
            
        } else if primary {  // 글자 버튼에서만 드래그 가능
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
                    // 일정 거리 초과/미만 드래그 -> 커서 이동 활성화
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if dragWidthDiff < -cursorActiveWidth || dragWidthDiff > cursorActiveWidth {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                    }
                }
            }
        }
        if isCursorMovable {  // 커서 이동 활성화 됐을 때
            // 일정 거리 초과/미만 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
            let dragDiff = value.translation.width - dragStartWidth
            if dragDiff < -cursorMoveWidth {
                dragStartWidth = value.translation.width
                Feedback.shared.playHaptic(style: .light)
            } else if dragDiff > cursorMoveWidth {
                dragStartWidth = value.translation.width
                Feedback.shared.playHaptic(style: .light)
            }
        }
    }
    
    private func dragOnEnded() {  // 버튼 뗐을 때
        if !isCursorMovable {
            // 드래그를 일정 거리에 못미치게 했을 경우(터치 오차) 무시하고 글자가 입력되도록 함
            onRelease?()
        }
        isCursorMovable = false
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
        onLongPressFinished?()
        nowGesture = .released
        state.nowPressedButton = nil
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
                } else {
                    Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? systemName! + ".fill" : systemName!)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
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
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberKeyboardTypeEnabled {
                                    Image(systemName: "arrowtriangle.left.fill")
                                    Text("123")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 10))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 0))
                        })
                } else if text == "한글" {
                    // 기호 자판
                    if state.currentInputType == .symbol {
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumberKeyboardTypeEnabled {
                                        Text("123")
                                        Image(systemName: "arrowtriangle.right.fill")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 10))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 2))
                            })
                    } else if state.currentInputType == .number {
                        // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
                                HStack(spacing: 1) {
                                    if isNumberKeyboardTypeEnabled {
                                        Image(systemName: "arrowtriangle.left.fill")
                                        Text("!#1")
                                    }
                                }
                                .monospaced()
                                .font(.system(size: 10))
                                .foregroundStyle(Color(uiColor: .label))
                                .backgroundStyle(Color(uiColor: .clear))
                                .padding(EdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 0))
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
            DragGesture(minimumDistance: 0)
            // 버튼 드래그 할 때 호출
                .onChanged { value in
                    print("DragGesture() onChanged")
                    if nowGesture != .released {
                        dragOnChanged(value: value)
                    }
                }
            
            // 버튼 뗐을 때
                .onEnded { _ in
                    print("DragGesture() onEnded")
                    if nowGesture != .released {
                        dragOnEnded()
                    }
                }
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: longPressTime)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged { _ in
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
                }
            
            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                .onEnded { _ in
                    print("LongPressGesture() onEnded")
                    if nowGesture != .released {
                        longPressOnEnded()
                    }
                }
            
            // 버튼 길게 눌렀다가 뗐을 때 호출
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { _ in
                    print("LongPressGesture()->DragGesture() onEnded")
                    if nowGesture != .released {
                        seqDragOnEnded()
                    }
                }
        )
    }
}
