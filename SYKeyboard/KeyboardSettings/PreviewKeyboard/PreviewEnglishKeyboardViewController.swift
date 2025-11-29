//
//  PreviewEnglishKeyboardViewController.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/29/25.
//

import SwiftUI
import SYKeyboardCore
import EnglishKeyboardCore

/// 키보드 Preview
/// - 높이는 SwiftUI에서 `frame`으로 조정
/// - 한 손 키보드 너비는 `updateOneHandedWidthForPreview` 메서드로 조정
struct PreviewEnglishKeyboardViewController: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    @Binding var keyboardHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    
    // MARK: - Internal Methods
    
    func makeUIViewController(context: Context) -> BaseKeyboardViewController {
        let keyboard = EnglishKeyboardCoreViewController()
        keyboard.isPreview = true
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screenWidth = windowScene?.screen.bounds.width ?? 0
        
        keyboard.view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: keyboardHeight)
        keyboard.view.layoutIfNeeded()
        
        return keyboard
    }
    
    func updateUIViewController(_ uiViewController: BaseKeyboardViewController, context: Context) {
        uiViewController.updateOneHandedWidthForPreview(to: oneHandedKeyboardWidth)
    }
}
