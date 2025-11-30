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

struct FeedbackSettingsView: View {
    
    // MARK: - Properteis
    
    @AppStorage(UserDefaultsKeys.isSoundFeedbackEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isSoundFeedbackEnabled = DefaultValues.isSoundFeedbackEnabled
    
    @AppStorage(UserDefaultsKeys.isHapticFeedbackEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isHapticFeedbackEnabled = DefaultValues.isHapticFeedbackEnabled
    
    // MARK: - Contents
    
    var body: some View {
        Toggle("소리 피드백", isOn: $isSoundFeedbackEnabled)
        
        Toggle("햅틱 피드백", isOn: $isHapticFeedbackEnabled)
    }
}

// MARK: - Preview

#Preview {
    FeedbackSettingsView()
}
