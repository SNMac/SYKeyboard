//
//  KeyboardToolbarSettingsView.swift
//  SYKeyboard
//
//  Created by Claude on 9/10/26.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

/// 자동완성 바에 얹히는 액세서리 버튼 설정
///
/// undo/redo와 클립보드는 자동완성 후보와 독립적으로 동작하므로 자동완성 설정과 분리한다.
struct KeyboardToolbarSettingsView: View {

    // MARK: - Properties

    @AppStorage(UserDefaultsKeys.isUndoRedoEnabled, store: UserDefaultsManager.shared.storage)
    private var isUndoRedoEnabled = DefaultValues.isUndoRedoEnabled

    @AppStorage(UserDefaultsKeys.isClipboardHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardHistoryEnabled = DefaultValues.isClipboardHistoryEnabled

    @AppStorage(UserDefaultsKeys.isClipboardImageHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardImageHistoryEnabled = DefaultValues.isClipboardImageHistoryEnabled

    // MARK: - Content

    var body: some View {
        Toggle(isOn: $isUndoRedoEnabled, label: {
            Text("Undo/Redo 기능")
            Text("키보드 상단에 Undo/Redo 버튼을 표시\n(일부 앱에서는 정상적으로 동작하지 않을 수 있습니다)")
                .font(.caption)
        })
        .onChange(of: isUndoRedoEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_undo_redo")
            Analytics.logEvent("undo_redo", parameters: [
                "view": "KeyboardToolbarSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }

        Toggle(isOn: $isClipboardHistoryEnabled, label: {
            Text("클립보드 기록")
            Text("복사한 텍스트를 키보드 상단 클립보드 버튼으로 붙여넣기\n(설정 ➡️ SY키보드 ➡️ '다른 앱에서 붙여넣기'를 '허용'으로 바꾸면 확인 알림 없이 저장됩니다)")
                .font(.caption)
        })
        .onChange(of: isClipboardHistoryEnabled) { newValue in
            Analytics.setUserProperty(newValue.analyticsValue,
                                      forName: "pref_clipboard_history")
            Analytics.logEvent("clipboard_history", parameters: [
                "view": "KeyboardToolbarSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }

        if isClipboardHistoryEnabled {
            Toggle(isOn: $isClipboardImageHistoryEnabled, label: {
                Text("이미지도 기록")
                Text("복사한 이미지를 저장하고 탭하면 클립보드로 복원합니다. 이미지당 12 MB까지. 끄면 새로 복사한 이미지를 저장하지 않으며, 저장된 이미지는 클립보드 기록 관리에서 삭제할 수 있습니다.")
                    .font(.caption)
            })
            .onChange(of: isClipboardImageHistoryEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_clipboard_image_history")
                Analytics.logEvent("clipboard_image_history", parameters: [
                    "view": "KeyboardToolbarSettingsView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }

            // 목적지 init이 저장소를 읽으므로 링크를 누를 때만 만든다
            NavigationLink("클립보드 기록 관리") {
                LazyView(ClipboardHistorySettingsView())
            }
        }
    }
}

// MARK: - Preview

#Preview {
    KeyboardToolbarSettingsView()
}
