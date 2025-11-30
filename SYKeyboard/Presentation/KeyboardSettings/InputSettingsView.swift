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
    
    @AppStorage(UserDefaultsKeys.isTextReplacementEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isTextReplacementEnabled = DefaultValues.isTextReplacementEnabled
    
    @AppStorage(UserDefaultsKeys.isAutoChangeToPrimaryEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isAutoChangeToPrimaryEnabled = DefaultValues.isAutoChangeToPrimaryEnabled
    
    @AppStorage(UserDefaultsKeys.isDragToMoveCursorEnabled, store: UserDefaults(suiteName: DefaultValues.groupBundleID))
    private var isDragToMoveCursorEnabled = DefaultValues.isDragToMoveCursorEnabled
    
    // MARK: - Contents
    
    var body: some View {
        Toggle(isOn: $isLongPressToRepeatInputEnabled, label: {
            Text("길게 눌러서 반복 입력")
            Text("'길게 눌러서 숫자 입력' 기능 사용 시 비활성화")
                .font(.caption)
        })
        .onChange(of: isLongPressToRepeatInputEnabled) { newValue in
            if newValue {
                isLongPressToNumberInputEnabled = false
            }
            hideKeyboard()
        }
        
        Toggle(isOn: $isLongPressToNumberInputEnabled, label: {
            Text("길게 눌러서 숫자 입력")
            Text("'길게 눌러서 반복 입력' 기능 사용 시 비활성화")
                .font(.caption)
        })
        .onChange(of: isLongPressToNumberInputEnabled) { newValue in
            if newValue {
                isLongPressToRepeatInputEnabled = false
            }
            hideKeyboard()
        }
        
        NavigationLink("길게 누르기 입력") {
            KeyRepeatSettingsView()
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
        
        if isDragToMoveCursorEnabled {
            NavigationLink("커서 이동") {
                CursorMovementSettingsView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    InputSettingsView()
}
