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
    private let performanceSignposter = OSSignposter(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "KeyboardLifecycle"
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
                return keyboardSettingsManager.lastOneHandedMode
            }
        }
        set {
            if BaseKeyboardViewController.isPreview {
                previewOneHandedMode = newValue
                onPreviewOneHandedModeChanged?(newValue)
            } else {
                keyboardSettingsManager.lastOneHandedMode = newValue
            }
            updateOneHandModekeyboard()
        }
    }
    /// 키보드 리턴 버튼 배열
    private var returnButtonList: [ReturnButton] {
        return [primaryKeyboardView.returnButton,
                symbolKeyboardView.returnButton,
                numericKeyboardView.returnButton]
    }
    /// 전체 키보드 버튼 배열
    private var allKeyboardButtonList: [BaseKeyboardButton] {
        return primaryKeyboardView.allButtonList
        + symbolKeyboardView.allButtonList
        + numericKeyboardView.allButtonList
        + tenkeyKeyboardView.allButtonList
    }
    /// 기본/숫자 키보드 입력 버튼 배열
    private var primaryAndNumericTextInteractableButtonList: [TextInteractable] {
        return primaryKeyboardView.totalTextInterableButtonList
        + numericKeyboardView.totalTextInterableButtonList
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
    public lazy var buttonStateController = ButtonStateController(suggestionBarView: suggestionBarView)

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
    /// 키보드 세션 동안만 유지되는 undo/redo 상태 관리자
    private var undoRedoSession = KeyboardUndoRedoSession()
    /// 첫 표시 이후 자동완성 준비를 한 번만 시작했는지 여부
    private var didStartDeferredSuggestionPreparation = false
    /// 첫 후보 갱신 계측 이벤트 중복 방지 플래그
    private var didEmitFirstSuggestionUpdateSignpost = false
    /// 첫 입력 처리 계측 이벤트 중복 방지 플래그
    private var didEmitFirstTextInteractionSignpost = false
    /// 자동완성과 undo/redo 설정이 모두 켜진 경우에만 기능을 활성화합니다.
    private var isUndoRedoFeatureAvailable: Bool {
        return KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable(
            isPredictiveTextEnabled: keyboardSettingsManager.isPredictiveTextEnabled,
            isUndoRedoEnabled: keyboardSettingsManager.isUndoRedoEnabled
        )
    }

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
    private lazy var suggestionBarView = keyboardView.suggestionBarView
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
        let state = performanceSignposter.beginInterval("KeyboardLoadView")
        defer { performanceSignposter.endInterval("KeyboardLoadView", state) }

        self.view = keyboardView
    }

    open override func viewDidLoad() {
        let state = performanceSignposter.beginInterval("KeyboardViewDidLoad")
        defer { performanceSignposter.endInterval("KeyboardViewDidLoad", state) }

        super.viewDidLoad()
        resetInputBuffer()
        setupUI()
        setNextKeyboardButton()
        if BaseKeyboardViewController.isPreview { updateReturnButtonType() }

        if keyboardSettingsManager.isOneHandedKeyboardEnabled { updateOneHandModekeyboard() }

        // 사용자 설정을 SuggestionController에 전달 — 엔진 생성은 첫 표시 이후로 지연
        suggestionController.isTextReplacementEnabled = keyboardSettingsManager.isTextReplacementEnabled
        suggestionController.isPredictiveTextEnabled = keyboardSettingsManager.isPredictiveTextEnabled

        updateSuggestionBarHidden()
    }

    open override func viewWillAppear(_ animated: Bool) {
        let state = performanceSignposter.beginInterval("KeyboardViewWillAppear")
        defer { performanceSignposter.endInterval("KeyboardViewWillAppear", state) }

        super.viewWillAppear(animated)
        if !BaseKeyboardViewController.isPreview { setKeyboardHeight() }
        FeedbackManager.shared.prepareHaptic()
    }

    open override func viewDidAppear(_ animated: Bool) {
        let state = performanceSignposter.beginInterval("KeyboardViewDidAppear")
        defer { performanceSignposter.endInterval("KeyboardViewDidAppear", state) }

        super.viewDidAppear(animated)
        let systemGestureRecognizer0 = self.view.window?.gestureRecognizers?[0] as? UIGestureRecognizer
        let systemGestureRecognizer1 = self.view.window?.gestureRecognizers?[1] as? UIGestureRecognizer
        systemGestureRecognizer0?.delaysTouchesBegan = false
        systemGestureRecognizer1?.delaysTouchesBegan = false
        startDeferredSuggestionPreparationIfNeeded()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in self?.setKeyboardHeight() }
    }

    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        logger.debug("textWillChange")
        undoRedoSession.prepareForTextWillChange(
            inputIdentifier: textInputIdentifier(for: textInput),
            context: currentTextContextSnapshot()
        )
        resetInputBuffer()
        updateKeyboardType()
        updateReturnButtonType()
        updateReturnButtonEnabled()
        updateSuggestionBarHidden()
    }

    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        logger.debug("textDidChange")
        invalidateUndoRedoHistoryIfNeededAfterTextChange(textInput)
        updateKeyboardType()
        oldKeyboardType = textDocumentProxy.keyboardType
        updateReturnButtonType()
        updateReturnButtonEnabled()
        updateSuggestionBarHidden()
        updateSuggestions()
    }
    
    open override func selectionWillChange(_ textInput: (any UITextInput)?) {
        super.selectionWillChange(textInput)
        logger.debug("selectionWillChange")
    }
    
    open override func selectionDidChange(_ textInput: (any UITextInput)?) {
        super.selectionDidChange(textInput)
        logger.debug("selectionDidChange")
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelTimer()
        undoRedoSession.removeAll()
        updateUndoRedoControls()
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
        if !isRepeatingInput {
            updateReturnButtonEnabled()
            updateSuggestions()
        }
    }

    /// SuggestionBar에서 후보를 선택하여 텍스트가 교체된 후 호출되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func suggestionDidApply() {}

    /// undo/redo로 텍스트가 직접 변경된 후 내부 입력 상태를 동기화하기 위한 hook입니다.
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func undoRedoEditDidApply() {
        resetInputBuffer()
        suggestionController.clearReplacementHistory()
    }

    /// 조합 중인 텍스트가 있을 때 undo 단위 확정을 미루기 위한 hook입니다.
    open var shouldDeferUndoRedoCommit: Bool {
        return false
    }

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

        updateReturnButtonEnabled()
        updateSuggestions()
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

        suggestionController.recordUncommittedWords(from: inputBuffer)

        insertText(" ")
        commitUndoRedoGroupIfPossible()
    }

    /// 개행 문자를 입력하는 메서드
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    open func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }

        suggestionController.endSentence(inputBuffer: inputBuffer)

        textDocumentProxy.insertText("\n")
        recordUndoRedoChange(deletedText: "", insertedText: "\n")
        commitUndoRedoGroupIfPossible()
        resetInputBuffer()
        suggestionController.clearReplacementHistory()
    }

    /// 리턴 버튼 단일 입력을 수행하는 메서드
    ///
    /// 리턴 버튼에 추가 동작이 필요한 경우 이 메서드에서 분기합니다.
    open func performReturnButtonTextInteraction() {
        insertReturnText()
    }

    /// 리턴 버튼 반복 입력을 수행하는 메서드
    ///
    /// 리턴 버튼에 추가 동작이 필요한 경우 이 메서드에서 분기합니다.
    open func performRepeatReturnButtonTextInteraction(for button: TextInteractable) {
        insertReturnText()
        button.playFeedback()
    }

    /// 삭제가 일어나기 전 실행되는 메서드
    open func deleteBackwardWillPerform() {
        commitUndoRedoGroupIfPossible()
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

    /// 삭제 버튼 팬 제스처로 커서 앞 글자를 삭제하고 복구 버퍼 반영 여부를 반환합니다.
    ///
    /// 입력기별 내부 조합 버퍼가 있는 경우 override하여 버퍼를 함께 동기화합니다.
    open func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)? {
        guard let lastBeforeCursor = textDocumentProxy.documentContextBeforeInput?.last else { return nil }

        deleteText()
        return (lastBeforeCursor, true)
    }

    /// 삭제 버튼 팬 제스처로 임시 삭제된 문자를 복구합니다.
    ///
    /// 입력기별 내부 조합 버퍼가 있는 경우 override하여 복구된 문자를 조합 상태에 반영합니다.
    open func deleteButtonPanRestoreText(_ character: Character) {
        insertText(String(character))
    }

    /// 삭제 버튼 팬 제스처가 끝난 뒤 입력기별 임시 복구 상태를 정리합니다.
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func deleteButtonPanDidStop() {}

    // MARK: - Public Methods

    public func updateOneHandedWidthForPreview(to oneHandedWidth: Double) {
        keyboardView.updateOneHandedWidth(oneHandedWidth)
        self.view.layoutIfNeeded()
    }

    public func updateOneHandedModeForPreview(to oneHandedMode: OneHandedMode) {
        previewOneHandedMode = oneHandedMode
        updateOneHandModekeyboard()
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
        recordUndoRedoChange(deletedText: "", insertedText: text)
    }

    /// `textDocumentProxy`에서 1글자를 삭제하고 `inputBuffer`를 동기화합니다.
    ///
    /// `textDocumentProxy.deleteBackward()`를 직접 호출하는 대신 이 메서드를 사용하여
    /// 입력 버퍼가 항상 실제 입력과 일치하도록 보장합니다.
    public func deleteText() {
        let wasSpaceAtEnd = inputBuffer.last?.isWhitespace == true
        let deletedText = textDeletedBySingleBackward()

        textDocumentProxy.deleteBackward()
        if !inputBuffer.isEmpty {
            inputBuffer.removeLast()
        }
        recordUndoRedoChange(deletedText: deletedText, insertedText: "")

        if inputBuffer.isEmpty {
            // 모든 입력을 지운 경우 → 문장 버퍼 전체 초기화
            suggestionController.resetSentenceBuffer()
        } else if wasSpaceAtEnd && inputBuffer.last?.isWhitespace != true {
            // 스페이스를 지워서 커밋된 단어 경계를 허문 경우 → n-gram 버퍼에서 pop
            suggestionController.removeLastRecordedWord()
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
        let deletedText = textBeforeCursorSuffix(count: deleteCount)
        replaceTextInDocument(deleteCount: deleteCount, insert: text)
        replaceInputBufferSuffix(deleteCount: deleteCount, insert: text)
        recordUndoRedoChange(deletedText: deletedText, insertedText: text)
    }

    /// 입력 버퍼를 초기화합니다.
    ///
    /// 커서 이동, 키보드 열림/닫힘 등 버퍼와 실제 텍스트 위치가
    /// 어긋날 수 있는 상황에서 호출합니다.
    public func resetInputBuffer() {
        inputBuffer = ""
        suggestionController.resetSentenceBuffer()
    }

    /// 조합 확정 지연 요청이 있었고 현재 확정 가능한 상태라면 pending undo 단위를 stack에 반영합니다.
    public final func commitDeferredUndoRedoGroupIfNeeded() {
        guard undoRedoSession.commitDeferredGroupIfNeeded(
            shouldDeferCommit: shouldDeferUndoRedoCommit
        ) else { return }
        updateUndoRedoControls()
    }

    /// 스페이스/리턴처럼 사용자가 명시적인 편집 경계를 만든 경우 pending undo 단위를 확정합니다.
    public final func commitUndoRedoGroupIfPossible() {
        commitPendingUndoRedoGroup()
    }

    /// 삭제 시작처럼 조합 중이어도 이전 편집 단위를 끊어야 하는 경우 pending undo 단위를 확정합니다.
    public final func commitUndoRedoGroupIgnoringCompositionDeferral() {
        guard isUndoRedoFeatureAvailable else { return }

        undoRedoSession.commitPendingGroupIgnoringDeferral()
        updateUndoRedoControls()
    }

}

