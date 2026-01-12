//
//  ReturnButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 리턴 버튼
final public class ReturnButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    public let type: TextInteractableType = .returnButton
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    func update(for returnKeyType: ReturnKeyType) {
        self.configuration?.image = returnKeyType.image
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            
            primaryKeyListLabel.text = returnKeyType.title
            primaryKeyListLabel.font = .systemFont(ofSize: 18)
            switch button.state {
            case .normal:
                if isGesturing {
                    primaryKeyListLabel.textColor = returnKeyType.highlightedColor
                    backgroundView.backgroundColor = .secondaryButtonPressed
                } else {
                    primaryKeyListLabel.textColor = returnKeyType.normalColor
                    backgroundView.backgroundColor = returnKeyType.backgroundColor
                }
            case .highlighted:
                if isPressed || isGesturing {
                    primaryKeyListLabel.textColor = returnKeyType.highlightedColor
                    backgroundView.backgroundColor = .secondaryButtonPressed
                } else {
                    primaryKeyListLabel.textColor = returnKeyType.normalColor
                    backgroundView.backgroundColor = returnKeyType.backgroundColor
                }
            default:
                break
            }
        }
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
                let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.imageSize, weight: .medium)
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
