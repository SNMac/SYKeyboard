//
//  EnglishKeyboardCoreViewController.swift
//  EnglishKeyboardCore
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SYKeyboardCore

/// 영어 키보드 입력/UI 컨트롤러
///
/// `textDocumentProxy` 조작은 `BaseKeyboardViewController`의 래핑 메서드
/// (`insertText`, `deleteText`, `replaceText`)를 통해 수행하여
/// `inputBuffer`가 항상 자동 동기화됩니다.
open class EnglishKeyboardCoreViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    private let inputAdapter: EnglishKeyboardInputAdapter
    
    // MARK: - UI Components
    
    open override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        return inputAdapter.primaryKeyboardView
    }

    open override var treatsDefaultSmartQuotesAsEnabled: Bool {
        return false
    }

    open override var smartQuoteRule: KeyboardSmartQuoteRule {
        return .englishSystem
    }
    
    // MARK: - Initializer
    
    public init() {
        inputAdapter = EnglishKeyboardInputAdapter()
        SwitchButton.previewPrimaryLanguage = "en-US"
        super.init(language: "en-US")
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateShiftButton()
    }
    
    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        updateShiftButton()
    }
    
    open override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        let symbolKeyboardMode = SymbolKeyboardMode(keyboardType: textDocumentProxy.keyboardType)
        symbolKeyboardView.currentSymbolKeyboardMode = symbolKeyboardMode
        inputAdapter.updateLayout(for: textDocumentProxy.keyboardType)
        
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            currentKeyboard = .qwerty
        case .asciiCapable:
            currentKeyboard = .qwerty
        case .numbersAndPunctuation:
            currentKeyboard = .symbol
        case .URL:
            currentKeyboard = .qwerty
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            currentKeyboard = .qwerty
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            currentKeyboard = .qwerty
        case .webSearch:
            currentKeyboard = .qwerty
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            currentKeyboard = .qwerty
        }
    }
    
    open override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)
        if let primaryKey = button.type.primaryKeyList.first {
            inputAdapter.recordInsertedText(primaryKey)
        }
        if !isRepeatingInput { updateShiftButton() }
    }
    
    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("keys 배열이 비어있습니다.") }
        insertTypedText(primaryKey)
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        insertTypedText(secondaryKey)
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        insertTypedText(primaryKey)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardCoreViewController {
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {
        let isShiftButtonPressed = buttonStateController.isShiftButtonPressed
        inputAdapter.updateAutocapitalization(
            type: textDocumentProxy.autocapitalizationType ?? .none,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
            isEnabled: UserDefaultsManager.shared.isAutoCapitalizationEnabled,
            isShiftButtonPressed: isShiftButtonPressed
        )
    }
}
