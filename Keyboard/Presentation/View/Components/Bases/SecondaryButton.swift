//
//  SecondaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 기능 관련 버튼 `BaseKeyboardButton`
class SecondaryButton: BaseKeyboardButton {
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
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
        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.background.backgroundColor = .secondaryButton
            case .highlighted:
                button.configuration?.background.backgroundColor = .secondaryButtonPressed
            default:
                break
            }
        }
    }
}
