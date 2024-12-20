//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct ContentView: View {
    private var defaults: UserDefaults?
    private var state: PreviewNaratgeulState
    
    init() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        GlobalValues.setupDefaults(defaults)
        
        state = PreviewNaratgeulState()
    }
    
    private var keyboardSettings: some View {
        List {
            Section {
                InitialSettingsView()
            } header: {
                Text("초기 설정")
            } footer: {
                Text("키보드 ➡️ 나랏글, 전체 접근 허용 ON")
                    .font(.system(.caption))
            }
            
            Section {
                FeedbackSettingsView()
            } header: {
                Text("피드백 설정")
            }
            
            Section {
                InputSettingsView()
            } header: {
                Text("입력 설정")
            }
            
            Section {
                AppearanceSettingsView()
            } header: {
                Text("외형 설정")
            }
            
            Section {
                InfoView()
            } header: {
                Text("정보")
            }
        }
        .scrollDismissesKeyboard(.immediately).ignoresSafeArea(.keyboard, edges: .all)
        .navigationTitle((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var body: some View {
        NavigationStack {
            KeyboardTestView()
            keyboardSettings
        }
        .environmentObject(state)
    }
}

#Preview {
    ContentView()
}
