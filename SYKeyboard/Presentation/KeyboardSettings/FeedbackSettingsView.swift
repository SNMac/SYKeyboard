//
//  FeedbackSettingsView.swift
//  SYKeyboard
//
//  Created by Sunghyun Cho on 1/30/24.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - QuickSettingsView.swift
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct FeedbackSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isSoundFeedbackEnabled, store: UserDefaultsManager.shared.storage)
    private var isSoundFeedbackEnabled = DefaultValues.isSoundFeedbackEnabled
    
    @AppStorage(UserDefaultsKeys.isHapticFeedbackEnabled, store: UserDefaultsManager.shared.storage)
    private var isHapticFeedbackEnabled = DefaultValues.isHapticFeedbackEnabled
    
    // MARK: - Contents
    
    var body: some View {
        Toggle("소리 피드백", isOn: $isSoundFeedbackEnabled)
            .onChange(of: isSoundFeedbackEnabled) { newValue in
                let newValueStr = newValue ? "true" : "false"
                Analytics.setUserProperty(newValueStr,
                                          forName: "pref_sound_feedback")
                Analytics.logEvent("sound_feedback", parameters: [
                    "view": "FeedbackSettingsView",
                    "enabled": newValueStr
                ])
                hideKeyboard()
            }
        
        Toggle("햅틱 피드백", isOn: $isHapticFeedbackEnabled)
            .onChange(of: isHapticFeedbackEnabled) { newValue in
                let newValueStr = newValue ? "true" : "false"
                Analytics.setUserProperty(newValueStr,
                                          forName: "pref_haptic_feedback")
                Analytics.logEvent("haptic_feedback", parameters: [
                    "view": "FeedbackSettingsView",
                    "enabled": newValueStr
                ])
                hideKeyboard()
            }
    }
}

// MARK: - Preview

#Preview {
    FeedbackSettingsView()
}
