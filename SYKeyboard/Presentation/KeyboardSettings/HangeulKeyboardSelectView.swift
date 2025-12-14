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
    
    enum HangeulKeyboard: Int, CaseIterable {
        case naratgeul
        case cheonjiin
        // TODO: 두벌식 추가
        
        var displayStr: String {
            switch self {
            case .naratgeul:
                String(localized: "나랏글")
            case .cheonjiin:
                String(localized: "천지인")
            }
        }
        
        var analyticsValue: String {
            switch self {
            case .naratgeul:
                "naratgeul"
            case .cheonjiin:
                "cheonjiin"
            }
        }
    }
    
    private var keyboardSelectionBinding: Binding<HangeulKeyboard> {
        Binding {
            return HangeulKeyboard(rawValue: selectedHangeulKeyboard.rawValue) ?? .naratgeul
        } set: { newValue in
            selectedHangeulKeyboard = HangeulKeyboardType(rawValue: newValue.rawValue) ?? .naratgeul
            
            Analytics.logEvent("selected_hangeul_keyboard", parameters: [
                "view": "HangeulKeyboardSelectView",
                "value": newValue.analyticsValue
            ])
            hideKeyboard()
        }
    }
    
    // MARK: - Contents
    
    var body: some View {
        Picker("한글 키보드", selection: keyboardSelectionBinding) {
            ForEach(HangeulKeyboard.allCases, id: \.self) {
                Text($0.displayStr)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HangeulKeyboardSelectView()
}