// MARK: - Text Proxy Wrapper Helper Methods

private extension BaseKeyboardViewController {
    func replaceTextInDocument(deleteCount: Int, insert text: String) {
        for _ in 0..<deleteCount {
            textDocumentProxy.deleteBackward()
        }
        if !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
    }

    func replaceInputBufferSuffix(deleteCount: Int, insert text: String) {
        if inputBuffer.count >= deleteCount {
            inputBuffer.removeLast(deleteCount)
        } else {
            inputBuffer = ""
        }
        inputBuffer.append(text)
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
        suggestionBarView.suggestionDelegate = self
    }

    func setActions() {
        setButtonFeedbackAction()
        setTextInteractableButtonAction()
        setSwitchButtonAction()
        setExclusiveButtonAction()
        setChevronButtonAction()
    }

    func setKeyboardHeight() {
        guard let window = self.view.window,
              let orientation = window.windowScene?.effectiveGeometry.interfaceOrientation else { return }

        let isSuggestionBarVisible = !KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
            isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
            autocorrectionType: textDocumentProxy.autocorrectionType ?? .default,
            currentKeyboard: currentKeyboard
        )

        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: keyboardSettingsManager.keyboardHeight,
            landscapeKeyboardHeight: KeyboardLayoutFigure.landscapeKeyboardHeight,
            suggestionBarHeight: KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing,
            isSuggestionBarVisible: isSuggestionBarVisible,
            isPortrait: orientation == .portrait
        )

        if let keyboardViewHeightConstraint {
            keyboardViewHeightConstraint.constant = height.keyboardViewHeight
        } else {
            let heightConstraint = keyboardView.heightAnchor.constraint(equalToConstant: height.keyboardViewHeight)
            heightConstraint.priority = .init(999)
            heightConstraint.isActive = true
            keyboardViewHeightConstraint = heightConstraint
        }

        if let keyboardHStackViewHeightConstraint {
            keyboardHStackViewHeightConstraint.constant = height.keyboardHStackViewHeight
        } else {
            let heightConstraint = keyboardHStackView.heightAnchor.constraint(equalToConstant: height.keyboardHStackViewHeight)
            heightConstraint.isActive = true
            keyboardHStackViewHeightConstraint = heightConstraint
        }
    }

    func setNextKeyboardButton() {
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView].forEach {
            $0.updateNextKeyboardButton(needsInputModeSwitchKey: self.needsInputModeSwitchKey,
                                        nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        }

        keyboardSettingsManager.needsInputModeSwitchKey = self.needsInputModeSwitchKey

    }
}

