//
//  KeyButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 키 버튼
final class KeyButton: PrimaryButton {
    
    // MARK: - Properties
    
    override var button: TextInteractionButton {
        didSet {
            updateTitle()
        }
    }
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout, button: TextInteractionButton) {
        super.init(layout: layout)
        self.button = button
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(button: TextInteractionButton) {
        self.button = button
    }
}

// MARK: - UI Methods

private extension KeyButton {
    func setupUI() {
        setActions()
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playKeyTypingSound()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}

// MARK: - Update Methods

private extension KeyButton {
    func updateTitle() {
        let keys = button.keys
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if key.count == 1 && Character(key).isLowercase {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 25, weight: .regular), .foregroundColor: UIColor.label]))
            } else {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
            }
        } else {
            let joined = keys.joined(separator: "")
            self.configuration?.attributedTitle = AttributedString(joined, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
        }
    }
}
