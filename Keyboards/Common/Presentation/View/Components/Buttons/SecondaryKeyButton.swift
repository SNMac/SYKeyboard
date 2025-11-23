//
//  SecondaryKeyButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 보조 키 버튼
final class SecondaryKeyButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    private(set) var type: TextInteractableType {
        didSet {
            if type.keys.isEmpty {
                self.isHidden = true
            } else {
                updateTitle()
                self.isHidden = false
            }
        }
    }
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType, button: TextInteractableType) {
        self.type = button
        super.init(keyboard: keyboard)
        
        updateTitle()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    func update(button: TextInteractableType) {
        self.type = button
    }
}

// MARK: - Update Methods

private extension SecondaryKeyButton {
    func updateTitle() {
        let keys = type.keys
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if key.count == 1 && Character(key).isLowercase {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24, weight: .regular)]))
            } else if key.count > 1 {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .regular)]))
            } else {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular)]))
            }
        } else {
            let joined = keys.joined(separator: "")
            self.configuration?.attributedTitle = AttributedString(joined, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular)]))
        }
    }
}
