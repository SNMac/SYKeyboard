//
//  BaseKeyboardViewController.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/12/25.
//

import UIKit
import Combine
import OSLog

import SnapKit
import Then

public class BaseKeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    /// 키보드 높이 제약 조건 할당 여부
    private var isHeightConstraintAdded: Bool = false
    
    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    
    /// 현재 표시되는 키보드
    lazy var currentKeyboard: Keyboard = primaryKeyboardView.keyboard {
        didSet {
            updateShowingKeyboard()
            updateReturnButtonType()
        }
    }
    /// 현재 한 손 키보드 모드
    private var currentOneHandedMode: OneHandedMode = UserDefaultsManager.shared.lastOneHandedMode {
        didSet {
            UserDefaultsManager.shared.lastOneHandedMode = currentOneHandedMode
            updateOneHandModekeyboard()
        }
    }
    /// 현재 키보드의 리턴 버튼
    private var currentReturnButton: ReturnButton? {
        switch currentKeyboard {
        case .hangeul, .english:
            return primaryKeyboardView.returnButton
        case .symbol:
            return symbolKeyboardView.returnButton
        case .numeric:
            return numericKeyboardView.returnButton
        default:
            return nil
        }
    }
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    
    // MARK: - UI Components
    
    /// 키보드 전체 수직 스택
    private let keyboardFrameHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.backgroundColor = .clear
    }
    /// 키보드 레이아웃 뷰
    private let keyboardLayoutView = UIView()
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private let leftChevronButton = ChevronButton(direction: .left).then { $0.isHidden = true }
    /// 주 키보드(오버라이딩 필요)
    var primaryKeyboardView: PrimaryKeyboard { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 기호 키보드
    final lazy var symbolKeyboardView: SymbolKeyboardLayout = SymbolKeyboardView().then { $0.isHidden = true }
    /// 숫자 키보드
    final lazy var numericKeyboardView: NumericKeyboardLayout = NumericKeyboardView().then { $0.isHidden = true }
    /// 텐키 키보드
    final lazy var tenkeyKeyboardView: TenkeyKeyboardLayout = TenkeyKeyboardView().then { $0.isHidden = true }
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private let rightChevronButton = ChevronButton(direction: .right).then { $0.isHidden = true }
    
    /// 키보드 전환 버튼 제스처 컨트롤러
    private lazy var switchButtonGestureController = SwitchButtonGestureController(keyboardFrameView: keyboardFrameHStackView,
                                                                                   hangeulKeyboardView: primaryKeyboardView as? SwitchButtonGestureHandler,
                                                                                   englishKeyboardView: primaryKeyboardView as? SwitchButtonGestureHandler,
                                                                                   symbolKeyboardView: symbolKeyboardView,
                                                                                   numericKeyboardView: numericKeyboardView,
                                                                                   getCurrentKeyboard: { [weak self] in return (self?.currentKeyboard)! },
                                                                                   getCurrentOneHandedMode: { [weak self] in self?.currentOneHandedMode ?? .center })
    /// 키 입력 버튼, 스페이스 버튼, 삭제 버튼 제스처 컨트롤러
    private lazy var textInteractionButtonGestureController = TextInteractionButtonGestureController(hangeulKeyboardView: primaryKeyboardView as? TextInteractionButtonGestureHandler,
                                                                                                     englishKeyboardView: primaryKeyboardView as? TextInteractionButtonGestureHandler,
                                                                                                     symbolKeyboardView: symbolKeyboardView,
                                                                                                     numericKeyboardView: numericKeyboardView,
                                                                                                     getCurrentKeyboard: { [weak self] in return (self?.currentKeyboard)! })
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setNextKeyboardButton()
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled {
            updateOneHandModekeyboard()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setKeyboardHeight()
        FeedbackManager.shared.prepareHaptic()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if DEBUG
        checkForAmbiguity(in: self.view)
        #endif
    }
    
    public override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateKeyboardAppearance()
        updateKeyboardType()
        updateReturnButtonType()
    }
    
    // MARK: - Overriable Methods
    
    func updateKeyboardType() {
        fatalError("메서드가 오버라이딩 되지 않았습니다.")
    }
}

// MARK: - UI Methods

