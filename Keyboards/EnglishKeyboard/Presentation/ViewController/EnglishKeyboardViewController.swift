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
            currentKeyboard = .english
        case .asciiCapable:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .english
        case .numbersAndPunctuation:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            englishKeyboardView.currentEnglishKeyboardMode = .URL
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboard = .english
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            englishKeyboardView.currentEnglishKeyboardMode = .emailAddress
            symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            currentKeyboard = .english
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            englishKeyboardView.currentEnglishKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .english
        case .webSearch:
            englishKeyboardView.currentEnglishKeyboardMode = .webSearch
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboard = .english
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .english
        }
    }
}
