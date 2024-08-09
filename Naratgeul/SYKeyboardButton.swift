//
//  SYKeyboardButton.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 12/20/22.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - KeyboardButton.swift
//

import SwiftUI


struct SYKeyboardButton: View {
    @State private var pressed: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var text: String?
    var systemName: String?
    let primary: Bool
    var action: () -> Void
    var onLongPress: (() -> Void)?
    var onLongPressFinished: (() -> Void)?
    
    var body: some View {
        Button(action: {}) {
            if systemName != nil {
                Image(systemName: systemName!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: 24))
                    .foregroundColor(Color(uiColor: UIColor.label))
                    .background(
                        primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
                    )
                    .clipShape(.rect(cornerRadius: 5))
            } else if text != nil {
                Text(text!)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: 24))
                    .foregroundColor(Color(uiColor: UIColor.label))
                    .background(
                        primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
                    )
                    .clipShape(.rect(cornerRadius: 5))
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    Feedback.shared.playTypingSound()
                    Feedback.shared.playHaptics()
                    onLongPress?()
                }
                .onEnded { _ in
                    onLongPressFinished?()
                }
        )
        .highPriorityGesture(
            withAnimation(.easeInOut(duration: 0.5)) {
                TapGesture()
                    .onEnded { _ in
                        pressed = true
                        action()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            pressed = false
                        }
                    }
            }
        )
        .opacity(pressed ? 0.5 : 1.0)
    }
}
