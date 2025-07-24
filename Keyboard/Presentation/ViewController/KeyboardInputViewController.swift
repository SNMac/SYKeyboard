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
    
    /// 로깅용
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    /// 현재 키보드
    private var currentKeyboardLayout: KeyboardLayout = .hangeul {
        didSet {
            updateKeyboardLayout()
        }
    }
    /// 현재 한 손 키보드
    private var currentOneHandMode: OneHandedMode = .center {
        didSet {
            UserDefaultsManager.shared.lastOneHandedMode = currentOneHandMode
            updateKeyboardConstraints()
        }
    }
    /// iPhone SE용 키보드 전환 버튼 액션
    private let nextKeyboardAction: Selector = #selector(handleInputModeList(from:with:))
    
    // MARK: - UI Components
    
    /// 키보드 전체 프레임
    private let keyboardFrameHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.backgroundColor = .clear
    }
    /// 키보드 뷰
    private let keyboardLayoutView = UIView().then {
        $0.backgroundColor = .clear
    }
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private let leftChevronButton = ChevronButton(direction: .left).then { $0.isHidden = true }
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView = NaratgeulKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                                   nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = false }
    /// 기호 키보드
    private lazy var symbolKeyboardView = SymbolKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                             nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = true }
    /// 숫자 키보드
    private lazy var numericKeyboardView = NumericKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                               nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = true }
    /// 텐키 키보드
    private lazy var tenkeyKeyboardView = TenkeyKeyboardView().then { $0.isHidden = true }
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
        
        keyboardLayoutView.addSubviews(naratgeulKeyboardView,
                                       symbolKeyboardView,
                                       numericKeyboardView,
                                       tenkeyKeyboardView)
    }
    
    func setConstraints() {
        keyboardFrameHStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(.high)
        }
        
        naratgeulKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        symbolKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        numericKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        tenkeyKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: - Button Action Methods

private extension KeyboardInputViewController {
    func setSwitchButtonAction() {
        // 한글 키보드 ➡️ 기호 키보드
        let hangeulSwithButtonTouchUpInside = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .symbol
        }
        naratgeulKeyboardView.switchButton.addAction(hangeulSwithButtonTouchUpInside, for: .touchUpInside)
        
        // 기호 키보드 ➡️ 한글 키보드
        let symbolSwitchButtonTapped = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        symbolKeyboardView.switchButton.addAction(symbolSwitchButtonTapped, for: .touchUpInside)
        // 기호 키보드 ➡️ 숫자 키보드
        let symbolSwitchButtonPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSymbolSwitchButtonPanGesture(_:)))
        symbolKeyboardView.switchButton.addGestureRecognizer(symbolSwitchButtonPanGesture)
        
        // 숫자 키보드 ➡️ 한글 키보드
        let numericSwitchButtonTapped = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        numericKeyboardView.switchButton.addAction(numericSwitchButtonTapped, for: .touchUpInside)
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
        naratgeulKeyboardView.isHidden = (currentKeyboardLayout != .hangeul)
        symbolKeyboardView.isHidden = (currentKeyboardLayout != .symbol)
        numericKeyboardView.isHidden = (currentKeyboardLayout != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboardLayout != .tenKey)
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
            let location = gesture.location(in: symbolKeyboardView.switchButton)
            if location.x > symbolKeyboardView.switchButton.bounds.maxX {
                currentKeyboardLayout = .numeric
            }
        }
    }
}
