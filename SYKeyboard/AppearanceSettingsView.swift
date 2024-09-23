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
            Text("숫자 자판 활성화")
            Text("자판 변경 버튼을 화살표 방향으로 드래그하여 전환")
                .font(.system(.caption))
        }).onChange(of: isNumberPadEnabled) { _ in
            hideKeyboard()
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