// MARK: - Button Action Methods

private extension BaseKeyboardViewController {
    func setButtonFeedbackAction() {
        buttonStateController.setFeedbackActionToButtons(allKeyboardButtonList)
    }

    func setTextInteractableButtonAction() {
        setPrimaryAndNumericTextInteractableButtonAction()
        setSymbolTextInteractableButtonAction()
        setTenkeyTextInteractableButtonAction()
    }

    func setPrimaryAndNumericTextInteractableButtonAction() {
        primaryAndNumericTextInteractableButtonList.forEach {
            addInputActionToTextInterableButton($0)
            addGesturesToTextInterableButton($0)
        }
    }

    func setSymbolTextInteractableButtonAction() {
        symbolKeyboardView.totalTextInterableButtonList.forEach {
            addInputActionToSymbolTextInterableButton($0)
            addGesturesToTextInterableButton($0)
        }
    }

    func setTenkeyTextInteractableButtonAction() {
        tenkeyKeyboardView.totalTextInterableButtonList.forEach { addInputActionToTextInterableButton($0) }
    }

    func addInputActionToTextInterableButton(_ button: TextInteractable) {
        let inputAction = makeTextInputAction()
        if button is DeleteButton {
            button.addAction(inputAction, for: .touchDown)
        } else if let spaceButton = button as? SpaceButton {
            button.addAction(inputAction, for: .touchUpInside)
            addPeriodShortcutActionToSpaceButton(spaceButton)
        } else {
            button.addAction(inputAction, for: .touchUpInside)
        }
    }

