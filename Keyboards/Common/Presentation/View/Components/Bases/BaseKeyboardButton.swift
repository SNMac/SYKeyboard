//
//  BaseKeyboardButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

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
    
    // MARK: - UI Components
    
    /// 배경 UI
    final lazy var backgroundView = ButtonBackgroundView(cornerRadius: self.cornerRadius)
    /// 그림자 UI
    final lazy var shadowView = ButtonShadowView(cornerRadius: self.cornerRadius)
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType) {
        switch keyboard {
        case .hangeul, .numeric, .tenKey:
            self.insetDx = 3
            self.insetDy = 2
        case .english, .symbol:
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
        buttonConfig.baseForegroundColor = .label
        buttonConfig.automaticallyUpdateForSelection = false
        self.configuration = buttonConfig
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
