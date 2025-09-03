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

/// 키보드 입력/UI 컨트롤러
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
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
    /// 키보드 전환 버튼 제스처 컨트롤러
    private lazy var switchButtonGestureController = SwitchButtonGestureController(naratgeulKeyboardView: naratgeulKeyboardView,
                                                                                   symbolKeyboardView: symbolKeyboardView,
                                                                                   numericKeyboardView: numericKeyboardView,
                                                                                   getCurrentKeyboardLayout: { [weak self] in return self?.currentKeyboardLayout ?? .hangeul },
                                                                                   getCurrentOneHandedMode: { [weak self] in self?.currentOneHandedMode ?? .center })
    /// 키 입력 버튼, 스페이스 버튼, 삭제 버튼 제스처 컨트롤러
    private lazy var primaryDeleteButtonGestureController = TextInteractionButtonGestureController(naratgeulKeyboardView: naratgeulKeyboardView,
                                                                                                 symbolKeyboardView: symbolKeyboardView,
                                                                                                 numericKeyboardView: numericKeyboardView,
                                                                                                 getCurrentKeyboardLayout: { [weak self] in return self?.currentKeyboardLayout ?? .hangeul })
    
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
        primaryDeleteButtonGestureController.delegate = self
        switchButtonGestureController.delegate = self
    }
    
    func setActions() {
        setTextInteractionButtonAction()
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
    func setTextInteractionButtonAction() {
        [naratgeulKeyboardView.totalTextInteractionButtonList,
         numericKeyboardView.totalTextInteractionButtonList,
         symbolKeyboardView.totalTextInteractionButtonList].forEach { buttonList in
            buttonList.forEach { addGesturesToPrimaryButton($0) }
        }
    }
    
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
    
    func setChevronButtonAction() {
        let resetOneHandMode = UIAction { [weak self] _ in
            self?.currentOneHandedMode = .center
        }
        leftChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
        rightChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
    }
    
    func addGesturesToPrimaryButton(_ button: TextInteractionButton) {
        // 팬(드래그) 제스쳐
        let panGesture = UIPanGestureRecognizer(target: primaryDeleteButtonGestureController, action: #selector(primaryDeleteButtonGestureController.panGestureHandler(_:)))
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스쳐
        let longPressGesture = UILongPressGestureRecognizer(target: primaryDeleteButtonGestureController, action: #selector(primaryDeleteButtonGestureController.longPressGestureHandler(_:)))
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        // 팬(드래그) 제스쳐
        let panGesture = UIPanGestureRecognizer(target: switchButtonGestureController, action: #selector(switchButtonGestureController.panGestureHandler(_:)))
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스쳐
        let longPressGesture = UILongPressGestureRecognizer(target: switchButtonGestureController, action: #selector(switchButtonGestureController.longPressGestureHandler(_:)))
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
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

// MARK: - SwitchButtonGestureControllerDelegate

extension KeyboardInputViewController: SwitchButtonGestureControllerDelegate {
    func changeKeyboardLayout(_ controller: SwitchButtonGestureController, to newLayout: KeyboardLayout) {
        self.currentKeyboardLayout = newLayout
    }
    
    func changeOneHandedMode(_ controller: SwitchButtonGestureController, to newMode: OneHandedMode) {
        self.currentOneHandedMode = newMode
    }
}

// MARK: - TextInteractionButtonGestureControllerDelegate

extension KeyboardInputViewController: TextInteractionButtonGestureControllerDelegate {
    func moveCursor(_ controller: TextInteractionButtonGestureController, to direction: PanDirection) {
        logger.debug("커서 이동 방향: \(String(describing: direction))")
        FeedbackManager.shared.playHaptic()
    }
    
    func repeatInput(_ controller: TextInteractionButtonGestureController) {
        
    }
}
