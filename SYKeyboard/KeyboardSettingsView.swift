//
//  KeyboardSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/17/25.
//

import SwiftUI

struct KeyboardSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var isKeyboardExtensionEnabled: Bool = false
    
    // MARK: - Contents
    
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
        .ignoresSafeArea(.keyboard, edges: .all)
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active, .inactive:
                isKeyboardExtensionEnabled = checkKeyboardExtensionEnabled()
            default:
                break
            }
        }
    }
}

// MARK: - Private Methods

private extension KeyboardSettingsView {
    /// 사용자의 "AppleKeyboards" 설정에 현재 앱의 키보드 확장이 포함되어 있는지 여부를 반환하는 메서드
    func checkKeyboardExtensionEnabled() -> Bool {
        // 사용자의 설정 데이터 가져옴
        //   - "AppleKeyboards" 값은 사용자가 설정에서 활성화한 키보드 목록(예: "com.apple.keyboard.emoji", "com.thirdparty.customkeyboard")을 포함
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }
        
        // 현재 앱의 Bundle ID에 "."을 붙여서 키보드 확장의 Bundle ID 패턴을 생성
        //   - 메인 앱의 Bundle ID: "github.com-SNMac.SYKeyboard"
        //     -> 키보드 Extension의 Bundle ID: "github.com-SNMac.SYKeyboard.keyboard"
        let keyboardExtensionBundleIDPrefix = Bundle.main.bundleIdentifier! + "."
        for keyboard in keyboards {
            // "AppleKeyboards" 목록을 순회하며 현재 앱의 키보드 확장이 포함되어 있는지 검사
            if keyboard.hasPrefix(keyboardExtensionBundleIDPrefix) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Preview

#Preview {
    KeyboardSettingsView()
}
