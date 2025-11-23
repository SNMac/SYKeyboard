//
//  ReturnButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 리턴 버튼
final class ReturnButton: SecondaryButton, TextInteractable {
    
    // MARK: - Properties
    
    private(set) var type: TextInteractableType = .returnButton
    
    // MARK: - Override Methods
    
    override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }
    
    // MARK: - Internal Methods
    
    func update(for type: ReturnKeyType) {
        self.configuration?.image = type.image
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                configuration?.attributedTitle = type.normalAttributedTitle
                backgroundView.backgroundColor = type.backgroundColor
            case .highlighted:
                if isPressed {
                    configuration?.attributedTitle = type.highlightedAttributedTitle
                    backgroundView.backgroundColor = .secondaryButtonPressed
                } else {
                    configuration?.attributedTitle = type.normalAttributedTitle
                    backgroundView.backgroundColor = type.backgroundColor
                }
            case .selected:
                configuration?.attributedTitle = type.highlightedAttributedTitle
                backgroundView.backgroundColor = .secondaryButtonPressed
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
        
        var normalAttributedTitle: AttributedString? {
            guard let title else { return nil }
            let foregroundColor = self.backgroundColor == UIColor.systemBlue ? UIColor.white : UIColor.label
            let attributes = AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .regular), .foregroundColor: foregroundColor])
            return AttributedString(title, attributes: attributes)
        }
        
        var highlightedAttributedTitle: AttributedString? {
            guard let title else { return nil }
            let attributes = AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
            return AttributedString(title, attributes: attributes)
        }
        
        var image: UIImage? {
            switch self {
            case .default:
                let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
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
