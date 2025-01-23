//
//  AppearanceSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("isNumericKeypadEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isNumericKeypadEnabled = true
    @AppStorage("isOneHandedKeyboardEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOneHandedKeyboardEnabled = true
    
    var body: some View {
        NavigationLink("키보드 높이") {
            KeyboardHeightSettingsView()
        }
        
        Toggle(isOn: $isNumericKeypadEnabled, label: {
            Text("숫자 키패드 활성화")
            Text("'!#1' 또는 '한글' 버튼을 화살표 방향으로 드래그하여 전환")
                .font(.system(.caption))
        })
        
        Toggle(isOn: $isOneHandedKeyboardEnabled, label: {
            Text("한 손 키보드 활성화")
            Text("'!#1' 또는 '한글' 버튼을 위로 드래그하거나 길게 눌러 변경")
                .font(.system(.caption))
        })
        
        if isOneHandedKeyboardEnabled {
            NavigationLink("한 손 키보드 너비") {
                OneHandedKeyboardWidthSettingsView()
            }
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
