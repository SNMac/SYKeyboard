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
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// Preview 모드 플래그 변수
    public static var isPreview: Bool = false
    final public var previewOneHandedMode: OneHandedMode = .center
    public var onPreviewOneHandedModeChanged: ((OneHandedMode) -> Void)?
    
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
            if BaseKeyboardViewController.isPreview {
                return previewOneHandedMode
            } else {
                return UserDefaultsManager.shared.lastOneHandedMode
            }
        }
        set {
            if BaseKeyboardViewController.isPreview {
                previewOneHandedMode = newValue
                onPreviewOneHandedModeChanged?(newValue)
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
    private lazy var textInteractionGestureController = TextInteractionGestureController(
        keyboardHStackView: keyboardHStackView,
        getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
        setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button }
    )
    
    /// 키보드 전환 버튼 제스처 컨트롤러
    private lazy var switchGestureController = SwitchGestureController(
        keyboardHStackView: keyboardHStackView,
        hangeulKeyboardView: primaryKeyboardView as SwitchGestureHandling,
        englishKeyboardView: primaryKeyboardView as SwitchGestureHandling,
        symbolKeyboardView: symbolKeyboardView,
        numericKeyboardView: numericKeyboardView,
        getCurrentKeyboard: { [weak self] in return self?.currentKeyboard ?? .naratgeul },
        getCurrentOneHandedMode: { [weak self] in return self?.currentOneHandedMode ?? .center },
        getCurrentPressedButton: { [weak self] in self?.buttonStateController.currentPressedButton },
        setCurrentPressedButton: { [weak self] button in self?.buttonStateController.currentPressedButton = button }
    )
    /// 버튼 상태 컨트롤러
    public let buttonStateController = ButtonStateController()
    
    /// 자동완성 텍스트 제안 컨트롤러
    private let suggestionController: SuggestionService
    
    /// 현재 키보드 세션에서 직접 입력한 텍스트를 추적하는 버퍼
    ///
    /// `documentContextBeforeInput` 대신 이 버퍼를 사용하여
    /// 다른 키보드에서 입력한 텍스트나 앱이 미리 채운 텍스트가
    /// n-gram 학습에 포함되는 것을 방지합니다.
    ///
    /// 커서 이동, 키보드 열림/닫힘 시 초기화됩니다.
    /// 서브클래스에서는 `insertText`, `deleteText`, `replaceText`,
    /// `resetInputBuffer` 래핑 메서드를 통해 조작합니다.
    private var inputBuffer: String = ""
    
    /// `KeyboardView` 높이 제약 조건
    private var keyboardViewHeightConstraint: NSLayoutConstraint?
    /// `keyboardHStackView` 높이 제약 조건
    private var keyboardHStackViewHeightConstraint: NSLayoutConstraint?
    
    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    /// 현재 반복 입력 동작 중인지 확인하는 플래그
    public private(set) var isRepeatingInput: Bool = false
    
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    
    /// '.' 단축키 수행 여부
    final public var performedPeriodShortcut: Bool = false
    /// 사용자가 '.' 단축키로 입력된 마침표를 지웠을 때, 다시 '.' 단축키가 실행되는 것을 막는 플래그
    final public var preventNextPeriodShortcut: Bool = false
    
    /// 기호 키보드에서 기호 입력 여부를 저장하는 변수
    private var isSymbolInput: Bool = false
    
    // MARK: - UI Components
    
    private lazy var keyboardView: KeyboardView = {
        return KeyboardView.loadFromNib(primaryKeyboardView: primaryKeyboardView)
    }()
    /// 자동완성 툴바
    private lazy var suggestionBarHStackView = keyboardView.suggestionBarHStackView
    /// 키보드 수평 스택
    private lazy var keyboardHStackView = keyboardView.keyboardHStackView
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
    
    // MARK: - Initializer
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.suggestionController = SuggestionController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public init(language: String) {
        self.suggestionController = SuggestionController(language: language)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
    
    // MARK: - Lifecycle
    
    open override func loadView() {
        self.view = keyboardView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        resetInputBuffer()
        setupUI()
        setNextKeyboardButton()
        if BaseKeyboardViewController.isPreview { updateReturnButtonType() }
        
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled { updateOneHandModekeyboard() }
        if UserDefaultsManager.shared.isTextReplacementEnabled
            || UserDefaultsManager.shared.isPredictiveTextEnabled {
            suggestionController.loadLexicon(from: self)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !BaseKeyboardViewController.isPreview { setKeyboardHeight() }
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
        coordinator.animate { [weak self] _ in self?.setKeyboardHeight() }
    }
    
    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        resetInputBuffer()
        updateKeyboardType()
        updateReturnButtonType()
        updateSuggestionBarHidden()
        oldKeyboardType = textDocumentProxy.keyboardType
        
        if UserDefaultsManager.shared.isPredictiveTextEnabled {
            suggestionController.updateSuggestions(inputBuffer: inputBuffer)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelTimer()
        resetInputBuffer()
        suggestionController.saveNGramData()
    }
    
    // MARK: - Overridable Methods
    
    open func didSetCurrentKeyboard() {
        updateShowingKeyboard()
        updateReturnButtonType()
    }
    
    /// `UIKeyboardType`에 맞는 키보드 레이아웃으로 업데이트하는 메서드
    open func updateKeyboardType() { fatalError("메서드가 오버라이딩 되지 않았습니다.") }
    
    /// 텍스트 상호작용이 일어나기 전 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func textInteractionWillPerform(button: TextInteractable) {
        if !(button is SpaceButton) && !(button is DeleteButton) {
            preventNextPeriodShortcut = false
            performedPeriodShortcut = false
        }
        
        if !(button is SpaceButton) {
            suggestionController.clearIgnoredShortcut()
        }
        
        tempDeletedCharacters.removeAll()
    }
    /// 텍스트 상호작용이 일어난 후 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func textInteractionDidPerform(button: TextInteractable) {
        if !isRepeatingInput && UserDefaultsManager.shared.isPredictiveTextEnabled {
            suggestionController.updateSuggestions(inputBuffer: inputBuffer)
        }
    }
    
    /// SuggestionBar에서 후보를 선택하여 텍스트가 교체된 후 호출되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func suggestionDidApply() {}
    
    /// 반복 텍스트 상호작용이 일어나기 전 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func repeatTextInteractionWillPerform(button: TextInteractable) {
        // 방어 코드
        cancelTimer()
        isRepeatingInput = true
    }
    /// 반복 텍스트 상호작용이 일어난 후 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func repeatTextInteractionDidPerform(button: TextInteractable) {
        cancelTimer()
        tempDeletedCharacters.removeAll()
        isRepeatingInput = false
        
        if UserDefaultsManager.shared.isPredictiveTextEnabled {
            suggestionController.updateSuggestions(inputBuffer: inputBuffer)
        }
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `primaryKeyList` 중 상황에 맞는 문자를 입력하는 메서드 (단일 호출)
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("primaryKeyList 배열이 비어있습니다.")
            return
        }
        insertText(primaryKey)
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `secondaryKey`를 입력하는 메서드 (단일 호출)
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        insertText(secondaryKey)
    }
    
    /// 사용자가 탭한 `TextInteractable` 버튼의 `primaryKeyList` 중 상황에 맞는 문자를 입력하는 메서드 (반복 호출)
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    ///
    /// - Parameters:
    ///   - button: `TextInteractable` 버튼
    open func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else {
            assertionFailure("keys 배열이 비어있습니다.")
            return
        }
        insertText(primaryKey)
    }
    
    /// 공백 문자를 입력하는 메서드
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    open func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }
        
        // 스페이스 입력 전 직전 단어를 n-gram에 기록
        let lastWord: String
        if let spaceIndex = inputBuffer.lastIndex(where: { $0.isWhitespace }) {
            lastWord = String(inputBuffer[inputBuffer.index(after: spaceIndex)...])
        } else {
            lastWord = inputBuffer
        }
        
        if !lastWord.isEmpty {
            suggestionController.recordWord(lastWord)
        }
        
        insertText(" ")
    }
    
    /// 개행 문자를 입력하는 메서드
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    open func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }
        textDocumentProxy.insertText("\n")
        resetInputBuffer()
        suggestionController.clearReplacementHistory()
        suggestionController.endSentence()
    }
    
    /// 삭제가 일어나기 전 실행되는 메서드
    open func deleteBackwardWillPerform() {
        handlePeriodShortcutOnDelete()
    }
    
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (단일 호출)
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    ///
    /// > 하위 클래스에서 오버라이드 시 텍스트 수정 작업 전 반드시
    /// `super.deleteBackwardWillPerform` 호출 필요
    open func deleteBackward() {
        if BaseKeyboardViewController.isPreview { return }
        
        deleteBackwardWillPerform()
        deleteText()
    }
    
    /// 반복 삭제가 일어나기 전 실행되는 메서드
    open func repeatDeleteBackwardWillPerform() {
        handlePeriodShortcutOnDelete()
    }
    
    /// 문자열 입력 UI의 텍스트를 삭제하는 메서드 (반복 호출)
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    ///
    /// > 하위 클래스에서 오버라이드 시 텍스트 수정 작업 전 반드시
    /// `super.repeatDeleteBackwardWillPerform` 호출 필요
    open func repeatDeleteBackward() {
        if BaseKeyboardViewController.isPreview || self.view.window == nil { return }
        
        repeatDeleteBackwardWillPerform()
        deleteText()
    }
    
    // MARK: - Public Methods
    
    public func updateOneHandedWidthForPreview(to oneHandedWidth: Double) {
        keyboardView.updateOneHandedWidth(oneHandedWidth)
        self.view.layoutIfNeeded()
    }
}

