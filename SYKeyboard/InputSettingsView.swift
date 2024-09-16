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
    @AppStorage("isHoegSsangToCommaPeriodEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isHoegSsangToCommaPeriodEnabled = true
    
    var body: some View {
        NavigationLink("속도 설정") {
            SpeedSettingsView()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("iOS 시스템 설정의 단축키를 사용합니다")
                .font(.system(.caption))
        })
        
        Toggle(isOn: $isHoegSsangToCommaPeriodEnabled, label: {
            Text("획/쌍 → \",\"/\".\" 전환 허용")
            Text("획/쌍 추가를 할 수 없을 때 \",\"/\".\" 글자를 입력합니다")
                .font(.system(.caption))
        }).onChange(of: isHoegSsangToCommaPeriodEnabled) { _ in
            hideKeyboard()
        }
    }
}

#Preview {
    InputSettingsView()
}
