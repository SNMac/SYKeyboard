//
//  ChevronButton.swift
//  Naratgeul
//
//  Created by 서동환 on 11/7/24.
//

import SwiftUI

struct ChevronButton: View {
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("currentOneHandMode", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandMode = 1
    @State private var isPressed: Bool = false
    
    let isLeftHandMode: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: isLeftHandMode ? "chevron.compact.right" : "chevron.compact.left")
                .frame(maxWidth: .infinity, minHeight: state.keyboardHeight)
                .font(.system(size: 40))
                .foregroundStyle(isPressed ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
                .background(Color.white.opacity(0.001))
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
                                state.activeOneHandModeSelectOverlay = false
                                state.currentOneHandMode = .center
                                currentOneHandMode = OneHandMode.center.rawValue
                                isPressed = false
                            }
                        })
                )
        }
    }
}
