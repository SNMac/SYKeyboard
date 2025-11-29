//
//  PreviewKeyboardView.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/29/25.
//

import SwiftUI
import SYKeyboardCore
import HangeulKeyboardCore
import EnglishKeyboardCore

struct PreviewKeyboardView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    @Binding var keyboardHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    
    // MARK: - Internal Methods
    
    func makeUIViewController(context: Context) -> BaseKeyboardViewController {
        let hangeulKeyboard = HangeulKeyboardCoreViewController()
        hangeulKeyboard.isPreview = true
        return hangeulKeyboard
    }
    
    func updateUIViewController(_ uiViewController: BaseKeyboardViewController, context: Context) {
        uiViewController.updateSettings(height: keyboardHeight, oneHandedWidth: oneHandedKeyboardWidth)
    }
}
