//
//  NaratgeulViewController.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

class NaratgeulViewController: UIInputViewController {
    // MARK: - Properties
    private var defaults: UserDefaults?
    private let ioManager = NaratgeulIOManager()
    private var state: NaratgeulState?
    private var keyboardType: UIKeyboardType = .default
    private var cursorPos: Int = 0
    
    private var userLexicon: UILexicon?
    private var textReplacementHistory: [String] = []
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDefaults()
        setupIOManager()
        setupUI()
        Task {
            await setupUserLexicon()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCursorPos()
        updateHoegSsangAvailiableToOptions()
        Feedback.shared.prepareHaptic()
    }
    
    // MARK: - Method
    private func setupDefaults() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
        GlobalValues.setupDefaults(defaults)
    }
    
    private func setupIOManager() {
        ioManager.inputText = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            if defaults?.bool(forKey: "isTextReplacementEnabled") ?? true {
                if ioManager.isEditingLastCharacter {
                    if $0 == " " || $0 == "\n" {
                        let _ = attemptToReplaceCurrentWord()
                    }
                }
                proxy.insertText($0)
            } else {
                proxy.insertText($0)
            }
            
            updateCursorPos()
            updateHoegSsangAvailiableToOptions()
        }
        
        ioManager.deleteForInput = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            if let beforeInput = proxy.documentContextBeforeInput {
                if !beforeInput.isEmpty && ioManager.isEditingLastCharacter {
                    proxy.deleteBackward()
                }
            }
        }
        
        ioManager.deleteText = { [weak self] in
            guard let self = self else { return false }
            var isDeleted = false
            
            let proxy = textDocumentProxy
            if let beforeInput = proxy.documentContextBeforeInput {
                if !beforeInput.isEmpty {
                    isDeleted = true
                }
            }
            proxy.deleteBackward()
            
            updateCursorPos()
            updateHoegSsangAvailiableToOptions()
            
            return isDeleted
        }
        
        ioManager.inputForDelete = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            proxy.insertText($0)
            
            updateCursorPos()
            updateHoegSsangAvailiableToOptions()
        }
        
        ioManager.attemptRestoreWord = { [weak self] in
            guard let self = self else { return false }
            return attemptToRestoreReplacementWord()
        }
        
        ioManager.onlyUpdateHoegSsang = { [weak self] in
            guard let self = self else { return }
            updateHoegSsangAvailiableToOptions()
        }
        
        ioManager.moveCursorToLeft = { [weak self] in
            guard let self = self else { return false }
            print("moveCursorToLeft()")
            
            let prevCurPos = cursorPos
            
            let proxy = textDocumentProxy
            proxy.adjustTextPosition(byCharacterOffset: -1)
            
            updateCursorPos()
            ioManager.flushBuffer()
            updateHoegSsangAvailiableToOptions()
            
            if cursorPos != prevCurPos {
                return true
            } else {
                return false
            }
        }
        
        ioManager.moveCursorToRight = { [weak self] in
            guard let self = self else { return false }
            print("moveCursorToRight()")
            
            let prevCurPos = cursorPos
            
            let proxy = textDocumentProxy
            proxy.adjustTextPosition(byCharacterOffset: 1)
            
            updateCursorPos()
            ioManager.flushBuffer()
            updateHoegSsangAvailiableToOptions()
            
            if cursorPos != prevCurPos {
                return true
            } else {
                return false
            }
        }
    }
    
    private func setupUI() {
        let nextKeyboardAction = #selector(handleInputModeList(from:with:))
        
        let options = NaratgeulState(
            delegate: ioManager,
            keyboardHeight: CGFloat(defaults?.double(forKey: "keyboardHeight") ?? GlobalValues.defaultKeyboardHeight),
            oneHandWidth: CGFloat(defaults?.double(forKey: "oneHandWidth") ?? GlobalValues.defaultOneHandWidth),
            longPressTime: 1.0 - (defaults?.double(forKey: "longPressSpeed") ?? GlobalValues.defaultLongPressSpeed),
            repeatTimerCycle: 0.10 - (defaults?.double(forKey: "repeatTimerSpeed") ?? GlobalValues.defaultRepeatTimerSpeed),
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            nextKeyboardAction: nextKeyboardAction
        )
        
        let SYKeyboard = UIHostingController(rootView: NaratgeulView().environmentObject(options))
        SYKeyboard.view.backgroundColor = .clear
        
        self.state = options
        
        defaults?.setValue(needsInputModeSwitchKey, forKey: "needsInputModeSwitchKey")
        
        view.addSubview(SYKeyboard.view)
        SYKeyboard.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            SYKeyboard.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            SYKeyboard.view.topAnchor.constraint(equalTo: view.topAnchor),
            SYKeyboard.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            SYKeyboard.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        addChild(SYKeyboard)
        SYKeyboard.didMove(toParent: self)
    }
        
    private func setupUserLexicon() async {
        userLexicon = await requestSupplementaryLexicon()
    }
    
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        print("textWillChange()")
        
        updateKeyboardTypeToOptions()
        updateReturnButtonLabelToOptions()
    }
    
    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        print("textDidChange()")
        
        updateCursorPos()
        ioManager.flushBuffer()
        updateHoegSsangAvailiableToOptions()
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
        } else {
            cursorPos = 0
        }
    }
    
    private func updateHoegSsangAvailiableToOptions() {
        state?.isHoegSsangAvailable = ioManager.isHoegSsangAvailiable
    }
    
    private func updateKeyboardTypeToOptions() {
        let proxy = textDocumentProxy
        let keyboardType = proxy.keyboardType
        switch keyboardType {
        case .default:
            state?.currentKeyboardType = ._default
        case .numbersAndPunctuation:
            state?.currentKeyboardType = .numbersAndPunctuation
            state?.currentInputType = .symbol
        case .URL:
            state?.currentKeyboardType = .URL
        case .numberPad:
            state?.currentKeyboardType = .numberPad
            state?.currentInputType = .number
        case .emailAddress:
            state?.currentKeyboardType = .emailAddress
        case .twitter:
            state?.currentKeyboardType = .twitter
        case .webSearch:
            state?.currentKeyboardType = .webSearch
        case .asciiCapableNumberPad:
            state?.currentKeyboardType = .asciiCapableNumberPad
            state?.currentInputType = .number
        default:
            state?.currentKeyboardType = ._default
        }
    }
    
    private func updateReturnButtonLabelToOptions() {
        let proxy = textDocumentProxy
        let returnKeyType = proxy.returnKeyType
        let returnButtonType: ReturnButtonType
        switch returnKeyType {
        case .go:
            returnButtonType = .go
        case .google:
            returnButtonType = .search
        case .join:
            returnButtonType = .join
        case .next:
            returnButtonType = .next
        case .route:
            returnButtonType = .route
        case .search:
            returnButtonType = .search
        case .send:
            returnButtonType = .send
        case .yahoo:
            returnButtonType = .search
        case .done:
            returnButtonType = .done
        case .emergencyCall:
            returnButtonType = .emergencyCall
        case .continue:
            returnButtonType = ._continue
        default:
            returnButtonType = ._default
        }
        state?.returnButtonType = returnButtonType
    }
}

// MARK: - Extension
extension NaratgeulViewController {
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
