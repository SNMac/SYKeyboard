//
//  NextKeyboardButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/15/25.
//

import UIKit

/// iPhone SE용 키보드 전환 버튼
final public class NextKeyboardButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
}

// MARK: - UI Methods

private extension NextKeyboardButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium)
        self.configuration?.image = UIImage(systemName: "globe")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
    
    func setActions() {
        let setSelected = UIAction { [weak self] _ in self?.isGesturing = true }
        self.addAction(setSelected, for: [.touchDragInside, .touchDragOutside])
        
        let setDeselected = UIAction { [weak self] _ in self?.isGesturing = false }
        self.addAction(setDeselected, for: [.touchUpInside, .touchUpOutside])
    }
}
