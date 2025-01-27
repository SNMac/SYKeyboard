//
//  KeyboardSelectOverlayView.swift
//  Keyboard
//
//  Created by 서동환 on 11/9/24.
//

import SwiftUI

struct KeyboardSelectOverlayView: View {
    @EnvironmentObject private var state: KeyboardState
    @AppStorage("screenWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var screenWidth = 1.0
    
    private let frameWidth: CGFloat = 180
    private let interItemSpacing: CGFloat = 8
    private let fontSize: Double = 20
    
    var body: some View {
        let overlayWidth: CGFloat = state.currentOneHandedKeyboard == .center ? frameWidth : frameWidth * (state.oneHandedKeyboardWidth / screenWidth)
        
        HStack(spacing: interItemSpacing) {
            if state.currentKeyboard == .hangeul {
                Text("123")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: "xmark.square")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentKeyboard == .numeric {
                Text("!#1")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: "xmark.square")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentKeyboard == .symbol {
                Image(systemName: "xmark.square")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Text("123")
                    .font(.system(size: fontSize))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 8).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.keyboardSelectButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
            }
        }
        .frame(width: overlayWidth, height: state.keyboardHeight / 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
