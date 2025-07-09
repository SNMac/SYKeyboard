//
//  KeyboardView.swift
//  Keyboard
//
//  Created by 서동환 on 7/9/25.
//

import UIKit

/// 키보드 `UIView`
final class KeyboardView: UIView {
    
    // MARK: - UI Components
    
    
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func configure() {
        
    }
}

private extension KeyboardView {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setViewHierarchy() {
        
    }
    
    func setConstraints() {
        
    }
}