// MARK: - Text Proxy Wrapper Methods

extension BaseKeyboardViewController {
    /// `textDocumentProxy`에 텍스트를 삽입하고 `inputBuffer`를 동기화합니다.
    ///
    /// `textDocumentProxy.insertText`를 직접 호출하는 대신 이 메서드를 사용하여
    /// 입력 버퍼가 항상 실제 입력과 일치하도록 보장합니다.
    ///
    /// - Parameter text: 삽입할 텍스트
    public func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
        inputBuffer.append(text)
    }
    
    /// `textDocumentProxy`에서 1글자를 삭제하고 `inputBuffer`를 동기화합니다.
    ///
    /// `textDocumentProxy.deleteBackward()`를 직접 호출하는 대신 이 메서드를 사용하여
    /// 입력 버퍼가 항상 실제 입력과 일치하도록 보장합니다.
    public func deleteText() {
        textDocumentProxy.deleteBackward()
        if !inputBuffer.isEmpty {
            inputBuffer.removeLast()
        }
    }
    
    /// `textDocumentProxy`에서 여러 글자를 삭제한 후 새 텍스트를 삽입하고
    /// `inputBuffer`를 동기화합니다.
    ///
    /// 한글 오토마타의 delete → reinsert 패턴이나 텍스트 대치/복구에 사용합니다.
    ///
    /// - Parameters:
    ///   - deleteCount: 삭제할 글자 수
    ///   - text: 삭제 후 삽입할 텍스트
    public func replaceText(deleteCount: Int, insert text: String) {
        for _ in 0..<deleteCount {
            textDocumentProxy.deleteBackward()
        }
        if !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
        
        if inputBuffer.count >= deleteCount {
            inputBuffer.removeLast(deleteCount)
        } else {
            inputBuffer = ""
        }
        inputBuffer.append(text)
    }
    
    /// 입력 버퍼를 초기화합니다.
    ///
    /// 커서 이동, 키보드 열림/닫힘 등 버퍼와 실제 텍스트 위치가
    /// 어긋날 수 있는 상황에서 호출합니다.
    public func resetInputBuffer() {
        inputBuffer = ""
    }
}

