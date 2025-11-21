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
    private lazy var englishKeyboardView: EnglishKeyboardLayoutProvider = EnglishKeyboardView(getIsUppercaseInput: { [weak self] in return (self?.isUppercaseInput)! })
    
    override var primaryKeyboardView: PrimaryKeyboardRepresentable { englishKeyboardView }
    
    // MARK: - Override Methods
    
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateShiftButton()
    }
    
    override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        updateShiftButton()
    }
    
    override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        isUppercaseInput = false
    }
    
    override func updateKeyboardType() {
        guard self.textDocumentProxy.keyboardType != self.oldKeyboardType else { return }
        switch self.textDocumentProxy.keyboardType {
        case .default, nil:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .english
        case .asciiCapable:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .english
        case .numbersAndPunctuation:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .symbol
        case .URL:
            englishKeyboardView.currentEnglishKeyboardMode = .URL
            self.symbolKeyboardView.currentSymbolKeyboardMode = .URL
            self.currentKeyboard = .english
        case .numberPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        case .emailAddress:
            englishKeyboardView.currentEnglishKeyboardMode = .emailAddress
            self.symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            self.currentKeyboard = .english
        case .decimalPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            self.currentKeyboard = .tenKey
        case .twitter:
            englishKeyboardView.currentEnglishKeyboardMode = .twitter
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .english
        case .webSearch:
            englishKeyboardView.currentEnglishKeyboardMode = .webSearch
            self.symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            self.currentKeyboard = .english
        case .asciiCapableNumberPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            englishKeyboardView.currentEnglishKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .english
        }
    }
    
    override func textInteractionDidPerform() {
        super.textInteractionDidPerform()
        updateShiftButton()
    }
    
    override func repeatTextInteractionDidPerform() {
        super.repeatTextInteractionDidPerform()
        updateShiftButton()
    }
    
    override func insertKeyText(from keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        
        if key.count == 1 && Character(key).isUppercase { isUppercaseInput = true }
        self.textDocumentProxy.insertText(key)
    }
    
    override func repeatInsertKeyText(from keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        
        if key.count == 1 && Character(key).isUppercase { isUppercaseInput = true }
        self.textDocumentProxy.insertText(key)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardViewController {
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {
        // Shift 버튼이 눌려있는 경우 실행 X
        guard !self.buttonStateController.isShiftButtonPressed else { return }
        
        if UserDefaultsManager.shared.isAutoCapitalizationEnabled {
            switch self.textDocumentProxy.autocapitalizationType {
            case .words:
                if let beforeCursor = self.textDocumentProxy.documentContextBeforeInput {
                    if beforeCursor.endsWithWhitespace() {
                        primaryKeyboardView.updateShiftButton(isShifted: true)
                    } else {
                        primaryKeyboardView.updateShiftButton(isShifted: false)
                    }
                } else {
                    primaryKeyboardView.updateShiftButton(isShifted: true)
                }
            case .sentences:
                if let beforeCursor = self.textDocumentProxy.documentContextBeforeInput {
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
}
