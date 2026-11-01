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
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaultsManager.shared.storage)
    private var keyboardHeight = DefaultValues.keyboardHeight

    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaultsManager.shared.storage)
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth

    @AppStorage(UserDefaultsKeys.letterColumnWidthMultiplier, store: UserDefaultsManager.shared.storage)
    private var letterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier

    @State private var previewOneHandedMode: OneHandedMode = .center
    @State private var tempLetterColumnWidthMultiplier: Double = DefaultValues.letterColumnWidthMultiplier

    // MARK: - Content

    var body: some View {
        VStack {
            letterColumnWidthSettings

            Spacer()

            PreviewKeyboardView(keyboardSettingsHeight: keyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $tempLetterColumnWidthMultiplier,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempLetterColumnWidthMultiplier = letterColumnWidthMultiplier
        }.requestReviewOnDetailSettingsReturn()
    }
}

// MARK: - UI Components

private extension LetterColumnWidthSettingsView {
    var widthValueText: Text {
        Text("\(Int(KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier)))")
    }

    var widthSlider: some View {
        Slider(value: letterColumnWidthPercent,
               in: KeyboardLayoutFigure.letterColumnWidthPercentRange,
               step: 1)
    }

    @ViewBuilder
    var letterColumnWidthControls: some View {
        if verticalSizeClass == .compact {
            // 가로는 높이가 모자라 값과 슬라이더를 한 줄에 둔다
            PreviewSettingsCompactRow {
                widthValueText
            } slider: {
                widthSlider
            }
            .padding(.top, 8)
        } else {
            VStack {
                widthValueText
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                widthSlider
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
            }
        }
    }

    /// 슬라이더용 정수 바인딩. 실수 step의 부동소수점 오차를 피한다
    var letterColumnWidthPercent: Binding<Double> {
        Binding(
            get: { KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier) },
            set: { tempLetterColumnWidthMultiplier = KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: $0) }
        )
    }

    var letterColumnWidthSettings: some View {
        // 세로처럼 다 들어가면 그대로 두고, 가로처럼 미리보기를 뺀 높이가 모자라면 이 부분만 스크롤한다
        ViewThatFits(in: .vertical) {
            letterColumnWidthControls
            ScrollView {
                letterColumnWidthControls
            }
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

// MARK: - Preview

#Preview {
    NavigationStack {
        LetterColumnWidthSettingsView()
    }
}
