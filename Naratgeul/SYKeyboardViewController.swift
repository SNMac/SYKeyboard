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
    
    // MARK: - View Properties
    private lazy var SYKeyboard: UIHostingController = {
        let SYKeyboardView = UIHostingController(
            rootView: SYKeyboardView(
                delegate: keyboardIOManager,
                keyboardHeight: keyboardHeight,
                needsInputModeSwitchKey: self.needsInputModeSwitchKey,
//                needsInputModeSwitchKey: true,
                nextKeyboardAction: #selector(self.handleInputModeList(from:with:)),
                backgroundColor: .clear
            ))
        return SYKeyboardView
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setConstraintsOfCustomKeyboard()
        bindingKeyboardManager()
    }
    
    // MARK: - Method
    private func bindingKeyboardManager() {
        keyboardIOManager.updateTextView = { [weak self] in
            guard let self = self else { return }
            
            while self.textDocumentProxy.hasText {
                self.textDocumentProxy.deleteBackward()
            }
            self.textDocumentProxy.insertText($0)
        }
        
        keyboardIOManager.dismiss = { [weak self] in
            self?.dismissKeyboard()
        }
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
