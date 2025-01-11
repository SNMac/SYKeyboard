//
//  PreviewChevronButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/20/24.
//

import SwiftUI

struct PreviewChevronButton: View {
    @EnvironmentObject private var state: PreviewNaratgeulState
    @State private var isPressed: Bool = false
    @Binding var keyboardHeight: Double
    
    let isLeftHandMode: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
                .frame(maxWidth: .infinity, minHeight: keyboardHeight)
                .font(.system(size: 40))
                .foregroundStyle(isPressed ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                .background(Color("KeyboardBackground"))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            if value.location.x > geometry.frame(in: .local).minX - 40 && value.location.x < geometry.frame(in: .local).maxX + 40
                                && value.location.y > geometry.frame(in: .local).minY {
                                isPressed = true
                            } else {
                                isPressed = false
                            }
                        })
                        .onEnded({ _ in
                            if isPressed {
                                state.currentOneHandMode = .center
                                isPressed = false
                            }
                        })
                )
        }
    }
}
