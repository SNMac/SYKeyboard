//
//  KeyRepeatSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct KeyRepeatSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.longPressDuration, store: UserDefaultsManager.shared.storage)
    private var longPressDuration = DefaultValues.longPressDuration
    
    @AppStorage(UserDefaultsKeys.repeatRate, store: UserDefaultsManager.shared.storage)
    private var repeatRate = DefaultValues.repeatRate
    
    // MARK: - Contents
    
    var body: some View {
        NavigationStack {
            KeyboardTestView()
            List {
                Section {
                    longPressDurationSetting
                } header: {
                    Text("길게 누르기 지연 시간")
                }
                
                Section {
                    repeatRateSetting
                } header: {
                    Text("키 반복 속도")
                }
            }
            .navigationTitle("길게 누르기 입력")
            .navigationBarTitleDisplayMode(.inline)
            .requestReviewViewModifier()
        }.onDisappear {
            Analytics.logEvent("key_repeat_settings", parameters: [
                "long_press_duration": longPressDuration,
                "repeat_rate": repeatRate
            ])
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
