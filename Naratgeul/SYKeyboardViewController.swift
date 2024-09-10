//
//  SYKeyboardViewController.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

class SYKeyboardViewController: UIInputViewController {
    // MARK: - Properties
    private var defaults: UserDefaults?
    private let keyboardIOManager = SYKeyboardIOManager()
    private var options: SYKeyboardOptions?
    private var cursorPos: Int = 0
    private var userLexicon: UILexicon?
    private var textReplacementHistory: [String] = []
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDefaults()
        setupIOManager()
        setupUI()
        setupUserLexicon()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCursorPos()
        updateHoegSsangAvailiable()
        Feedback.shared.prepareHaptics()
    }
    
    // MARK: - Method
    private func setupDefaults() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        DefaultValues().setupDefaults(defaults: defaults)
    }
    
    private func setupIOManager() {
        keyboardIOManager.inputText = { [weak self] in
            guard let self = self else { return }
            print("inputText()")
            
            let proxy = textDocumentProxy
            
            if defaults?.bool(forKey: "isTextReplacementEnabled") ?? true {
                if keyboardIOManager.isEditingLastCharacter {
                    if $0 == " " || $0 == "\n" {
                        let _ = attemptToReplaceCurrentWord()
                    }
                }
                proxy.insertText($0)
            } else {
                proxy.insertText($0)
            }
            
            updateCursorPos()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.deleteForInput = { [weak self] in
            guard let self = self else { return }
            print("deleteForInput()")
            
            let proxy = textDocumentProxy
            if let beforeInput = proxy.documentContextBeforeInput {
                if !beforeInput.isEmpty && keyboardIOManager.isEditingLastCharacter {
                    proxy.deleteBackward()
                }
            }
        }
        
        keyboardIOManager.deleteText = { [weak self] in
            guard let self = self else { return false }
            print("deleteText()")
            
            var isDeleted = false
            
            let proxy = textDocumentProxy
            if let beforeInput = proxy.documentContextBeforeInput {
                if !beforeInput.isEmpty {
                    isDeleted = true
                }
            }
            proxy.deleteBackward()
            
            updateCursorPos()
            updateHoegSsangAvailiable()
            
            return isDeleted
        }
        
        keyboardIOManager.inputForDelete = { [weak self] in
            guard let self = self else { return }
            print("inputForDelete()")
            
            let proxy = textDocumentProxy
            proxy.insertText($0)
            
            updateCursorPos()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.attemptRestoreWord = { [weak self] in
            guard let self = self else { return false }
            
            return attemptToRestoreReplacementWord()
        }
        
        keyboardIOManager.hoegPeriod = { [weak self] in
            guard let self = self else { return }
            
            let proxy = textDocumentProxy
            if proxy.documentContextBeforeInput?.last == " " {
                proxy.deleteBackward()
                proxy.insertText(", ")
            } else {
                proxy.insertText(", ")
            }
            
            updateCursorPos()
            keyboardIOManager.flushBuffer()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.ssangComma = { [weak self] in
            guard let self = self else { return }
            
            let proxy = textDocumentProxy
            if proxy.documentContextBeforeInput?.last == " " {
                proxy.deleteBackward()
                proxy.insertText(". ")
            } else {
                proxy.insertText(". ")
            }
            
            updateCursorPos()
            keyboardIOManager.flushBuffer()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.onlyUpdateHoegSsang = { [weak self] in
            guard let self = self else { return }
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.moveCursorToLeft = { [weak self] in
            guard let self = self else { return false }
            print("moveCursorToLeft()")
            
            let prevCurPos = cursorPos
            
            let proxy = textDocumentProxy
            proxy.adjustTextPosition(byCharacterOffset: -1)
            
            updateCursorPos()
            keyboardIOManager.flushBuffer()
            updateHoegSsangAvailiable()
            
            if cursorPos != prevCurPos {
                return true
            } else {
                return false
            }
        }
        
        keyboardIOManager.moveCursorToRight = { [weak self] in
            guard let self = self else { return false }
            print("moveCursorToRight()")
            
            let prevCurPos = cursorPos
            
            let proxy = textDocumentProxy
            proxy.adjustTextPosition(byCharacterOffset: 1)
            
            updateCursorPos()
            keyboardIOManager.flushBuffer()
            updateHoegSsangAvailiable()
            
            if cursorPos != prevCurPos {
                return true
            } else {
                return false
            }
        }
    }
    
    private func setupUI() {
        let nextKeyboardAction = #selector(handleInputModeList(from:with:))
        let options = SYKeyboardOptions(
            delegate: keyboardIOManager,
            keyboardHeight: CGFloat(defaults?.double(forKey: "keyboardHeight") ?? DefaultValues().defaultKeyboardHeight),
            longPressTime: 1.0 - (defaults?.double(forKey: "longPressSpeed") ?? DefaultValues().defaultLongPressSpeed),
            repeatTimerCycle: 0.10 - (defaults?.double(forKey: "repeatTimerSpeed") ?? DefaultValues().defaultRepeatTimerSpeed),
            colorScheme: traitCollection.userInterfaceStyle == .dark ? .dark : .light,
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            nextKeyboardAction: nextKeyboardAction
        )
        
        let SYKeyboard = UIHostingController(rootView: SYKeyboardView().environmentObject(options))
        
        self.options = options
        
        defaults?.setValue(needsInputModeSwitchKey, forKey: "needsInputModeSwitchKey")
        
        view.addSubview(SYKeyboard.view)
        addChild(SYKeyboard)
        SYKeyboard.didMove(toParent: self)
        
        SYKeyboard.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            SYKeyboard.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            SYKeyboard.view.topAnchor.constraint(equalTo: view.topAnchor),
            SYKeyboard.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            SYKeyboard.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupUserLexicon() {
        requestSupplementaryLexicon { lexicon in
            self.userLexicon = lexicon
        }
    }
    
    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        print("textDidChange()")
        
        updateCursorPos()
        keyboardIOManager.flushBuffer()
        updateHoegSsangAvailiable()
    }
    
    override func selectionWillChange(_ textInput: (any UITextInput)?) {
        super.selectionWillChange(textInput)
        print("selectionWillChange()")
        
        updateCursorPos()
    }
    
    override func selectionDidChange(_ textInput: (any UITextInput)?) {
        super.selectionDidChange(textInput)
        print("selectionDidChange()")
        
        updateCursorPos()
    }
    
    private func updateCursorPos() {
        let proxy = textDocumentProxy
        if let beforeInput = proxy.documentContextBeforeInput {
            cursorPos = beforeInput.count
        }
        print("cursorPos =", cursorPos)
    }
    
    private func updateHoegSsangAvailiable() {
        options?.isHoegSsangAvailable = keyboardIOManager.isHoegSsangAvailiable
    }
}

extension SYKeyboardViewController {
    // MARK: - Extension
    // 텍스트 대치
    func attemptToReplaceCurrentWord() -> Bool {  // 글자 입력할때 호출
        let proxy = textDocumentProxy
        guard let entries = userLexicon?.entries else { return false }
        
        if let stringBeforeCursor = proxy.documentContextBeforeInput {
            let replacementEntries = entries.filter {
                stringBeforeCursor.lowercased().contains($0.userInput.lowercased())
            }
            
            if let replacement = replacementEntries.first {
                if replacement.userInput == stringBeforeCursor.suffix(replacement.userInput.count) {
                    
                    for _ in 0..<replacement.userInput.count {
                        proxy.deleteBackward()
                    }
                    proxy.insertText(replacement.documentText)
                    
                    textReplacementHistory.append(replacement.documentText)
                    return true
                }
            }
        }
        return false
    }
    
    // 텍스트 대치 취소
    func attemptToRestoreReplacementWord() -> Bool {  // 글자 지울때 호출
        let proxy = textDocumentProxy
        guard let entries = userLexicon?.entries else { return false }
        
        if let stringBeforeCursor = proxy.documentContextBeforeInput {
            let replacementEntries = entries.filter {
                textReplacementHistory.contains($0.documentText)
            }
            
            if let replacement = replacementEntries.first {
                if replacement.documentText == stringBeforeCursor.suffix(replacement.documentText.count) {
                    for _ in 0..<replacement.documentText.count {
                        proxy.deleteBackward()
                    }
                    proxy.insertText(replacement.userInput)
                    
                    if let historyIndex = textReplacementHistory.firstIndex(of: replacement.documentText) {
                        textReplacementHistory.remove(at: historyIndex)
                        return true
                    }
                }
            }
        }
        return false
    }
}
