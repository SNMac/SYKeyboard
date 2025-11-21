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
    
    private(set) lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    final lazy var oldKeyboardType: UIKeyboardType? = textDocumentProxy.keyboardType
    
    /// 현재 표시되는 키보드
    final lazy var currentKeyboard: SYKeyboardType = primaryKeyboardView.keyboard {
        didSet {
            updateShowingKeyboard()
            updateReturnButtonType()
            updateShiftButton()
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
    
    /// 키 입력 버튼, 스페이스 버튼, 삭제 버튼 제스처 컨트롤러
    private lazy var textInteractionGestureController = TextInteractionGestureController(keyboardFrameView: keyboardFrameHStackView,
                                                                                         getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
                                                                                         setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button })
    
    /// 키보드 전환 버튼 제스처 컨트롤러
    private lazy var switchGestureController = SwitchGestureController(keyboardFrameView: keyboardFrameHStackView,
                                                                       hangeulKeyboardView: primaryKeyboardView as? SwitchGestureHandling,
                                                                       englishKeyboardView: primaryKeyboardView as? SwitchGestureHandling,
                                                                       symbolKeyboardView: symbolKeyboardView,
                                                                       numericKeyboardView: numericKeyboardView,
                                                                       getCurrentKeyboard: { [weak self] in return (self?.currentKeyboard)! },
                                                                       getCurrentOneHandedMode: { [weak self] in return (self?.currentOneHandedMode)! },
                                                                       getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
                                                                       setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button })
    /// 버튼 상태 컨트롤러
    private(set) lazy var buttonStateController = ButtonStateController()
    
    /// 키보드 높이 제약 조건 할당 여부
    private var isHeightConstraintAdded: Bool = false
    
    /// 마지막으로 입력한 문자
    private var lastInputText: String?
    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    /// 기호 키보드에서 기호 입력 여부를 저장하는 변수
    private var isSymbolInput: Bool = false
    
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
    var primaryKeyboardView: PrimaryKeyboardRepresentable { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 기호 키보드
    final lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = SymbolKeyboardView().then { $0.isHidden = true }
    /// 숫자 키보드
    final lazy var numericKeyboardView: NumericKeyboardLayoutProvider = NumericKeyboardView().then { $0.isHidden = true }
    /// 텐키 키보드
    final lazy var tenkeyKeyboardView: TenkeyKeyboardLayoutProvider = TenkeyKeyboardView().then { $0.isHidden = true }
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private let rightChevronButton = ChevronButton(direction: .right).then { $0.isHidden = true }
    
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
        let window = self.view.window!
        let systemGestureRecognizer0 = window.gestureRecognizers?[0] as? UIGestureRecognizer
        let systemGestureRecognizer1 = window.gestureRecognizers?[1] as? UIGestureRecognizer
        systemGestureRecognizer0?.delaysTouchesBegan = false
        systemGestureRecognizer1?.delaysTouchesBegan = false
    }
    
    public override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        logger.debug(#function)
        updateKeyboardAppearance()
        updateKeyboardType(oldKeyboardType: oldKeyboardType)
        oldKeyboardType = textDocumentProxy.keyboardType
        updateReturnButtonType()
        updateShiftButton()
    }
    
    // MARK: - Overridable Methods
    
    /// 현재 보이는 키보드를  `currentKeyboard`에 맞게 변경하는 메서드
    func updateShowingKeyboard() {
        primaryKeyboardView.isHidden = (currentKeyboard != primaryKeyboardView.keyboard)
        symbolKeyboardView.isHidden = (currentKeyboard != .symbol)
        symbolKeyboardView.initShiftButton()
        isSymbolInput = false
        numericKeyboardView.isHidden = (currentKeyboard != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboard != .tenKey)
    }
    
    /// `UIKeyboardType`에 맞는 키보드 레이아웃으로 업데이트하는 메서드
    ///
    /// - Parameters:
    ///   - oldKeyboardType: 이전 `UIKeyboardType`
    func updateKeyboardType(oldKeyboardType: UIKeyboardType?) { fatalError("메서드가 오버라이딩 되지 않았습니다.") }
    
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {}
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `keys` 중 상황에 맞는 문자를 반환하는 메서드
    ///
    /// - Parameters:
    ///   - keys: `TextInteractable` 버튼에 입력할 수 있는 문자 배열
    /// - Returns: 입력할 문자
    func getInputText(from keys: [String]) -> String { fatalError("메서드가 오버라이딩 되지 않았습니다.") }
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
        textInteractionGestureController.delegate = self
        switchGestureController.delegate = self
    }
    
    func setActions() {
        setButtonFeedbackAction()
        setTextInteractableButtonAction()
        setSwitchButtonAction()
        setExclusiveButtonAction()
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
    func setButtonFeedbackAction() {
        let allButtonList = (primaryKeyboardView.allButtonList
                             + symbolKeyboardView.allButtonList
                             + numericKeyboardView.allButtonList
                             + tenkeyKeyboardView.allButtonList)
        buttonStateController.setFeedbackActionToButtons(allButtonList)
    }
    
    func setTextInteractableButtonAction() {
        (primaryKeyboardView.totalTextInterableButtonList + numericKeyboardView.totalTextInterableButtonList).forEach {
            addInputActionToTextInterableButton($0)
            addGesturesToTextInterableButton($0)
        }
        
        symbolKeyboardView.totalTextInterableButtonList.forEach {
            addInputActionToSymbolTextInterableButton($0)
            addGesturesToTextInterableButton($0)
        }
        
        tenkeyKeyboardView.totalTextInterableButtonList.forEach { addInputActionToTextInterableButton($0) }
    }
    
    func addInputActionToTextInterableButton(_ button: TextInteractable) {
        let inputAction = UIAction { [weak self] _ in
            guard let self,
                  let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton === button else { return }
            performTextInteraction(for: button.button)
        }
        if button is DeleteButton {
            button.addAction(inputAction, for: .touchDown)
        } else {
            button.addAction(inputAction, for: .touchUpInside)
        }
    }
    
    func addInputActionToSymbolTextInterableButton(_ button: TextInteractable) {
        addInputActionToTextInterableButton(button)
        
        switch button.button {
        case .keyButton(keys: ["‘"]):
            // touchUpInside 되었을 때 ➡️ 주 키보드 전환
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if textDocumentProxy.keyboardType != .numbersAndPunctuation && UserDefaultsManager.shared.isAutoChangeToPrimaryEnabled {
                    currentKeyboard = primaryKeyboardView.keyboard
                }
            }
            button.addAction(switchToPrimaryKeyboard, for: .touchUpInside)
            
        case .spaceButton, .returnButton:
            // 이전에 기호가 입력되고 난 후 touchUpInside 되었을 때 ➡️ 주 키보드 전환
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if textDocumentProxy.keyboardType != .numbersAndPunctuation && UserDefaultsManager.shared.isAutoChangeToPrimaryEnabled && isSymbolInput {
                    currentKeyboard = primaryKeyboardView.keyboard
                }
            }
            button.addAction(switchToPrimaryKeyboard, for: .touchUpInside)
            
        case .deleteButton:
            break
            
        default:
            let additionalInputAction = UIAction { [weak self] _ in self?.isSymbolInput = true }
            button.addAction(additionalInputAction, for: .touchUpInside)
        }
    }
    
    func addGesturesToTextInterableButton(_ button: TextInteractable) {
        guard !(button is ReturnButton) && !(button is SecondaryKeyButton) && !(button.button.keys == [".com"]) else { return }
        // 팬(드래그) 제스처
        let panGesture = UIPanGestureRecognizer(target: textInteractionGestureController, action: #selector(textInteractionGestureController.panGestureHandler(_:)))
        panGesture.delegate = textInteractionGestureController
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스처
        let longPressGesture = UILongPressGestureRecognizer(target: textInteractionGestureController, action: #selector(textInteractionGestureController.longPressGestureHandler(_:)))
        longPressGesture.delegate = textInteractionGestureController
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func setSwitchButtonAction() {
        // 기호 키보드 전환
        let switchToSymbolKeyboard = UIAction { [weak self] action in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton === primaryKeyboardView.switchButton else { return }
            currentKeyboard = .symbol
        }
        primaryKeyboardView.switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        
        // 주 키보드 전환
        let switchToPrimaryKeyboardForSymbol = UIAction { [weak self] _ in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton === symbolKeyboardView.switchButton else { return }
            currentKeyboard = primaryKeyboardView.keyboard
        }
        symbolKeyboardView.switchButton.addAction(switchToPrimaryKeyboardForSymbol, for: .touchUpInside)
        
        let switchToPrimaryKeyboardForNumeric = UIAction { [weak self] _ in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton === numericKeyboardView.switchButton else { return }
            currentKeyboard = primaryKeyboardView.keyboard
        }
        numericKeyboardView.switchButton.addAction(switchToPrimaryKeyboardForNumeric, for: .touchUpInside)
        
        // 숫자 키보드, 한 손 키보드 전환
        [primaryKeyboardView.switchButton,
         symbolKeyboardView.switchButton,
         numericKeyboardView.switchButton].forEach { addGesturesToSwitchButton($0) }
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        // 팬(드래그) 제스처
        let panGesture = UIPanGestureRecognizer(target: switchGestureController, action: #selector(switchGestureController.panGestureHandler(_:)))
        panGesture.delegate = textInteractionGestureController
        button.addGestureRecognizer(panGesture)
        
        // 길게 누르기 제스처
        let longPressGesture = UILongPressGestureRecognizer(target: switchGestureController, action: #selector(switchGestureController.longPressGestureHandler(_:)))
        longPressGesture.delegate = textInteractionGestureController
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func setExclusiveButtonAction() {
        let allButtonList = (primaryKeyboardView.allButtonList
                             + symbolKeyboardView.allButtonList
                             + numericKeyboardView.allButtonList
                             + tenkeyKeyboardView.allButtonList)
        buttonStateController.setExclusiveActionToButtons(allButtonList)
    }
    
    func setChevronButtonAction() {
        let resetOneHandMode = UIAction { [weak self] _ in self?.currentOneHandedMode = .center }
        leftChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
        rightChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension BaseKeyboardViewController {
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
    func performTextInteraction(for button: TextInteractableType) {
        tempDeletedCharacters.removeAll()
        
        switch button {
        case .keyButton(let keys):
            let inputText = getInputText(from: keys)
            textDocumentProxy.insertText(inputText)
            lastInputText = inputText
        case .deleteButton:
            if let selectedText = textDocumentProxy.selectedText {
                tempDeletedCharacters.append(contentsOf: selectedText.reversed())
                textDocumentProxy.deleteBackward()
            } else if let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput?.last {
                tempDeletedCharacters.append(lastBeforeCursor)
                textDocumentProxy.deleteBackward()
            }
        case .spaceButton, .returnButton:
            guard let key = button.keys.first else { fatalError("옵셔널 언래핑 실패") }
            textDocumentProxy.insertText(key)
        }
        
        updateShiftButton()
    }
    
    func performRepeatTextInteraction(for button: TextInteractableType) {
        switch button {
        case .keyButton(let keys):
            textDocumentProxy.insertText(lastInputText ?? "")
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playKeyTypingSound()
        case .deleteButton:
            if textDocumentProxy.documentContextBeforeInput != nil || textDocumentProxy.selectedText != nil {
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
            logger.error("도달할 수 없는 case 입니다.")
        }
        
        updateShiftButton()
    }
}

// MARK: - SwitchGestureControllerDelegate

extension BaseKeyboardViewController: SwitchGestureControllerDelegate {
    final func changeKeyboard(_ controller: SwitchGestureController, to newKeyboard: SYKeyboardType) {
        self.currentKeyboard = newKeyboard
    }
    
    final func changeOneHandedMode(_ controller: SwitchGestureController, to newMode: OneHandedMode) {
        self.currentOneHandedMode = newMode
    }
}

// MARK: - TextInteractionGestureControllerDelegate

extension BaseKeyboardViewController: TextInteractionGestureControllerDelegate {
    final func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {
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
            logger.error("도달할 수 없는 case 입니다.")
        }
    }
    
    final func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {
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
            logger.error("도달할 수 없는 case 입니다.")
        }
    }
    
    final func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        tempDeletedCharacters.removeAll()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }
    
    final func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {
        textInteractableButtonLongPressStopped(controller)
        
        let repeatTimerInterval = 0.10 - UserDefaultsManager.shared.repeatRate
        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.performRepeatTextInteraction(for: button.button) }
        logger.debug("반복 타이머 생성")
    }
    
    final func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController) {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
        tempDeletedCharacters.removeAll()
        lastInputText = nil
    }
}
