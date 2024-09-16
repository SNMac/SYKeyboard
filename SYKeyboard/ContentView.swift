//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct ContentView: View {
    private var defaults: UserDefaults?
    private var options: PreviewSYKeyboardOptions
    
    init() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        DefaultValues().setupDefaults(defaults: defaults)
        
        options = PreviewSYKeyboardOptions()
    }
    
    private var keyboardSettings: some View {
        List {
            Section{
                FeedbackSettingsView()
            } header: {
                Text("피드백 설정")
            }
            
            Section{
                InputSettingsView()
            } header: {
                Text("입력 설정")
            }
            
            Section {
                NavigationLink("키보드 높이") {
                    HeightSettingsView()
                }
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
        .environmentObject(options)
    }
}

#Preview {
    ContentView()
}
