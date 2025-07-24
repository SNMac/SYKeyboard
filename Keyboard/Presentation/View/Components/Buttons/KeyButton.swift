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
    
    private var keys: [String] {
        didSet {
            updateTitle()
        }
    }
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout, keys: [String]) {
        self.keys = keys
        super.init(layout: layout)
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func update(keys: [String]) {
        self.keys = keys
    }
}

// MARK: - UI Methods

private extension KeyButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        updateTitle()
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            if UserDefaultsManager.shared.isSoundFeedbackEnabled { FeedbackManager.shared.playKeyTypingSound() }
            if UserDefaultsManager.shared.isHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}

// MARK: - Update Methods

private extension KeyButton {
    func updateTitle() {
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if Character(key).isLowercase {
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
