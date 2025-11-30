//
//  PreviewKeyboardView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/30/25.
//

import SwiftUI

struct PreviewKeyboardView: View {
    
    // MARK: - Properties
    
    @Binding var keyboardHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    @Binding var needsInputModeSwitchKey: Bool
    @Binding var previewKeyboardLanguage: PreviewKeyboardLanguage
    
    let displayOneHandedMode: Bool
    
    // MARK: - Contents
    
    var body: some View {
        Picker(selection: $previewKeyboardLanguage, label: Text("키보드 언어")) {
            ForEach(PreviewKeyboardLanguage.allCases, id: \.self) {
                Text($0.rawValue)
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
                                             displayOneHandedMode: displayOneHandedMode)
            .frame(height: keyboardHeight)
            .background(.keyboardBackground)
            .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }
    
    var previewEnglishKeyboard: some View {
        PreviewEnglishKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             displayOneHandedMode: displayOneHandedMode)
            .frame(height: keyboardHeight)
            .background(.keyboardBackground)
            .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }
}

// MARK: - UISegmentedControl Extension

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}