// MARK: - UI Methods

private extension BaseKeyboardViewController {
    func setupUI() {
        setDelegates()
        setActions()
    }
    
    func setDelegates() {
        textInteractionGestureController.delegate = self
        switchGestureController.delegate = self
        suggestionController.delegate = self
        suggestionBarHStackView.suggestionDelegate = self
    }
    
    func setActions() {
        setButtonFeedbackAction()
        setTextInteractableButtonAction()
        setSwitchButtonAction()
        setExclusiveButtonAction()
        setChevronButtonAction()
    }
    
    func setKeyboardHeight() {
        let keyboardViewHeight: CGFloat
        let keyboardHStackViewHeight: CGFloat
        if let orientation = self.view.window?.windowScene?.effectiveGeometry.interfaceOrientation {
            let isSuggestionBarVisible = UserDefaultsManager.shared.isPredictiveTextEnabled
            && textDocumentProxy.autocorrectionType != .no
            && currentKeyboard != .tenKey
            
            let suggestionBarHeight = isSuggestionBarVisible
            ? KeyboardLayoutFigure.suggestionBarHeight + KeyboardLayoutFigure.keyboardFrameSpacing * 2
            : 0
            
            keyboardViewHeight = (orientation == .portrait)
            ? UserDefaultsManager.shared.keyboardHeight + suggestionBarHeight
            : KeyboardLayoutFigure.landscapeKeyboardHeight
            
            keyboardHStackViewHeight = (orientation == .portrait)
            ? UserDefaultsManager.shared.keyboardHeight
            : KeyboardLayoutFigure.landscapeKeyboardHeight - suggestionBarHeight
        } else {
            assertionFailure("View가 window 계층에 없습니다.")
            return
        }
        
        if let keyboardViewHeightConstraint {
            keyboardViewHeightConstraint.constant = keyboardViewHeight
        } else {
            let heightConstraint = keyboardView.heightAnchor.constraint(equalToConstant: keyboardViewHeight)
            heightConstraint.priority = .init(999)
            heightConstraint.isActive = true
            keyboardViewHeightConstraint = heightConstraint
        }
        
        if let keyboardHStackViewHeightConstraint {
            keyboardHStackViewHeightConstraint.constant = keyboardHStackViewHeight
        } else {
            let heightConstraint = keyboardHStackView.heightAnchor.constraint(equalToConstant: keyboardHStackViewHeight)
            heightConstraint.isActive = true
            keyboardHStackViewHeightConstraint = heightConstraint
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
            guard let self, let currentButton = action.sender as? TextInteractable else { return }
            
            if currentButton.isProgrammaticCall {
                performTextInteraction(for: currentButton)
            } else {
                if let currentPressedButton = buttonStateController.currentPressedButton,
                   currentPressedButton == currentButton {
                    performTextInteraction(for: currentButton)
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
        case .keyButton(primary: ["'"], secondary: nil):
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if textDocumentProxy.keyboardType != .numbersAndPunctuation && UserDefaultsManager.shared.isAutoChangeToPrimaryEnabled {
                    currentKeyboard = primaryKeyboardView.keyboard
                }
            }
            button.addAction(switchToPrimaryKeyboard, for: .touchUpInside)
            
        case .spaceButton, .returnButton:
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
                if BaseKeyboardViewController.isPreview || preventNextPeriodShortcut { return }
                
                guard let beforeText = textDocumentProxy.documentContextBeforeInput else { return }
                
                if beforeText.hasSuffix(" ") {
                    let textWithoutLastSpace = beforeText.dropLast()
                    
                    if let lastChar = textWithoutLastSpace.last,
                       (lastChar.isLetter || lastChar.isNumber) {
                        
                        // " " → "." 교체: 래핑 메서드 사용
                        replaceText(deleteCount: 1, insert: ".")
                        
                        performedPeriodShortcut = true
                    }
                }
            }
            button.addAction(periodShortcutAction, for: .touchDownRepeat)
        }
    }
    
