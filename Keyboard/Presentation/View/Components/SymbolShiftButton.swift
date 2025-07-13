//
//  SymbolShiftButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

final class SymbolShiftButton: SecondaryButton {
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func configure() {
        
    }
}

// MARK: - UI Methods

private extension SymbolShiftButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        guard var buttonConfig = self.configuration else { return }
        let attributes = AttributeContainer([.font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
        buttonConfig.attributedTitle = AttributedString("1/2", attributes: attributes)
        self.configuration = buttonConfig
    }
}
