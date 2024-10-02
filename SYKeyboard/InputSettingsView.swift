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
    @AppStorage("isAutoChangeToHangeulEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutoChangeToHangeulEnabled = true
    
    var body: some View {
        NavigationLink("속도 설정") {
            SpeedSettingsView()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("시스템 설정의 단축키 사용")
                .font(.system(.caption))
        })
        
        Toggle(isOn: $isAutoChangeToHangeulEnabled, label: {
            Text("한글 자판 자동 변경")
            Text("기호 자판 입력 후 스페이스/리턴 → 한글 자판으로 변경")
                .font(.system(.caption))
        })
    }
}

#Preview {
    InputSettingsView()
}
