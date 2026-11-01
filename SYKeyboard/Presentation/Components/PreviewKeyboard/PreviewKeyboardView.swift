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

    /// 키보드 높이 설정값. 높이 설정 화면에서는 저장 전 슬라이더 값이다
    let keyboardSettingsHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    @Binding var letterColumnWidthMultiplier: Double
    @Binding var needsInputModeSwitchKey: Bool
    @Binding var previewKeyboardLanguage: PreviewKeyboardLanguage
    @Binding var oneHandedMode: OneHandedMode

    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow

    @AppStorage(UserDefaultsKeys.isPredictiveTextEnabled, store: UserDefaultsManager.shared.storage)
    private var isPredictiveTextEnabled = DefaultValues.isPredictiveTextEnabled

    @AppStorage(UserDefaultsKeys.isUndoRedoEnabled, store: UserDefaultsManager.shared.storage)
    private var isUndoRedoEnabled = DefaultValues.isUndoRedoEnabled

    @AppStorage(UserDefaultsKeys.isClipboardHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardHistoryEnabled = DefaultValues.isClipboardHistoryEnabled

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
        
        Group {
            switch previewKeyboardLanguage {
            case .hangeul:
                previewHangeulKeyboard
            case .english:
                previewEnglishKeyboard
            }
        }
        // 실제 키보드처럼 iPhone Duo 세로 바 영역까지 키를 채운다
        .ignoresSafeArea(.container, edges: .horizontal)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }
}

// MARK: - UI Components

private extension PreviewKeyboardView {
    var previewHangeulKeyboard: some View {
        PreviewHangeulKeyboardViewController(keyboardHeight: previewFrameHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode,
                                             numberRowHeight: numberRowHeight)
    }

    var previewEnglishKeyboard: some View {
        PreviewEnglishKeyboardViewController(keyboardHeight: previewFrameHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode,
                                             numberRowHeight: numberRowHeight)
    }

    /// 미리보기는 항상 세로 화면이므로 세로 높이 규칙을 쓴다
    var usesPortraitHeight: Bool { true }

    var isSuggestionBarVisible: Bool {
        KeyboardPresentationStatePolicy.isSuggestionBarVisibleForSettingsPreview(
            isPredictiveTextEnabled: isPredictiveTextEnabled,
            isUndoRedoEnabled: isUndoRedoEnabled,
            isClipboardHistoryEnabled: isClipboardHistoryEnabled
        )
    }

    var numberRowHeight: CGFloat {
        KeyboardHeightPolicy.numberRowHeight(
            isEnabled: showsNumberRow,
            usesPortraitHeight: usesPortraitHeight,
            keyboardSettingsHeight: keyboardSettingsHeight
        )
    }

    /// 실제 키보드가 `setKeyboardHeight()`에서 쓰는 것과 같은 계산으로 키보드 뷰 높이를 정한다.
    /// 미리보기는 키 영역에 높이 제약이 없어 자동완성 바를 뺀 나머지를 키 영역이 채운다
    var previewFrameHeight: CGFloat {
        KeyboardHeightPolicy.height(
            keyboardSettingsHeight: keyboardSettingsHeight,
            landscapeKeyboardHeight: KeyboardLayoutFigure.landscapeKeyboardHeight,
            suggestionBarHeight: KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing,
            isSuggestionBarVisible: isSuggestionBarVisible,
            usesPortraitHeight: usesPortraitHeight,
            numberRowHeight: numberRowHeight
        ).keyboardViewHeight
    }
}

// MARK: - UISegmentedControl Extension

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
