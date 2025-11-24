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
    lazy var currentKeyboard: SYKeyboardType = primaryKeyboardView.keyboard {
        didSet {
            didSetCurrentKeyboard()
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
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty:
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
                                                                       getCurrentKeyboard: { [weak self] in return self?.currentKeyboard ?? .naratgeul },
                                                                       getCurrentOneHandedMode: { [weak self] in return self?.currentOneHandedMode ?? .center },
                                                                       getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
                                                                       setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button })
    /// 버튼 상태 컨트롤러
    private(set) lazy var buttonStateController = ButtonStateController()
    
    /// 텍스트 대치 데이터
    private var userLexicon: UILexicon?
    /// 텍스트 대치 기록
    private var textReplacementHistory: [String] = []
    
    /// 키보드 높이 제약 조건 할당 여부
    private var isHeightConstraintAdded: Bool = false
    
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
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled { updateOneHandModekeyboard() }
        if UserDefaultsManager.shared.isTextReplacementEnabled {
            Task { userLexicon = await requestSupplementaryLexicon() }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setKeyboardHeight()
        FeedbackManager.shared.prepareHaptic()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let window = self.view.window else { fatalError("View가 window 계층에 없습니다.") }
        let systemGestureRecognizer0 = window.gestureRecognizers?[0] as? UIGestureRecognizer
        let systemGestureRecognizer1 = window.gestureRecognizers?[1] as? UIGestureRecognizer
        systemGestureRecognizer0?.delaysTouchesBegan = false
        systemGestureRecognizer1?.delaysTouchesBegan = false
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in self.setKeyboardHeight() }
    }
    
    public override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateKeyboardType()
        oldKeyboardType = textDocumentProxy.keyboardType
        updateReturnButtonType()
    }
    
    // MARK: - Overridable Methods
    
    func didSetCurrentKeyboard() {
        updateShowingKeyboard()
        updateReturnButtonType()
    }
    
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
    func updateKeyboardType() { fatalError("메서드가 오버라이딩 되지 않았습니다.") }
    
    /// 텍스트 상호작용이 일어나기 전 실행되는 메서드
    func textInteractionWillPerform() {
        tempDeletedCharacters.removeAll()
    }
    /// 텍스트 상호작용이 일어난 후 실행되는 메서드
    func textInteractionDidPerform() {}
    
    /// 반복 텍스트 상호작용이 일어나기 전 실행되는 메서드
    func repeatTextInteractionWillPerform(button: TextInteractable) {
        // 방어 코드
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
    }
    /// 반복 텍스트 상호작용이 일어난 후 실행되는 메서드
    func repeatTextInteractionDidPerform() {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
        
        tempDeletedCharacters.removeAll()
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `keys` 중 상황에 맞는 문자를 입력하는 메서드 (단일 호출)
    ///
    /// - Parameters:
    ///   - keys: `TextInteractable` 버튼에 입력할 수 있는 문자 배열
    func insertKeyText(from keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        textDocumentProxy.insertText(key)
    }
    /// 사용자가 탭한 `TextInteractable` 버튼의 `keys` 중 상황에 맞는 문자를 입력하는 메서드 (반복 호출)
    ///
    /// - Parameters:
    ///   - keys: `TextInteractable` 버튼에 입력할 수 있는 문자 배열
    func repeatInsertKeyText(from keys: [String]) {
        guard let key = keys.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        textDocumentProxy.insertText(key)
    }
    
    /// 공백 문자를 입력하는 메서드
    func insertSpaceText() { textDocumentProxy.insertText(" ") }
    /// 개행 문자를 입력하는 메서드
    func insertReturnText() { textDocumentProxy.insertText("\n") }
    
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (단일 호출)
    func deleteBackward() { textDocumentProxy.deleteBackward() }
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (반복 호출)
    func repeatDeleteBackward() { textDocumentProxy.deleteBackward() }
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
        let keyboardHeight: CGFloat
        if let orientation = self.view.window?.windowScene?.effectiveGeometry.interfaceOrientation {
            keyboardHeight = orientation == .portrait ? UserDefaultsManager.shared.keyboardHeight : KeyboardLayoutFigure.landscapeKeyboardHeight
        } else {
            assertionFailure("View가 window 계층에 없습니다.")
            keyboardHeight = UserDefaultsManager.shared.keyboardHeight
        }
        
        if !isHeightConstraintAdded {
            self.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.equalTo(keyboardHeight).priority(999)
            }
            isHeightConstraintAdded = true
        } else {
            self.view.snp.updateConstraints {
                $0.height.equalTo(keyboardHeight).priority(999)
            }
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
            performTextInteraction(for: button)
        }
        if button is DeleteButton {
            button.addAction(inputAction, for: .touchDown)
        } else {
            button.addAction(inputAction, for: .touchUpInside)
        }
    }
    
    func addInputActionToSymbolTextInterableButton(_ button: TextInteractable) {
        addInputActionToTextInterableButton(button)
        
        switch button.type {
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
        guard !(button is ReturnButton) && !(button is SecondaryKeyButton) && !(button.type.keys == [".com"]) else { return }
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
    
    func updateReturnButtonType() {
        let type = ReturnButton.ReturnKeyType(type: textDocumentProxy.returnKeyType)
        currentReturnButton?.update(for: type)
    }
}

// MARK: - Text Interaction Methods

extension BaseKeyboardViewController {
    final func performTextInteraction(for button: TextInteractable) {
        textInteractionWillPerform()
        defer { textInteractionDidPerform() }
        
        switch button.type {
        case .keyButton(let keys):
            insertKeyText(from: keys)
        case .deleteButton:
            if !attemptToRestoreReplacementWord() {
                if let selectedText = textDocumentProxy.selectedText {
                    tempDeletedCharacters.append(contentsOf: selectedText.reversed())
                } else if let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput?.last {
                    tempDeletedCharacters.append(lastBeforeCursor)
                }
                deleteBackward()
            }
        case .spaceButton:
            attemptToReplaceCurrentWord()
            insertSpaceText()
        case .returnButton:
            insertReturnText()
        }
    }
    
    final func performRepeatTextInteraction(for button: TextInteractable) {
        textInteractionWillPerform()
        defer { textInteractionDidPerform() }
        
        switch button.type {
        case .keyButton(let keys):
            repeatInsertKeyText(from: keys)
            button.playFeedback()
        case .deleteButton:
            if textDocumentProxy.documentContextBeforeInput != nil || textDocumentProxy.selectedText != nil {
                repeatDeleteBackward()
                button.playFeedback()
            }
        case .spaceButton:
            insertSpaceText()
            button.playFeedback()
        case .returnButton:
            insertReturnText()
            button.playFeedback()
        }
    }
    
    private func attemptToReplaceCurrentWord() {
        guard let entries = userLexicon?.entries,
              let beforeText = textDocumentProxy.documentContextBeforeInput else { return }
        
        let replacementEntries = entries.filter { beforeText.lowercased().hasSuffix($0.userInput.lowercased()) }
        
        guard let replacement = replacementEntries.max(by: { $0.userInput.count < $1.userInput.count }) else { return }
        
        for _ in 0..<replacement.userInput.count { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(replacement.documentText)
        
        textReplacementHistory.append(replacement.documentText)
    }
    
    private func attemptToRestoreReplacementWord() -> Bool {
        guard let entries = userLexicon?.entries,
              let beforeText = textDocumentProxy.documentContextBeforeInput,
              !textReplacementHistory.isEmpty else { return false }
        
        for replacedText in textReplacementHistory.reversed() {
            if beforeText.hasSuffix(replacedText) {
                if let entry = entries.first(where: { $0.documentText == replacedText }) {
                    for _ in 0..<entry.documentText.count { textDocumentProxy.deleteBackward() }
                    textDocumentProxy.insertText(entry.userInput)
                    
                    if let historyIndex = textReplacementHistory.firstIndex(of: entry.documentText) {
                        textReplacementHistory.remove(at: historyIndex)
                    }
                    return true
                }
            }
        }
        
        return false
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
        }
    }
    
    final func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        tempDeletedCharacters.removeAll()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }
    
    final func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {
        repeatTextInteractionWillPerform(button: button)
        
        let repeatTimerInterval = 0.10 - UserDefaultsManager.shared.repeatRate
        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performRepeatTextInteraction(for: button)
            }
        logger.debug("반복 타이머 생성")
    }
    
    final func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController) {
        repeatTextInteractionDidPerform()
    }
}