    func makeTextInputAction() -> UIAction {
        return UIAction { [weak self] action in
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
    }

    func addInputActionToSymbolTextInterableButton(_ button: TextInteractable) {
        addInputActionToTextInterableButton(button)

        switch button.type {
        case .keyButton(primary: ["'"], secondary: nil):
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                    buttonType: button.type,
                    keyboardType: textDocumentProxy.keyboardType ?? .default,
                    isAutoChangeToPrimaryEnabled: keyboardSettingsManager.isAutoChangeToPrimaryEnabled
                ) {
                    currentKeyboard = primaryKeyboardView.keyboard
                }
            }
            button.addAction(switchToPrimaryKeyboard, for: .touchUpInside)

        case .spaceButton, .returnButton:
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterSpaceOrReturn(
                    buttonType: button.type,
                    keyboardType: textDocumentProxy.keyboardType ?? .default,
                    isAutoChangeToPrimaryEnabled: keyboardSettingsManager.isAutoChangeToPrimaryEnabled,
                    isSymbolInput: isSymbolInput
                ) {
                    currentKeyboard = primaryKeyboardView.keyboard
                }
            }
            button.addAction(switchToPrimaryKeyboard, for: .touchUpInside)

        case .deleteButton:
            break

        default:
            if KeyboardSymbolInputPolicy.shouldMarkSymbolInput(buttonType: button.type) {
                let additionalInputAction = UIAction { [weak self] _ in self?.isSymbolInput = true }
                button.addAction(additionalInputAction, for: .touchUpInside)
            }
        }
    }

    func addPeriodShortcutActionToSpaceButton(_ button: SpaceButton) {
        if keyboardSettingsManager.isPeriodShortcutEnabled {
            let periodShortcutAction = UIAction { [weak self] _ in
                guard let self else { return }
                guard KeyboardPeriodShortcutPolicy.shouldReplaceTrailingSpaceWithPeriod(
                    isPreview: BaseKeyboardViewController.isPreview,
                    preventsNextPeriodShortcut: preventNextPeriodShortcut,
                    documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
                ) else { return }

                // " " -> "." 교체: 래핑 메서드 사용
                replaceText(deleteCount: 1, insert: ".")

                performedPeriodShortcut = true
            }
            button.addAction(periodShortcutAction, for: .touchDownRepeat)
        }
    }

    func addGesturesToTextInterableButton(_ button: TextInteractable) {
        guard KeyboardGesturePolicy.shouldAddTextInteractionGestures(
            isReturnButton: button is ReturnButton,
            isSecondaryKeyButton: button is SecondaryKeyButton,
            primaryKeyList: button.type.primaryKeyList
        ) else { return }

        let isDeleteButton = button is DeleteButton

        if KeyboardGesturePolicy.shouldAddTextInteractionPanGesture(
            isDragToMoveCursorEnabled: keyboardSettingsManager.isDragToMoveCursorEnabled,
            isDeleteButton: isDeleteButton
        ) {
            let panGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handlePanGesture(_:))
            )
            panGesture.delegate = textInteractionGestureController
            panGesture.delaysTouchesBegan = false
            panGesture.cancelsTouchesInView = true
            button.addGestureRecognizer(panGesture)
        }

        if KeyboardGesturePolicy.shouldAddTextInteractionLongPressGesture(
            selectedLongPressAction: keyboardSettingsManager.selectedLongPressAction,
            isDeleteButton: isDeleteButton
        ) {
            let longPressGesture = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPressGesture(_:))
            )
            longPressGesture.delegate = textInteractionGestureController
            longPressGesture.minimumPressDuration = keyboardSettingsManager.longPressDuration
            longPressGesture.allowableMovement = keyboardSettingsManager.cursorActiveDistance
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
        if keyboardSettingsManager.isNumericKeypadEnabled {
            let keyboardSelectPanGesture = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleKeyboardSelectPan(_:))
            )
            keyboardSelectPanGesture.name = SwitchGestureController.PanGestureName.keyboardSelect.rawValue
            keyboardSelectPanGesture.delegate = switchGestureController
            button.addGestureRecognizer(keyboardSelectPanGesture)
        }

        if keyboardSettingsManager.isOneHandedKeyboardEnabled {
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
            oneHandedModeSelectLongPressGesture.minimumPressDuration = keyboardSettingsManager.longPressDuration
            oneHandedModeSelectLongPressGesture.allowableMovement = keyboardSettingsManager.cursorActiveDistance
            button.addGestureRecognizer(oneHandedModeSelectLongPressGesture)
        }
    }

    func setExclusiveButtonAction() {
        buttonStateController.setExclusiveActionToButtons(allKeyboardButtonList)
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
        keyboardView.updateOneHandedMode(currentOneHandedMode)
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
        returnButtonList.forEach { $0.update(for: type) }
    }

    func updateReturnButtonEnabled() {
        let isEnabled = KeyboardPresentationStatePolicy.isReturnButtonEnabled(
            enablesReturnKeyAutomatically: textDocumentProxy.enablesReturnKeyAutomatically == true,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
            documentContextAfterInput: textDocumentProxy.documentContextAfterInput
        )
        returnButtonList.forEach { $0.updateEnabled(isEnabled) }
    }

    func updateSuggestionBarHidden() {
        let prevSuggestionHiddenState = suggestionBarView.isHidden

        let shouldHideSuggestions = KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
            isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
            autocorrectionType: textDocumentProxy.autocorrectionType ?? .default,
            currentKeyboard: currentKeyboard
        )

        suggestionBarView.isHidden = shouldHideSuggestions
        suggestionController.isSuspended = shouldHideSuggestions
        updateUndoRedoControls()

        if prevSuggestionHiddenState != shouldHideSuggestions {
            DispatchQueue.main.async { [weak self] in
                self?.setKeyboardHeight()
            }
        }
    }

    func startDeferredSuggestionPreparationIfNeeded() {
        guard !BaseKeyboardViewController.isPreview else { return }
        guard !didStartDeferredSuggestionPreparation else { return }
        let shouldLoadLexicon = KeyboardSuggestionSelectionPolicy.shouldLoadLexicon(
            isTextReplacementEnabled: keyboardSettingsManager.isTextReplacementEnabled,
            isPredictiveTextEnabled: keyboardSettingsManager.isPredictiveTextEnabled
        )
        let shouldPreparePredictiveEngines = keyboardSettingsManager.isPredictiveTextEnabled
            && !suggestionController.isSuspended
        guard shouldLoadLexicon || shouldPreparePredictiveEngines else { return }

        didStartDeferredSuggestionPreparation = true
        let state = performanceSignposter.beginInterval("DeferredSuggestionPreparation")
        if shouldPreparePredictiveEngines {
            suggestionController.preparePredictiveEnginesIfNeeded()
        }

        if shouldLoadLexicon {
            suggestionController.loadLexicon(from: self)
        }
        performanceSignposter.endInterval("DeferredSuggestionPreparation", state)

        if KeyboardSuggestionSelectionPolicy.shouldUpdateInitialSuggestionsAfterDeferredPreparation(
            shouldPreparePredictiveEngines: shouldPreparePredictiveEngines
        ) {
            updateSuggestions()
        }
    }
}

