//
//  KeyRepeatSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

import SYKeyboardCore

struct KeyRepeatSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.longPressDuration, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var longPressDuration = DefaultValues.longPressDuration
    
    @AppStorage(UserDefaultsKeys.repeatRate, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var repeatRate = DefaultValues.repeatRate
    
    // MARK: - Contents
    
    var body: some View {
        NavigationStack {
            KeyboardTestView()
            List {
                Section {
                    longPressDurationSetting
                } header: {
                    Text("반복 지연 시간")
                }
                
                Section {
                    repeatRateSetting
                } header: {
                    Text("키 반복 속도")
                }
            }
            .navigationTitle("반복 입력")
            .navigationBarTitleDisplayMode(.inline)
            .requestReviewViewModifier()
        }
    }
}

// MARK: - UI Components

private extension KeyRepeatSettingsView {
    var longPressDurationSetting: some View {
        HStack {
            Text("\(longPressDuration, specifier: "%.2f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $longPressDuration, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }
            Button {
                longPressDuration = DefaultValues.longPressDuration
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    var repeatRateSetting: some View {
        HStack {
            Text("\(repeatRate * 100, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $repeatRate, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            Button {
                repeatRate = DefaultValues.repeatRate
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    KeyRepeatSettingsView()
}
