//
//  SYKeyboardButton_Swift_6.swift
//  Naratgeul
//
//  Created by 서동환 on 9/22/24.
//

import SwiftUI

struct Swift6_SYKeyboardButton: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var options: SYKeyboardOptions
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
    
    // MARK: - Basic of Gesture Method
    private func onDragging(value: DragGesture.Value) {  // 버튼 드래그 할 때 호출
        if text == "123" || text == "!#1" || text == "한글" {  // 자판 전환 버튼
            if nowGesture != .dragging {  // 드래그 시작
                dragStartWidth = value.translation.width
                nowGesture = .dragging
            } else {  // 드래그 중
                if !isCursorMovable {
                    // 왼쪽으로 일정 거리 초과 드래그 -> 이전 자판으로 변경
                    let dragWidthDiff = value.translation.width - dragStartWidth
                    if dragWidthDiff < -20 {
                        isCursorMovable = true
                        dragStartWidth = value.translation.width
                        options.current = options.current.previous()
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
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        }
                    }
                } else if dragDiff > 5 {
                    print("Drag to right")
                    dragStartWidth = value.translation.width
                    if let isMoved = options.delegate?.dragToRight() {
                        if isMoved {
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
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
        options.curPressedButton = nil
    }
    
    private func onPressing() {  // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
        nowGesture = .pressing
        onPress()
    }
    
    private func onLongPressing() {  // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
        nowGesture = .longPressing
        onLongPress?()
    }
    
    private func seqDragOnEnded() {  // 버튼 길게 눌렀다가 뗐을 때 호출
        onLongPressFinished?()
        nowGesture = .released
        options.curPressedButton = nil
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
        if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
            switch options.curPressedButton_Swift_6?.nowGesture {
            case .pressing:
                options.curPressedButton_Swift_6?.onReleased()
            case .longPressing:
                options.curPressedButton_Swift_6?.seqDragOnEnded()
            case .dragging:
                options.curPressedButton_Swift_6?.onReleased()
            default:
                break
            }
        }
        options.curPressedButton_Swift_6 = self
        onPressing()
    }
    
    private func onLongPressGestureOnPressingFalse() {
        if nowGesture != .released {
            onReleased()
        }
    }
    
    // MARK: - SYKeyboardButton
    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 20)
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
                if options.returnButtonLabel == ._default {
                    Image(systemName: "return.left")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: imageSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .simultaneousGesture(dragGesture)
                        .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
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
                    
                } else if options.returnButtonLabel == ._continue || options.returnButtonLabel == .next {
                    Text(options.returnButtonLabel.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                        .clipShape(.rect(cornerRadius: 5))
                        .simultaneousGesture(dragGesture)
                        .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            if nowGesture != .released {
                                onLongPressing()
                            }
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                    switch options.curPressedButton_Swift_6?.nowGesture {
                                    case .pressing:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    case .longPressing:
                                        options.curPressedButton_Swift_6?.seqDragOnEnded()
                                    case .dragging:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    default:
                                        break
                                    }
                                }
                                options.curPressedButton_Swift_6 = self
                                onPressing()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                if nowGesture != .released {
                                    onReleased()
                                }
                            }
                        }
                    
                } else if options.returnButtonLabel == .go || options.returnButtonLabel == .send {
                    Text(options.returnButtonLabel.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .simultaneousGesture(dragGesture)
                        .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            if nowGesture != .released {
                                onLongPressing()
                            }
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                    switch options.curPressedButton_Swift_6?.nowGesture {
                                    case .pressing:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    case .longPressing:
                                        options.curPressedButton_Swift_6?.seqDragOnEnded()
                                    case .dragging:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    default:
                                        break
                                    }
                                }
                                options.curPressedButton_Swift_6 = self
                                onPressing()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                if nowGesture != .released {
                                    onReleased()
                                }
                            }
                        }
                    
                } else {
                    Text(options.returnButtonLabel.rawValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: textSize))
                        .foregroundStyle(Color(uiColor: UIColor.label))
                        .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color(.tintColor))
                        .clipShape(.rect(cornerRadius: 5))
                        .simultaneousGesture(dragGesture)
                        .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                            // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                            print("onLongPressGesture()->perform: longPressing")
                            if nowGesture != .released {
                                onLongPressing()
                            }
                        } onPressingChanged: { isPressing in
                            if isPressing {
                                // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                                print("onLongPressGesture()->onPressingChanged: pressing")
                                if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                    switch options.curPressedButton_Swift_6?.nowGesture {
                                    case .pressing:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    case .longPressing:
                                        options.curPressedButton_Swift_6?.seqDragOnEnded()
                                    case .dragging:
                                        options.curPressedButton_Swift_6?.onReleased()
                                    default:
                                        break
                                    }
                                }
                                options.curPressedButton_Swift_6 = self
                                onPressing()
                            } else {
                                // 버튼 뗐을 때
                                print("onLongPressGesture()->onPressingChanged: released")
                                if nowGesture != .released {
                                    onReleased()
                                }
                            }
                        }
                }
                
                // 스페이스 버튼
            } else if systemName == "space" {
                Image(systemName: "space")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton") )
                    .clipShape(.rect(cornerRadius: 5))
                    .simultaneousGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        if nowGesture != .released {
                            onLongPressing()
                        }
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                switch options.curPressedButton_Swift_6?.nowGesture {
                                case .pressing:
                                    options.curPressedButton_Swift_6?.onReleased()
                                case .longPressing:
                                    options.curPressedButton_Swift_6?.seqDragOnEnded()
                                case .dragging:
                                    options.curPressedButton_Swift_6?.onReleased()
                                default:
                                    break
                                }
                            }
                            options.curPressedButton_Swift_6 = self
                            onPressing()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            if nowGesture != .released {
                                onReleased()
                            }
                        }
                    }
                
                // 그 외 버튼
            } else if systemName == "delete.left" {
                Image(systemName: nowGesture == .pressing || nowGesture == .longPressing ? "delete.left.fill" : "delete.left")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: imageSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .simultaneousGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        if nowGesture != .released {
                            onLongPressing()
                        }
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                switch options.curPressedButton_Swift_6?.nowGesture {
                                case .pressing:
                                    options.curPressedButton_Swift_6?.onReleased()
                                case .longPressing:
                                    options.curPressedButton_Swift_6?.seqDragOnEnded()
                                case .dragging:
                                    options.curPressedButton_Swift_6?.onReleased()
                                default:
                                    break
                                }
                            }
                            options.curPressedButton_Swift_6 = self
                            onPressing()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            if nowGesture != .released {
                                onReleased()
                            }
                        }
                    }
            }
            
            // Text 버튼들
        } else if text != nil {
            if text == "123" || text == "!#1" || text == "한글" {
                Text(text!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: options.needsInputModeSwitchKey ? textSize - 2 : textSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .simultaneousGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        if nowGesture != .released {
                            onLongPressing()
                        }
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                switch options.curPressedButton_Swift_6?.nowGesture {
                                case .pressing:
                                    options.curPressedButton_Swift_6?.onReleased()
                                case .longPressing:
                                    options.curPressedButton_Swift_6?.seqDragOnEnded()
                                case .dragging:
                                    options.curPressedButton_Swift_6?.onReleased()
                                default:
                                    break
                                }
                            }
                            options.curPressedButton_Swift_6 = self
                            onPressing()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            if nowGesture != .released {
                                onReleased()
                            }
                        }
                    }
                
            } else if text == "\(options.curSymbolPage + 1)/\(options.totalSymbolPage)" {
                Text("\(options.curSymbolPage + 1)/\(options.totalSymbolPage)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: textSize - 2))
                    .monospaced()
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .simultaneousGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        if nowGesture != .released {
                            onLongPressing()
                        }
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                switch options.curPressedButton_Swift_6?.nowGesture {
                                case .pressing:
                                    options.curPressedButton_Swift_6?.onReleased()
                                case .longPressing:
                                    options.curPressedButton_Swift_6?.seqDragOnEnded()
                                case .dragging:
                                    options.curPressedButton_Swift_6?.onReleased()
                                default:
                                    break
                                }
                            }
                            options.curPressedButton_Swift_6 = self
                            onPressing()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            if nowGesture != .released {
                                onReleased()
                            }
                        }
                    }
            } else {
                Text(text!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: keyTextSize))
                    .foregroundStyle(Color(uiColor: UIColor.label))
                    .background(nowGesture == .pressing || nowGesture == .longPressing ? Color("SecondaryKeyboardButton") : Color("PrimaryKeyboardButton"))
                    .clipShape(.rect(cornerRadius: 5))
                    .simultaneousGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: options.longPressTime, maximumDistance: 20) {
                        // 버튼 길게 누르면(누른 상태에서 일정시간이 지나면) 호출
                        print("onLongPressGesture()->perform: longPressing")
                        if nowGesture != .released {
                            onLongPressing()
                        }
                    } onPressingChanged: { isPressing in
                        if isPressing {
                            // 버튼 눌렀을 때 호출(버튼 누르면 무조건 첫번째로 호출)
                            print("onLongPressGesture()->onPressingChanged: pressing")
                            if options.curPressedButton_Swift_6 != nil {  // 이미 다른 버튼이 눌려있는 상태
                                switch options.curPressedButton_Swift_6?.nowGesture {
                                case .pressing:
                                    options.curPressedButton_Swift_6?.onReleased()
                                case .longPressing:
                                    options.curPressedButton_Swift_6?.seqDragOnEnded()
                                case .dragging:
                                    options.curPressedButton_Swift_6?.onReleased()
                                default:
                                    break
                                }
                            }
                            options.curPressedButton_Swift_6 = self
                            onPressing()
                        } else {
                            // 버튼 뗐을 때
                            print("onLongPressGesture()->onPressingChanged: released")
                            if nowGesture != .released {
                                onReleased()
                            }
                        }
                    }
            }
        }
    }
}