// MARK: - Text Interaction Methods

extension BaseKeyboardViewController {
    final public func performTextInteraction(for button: TextInteractable, insertSecondaryKeyIfAvailable: Bool = false) {
        if !didEmitFirstTextInteractionSignpost {
            didEmitFirstTextInteractionSignpost = true
            performanceSignposter.emitEvent("FirstTextInteraction")
        }

        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform(button: button) }

        switch button.type {
        case .keyButton:
            if KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(
                insertSecondaryKeyIfAvailable: insertSecondaryKeyIfAvailable,
                secondaryKey: button.type.secondaryKey
            ) {
                insertSecondaryKeyText(from: button)
            } else {
                insertPrimaryKeyText(from: button)
            }
        case .deleteButton:
            if let restore = suggestionController.attemptRestoreReplacement(
                inputBuffer: inputBuffer,
                documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
                selectedText: textDocumentProxy.selectedText
            ) {
                // 대치 복구: 래핑 메서드 사용
                replaceText(deleteCount: restore.deleteCount, insert: restore.insertText)
            } else {
                let deletedCharacters = KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
                    selectedText: textDocumentProxy.selectedText,
                    documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
                )
                tempDeletedCharacters.append(contentsOf: deletedCharacters)
                deleteBackward()
            }
        case .spaceButton:
            if let replacement = suggestionController.attemptTextReplacement(
                baseText: inputBuffer
            ) {
                // 텍스트 대치: 래핑 메서드 사용
                replaceText(deleteCount: replacement.deleteCount, insert: replacement.insertText)
            }
            insertSpaceText()
        case .returnButton:
            performReturnButtonTextInteraction()
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
            if KeyboardTextInteractionPolicy.shouldRepeatDelete(
                documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
                selectedText: textDocumentProxy.selectedText
            ) {
                repeatDeleteBackward()
                button.playFeedback()
            } else {
                button.isGesturing = false
            }
        case .spaceButton:
            insertSpaceText()
            button.playFeedback()
        case .returnButton:
            performRepeatReturnButtonTextInteraction(for: button)
        }
    }
}

