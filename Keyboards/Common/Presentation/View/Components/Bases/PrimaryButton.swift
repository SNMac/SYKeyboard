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
    
    override init(layout: KeyboardLayout) {
        super.init(layout: layout)
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
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                self?.backgroundView.backgroundColor = .primaryButton
            case .highlighted, .selected:
                self?.backgroundView.backgroundColor = .primaryButtonPressed
            default:
                break
            }
        }
    }
    
    func setActions() {
        // TODO: - 키 입력 로직
    }
    
    func setHierarchy() {
        self.addSubviews(shadowView,
                         backgroundView)
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
