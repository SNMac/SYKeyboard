//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

import SnapKit
import Then

/// 키보드 입력/UI 컨트롤러
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - Properties
    /// 현재 키보드
    private var currentKeyboardLayout: KeyboardLayout = .hangeul {
        didSet {
            updateKeyboardLayout()
        }
    }
    /// 현재 한 손 키보드
    private var currentOneHandedMode: OneHandedMode = .center {
        didSet {
            UserDefaultsManager.shared.lastOneHandedMode = currentOneHandedMode
            updateKeyboardConstraints()
        }
    }
    /// iPhone SE용 키보드 전환 버튼 액션
    private let nextKeyboardAction: Selector = #selector(handleInputModeList(from:with:))
    /// 키보드 제스처 컨트롤러
    private lazy var gestureController = GestureController(naratgeulKeyboardView: naratgeulKeyboardView,
                                                           symbolKeyboardView: symbolKeyboardView,
                                                           numericKeyboardView: numericKeyboardView,
                                                           getCurrentKeyboardLayout: { [weak self] in return self?.currentKeyboardLayout ?? .hangeul },
                                                           getCurrentOneHandedMode: { [weak self] in self?.currentOneHandedMode ?? .center })
    
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
    }
}

// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI() {
        setStyles()
        setDelegates()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.inputView?.backgroundColor = .clear
    }
    
    func setDelegates() {
        gestureController.delegate = self
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
        // 기호 키보드 전환
        let switchToSymbolKeyboard = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .symbol
        }
        naratgeulKeyboardView.switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        
        // 한글 키보드 전환
        let switchToHangeulKeyboard = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        symbolKeyboardView.switchButton.addAction(switchToHangeulKeyboard, for: .touchUpInside)
        numericKeyboardView.switchButton.addAction(switchToHangeulKeyboard, for: .touchUpInside)
        
        // 키보드 전환 버튼 제스쳐
        [naratgeulKeyboardView.switchButton,
         symbolKeyboardView.switchButton,
         numericKeyboardView.switchButton].forEach { addGesturesToSwitchButton($0) }
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        // 팬(드래그) 제스쳐
        let panGesture = UIPanGestureRecognizer(target: gestureController, action: #selector(gestureController.handleSwitchButtonPanGesture(_:)))
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스쳐
        let longPressGesture = UILongPressGestureRecognizer(target: gestureController, action: #selector(gestureController.handleSwitchButtonLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func setChevronButtonAction() {
        let resetOneHandMode = UIAction { [weak self] _ in
            self?.currentOneHandedMode = .center
        }
        leftChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
        rightChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
    }
}

// MARK: - GestureControllerDelegate

extension KeyboardInputViewController: GestureControllerDelegate {
    func changeKeyboardLayout(_ controller: GestureController, to newLayout: KeyboardLayout) {
        self.currentKeyboardLayout = newLayout
    }
    
    func changeOneHandedMode(_ controller: GestureController, to newMode: OneHandedMode) {
        self.currentOneHandedMode = newMode
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
        switch currentOneHandedMode {
        case .left, .right:
            keyboardLayoutView.snp.remakeConstraints {
                $0.width.equalTo(UserDefaultsManager.shared.oneHandedKeyboardWidth).priority(.high)
            }
        case .center:
            keyboardLayoutView.snp.removeConstraints()
        }
        leftChevronButton.isHidden = !(currentOneHandedMode == .right)
        rightChevronButton.isHidden = !(currentOneHandedMode == .left)
    }
}
