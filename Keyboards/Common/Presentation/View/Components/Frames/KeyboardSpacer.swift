//
//  KeyboardSpacer.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 여백 확보용
final class KeyboardSpacer: UIView {
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension KeyboardSpacer {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
}
