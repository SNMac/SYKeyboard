//
//  AppearanceSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct AppearanceSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isNumericKeypadEnabled, store: UserDefaultsManager.shared.storage)
    private var isNumericKeypadEnabled = DefaultValues.isNumericKeypadEnabled
    
    @AppStorage(UserDefaultsKeys.isOneHandedKeyboardEnabled, store: UserDefaultsManager.shared.storage)
    private var isOneHandedKeyboardEnabled = DefaultValues.isOneHandedKeyboardEnabled
    
    // MARK: - Contents
    
    var body: some View {
        NavigationLink("키보드 높이") {
            KeyboardHeightSettingsView()
        }
        
        Toggle(isOn: $isNumericKeypadEnabled, label: {
            Text("숫자 키패드 활성화")
            Text("'!#1', '한글' 또는 'ABC' 버튼을 화살표 방향으로 드래그하여 전환")
                .font(.caption)
        })
        .onChange(of: isNumericKeypadEnabled) { newValue in
            Analytics.logEvent("appearance_settings", parameters: [
                "name": "numeric_keypad",
                "value": newValue ? "on" : "off"
            ])
            
            hideKeyboard()
        }
        
        Toggle(isOn: $isOneHandedKeyboardEnabled, label: {
            Text("한 손 키보드 활성화")
            Text("'!#1', '한글' 또는 'ABC' 버튼을 위로 드래그하거나 길게 눌러 변경")
                .font(.caption)
        })
        .onChange(of: isOneHandedKeyboardEnabled) { newValue in
            Analytics.logEvent("appearance_settings", parameters: [
                "name": "one_handed_keyboard",
                "value": newValue ? "on" : "off"
            ])
            
            hideKeyboard()
        }
        
        if isOneHandedKeyboardEnabled {
            NavigationLink("한 손 키보드 너비") {
                OneHandedKeyboardWidthSettingsView()
            }
        }
    }
}

// MARK: - Contents

#Preview {
    AppearanceSettingsView()
}
