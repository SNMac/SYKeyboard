//
//  LetterColumnWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 8/29/26.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct LetterColumnWidthSettingsView: View {

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

    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaultsManager.shared.storage)
    private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey

    @AppStorage("previewKeyboardLanguage") private var previewKeyboardLanguage: PreviewKeyboardLanguage = .hangeul

    @State private var previewOneHandedMode: OneHandedMode = .center
    @State private var previewKeyboardHeight: Double = DefaultValues.keyboardHeight
    @State private var tempLetterColumnWidthMultiplier: Double = DefaultValues.letterColumnWidthMultiplier

    // MARK: - Content

    var body: some View {
        NavigationStack {
            letterColumnWidthSettings

            Spacer()

            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $tempLetterColumnWidthMultiplier,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempLetterColumnWidthMultiplier = letterColumnWidthMultiplier
            updatePreviewKeyboardHeight()
        }.requestReviewOnDetailSettingsReturn()
    }
}

// MARK: - UI Components

private extension LetterColumnWidthSettingsView {
    /// 슬라이더용 정수 바인딩. 실수 step의 부동소수점 오차를 피한다
    var letterColumnWidthPercent: Binding<Double> {
        Binding(
            get: { KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier) },
            set: { tempLetterColumnWidthMultiplier = KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: $0) }
        )
    }

    var letterColumnWidthSettings: some View {
        VStack {
            Text("\(Int(KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier)))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: letterColumnWidthPercent,
                   in: KeyboardLayoutFigure.letterColumnWidthPercentRange,
                   step: 1)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
        }
        .navigationTitle("글자 열 너비")
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
                    tempLetterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    letterColumnWidthMultiplier = tempLetterColumnWidthMultiplier
                    Analytics.setUserProperty(String(format: "%.2f", letterColumnWidthMultiplier),
                                              forName: "pref_letter_column_width")
                    Analytics.logEvent("letter_column_width", parameters: [
                        "view": "LetterColumnWidthSettingsView",
                        "value": letterColumnWidthMultiplier
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

private extension LetterColumnWidthSettingsView {
    func updatePreviewKeyboardHeight() {
        let suggestionBarHeight = isPredictiveTextEnabled
        ? KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing + KeyboardLayoutFigure.keyboardFrameSpacing
        : 0
        previewKeyboardHeight = keyboardHeight + suggestionBarHeight
    }
}

// MARK: - Preview

#Preview {
    LetterColumnWidthSettingsView()
}
