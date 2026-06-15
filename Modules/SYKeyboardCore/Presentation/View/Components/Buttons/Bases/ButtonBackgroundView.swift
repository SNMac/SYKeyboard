//
//  ButtonBackgroundView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/16/25.
//

import UIKit

/// 키보드 버튼 배경
final class ButtonBackgroundView: UIView {
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ButtonBackgroundView {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.isUserInteractionEnabled = false
        
        self.clipsToBounds = true
        self.layer.cornerRadius = KeyboardLayoutFigure.buttonCornerRadius
    }
}
