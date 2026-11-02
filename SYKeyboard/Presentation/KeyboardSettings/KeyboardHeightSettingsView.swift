//
//  HeightSettingsView.swift.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/3/24.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct KeyboardHeightSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaultsManager.shared.storage)
    private var keyboardHeight = DefaultValues.keyboardHeight
    
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaultsManager.shared.storage)
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth

    @AppStorage(UserDefaultsKeys.letterColumnWidthMultiplier, store: UserDefaultsManager.shared.storage)
    private var letterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier

    
    @State private var previewOneHandedMode: OneHandedMode = .center
    @State private var tempKeyboardHeight: Double = DefaultValues.keyboardHeight
    
    // MARK: - Content
    
    var body: some View {
        VStack {
            keyboardHeightSettings
            
            // 가로에서 안내 문구 두 줄을 넣을 높이를 확보하려고 최소 높이를 두지 않는다. 세로에서는 늘어나므로 영향이 없다
            Spacer(minLength: 0)
            
            PreviewKeyboardView(keyboardSettingsHeight: tempKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempKeyboardHeight = keyboardHeight
        }.requestReviewOnDetailSettingsReturn()
    }
}

// MARK: - UI Components

private extension KeyboardHeightSettingsView {
    var heightValueText: Text {
        Text("\(Int(tempKeyboardHeight) - (Int(DefaultValues.keyboardHeight) - 100))")
    }

    var heightSlider: some View {
        Slider(value: $tempKeyboardHeight, in: KeyboardLayoutFigure.keyboardHeightRange, step: 1)
    }

    var heightNotice: some View {
        Group {
            if KeyboardHeightPolicy.usesPortraitHeight(horizontalSizeClass: UIUserInterfaceSizeClass(horizontalSizeClass),
                                                       verticalSizeClass: UIUserInterfaceSizeClass(verticalSizeClass)) {
                Text("가로 모드에선 iOS 기본 키보드와 동일한 높이로 표시됩니다.\n(iPhone Duo의 안쪽 화면 제외)")
            } else {
                // 가로 높이 규칙에서는 슬라이더를 움직여도 미리보기가 변하지 않는다
                Text("가로 모드에서는 높이 설정이 미리보기에 반영되지 않습니다.\n세로 모드와 iPhone Duo의 안쪽 화면에 적용됩니다.")
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
    }

    var keyboardHeightSettings: some View {
        PreviewSettingsControls {
            // 가로는 높이가 모자라 값과 슬라이더를 한 줄에 두고, 안내 문구와 붙어 보이지 않게 띄운다
            VStack(spacing: 8) {
                PreviewSettingsCompactRow {
                    heightValueText
                } slider: {
                    heightSlider
                }
                heightNotice
                    .padding(.horizontal)
            }
        } regular: {
            VStack {
                heightValueText
                    .padding(.top)
                    .padding(.horizontal)
                heightSlider
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                heightNotice
                    .padding()
            }
        }
        .navigationTitle("키보드 높이")
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
                    tempKeyboardHeight = DefaultValues.keyboardHeight
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    keyboardHeight = tempKeyboardHeight
                    Analytics.setUserProperty(String(format: "%.1f", keyboardHeight),
                                              forName: "pref_keyboard_height")
                    Analytics.logEvent("keyboard_height", parameters: [
                        "view": "KeyboardHeightSettingsView",
                        "value": keyboardHeight
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
        KeyboardHeightSettingsView()
    }
}
