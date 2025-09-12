//
//  SpaceButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 스페이스 버튼
final class SpaceButton: PrimaryButton, TextInteractionButtonProtocol {
    
    private(set) var button: TextInteractionButton
    
    // MARK: - Initializer
    
    override init(keyboard: Keyboard) {
        self.button = .spaceButton
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension SpaceButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "space")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}
