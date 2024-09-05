//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct InputSettingsView: View {
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = true
    
    
    var body: some View {
        Toggle("자동 완성 및 추천", isOn: $isAutocompleteEnabled)
        
        NavigationLink("속도 설정") {
            SpeedSettingsView()
        }
    }
}

#Preview {
    InputSettingsView()
}
