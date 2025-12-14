//
//  BaseKeyboardViewController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit
import Combine
import OSLog

open class BaseKeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    /// Preview 모드 플래그 변수
    final public var isPreview: Bool = false
    final public var previewOneHandedMode: OneHandedMode = .center
    
    /// 전체 접근 허용 안내 필요 여부
    final public var needToShowFullAccessGuide: Bool {
        return !hasFullAccess && !keyboardSettingsManager.isRequestFullAccessOverlayClosed
    }
    
    /// 키보드 설정을 관리하는 `UserDefaultsManager`
    /// - 서브클래스 접근용
    final public let keyboardSettingsManager: UserDefaultsManager = UserDefaultsManager.shared
    
    final public lazy var oldKeyboardType: UIKeyboardType? = textDocumentProxy.keyboardType
    
    /// 현재 표시되는 키보드
    public lazy var currentKeyboard: SYKeyboardType = primaryKeyboardView.keyboard {
        didSet {
            didSetCurrentKeyboard()
        }
    }
    /// 현재 한 손 키보드 모드
    private var currentOneHandedMode: OneHandedMode {
        get {
            if isPreview {
                return previewOneHandedMode
            } else {
                return UserDefaultsManager.shared.lastOneHandedMode
            }
        }
        set {
            if isPreview {
                previewOneHandedMode = newValue
            } else {
                UserDefaultsManager.shared.lastOneHandedMode = newValue
            }
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
                                                                       hangeulKeyboardView: primaryKeyboardView as SwitchGestureHandling,
                                                                       englishKeyboardView: primaryKeyboardView as SwitchGestureHandling,
                                                                       symbolKeyboardView: symbolKeyboardView,
                                                                       numericKeyboardView: numericKeyboardView,
                                                                       getCurrentKeyboard: { [weak self] in return self?.currentKeyboard ?? .naratgeul },
                                                                       getCurrentOneHandedMode: { [weak self] in return self?.currentOneHandedMode ?? .center },
                                                                       getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
                                                                       setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button })
    /// 버튼 상태 컨트롤러
    public let buttonStateController = ButtonStateController()
    
    /// 텍스트 대치 데이터
    private var userLexicon: UILexicon?
    /// 텍스트 대치 기록
    private var textReplacementHistory: [String] = []
    
    /// 키보드 높이 제약 조건
    private var keyboardHeightConstraint: NSLayoutConstraint?
    
    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    
    /// '.' 단축키 수행 여부
    final public var performedPeriodShortcut: Bool = false
    /// 사용자가 '.' 단축키로 입력된 마침표를 지웠을 때, 다시 '.' 단축키가 실행되는 것을 막는 플래그
    final public var preventNextPeriodShortcut: Bool = false
    
    /// 기호 키보드에서 기호 입력 여부를 저장하는 변수
    private var isSymbolInput: Bool = false
    
    // MARK: - UI Components
    
    private lazy var keyboardView = KeyboardView(primaryKeyboardView: primaryKeyboardView)
    /// 키보드 전체 수직 스택
    private lazy var keyboardFrameHStackView = keyboardView.keyboardFrameHStackView
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private lazy var leftChevronButton = keyboardView.leftChevronButton
    /// 주 키보드(오버라이딩 필요)
    open var primaryKeyboardView: PrimaryKeyboardRepresentable { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 기호 키보드
    final public lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = keyboardView.symbolKeyboardView
    /// 숫자 키보드
    final public lazy var numericKeyboardView: NumericKeyboardLayoutProvider = keyboardView.numericKeyboardView
    /// 텐키 키보드
    final public lazy var tenkeyKeyboardView: TenkeyKeyboardLayoutProvider = keyboardView.tenkeyKeyboardView
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private lazy var rightChevronButton = keyboardView.rightChevronButton
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setNextKeyboardButton()
        if isPreview { updateReturnButtonType() }
        
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled { updateOneHandModekeyboard() }
        if UserDefaultsManager.shared.isTextReplacementEnabled {
            Task { userLexicon = await requestSupplementaryLexicon() }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isPreview { setKeyboardHeight() }
        FeedbackManager.shared.prepareHaptic()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let systemGestureRecognizer0 = self.view.window?.gestureRecognizers?[0] as? UIGestureRecognizer
        let systemGestureRecognizer1 = self.view.window?.gestureRecognizers?[1] as? UIGestureRecognizer
        systemGestureRecognizer0?.delaysTouchesBegan = false
        systemGestureRecognizer1?.delaysTouchesBegan = false
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in self.setKeyboardHeight() }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelTimer()
    }
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        updateKeyboardType()
        oldKeyboardType = textDocumentProxy.keyboardType
        updateReturnButtonType()
    }
    
    // MARK: - Overridable Methods
    
    open func didSetCurrentKeyboard() {
        updateShowingKeyboard()
        updateReturnButtonType()
    }
    
    /// 현재 보이는 키보드를  `currentKeyboard`에 맞게 변경하는 메서드
    open func updateShowingKeyboard() {
        primaryKeyboardView.isHidden = (currentKeyboard != primaryKeyboardView.keyboard)
        symbolKeyboardView.isHidden = (currentKeyboard != .symbol)
        symbolKeyboardView.initShiftButton()
        isSymbolInput = false
        numericKeyboardView.isHidden = (currentKeyboard != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboard != .tenKey)
    }
    
    /// `UIKeyboardType`에 맞는 키보드 레이아웃으로 업데이트하는 메서드
    open func updateKeyboardType() { fatalError("메서드가 오버라이딩 되지 않았습니다.") }
    
    /// 텍스트 상호작용이 일어나기 전 실행되는 메서드
    open func textInteractionWillPerform(button: TextInteractable) {
        if !(button is SpaceButton) && !(button is DeleteButton) {
            preventNextPeriodShortcut = false
            performedPeriodShortcut = false
        }
        tempDeletedCharacters.removeAll()
    }
    /// 텍스트 상호작용이 일어난 후 실행되는 메서드
    open func textInteractionDidPerform() {}
    
    /// 반복 텍스트 상호작용이 일어나기 전 실행되는 메서드
    open func repeatTextInteractionWillPerform(button: TextInteractable) {
        // 방어 코드
        cancelTimer()
    }
    /// 반복 텍스트 상호작용이 일어난 후 실행되는 메서드
    open func repeatTextInteractionDidPerform(button: TextInteractable) {
        cancelTimer()
        tempDeletedCharacters.removeAll()
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `primaryKeyList` 중 상황에 맞는 문자를 입력하는 메서드 (단일 호출)
    /// - `isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func insertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("primaryKeyList 배열이 비어있습니다.")
            return
        }
        textDocumentProxy.insertText(primaryKey)
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `secondaryKey`를 입력하는 메서드 (단일 호출)
    /// - `isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func insertSecondaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        textDocumentProxy.insertText(secondaryKey)
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `primaryKeyList` 중 상황에 맞는 문자를 입력하는 메서드 (반복 호출)
    /// - `isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        textDocumentProxy.insertText(primaryKey)
    }
    
    /// 공백 문자를 입력하는 메서드
    /// - `isPreview == true`이면 즉시 리턴
    open func insertSpaceText() {
        if isPreview { return }
        textDocumentProxy.insertText(" ")
    }
    /// 개행 문자를 입력하는 메서드
    /// - `isPreview == true`이면 즉시 리턴
    open func insertReturnText() {
        if isPreview { return }
        textDocumentProxy.insertText("\n")
    }
    
    /// 삭제가 일어나기 전 실행되는 메서드
    open func deleteBackwardWillPerform() {
        handlePeriodShortcutOnDelete()
    }
    
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (단일 호출)
    /// - `isPreview == true`이면 즉시 리턴
    open func deleteBackward() {
        if isPreview { return }
        
        deleteBackwardWillPerform()
        textDocumentProxy.deleteBackward()
    }
    
    /// 반복 삭제가 일어나기 전 실행되는 메서드
    open func repeatDeleteBackwardWillPerform() {
        handlePeriodShortcutOnDelete()
    }
    
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (반복 호출)
    /// - `isPreview == true`이면 즉시 리턴
    open func repeatDeleteBackward() {
        if isPreview || self.view.window == nil { return }
        
        repeatDeleteBackwardWillPerform()
        textDocumentProxy.deleteBackward()
    }
    
    // MARK: - Public Methods
    
    public func updateOneHandedWidthForPreview(to oneHandedWidth: Double) {
        keyboardView.updateOneHandedWidth(oneHandedWidth)
        self.view.layoutIfNeeded()
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
        self.view.addSubview(keyboardView)
    }
    
    func setConstraints() {
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: self.view.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    func setKeyboardHeight() {
        let keyboardHeight: CGFloat
        if let orientation = self.view.window?.windowScene?.effectiveGeometry.interfaceOrientation {
            keyboardHeight = (orientation == .portrait) ? UserDefaultsManager.shared.keyboardHeight : KeyboardLayoutFigure.landscapeKeyboardHeight
        } else {
            if !isPreview { assertionFailure("View가 window 계층에 없습니다.") }
            keyboardHeight = UserDefaultsManager.shared.keyboardHeight
        }
        
        if let keyboardHeightConstraint {
            keyboardHeightConstraint.constant = keyboardHeight
        } else {
            let constraint = self.view.heightAnchor.constraint(equalToConstant: keyboardHeight)
            constraint.priority = .init(999)
            constraint.isActive = true
            
            keyboardHeightConstraint = constraint
        }
    }
    
    func setNextKeyboardButton() {
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView].forEach {
            $0.updateNextKeyboardButton(needsInputModeSwitchKey: self.needsInputModeSwitchKey,
                                        nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        }
        
        UserDefaultsManager.shared.needsInputModeSwitchKey = self.needsInputModeSwitchKey

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
        let inputAction = UIAction { [weak self] action in
            guard let self, let currentButton = action.sender as? BaseKeyboardButton else { return }
            
            if currentButton.isProgrammaticCall {
                // 코드로 강제 호출된 경우 -> 무조건 입력 수행
                performTextInteraction(for: button)
                
            } else {
                // 사용자가 touchUpInside한 경우 -> currentPressedButton 확인
                if let currentPressedButton = buttonStateController.currentPressedButton,
                   currentPressedButton === button {
                    performTextInteraction(for: button)
                }
            }
        }
        if button is DeleteButton {
            button.addAction(inputAction, for: .touchDown)
        } else if let spaceButton = button as? SpaceButton {
            button.addAction(inputAction, for: .touchUpInside)
            addPeriodShortcutActionToSpaceButton(spaceButton)
        } else {
            button.addAction(inputAction, for: .touchUpInside)
        }
    }
    
    func addInputActionToSymbolTextInterableButton(_ button: TextInteractable) {
        addInputActionToTextInterableButton(button)
        
        switch button.type {
        case .keyButton(primary: ["’"], secondary: nil):
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
    
    func addPeriodShortcutActionToSpaceButton(_ button: SpaceButton) {
        if UserDefaultsManager.shared.isPeriodShortcutEnabled {
            let periodShortcutAction = UIAction { [weak self] _ in
                guard let self else { return }
                if isPreview || preventNextPeriodShortcut { return }
                
                guard let beforeText = textDocumentProxy.documentContextBeforeInput else { return }
                
                if beforeText.hasSuffix(" ") {
                    let textWithoutLastSpace = beforeText.dropLast()
                    
                    if let lastChar = textWithoutLastSpace.last,
                       (lastChar.isLetter || lastChar.isNumber) {
                        
                        textDocumentProxy.deleteBackward()
                        textDocumentProxy.insertText(".")
                        
                        performedPeriodShortcut = true
                    }
                }
            }
            button.addAction(periodShortcutAction, for: .touchDownRepeat)
        }
    }
    
    func addGesturesToTextInterableButton(_ button: TextInteractable) {
        guard !(button is ReturnButton) && !(button is SecondaryKeyButton) && !(button.type.primaryKeyList == [".com"]) else { return }
        
        if UserDefaultsManager.shared.isDragToMoveCursorEnabled
            || button is DeleteButton {
            // 팬(드래그) 제스처
            let panGesture = UIPanGestureRecognizer(target: textInteractionGestureController, action: #selector(textInteractionGestureController.panGestureHandler(_:)))
            panGesture.delegate = textInteractionGestureController
            button.addGestureRecognizer(panGesture)
        }
        
        if (UserDefaultsManager.shared.isLongPressToRepeatInputEnabled || UserDefaultsManager.shared.isLongPressToNumberInputEnabled)
            || button is DeleteButton {
            // 길게 누르기 제스처
            let longPressGesture = UILongPressGestureRecognizer(target: textInteractionGestureController, action: #selector(textInteractionGestureController.longPressGestureHandler(_:)))
            longPressGesture.delegate = textInteractionGestureController
            longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
            longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
            button.addGestureRecognizer(longPressGesture)
        }
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
        if UserDefaultsManager.shared.isNumericKeypadEnabled {
            // 팬(드래그) 제스처
            let keyboardSelectPanGesture = UIPanGestureRecognizer(target: switchGestureController, action: #selector(switchGestureController.keyboardSelectPanGestureHandler(_:)))
            keyboardSelectPanGesture.name = SwitchGestureController.PanGestureName.keyboardSelect.rawValue
            keyboardSelectPanGesture.delegate = switchGestureController
            button.addGestureRecognizer(keyboardSelectPanGesture)
        }
        
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled {
            // 팬(드래그) 제스처
            let oneHandedModeSelectPanGesture = UIPanGestureRecognizer(target: switchGestureController, action: #selector(switchGestureController.oneHandedModeSelectPanGestureHandler(_:)))
            oneHandedModeSelectPanGesture.delegate = switchGestureController
            button.addGestureRecognizer(oneHandedModeSelectPanGesture)
            
            // 길게 누르기 제스처
            let oneHandedModeSelectLongPressGesture = UILongPressGestureRecognizer(target: switchGestureController, action: #selector(switchGestureController.oneHandedModeLongPressGestureHandler(_:)))
            oneHandedModeSelectPanGesture.name = SwitchGestureController.PanGestureName.oneHandedModeSelect.rawValue
            oneHandedModeSelectLongPressGesture.delegate = switchGestureController
            oneHandedModeSelectLongPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
            oneHandedModeSelectLongPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
            button.addGestureRecognizer(oneHandedModeSelectLongPressGesture)
        }
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
    final public func performTextInteraction(for button: TextInteractable, insertSecondaryKeyIfAvailable: Bool = false) {
        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform() }
        
        switch button.type {
        case .keyButton:
            if insertSecondaryKeyIfAvailable && button.type.secondaryKey != nil {
                insertSecondaryKeyText(from: button)
            } else {
                insertPrimaryKeyText(from: button)
            }
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
    
    final public func performRepeatTextInteraction(for button: TextInteractable) {
        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform() }
        
        switch button.type {
        case .keyButton:
            repeatInsertPrimaryKeyText(from: button)
            button.playFeedback()
        case .deleteButton:
            if textDocumentProxy.documentContextBeforeInput != nil || textDocumentProxy.selectedText != nil {
                repeatDeleteBackward()
                button.playFeedback()
            } else {
                button.isGesturing = false
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

// MARK: - Private Methods

private extension BaseKeyboardViewController {
    func handlePeriodShortcutOnDelete() {
        guard UserDefaultsManager.shared.isPeriodShortcutEnabled else { return }
        
        if performedPeriodShortcut {
            preventNextPeriodShortcut = true
            performedPeriodShortcut = false
        } else if preventNextPeriodShortcut {
            if let lastChar = textDocumentProxy.documentContextBeforeInput?.last {
                if lastChar.isLetter || lastChar.isNumber {
                    preventNextPeriodShortcut = false
                }
            }
        }
    }
    
    func cancelTimer() {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
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
        if UserDefaultsManager.shared.isLongPressToRepeatInputEnabled
            || button is DeleteButton {
            repeatTextInteractionWillPerform(button: button)
            
            let repeatTimerInterval = 0.10 - UserDefaultsManager.shared.repeatRate
            timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    if self?.view.window == nil {
                        self?.cancelTimer()
                        return
                    }
                    
                    self?.performRepeatTextInteraction(for: button)
                }
            logger.debug("반복 타이머 생성")
        } else if UserDefaultsManager.shared.isLongPressToNumberInputEnabled {
            performTextInteraction(for: button, insertSecondaryKeyIfAvailable: true)
            button.isGesturing = false
        }
    }
    
    final func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable) {
        if UserDefaultsManager.shared.isLongPressToRepeatInputEnabled
            || button is DeleteButton {
            repeatTextInteractionDidPerform(button: button)
        }
    }
}
