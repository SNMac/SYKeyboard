//
//  DeleteButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 삭제 버튼
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
            self.shadowView.snp.updateConstraints { $0.leading.equalToSuperview().inset(super.insetDx + 3) }
            self.backgroundView.snp.updateConstraints { $0.leading.equalToSuperview().inset(super.insetDx + 3) }
        default:
            break
        }
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        self.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                super.backgroundView.backgroundColor = .secondaryButton
                button.configuration?.image = UIImage(systemName: "delete.backward")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            case .highlighted:
                super.backgroundView.backgroundColor = .secondaryButtonPressed
                button.configuration?.image = UIImage(systemName: "delete.backward.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                FeedbackManager.shared.playDeleteSound()
                FeedbackManager.shared.playHaptic()
            default:
                break
            }
        }
    }
}
