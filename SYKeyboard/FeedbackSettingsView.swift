//
//  FeedbackSettingsView.swift
//  SYKeyboard
//
//  Created by Sunghyun Cho on 2024-01-30.
//  Edited by 서동환 on 8/8/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - QuickSettingsView.swift
//

import SwiftUI

struct FeedbackSettingsView: View {
    @AppStorage("isSoundFeedbackEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isSoundFeedbackEnabled = true
    @AppStorage("isHapticFeedbackEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isHapticFeedbackEnabled = true
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = true
    
    var body: some View {
        VStack {
            Toggle("소리 피드백", isOn: $isSoundFeedbackEnabled)
            
            Divider()
            
            Toggle("햅틱 피드백", isOn: $isHapticFeedbackEnabled)
            
            Divider()
            
            Toggle("자동완성 및 추천", isOn: $isAutocompleteEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FeedbackSettingsView()
}