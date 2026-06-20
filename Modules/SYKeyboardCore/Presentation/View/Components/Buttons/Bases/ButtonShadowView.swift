//
//  ButtonShadowView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/16/25.
//

import UIKit

import SYKeyboardAssets

/// 키보드 버튼 그림자
final class ButtonShadowView: UIView {
        
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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

private extension ButtonShadowView {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.isUserInteractionEnabled = false
    }
    
    func setShadows() {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: KeyboardLayoutFigure.buttonCornerRadius).cgPath
        self.layer.shadowColor = UIColor.buttonShadow.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 0
    }
}

