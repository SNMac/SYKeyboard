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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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
        // 가로에서는 높이가 모자라 각 설정 화면이 슬라이더 옆에 언어 선택을 둔다
        if verticalSizeClass != .compact {
            PreviewKeyboardLanguagePicker(selection: $previewKeyboardLanguage)
                .frame(height: 44)
                .padding(.horizontal)
        }

        Group {
            switch previewKeyboardLanguage {
            case .hangeul:
                previewHangeulKeyboard
            case .english:
                previewEnglishKeyboard
            }
        }
        .ignoresSafeArea(.container, edges: ignoredSafeAreaEdges)
        .frame(height: previewFrameHeight)
        .background(.keyboardBackground)
        .padding(.bottom, systemButtonRowHeight)
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

    /// 실제 키보드처럼 화면 size class로 세로·가로 높이 규칙을 고른다
    var usesPortraitHeight: Bool {
        KeyboardHeightPolicy.usesPortraitHeight(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    /// 세로에서는 실제 키보드처럼 iPhone Duo 세로 바 영역까지 키를 채운다.
    /// 가로에서는 실제 키보드가 양옆을 지구본·받아쓰기 버튼 자리로 비우므로 설정 앱의 좌우 safe area 안에 키를 둔다.
    /// 키보드 쪽 여백이 노치만 피하는 앱보다 넓어 실제 키 폭과 완전히 같지는 않다(iPhone 13 mini에서 양쪽 약 25pt)
    var ignoredSafeAreaEdges: Edge.Set {
        verticalSizeClass == .compact ? [] : .horizontal
    }

    /// 키보드 아래 시스템 버튼 줄(지구본·받아쓰기) 자리. 가로에서는 이 버튼이 키보드 양옆으로 가므로 비우지 않는다
    var systemButtonRowHeight: CGFloat {
        guard !needsInputModeSwitchKey, verticalSizeClass != .compact else { return 0 }
        return 40
    }

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

// MARK: - PreviewKeyboardLanguagePicker

/// 미리보기 키보드의 한글·영어 선택. 세로에서는 미리보기 위에, 가로에서는 설정 화면의 슬라이더 옆에 둔다
struct PreviewKeyboardLanguagePicker: View {
    @Binding var selection: PreviewKeyboardLanguage

    var body: some View {
        Picker(selection: $selection, label: Text("키보드 언어")) {
            ForEach(PreviewKeyboardLanguage.allCases, id: \.self) {
                Text($0.displayStr)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - PreviewSettingsCompactRow

/// 가로 설정 화면의 한 줄 배치: 값, 슬라이더, 미리보기 언어 선택
struct PreviewSettingsCompactRow<Value: View, SliderContent: View>: View {
    @Binding var previewKeyboardLanguage: PreviewKeyboardLanguage
    @ViewBuilder let value: () -> Value
    @ViewBuilder let slider: () -> SliderContent

    var body: some View {
        HStack(spacing: 12) {
            value()
                .monospacedDigit()
                .frame(minWidth: 40)
            slider()
            PreviewKeyboardLanguagePicker(selection: $previewKeyboardLanguage)
                .frame(width: 256)
        }
        .frame(height: 44)
        .padding(.horizontal)
    }
}

// MARK: - KeyboardHeightPolicy Extension

extension KeyboardHeightPolicy {
    /// 설정 앱 화면의 size class로 실제 키보드와 같은 높이 규칙을 고른다. iPhone Duo 안쪽 화면은 가로여도 세로 높이 규칙이다.
    /// iPhone의 size class는 항상 정해져 있어 `fallbackBounds`는 쓰이지 않는다
    static func usesPortraitHeight(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        usesPortraitHeight(
            orientation: .unknown,
            usesOrientation: false,
            fallbackBounds: .zero,
            horizontalSizeClass: UIUserInterfaceSizeClass(horizontalSizeClass),
            verticalSizeClass: UIUserInterfaceSizeClass(verticalSizeClass)
        )
    }
}

// MARK: - UISegmentedControl Extension

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
