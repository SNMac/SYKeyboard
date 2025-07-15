//
//  OneHandedKeyboardWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/17/24.
//

import SwiftUI

struct OneHandedKeyboardWidthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var state: PreviewKeyboardState
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var keyboardHeight = DefaultValues.keyboardHeight
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)) private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    @State private var tempOneHandedKeyboardWidth: Double = DefaultValues.oneHandedKeyboardWidth
    
    private let fontSize: CGFloat = 40
    
    private var oneHandedKeyboardWidthSettings: some View {
        VStack {
            Text("\(Int(tempOneHandedKeyboardWidth) - (Int(DefaultValues.oneHandedKeyboardWidth) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempOneHandedKeyboardWidth, in: 300...340, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    state.currentOneHandedKeyboard = .left
                } label: {
                    Image(systemName: "keyboard.onehanded.left")
                        .font(.system(size: fontSize))
                }.buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    state.currentOneHandedKeyboard = .right
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
                    tempOneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    oneHandedKeyboardWidth = tempOneHandedKeyboardWidth
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            oneHandedKeyboardWidthSettings
            
            HStack(spacing: 0) {
                if state.currentOneHandedKeyboard == .right {
                    PreviewChevronButton(keyboardHeight: $keyboardHeight, isLeftHandMode: false)
                }
                
                PreviewHangeulView(keyboardHeight: $keyboardHeight, oneHandedKeyboardWidth: $tempOneHandedKeyboardWidth)
                if state.currentOneHandedKeyboard == .left {
                    PreviewChevronButton(keyboardHeight: $keyboardHeight, isLeftHandMode: true)
                }
            }.frame(height: needsInputModeSwitchKey ? keyboardHeight : keyboardHeight + 40)
        }
        .onAppear {
            tempOneHandedKeyboardWidth = oneHandedKeyboardWidth
            state.currentOneHandedKeyboard = .right
        }
        .requestReviewViewModifier()
    }
}

#Preview {
    OneHandedKeyboardWidthSettingsView()
        .environmentObject(PreviewKeyboardState())
}
