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

    /// 지금 화면 크기(현재 방향 기준). 실제 키보드가 비우는 여백을 정하는 데 쓴다
    @State private var screenSize: CGSize = .zero
    @State private var hasHomeIndicator = false
    /// 설정 앱 화면의 아래 safe area. 미리보기는 이 위에 놓이므로 실제 키보드 자리까지 내리는 데 쓴다
    @State private var bottomSafeAreaInset: CGFloat = 0
    /// 설정 앱 화면의 양옆 safe area 중 큰 값. 가로에서 기기 종류를 나누는 데 쓴다
    @State private var sideSafeAreaInset: CGFloat = 0

    // MARK: - Content
    
    var body: some View {
        // 한영 키보드라 한글·영어는 미리보기 안의 한영 전환 키로 바꾼다
        PreviewHangeulEnglishKeyboardViewController(keyboardHeight: previewFrameHeight,
                                                    oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                                    letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                                    oneHandedMode: $oneHandedMode,
                                                    numberRowHeight: numberRowHeight)
        .frame(height: previewFrameHeight)
        // 실제 키보드가 화면 안에서 양옆에 비우는 자리(가로의 지구본·받아쓰기 자리, iPhone Duo 세로의 양옆)를 똑같이 비운다
        .padding(.leading, frameInsets.leading)
        .padding(.trailing, frameInsets.trailing)
        // 실제 키보드처럼 iOS가 키보드 아래에 비우는 자리(홈 인디케이터, 세로의 지구본·받아쓰기 줄)를 비운다.
        // 미리보기는 설정 앱의 아래 safe area 위에 놓이므로 그만큼 빼고, 빈 자리는 키보드 배경으로 채운다
        .padding(.bottom, frameInsets.bottom - bottomSafeAreaInset)
        .background(.keyboardBackground)
        // 여백은 화면 끝 기준이므로 설정 앱의 safe area(노치, iPhone Duo 세로 바)는 무시한다
        .ignoresSafeArea(.container, edges: .horizontal)
        .background {
            // 회전과 iPhone Duo 접기·펼치기로 화면이 바뀔 때 그 화면의 크기를 다시 읽는다
            GeometryReader { proxy in
                Color.clear
                    .onAppear { updateScreen() }
                    .onChange(of: proxy.size) { _ in updateScreen() }
            }
        }
    }
}

// MARK: - Private Methods

private extension PreviewKeyboardView {
    /// 실제 키보드처럼 화면 size class로 세로·가로 높이 규칙을 고른다
    var usesPortraitHeight: Bool {
        KeyboardHeightPolicy.usesPortraitHeight(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    /// 실제 키보드가 지금 화면에서 비우는 여백
    var frameInsets: KeyboardFrameInsetsPolicy.Insets {
        KeyboardFrameInsetsPolicy.insets(
            screenSize: screenSize,
            hasHomeIndicator: hasHomeIndicator,
            sideSafeAreaInset: sideSafeAreaInset
        )
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

    /// 지금 화면 크기와 설정 앱의 safe area를 읽는다
    func updateScreen() {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let windowScene = windowScenes.first(where: { $0.activationState == .foregroundActive })
                ?? windowScenes.first else { return }

        let safeAreaInsets = windowScene.keyWindow?.safeAreaInsets ?? .zero
        screenSize = windowScene.screen.bounds.size
        bottomSafeAreaInset = safeAreaInsets.bottom
        sideSafeAreaInset = max(safeAreaInsets.left, safeAreaInsets.right)
        hasHomeIndicator = bottomSafeAreaInset > 0
    }
}

// MARK: - PreviewSettingsCompactRow

/// 가로 설정 화면의 한 줄 배치: 값, 슬라이더
struct PreviewSettingsCompactRow<Value: View, SliderContent: View>: View {
    @ViewBuilder let value: () -> Value
    @ViewBuilder let slider: () -> SliderContent

    var body: some View {
        HStack(spacing: 12) {
            value()
                .monospacedDigit()
                .frame(minWidth: 40)
            slider()
        }
        // 높이를 고정하지 않는다. 가로에서 아래 안내 문구와 미리보기 사이 간격을 남기고, iOS 버전마다 다른 컨트롤 높이를 따른다
        .padding(.vertical, 2)
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