private extension BaseKeyboardViewController {
    func setupUI() {
        setDelegates()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setDelegates() {
        textInteractionButtonGestureController.delegate = self
        switchButtonGestureController.delegate = self
    }
    
    func setActions() {
        setTextInteractionButtonAction()
        setSwitchButtonAction()
        setChevronButtonAction()
    }
    
    func setHierarchy() {
        self.view.addSubview(keyboardFrameHStackView)
        
        keyboardFrameHStackView.addArrangedSubviews(leftChevronButton, keyboardLayoutView, rightChevronButton)
        
        keyboardLayoutView.addSubviews(primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView)
    }
    
    func setConstraints() {
        // TODO: 가로모드
        keyboardFrameHStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        keyboardLayoutView.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(UserDefaultsManager.shared.oneHandedKeyboardWidth)
        }
        
        primaryKeyboardView.snp.makeConstraints {
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
    
    func setKeyboardHeight() {
        if !isHeightConstraintAdded, self.view.superview != nil {
            self.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(999)
            }
            isHeightConstraintAdded = true
        }
    }
    
    func setNextKeyboardButton() {
        primaryKeyboardView.updateNextKeyboardButton(needsInputModeSwitchKey: self.needsInputModeSwitchKey,
                                                     nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        symbolKeyboardView.updateNextKeyboardButton(needsInputModeSwitchKey: self.needsInputModeSwitchKey,
                                                    nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        numericKeyboardView.updateNextKeyboardButton(needsInputModeSwitchKey: self.needsInputModeSwitchKey,
                                                     nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
    }
    
    func checkForAmbiguity(in view: UIView) {
        if view.hasAmbiguousLayout {
            let message = "모호한 레이아웃이 존재합니다. - View: \(view), Identifier: \(view.accessibilityIdentifier ?? "없음")"
            logger.error("\(message)")
            view.exerciseAmbiguityInLayout()
        }
        
        // 모든 서브 뷰에 대해 재귀적으로 확인
        for subview in view.subviews {
            checkForAmbiguity(in: subview)
        }
    }
}

// MARK: - Button Action Methods

private extension BaseKeyboardViewController {
    func setTextInteractionButtonAction() {
        [primaryKeyboardView.totalTextInteractionButtonList,
         numericKeyboardView.totalTextInteractionButtonList,
         symbolKeyboardView.totalTextInteractionButtonList].forEach { buttonList in
            buttonList.forEach { addGesturesToTextInteractionButton($0) }
        }
    }
    
    func addGesturesToTextInteractionButton(_ button: TextInteractionButtonProtocol) {
        // 팬(드래그) 제스처
        let panGesture = UIPanGestureRecognizer(target: textInteractionButtonGestureController, action: #selector(textInteractionButtonGestureController.panGestureHandler(_:)))
        panGesture.delegate = textInteractionButtonGestureController
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스처
        let longPressGesture = UILongPressGestureRecognizer(target: textInteractionButtonGestureController, action: #selector(textInteractionButtonGestureController.longPressGestureHandler(_:)))
        longPressGesture.delegate = textInteractionButtonGestureController
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func setSwitchButtonAction() {
        // 기호 키보드 전환
        let switchToSymbolKeyboard = UIAction { [weak self] _ in
            self?.currentKeyboard = .symbol
        }
        primaryKeyboardView.switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        
        // 주 키보드 전환
        let switchToPrimaryKeyboard = UIAction { [weak self] _ in
            guard let self else { return }
            currentKeyboard = primaryKeyboardView.keyboard
        }
        symbolKeyboardView.switchButton.addAction(switchToPrimaryKeyboard, for: .touchUpInside)
        numericKeyboardView.switchButton.addAction(switchToPrimaryKeyboard, for: .touchUpInside)
        
        // 숫자 키보드, 한 손 키보드 전환
        [primaryKeyboardView.switchButton,
         symbolKeyboardView.switchButton,
         numericKeyboardView.switchButton].forEach { addGesturesToSwitchButton($0) }
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        // 팬(드래그) 제스처
        let panGesture = UIPanGestureRecognizer(target: switchButtonGestureController, action: #selector(switchButtonGestureController.panGestureHandler(_:)))
        panGesture.delegate = textInteractionButtonGestureController
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스처
        let longPressGesture = UILongPressGestureRecognizer(target: switchButtonGestureController, action: #selector(switchButtonGestureController.longPressGestureHandler(_:)))
        longPressGesture.delegate = textInteractionButtonGestureController
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

// MARK: - Update Methods

private extension BaseKeyboardViewController {
    func updateShowingKeyboard() {
        primaryKeyboardView.isHidden = (currentKeyboard != primaryKeyboardView.keyboard)
        primaryKeyboardView.initShiftButton()  // TODO: - 자동 대문자 설정
        symbolKeyboardView.isHidden = (currentKeyboard != .symbol)
        symbolKeyboardView.initShiftButton()
        numericKeyboardView.isHidden = (currentKeyboard != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboard != .tenKey)
    }
    
    func updateOneHandModekeyboard() {
        leftChevronButton.isHidden = !(currentOneHandedMode == .right)
        rightChevronButton.isHidden = !(currentOneHandedMode == .left)
    }
    
    func updateKeyboardAppearance() {
        // TODO: 키보드 라이트모드, 다크모드 전환 구현
    }
    
    func updateReturnButtonType() {
        let type = ReturnButton.ReturnKeyType(type: textDocumentProxy.returnKeyType)
        currentReturnButton?.update(for: type)
    }
}

// MARK: - Text Interaction Methods

private extension BaseKeyboardViewController {
    func performTextInteraction(for button: TextInteractionButton) {
        switch button {
        case .keyButton(let keys):
            textDocumentProxy.insertText("")
        case .deleteButton:
            textDocumentProxy.deleteBackward()
        case .spaceButton, .returnButton:
            guard let key = button.keys.first else { fatalError("옵셔널 언래핑 실패") }
            textDocumentProxy.insertText(key)
        }
    }
    
    func performRepeatTextInteraction(for button: TextInteractionButton) {
        switch button {
        case .keyButton(let keys):
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playKeyTypingSound()
        case .deleteButton:
            if let beforeCursor = textDocumentProxy.documentContextBeforeInput, !beforeCursor.isEmpty {
                textDocumentProxy.deleteBackward()
                FeedbackManager.shared.playHaptic()
                FeedbackManager.shared.playDeleteSound()
            }
        case .spaceButton:
            guard let key = button.keys.first else { fatalError("옵셔널 언래핑 실패") }
            textDocumentProxy.insertText(key)
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
}

// MARK: - SwitchButtonGestureControllerDelegate

extension BaseKeyboardViewController: SwitchButtonGestureControllerDelegate {
    final func changeKeyboard(_ controller: SwitchButtonGestureController, to newKeyboard: Keyboard) {
        self.currentKeyboard = newKeyboard
    }
    
    final func changeOneHandedMode(_ controller: SwitchButtonGestureController, to newMode: OneHandedMode) {
        self.currentOneHandedMode = newMode
    }
}

// MARK: - TextInteractionButtonGestureControllerDelegate

extension BaseKeyboardViewController: TextInteractionButtonGestureControllerDelegate {
    final func primaryButtonPanning(_ controller: TextInteractionButtonGestureController, to direction: PanDirection) {
        logger.debug("Primary Button 팬 제스처 방향: \(String(describing: direction))")
        
        switch direction {
        case .left:
            if textDocumentProxy.documentContextBeforeInput != nil {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
                FeedbackManager.shared.playHaptic(isForcing: true)
                logger.debug("커서 왼쪽 이동")
            }
        case .right:
            if textDocumentProxy.documentContextAfterInput != nil {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
                FeedbackManager.shared.playHaptic(isForcing: true)
                logger.debug("커서 오른쪽 이동")
            }
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
    
    final func deleteButtonPanning(_ controller: TextInteractionButtonGestureController, to direction: PanDirection) {
        logger.debug("DeleteButton 팬 제스처 방향: \(String(describing: direction))")
        
        switch direction {
        case .left:
            if let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput?.last {
                tempDeletedCharacters.append(lastBeforeCursor)
                textDocumentProxy.deleteBackward()
                FeedbackManager.shared.playHaptic()
                FeedbackManager.shared.playDeleteSound()
                logger.debug("커서 앞 글자 삭제")
            }
        case .right:
            if let lastDeleted = tempDeletedCharacters.popLast() {
                textDocumentProxy.insertText(String(lastDeleted))
                FeedbackManager.shared.playHaptic()
                FeedbackManager.shared.playDeleteSound()
                logger.debug("삭제된 글자 복구")
            }
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }
    
    final func deleteButtonPanStopped(_ controller: TextInteractionButtonGestureController) {
        tempDeletedCharacters.removeAll()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }
    
    final func textInteractionButtonLongPressing(_ controller: TextInteractionButtonGestureController, button: TextInteractionButton) {
        textInteractionButtonLongPressStopped(controller)
        
        let repeatTimerInterval = 0.10 - UserDefaultsManager.shared.repeatRate
        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performRepeatTextInteraction(for: button)
            }
        logger.debug("반복 타이머 생성")
    }
    
    final func textInteractionButtonLongPressStopped(_ controller: TextInteractionButtonGestureController) {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
    }
}
