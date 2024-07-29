//
//  KeyboardViewController.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI

class SYKeyboardViewController: UIInputViewController {

    private let keyboardHeight: CGFloat = 260
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keyboardViewController = UIHostingController(
            rootView: NaratgeulKeyboardView(
                insertText: { [weak self] text in
                    guard let self else { return }
                    self.textDocumentProxy.insertText(text)

                },
                deleteText: { [weak self] in
                    guard let self,
                          self.textDocumentProxy.hasText else { return }

                    self.textDocumentProxy.deleteBackward()
                },
                keyboardHeight: keyboardHeight,
                needsInputModeSwitchKey: self.needsInputModeSwitchKey,
//                needsInputModeSwitchKey: true,
                nextKeyboardAction: #selector(self.handleInputModeList(from:with:)),
                backgroundColor: .clear
            ))
        
        
        let keyboardView = keyboardViewController.view!
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChild(keyboardViewController)
        self.view.addSubview(keyboardView)
        keyboardViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
