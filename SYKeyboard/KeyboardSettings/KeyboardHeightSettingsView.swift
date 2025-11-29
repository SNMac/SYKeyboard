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
    
    @State private var tempKeyboardHeight: Double = DefaultValues.keyboardHeight
    
    private var keyboardHeightSettings: some View {
        VStack {
            Text("\(Int(tempKeyboardHeight) - (Int(DefaultValues.keyboardHeight) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempKeyboardHeight, in: 190...290, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
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
                        "value": tempKeyboardHeight
                    ])
                    
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Contents
    
    var body: some View {
        NavigationStack {
            keyboardHeightSettings
            
            PreviewKeyboardView(keyboardHeight: $tempKeyboardHeight, oneHandedKeyboardWidth: $oneHandedKeyboardWidth)
                .background(.keyboardBackground)
                .frame(height: tempKeyboardHeight)
                .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
        }
        .onAppear {
            tempKeyboardHeight = keyboardHeight
        }
        .requestReviewViewModifier()
    }
}

// MARK: - Preview

#Preview {
    KeyboardHeightSettingsView()
}
