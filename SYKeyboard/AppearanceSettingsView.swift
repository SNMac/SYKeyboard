//
//  AppearanceSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("isNumberPadEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberPadEnabled = true
    
    var body: some View {
        Toggle(isOn: $isNumberPadEnabled, label: {
            Text("숫자 패드 활성화")
            if isNumberPadEnabled {
                Text("한글 - 숫자 - 기호")
                    .font(.system(.caption))
            } else {
                Text("한글 - 기호")
                    .font(.system(.caption))
            }
        }).onChange(of: isNumberPadEnabled) { _ in
            hideKeyboard()
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
