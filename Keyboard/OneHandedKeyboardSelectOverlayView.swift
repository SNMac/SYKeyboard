//
//  OneHandedKeyboardSelectOverlayView.swift
//  Keyboard
//
//  Created by 서동환 on 10/30/24.
//

import SwiftUI

struct OneHandedKeyboardSelectOverlayView: View {
    @EnvironmentObject private var state: KeyboardState
    @AppStorage("currentOneHandedKeyboard", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandedKeyboard = 1
    @AppStorage("screenWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var screenWidth = 1.0
    
    private let frameWidth: CGFloat = 230
    private let interItemSpacing: CGFloat = 8
    private let fontSize: Double = 26
    
    // MARK: - Gesture Recognization Methods
    private func gestureDrag(DragGestureValue: DragGesture.Value) {
        onDrag(DragGestureValue: DragGestureValue)
    }
    
    private func gestureReleased() {
        onReleased()
    }
    
    // MARK: - Gesture Execution Methods
    private func onReleased() {
        if state.activeOneHandedKeyboardSelectOverlay {
            if let selectedOneHandedKeyboard = state.selectedOneHandedKeyboard {
                state.currentOneHandedKeyboard = selectedOneHandedKeyboard
                currentOneHandedKeyboard = selectedOneHandedKeyboard.rawValue
                state.selectedOneHandedKeyboard = nil
            }
            state.activeOneHandedKeyboardSelectOverlay = false
        }
    }
    
    private func onDrag(DragGestureValue: DragGesture.Value) {
        selectOneHandedKeyboard(DragGestureValue: DragGestureValue)
    }
    
    // MARK: - One Hand Mode Select Methods
    private func selectOneHandedKeyboard(DragGestureValue: DragGesture.Value) {
        let dragXLocation = DragGestureValue.location.x
        let dragYLocation = DragGestureValue.location.y
        
        if state.activeOneHandedKeyboardSelectOverlay {
            // 특정 방향으로 일정 거리 초과 드래그 -> 한 손 키보드 변경
            if state.selectedOneHandedKeyboard != .left
                && dragXLocation >= state.oneHandedKeyboardSelectButtonPosition[0].minX && dragXLocation < state.oneHandedKeyboardSelectButtonPosition[1].minX
                && dragYLocation >= state.oneHandedKeyboardSelectButtonPosition[0].minY && dragYLocation <= state.oneHandedKeyboardSelectButtonPosition[0].maxY {
                state.selectedOneHandedKeyboard = .left
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandedKeyboard != .center
                        && dragXLocation >= state.oneHandedKeyboardSelectButtonPosition[1].minX && dragXLocation <= state.oneHandedKeyboardSelectButtonPosition[1].maxX
                        && dragYLocation >= state.oneHandedKeyboardSelectButtonPosition[1].minY && dragYLocation <= state.oneHandedKeyboardSelectButtonPosition[1].maxY {
                state.selectedOneHandedKeyboard = .center
                Feedback.shared.playHapticByForce(style: .light)
            } else if state.selectedOneHandedKeyboard != .right
                        && dragXLocation > state.oneHandedKeyboardSelectButtonPosition[1].maxX && dragXLocation <= state.oneHandedKeyboardSelectButtonPosition[2].maxX
                        && dragYLocation >= state.oneHandedKeyboardSelectButtonPosition[2].minY && dragYLocation <= state.oneHandedKeyboardSelectButtonPosition[2].maxY {
                state.selectedOneHandedKeyboard = .right
                Feedback.shared.playHapticByForce(style: .light)
            } else if dragXLocation < state.oneHandedKeyboardSelectButtonPosition[0].minX || dragXLocation > state.oneHandedKeyboardSelectButtonPosition[2].maxX
                        || dragYLocation < state.oneHandedKeyboardSelectButtonPosition[0].minY || dragYLocation > state.oneHandedKeyboardSelectButtonPosition[2].maxY {
                state.selectedOneHandedKeyboard = state.currentOneHandedKeyboard
            }
        }
    }
    
    var body: some View {
        let overlayWidth: CGFloat = state.currentOneHandedKeyboard == .center ? frameWidth : frameWidth * (state.oneHandedKeyboardWidth / screenWidth)
        
        HStack(spacing: interItemSpacing) {
            Image(systemName: "keyboard.onehanded.left")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandedKeyboard == .left ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandedKeyboard == .left ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandedKeyboardSelectButtonPosition[0] = geometry.frame(in: .global)
                            }
                    }
                }
            
            Image(systemName: "keyboard")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandedKeyboard == .center ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandedKeyboard == .center ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandedKeyboardSelectButtonPosition[1] = geometry.frame(in: .global)
                            }
                    }
                }
            
            Image(systemName: "keyboard.onehanded.right")
                .font(.system(size: fontSize))
                .frame(width: (overlayWidth - interItemSpacing * 4) / 3, height: state.keyboardHeight / 4 - 20)
                .foregroundStyle(state.selectedOneHandedKeyboard == .right ? Color.white : Color(uiColor: .label))
                .background(RoundedRectangle(cornerRadius: 10).fill(state.selectedOneHandedKeyboard == .right ? Color.blue : Color.clear))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                state.oneHandedKeyboardSelectButtonPosition[2] = geometry.frame(in: .global)
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
    OneHandedKeyboardSelectOverlayView()
}
