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
    
    // MARK: - View Properties
    private lazy var SYKeyboard: UIHostingController = {
        let SYKeyboard = UIHostingController(
            rootView: SYKeyboardView(
                delegate: keyboardIOManager,
                keyboardHeight: keyboardHeight,
                needsInputModeSwitchKey: self.needsInputModeSwitchKey,
//                needsInputModeSwitchKey: true,
                nextKeyboardAction: #selector(self.handleInputModeList(from:with:))
            ))
        
        return SYKeyboard
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setConstraintsOfCustomKeyboard()
        bindingKeyboardManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateCursorPos()
        updateBufferSize()
    }
    
    // MARK: - Method
    private func bindingKeyboardManager() {
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
        }
        
        keyboardIOManager.deleteText = { [weak self] in
            guard let self = self else { return }
            let proxy = textDocumentProxy
            
            proxy.deleteBackward()
            
            updateCursorPos()
            updateBufferSize()
        }
        
        keyboardIOManager.dismiss = { [weak self] in
            self?.dismissKeyboard()
        }
    }
    
    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        
        keyboardIOManager.flushBuffer()
        updateCursorPos()
        updateBufferSize()
    }
    
    override func selectionWillChange(_ textInput: (any UITextInput)?) {
        super.selectionWillChange(textInput)
        
        keyboardIOManager.flushBuffer()
        updateCursorPos()
        updateBufferSize()
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
}

// MARK: - UI
extension SYKeyboardViewController {
    private func setConstraintsOfCustomKeyboard() {
        let keyboardView = SYKeyboard.view!
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChild(SYKeyboard)
        self.view.addSubview(keyboardView)
        SYKeyboard.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