// MARK: - Private Methods

private extension BaseKeyboardViewController {
    func performUndo() {
        guard isUndoRedoFeatureAvailable else { return }

        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyUndo(from: currentTextContextSnapshot()) else {
            updateUndoRedoControls()
            return
        }
        guard let edit = undoRedoSession.undo() else {
            updateUndoRedoControls()
            return
        }
        guard applyUndoRedoEdit(edit) else {
            invalidateUndoRedoHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastRedoTargetContext(currentTextContextSnapshot())
        updateUndoRedoControls()
        FeedbackManager.shared.playHaptic()
    }

    func performRedo() {
        guard isUndoRedoFeatureAvailable else { return }

        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyRedo(from: currentTextContextSnapshot()) else {
            updateUndoRedoControls()
            return
        }
        guard let edit = undoRedoSession.redo() else {
            updateUndoRedoControls()
            return
        }
        guard applyUndoRedoEdit(edit) else {
            invalidateUndoRedoHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastUndoTargetContext(currentTextContextSnapshot())
        updateUndoRedoControls()
        FeedbackManager.shared.playHaptic()
    }

    func applyUndoRedoEdit(_ edit: KeyboardUndoRedoEdit) -> Bool {
        guard !BaseKeyboardViewController.isPreview else { return false }

        return undoRedoSession.performApplyingEdit {
            guard restoreTextPositionIfPossible(to: edit.targetContext) else { return false }

            for _ in 0..<edit.deleteCount {
                textDocumentProxy.deleteBackward()
            }
            if !edit.insertText.isEmpty {
                textDocumentProxy.insertText(edit.insertText)
            }

            undoRedoEditDidApply()
            updateReturnButtonEnabled()
            updateSuggestions()
            return true
        }
    }

    func recordUndoRedoChange(
        deletedText: String,
        insertedText: String
    ) {
        guard isUndoRedoFeatureAvailable,
              !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.record(
            deletedText: deletedText,
            insertedText: insertedText,
            targetContext: currentTextContextSnapshot(),
            shouldDeferCommit: { [weak self] in
                self?.shouldDeferUndoRedoCommit == true
            },
            debouncedCommitDidFinish: { [weak self] in
                self?.updateUndoRedoControls()
            }
        )
        updateUndoRedoControls()
    }

    func commitPendingUndoRedoGroup() {
        undoRedoSession.commitPendingGroup(shouldDeferCommit: shouldDeferUndoRedoCommit)
        updateUndoRedoControls()
    }

    func invalidateUndoRedoHistoryForTextContextChange() {
        guard !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.removeAll()
        updateUndoRedoControls()
    }

    func updateUndoRedoControls() {
        let shouldShowUndoRedo = KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
            isSuggestionBarHidden: suggestionBarView.isHidden,
            isUndoRedoFeatureAvailable: isUndoRedoFeatureAvailable
        )
        let currentContext = currentTextContextSnapshot()
        suggestionBarView.updateUndoRedoControls(
            isVisible: shouldShowUndoRedo,
            canUndo: undoRedoSession.canApplyUndo(from: currentContext),
            canRedo: undoRedoSession.canApplyRedo(from: currentContext)
        )
    }

    func textDeletedBySingleBackward() -> String {
        return KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
            selectedText: textDocumentProxy.selectedText,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
        )
    }

