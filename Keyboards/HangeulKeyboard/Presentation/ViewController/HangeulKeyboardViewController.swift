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
    
    override func updateKeyboardType(oldKeyboardType: UIKeyboardType?) {
        guard self.textDocumentProxy.keyboardType != oldKeyboardType else { return }
        switch self.textDocumentProxy.keyboardType {
        case .default, nil:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .hangeul
        case .asciiCapable:
            // 지원 안함
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .hangeul
        case .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .symbol
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .URL
            self.currentKeyboard = .hangeul
        case .numberPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            // 항상 iOS 시스템 키보드 표시됨
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            self.currentKeyboard = .hangeul
        case .decimalPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            self.currentKeyboard = .tenKey
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .hangeul
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            self.currentKeyboard = .hangeul
        case .asciiCapableNumberPad:
            self.tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            self.currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            self.symbolKeyboardView.currentSymbolKeyboardMode = .default
            self.currentKeyboard = .hangeul
        }
    }
    
    override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.performTextInteraction(for: button)
        if lastInputText != nil { button.playFeedback() }
    }
    
    override func insertKeyText(from keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        
        let beforeText = String(buffer.reversed().prefix(while: { !$0.isWhitespace }).reversed())
        let (processedText, input글자) = processor.input(글자Input: key, beforeText: beforeText)
        
        for _ in 0..<beforeText.count { self.textDocumentProxy.deleteBackward() }
        buffer = processedText
        self.lastInputText = input글자
        self.textDocumentProxy.insertText(processedText)
    }
    
    override func repeatInsertKeyText(from keys: [String]) {
        guard let lastInputText else { return }
        textDocumentProxy.insertText(lastInputText)
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
            for _ in 0..<buffer.count { self.textDocumentProxy.deleteBackward() }
            let text = processor.delete(beforeText: buffer)
            self.textDocumentProxy.insertText(text)
            
            buffer = text
        } else {
            self.textDocumentProxy.deleteBackward()
        }
        self.lastInputText = nil
    }
}
