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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var options: NaratgeulOptions
    @AppStorage("isNumberPadEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberPadEnabled = true
    @State var nowGesture: Gestures = .released
    @State private var isCursorMovable: Bool = false
    @State private var initialDragStartWidth: Double = 0.0
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
                    if (options.currentInputType == .hangeul || options.currentInputType == .number) && dragWidthDiff < -20 {
                        isCursorMovable = true
                        if options.currentInputType == .hangeul {  // 한글 자판
                            if isNumberPadEnabled {
                                options.currentInputType = .number
                                Feedback.shared.playHaptic(style: .medium)
                            }
                        } else {  // 숫자 자판
                            options.currentInputType = .symbol
                            Feedback.shared.playHaptic(style: .medium)
                        }
                    } else if options.currentInputType == .symbol && dragWidthDiff > 20 {  // 기호 자판
                        isCursorMovable = true
                        if isNumberPadEnabled {
                            options.currentInputType = .number
                            Feedback.shared.playHaptic(style: .medium)
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
                    if dragWidthDiff < -20 || dragWidthDiff > 20 {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                    }
                }
            }
            if isCursorMovable {  // 커서 이동 활성화 됐을 때
                // 일정 거리 초과 드래그 -> 커서를 한칸씩 드래그한 방향으로 이동
                let dragDiff = value.translation.width - dragStartWidth
                if dragDiff < -5 {
                    print("Drag to left")
                    dragStartWidth = value.translation.width
                    if let isMoved = options.delegate?.dragToLeft() {
                        if isMoved {
                            Feedback.shared.playHaptic(style: .light)
                        }
                    }
                } else if dragDiff > 5 {
                    print("Drag to right")
                    dragStartWidth = value.translation.width
                    if let isMoved = options.delegate?.dragToRight() {
                        if isMoved {
                            Feedback.shared.playHaptic(style: .light)
                        }
                    }
                }
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
        Button(action: {}) {
            // Image 버튼들
            if systemName != nil {
                // 리턴 버튼
                if systemName == "return.left" {
                    if options.returnButtonType == ._default {
                        Image(systemName: "return.left")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: imageSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if options.returnButtonType == ._continue || options.returnButtonType == .next {
                        Text(options.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                    } else if options.returnButtonType == .go || options.returnButtonType == .send {
                        Text(options.returnButtonType.rawValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: textSize))
                            .foregroundStyle(nowGesture == .pressing || nowGesture == .longPressing ? Color(uiColor: UIColor.label) : Color.white)
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                            .clipShape(.rect(cornerRadius: 5))
                    } else {
                        Text(options.returnButtonType.rawValue)
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
                    
                    // 그 외 버튼
                } else if systemName == "delete.left" {
                    Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? "delete.left.fill" : "delete.left")
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
                        .font(.system(size: options.needsInputModeSwitchKey ? textSize - 2 : textSize))
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
                    // 기호 자판
                    if options.currentInputType == .symbol {
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: options.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomTrailing, content: {
                                HStack(spacing: 1) {
                                    if isNumberPadEnabled {
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
                    } else if options.currentInputType == .number {
                        // 숫자 자판
                        Text("한글")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: options.needsInputModeSwitchKey ? textSize - 2 : textSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                            .clipShape(.rect(cornerRadius: 5))
                            .overlay(alignment: .bottomLeading, content: {
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
                                .padding(EdgeInsets(top: 0, leading: 2, bottom: 2, trailing: 0))
                            })
                    }
                    
                } else if text == "\(options.nowSymbolPage + 1)/\(options.totalSymbolPage)" {
                    Text("\(options.nowSymbolPage + 1)/\(options.totalSymbolPage)")
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
                .onEnded({ _ in
                    print("DragGesture() onEnded")
                    if nowGesture != .released {
                        dragOnEnded()
                    }
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: options.longPressTime)
            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                .onChanged({ _ in
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
                })
            
            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                .onEnded({ _ in
                    print("LongPressGesture() onEnded")
                    if nowGesture != .released {
                        longPressOnEnded()
                    }
                })
            
            // 버튼 길게 눌렀다가 뗐을 때 호출
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded({ _ in
                    print("LongPressGesture()->DragGesture() onEnded")
                    if nowGesture != .released {
                        seqDragOnEnded()
                    }
                })
        )
    }
}