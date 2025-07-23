//
//  ChevronButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/22/25.
//

import UIKit

final class ChevronButton: UIButton {
    
    // MARK: - Properties
    
    /// chevron.compact 이미지 방향
    enum Direction {
        case left
        case right
    }
    /// 방향에 따른 chevron.compact 이미지
    private let chevronImage: UIImage?
    
    // MARK: - Initializer
    
    init(direction: Direction) {
        switch direction {
        case .left:
            chevronImage = UIImage(systemName: "chevron.compact.left")
        case .right:
            chevronImage = UIImage(systemName: "chevron.compact.right")
        }
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        buttonConfig.titleAlignment = .center
        self.configuration = buttonConfig
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                button.configuration?.image = self?.chevronImage?.withConfiguration(imageConfig).withTintColor(.chevronButton, renderingMode: .alwaysOriginal)
            case .highlighted:
                button.configuration?.image = self?.chevronImage?.withConfiguration(imageConfig).withTintColor(.chevronButtonPressed, renderingMode: .alwaysOriginal)
            default:
                break
            }
        }
    }
}
