//
//  KeyButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

final class KeyButton: PrimaryButton {
    
    // MARK: - Properties
    
    private let keys: [String]
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout, keys: [String]) {
        self.keys = keys
        super.init(layout: layout)
        configure(keys: keys)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension KeyButton {
    func configure(keys: [String]) {
        guard var buttonConfig = self.configuration else { return }
        
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if Character(key).isLowercase {
                buttonConfig.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 25, weight: .regular), .foregroundColor: UIColor.label]))
            } else {
                buttonConfig.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
            }
        } else {
            let joined = keys.joined(separator: "")
            buttonConfig.attributedTitle = AttributedString(joined, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
        }
        
        self.configuration = buttonConfig
    }
}
