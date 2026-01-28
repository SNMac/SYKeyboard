//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

import SYKeyboardCore
import EnglishKeyboardCore

import FirebaseAnalytics

struct InputSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isLongPressToNumberInputEnabled, store: UserDefaultsManager.shared.storage)
    private var isLongPressToNumberInputEnabled = DefaultValues.isLongPressToNumberInputEnabled
    
    @AppStorage(UserDefaultsKeys.isLongPressToRepeatInputEnabled, store: UserDefaultsManager.shared.storage)
    private var isLongPressToRepeatInputEnabled = DefaultValues.isLongPressToRepeatInputEnabled
    
    @AppStorage(UserDefaultsKeys.isAutoCapitalizationEnabled, store: UserDefaultsManager.shared.storage)
    private var isAutoCapitalizationEnabled = DefaultValues.isAutoCapitalizationEnabled
    
    @AppStorage(UserDefaultsKeys.isTextReplacementEnabled, store: UserDefaultsManager.shared.storage)
    private var isTextReplacementEnabled = DefaultValues.isTextReplacementEnabled
    
    @AppStorage(UserDefaultsKeys.isPeriodShortcutEnabled, store: UserDefaultsManager.shared.storage)
    private var isPeriodShortcutEnabled = DefaultValues.isPeriodShortcutEnabled
    
    @AppStorage(UserDefaultsKeys.isAutoChangeToPrimaryEnabled, store: UserDefaultsManager.shared.storage)
    private var isAutoChangeToPrimaryEnabled = DefaultValues.isAutoChangeToPrimaryEnabled
    
    @AppStorage(UserDefaultsKeys.isDragToMoveCursorEnabled, store: UserDefaultsManager.shared.storage)
    private var isDragToMoveCursorEnabled = DefaultValues.isDragToMoveCursorEnabled
    
    enum LongPressMode: Int, CaseIterable {
        case repeatInput
        case numberInput
        case disabled
        
        var displayStr: String {
            switch self {
            case .repeatInput:
                String(localized: "반복 입력")
            case .numberInput:
                String(localized: "숫자 입력")
            case .disabled:
                String(localized: "비활성화")
            }
        }
        
        var analyticsValue: String {
            switch self {
            case .repeatInput:
                "repeat_input"
            case .numberInput:
                "number_input"
            case .disabled:
                "disabled"
            }
        }
    }
    
    private var longPressModeBinding: Binding<LongPressMode> {
        Binding {
            if isLongPressToRepeatInputEnabled {
                return .repeatInput
            } else if isLongPressToNumberInputEnabled {
                return .numberInput
            } else {
                return .disabled
            }
        } set: { newValue in
            switch newValue {
            case .repeatInput:
                isLongPressToRepeatInputEnabled = true
                isLongPressToNumberInputEnabled = false
            case .numberInput:
                isLongPressToRepeatInputEnabled = false
                isLongPressToNumberInputEnabled = true
            case .disabled:
                isLongPressToRepeatInputEnabled = false
                isLongPressToNumberInputEnabled = false
            }
            
            Analytics.logEvent("selected_long_press_action", parameters: [
                "view": "InputSettingsView",
                "selection": newValue.analyticsValue
            ])
            hideKeyboard()
        }
    }
    
    // MARK: - Contents
    
    var body: some View {
        Picker("길게 누르기 동작", selection: longPressModeBinding) {
            ForEach(LongPressMode.allCases, id: \.self) {
                Text($0.displayStr)
            }
        }
        
        NavigationLink("길게 누르기 입력") {
            KeyRepeatSettingsView()
        }
        
        Toggle(isOn: $isAutoCapitalizationEnabled, label: {
            Text("자동 대문자")
        })
        .onChange(of: isAutoCapitalizationEnabled) { newValue in
            Analytics.logEvent("auto_capitalization", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue ? "on" : "off"
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("시스템 설정의 텍스트 대치 단축키 사용")
                .font(.caption)
        })
        .onChange(of: isTextReplacementEnabled) { newValue in
            Analytics.logEvent("text_replacement", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue ? "on" : "off"
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isPeriodShortcutEnabled, label: {
            Text("'.' 단축키")
            Text("스페이스 바를 두 번 탭하면 마침표와 간격을 차례로 삽입")
                .font(.caption)
        })
        .onChange(of: isPeriodShortcutEnabled) { newValue in
            Analytics.logEvent("input_settings", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue ? "on" : "off"
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isAutoChangeToPrimaryEnabled, label: {
            Text("한글 키보드 자동 변경")
            Text("기호 키보드 입력 후 스페이스/리턴 ➡️ 한글 키보드")
                .font(.caption)
        })
        .onChange(of: isAutoChangeToPrimaryEnabled) { newValue in
            Analytics.logEvent("auto_change_to_primary", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue ? "on" : "off"
            ])
            hideKeyboard()
        }
        
        Toggle(isOn: $isDragToMoveCursorEnabled, label: {
            Text("드래그하여 커서 이동")
        })
        .onChange(of: isDragToMoveCursorEnabled) { newValue in
            Analytics.logEvent("drag_to_move_cursor", parameters: [
                "view": "InputSettingsView",
                "enabled": newValue ? "on" : "off"
            ])
            hideKeyboard()
        }
        
        NavigationLink("커서 이동") {
            CursorMovementSettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    InputSettingsView()
}
