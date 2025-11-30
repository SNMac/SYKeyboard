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
    
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var keyboardHeight = DefaultValues.keyboardHeight
    
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
    
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var needsInputModeSwitchKey = true
    
    @AppStorage("previewKeyboardLanguage") private var previewKeyboardLanguage: PreviewKeyboardLanguage = .hangeul
    
    @State private var tempKeyboardHeight: Double = DefaultValues.keyboardHeight
    
    // MARK: - Contents
    
    var body: some View {
        NavigationStack {
            keyboardHeightSettings
            
            Spacer()
            
            PreviewKeyboardView(keyboardHeight: $tempKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                displayOneHandedMode: false)
        }.onAppear {
            tempKeyboardHeight = keyboardHeight
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
                    Analytics.logEvent("update_keyboard_height", parameters: [
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

// MARK: - Preview

#Preview {
    KeyboardHeightSettingsView()
}
