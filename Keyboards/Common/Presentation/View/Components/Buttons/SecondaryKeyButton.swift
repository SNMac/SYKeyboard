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
        if type.keys.count == 1 {
            guard let key = type.keys.first else { return }
            _titleLabel.text = key
            
            if key.count == 1 && Character(key).isLowercase {
                if Character(key).isLowercase {
                    _titleLabel.font = .systemFont(ofSize: FontSize.lowercaseKeySize)
                } else {
                    _titleLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
                }
            } else {
                _titleLabel.font = .systemFont(ofSize: FontSize.stringKeySize)
            }
        } else {
            _titleLabel.text = type.keys.joined(separator: "")
            _titleLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
        }
    }
}
