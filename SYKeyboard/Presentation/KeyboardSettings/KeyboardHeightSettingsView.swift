//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct KeyboardHeightSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaultsManager.shared.storage)
    private var keyboardHeight = DefaultValues.keyboardHeight
    
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaultsManager.shared.storage)
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
    
    @AppStorage(UserDefaultsKeys.isPredictiveTextEnabled, store: UserDefaultsManager.shared.storage)
    private var isPredictiveTextEnabled = DefaultValues.isPredictiveTextEnabled
    
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaultsManager.shared.storage)
    private var needsInputModeSwitchKey = true
    
    @AppStorage("previewKeyboardLanguage") private var previewKeyboardLanguage: PreviewKeyboardLanguage = .hangeul
    
    @State private var previewOneHandedMode: OneHandedMode = .center
    @State private var tempKeyboardHeight: Double = DefaultValues.keyboardHeight
    @State private var previewKeyboardHeight: Double = DefaultValues.keyboardHeight
    
    // MARK: - Content
    
    var body: some View {
        NavigationStack {
            keyboardHeightSettings
            
            Spacer()
            
            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempKeyboardHeight = keyboardHeight
            updatePreviewKeyboardHeight()
        }.onChange(of: tempKeyboardHeight) { _ in
            updatePreviewKeyboardHeight()
        }.requestReviewViewModifier()
    }
}

// MARK: - UI Components

private extension KeyboardHeightSettingsView {
    var keyboardHeightSettings: some View {
        VStack {
            Text("\(Int(tempKeyboardHeight) - (Int(DefaultValues.keyboardHeight) - 100))")
                .padding(.top)
                .padding(.horizontal)
            Slider(value: $tempKeyboardHeight, in: 190...290, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Text("가로 모드에선 iOS 기본 키보드와 동일한 높이로 표시됩니다.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("키보드 높이")
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
                    tempKeyboardHeight = DefaultValues.keyboardHeight
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    keyboardHeight = tempKeyboardHeight
                    Analytics.setUserProperty(String(format: "%.1f", keyboardHeight),
                                              forName: "pref_keyboard_height")
                    Analytics.logEvent("keyboard_height", parameters: [
                        "view": "KeyboardHeightSettingsView",
                        "value": keyboardHeight
                    ])
                    
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension KeyboardHeightSettingsView {
    func updatePreviewKeyboardHeight() {
        let suggestionBarHeight = isPredictiveTextEnabled
        ? KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing + KeyboardLayoutFigure.keyboardFrameSpacing
        : 0
        previewKeyboardHeight = tempKeyboardHeight + suggestionBarHeight
    }
}

// MARK: - Preview

#Preview {
    KeyboardHeightSettingsView()
}
