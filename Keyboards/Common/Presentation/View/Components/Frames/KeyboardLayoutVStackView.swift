//
//  KeyboardLayoutVStackView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 키보드 레이아웃 프레임
final class KeyboardLayoutVStackView: UIStackView {
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension KeyboardLayoutVStackView {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
        
        self.axis = .vertical
        self.spacing = 0
        self.alignment = .fill
        self.distribution = .fillEqually
    }
}
