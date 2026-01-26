//
//  DeleteButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SYKeyboardAssets

/// 삭제 버튼
final public class DeleteButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    public let type: TextInteractableType = .deleteButton
    
    private let keyboard: SYKeyboardType
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playDeleteSound()
    }
}

// MARK: - UI Methods

private extension DeleteButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium, scale: .large)
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                if isGesturing {
                    backgroundView.backgroundColor = .secondaryButtonPressed
                    primaryKeyListImageView.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                } else {
                    backgroundView.backgroundColor = .secondaryButton
                    primaryKeyListImageView.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                }
            case .highlighted:
                if isPressed || isGesturing {
                    backgroundView.backgroundColor = .secondaryButtonPressed
                    primaryKeyListImageView.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                } else {
                    backgroundView.backgroundColor = .secondaryButton
                    primaryKeyListImageView.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                }
            default:
                break
            }
        }
    }
}
