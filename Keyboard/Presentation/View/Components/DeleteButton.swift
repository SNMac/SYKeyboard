//
//  DeleteButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 삭제 버튼 `SecondaryButton`
final class DeleteButton: SecondaryButton {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        self.layout = layout
        super.init(layout: layout)
        
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch layout {
        case .symbol:
            self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds.inset(by: UIEdgeInsets(top: super.insetDy,
                                                                                                 left: super.insetDx + 3,
                                                                                                 bottom: super.insetDy,
                                                                                                 right: super.insetDx)), cornerRadius: cornerRadius).cgPath
        default:
            break
        }
    }
}

// MARK: - UI Methods

private extension DeleteButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        switch layout {
        case .symbol:
            self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 3, bottom: 0, trailing: 0)
            self.configuration?.background.backgroundInsets.leading = super.insetDx + 3
        default:
            break
        }
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.background.backgroundColor = .secondaryButton
                button.configuration?.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            case .highlighted:
                button.configuration?.background.backgroundColor = .secondaryButtonPressed
                button.configuration?.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            default:
                break
            }
        }
    }
}
