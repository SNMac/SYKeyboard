//
//  BaseKeyboardButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

class BaseKeyboardButton: UIButton {
    
    // MARK: - Properties
    
    let insetDx: CGFloat
    let insetDy: CGFloat
    let cornerRadius: CGFloat = 4.6
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout) {
        switch layout {
        case .hangeul, .numeric:
            self.insetDx = 3
            self.insetDy = 2
        case .symbol:
            self.insetDx = 3
            self.insetDy = 3
        }
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setShadows()
    }
}

// MARK: - UI Methods

private extension BaseKeyboardButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.background.backgroundInsets = NSDirectionalEdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3)
        buttonConfig.background.cornerRadius = cornerRadius
        self.configuration = buttonConfig
    }
    
    func setShadows() {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds.insetBy(dx: insetDx, dy: insetDy), cornerRadius: cornerRadius).cgPath
        self.layer.shadowColor = UIColor.buttonShadow.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 0
    }
}
