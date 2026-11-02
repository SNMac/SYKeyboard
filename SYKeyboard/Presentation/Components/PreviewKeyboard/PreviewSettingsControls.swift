//
//  PreviewSettingsControls.swift
//  SYKeyboard
//
//  Created by Claude on 11/1/26.
//

import SwiftUI

// MARK: - PreviewSettingsControls

/// 미리보기 설정 화면에서 미리보기 위에 놓는 컨트롤.
/// 높이가 모자란 화면(가로)에서는 `compact` 배치를 쓰고, 미리보기를 뺀 높이에 다 들어가지 않으면 이 부분만 스크롤한다
struct PreviewSettingsControls<Compact: View, Regular: View>: View {

    // MARK: - Properties

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @ViewBuilder let compact: () -> Compact
    @ViewBuilder let regular: () -> Regular

    // MARK: - Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            controls
            ScrollView {
                controls
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if verticalSizeClass == .compact {
            compact()
        } else {
            regular()
        }
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
