//
//  FeedbackSettingsView.swift
//  SYKeyboard
//
//  Created by Sunghyun Cho on 1/30/24.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - QuickSettingsView.swift
//

import SwiftUI

struct FeedbackSettingsView: View {
    @AppStorage("isSoundFeedbackEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isSoundFeedbackEnabled = true
    @AppStorage("isHapticFeedbackEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isHapticFeedbackEnabled = true
    
    var body: some View {
        Toggle("소리 피드백", isOn: $isSoundFeedbackEnabled)
        
        Toggle("햅틱 피드백", isOn: $isHapticFeedbackEnabled)
    }
}

#Preview {
    FeedbackSettingsView()
}