    func addGesturesToTextInterableButton(_ button: TextInteractable) {
        guard !(button is ReturnButton)
                && !(button is SecondaryKeyButton)
                && !(button.type.primaryKeyList == [".com"]) else { return }
        
        if UserDefaultsManager.shared.isDragToMoveCursorEnabled ||
            button is DeleteButton {
            let panGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handlePanGesture(_:))
            )
            panGesture.delegate = textInteractionGestureController
            panGesture.delaysTouchesBegan = false
            panGesture.cancelsTouchesInView = true
            button.addGestureRecognizer(panGesture)
        }
        
        if UserDefaultsManager.shared.selectedLongPressAction != .disabled
            || button is DeleteButton {
            let longPressGesture = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPressGesture(_:))
            )
            longPressGesture.delegate = textInteractionGestureController
            longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
            longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
            longPressGesture.delaysTouchesBegan = false
            button.addGestureRecognizer(longPressGesture)
        }
    }
    
    func setSwitchButtonAction() {
        let switchToSymbolKeyboard = UIAction { [weak self] action in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton == primaryKeyboardView.switchButton else { return }
            currentKeyboard = .symbol
        }
        primaryKeyboardView.switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        
        let switchToPrimaryKeyboardForSymbol = UIAction { [weak self] _ in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton == symbolKeyboardView.switchButton else { return }
            currentKeyboard = primaryKeyboardView.keyboard
        }
        symbolKeyboardView.switchButton.addAction(switchToPrimaryKeyboardForSymbol, for: .touchUpInside)
        
        let switchToPrimaryKeyboardForNumeric = UIAction { [weak self] _ in
            guard let self else { return }
            guard let currentPressedButton = buttonStateController.currentPressedButton,
                  currentPressedButton == numericKeyboardView.switchButton else { return }
            currentKeyboard = primaryKeyboardView.keyboard
        }
        numericKeyboardView.switchButton.addAction(switchToPrimaryKeyboardForNumeric, for: .touchUpInside)
        
        [primaryKeyboardView.switchButton,
         symbolKeyboardView.switchButton,
         numericKeyboardView.switchButton].forEach { addGesturesToSwitchButton($0) }
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        if UserDefaultsManager.shared.isNumericKeypadEnabled {
            let keyboardSelectPanGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleKeyboardSelectPan(_:))
            )
            keyboardSelectPanGesture.name = SwitchGestureController.PanGestureName.keyboardSelect.rawValue
            keyboardSelectPanGesture.delegate = switchGestureController
            button.addGestureRecognizer(keyboardSelectPanGesture)
        }
        
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled {
            let oneHandedModeSelectPanGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleOneHandedModePan(_:))
            )
            oneHandedModeSelectPanGesture.delegate = switchGestureController
            button.addGestureRecognizer(oneHandedModeSelectPanGesture)
            
            let oneHandedModeSelectLongPressGesture = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleOneHandedModeLongPress(_:))
            )
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

