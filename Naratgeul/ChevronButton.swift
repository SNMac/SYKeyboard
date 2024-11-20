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
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
                .frame(maxWidth: .infinity, minHeight: state.keyboardHeight)
                .font(.system(size: 40))
                .foregroundStyle(isPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                .background(Color.white.opacity(0.001))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            if value.location.x > geometry.frame(in: .local).minX - 40 && value.location.x < geometry.frame(in: .local).maxX + 40 {
                                isPressing = true
                            } else {
                                isPressing = false
                            }
                        })
                        .onEnded({ value in
                            if value.location.x <= geometry.frame(in: .local).minX - 40 || value.location.x >= geometry.frame(in: .local).maxX + 40 {
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
}
