//
//  NaratgeulOneHandSelectView.swift
//  Naratgeul
//
//  Created by 서동환 on 10/30/24.
//

import SwiftUI

struct OneHandSelectOverlayView: View {
    @EnvironmentObject var state: NaratgeulState
    
    let frameWidth: CGFloat = 240
    let interItemSpacing: CGFloat = 10
    let fontSize: Double = 28
    
    var body: some View {
        HStack(spacing: interItemSpacing) {
            Image(systemName: "keyboard.onehanded.left")
                .font(.system(size: fontSize))
                .frame(width: (frameWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .left ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .left ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonMinXPosition[0] = geometry.frame(in: .global).minX
                                state.oneHandButtonMaxXPosition[0] = geometry.frame(in: .global).maxX
                                state.oneHandButtonMinYPosition[0] = geometry.frame(in: .global).minY
                                state.oneHandButtonMaxYPosition[0] = geometry.frame(in: .global).maxY
                            }
                    }
                }
            
            Image(systemName: "keyboard")
                .font(.system(size: fontSize))
                .frame(width: (frameWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .center ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .center ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonMinXPosition[1] = geometry.frame(in: .global).minX
                                state.oneHandButtonMaxXPosition[1] = geometry.frame(in: .global).maxX
                                state.oneHandButtonMinYPosition[1] = geometry.frame(in: .global).minY
                                state.oneHandButtonMaxYPosition[1] = geometry.frame(in: .global).maxY
                            }
                    }
                }
            
            Image(systemName: "keyboard.onehanded.right")
                .font(.system(size: fontSize))
                .frame(width: (frameWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .right ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .right ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonMinXPosition[2] = geometry.frame(in: .global).minX
                                state.oneHandButtonMaxXPosition[2] = geometry.frame(in: .global).maxX
                                state.oneHandButtonMinYPosition[2] = geometry.frame(in: .global).minY
                                state.oneHandButtonMaxYPosition[2] = geometry.frame(in: .global).maxY
                            }
                    }
                }
            
        }
        .frame(width: frameWidth, height: state.keyboardHeight / 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    OneHandSelectOverlayView()
}
