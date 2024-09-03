//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

struct ContentView: View {
    private let defaults: UserDefaults?
    
    init() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        
        // UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만듬
        if defaults?.object(forKey: "isSoundFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isSoundFeedbackEnabled")
        }
        
        if defaults?.object(forKey: "isHapticFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isHapticFeedbackEnabled")
        }
        
        if defaults?.object(forKey: "isAutocompleteEnabled") == nil {
            defaults?.setValue(true, forKey: "isAutocompleteEnabled")
        }
        
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.setValue(GlobalData().defaultHeight, forKey: "keyboardHeight")
        }
        
        if defaults?.object(forKey: "tempKeyboardHeight") == nil {
            defaults?.setValue(Double(GlobalData().defaultHeight), forKey: "tempKeyboardHeight")
        }
    }
    
    private var insideNavigation: some View {
        List {
            Section(content: {
                QuickSettingsView()
            }, header: {
                Text("일반 설정")
            })
            
            Section {
                NavigationLink("키보드 높이") {
                    HeightSettingsView()
                }
            } header: {
                Text("외형 설정")
            }
            
            Section {
                Text((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!)
            } header: {
                Text("정보")
            }
        }
        .navigationTitle((Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)!)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                KeyboardTestView()
                insideNavigation
            }
        } else {
            NavigationView {
                KeyboardTestView()
                insideNavigation
            }
        }
    }
}

#Preview {
    ContentView()
}
