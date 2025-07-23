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
    
    private var currentOneHandMode: OneHandedMode = .center {
        didSet {
            UserDefaultsManager.shared.lastOneHandedMode = currentOneHandMode
            updateKeyboardConstraints()
        }
    }
    
    // MARK: - UI Components
    
    /// 키보드 전체 프레임
    private let keyboardFrameHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.backgroundColor = .clear
    }
    /// 키보드 레이아웃 컨테이너 뷰
    private let keyboardLayoutView = UIView().then {
        $0.backgroundColor = .clear
    }
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private let leftChevronButton = ChevronButton(direction: .left).then { $0.isHidden = true }
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
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private let rightChevronButton = ChevronButton(direction: .right).then { $0.isHidden = true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        currentOneHandMode = .left
    }
}
    
// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.inputView?.backgroundColor = .clear
    }
    
    func setActions() {
        setSwitchButtonAction()
        setChevronButtonAction()
    }
    
    func setHierarchy() {
        guard let inputView = self.inputView else { return }
        inputView.addSubview(keyboardFrameHStackView)
        
        keyboardFrameHStackView.addArrangedSubviews(leftChevronButton, keyboardLayoutView, rightChevronButton)
        
        keyboardLayoutView.addSubviews(hangeulView,
                                       symbolView,
                                       numericView,
                                       tenKeyView)
    }
    
    func setConstraints() {
        keyboardFrameHStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(.high)
        }
        
        hangeulView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        symbolView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        numericView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        tenKeyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
    
    func setChevronButtonAction() {
        let chevronButtonTouchUpInside = UIAction { [weak self] _ in
            self?.currentOneHandMode = .center
        }
        leftChevronButton.addAction(chevronButtonTouchUpInside, for: .touchUpInside)
        rightChevronButton.addAction(chevronButtonTouchUpInside, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension KeyboardInputViewController {
    func updateKeyboardLayout() {
        hangeulView.isHidden = (currentKeyboardLayout != .hangeul)
        symbolView.isHidden = (currentKeyboardLayout != .symbol)
        numericView.isHidden = (currentKeyboardLayout != .numeric)
        tenKeyView.isHidden = (currentKeyboardLayout != .tenKey)
    }
    
    func updateKeyboardConstraints() {
        switch currentOneHandMode {
        case .left:
            leftChevronButton.isHidden = true
            rightChevronButton.isHidden = false
            keyboardLayoutView.snp.remakeConstraints {
                $0.width.equalTo(UserDefaultsManager.shared.oneHandedKeyboardWidth)
            }
        case .right:
            leftChevronButton.isHidden = false
            rightChevronButton.isHidden = true
            keyboardLayoutView.snp.remakeConstraints {
                $0.width.equalTo(UserDefaultsManager.shared.oneHandedKeyboardWidth)
            }
        case .center:
            leftChevronButton.isHidden = true
            rightChevronButton.isHidden = true
            keyboardLayoutView.snp.removeConstraints()
        }
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
