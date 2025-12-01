//
//  InputSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

import SYKeyboardCore

struct InputSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.isLongPressToNumberInputEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isLongPressToNumberInputEnabled = DefaultValues.isLongPressToNumberInputEnabled
    
    @AppStorage(UserDefaultsKeys.isLongPressToRepeatInputEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isLongPressToRepeatInputEnabled = DefaultValues.isLongPressToRepeatInputEnabled
    
    @AppStorage(UserDefaultsKeys.isAutoCapitalizationEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isAutoCapitalizationEnabled = DefaultValues.isAutoCapitalizationEnabled
    
    @AppStorage(UserDefaultsKeys.isTextReplacementEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isTextReplacementEnabled = DefaultValues.isTextReplacementEnabled
    
    @AppStorage(UserDefaultsKeys.isAutoChangeToPrimaryEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isAutoChangeToPrimaryEnabled = DefaultValues.isAutoChangeToPrimaryEnabled
    
    @AppStorage(UserDefaultsKeys.isDragToMoveCursorEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isDragToMoveCursorEnabled = DefaultValues.isDragToMoveCursorEnabled
    
    enum LongPressMode: String, CaseIterable, Identifiable {
        case repeatInput = "반복 입력"
        case numberInput = "숫자 입력"
        case disabled = "비활성화"
        
        var id: String { self.rawValue }
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
            case .disabled:
                isLongPressToRepeatInputEnabled = false
                isLongPressToNumberInputEnabled = false
            case .repeatInput:
                isLongPressToRepeatInputEnabled = true
                isLongPressToNumberInputEnabled = false
            case .numberInput:
                isLongPressToRepeatInputEnabled = false
                isLongPressToNumberInputEnabled = true
            }
            hideKeyboard()
        }
    }
    
    // MARK: - Contents
    
    var body: some View {
        Picker("길게 누르기 동작", selection: longPressModeBinding) {
            ForEach(LongPressMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        
        NavigationLink("길게 누르기 입력") {
            KeyRepeatSettingsView()
        }
        
        Toggle(isOn: $isAutoCapitalizationEnabled, label: {
            Text("자동 대문자")
        })
        .onChange(of: isAutoCapitalizationEnabled) { _ in
            hideKeyboard()
        }
        
        Toggle(isOn: $isTextReplacementEnabled, label: {
            Text("텍스트 대치")
            Text("시스템 설정의 텍스트 대치 단축키 사용")
                .font(.caption)
        })
        .onChange(of: isTextReplacementEnabled) { _ in
            hideKeyboard()
        }
        
        Toggle(isOn: $isAutoChangeToPrimaryEnabled, label: {
            Text("한글 키보드 자동 변경")
            Text("기호 키보드 입력 후 스페이스/리턴 ➡️ 한글 키보드")
                .font(.caption)
        })
        .onChange(of: isAutoChangeToPrimaryEnabled) { _ in
            hideKeyboard()
        }
        
        Toggle(isOn: $isDragToMoveCursorEnabled, label: {
            Text("드래그하여 커서 이동")
        })
        .onChange(of: isDragToMoveCursorEnabled) { _ in
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
