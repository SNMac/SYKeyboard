//
//  SecondaryKeyButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/6/25.
//

import UIKit

/// 보조 키 버튼
final public class SecondaryKeyButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    public private(set) var type: TextInteractableType {
        didSet {
            if type.primaryKeyList.isEmpty {
                self.isHidden = true
            } else {
                updatePrimaryKeyListLabel()
                self.isHidden = false
            }
        }
    }
    
    // MARK: - Initializer
    
    public init(keyboard: SYKeyboardType, button: TextInteractableType) {
        self.type = button
        super.init(keyboard: keyboard)
        
        updatePrimaryKeyListLabel()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
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
    func updatePrimaryKeyListLabel() {
        if type.primaryKeyList.count == 1 {
            guard let key = type.primaryKeyList.first else { return }
            primaryKeyListLabel.text = key
            
            if key.count == 1 {
                if Character(key).isLowercase {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.lowercaseKeySize)
                } else {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
                }
            } else {
                primaryKeyListLabel.font = .systemFont(ofSize: FontSize.stringKeySize)
            }
        } else {
            primaryKeyListLabel.text = type.primaryKeyList.joined(separator: "")
            primaryKeyListLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
        }
    }
}
