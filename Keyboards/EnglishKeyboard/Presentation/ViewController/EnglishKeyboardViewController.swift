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
    private lazy var englishKeyboardView: EnglishKeyboardLayout = EnglishKeyboardView(getIsUppercaseInput: { [weak self] in return (self?.isUppercaseInput)! })
    override var primaryKeyboardView: PrimaryKeyboard { englishKeyboardView }
    
    // MARK: - Override Methods
    
    override func updateShiftButton() {
        // Shift 버튼이 눌려있는 경우 실행 X
        guard !buttonStateController.isShiftButtonPressed else { return }
        
        if UserDefaultsManager.shared.isAutoCapitalizationEnabled {
            switch textDocumentProxy.autocapitalizationType {
            case .words:
                if let beforeCursor = textDocumentProxy.documentContextBeforeInput {
                    if beforeCursor.endsWithWhitespace() {
                        primaryKeyboardView.updateShiftButton(isShifted: true)
                    } else {
                        primaryKeyboardView.updateShiftButton(isShifted: false)
                    }
                } else {
                    primaryKeyboardView.updateShiftButton(isShifted: true)
                }
            case .sentences:
                if let beforeCursor = textDocumentProxy.documentContextBeforeInput {
                    if beforeCursor.hasOnlyWhitespaceFromLastDot() {
                        primaryKeyboardView.updateShiftButton(isShifted: true)
                    } else {
                        primaryKeyboardView.updateShiftButton(isShifted: false)
                    }
                } else {
                    primaryKeyboardView.updateShiftButton(isShifted: true)
                }
            case .allCharacters:
                primaryKeyboardView.updateShiftButton(isShifted: true)
            default:
                primaryKeyboardView.updateShiftButton(isShifted: false)
            }
        } else {
            primaryKeyboardView.updateShiftButton(isShifted: false)
        }
        
        isUppercaseInput = false
    }
    
    override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        isUppercaseInput = false
    }
    
    override func updateKeyboardType(oldKeyboardType: UIKeyboardType?) {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
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
        if key.count == 1 && Character(key).isUppercase {
            isUppercaseInput = true
        }
        textDocumentProxy.insertText(key)
    }
}
