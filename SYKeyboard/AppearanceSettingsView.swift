//
//  AppearanceSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    
    var body: some View {
        NavigationLink("키보드 높이") {
            KeyboardHeightSettingsView()
        }
        
        Toggle(isOn: $isNumberKeyboardTypeEnabled, label: {
            Text("숫자 자판 활성화")
            Text("자판 변경 버튼을 화살표 방향으로 드래그하여 전환")
                .font(.system(.caption))
        })
        
        Toggle(isOn: $isOneHandTypeEnabled, label: {
            Text("한손 키보드 활성화")
            Text("자판 변경 버튼을 위로 드래그하여 선택")
                .font(.system(.caption))
        })
        
        if isOneHandTypeEnabled {
            NavigationLink("한손 키보드 너비") {
                OneHandWidthSettingsView()
            }
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
