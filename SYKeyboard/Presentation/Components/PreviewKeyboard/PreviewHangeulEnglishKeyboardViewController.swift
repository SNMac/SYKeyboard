//
//  PreviewHangeulEnglishKeyboardViewController.swift
//  SYKeyboard
//
//  Created by 서동환 on 11/29/25.
//

import SwiftUI

import SYKeyboardCore
import HangeulEnglishKeyboardCore

/// 한영 키보드 Preview. 한글·영어는 미리보기 안의 한영 전환 키로 바꾼다
/// - 높이는 SwiftUI에서 `frame`으로 조정
/// - 한 손 키보드 너비는 `updateOneHandedWidthForPreview` 메서드로 조정
/// - 글자 열 너비 배율은 `updateLetterColumnWidthForPreview` 메서드로 조정
/// - 숫자 행 높이는 `updateNumberRowHeightForPreview` 메서드로 조정
struct PreviewHangeulEnglishKeyboardViewController: UIViewControllerRepresentable {

    // MARK: - Properties

    /// 처음 만들 때의 뷰 높이. 이후 높이는 SwiftUI `frame`이 정한다
    var keyboardHeight: CGFloat
    @Binding var oneHandedKeyboardWidth: Double
    @Binding var letterColumnWidthMultiplier: Double
    @Binding var oneHandedMode: OneHandedMode
    /// 세로 숫자 행 높이. 숫자 행이 없으면 0이고 뷰가 무시한다
    var numberRowHeight: CGFloat
    
    class Coordinator: NSObject {
        var parent: PreviewHangeulEnglishKeyboardViewController
        
        init(_ parent: PreviewHangeulEnglishKeyboardViewController) {
            self.parent = parent
        }
    }
    
    // MARK: - UIViewControllerRepresentable Methods
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> HangeulEnglishKeyboardCoreViewController {
        // Base가 viewDidLoad에서 전체 접근 허용 안내를 띄우지 않도록 view를 만들기 전에 표시한다
        HangeulEnglishKeyboardCoreViewController.isPreview = true
        let keyboard = HangeulEnglishKeyboardCoreViewController()
        keyboard.previewOneHandedMode = oneHandedMode
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screenWidth = windowScene?.screen.bounds.width ?? 0
        
        keyboard.view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: keyboardHeight)
        keyboard.view.layoutIfNeeded()
        keyboard.updateNumberRowHeightForPreview(to: numberRowHeight)
        
        keyboard.onPreviewOneHandedModeChanged = { newMode in
            DispatchQueue.main.async {
                context.coordinator.parent.oneHandedMode = newMode
            }
        }
        
        return keyboard
    }
    
    func updateUIViewController(_ uiViewController: HangeulEnglishKeyboardCoreViewController, context: Context) {
        context.coordinator.parent = self
        
        uiViewController.updateOneHandedWidthForPreview(to: oneHandedKeyboardWidth)
        uiViewController.updateLetterColumnWidthForPreview(to: letterColumnWidthMultiplier)
        uiViewController.updateNumberRowHeightForPreview(to: numberRowHeight)
        if uiViewController.previewOneHandedMode != oneHandedMode {
            uiViewController.updateOneHandedModeForPreview(to: oneHandedMode)
        }
    }
}
