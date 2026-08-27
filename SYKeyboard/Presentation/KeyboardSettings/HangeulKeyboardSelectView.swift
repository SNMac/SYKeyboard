//
//  HangeulKeyboardSelectView.swift
//  SYKeyboard
//
//  Created by 서동환 on 12/2/25.
//

import SwiftUI

import SYKeyboardCore
import HangeulKeyboardCore

import FirebaseAnalytics

struct HangeulKeyboardSelectView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.selectedHangeulKeyboard, store: UserDefaultsManager.shared.storage)
    private var selectedHangeulKeyboard = DefaultValues.selectedHangeulKeyboard
    
    @AppStorage(UserDefaultsKeys.isNaratgeulDotLabelEnabled, store: UserDefaultsManager.shared.storage)
    private var isNaratgeulDotLabelEnabled = DefaultValues.isNaratgeulDotLabelEnabled
    
    enum HangeulKeyboard: Int, CaseIterable {
        case naratgeul
        case cheonjiin
        case dubeolsik
        
        var displayStr: String {
            switch self {
            case .naratgeul:
                String(localized: "나랏글")
            case .cheonjiin:
                String(localized: "천지인")
            case .dubeolsik:
                String(localized: "두벌식")
            }
        }
        
        var analyticsValue: String {
            switch self {
            case .naratgeul:
                "naratgeul"
            case .cheonjiin:
                "cheonjiin"
            case .dubeolsik:
                "dubeolsik"
            }
        }
    }
    
    private var keyboardSelectionBinding: Binding<HangeulKeyboard> {
        Binding {
            return HangeulKeyboard(rawValue: selectedHangeulKeyboard.rawValue) ?? .naratgeul
        } set: { newValue in
            selectedHangeulKeyboard = HangeulKeyboardType(rawValue: newValue.rawValue) ?? .naratgeul
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_hangeul_keyboard")
            Analytics.logEvent("selected_hangeul_keyboard", parameters: [
                "view": "HangeulKeyboardSelectView",
                "selection": newValue.analyticsValue
            ])
            hideKeyboard()
        }
    }
    
    // MARK: - Content
    
    var body: some View {
        Picker("한글 키보드", selection: keyboardSelectionBinding) {
            ForEach(HangeulKeyboard.allCases, id: \.self) {
                Text($0.displayStr)
            }
        }
        
        if selectedHangeulKeyboard == .naratgeul {
            Toggle(isOn: $isNaratgeulDotLabelEnabled, label: {
                Text("획·쌍 버튼 점 표기")
                Text("'획'을 'ㆍ', '쌍'을 'ᆢ'로 표시")
                    .font(.caption)
            })
            .onChange(of: isNaratgeulDotLabelEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_naratgeul_dot_label")
                Analytics.logEvent("naratgeul_dot_label", parameters: [
                    "view": "HangeulKeyboardSelectView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HangeulKeyboardSelectView()
}
