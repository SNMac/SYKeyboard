//
//  AppearanceSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI

import SYKeyboardCore
import HangeulKeyboardCore

import FirebaseAnalytics

struct AppearanceSettingsView: View {
    
    // MARK: - Properties
    
    @AppStorage(UserDefaultsKeys.selectedHangeulKeyboard, store: UserDefaultsManager.shared.storage)
    private var selectedHangeulKeyboard = DefaultValues.selectedHangeulKeyboard

    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow

    @AppStorage(UserDefaultsKeys.isNumericKeypadEnabled, store: UserDefaultsManager.shared.storage)
    private var isNumericKeypadEnabled = DefaultValues.isNumericKeypadEnabled

    @AppStorage(UserDefaultsKeys.isBottomSpaceEnabled, store: UserDefaultsManager.shared.storage)
    private var isBottomSpaceEnabled = DefaultValues.isBottomSpaceEnabled

    @AppStorage(UserDefaultsKeys.isOneHandedKeyboardEnabled, store: UserDefaultsManager.shared.storage)
    private var isOneHandedKeyboardEnabled = DefaultValues.isOneHandedKeyboardEnabled
    
    // MARK: - Content
    
    var body: some View {
        NavigationLink("키보드 높이") {
            KeyboardHeightSettingsView()
        }

        Toggle(isOn: $showsNumberRow, label: {
            Text("숫자 행 표시")
            Text("두벌식·쿼티 자판 맨 윗줄에 숫자 키 표시")
                .font(.caption)
        })
        .onChange(of: showsNumberRow) { newValue in
            // 사용자 속성 25개 한도 때문에 이벤트로만 남긴다
            Analytics.logEvent("number_row", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }

        if showsLetterColumnWidthSettings {
            NavigationLink {
                LetterColumnWidthSettingsView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("글자 열 너비")
                    Text("나랏글·천지인·숫자 키패드에 적용")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        Toggle(isOn: $isNumericKeypadEnabled, label: {
            Text("숫자 키패드 활성화")
            Text("'!#1', '한글' 또는 'ABC' 버튼을 화살표 방향으로 드래그하여 전환")
                .font(.caption)
        })
        .onChange(of: isNumericKeypadEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_numeric_keypad")
            Analytics.logEvent("numeric_keypad", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }

        if showsBottomSpaceSettings {
            Toggle(isOn: $isBottomSpaceEnabled, label: {
                Text("스페이스 하단 배치")
                Text("천지인·숫자 키패드의 스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림")
                    .font(.caption)
            })
            .onChange(of: isBottomSpaceEnabled) { newValue in
                // 사용자 속성 25개 한도 때문에 이벤트로만 남긴다
                Analytics.logEvent("bottom_space", parameters: [
                    "view": "AppearanceSettingsView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }
        }

        Toggle(isOn: $isOneHandedKeyboardEnabled, label: {
            Text("한 손 키보드 활성화")
            Text("'!#1', '한글' 또는 'ABC' 버튼을 위로 드래그하거나 길게 눌러 변경")
                .font(.caption)
        })
        .onChange(of: isOneHandedKeyboardEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_one_handed_keyboard")
            Analytics.logEvent("one_handed_keyboard", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
        
        if isOneHandedKeyboardEnabled {
            NavigationLink("한 손 키보드 너비") {
                OneHandedKeyboardWidthSettingsView()
            }
        }
    }

    /// 4열 격자 키보드를 하나라도 쓰는 사용자에게만 노출한다
    private var showsLetterColumnWidthSettings: Bool {
        selectedHangeulKeyboard == .naratgeul
        || selectedHangeulKeyboard == .cheonjiin
        || isNumericKeypadEnabled
    }

    /// 스페이스 하단 배치가 적용되는 천지인·숫자 키패드 중 하나라도 쓰는 사용자에게만 노출한다
    private var showsBottomSpaceSettings: Bool {
        selectedHangeulKeyboard == .cheonjiin || isNumericKeypadEnabled
    }
}

// MARK: - Content

#Preview {
    AppearanceSettingsView()
}