    func textBeforeCursorSuffix(count: Int) -> String {
        guard count > 0,
              let beforeInput = textDocumentProxy.documentContextBeforeInput else { return "" }
        return String(beforeInput.suffix(count))
    }

    func currentTextContextSnapshot() -> KeyboardTextContextSnapshot {
        return KeyboardTextContextSnapshot(
            beforeInput: textDocumentProxy.documentContextBeforeInput,
            afterInput: textDocumentProxy.documentContextAfterInput
        )
    }

    func textInputIdentifier(for textInput: (any UITextInput)?) -> ObjectIdentifier? {
        guard let textInput else { return nil }
        return ObjectIdentifier(textInput as AnyObject)
    }

    func invalidateUndoRedoHistoryIfNeededAfterTextChange(_ textInput: (any UITextInput)?) {
        if undoRedoSession.shouldInvalidateAfterTextChange(
            inputIdentifier: textInputIdentifier(for: textInput),
            currentContext: currentTextContextSnapshot()
        ) {
            invalidateUndoRedoHistoryForTextContextChange()
        }
    }

    func restoreTextPositionIfPossible(to targetContext: KeyboardTextContextSnapshot?) -> Bool {
        guard let targetContext else { return true }

        guard let offset = KeyboardTextContextNavigator.cursorOffset(
            from: currentTextContextSnapshot(),
            to: targetContext
        ) else {
            return false
        }

        if offset != 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
        }
        return true
    }

    func updateSuggestions() {
        if !didEmitFirstSuggestionUpdateSignpost {
            didEmitFirstSuggestionUpdateSignpost = true
            performanceSignposter.emitEvent("FirstUpdateSuggestions")
        }

        let action = KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
            isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
            selectedText: textDocumentProxy.selectedText,
            inputBuffer: inputBuffer
        )

        switch action {
        case .none:
            break
        case .update(let text):
            suggestionController.updateSuggestions(for: text)
        case .clear:
            suggestionController.clearSuggestions()
        }
    }

    func handlePeriodShortcutOnDelete() {
        let state = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: keyboardSettingsManager.isPeriodShortcutEnabled,
            performedPeriodShortcut: performedPeriodShortcut,
            preventsNextPeriodShortcut: preventNextPeriodShortcut,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
        )

        performedPeriodShortcut = state.performedPeriodShortcut
        preventNextPeriodShortcut = state.preventsNextPeriodShortcut
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
    final func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection, steps: Int) {
        logger.debug("Primary Button 팬 제스처 방향: \(String(describing: direction)), steps: \(steps)")

        // 커서 이동 시 입력 버퍼 초기화
        resetInputBuffer()
        moveCursorIfPossible(to: direction, steps: steps)
    }

    final func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {
        logger.debug("DeleteButton 팬 제스처 방향: \(String(describing: direction))")

        switch direction {
        case .left:
            performDeleteButtonPanDeleteIfPossible()
        case .right:
            performDeleteButtonPanRestoreIfPossible()
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }

    final func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        tempDeletedCharacters.removeAll()
        deleteButtonPanDidStop()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }

    final func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {
        let isDeleteButton = button is DeleteButton

        if KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
            selectedLongPressAction: keyboardSettingsManager.selectedLongPressAction,
            isDeleteButton: isDeleteButton
        ) {
            repeatTextInteractionWillPerform(button: button)
            startRepeatInputTimer(for: button)
        } else if KeyboardGesturePolicy.shouldPerformNumberInputOnLongPress(
            selectedLongPressAction: keyboardSettingsManager.selectedLongPressAction,
            isDeleteButton: isDeleteButton
        ) {
            performNumberInputLongPress(for: button)
        }
    }

    final func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable) {
        if KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
            selectedLongPressAction: keyboardSettingsManager.selectedLongPressAction,
            isDeleteButton: button is DeleteButton
        ) {
            repeatTextInteractionDidPerform(button: button)
        }
    }
}

