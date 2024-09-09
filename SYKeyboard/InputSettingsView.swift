//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct InputSettingsView: View {
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = true
    @AppStorage("isTextReplacementsEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isTextReplacementsEnabled = true
    
    var body: some View {
        NavigationLink("속도 설정") {
            SpeedSettingsView()
        }
        
        Toggle(isOn: $isTextReplacementsEnabled, label: {
            Text("텍스트 대치")
            Text("iOS 시스템 설정의 단축키를 사용합니다")
                .font(.system(.caption))
        })
        
//        Toggle("자동 완성 및 추천", isOn: $isAutocompleteEnabled)
    }
}

#Preview {
    InputSettingsView()
}
