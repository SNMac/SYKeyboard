//
//  SpaceButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 스페이스 버튼
final class SpaceButton: PrimaryButton {
    
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

private extension SpaceButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "space")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        
        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                self.backgroundView.backgroundColor = .primaryButton
            case .highlighted:
                self.backgroundView.backgroundColor = .primaryButtonPressed
                if UserDefaultsManager.shared.isSoundFeedbackEnabled { FeedbackManager.shared.playModifierSound() }
                if UserDefaultsManager.shared.isHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
            default:
                break
            }
        }
    }
}
