//
//  NextKeyboardButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/15/25.
//

import UIKit

import SnapKit
import Then

/// iPhone SE용 키보드 전환 버튼
final class NextKeyboardButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        self.layout = layout
        super.init(layout: layout)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHighlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.isHighlighted = false
    }
}

// MARK: - UI Methods

private extension NextKeyboardButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configuration?.image = UIImage(systemName: "globe")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
    }
}