// MARK: - @objc Methods

@objc private extension BaseKeyboardViewController {
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        textInteractionGestureController.panGestureHandler(gesture)
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        textInteractionGestureController.longPressGestureHandler(gesture)
    }
    
    @objc func handleKeyboardSelectPan(_ gesture: UIPanGestureRecognizer) {
        switchGestureController.keyboardSelectPanGestureHandler(gesture)
    }
    
    @objc func handleOneHandedModePan(_ gesture: UIPanGestureRecognizer) {
        switchGestureController.oneHandedModeSelectPanGestureHandler(gesture)
    }
    
    @objc func handleOneHandedModeLongPress(_ gesture: UILongPressGestureRecognizer) {
        switchGestureController.oneHandedModeLongPressGestureHandler(gesture)
    }
}

// MARK: - Update Methods

private extension BaseKeyboardViewController {
    func updateOneHandModekeyboard() {
        leftChevronButton.isHidden = !(currentOneHandedMode == .right)
        rightChevronButton.isHidden = !(currentOneHandedMode == .left)
    }
    
    func updateShowingKeyboard() {
        primaryKeyboardView.isHidden = (currentKeyboard != primaryKeyboardView.keyboard)
        symbolKeyboardView.isHidden = (currentKeyboard != .symbol)
        symbolKeyboardView.initShiftButton()
        isSymbolInput = false
        numericKeyboardView.isHidden = (currentKeyboard != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboard != .tenKey)
    }
    
    func updateReturnButtonType() {
        let type = ReturnButton.ReturnKeyType(type: textDocumentProxy.returnKeyType)
        currentReturnButton?.update(for: type)
    }
    
    func updateSuggestionBarHidden() {
        let prevSuggestionHiddenState = suggestionBarHStackView.isHidden
        
        let shouldHideSuggestions = !UserDefaultsManager.shared.isPredictiveTextEnabled
        || textDocumentProxy.autocorrectionType == .no
        || currentKeyboard == .tenKey
        
        suggestionBarHStackView.isHidden = shouldHideSuggestions
        suggestionController.isEnabled = !shouldHideSuggestions
        
        if prevSuggestionHiddenState != shouldHideSuggestions {
            DispatchQueue.main.async {
                self.setKeyboardHeight()
            }
        }
    }
}

// MARK: - Text Interaction Methods

extension BaseKeyboardViewController {
    final public func performTextInteraction(for button: TextInteractable, insertSecondaryKeyIfAvailable: Bool = false) {
        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform(button: button) }
        
