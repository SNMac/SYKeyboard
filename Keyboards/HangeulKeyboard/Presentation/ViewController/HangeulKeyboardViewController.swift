//
//  HangeulKeyboardViewController.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

/// 한글 키보드 입력/UI 컨트롤러
final class HangeulKeyboardViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    /// 입력한 문자열 임시저장 버퍼
    private var buffer: String = ""
    /// 마지막으로 입력한 문자
    private var lastInputText: String?
    
    /// 한글 키보드 입력기
    private lazy var processor: HangeulProcessable = NaratgeulProcessor()
    
    // MARK: - UI Components
    
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView: HangeulKeyboardLayoutProvider = NaratgeulKeyboardView(keyboard: .naratgeul)
    /// 천지인 키보드
    private lazy var cheonjiinKeyboardView: HangeulKeyboardLayoutProvider = CheonjiinKeyboardView(keyboard: .cheonjiin)
    
    /// 사용자가 선택한 한글 키보드
    private var hangeulKeyboardView: HangeulKeyboardLayoutProvider {
        switch UserDefaultsManager.shared.selectedHangeulKeyboard {
        case .naratgeul:
            return naratgeulKeyboardView
        case .cheonjiin:
            return cheonjiinKeyboardView
        }
    }
    
    override var primaryKeyboardView: PrimaryKeyboardRepresentable { hangeulKeyboardView }
    
    // MARK: - Override Methods
    
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        buffer.removeAll()
        lastInputText = nil
    }
    
    override func updateShowingKeyboard() {
        super.updateShowingKeyboard()
        buffer.removeAll()
        lastInputText = nil
    }
    
    override func updateKeyboardType() {
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
    
    override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.performTextInteraction(for: button)
        if lastInputText != nil { button.playFeedback() }
    }
    
    override func insertKeyText(from keys: [String]) {
        guard let key = keys.first else { fatalError("keys 배열이 비어있습니다.") }
        
        let beforeText = String(buffer.reversed().prefix(while: { !$0.isWhitespace }).reversed())
        let (processedText, input글자) = processor.input(글자Input: key, beforeText: beforeText)
        
        for _ in 0..<beforeText.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(processedText)
        
        buffer = processedText
        lastInputText = input글자
    }
    
    override func repeatInsertKeyText(from keys: [String]) {
        guard let lastInputText else { return }
        textDocumentProxy.insertText(lastInputText)
        
        buffer.append(lastInputText)
    }
    
    override func insertSpaceText() {
        super.insertSpaceText()
        buffer.removeAll()
        lastInputText = nil
    }
    
    override func insertReturnText() {
        super.insertReturnText()
        buffer.removeAll()
        lastInputText = nil
    }
    
    override func deleteBackward() {
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
    
    override func repeatDeleteBackward() {
        textDocumentProxy.deleteBackward()
        if !buffer.isEmpty { buffer.removeLast() }
        lastInputText = nil
    }
}
