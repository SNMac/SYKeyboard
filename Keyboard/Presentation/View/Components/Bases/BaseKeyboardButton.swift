//
//  BaseKeyboardButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 키보드 버튼 베이스
class BaseKeyboardButton: UIButton {
    
    // MARK: - Properties
    
    let insetDx: CGFloat
    let insetDy: CGFloat
    let cornerRadius: CGFloat = 4.6
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout) {
        switch layout {
        case .hangeul, .numeric, .tenKey:
            self.insetDx = 3
            self.insetDy = 2
        case .symbol:
            self.insetDx = 3
            self.insetDy = 4
        }
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension BaseKeyboardButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.tintColor = .clear
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.automaticallyUpdateForSelection = false
        buttonConfig.contentInsets = .zero
        buttonConfig.titleAlignment = .center
        self.configuration = buttonConfig
    }
}
