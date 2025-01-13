//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    private var defaults: UserDefaults?
    private var state: PreviewNaratgeulState
    @State private var isKeyboardExtensionEnabled: Bool = false
    
    private func checkKeyboardExtensionEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("isKeyboardExtensionEnabled(): Cannot retrieve bundle identifier.")
        }
        
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            // There is no key `AppleKeyboards` in NSUserDefaults. That happens sometimes.
            return false
        }
        
        let keyboardExtensionBundleIdentifierPrefix = appBundleIdentifier + "."
        for keyboard in keyboards {
            if keyboard.hasPrefix(keyboardExtensionBundleIdentifierPrefix) {
                return true
            }
        }
        
        return false
    }
    
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
                Text("키보드 ➡️ 나랏글, 전체 접근 허용 활성화")
                    .font(.system(.caption))
            }
            
            if isKeyboardExtensionEnabled {
                // TODO: 키보드 설정에 추가됐는지 확인하는 기능 추가
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
                .onAppear(perform: {
                    isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
                })
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
                    case .inactive:
                        isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
                    default:
                        break
                    }
                }
        }
        .environmentObject(state)
    }
}

#Preview {
    ContentView()
}
