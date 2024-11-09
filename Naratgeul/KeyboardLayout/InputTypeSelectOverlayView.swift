//
//  InputTypeSelectOverlayView.swift
//  Naratgeul
//
//  Created by 서동환 on 11/9/24.
//

import SwiftUI

struct InputTypeSelectOverlayView: View {
    @EnvironmentObject var state: NaratgeulState
    
    let frameWidth: CGFloat = 140
    let interItemSpacing: CGFloat = 5
    let fontSize: Double = 16
    
    var body: some View {
        let overlayWidth = state.currentOneHandType == .center ? frameWidth : frameWidth - frameWidth / 6
        HStack(spacing: interItemSpacing) {
            if state.currentInputType == .hangeul {
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[0] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[0] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .symbol ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[1] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[1] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Image(systemName: state.selectedInputType == .hangeul ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .hangeul ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[2] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[2] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                
            } else if state.currentInputType == .number {
                Text("!#1")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .symbol ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[0] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[0] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Text("한글")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .hangeul ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[1] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[1] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Image(systemName: state.selectedInputType == .number ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[2] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[2] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                
            } else if state.currentInputType == .symbol {
                Image(systemName: state.selectedInputType == .symbol ? "x.square.fill" : "x.square")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .symbol ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .symbol ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .symbol ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[0] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[0] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Text("한글")
                    .font(.system(size: fontSize, weight: state.selectedInputType == .hangeul ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .hangeul ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .hangeul ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[1] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[1] = geometry.frame(in: .global).maxX
                                }
                        }
                    }
                
                Text("123")
                    .monospaced()
                    .font(.system(size: fontSize, weight: state.selectedInputType == .number ? .semibold : .regular))
                    .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                    .foregroundStyle(state.selectedInputType == .number ? Color.white : Color(uiColor: .label))
                    .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedInputType == .number ? Color.blue : Color.clear))
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    state.inputTypeButtonMinXPosition[2] = geometry.frame(in: .global).minX
                                    state.inputTypeButtonMaxXPosition[2] = geometry.frame(in: .global).maxX
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
