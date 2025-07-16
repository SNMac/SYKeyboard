//
//  SymbolShiftButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 기호 전환 버튼
final class SymbolShiftButton: SecondaryButton {
    
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
}

// MARK: - UI Methods

private extension SymbolShiftButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        switch layout {
        case .symbol:
            self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 3)
            self.shadowView.snp.updateConstraints { $0.trailing.equalToSuperview().inset(self.insetDx + 3) }
            self.backgroundView.snp.updateConstraints { $0.trailing.equalToSuperview().inset(self.insetDx + 3) }
        default:
            break
        }
        
        let attributes = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label])
        self.configuration?.attributedTitle = AttributedString("1/2", attributes: attributes)
    }
}

