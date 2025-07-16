//
//  PrimaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

import SnapKit

/// 입력 관련 키보드 버튼
class PrimaryButton: BaseKeyboardButton {
    
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
    
    // MARK: - Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.isHighlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHighlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.isHighlighted = false
    }
}

// MARK: - UI Methods

private extension PrimaryButton {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                self?.backgroundView.backgroundColor = .primaryButton
            case .highlighted:
                self?.backgroundView.backgroundColor = .primaryButtonPressed
                if UserDefaultsManager.shared.getIsSoundFeedbackEnabled { FeedbackManager.shared.playTypingSound() }
                if UserDefaultsManager.shared.getIsHapticFeedbackEnabled { FeedbackManager.shared.playHaptic() }
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
