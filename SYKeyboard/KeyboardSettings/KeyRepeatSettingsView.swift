//
//  KeyRepeatSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

struct KeyRepeatSettingsView: View {
    @AppStorage("longPressDuration", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) private var longPressDuration = UserDefaultsManager.defaultLongPressDuration
    @AppStorage("repeatRate", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) private var repeatRate = UserDefaultsManager.defaultRepeatRate
    
    private var longPressDurationSetting: some View {
        HStack {
            Text("\(longPressDuration, specifier: "%.2f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $longPressDuration, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }
            Button {
                longPressDuration = UserDefaultsManager.defaultLongPressDuration
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    private var repeatRateSetting: some View {
        HStack {
            Text("\(repeatRate * 100, specifier: "%.1f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $repeatRate, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            Button {
                repeatRate = UserDefaultsManager.defaultRepeatRate
                hideKeyboard()
            } label: {
                Text("리셋")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
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

#Preview {
    KeyRepeatSettingsView()
}
