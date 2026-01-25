//
//  ShiftButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 대문자/기호 전환 버튼
final public class ShiftButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let keyboard: SYKeyboardType
    
    private let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium, scale: .large)
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
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
    
    // MARK: - Public Methods
    
    public func updateShiftState(to isShifted: Bool) {
        switch keyboard {
        case .dubeolsik, .qwerty:
            if isShifted {
                self.isGesturing = true
                primaryKeyListImageView.image = UIImage(systemName: "shift.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            } else {
                self.isGesturing = false
                primaryKeyListImageView.image = UIImage(systemName: "shift")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            }
        case .symbol:
            if isShifted {
                primaryKeyListLabel.text = "2/2"
            } else {
                primaryKeyListLabel.text = "1/2"
            }
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
    
    public func updateCapsLockState(to isCapsLocked: Bool) {
        switch keyboard {
        case .dubeolsik, .qwerty:
            if isCapsLocked {
                self.isPressed = true
                self.isGesturing = true
                primaryKeyListImageView.image = UIImage(systemName: "capslock.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            } else {
                self.isPressed = false
                self.isGesturing = false
                primaryKeyListImageView.image = UIImage(systemName: "shift")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            }
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
}

// MARK: - UI Methods

private extension ShiftButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let newConstant = -(insetDx + KeyboardLayoutFigure.buttonHorizontalInset)
        trailingConstraint?.constant = newConstant
        
        switch keyboard {
        case .dubeolsik, .qwerty:
            self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: KeyboardLayoutFigure.buttonHorizontalInset)
            primaryKeyListImageView.image = UIImage(systemName: "shift")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        case .symbol:
            primaryKeyListLabel.text = "1/2"
            primaryKeyListLabel.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
            
            self.configurationUpdateHandler = { [weak self] button in
                switch button.state {
                case .normal, .highlighted:
                    self?.backgroundView.backgroundColor = .secondaryButton
                default:
                    break
                }
            }
        case .naratgeul, .cheonjiin, .numeric, .tenKey:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
}
