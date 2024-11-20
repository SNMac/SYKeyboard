//
//  PreviewChevronButton.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/20/24.
//

import SwiftUI

struct PreviewChevronButton: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @Binding var keyboardHeight: Double
    @State var isPressing: Bool = false
    
    let isLeftHandMode: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
                .frame(maxWidth: .infinity, minHeight: keyboardHeight)
                .font(.system(size: 40))
                .foregroundStyle(isPressing ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                .background(Color("KeyboardBackground"))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            if value.location.x > geometry.frame(in: .local).minX - 40 && value.location.x < geometry.frame(in: .local).maxX + 40
                                && value.location.y > geometry.frame(in: .local).minY {
                                isPressing = true
                            } else {
                                isPressing = false
                            }
                        })
                        .onEnded({ _ in
                            if isPressing {
                                state.currentOneHandType = .center
                                isPressing = false
                            }
                        })
                )
        }
    }
}
