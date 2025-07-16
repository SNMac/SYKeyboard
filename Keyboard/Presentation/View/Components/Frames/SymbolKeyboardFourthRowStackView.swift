//
//  SymbolKeyboardFourthRowStackView.swift
//  Keyboard
//
//  Created by 서동환 on 7/17/25.
//

import UIKit

/// 기호 키보드 네번째 행
final class SymbolKeyboardFourthRowStackView: UIStackView {
    
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

private extension SymbolKeyboardFourthRowStackView {
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
