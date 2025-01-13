//
//  NextKeyboardButton.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI
import UIKit

struct NextKeyboardButton: View {
    let systemName: String
    let action: Selector
    
    var body: some View {
        Button(action:{}) {
            Image(systemName: systemName)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .font(.system(size: 20))
                .foregroundColor(Color(uiColor: UIColor.label))
                .background(Color("SecondaryKeyboardButton"))
                .clipShape(.rect(cornerRadius: 5))
        }
        .shadow(color: Color("KeyboardButtonShadow"), radius: 0, x: 0, y: 1)
        .overlay {
            NextKeyboardButtonOverlay(action: action)
        }
    }
}

struct NextKeyboardButtonOverlay: UIViewRepresentable {
    let action: Selector
    
    func makeUIView(context _: Context) -> UIButton {
        let button = UIButton()
        button.addTarget(nil, action: action, for: .allTouchEvents)
        button.addAction(UIAction { _ in
            Feedback.shared.playModifierSound()
            Feedback.shared.playHaptic(style: .light)
        }, for: .touchDown)
        return button
    }
    
    func updateUIView(_: UIButton, context _: Context) {}
}
