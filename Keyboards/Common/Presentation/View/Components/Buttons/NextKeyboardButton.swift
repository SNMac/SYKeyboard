//
//  NextKeyboardButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/15/25.
//

import UIKit

import SnapKit
import Then

/// iPhone SE용 키보드 전환 버튼
final class NextKeyboardButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
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
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        }
        self.addAction(playFeedback, for: .touchDown)
        
        let setSelected = UIAction { [weak self] _ in
            self?.isSelected = true
        }
        self.addAction(setSelected, for: [.touchDragInside, .touchDragOutside])
        let setDeselected = UIAction { [weak self] _ in
            self?.isSelected = false
        }
        self.addAction(setDeselected, for: [.touchUpInside, .touchUpOutside])
    }
}
