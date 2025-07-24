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
    private var isShifted: Bool = false {
        didSet {
            updateTitle()
        }
    }
    
    // MARK: - Initializer
    
    override init(layout: KeyboardLayout) {
        self.layout = layout
        super.init(layout: layout)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    
    func update(isShifted: Bool) {
        self.isShifted = isShifted
    }
}

// MARK: - UI Methods

private extension SymbolShiftButton {
    func setupUI() {
        setStyles()
        setActions()
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
        
        let attributes = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.label])
        self.configuration?.attributedTitle = AttributedString("1/2", attributes: attributes)
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            if UserDefaultsManager.shared.isSoundFeedbackEnabled { FeedbackManager.shared.playModifierSound() }
            if UserDefaultsManager.shared.isHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}

// MARK: - Update Methods

private extension SymbolShiftButton {
    func updateTitle() {
        if isShifted {
            self.configuration?.attributedTitle?.characters = .init("2/2")
        } else {
            self.configuration?.attributedTitle?.characters = .init("1/2")
        }
    }
}
