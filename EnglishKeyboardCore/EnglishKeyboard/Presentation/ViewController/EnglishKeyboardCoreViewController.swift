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
    
    // MARK: - Initializer
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        SwitchButton.previewPrimaryLanguage = "en-US"
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
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
    
    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("keys 배열이 비어있습니다.") }
        if primaryKey.count == 1 && Character(primaryKey).isUppercase { isUppercaseInput = true }
        textDocumentProxy.insertText(primaryKey)
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        textDocumentProxy.insertText(secondaryKey)
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        if primaryKey.count == 1 && Character(primaryKey).isUppercase { isUppercaseInput = true }
        textDocumentProxy.insertText(primaryKey)
    }
}

// MARK: - Private Methods

private extension EnglishKeyboardCoreViewController {
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {
        // Shift 버튼이 눌려있는 경우 실행 X
        guard !buttonStateController.isShiftButtonPressed else { return }
        
        var shouldShift: Bool = false
        if UserDefaultsManager.shared.isAutoCapitalizationEnabled {
            switch textDocumentProxy.autocapitalizationType {
            case .allCharacters:
                shouldShift = true
            case .sentences:
                shouldShift = textDocumentProxy.documentContextBeforeInput?.hasOnlyWhitespaceAfterLastDot() ?? true
            case .words:
                shouldShift = textDocumentProxy.documentContextBeforeInput?.endsWithWhitespace() ?? true
            default:
                break
            }
        }
        
        primaryKeyboardView.updateShiftButton(isShifted: shouldShift)
        isUppercaseInput = false
    }
}
