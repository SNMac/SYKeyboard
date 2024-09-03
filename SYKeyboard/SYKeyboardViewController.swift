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
    private var cursorPos: Int = 0
    private var options: SYKeyboardOptions?
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDefaults()
        setupIOManager()
        setupUI()
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
        
        // UserDefaults 값이 존재하는지 확인하고, 없으면 새로 만듬
        if defaults?.object(forKey: "isSoundFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isSoundFeedbackEnabled")
        }
        
        if defaults?.object(forKey: "isHapticFeedbackEnabled") == nil {
            defaults?.setValue(true, forKey: "isHapticFeedbackEnabled")
        }
        
        if defaults?.object(forKey: "isAutocompleteEnabled") == nil {
            defaults?.setValue(true, forKey: "isAutocompleteEnabled")
        }
        
        if defaults?.object(forKey: "keyboardHeight") == nil {
            defaults?.setValue(240.0, forKey: "keyboardHeight")
        }
        
        if defaults?.object(forKey: "tempKeyboardHeight") == nil {
            defaults?.setValue(Double(GlobalData().defaultHeight), forKey: "tempKeyboardHeight")
        }
    }
    
    private func setupIOManager() {
        keyboardIOManager.inputText = { [weak self] in
            guard let self = self else { return }
            print("inputText()")
            
            let proxy = textDocumentProxy
            proxy.insertText($0)
            
            updateCursorPos()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.deleteForInput = { [weak self] in
            guard let self = self else { return }
            
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
            keyboardHeight: CGFloat(defaults?.integer(forKey: "keyboardHeight") ?? GlobalData().defaultHeight),
            colorScheme: traitCollection.userInterfaceStyle == .dark ? .dark : .light,
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            nextKeyboardAction: nextKeyboardAction
        )
        
        let SYKeyboard = UIHostingController(rootView: SYKeyboardView().environmentObject(options))
        
        self.options = options
        
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
