//
//  KeyboardRowHStackView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

/// 키보드 행
final public class KeyboardRowHStackView: UIStackView {
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Update Methods

public extension KeyboardRowHStackView {
    /// 지구본 표시 여부에 따라 modifier 버튼의 폭 분배를 전환합니다.
    ///
    /// 4x4 계열은 4행 스택이 전체 폭을 4등분해 modifier 영역 폭이 고정이므로,
    /// 지구본이 표시되면 세 버튼이 그 폭을 균등하게 나눠 갖는다.
    /// 지구본이 숨겨지면 한영 전환 버튼만 고정 폭을 쓰고 나머지는 전환 버튼이 채운다
    func updateModifierDistribution(
        languageSwitchWidthConstraint: NSLayoutConstraint,
        isNextKeyboardButtonVisible: Bool
    ) {
        // 분배를 바꾸는 순간 고정 폭 제약과 충돌하지 않도록 먼저 해제한다
        languageSwitchWidthConstraint.isActive = false
        self.distribution = isNextKeyboardButtonVisible ? .fillEqually : .fill
        languageSwitchWidthConstraint.isActive = !isNextKeyboardButtonVisible
    }
}

// MARK: - UI Methods

private extension KeyboardRowHStackView {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
        
        self.axis = .horizontal
        self.spacing = 0
        self.alignment = .fill
        self.distribution = .fillEqually
    }
}
