//
//  ShiftButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 대문자/기호 전환 버튼
final class ShiftButton: SecondaryButton {
    
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
    
    // MARK: - Methods
    
    func update(isShifted: Bool) {
        switch layout {
        case .english:
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            if isShifted {
                self.isSelected = true
                self.configuration?.image = UIImage(systemName: "shift.fill")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
                self.backgroundView.backgroundColor = .secondaryButtonPressed
            } else {
                self.isSelected = false
                self.configuration?.image = UIImage(systemName: "shift")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            }
        case .symbol:
            if isShifted {
                self.configuration?.attributedTitle?.characters = .init("2/2")
            } else {
                self.configuration?.attributedTitle?.characters = .init("1/2")
            }
        default:
            fatalError("도달할 수 없는 case 입니다.")
        }

    }
}

// MARK: - UI Methods

private extension ShiftButton {
    func setupUI() {
        setStyles()
        setActions()
    }
    
    func setStyles() {
        self.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 6)
        self.shadowView.snp.updateConstraints { $0.trailing.equalToSuperview().inset(self.insetDx + 6) }
        self.backgroundView.snp.updateConstraints { $0.trailing.equalToSuperview().inset(self.insetDx + 6) }
        
        switch layout {
        case .english:
            let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            self.configuration?.image = UIImage(systemName: "shift")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        case .symbol:
            let attributes = AttributeContainer([.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.label])
            self.configuration?.attributedTitle = AttributedString("1/2", attributes: attributes)
            
            self.configurationUpdateHandler = { [weak self] button in
                switch button.state {
                case .normal, .highlighted, .selected:
                    self?.backgroundView.backgroundColor = .secondaryButton
                default:
                    break
                }
            }
        default:
            fatalError("도달할 수 없는 case 입니다.")
        }
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}
