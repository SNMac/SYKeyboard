//
//  InputTypeSelectOverlayView.swift
//  Naratgeul
//
//  Created by 서동환 on 11/9/24.
//

import SwiftUI

struct InputTypeSelectOverlayView: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("screenWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var screenWidth = 1.0
    
    let frameWidth: CGFloat = 180
    let interItemSpacing: CGFloat = 8
    let fontSize: Double = 20
    
    var body: some View {
        let overlayWidth: CGFloat = state.currentOneHandType == .center ? frameWidth : frameWidth * (state.oneHandWidth / screenWidth)
        HStack(spacing: interItemSpacing) {
            if state.currentInputType == .hangeul {
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: state.selectedInputType == .hangeul ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .hangeul ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentInputType == .number {
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .symbol ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[0] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                Image(systemName: state.selectedInputType == .number ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonPosition[1] = geometry.frame(in: .global)
                                }
                        }
                    }
                
                
            } else if state.currentInputType == .symbol {
                Image(systemName: state.selectedInputType == .symbol ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .symbol ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
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
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .bold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 3) / 2, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
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
    InputTypeSelectOverlayView()
}
