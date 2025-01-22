//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import SnapKit

class KeyboardViewController: UIInputViewController {
    private var defaults: UserDefaults?
    
    private let ioManager = KeyboardIOManager()
    private var state: KeyboardState?
    private var cursorPos: Int = 0
    private var userLexicon: UILexicon?
    private var textReplacementHistory: [String] = []
    
    private let requestFullAccessView = RequestFullAccessOverlayView()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaults()
        setupKeyboard()
        setupUI()
        if !hasFullAccess {
            setupRequestFullAccessUI()
        }
        loadTextReplacement()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateScreenWidthToDefaults()
        updateCursorPos()
        updateHoegSsangAvailiableToOptions()
        updateKeyboardTypeToOptions()
        updateReturnButtonLabelToOptions()
        Feedback.shared.prepareHaptic()
    }
    
    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        updateCursorPos()
        ioManager.flushBuffer()
        updateHoegSsangAvailiableToOptions()
    }
    
    override func selectionWillChange(_ textInput: (any UITextInput)?) {
        super.selectionWillChange(textInput)
        updateCursorPos()
    }
    
    override func selectionDidChange(_ textInput: (any UITextInput)?) {
        super.selectionDidChange(textInput)
        updateCursorPos()
    }
    
    // MARK: - Keyboard UI Methods
    private func setupUI() {
        let nextKeyboardAction = #selector(handleInputModeList(from:with:))
        let state = KeyboardState(
            delegate: ioManager,
            keyboardHeight: CGFloat(defaults?.double(forKey: "keyboardHeight") ?? GlobalValues.defaultKeyboardHeight),
            oneHandedKeyboardWidth: CGFloat(defaults?.double(forKey: "oneHandedKeyboardWidth") ?? GlobalValues.defaultOneHandedKeyboardWidth),
            longPressTime: 1.0 - (defaults?.double(forKey: "longPressSpeed") ?? GlobalValues.defaultLongPressSpeed),
            repeatTimerCycle: 0.10 - (defaults?.double(forKey: "repeatTimerSpeed") ?? GlobalValues.defaultRepeatTimerSpeed),
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            nextKeyboardAction: nextKeyboardAction
        )
        self.state = state
        
        let keyboard = UIHostingController(rootView: KeyboardView().environmentObject(state))
        keyboard.view.backgroundColor = .clear
        if hasFullAccess {
            keyboard.view.isUserInteractionEnabled = true
        } else {
            keyboard.view.isUserInteractionEnabled = false
        }
        
        setViewHierarchy(keyboardView: keyboard.view)
        setConstraints(keyboardView: keyboard.view)
        addChild(keyboard)
        keyboard.didMove(toParent: self)
    }
    
    private func setViewHierarchy(keyboardView: UIView) {
        self.view.addSubview(keyboardView)
    }
    
    private func setConstraints(keyboardView: UIView) {
        keyboardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Keyboard Setup Methods
    private func setupKeyboard() {
        configureIOManager()
        loadTextReplacement()
    }
    
    private func configureIOManager() {
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
    
    private func loadTextReplacement() {
        Task {
            await userLexicon = requestSupplementaryLexicon()
        }
    }
    
    // MARK: - Property Update Methods
    private func updateCursorPos() {
        let proxy = textDocumentProxy
        if let beforeInput = proxy.documentContextBeforeInput {
            cursorPos = beforeInput.count
        } else {
            cursorPos = 0
        }
    }
        
    // MARK: - UserDefaults Update Methods
    private func setupDefaults() {
        defaults = UserDefaults(suiteName: GlobalValues.groupBundleID)
        GlobalValues.setupDefaults(defaults)
        defaults?.set(needsInputModeSwitchKey, forKey: "needsInputModeSwitchKey")
    }
    
    private func updateScreenWidthToDefaults() {
        let screenWidth = view.window?.windowScene?.screen.bounds.width
        defaults?.set(screenWidth, forKey: "screenWidth")
    }
    
    // MARK: - KeyboardState Update Methods
    private func updateHoegSsangAvailiableToOptions() {
        state?.isHoegSsangAvailable = ioManager.isHoegSsangAvailiable
    }
    
    private func updateKeyboardTypeToOptions() {
        let proxy = textDocumentProxy
        switch proxy.keyboardType {
        case .default:
            state?.currentUIKeyboardType = .default
        case .numbersAndPunctuation:
            state?.currentUIKeyboardType = .numbersAndPunctuation
            state?.currentKeyboard = .symbol
        case .URL:
            state?.currentUIKeyboardType = .URL
        case .numberPad:
            state?.currentUIKeyboardType = .numberPad
            state?.currentKeyboard = .numeric
        case .emailAddress:
            state?.currentUIKeyboardType = .emailAddress
        case .twitter:
            state?.currentUIKeyboardType = .twitter
        case .webSearch:
            state?.currentUIKeyboardType = .webSearch
        case .asciiCapableNumberPad:
            state?.currentUIKeyboardType = .asciiCapableNumberPad
            state?.currentKeyboard = .numeric
        default:
            state?.currentUIKeyboardType = .default
        }
    }
    
    private func updateReturnButtonLabelToOptions() {
        let proxy = textDocumentProxy
        switch proxy.returnKeyType {
        case .go:
            state?.returnButtonType = .go
        case .google:
            state?.returnButtonType = .search
        case .join:
            state?.returnButtonType = .join
        case .next:
            state?.returnButtonType = .next
        case .route:
            state?.returnButtonType = .route
        case .search:
            state?.returnButtonType = .search
        case .send:
            state?.returnButtonType = .send
        case .yahoo:
            state?.returnButtonType = .search
        case .done:
            state?.returnButtonType = .done
        case .emergencyCall:
            state?.returnButtonType = .emergencyCall
        case .continue:
            state?.returnButtonType = .continue
        default:
            state?.returnButtonType = .default
        }
    }
}

// MARK: - Text Replacement Methods
private extension KeyboardViewController {
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

// MARK: - Request Full Access Methods
private extension KeyboardViewController {
    func setupRequestFullAccessUI() {
        requestFullAccessView.goToSettingsButton.addAction(UIAction(handler: { _ in
            self.redirectToSettings()
        }), for: .touchUpInside)
        
        self.view.addSubview(requestFullAccessView)
        
        requestFullAccessView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func redirectToSettings() {
        let url = "sykeyboard://"
        guard let urlScheme = URL(string: url) else {
            return
        }
        
        openURL(urlScheme)
    }
    
    @discardableResult
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(openURL(_:)), with: url) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }
}
