//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct InputSettingsView: View {
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = true
    @AppStorage("isTextReplacementEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isTextReplacementEnabled = true
    
    var body: some View {
        NavigationLink("속도 설정") {
            SpeedSettingsView()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("iOS 시스템 설정의 단축키를 사용합니다")
                .font(.system(.caption))
        })
    }
}

#Preview {
    InputSettingsView()
}
