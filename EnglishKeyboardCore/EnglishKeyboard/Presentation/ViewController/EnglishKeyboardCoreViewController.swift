//
//  EnglishKeyboardCoreViewController.swift
//  EnglishKeyboardCore
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SYKeyboardCore

/// 영어 키보드 입력/UI 컨트롤러
open class EnglishKeyboardCoreViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    private var isUppercaseInput: Bool = false
    
    // MARK: - UI Components
    
    /// 영어 키보드
    private lazy var englishKeyboardView: EnglishKeyboardLayoutProvider = EnglishKeyboardView(getIsUppercaseInput: { [weak self] in return self?.isUppercaseInput ?? false })
    
    open override var primaryKeyboardView: PrimaryKeyboardRepresentable { englishKeyboardView }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateShiftButton()
    }
    
    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        updateShiftButton()
    }
    
    open override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        isUppercaseInput = false
    }
    
    open override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .qwerty
        case .asciiCapable:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .qwerty
        case .numbersAndPunctuation:
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            englishKeyboardView.currentEnglishKeyboardMode = .URL
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboard = .qwerty
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
            currentKeyboard = .qwerty
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            englishKeyboardView.currentEnglishKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .qwerty
        case .webSearch:
            englishKeyboardView.currentEnglishKeyboardMode = .webSearch
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboard = .qwerty
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            englishKeyboardView.currentEnglishKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .qwerty
        }
    }
    
    open override func textInteractionDidPerform() {
        super.textInteractionDidPerform()
        updateShiftButton()
    }
    
    open override func repeatTextInteractionDidPerform() {
        super.repeatTextInteractionDidPerform()
        updateShiftButton()
    }
    
    open override func insertKeyText(from keys: [String]) {
        if isPreview { return }
        
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        
        if key.count == 1 && Character(key).isUppercase { isUppercaseInput = true }
        textDocumentProxy.insertText(key)
    }
    
    open override func repeatInsertKeyText(from keys: [String]) {
        if isPreview { return }
        
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        
        if key.count == 1 && Character(key).isUppercase { isUppercaseInput = true }
        textDocumentProxy.insertText(key)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardCoreViewController {
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {
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
                    if beforeCursor.hasOnlyWhitespaceAfterLastDot() {
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
