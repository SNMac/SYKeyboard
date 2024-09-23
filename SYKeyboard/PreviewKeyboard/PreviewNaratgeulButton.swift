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
    @EnvironmentObject var options: PreviewNaratgeulOptions
    @AppStorage("longPressSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var longPressSpeed = 0.6
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    @AppStorage("isNumberPadEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberPadEnabled = true
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
                    // 왼쪽으로 일정 거리 초과 드래그 -> 이전 자판으로 변경
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if (options.current == .hangeul || options.current == .number) && dragWidthDiff < -20 {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                        if options.current == .hangeul {  // 한글 자판
                            if isNumberPadEnabled {  // 숫자 자판
                                options.current = .number
                            } else {  // 한글 자판
                                options.current = .symbol
                            }
                        } else {  // 숫자 자판
                            options.current = .symbol
                        }
                        Feedback.shared.playHaptic(style: .medium)
                    } else if options.current == .symbol && dragWidthDiff > 20 {  // 기호 자판
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                        options.current = .hangeul
                        Feedback.shared.playHaptic(style: .medium)
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
                dragStartWidth = value.translation.width
                Feedback.shared.playHaptic(style: .light)
            } else if dragDiff > 5 {
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
        options.nowPressedButton = nil
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
        options.nowPressedButton = nil
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
                if text == "123" {
                    Text("123")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .monospaced()
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomTrailing, content: {
                            HStack(spacing: 1) {
                                Text("한글")
                                Image(systemName: "arrowtriangle.right.fill")
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 2))
                        })
                } else if text == "!#1" {
                    Text("!#1")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .monospaced()
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: .bottomLeading, content: {
                            HStack(spacing: 1) {
                                if isNumberPadEnabled {
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
                    Text("한글")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: needsInputModeSwitchKey ? textSize - 2 : textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .overlay(alignment: isNumberPadEnabled ? .bottomLeading : .bottomTrailing, content: {
                            HStack(spacing: 1) {
                                if isNumberPadEnabled {
                                    Image(systemName: "arrowtriangle.left.fill")
                                    Text("!#1")
                                }
                            }
                            .monospaced()
                            .font(.system(size: 10))
                            .foregroundStyle(Color(uiColor: .label))
                            .backgroundStyle(Color(uiColor: .clear))
                            .padding(EdgeInsets(top: 0, leading: isNumberPadEnabled ? 2 : 0, bottom: 2, trailing: isNumberPadEnabled ? 0 : 2))
                        })
                } else if text == "\(options.nowSymbolPage + 1)/\(options.totalSymbolPage)" {
                    Text("\(options.nowSymbolPage + 1)/\(options.totalSymbolPage)")
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
                    if options.nowPressedButton != nil {  // 이미 다른 버튼이 눌려있는 상태
                        switch options.nowPressedButton?.nowGesture {
                        case .pressing:
                            options.nowPressedButton?.dragOnEnded()
                        case .longPressing:
                            options.nowPressedButton?.seqDragOnEnded()
                        case .dragging:
                            options.nowPressedButton?.dragOnEnded()
                        default:
                            break
                        }
                    }
                    options.nowPressedButton = self
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
