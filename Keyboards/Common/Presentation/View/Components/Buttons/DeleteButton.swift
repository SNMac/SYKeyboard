//
//  DeleteButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 삭제 버튼
final class DeleteButton: SecondaryButton, TextInteractionButtonProtocol {
    
    // MARK: - Properties
    
    private(set) var button: TextInteractionButton = .deleteButton
    private let keyboard: Keyboard
    
    // MARK: - Initializer
    
    override init(keyboard: Keyboard) {
        self.keyboard = keyboard
        super.init(keyboard: keyboard)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension DeleteButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        switch keyboard {
        case .english, .symbol:
            self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 0)
            self.shadowView.snp.updateConstraints { $0.leading.equalToSuperview().inset(self.insetDx + 3) }
            self.backgroundView.snp.updateConstraints { $0.leading.equalToSuperview().inset(self.insetDx + 3) }
        default:
            break
        }
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                self?.backgroundView.backgroundColor = .secondaryButton
                button.configuration?.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            case .highlighted, .selected:
                self?.backgroundView.backgroundColor = .secondaryButtonPressed
                button.configuration?.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            default:
                break
            }
        }
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playDeleteSound()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}
