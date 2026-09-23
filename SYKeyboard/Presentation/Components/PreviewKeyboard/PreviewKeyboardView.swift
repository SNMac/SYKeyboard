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

    @Binding var keyboardHeight: Double
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
                                             oneHandedMode: $oneHandedMode)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }

    var previewEnglishKeyboard: some View {
        PreviewEnglishKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }

    /// 미리보기는 항상 세로 화면이므로 세로 숫자 행 높이를 더한다
    var previewFrameHeight: CGFloat {
        keyboardHeight + KeyboardHeightPolicy.numberRowHeight(isEnabled: showsNumberRow, isPortrait: true)
    }
}

// MARK: - UISegmentedControl Extension

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
