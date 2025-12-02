//
//  ChevronButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/22/25.
//

import UIKit

import SYKeyboardAssets

/// 한 손 키보드 해제 버튼
final class ChevronButton: UIButton {
    
    // MARK: - Properties
    
    /// `chevron.compact` 이미지 방향
    enum Direction {
        case left
        case right
        
        var image: UIImage? {
            switch self {
            case .left:
                return UIImage(systemName: "chevron.compact.left")
            case .right:
                return UIImage(systemName: "chevron.compact.right")
            }
        }
    }
    
    private let direction: Direction
    
    // MARK: - Initializer
    
    init(direction: Direction) {
        self.direction = direction
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        
        let touchArea: CGRect
        switch direction {
        case .left:
            touchArea = self.bounds.inset(by: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 4))
        case .right:
            touchArea = self.bounds.inset(by: UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 0))
        }
        return touchArea.contains(point)
    }
}

private extension ChevronButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.automaticallyUpdateForSelection = false
        buttonConfig.contentInsets = .zero
        self.configuration = buttonConfig
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                button.configuration?.image = self?.direction.image?.withConfiguration(imageConfig).withTintColor(.chevronButton, renderingMode: .alwaysOriginal)
            case .highlighted:
                button.configuration?.image = self?.direction.image?.withConfiguration(imageConfig).withTintColor(.chevronButtonPressed, renderingMode: .alwaysOriginal)
            default:
                break
            }
        }
    }
}
