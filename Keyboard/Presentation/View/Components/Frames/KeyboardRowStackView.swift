//
//  KeyboardRowStackView.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

/// 키보드 행
final class KeyboardRowStackView: UIStackView {
    
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

private extension KeyboardRowStackView {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
        
        self.axis = .horizontal
        self.spacing = 0
        self.alignment = .fill
        self.distribution = .fill
    }
}
