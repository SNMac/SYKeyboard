//
//  PreviewSYKeyboardButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct PreviewSYKeyboardButton: View {
    @State private var isPressing: Bool = false
    var text: String?
    var systemName: String?
    let primary: Bool
    
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
        .highPriorityGesture(
            withAnimation(.easeInOut(duration: 0.5)) {
                TapGesture()
                    .onEnded({ _ in
                        isPressing = true
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptics()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isPressing = false
                        }
                    })
            }
        )
        .opacity(isPressing ? 0.5 : 1.0)
    }
}
