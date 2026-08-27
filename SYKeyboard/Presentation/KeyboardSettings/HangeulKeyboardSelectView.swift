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

    @AppStorage(UserDefaultsKeys.isCheonjiinBottomSpaceEnabled, store: UserDefaultsManager.shared.storage)
    private var isCheonjiinBottomSpaceEnabled = DefaultValues.isCheonjiinBottomSpaceEnabled

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
                Text("획·쌍 버튼 기호 표기")
                Text("'획' ➡️ 'ㆍ', '쌍' ➡️ 'ᆢ'")
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

        if selectedHangeulKeyboard == .cheonjiin {
            Toggle(isOn: $isCheonjiinBottomSpaceEnabled, label: {
                Text("스페이스 하단 배치")
                Text("스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림")
                    .font(.caption)
            })
            .onChange(of: isCheonjiinBottomSpaceEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_cheonjiin_bottom_space")
                Analytics.logEvent("cheonjiin_bottom_space", parameters: [
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
