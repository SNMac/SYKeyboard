//
//  OneHandKeyboardWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/17/24.
//

import SwiftUI

struct OneHandKeyboardWidthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var state: PreviewKeyboardState
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var keyboardHeight = GlobalValues.defaultKeyboardHeight
    @AppStorage("oneHandKeyboardWidth", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var oneHandKeyboardWidth = GlobalValues.defaultOneHandKeyboardWidth
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var needsInputModeSwitchKey = true
    @State private var tempOneHandKeyboardWidth: Double = GlobalValues.defaultOneHandKeyboardWidth
    
    private let fontSize: CGFloat = 40
    
    private var oneHandKeyboardWidthSettings: some View {
        VStack {
            Text("\(Int(tempOneHandKeyboardWidth) - (Int(GlobalValues.defaultOneHandKeyboardWidth) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempOneHandKeyboardWidth, in: 300...340, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    state.currentOneHandKeyboard = .left
                } label: {
                    Image(systemName: "keyboard.onehanded.left")
                        .font(.system(size: fontSize))
                }.buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    state.currentOneHandKeyboard = .right
                } label: {
                    Image(systemName: "keyboard.onehanded.right")
                        .font(.system(size: fontSize))
                }.buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .navigationTitle("한 손 키보드 너비")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempOneHandKeyboardWidth = GlobalValues.defaultOneHandKeyboardWidth
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    oneHandKeyboardWidth = tempOneHandKeyboardWidth
                    dismiss()
                } label: {
                    Text("저장")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            oneHandKeyboardWidthSettings
            
            HStack(spacing: 0) {
                if state.currentOneHandKeyboard == .right {
                    PreviewChevronButton(keyboardHeight: $keyboardHeight, isLeftHandMode: false)
                }
                
                PreviewHangeulView(keyboardHeight: $keyboardHeight, oneHandKeyboardWidth: $tempOneHandKeyboardWidth)
                if state.currentOneHandKeyboard == .left {
                    PreviewChevronButton(keyboardHeight: $keyboardHeight, isLeftHandMode: true)
                }
            }.frame(height: needsInputModeSwitchKey ? keyboardHeight : keyboardHeight + 40)
        }
        .onAppear {
            tempOneHandKeyboardWidth = oneHandKeyboardWidth
            state.currentOneHandKeyboard = .right
        }
        .requestReviewViewModifier()
    }
}

#Preview {
    OneHandKeyboardWidthSettingsView()
        .environmentObject(PreviewKeyboardState())
}
