//
//  EnglishKeyboardViewController.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

/// 영어 키보드 입력/UI 컨트롤러
final class EnglishKeyboardViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    private(set) var isUppercaseInput: Bool = false
    
    // MARK: - UI Components
    
    /// 영어 키보드
    private lazy var englishKeyboardView: EnglishKeyboardLayout = EnglishKeyboardView(getIsUppercaseInput: { [weak self] in return (self?.isUppercaseInput)! },
                                                                                      resetIsUppercaseInput: { [weak self] in self?.isUppercaseInput = false })
    override var primaryKeyboardView: PrimaryKeyboard { englishKeyboardView }
    
    // MARK: - Lifecycle
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        if let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput {
            englishKeyboardView.updateShiftButton(isShifted: lastBeforeCursor.isEmpty)
        } else {
            englishKeyboardView.updateShiftButton(isShifted: true)
        }
    }
    
    // MARK: - Override Methods
    
    override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        isUppercaseInput = false
    }
    
    override func updateKeyboardType() {
        switch textDocumentProxy.keyboardType {
        case .default, nil:
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
    
    override func inputKeyButton(keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        if Character(key).isUppercase { isUppercaseInput = true }
        textDocumentProxy.insertText(key)
    }
}
