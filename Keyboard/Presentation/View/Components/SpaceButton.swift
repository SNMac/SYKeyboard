//
//  SpaceButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

final class SpaceButton: PrimaryButton {
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension SpaceButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        guard var buttonConfig = self.configuration else { return }
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        buttonConfig.image = UIImage(systemName: "space")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        self.configuration = buttonConfig
    }
}
