//
//  KeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 11/25/25.
//

import UIKit

final class KeyboardView: UIView {
    
    // MARK: - Properties
    
    private var keyboardLayoutWidthConstraint: NSLayoutConstraint?
    
    // MARK: - UI Components
    
    /// 키보드 전체 수직 스택
    private let keyboardFrameHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.backgroundColor = .clear
        
        return stackView
    }()
    /// 키보드 레이아웃 뷰
    let keyboardLayoutView = UIView()
    /// 한 손 키보드 해제 버튼(오른손 모드)
    let leftChevronButton: ChevronButton = {
        let chevronButton = ChevronButton(direction: .left)
        chevronButton.isHidden = true
        
        return chevronButton
    }()
    /// 주 키보드
    let primaryKeyboardView: PrimaryKeyboardRepresentable
    /// 기호 키보드
    final lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = {
        let symbolKeyboardView = SymbolKeyboardView()
        symbolKeyboardView.isHidden = true
        
        return symbolKeyboardView
    }()
    /// 숫자 키보드
    final lazy var numericKeyboardView: NumericKeyboardLayoutProvider = {
        let numericKeyboardView = NumericKeyboardView()
        numericKeyboardView.isHidden = true
        
        return numericKeyboardView
    }()
    /// 텐키 키보드
    final lazy var tenkeyKeyboardView: TenkeyKeyboardLayoutProvider = {
        let tenkeyKeyboardView = TenkeyKeyboardView()
        tenkeyKeyboardView.isHidden = true
        
        return tenkeyKeyboardView
    }()
    /// 한 손 키보드 해제 버튼(왼손 모드)
    let rightChevronButton: ChevronButton = {
        let chevronButton = ChevronButton(direction: .right)
        chevronButton.isHidden = true
        
        return chevronButton
    }()
    
    // MARK: - Initializer
    
    init(primaryKeyboardView: PrimaryKeyboardRepresentable) {
        self.primaryKeyboardView = primaryKeyboardView
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 한 손 키보드 너비 업데이트를 업데이트하는 메서드
    public func updateOneHandedWidth(_ width: Double) {
        keyboardLayoutWidthConstraint?.constant = width
        self.layoutIfNeeded()
    }
}

// MARK: - UI Methods

private extension KeyboardView {
    func setupUI() {
        setHierarchy()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addSubview(keyboardFrameHStackView)
        
        [leftChevronButton, keyboardLayoutView, rightChevronButton].forEach { keyboardFrameHStackView.addArrangedSubview($0) }
        
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView].forEach { keyboardLayoutView.addSubview($0) }
    }
    
    func setConstraints() {
        keyboardFrameHStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardFrameHStackView.topAnchor.constraint(equalTo: self.topAnchor),
            keyboardFrameHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            keyboardFrameHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            keyboardFrameHStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        keyboardLayoutView.translatesAutoresizingMaskIntoConstraints = false
        let minWidth = UserDefaultsManager.shared.oneHandedKeyboardWidth
        keyboardLayoutWidthConstraint = keyboardLayoutView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth)
        keyboardLayoutWidthConstraint?.priority = .init(999)
        keyboardLayoutWidthConstraint?.isActive = true
        
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: keyboardLayoutView.topAnchor),
                $0.leadingAnchor.constraint(equalTo: keyboardLayoutView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: keyboardLayoutView.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: keyboardLayoutView.bottomAnchor)
            ])
        }
    }
}
