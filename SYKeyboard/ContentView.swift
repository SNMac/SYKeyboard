//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isKeyboardExtensionEnabled: Bool = false
    
    private var defaults: UserDefaults?
    private var state: PreviewNaratgeulState
    
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
    
    init() {
        defaults = UserDefaults(suiteName: GlobalValues.groupBundleID)
        GlobalValues.setupDefaults(defaults)
        
        state = PreviewNaratgeulState()
    }
    
    private var keyboardSettings: some View {
        List {
            Section {
                InitialSettingsView()
            } header: {
                Text("키보드 추가 및 권한 설정")
            } footer: {
                Text("키보드 ➡️ 나랏글 ON, 전체 접근 허용 ON")
                    .font(.system(.caption))
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
                    Text("‼️ 키보드 추가 필요 ‼️")
                } footer: {
                    Text("키보드를 추가하시면 세부 설정이 가능합니다.")
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
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
            
            NavigationStack {
                KeyboardTestView()
                
                keyboardSettings
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
                
                BannerView(adSize)
                  .frame(height: adSize.size.height)
            }
            .environmentObject(state)
        }
    }
}

#Preview {
    ContentView()
}
