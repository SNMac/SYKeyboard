//
//  ChevronButton.swift
//  Naratgeul
//
//  Created by 서동환 on 11/7/24.
//

import SwiftUI

struct ChevronButton: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @State var isPressing: Bool = false
    
    let isLeftHandMode: Bool
    let frameWidth: CGFloat = 80
    
    var body: some View {
        Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
            .frame(width: 80, height: state.keyboardHeight)
            .font(.system(size: 36))
            .foregroundStyle(isPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
            .background(Color.white.opacity(0.001))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        if value.location.x > 0 && value.location.x < frameWidth {
                            isPressing = true
                        } else {
                            isPressing = false
                        }
                    })
                    .onEnded({ value in
                        if value.location.x <= 0 || value.location.x >= frameWidth {
                            isPressing = false
                        } else {
                            state.currentOneHandType = .center
                            currentOneHandType = OneHandType.center.rawValue
                            isPressing = false
                        }
                    })
            )
    }
}
