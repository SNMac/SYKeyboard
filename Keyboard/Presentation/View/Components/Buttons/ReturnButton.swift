//
//  ReturnButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 리턴 버튼
final class ReturnButton: SecondaryButton, TextInteractionButton {
    
    // MARK: - Properties
    
    var keys: [String] = []
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
        self.keys = ["\n"]
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension ReturnButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "return")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            if UserDefaultsManager.shared.isSoundFeedbackEnabled { FeedbackManager.shared.playModifierSound() }
            if UserDefaultsManager.shared.isHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}
