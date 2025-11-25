//
//  SecondaryButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 보조 키보드 버튼
public class SecondaryButton: BaseKeyboardButton {
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
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
                backgroundView.backgroundColor = isGesturing ? .secondaryButtonPressed : .secondaryButton
            case .highlighted:
                backgroundView.backgroundColor = isPressed || isGesturing ? .secondaryButtonPressed : .secondaryButton
            default:
                break
            }
        }
    }
}
