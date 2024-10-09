//
//  PreviewInputTypeSelectView.swift
//  SYKeyboard
//
//  Created by 서동환 on 10/10/24.
//

import SwiftUI

struct PreviewInputTypeSelectView: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    
    let activeFontSize: Double = 28
    let otherFontSize: Double = 12
    
    var body: some View {
        HStack(spacing: 1) {
            if state.currentInputType == .hangeul {
                if state.selectedInputType == .number {
                    Group {
                        Image(systemName: "arrowtriangle.left.fill")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    
                    Group {
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                } else if state.selectedInputType == .symbol {
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right.fill")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                } else if state.selectedInputType == .hangeul {
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Image(systemName: "x.square.fill")
                        .font(.system(size: activeFontSize, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                }
                
                
            } else if state.currentInputType == .number {
                if state.selectedInputType == .symbol {
                    Group {
                        Image(systemName: "arrowtriangle.left.fill")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    
                    Group {
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                    
                } else if state.selectedInputType == .hangeul {
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right.fill")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                } else if state.selectedInputType == .number {
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
                        Text("!#1")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Image(systemName: "x.square.fill")
                        .font(.system(size: activeFontSize, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 2))
                }
                
                
            } else if state.currentInputType == .symbol {
                if state.selectedInputType == .number {
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 4))
                    
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right.fill")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                } else if state.selectedInputType == .hangeul {
                    Image(systemName: "x.square")
                        .font(.system(size: otherFontSize))
                        .foregroundStyle(.secondary)
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 4))
                    
                    Group {
                        Image(systemName: "arrowtriangle.left.fill")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: activeFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    
                    Group {
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                } else if state.selectedInputType == .symbol {
                    Image(systemName: "x.square.fill")
                        .font(.system(size: activeFontSize, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 4))
                    
                    Group {
                        Image(systemName: "arrowtriangle.left")
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Text("한글")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)

                    Group {
                        Text("123")
                            .monospaced()
                            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                        Image(systemName: "arrowtriangle.right")
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 2))
                    }
                    .font(.system(size: otherFontSize))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 160, height: 80)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: (needsInputModeSwitchKey ? 0 : 40), trailing: 0))
    }
}

#Preview {
    PreviewInputTypeSelectView()
}
