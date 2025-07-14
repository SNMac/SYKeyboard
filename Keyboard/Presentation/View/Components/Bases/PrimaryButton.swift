//
//  PrimaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

/// 입력 관련 버튼 `BaseKeyboardButton`
class PrimaryButton: BaseKeyboardButton {
    
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

private extension PrimaryButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.background.backgroundColor = .primaryButton
            case .highlighted:
                button.configuration?.background.backgroundColor = .primaryButtonPressed
            default:
                break
            }
        }
    }
}
