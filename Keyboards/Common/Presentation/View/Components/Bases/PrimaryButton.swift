//
//  PrimaryButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

/// 주 키보드 버튼
class PrimaryButton: BaseKeyboardButton {
    
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

private extension PrimaryButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                backgroundView.backgroundColor = isGesturing ? .primaryButtonPressed : .primaryButton
            case .highlighted:
                backgroundView.backgroundColor = isPressed ? .primaryButtonPressed : .primaryButton
            default:
                break
            }
        }
    }
}
