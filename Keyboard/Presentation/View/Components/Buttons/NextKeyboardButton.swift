//
//  NextKeyboardButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/15/25.
//

import UIKit

import SnapKit
import Then

/// iPhone SE용 키보드 전환 버튼
final class NextKeyboardButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        self.layout = layout
        super.init(layout: layout)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension NextKeyboardButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "globe")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            if UserDefaultsManager.shared.isSoundFeedbackEnabled { FeedbackManager.shared.playModifierSound() }
            if UserDefaultsManager.shared.isHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}
