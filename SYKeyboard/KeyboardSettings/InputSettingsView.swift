//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

struct InputSettingsView: View {
    @AppStorage(UserDefaultsKeys.isTextReplacementEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var isTextReplacementEnabled = DefaultValues.isTextReplacementEnabled
    @AppStorage(UserDefaultsKeys.isAutoChangeToPrimaryEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var isAutoChangeToPrimaryEnabled = DefaultValues.isAutoChangeToPrimaryEnabled
    
    var body: some View {
        NavigationLink("반복 입력") {
            KeyRepeatSettingsView()
        }
        
        NavigationLink("커서 이동") {
            CursorMovementSettingsView()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("시스템 설정의 텍스트 대치 단축키 사용")
                .font(.system(.caption))
        })
        
        Toggle(isOn: $isAutoChangeToPrimaryEnabled, label: {
            Text("한글 키보드 자동 변경")
            Text("기호 키보드 입력 후 스페이스/리턴 ➡️ 한글 키보드")
                .font(.system(.caption))
        })
    }
}

#Preview {
    InputSettingsView()
}
