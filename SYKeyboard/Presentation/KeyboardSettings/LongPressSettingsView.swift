//
//  LongPressSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/5/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct LongPressSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.longPressDuration, store: UserDefaultsManager.shared.storage)
    private var longPressDuration = DefaultValues.longPressDuration
    
    @AppStorage(UserDefaultsKeys.repeatRate, store: UserDefaultsManager.shared.storage)
    private var repeatRate = DefaultValues.repeatRate
    
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var longPressDurationResetCount = 0
    @State private var repeatRateResetCount = 0
    
    // MARK: - Content
    
    var body: some View {
        VStack {
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
            .requestReviewOnDetailSettingsReturn()
        }.onDisappear {
            Analytics.setUserProperty(String(format: "%.2f", longPressDuration),
                                      forName: "pref_long_press_duration")
            Analytics.logEvent("long_press_duration", parameters: [
                "view": "LongPressSettingsView",
                "value": longPressDuration,
            ])
            
            Analytics.setUserProperty(String(format: "%.3f", repeatRate),
                                      forName: "pref_repeat_rate")
            Analytics.logEvent("repeat_rate", parameters: [
                "view": "LongPressSettingsView",
                "value": repeatRate
            ])
        }
    }
}

// MARK: - UI Components

private extension LongPressSettingsView {
    var longPressDurationSetting: some View {
        HStack {
            Text("\(longPressDuration, specifier: "%.2f")")
                .frame(width: 40)
                .monospacedDigit()
            Slider(value: $longPressDuration, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }
            .id(longPressDurationResetCount)
            Button {
                longPressDuration = DefaultValues.longPressDuration
                longPressDurationResetCount += 1
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
            .id(repeatRateResetCount)
            Button {
                repeatRate = DefaultValues.repeatRate
                repeatRateResetCount += 1
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
    NavigationStack {
        LongPressSettingsView()
    }
}
