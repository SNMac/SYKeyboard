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
        let overlayWidth: CGFloat = state.currentOneHandKeyboard == .center ? frameWidth : frameWidth * (state.oneHandKeyboardWidth / screenWidth)
        
        HStack(spacing: interItemSpacing) {
            if state.currentKeyboard == .hangeul {
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .numeric ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: state.selectedKeyboard == .hangeul ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .hangeul ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentKeyboard == .numeric {
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .symbol ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: state.selectedKeyboard == .numeric ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .numeric ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentKeyboard == .symbol {
                Image(systemName: state.selectedKeyboard == .symbol ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .symbol ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedKeyboard == .numeric ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedKeyboard == .numeric ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedKeyboard == .numeric ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
            }
        }
        .frame(width: overlayWidth, height: state.keyboardHeight / 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}


#Preview {
    KeyboardSelectOverlayView()
}
