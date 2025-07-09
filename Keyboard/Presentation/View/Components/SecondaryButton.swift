//
//  SecondaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

final class SecondaryButton: UIButton {
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SecondaryButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        
    }
}
