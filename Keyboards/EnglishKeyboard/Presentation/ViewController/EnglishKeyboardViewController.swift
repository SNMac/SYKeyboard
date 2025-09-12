//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: BaseKeyboardViewController {
    
    // MARK: - UI Components
    
    /// 영어 키보드
    private lazy var englishKeyboardView: EnglishKeyboardLayout = EnglishKeyboardView()
    override var primaryKeyboardView: PrimaryKeyboard { englishKeyboardView }
    
    // MARK: - Override Methods
    
    override func updateKeyboardType() {
        switch textDocumentProxy.keyboardType {
        case .default, .none:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboardLayout = .english
        case .asciiCapable:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboardLayout = .english
        case .numbersAndPunctuation:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboardLayout = .symbol
        case .URL:
            englishKeyboardView.currentEnglishKeyboardMode = .URL
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboardLayout = .english
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboardLayout = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboardLayout = .tenKey
        case .emailAddress:
            englishKeyboardView.currentEnglishKeyboardMode = .emailAddress
            symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            currentKeyboardLayout = .english
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboardLayout = .tenKey
        case .twitter:
            englishKeyboardView.currentEnglishKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboardLayout = .english
        case .webSearch:
            englishKeyboardView.currentEnglishKeyboardMode = .webSearch
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboardLayout = .english
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboardLayout = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboardLayout = .english
        }
    }
}
