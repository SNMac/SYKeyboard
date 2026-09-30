//
//  PreviewKeyboardView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/30/25.
//

import SwiftUI

import SYKeyboardCore
import HangeulKeyboardCore

struct PreviewKeyboardView: View {

    // MARK: - Properties

    /// 자동완성 바를 포함한 글자 영역 미리보기 높이
    @Binding var keyboardHeight: Double
    /// 키보드 높이 설정값. 숫자 행 높이 계산에 쓴다
    let keyboardSettingsHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    @Binding var letterColumnWidthMultiplier: Double
    @Binding var needsInputModeSwitchKey: Bool
    @Binding var previewKeyboardLanguage: PreviewKeyboardLanguage
    @Binding var oneHandedMode: OneHandedMode

    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow

    // MARK: - Content
    
    var body: some View {
        Picker(selection: $previewKeyboardLanguage, label: Text("키보드 언어")) {
            ForEach(PreviewKeyboardLanguage.allCases, id: \.self) {
                Text($0.displayStr)
            }
        }
        .pickerStyle(.segmented)
        .frame(height: 44)
        .padding(.horizontal)
        
        switch previewKeyboardLanguage {
        case .hangeul:
            previewHangeulKeyboard
        case .english:
            previewEnglishKeyboard
        }
    }
}

// MARK: - UI Components

private extension PreviewKeyboardView {
    var previewHangeulKeyboard: some View {
        PreviewHangeulKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode,
                                             numberRowHeight: numberRowHeight)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }

    var previewEnglishKeyboard: some View {
        PreviewEnglishKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode,
                                             numberRowHeight: numberRowHeight)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }

    /// 미리보기는 항상 세로 화면이므로 세로 숫자 행 높이를 쓴다
    var numberRowHeight: CGFloat {
        KeyboardHeightPolicy.numberRowHeight(
            isEnabled: showsNumberRow,
            isPortrait: true,
            keyboardSettingsHeight: keyboardSettingsHeight
        )
    }

    var previewFrameHeight: CGFloat {
        keyboardHeight + numberRowHeight
    }
}

// MARK: - UISegmentedControl Extension

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
