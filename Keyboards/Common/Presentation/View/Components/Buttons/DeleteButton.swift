//
//  DeleteButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 삭제 버튼
final class DeleteButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    private(set) var type: TextInteractableType = .deleteButton
    private let keyboard: SYKeyboardType
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    override func playFeedback() {
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
        switch keyboard {
        case .english, .symbol:
            self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: KeyboardLayoutFigure.buttonHorizontalInset, bottom: 0, trailing: 0)
            shadowView.snp.updateConstraints { $0.leading.equalToSuperview().inset(insetDx + KeyboardLayoutFigure.buttonHorizontalInset) }
            backgroundView.snp.updateConstraints { $0.leading.equalToSuperview().inset(insetDx + KeyboardLayoutFigure.buttonHorizontalInset) }
        default:
            break
        }
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium)
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                if isGesturing {
                    backgroundView.backgroundColor = .secondaryButtonPressed
                    button.configuration?.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                } else {
                    backgroundView.backgroundColor = .secondaryButton
                    button.configuration?.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                }
            case .highlighted:
                if isPressed {
                    backgroundView.backgroundColor = .secondaryButtonPressed
                    button.configuration?.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                } else {
                    backgroundView.backgroundColor = .secondaryButton
                    button.configuration?.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                }
            default:
                break
            }
        }
    }
}
