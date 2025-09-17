//
//  SpaceButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 스페이스 버튼
final class SpaceButton: PrimaryButton, TextInteractionButton {
    
    private(set) var button: TextInteractionButtonType
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        self.button = .spaceButton
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
}

// MARK: - UI Methods

private extension SpaceButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "space")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
}
