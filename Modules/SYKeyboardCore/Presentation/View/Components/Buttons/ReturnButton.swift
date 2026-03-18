//
//  ReturnButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SYKeyboardAssets

/// 리턴 버튼
final public class ReturnButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    public let type: TextInteractableType = .returnButton
    
    // MARK: - Initializer
    
    public override init(keyboard: SYKeyboardType) {
        super.init(keyboard: keyboard)
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    func update(for returnKeyType: ReturnKeyType) {
        primaryKeyListImageView.image = returnKeyType.image
        
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            primaryKeyListLabel.text = returnKeyType.title
            
            guard self.isUserInteractionEnabled else { return }
            switch button.state {
            case .highlighted:
                if isPressed || isGesturing {
                    primaryKeyListLabel.textColor = returnKeyType.highlightedColor
                    backgroundView.backgroundColor = .secondaryButtonPressed
                } else {
                    primaryKeyListLabel.textColor = returnKeyType.normalColor
                    backgroundView.backgroundColor = returnKeyType.backgroundColor
                }
            default:
                if isGesturing {
                    primaryKeyListLabel.textColor = returnKeyType.highlightedColor
                    backgroundView.backgroundColor = .secondaryButtonPressed
                } else {
                    primaryKeyListLabel.textColor = returnKeyType.normalColor
                    backgroundView.backgroundColor = returnKeyType.backgroundColor
                }
            }
        }
    }
    
    /// 리턴 버튼의 활성화 상태를 설정합니다.
    ///
    /// `enablesReturnKeyAutomatically`가 `true`인 텍스트 필드에서
    /// 텍스트가 비어있을 때 비활성화합니다.
    func updateEnabled(_ isEnabled: Bool) {
        self.isUserInteractionEnabled = isEnabled
        if isEnabled {
            self.setNeedsUpdateConfiguration()
        } else {
            primaryKeyListLabel.textColor = .returnButtonDisabledLabel
            primaryKeyListImageView.tintColor = .returnButtonDisabledLabel
            backgroundView.backgroundColor = .returnButtonDisabledBackground
        }
    }
}

// MARK: - UI Methods

private extension ReturnButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        primaryKeyListLabel.font = .systemFont(ofSize: 18)
    }
}

// MARK: - Custom Enum

extension ReturnButton {
    enum ReturnKeyType {
        case `default`
        case go
        case google
        case join
        case next
        case route
        case search
        case send
        case yahoo
        case done
        case emergencyCall
        case `continue`
        
        init(type: UIReturnKeyType?) {
            switch type {
            case .default:
                self = .default
            case .go:
                self = .go
            case .google:
                self = .google
            case .join:
                self = .join
            case .next:
                self = .next
            case .route:
                self = .route
            case .search:
                self = .search
            case .send:
                self = .send
            case .yahoo:
                self = .yahoo
            case .done:
                self = .done
            case .emergencyCall:
                self = .emergencyCall
            case .continue:
                self = .continue
            default:
                self = .default
            }
        }
        
        var title: String? {
            switch self {
            case .default:
                return nil
            case .go:
                return "이동"
            case .google, .search, .yahoo:
                return "검색"
            case .join:
                return "연결"
            case .next:
                return "다음"
            case .route:
                return "경로"
            case .send:
                return "전송"
            case .continue:
                return "계속"
            case .done:
                return "완료"
            case .emergencyCall:
                return "긴급통화"
            }
        }
        
        var normalColor: UIColor? {
            return self.backgroundColor == UIColor.systemBlue ? UIColor.white : UIColor.label
        }
        
        var highlightedColor: UIColor? {
            return .label
        }
        
        var image: UIImage? {
            switch self {
            case .default:
                let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium, scale: .large)
                return UIImage(systemName: "return")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            case .go, .google, .join, .next, .route, .search, .send, .yahoo, .done, .emergencyCall, .continue:
                return nil
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .default, .next, .continue:
                return .secondaryButton
            case .go, .google, .join, .route, .search, .send, .yahoo, .done, .emergencyCall:
                return .systemBlue
            }
        }
    }
}
