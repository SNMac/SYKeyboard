//
//  OneHandedKeyboardWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/17/24.
//

import SwiftUI

import SYKeyboardCore

struct OneHandedKeyboardWidthSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var keyboardHeight = DefaultValues.keyboardHeight
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    @State private var tempOneHandedKeyboardWidth: Double = DefaultValues.oneHandedKeyboardWidth
    
    private let fontSize: CGFloat = 40
    
    // MARK: - Contents
    
    var body: some View {
        NavigationStack {
            oneHandedKeyboardWidthSettings
        }
        .requestReviewViewModifier()
    }
}

// MARK: - UI Components

private extension OneHandedKeyboardWidthSettingsView {
    var oneHandedKeyboardWidthSettings: some View {
        VStack {
            Text("\(Int(tempOneHandedKeyboardWidth) - (Int(DefaultValues.oneHandedKeyboardWidth) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempOneHandedKeyboardWidth, in: 300...340, step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            Spacer()
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
}

// MARK: - Preview

#Preview {
    OneHandedKeyboardWidthSettingsView()
}
