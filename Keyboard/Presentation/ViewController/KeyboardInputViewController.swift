//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit
import OSLog

import SnapKit
import Then

/// 키보드 컨트롤러
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private var currentKeyboardLayout: KeyboardLayout = .hangeul {
        didSet {
            updateKeyboardLayout()
        }
    }
    
    // MARK: - UI Components
    
    /// 한글 키보드
    private lazy var hangeulView = HangeulView(nextKeyboardAction: needsInputModeSwitchKey ?
                                               #selector(handleInputModeList(from:with:)) : nil).then { $0.isHidden = false }
    /// 기호 키보드
    private lazy var symbolView = SymbolView(nextKeyboardAction: needsInputModeSwitchKey ?
                                             #selector(handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    /// 숫자 키보드
    private lazy var numericView = NumericView(nextKeyboardAction: needsInputModeSwitchKey ?
                                               #selector(handleInputModeList(from:with:)) : nil).then { $0.isHidden = true }
    /// 텐키 키보드
    private lazy var tenKeyView = TenKeyView().then { $0.isHidden = true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let inputView = self.inputView else { return }
        setupUI(inputView: inputView)
    }
}
    
// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI(inputView: UIInputView) {
        setStyles()
        setActions()
        setHierarchy(inputView: inputView)
        setConstraints(inputView: inputView)
    }
    
    func setStyles() {}
    
    func setActions() {
        setSwitchButtonAction()
    }
    
    func setHierarchy(inputView: UIInputView) {
        inputView.addSubviews(hangeulView,
                              symbolView,
                              numericView,
                              tenKeyView)
    }
    
    func setConstraints(inputView: UIInputView) {
        hangeulView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(.high)
        }
        
        symbolView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
        
        numericView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
        
        tenKeyView.snp.makeConstraints {
            $0.edges.equalTo(hangeulView)
        }
    }
}

// MARK: - Button Action Methods

private extension KeyboardInputViewController {
    func setSwitchButtonAction() {
        let hangeulSwithButtonTouchUpInside = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .symbol
        }
        hangeulView.switchButton.addAction(hangeulSwithButtonTouchUpInside, for: .touchUpInside)
        
        let symbolSwitchButtonTapped = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        symbolView.switchButton.addAction(symbolSwitchButtonTapped, for: .touchUpInside)
        let symbolSwitchButtonPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSymbolSwitchButtonPanGesture(_:)))
        symbolView.switchButton.addGestureRecognizer(symbolSwitchButtonPanGesture)
        
        let numericSwitchButtonTapped = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        numericView.switchButton.addAction(numericSwitchButtonTapped, for: .touchUpInside)
    }
    
    func updateKeyboardLayout() {
        hangeulView.isHidden = (currentKeyboardLayout != .hangeul)
        symbolView.isHidden = (currentKeyboardLayout != .symbol)
        numericView.isHidden = (currentKeyboardLayout != .numeric)
        tenKeyView.isHidden = (currentKeyboardLayout != .tenKey)
    }
}

// MARK: - @objc Button Gesture Methods

@objc private extension KeyboardInputViewController {
    func handleSymbolSwitchButtonPanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let location = gesture.location(in: symbolView.switchButton)
            if location.x > symbolView.switchButton.bounds.maxX {
                currentKeyboardLayout = .numeric
            }
        }
    }
}
