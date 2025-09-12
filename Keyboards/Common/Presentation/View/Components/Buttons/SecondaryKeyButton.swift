//
//  SecondaryKeyButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 보조 키 버튼
final class SecondaryKeyButton: SecondaryButton, TextInteractionButtonProtocol {
    
    // MARK: - Properties
    
    private(set) var button: TextInteractionButton {
        didSet {
            if button.keys.isEmpty {
                self.isHidden = true
            } else {
                updateTitle()
                self.isHidden = false
            }
        }
    }
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout, button: TextInteractionButton) {
        self.button = button
        super.init(layout: layout)
        
        setupUI()
        updateTitle()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    func update(button: TextInteractionButton) {
        self.button = button
    }
}

// MARK: - UI Methods

private extension SecondaryKeyButton {
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

private extension SecondaryKeyButton {
    func updateTitle() {
        let keys = button.keys
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if key.count == 1 && Character(key).isLowercase {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24, weight: .regular), .foregroundColor: UIColor.label]))
            } else if key.count > 1 {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label]))
            } else {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
            }
        } else {
            let joined = keys.joined(separator: "")
            self.configuration?.attributedTitle = AttributedString(joined, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
        }
    }
}
