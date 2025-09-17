//
//  PrimaryButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

import SnapKit

/// 주 키보드 버튼
class PrimaryButton: BaseKeyboardButton {
    
    // MARK: - UI Components
    
    /// 배경 UI
    final lazy var backgroundView = ButtonBackgroundView(cornerRadius: self.cornerRadius)
    /// 그림자 UI
    final lazy var shadowView = ButtonShadowView(cornerRadius: self.cornerRadius)
    
    // MARK: - Initializer
    
    override init(keyboard: SYKeyboardType) {
        super.init(keyboard: keyboard)
        setupUI()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension PrimaryButton {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                backgroundView.backgroundColor = .primaryButton
            case .highlighted:
                backgroundView.backgroundColor = isPressed ? .primaryButtonPressed : .primaryButton
            case .selected:
                backgroundView.backgroundColor = .primaryButtonPressed
            default:
                break
            }
        }
    }
    
    func setHierarchy() {
        self.insertSubview(shadowView, at: 0)
        self.insertSubview(backgroundView, at: 1)
    }
    
    func setConstraints() {
        shadowView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(self.insetDy)
            $0.leading.trailing.equalToSuperview().inset(self.insetDx)
        }
        
        backgroundView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(self.insetDy)
            $0.leading.trailing.equalToSuperview().inset(self.insetDx)
        }
    }
}