private extension BaseKeyboardViewController {
    func moveCursorIfPossible(to direction: PanDirection, steps: Int) {
        let actualSteps = CursorDragAccelerationPolicy.applicableSteps(
            to: direction,
            requestedSteps: steps,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
            documentContextAfterInput: textDocumentProxy.documentContextAfterInput
        )
        guard actualSteps > 0 else { return }

        switch direction {
        case .left:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -actualSteps)
            logger.debug("커서 왼쪽 이동: \(actualSteps)칸")
        case .right:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: actualSteps)
            logger.debug("커서 오른쪽 이동: \(actualSteps)칸")
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
            return
        }

        updateUndoRedoControls()
        FeedbackManager.shared.playHaptic(isForcing: true)
    }

    func performDeleteButtonPanDeleteIfPossible() {
        guard let deleteResult = deleteButtonPanDeleteText(
            hasPendingRestoreText: !tempDeletedCharacters.isEmpty
        ) else { return }

        if deleteResult.shouldRestore {
            tempDeletedCharacters.append(deleteResult.character)
        }
        updateSuggestions()
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playDeleteSound()
        logger.debug("커서 앞 글자 삭제")
    }

    func performDeleteButtonPanRestoreIfPossible() {
        guard let lastDeleted = tempDeletedCharacters.popLast() else { return }

        deleteButtonPanRestoreText(lastDeleted)
        updateSuggestions()
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playDeleteSound()
        logger.debug("삭제된 글자 복구")
    }

    func startRepeatInputTimer(for button: TextInteractable) {
        let repeatTimerInterval = KeyboardTextInteractionPolicy.repeatTimerInterval(
            repeatRate: keyboardSettingsManager.repeatRate
        )
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
    }

    func performNumberInputLongPress(for button: TextInteractable) {
        performTextInteraction(for: button, insertSecondaryKeyIfAvailable: true)
        button.isGesturing = false
        textInteractionGestureController.releaseButtonGesture(for: button)
    }
}

// MARK: - SuggestionControllerDelegate

extension BaseKeyboardViewController: SuggestionControllerDelegate {
    final func suggestionController(_ controller: SuggestionController, didUpdateCurrentWord currentWord: String?, suggestions: [String]) {
        suggestionBarView.updateSuggestions(currentWord: currentWord, suggestions: suggestions)
    }
}

// MARK: - SuggestionBarDelegate

extension BaseKeyboardViewController: SuggestionBarDelegate {
    final func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        if handleSelectedTextSuggestion(at: index) { return }
        if handleNGramSuggestion(at: index) { return }
        if handleCurrentWordConfirmationIfNeeded(at: index) { return }
        handleInputBufferSuggestion(at: index)
    }

    final func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {
        performUndo()
    }

    final func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {
        performRedo()
    }
}

private extension BaseKeyboardViewController {
    func handleSelectedTextSuggestion(at index: Int) -> Bool {
        guard let selectedText = textDocumentProxy.selectedText,
              !selectedText.isEmpty else { return false }

        if index == 0 {
            // 현재 선택된 단어 확정, 후보 비우기
            suggestionController.clearSuggestions()
            return true
        }

        let suggestionIndex = index - 1
        guard suggestionIndex >= 0,
              let result = suggestionController.selectSuggestion(
                at: suggestionIndex,
                baseText: selectedText
              ) else { return true }

        // selectedText가 있는 상태에서 insertText하면
        // 시스템이 선택 영역을 자동 교체
        recordUndoRedoChange(deletedText: selectedText, insertedText: result.insertText)
        textDocumentProxy.insertText(result.insertText)
        inputBuffer.append(result.insertText)

        suggestionDidApply()
        updateSuggestions()
        return true
    }

    func handleNGramSuggestion(at index: Int) -> Bool {
        guard suggestionController.currentMode == .nGram else { return false }
        guard let word = suggestionController.nGramSuggestionText(at: index) else { return true }

        if KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
            inputBuffer: inputBuffer
        ) {
            insertText(" ")
        }

        insertText(word)

        suggestionDidApply()

        suggestionController.updateSuggestionsAfterNGramSelection(inputBuffer: inputBuffer)
        return true
    }

    func handleCurrentWordConfirmationIfNeeded(at index: Int) -> Bool {
        guard index == 0 else { return false }

        let currentWord = KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
            inputBuffer: inputBuffer
        )
        if !currentWord.isEmpty {
            suggestionController.learnWord(currentWord)
            suggestionController.recordWord(currentWord)
        }
        suggestionController.clearSuggestions()
        return true
    }

    func handleInputBufferSuggestion(at index: Int) {
        let suggestionIndex = index - 1

        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            baseText: inputBuffer
        ) else { return }

        replaceText(deleteCount: result.deleteCount, insert: result.insertText)

        suggestionController.recordWord(result.insertText)

        suggestionDidApply()
        updateSuggestions()
    }
}
