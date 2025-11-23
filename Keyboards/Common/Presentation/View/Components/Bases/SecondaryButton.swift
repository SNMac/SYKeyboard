//
//  SecondaryButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 보조 키보드 버튼
class SecondaryButton: BaseKeyboardButton {
    
    // MARK: - UI Components
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        super.init(keyboard: keyboard)
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension SecondaryButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                backgroundView.backgroundColor = .secondaryButton
            case .highlighted:
                backgroundView.backgroundColor = isPressed ? .secondaryButtonPressed : .secondaryButton
            case .selected:
                backgroundView.backgroundColor = .secondaryButtonPressed
            default:
                break
            }
        }
    }
}
