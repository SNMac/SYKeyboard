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

struct SYKeyboardButton: View {
    @State private var isPressed: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var text: String?
    var systemName: String?
    let primary: Bool
    var onClick: () -> Void
    var onRelease: (() -> Void)?
    var onLongPress: (() -> Void)?
    var onLongPressFinished: (() -> Void)?
    
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
                .onChanged { value in
                    print("DragGesture) onChanged")
                    if value.translation.width > 80 {
                        print("Drag to right")
                        isPressed = false
                        // TODO: 커서 오른쪽으로 이동
                        
                    } else if value.translation.width < -80 {
                        print("Drag to left")
                        isPressed = false
                        // TODO: 커서 왼쪽으로 이동
                        
                    }
                }
                .onEnded({ value in
                    print("DragGesture) onEnded")
                    onRelease?()
                    isPressed = false
                })
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onChanged({ value in
                    print("LongPressGesture) onChanged")
                    isPressed = true
                    onClick()
                })
                .onEnded({ value in
                    print("LongPressGesture) onEnded")
                    onLongPress?()
                })
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded({ value in
                    print("LongPressGesture->DragGesture) onEnded")
                    onLongPressFinished?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isPressed = false
                    }
                })
        )
        .opacity(isPressed ? 0.5 : 1.0)
    }
}
