//
//  OneHandedKeyboardWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/17/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct OneHandedKeyboardWidthSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaultsManager.shared.storage)
    private var keyboardHeight = DefaultValues.keyboardHeight
    
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaultsManager.shared.storage)
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth

    @AppStorage(UserDefaultsKeys.letterColumnWidthMultiplier, store: UserDefaultsManager.shared.storage)
    private var letterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier

    @AppStorage(UserDefaultsKeys.isPredictiveTextEnabled, store: UserDefaultsManager.shared.storage)
    private var isPredictiveTextEnabled = DefaultValues.isPredictiveTextEnabled

    @AppStorage(UserDefaultsKeys.isUndoRedoEnabled, store: UserDefaultsManager.shared.storage)
    private var isUndoRedoEnabled = DefaultValues.isUndoRedoEnabled

    @AppStorage(UserDefaultsKeys.isClipboardHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardHistoryEnabled = DefaultValues.isClipboardHistoryEnabled
    
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaultsManager.shared.storage)
    private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    
    @AppStorage("previewKeyboardLanguage") private var previewKeyboardLanguage: PreviewKeyboardLanguage = .hangeul
    
    @State private var previewOneHandedMode: OneHandedMode = .right
    @State private var previewKeyboardHeight: Double = DefaultValues.keyboardHeight
    @State private var tempOneHandedKeyboardWidth: Double = DefaultValues.oneHandedKeyboardWidth
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var sliderResetCount = 0
    
    // MARK: - Content
    
    var body: some View {
        VStack {
            oneHandedKeyboardWidthSettings
            
            Spacer()
            
            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                keyboardSettingsHeight: keyboardHeight,
                                oneHandedKeyboardWidth: $tempOneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempOneHandedKeyboardWidth = oneHandedKeyboardWidth
            updatePreviewKeyboardHeight()
            updatePreviewLanguageBasedOnSystem()
        }.requestReviewOnDetailSettingsReturn()
    }
}

// MARK: - UI Components

private extension OneHandedKeyboardWidthSettingsView {
    var oneHandedKeyboardWidthSettings: some View {
        VStack {
            Text("\(Int(tempOneHandedKeyboardWidth) - (Int(DefaultValues.oneHandedKeyboardWidth) - 100))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempOneHandedKeyboardWidth, in: 300...340, step: 1)
                .id(sliderResetCount)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
        }
        .navigationTitle("한 손 키보드 너비")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempOneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
                    sliderResetCount += 1
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    oneHandedKeyboardWidth = tempOneHandedKeyboardWidth
                    Analytics.setUserProperty(String(format: "%.1f", oneHandedKeyboardWidth),
                                              forName: "pref_one_handed_width")
                    Analytics.logEvent("one_handed_keyboard_width", parameters: [
                        "view": "OneHandedKeyboardWidthSettingsView",
                        "value": oneHandedKeyboardWidth
                    ])
                    
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension OneHandedKeyboardWidthSettingsView {
    func updatePreviewKeyboardHeight() {
        let isSuggestionBarVisible = KeyboardPresentationStatePolicy.isSuggestionBarVisibleForSettingsPreview(
            isPredictiveTextEnabled: isPredictiveTextEnabled,
            isUndoRedoEnabled: isUndoRedoEnabled,
            isClipboardHistoryEnabled: isClipboardHistoryEnabled
        )
        let suggestionBarHeight = isSuggestionBarVisible
        ? KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing + KeyboardLayoutFigure.keyboardFrameSpacing
        : 0
        previewKeyboardHeight = keyboardHeight + suggestionBarHeight
    }
    
    func updatePreviewLanguageBasedOnSystem() {
        let currentLanguageCode = Bundle.main.preferredLocalizations.first ?? "ko"
        
        if currentLanguageCode.hasPrefix("ko") {
            previewKeyboardLanguage = .hangeul
        } else {
            previewKeyboardLanguage = .english
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OneHandedKeyboardWidthSettingsView()
    }
}
