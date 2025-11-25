//
//  BaseKeyboardButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

/// 키보드 버튼 베이스
class BaseKeyboardButton: UIButton {
    
    // MARK: - Properties
    
    final let insetDx: CGFloat
    final let insetDy: CGFloat
    final let cornerRadius: CGFloat
    
    final var isPressed: Bool = false {
        didSet {
            self.setNeedsUpdateConfiguration()
        }
    }
    
    final var isGesturing: Bool = false {
        didSet {
            self.setNeedsUpdateConfiguration()
        }
    }
    
    // MARK: - UI Components
    
    /// 배경 UI
    final lazy var backgroundView = ButtonBackgroundView(cornerRadius: self.cornerRadius)
    /// 그림자 UI
    final lazy var shadowView = ButtonShadowView(cornerRadius: self.cornerRadius)
    /// iOS 26 `UIButton.Configuration.attributedTitle` 애니메이션 해결용
    final let _titleLabel = UILabel().then {
        $0.textColor = .label
        $0.textAlignment = .center
    }
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType) {
        switch keyboard {
        case .naratgeul, .cheonjiin, .numeric, .tenKey:
            self.insetDx = 3
            self.insetDy = 2
        case .dubeolsik, .qwerty, .symbol:
            self.insetDx = 3
            self.insetDy = 4
        }
        if #available(iOS 26, *) {
            self.cornerRadius = 8.5
        } else {
            self.cornerRadius = 4.6
        }
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overridable Methods
    
    /// 햅틱 피드백, 사운드 피드백을 재생하는 메서드
    func playFeedback() { assertionFailure("메서드가 오버라이딩 되지 않았습니다.") }
}

// MARK: - UI Methods

private extension BaseKeyboardButton {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.tintColor = .clear
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.contentInsets = .zero
        buttonConfig.titleAlignment = .center
        buttonConfig.automaticallyUpdateForSelection = false
        self.configuration = buttonConfig
    }
    
    func setHierarchy() {
        self.insertSubview(shadowView, at: 0)
        self.insertSubview(backgroundView, at: 1)
        
        self.addSubview(_titleLabel)
    }
    
    func setConstraints() {
        shadowView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(insetDy)
            $0.leading.trailing.equalToSuperview().inset(insetDx)
        }
        
        backgroundView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(insetDy)
            $0.leading.trailing.equalToSuperview().inset(insetDx)
        }
        
        _titleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(insetDy)
            $0.leading.trailing.equalToSuperview().inset(insetDx)
        }
    }
}
