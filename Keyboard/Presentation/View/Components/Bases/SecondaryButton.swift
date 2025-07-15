//
//  SecondaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 기능 관련 키보드 버튼
class SecondaryButton: BaseKeyboardButton {
    
    // MARK: - UI Components
    
    /// 배경 UI
    lazy var backgroundView = ButtonBackgroundView(cornerRadius: self.cornerRadius)
    /// 그림자 UI
    lazy var shadowView = ButtonShadowView(cornerRadius: self.cornerRadius)
    
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

private extension SecondaryButton {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                self?.backgroundView.backgroundColor = .secondaryButton
            case .highlighted:
                self?.backgroundView.backgroundColor = .secondaryButtonPressed
                FeedbackManager.shared.playModifierSound()
                FeedbackManager.shared.playHaptic()
            default:
                break
            }
        }
    }
    
    func setViewHierarchy() {
        self.addSubviews(shadowView,
                         backgroundView)
    }
    
    func setConstraints() {
        shadowView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(super.insetDy)
            $0.leading.trailing.equalToSuperview().inset(super.insetDx)
        }
        
        backgroundView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(super.insetDy)
            $0.leading.trailing.equalToSuperview().inset(super.insetDx)
        }
    }
}
