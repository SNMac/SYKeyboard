//
//  KeyboardSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI

struct KeyboardSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isKeyboardExtensionEnabled: Bool = false
    
    private func checkKeyboardExtensionEnabled() -> Bool {
        guard let appBundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("checkKeyboardExtensionEnabled(): Cannot retrieve bundle identifier.")
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
    
    var body: some View {
        List {
            Section {
                InitialSettingsView()
            } header: {
                Text("키보드 추가 및 권한 설정")
            } footer: {
                Text("키보드 ➡️ 'SY키보드' 및 '전체 접근 허용' 활성화")
                    .font(.system(.caption))
            }
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }
            
            if isKeyboardExtensionEnabled {
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
            } else {
                Section {
                    Text("‼️ SY키보드 추가 필요 ‼️")
                } footer: {
                    Text("SY키보드를 추가하시면 세부 설정이 가능합니다.")
                }
            }
            
            Section {
                InfoView()
            } header: {
                Text("정보")
            }
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }
        }
        .scrollDismissesKeyboard(.immediately).ignoresSafeArea(.keyboard, edges: .all)
        .navigationTitle(Bundle.displayName ?? "SY키보드")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
        }
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
}

#Preview {
    KeyboardSettingsView()
}
