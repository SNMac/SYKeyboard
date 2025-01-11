//
//  NaratgeulOneHandSelectView.swift
//  Naratgeul
//
//  Created by 서동환 on 10/30/24.
//

import SwiftUI

struct OneHandSelectOverlayView: View {
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @AppStorage("screenWidth", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var screenWidth = 1.0
    
    private let frameWidth: CGFloat = 230
    private let interItemSpacing: CGFloat = 8
    private let fontSize: Double = 26
    
    // MARK: - Gesture Execution Methods
    private func onReleased() {
        if state.isSelectingOneHandType {
            if let selectedOneHandType = state.selectedOneHandType {
                state.currentOneHandType = selectedOneHandType
                currentOneHandType = selectedOneHandType.rawValue
                state.selectedOneHandType = nil
            }
            state.isSelectingOneHandType = false
        }
    }
    
    private func onDrag(DragGestureValue: DragGesture.Value) {
        selectOneHandType(DragGestureValue: DragGestureValue)
    }
    
    // MARK: - Gesture Recognization Methods
    private func gestureDrag(DragGestureValue: DragGesture.Value) {
        onDrag(DragGestureValue: DragGestureValue)
    }
    
    private func gestureReleased() {
        onReleased()
    }
    
    // MARK: - Gesture UI Interaction Methods
    private func selectOneHandType(DragGestureValue: DragGesture.Value) {
        let dragXLocation = DragGestureValue.location.x
        let dragYLocation = DragGestureValue.location.y
        
        if state.isSelectingOneHandType {
            // 특정 방향으로 일정 거리 초과 드래그 -> 한손 키보드 변경
            if state.selectedOneHandType != .left
                && dragXLocation >= state.oneHandButtonPosition[0].minX && dragXLocation < state.oneHandButtonPosition[1].minX
                && dragYLocation >= state.oneHandButtonPosition[0].minY && dragYLocation <= state.oneHandButtonPosition[0].maxY {
                state.selectedOneHandType = .left
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandType != .center
                        && dragXLocation >= state.oneHandButtonPosition[1].minX && dragXLocation <= state.oneHandButtonPosition[1].maxX
                        && dragYLocation >= state.oneHandButtonPosition[1].minY && dragYLocation <= state.oneHandButtonPosition[1].maxY {
                state.selectedOneHandType = .center
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandType != .right
                        && dragXLocation > state.oneHandButtonPosition[1].maxX && dragXLocation <= state.oneHandButtonPosition[2].maxX
                        && dragYLocation >= state.oneHandButtonPosition[2].minY && dragYLocation <= state.oneHandButtonPosition[2].maxY {
                state.selectedOneHandType = .right
                Feedback.shared.playHapticByForce(style: .light)
            } else if dragXLocation < state.oneHandButtonPosition[0].minX || dragXLocation > state.oneHandButtonPosition[2].maxX
                        || dragYLocation < state.oneHandButtonPosition[0].minY || dragYLocation > state.oneHandButtonPosition[2].maxY {
                state.selectedOneHandType = state.currentOneHandType
            }
        }
    }
    
    var body: some View {
        let overlayWidth: CGFloat = state.currentOneHandType == .center ? frameWidth : frameWidth * (state.oneHandWidth / screenWidth)
        HStack(spacing: interItemSpacing) {
            Image(systemName: "keyboard.onehanded.left")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .left ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .left ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonPosition[0] = geometry.frame(in: .global)
                            }
                    }
                }
            
            Image(systemName: "keyboard")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .center ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .center ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonPosition[1] = geometry.frame(in: .global)
                            }
                    }
                }
            
            Image(systemName: "keyboard.onehanded.right")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandType == .right ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandType == .right ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandButtonPosition[2] = geometry.frame(in: .global)
                            }
                    }
                }
        }
        .frame(width: overlayWidth, height: state.keyboardHeight / 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged({ value in
                    gestureDrag(DragGestureValue: value)
                })
                .onEnded({ _ in
                    gestureReleased()
                })
        )
    }
}

#Preview {
    OneHandSelectOverlayView()
}