        switch button.type {
        case .keyButton:
            if insertSecondaryKeyIfAvailable && button.type.secondaryKey != nil {
                insertSecondaryKeyText(from: button)
            } else {
                insertPrimaryKeyText(from: button)
            }
        case .deleteButton:
            if UserDefaultsManager.shared.isTextReplacementEnabled,
               let restore = suggestionController.attemptRestoreReplacement(
                inputBuffer: inputBuffer
               ) {
                // 대치 복구: 래핑 메서드 사용
                replaceText(deleteCount: restore.deleteCount, insert: restore.insertText)
            } else {
                if let selectedText = textDocumentProxy.selectedText {
                    tempDeletedCharacters.append(contentsOf: selectedText.reversed())
                } else if let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput?.last {
                    tempDeletedCharacters.append(lastBeforeCursor)
                }
                deleteBackward()
            }
        case .spaceButton:
            if UserDefaultsManager.shared.isTextReplacementEnabled,
               let replacement = suggestionController.attemptTextReplacement(
                inputBuffer: inputBuffer
               ) {
                // 텍스트 대치: 래핑 메서드 사용
                replaceText(deleteCount: replacement.deleteCount, insert: replacement.insertText)
            }
            insertSpaceText()
        case .returnButton:
            insertReturnText()
        }
    }
    
    final public func performRepeatTextInteraction(for button: TextInteractable) {
        guard self.view.window != nil else { return }
        
        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform(button: button) }
        
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
        
        // 커서 이동 시 입력 버퍼 초기화
        resetInputBuffer()
        
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
                deleteText()
                FeedbackManager.shared.playHaptic()
                FeedbackManager.shared.playDeleteSound()
                logger.debug("커서 앞 글자 삭제")
            }
        case .right:
            if let lastDeleted = tempDeletedCharacters.popLast() {
                insertText(String(lastDeleted))
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
        if UserDefaultsManager.shared.selectedLongPressAction == .repeatInput
            || button is DeleteButton {
            repeatTextInteractionWillPerform(button: button)
            
            let repeatTimerInterval = 0.10 - UserDefaultsManager.shared.repeatRate
            timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self, weak button] _ in
                    if self?.view.window == nil {
                        self?.cancelTimer()
                        return
                    }
                    guard let button else {
                        self?.cancelTimer()
                        return
                    }
                    
                    self?.performRepeatTextInteraction(for: button)
                }
            logger.debug("반복 타이머 생성")
        } else if UserDefaultsManager.shared.selectedLongPressAction == .numberInput {
            performTextInteraction(for: button, insertSecondaryKeyIfAvailable: true)
            button.isGesturing = false
        }
    }
    
    final func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable) {
        if UserDefaultsManager.shared.selectedLongPressAction == .repeatInput
            || button is DeleteButton {
            repeatTextInteractionDidPerform(button: button)
        }
    }
}

// MARK: - SuggestionControllerDelegate

extension BaseKeyboardViewController: SuggestionControllerDelegate {
    final func suggestionController(_ controller: SuggestionController, didUpdateCurrentWord currentWord: String?, suggestions: [String]) {
        keyboardView.suggestionBarHStackView.updateSuggestions(currentWord: currentWord, suggestions: suggestions)
    }
}

// MARK: - SuggestionBarDelegate

extension BaseKeyboardViewController: SuggestionBarDelegate {
    final func suggestionBar(_ bar: SuggestionBarHStackView, didSelectSuggestionAt index: Int) {
        if suggestionController.currentMode == .nGram {
            guard let word = suggestionController.nGramSuggestionText(at: index) else { return }
            
            let needsLeadingSpace = !inputBuffer.isEmpty && inputBuffer.last?.isWhitespace != true
            if needsLeadingSpace {
                insertText(" ")
            }
            
            insertText(word)
            suggestionController.recordWord(word)
            
            suggestionDidApply()
            
            suggestionController.updateSuggestionsAfterNGramSelection(inputBuffer: inputBuffer)
            return
        }
        
        if index == 0 {
            let currentWord = inputBuffer.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
            if !currentWord.isEmpty {
                suggestionController.learnWord(currentWord)
                suggestionController.recordWord(currentWord)
            }
            suggestionController.clearSuggestions()
            return
        }
        
        let suggestionIndex = index - 1
        
        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            inputBuffer: inputBuffer
        ) else { return }
        
        replaceText(deleteCount: result.deleteCount, insert: result.insertText)
        
        suggestionController.recordWord(result.insertText)
        
        suggestionDidApply()
        suggestionController.updateSuggestions(inputBuffer: inputBuffer)
    }
}
