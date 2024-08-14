//
//  SYKeyboardViewController.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

class SYKeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    private let keyboardIOManager = SYKeyboardIOManager()
    private let keyboardHeight: CGFloat = 260
    private var cursorPos: Int = 0
    private var bufferSize: Int = 0
    private var options: SYKeyboardOptions?
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupIOManager()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCursorPos()
        updateBufferSize()
        updateHoegSsangAvailiable()
        Feedback.shared.prepareHaptics()
    }
    
    // MARK: - Method
    private func setupIOManager() {
        keyboardIOManager.inputText = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            if keyboardIOManager.isEditingLastCharacter {
                for _ in 0..<bufferSize {
                    proxy.deleteBackward()
                }
            }
            proxy.insertText($0)
            
            updateCursorPos()
            updateBufferSize()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.deleteText = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            proxy.deleteBackward()
            
            updateCursorPos()
            updateBufferSize()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.hoegPeriod = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            if proxy.documentContextBeforeInput?.last == " " {
                proxy.deleteBackward()
                proxy.insertText(". ")
            } else if !keyboardIOManager.isEditingLastCharacter {
                proxy.insertText(". ")
            }
            
            updateCursorPos()
            updateBufferSize()
            updateHoegSsangAvailiable()
        }
        
        keyboardIOManager.ssangComma = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            if proxy.documentContextBeforeInput?.last == " " {
                proxy.deleteBackward()
                proxy.insertText(", ")
            } else if !keyboardIOManager.isEditingLastCharacter {
                proxy.insertText(", ")
            }
            
            updateCursorPos()
            updateBufferSize()
            updateHoegSsangAvailiable()
        }
    }
    
    private func setupUI() {
        let nextKeyboardAction = #selector(handleInputModeList(from:with:))
        let options = SYKeyboardOptions(
            delegate: keyboardIOManager,
            keyboardHeight: keyboardHeight,
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
    
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        
        keyboardIOManager.flushBuffer()
        updateCursorPos()
        updateBufferSize()
        updateHoegSsangAvailiable()
    }
    
    override func selectionWillChange(_ textInput: (any UITextInput)?) {
        super.selectionWillChange(textInput)
        
        keyboardIOManager.flushBuffer()
        updateCursorPos()
        updateBufferSize()
        updateHoegSsangAvailiable()
    }
    
    private func updateCursorPos() {
        let proxy = textDocumentProxy
        if let documentContext = proxy.documentContextBeforeInput {
            cursorPos = documentContext.count
        }
        print("cursorPos) ", cursorPos)
    }
    
    private func updateBufferSize() {
        bufferSize = keyboardIOManager.getBufferSize()
        print("bufferSize) ", bufferSize)
    }
    
    private func updateHoegSsangAvailiable() {
        options?.isHoegSsangAvailable = keyboardIOManager.isHoegSsangAvailiable
    }
}
