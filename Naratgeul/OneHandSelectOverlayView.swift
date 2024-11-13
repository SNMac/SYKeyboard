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
    
    
    // MARK: - Basic of Gesture Method
    private func onReleased() {
        if state.isSelectingOneHandType {
            if let selectedOneHandType = state.selectedOneHandType {
                state.selectedOneHandType = nil
                state.currentOneHandType = selectedOneHandType
            }
            state.isSelectingOneHandType = false
        }
    }
    
    private func onDragging(value: DragGesture.Value) {
        let dragXLocation = value.location.x
        let dragYLocation = value.location.y
        
        if state.isSelectingOneHandType {
            // 특정 방향으로 일정 거리 초과 드래그 -> 한손 키보드 변경
            if dragYLocation >= 0 && dragYLocation <= state.keyboardHeight / 4 {
                if state.selectedOneHandType != .left && (dragXLocation > 0 && dragXLocation < frameWidth / 3) {
                    state.selectedOneHandType = .left
                    Feedback.shared.playHapticByForce(style: .light)
                } else if state.selectedOneHandType != .center && (dragXLocation >= frameWidth / 3 && dragXLocation <= frameWidth / 3 * 2) {
                    state.selectedOneHandType = .center
                    Feedback.shared.playHapticByForce(style: .light)
                } else if state.selectedOneHandType != .right && (dragXLocation > frameWidth / 3 * 2 && dragXLocation < frameWidth) {
                    state.selectedOneHandType = .right
                    Feedback.shared.playHapticByForce(style: .light)
                } else if dragXLocation <= 0 || dragXLocation >= frameWidth {
                    state.selectedOneHandType = state.currentOneHandType
                }
            } else {
                state.selectedOneHandType = state.currentOneHandType
            }
        }
    }
    
    
    // MARK: - Snippet of Gesture Method
    private func dragGestureOnChange(value: DragGesture.Value) {
        onDragging(value: value)
    }
    
    private func dragGestureOnEnded() {
        onReleased()
    }
    
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
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    print("OneHandSelectOverlayView) DragGesture() onChanged")
                    dragGestureOnChange(value: value)
                })
                .onEnded({ _ in
                    print("OneHandSelectOverlayView) DragGesture() onEnded")
                    dragGestureOnEnded()
                })
        )
    }
}

#Preview {
    OneHandSelectOverlayView()
}
