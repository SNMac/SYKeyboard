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
    
    @AppStorage(UserDefaultsKeys.isNaratgeulDotLabelEnabled, store: UserDefaultsManager.shared.storage)
    private var isNaratgeulDotLabelEnabled = DefaultValues.isNaratgeulDotLabelEnabled
    
    // MARK: - Content
    
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
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_numeric_keypad")
            Analytics.logEvent("numeric_keypad", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isOneHandedKeyboardEnabled, label: {
            Text("한 손 키보드 활성화")
            Text("'!#1', '한글' 또는 'ABC' 버튼을 위로 드래그하거나 길게 눌러 변경")
                .font(.caption)
        })
        .onChange(of: isOneHandedKeyboardEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_one_handed_keyboard")
            Analytics.logEvent("one_handed_keyboard", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
        
        if isOneHandedKeyboardEnabled {
            NavigationLink("한 손 키보드 너비") {
                OneHandedKeyboardWidthSettingsView()
            }
        }
        
        Toggle(isOn: $isNaratgeulDotLabelEnabled, label: {
            Text("나랏글 획·쌍 버튼 점 표기")
            Text("나랏글 키보드의 '획'을 'ㆍ', '쌍'을 'ᆢ'로 표시")
                .font(.caption)
        })
        .onChange(of: isNaratgeulDotLabelEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_naratgeul_dot_label")
            Analytics.logEvent("naratgeul_dot_label", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
    }
}

// MARK: - Content

#Preview {
    AppearanceSettingsView()
}
