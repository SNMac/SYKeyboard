//
//  HangeulKeyboardCoreViewController.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

import SYKeyboardCore

/// 한글 키보드 입력/UI 컨트롤러
open class HangeulKeyboardCoreViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    /// 입력한 문자열 임시저장 버퍼
    private var buffer: String = ""
    /// 마지막으로 입력한 문자
    private var lastInputText: String?
    
    /// 나랏글 입력기
    private lazy var naratgeulProcessor = NaratgeulProcessor()
    /// 천지인 입력기
    private lazy var cheonjiinProcessor = CheonjiinProcessor()
    
    /// 한글 키보드 입력기
    private var processor: HangeulProcessable {
        switch UserDefaultsManager.shared.selectedHangeulKeyboard {
        case .naratgeul:
            return naratgeulProcessor
        case .cheonjiin:
            return cheonjiinProcessor
        case .dubeolsik:
            fatalError("구현이 필요한 case 입니다.")
        }
    }
    
    // MARK: - UI Components
    
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView: HangeulKeyboardLayoutProvider = NaratgeulKeyboardView()
    /// 천지인 키보드
    private lazy var cheonjiinKeyboardView: HangeulKeyboardLayoutProvider = CheonjiinKeyboardView()
    
    /// 사용자가 선택한 한글 키보드
    private var hangeulKeyboardView: HangeulKeyboardLayoutProvider {
        switch UserDefaultsManager.shared.selectedHangeulKeyboard {
        case .naratgeul:
            return naratgeulKeyboardView
        case .cheonjiin:
            return cheonjiinKeyboardView
        case .dubeolsik:
            fatalError("구현이 필요한 case 입니다.")
        }
    }
    
    open override var primaryKeyboardView: PrimaryKeyboardRepresentable { hangeulKeyboardView }
    
    // MARK: - Initializer
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        SwitchButton.debugPrimaryLanguage = "ko-KR"
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        buffer.removeAll()
        lastInputText = nil
    }
    
    open override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        buffer.removeAll()
        lastInputText = nil
    }
    
    open override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapable:
            // 지원 안함
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboard = primaryKeyboardView.keyboard
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            currentKeyboard = primaryKeyboardView.keyboard
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }
    
    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.performTextInteraction(for: button)
        if lastInputText != nil { button.playFeedback() }
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("primaryKeyList 배열이 비어있습니다.") }
        
        let beforeText = String(buffer.reversed().prefix(while: { !$0.isWhitespace }).reversed())
        let (processedText, input글자) = processor.input(글자Input: primaryKey, beforeText: beforeText)
        
        for _ in 0..<beforeText.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(processedText)
        
        buffer = processedText
        lastInputText = input글자
    }
    
    open override func insertSecondaryKeyText(from button: any TextInteractable) {
        if isPreview { return }
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        
        let beforeText = String(buffer.reversed().prefix(while: { !$0.isWhitespace }).reversed())
        let (processedText, input글자) = processor.input(글자Input: secondaryKey, beforeText: beforeText)
        
        for _ in 0..<beforeText.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(processedText)
        
        buffer = processedText
        lastInputText = input글자
    }
    
    open override func repeatInsertKeyText(from button: TextInteractable) {
        if isPreview { return }
        guard let lastInputText else {
            super.repeatTextInteractionDidPerform(button: button)
            button.isGesturing = false
            return
        }
        
        textDocumentProxy.insertText(lastInputText)
        buffer.append(lastInputText)
    }
    
    open override func insertSpaceText() {
        if isPreview { return }
        
        super.insertSpaceText()
        buffer.removeAll()
        lastInputText = nil
    }
    
    open override func insertReturnText() {
        if isPreview { return }
        
        super.insertReturnText()
        buffer.removeAll()
        lastInputText = nil
    }
    
    open override func deleteBackward() {
        if isPreview { return }
        
        if !buffer.isEmpty {
            for _ in 0..<buffer.count { textDocumentProxy.deleteBackward() }
            let text = processor.delete(beforeText: buffer)
            textDocumentProxy.insertText(text)
            
            buffer = text
        } else {
            textDocumentProxy.deleteBackward()
        }
        lastInputText = nil
    }
    
    open override func repeatDeleteBackward() {
        if isPreview { return }
        
        textDocumentProxy.deleteBackward()
        if !buffer.isEmpty { buffer.removeLast() }
        lastInputText = nil
    }
}
