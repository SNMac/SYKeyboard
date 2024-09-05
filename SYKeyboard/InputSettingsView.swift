//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct InputSettingsView: View {
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = true
    @AppStorage("timerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var timerSpeed = 0.05
    
    var body: some View {
        Toggle("자동완성 및 추천", isOn: $isAutocompleteEnabled)
        Section {
            HStack {
                Text("반복 속도")
                Slider(value: $timerSpeed, in: 0.015...0.085, step: 0.005) { _ in
                    hideKeyboard()
                }
                Button {
                    timerSpeed = 0.05
                    hideKeyboard()
                } label: {
                    Text("리셋")
                }
            } header: {
                Text("반복 속도")
            }
        }
        .navigationTitle("속도 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InputSettingsView()
}
