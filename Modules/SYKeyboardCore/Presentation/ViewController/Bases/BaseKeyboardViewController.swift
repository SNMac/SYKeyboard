//
//  BaseKeyboardViewController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit
import OSLog
import SYKeyboardAssets

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
        return !hasFullAccess && !keyboardExtensionLocalStateStore.isClosed
    }

    /// 키보드 설정을 관리하는 `UserDefaultsManager`
    final public let keyboardSettingsManager: UserDefaultsManager = UserDefaultsManager.shared
    /// Keyboard extension별 local 상태 저장소
    final public let keyboardExtensionLocalStateStore = KeyboardExtensionLocalStateStore()

    /// 전체 접근 허용 안내 오버레이. Full Access가 꺼져 있고 사용자가 닫지 않았을 때만 만든다
    private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()

    final public lazy var oldKeyboardType: UIKeyboardType? = textDocument.keyboardType
    /// 마지막으로 확인한 `textContentType`. `inputTraitsDidChange()` 판정에 쓰입니다
    final public lazy var oldTextContentType: UITextContentType? = textDocument.textContentType
    /// 텍스트 프록시 읽기·쓰기 창구. 프록시는 이것으로만 읽고 쓴다
    final public private(set) lazy var textDocument = CachingTextDocumentProxy { [weak self] in
        guard let self else {
            // 키보드가 이미 사라졌으므로 프록시를 읽거나 쓰지 않는다.
            // Release는 크래시 대신 기록만 남기고, Debug는 `assertionFailure`로 멈춘다
            let message = "text document accessed after controller deinit"
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "BaseKeyboardViewController")
                .fault("\(message, privacy: .public)")
            KeyboardDiagnostics.log(message)
            assertionFailure("BaseKeyboardViewController가 해제된 뒤 textDocument에 접근했습니다")
            return nil
        }
        return self.textDocumentProxy
    }

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
        return primaryKeyboardViews.map(\.returnButton)
        + [symbolKeyboardView.returnButton, numericKeyboardView.returnButton]
    }
    /// 전체 키보드 버튼 배열
    private var allKeyboardButtonList: [BaseKeyboardButton] {
        return primaryKeyboardViews.flatMap(\.allButtonList)
        + symbolKeyboardView.allButtonList
        + numericKeyboardView.allButtonList
        + tenkeyKeyboardView.allButtonList
    }
    /// 기본/숫자 키보드 입력 버튼 배열
    private var primaryAndNumericTextInteractableButtonList: [TextInteractable] {
        return primaryKeyboardViews.flatMap(\.totalTextInterableButtonList)
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
        hangeulKeyboardView: hangeulSwitchGestureKeyboardView,
        englishKeyboardView: englishSwitchGestureKeyboardView,
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
    private var smartQuoteState = KeyboardSmartQuoteState()
    /// 버퍼가 빈 상태에서 첫 글자를 넣기 직전의 커서 앞 문맥(최대 256자). 후보 기준 텍스트와 조각 판정에 쓴다
    private var inputBufferLeadingContext: String?

    /// `KeyboardView` 높이 제약 조건
    private var keyboardViewHeightConstraint: NSLayoutConstraint?
    /// `keyboardHStackView` 높이 제약 조건
    private var keyboardHStackViewHeightConstraint: NSLayoutConstraint?

    /// 현재 반복 입력 동작 중인지 확인하는 플래그
    public var isRepeatingInput: Bool { textDeletionCoordinator.isRepeatingInput }
    /// 첫 표시 이후 자동완성 준비를 한 번만 시작했는지 여부
    private var didStartDeferredSuggestionPreparation = false
    /// 첫 후보 갱신 계측 이벤트 중복 방지 플래그
    private var didEmitFirstSuggestionUpdateSignpost = false
    /// 첫 입력 처리 계측 이벤트 중복 방지 플래그
    private var didEmitFirstTextInteractionSignpost = false
    /// primary 버튼 커서 드래그 중에는 `textDidChange` 후보 갱신을 건너뜁니다.
    private var isPrimaryCursorDragging = false
    /// 커서 이동 요청 직전 문맥입니다. `textDidChange`에서 실제 위치 변경을 확인한 뒤 소비합니다.
    private var pendingCursorDragHapticContext: KeyboardTextContextSnapshot?
    /// host text input 변경 hook에 마지막으로 전달한 식별자입니다.
    private var lastNotifiedTextInputIdentifier: ObjectIdentifier?
    /// suggestion bar 전체를 숨겨야 하는지 여부
    private var shouldHideSuggestionBar: Bool {
        return KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
            isPredictiveTextEnabled: keyboardSettingsManager.isPredictiveTextEnabled,
            autocorrectionType: suggestionSelectionCoordinator.currentAutocorrectionType,
            currentKeyboard: currentKeyboard,
            isUndoRedoEnabled: keyboardSettingsManager.isUndoRedoEnabled,
            isClipboardHistoryEnabled: isClipboardControlAvailable
        )
    }

    /// 클립보드 버튼을 표시할 설정 상태
    ///
    /// 바 표시 판정과 버튼 표시 판정이 같은 값을 봐야 버튼 없는 빈 바가 생기지 않는다.
    /// 앱 미리보기도 실제 키보드와 같은 모습을 보여야 하므로 여기서 제외하지 않고,
    /// 탭 동작만 `suggestionBarDidTapClipboard`에서 막는다.
    private var isClipboardControlAvailable: Bool {
        return keyboardSettingsManager.isClipboardHistoryEnabled
    }

    /// '.' 단축키 수행 여부
    final public var performedPeriodShortcut: Bool = false
    /// 사용자가 '.' 단축키로 입력된 마침표를 지웠을 때, 다시 '.' 단축키가 실행되는 것을 막는 플래그
    final public var preventNextPeriodShortcut: Bool = false

    /// 기호 키보드에서 기호 입력 여부를 저장하는 변수
    private var isSymbolInput: Bool = false
    /// 길게 누르기로 작은따옴표를 입력했는지 저장하는 변수 (손을 뗄 때 기본 키보드로 전환)
    private var didInputApostropheByLongPress: Bool = false

    // MARK: - UI Components

    private lazy var keyboardView: KeyboardView = {
        return KeyboardView.loadFromNib(primaryKeyboardViews: primaryKeyboardViews)
    }()
    /// 자동완성 툴바
    private lazy var suggestionBarView = keyboardView.suggestionBarView
    /// 후보 탭 처리·trait 동기화·전송 기록·후보 삭제 확인을 맡는다. `SuggestionSelectionHost` 채택은 파일 끝의 extension에 있다
    private lazy var suggestionSelectionCoordinator = SuggestionSelectionCoordinator(
        suggestionController: suggestionController,
        suggestionBarView: suggestionBarView,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
    /// 키보드 수평 스택
    private lazy var keyboardHStackView = keyboardView.keyboardHStackView
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private lazy var leftChevronButton = keyboardView.leftChevronButton
    /// 주 키보드(오버라이딩 필요)
    open var primaryKeyboardView: PrimaryKeyboardRepresentable { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 설치할 주 키보드 목록
    open var primaryKeyboardViews: [PrimaryKeyboardRepresentable] { [primaryKeyboardView] }
    /// 한글 전환 제스처를 처리할 키보드
    open var hangeulSwitchGestureKeyboardView: SwitchGestureHandling { primaryKeyboardView }
    /// 영어 전환 제스처를 처리할 키보드
    open var englishSwitchGestureKeyboardView: SwitchGestureHandling { primaryKeyboardView }
    /// 기호 키보드
    final public lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = keyboardView.symbolKeyboardView
    /// 숫자 키보드
    final public lazy var numericKeyboardView: NumericKeyboardLayoutProvider = keyboardView.numericKeyboardView
    /// 텐키 키보드
    final public lazy var tenkeyKeyboardView: TenkeyKeyboardLayoutProvider = keyboardView.tenkeyKeyboardView
    /// 클립보드 기록 패널
    final lazy var clipboardHistoryPanelView: ClipboardHistoryPanelView = keyboardView.clipboardHistoryPanelView
    /// 클립보드 기록 저장소. App Group 컨테이너를 얻지 못하면 `nil`이고 기능은 비활성 상태다
    final let clipboardHistoryStore: ClipboardHistoryStore? = ClipboardHistoryStore()
    /// 클립보드 패널 열기·닫기와 pasteboard 동기화를 맡는다. `ClipboardHistoryHost` 채택은 파일 끝의 extension에 있다
    private lazy var clipboardHistoryCoordinator = ClipboardHistoryCoordinator(
        clipboardHistoryStore: clipboardHistoryStore,
        clipboardHistoryPanelView: clipboardHistoryPanelView,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
    /// undo/redo 기록·확정·적용과 컨트롤 갱신을 맡는다. `UndoRedoHost` 채택은 파일 끝의 extension에 있다
    private lazy var undoRedoCoordinator = UndoRedoCoordinator(
        suggestionBarView: suggestionBarView,
        suggestionController: suggestionController,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private lazy var rightChevronButton = keyboardView.rightChevronButton
    /// 커서 드래그 활성 상태를 표시하는 overlay
    private lazy var cursorDragIndicatorView: CursorDragIndicatorView = {
        let view = CursorDragIndicatorView()
        view.isHidden = true
        return view
    }()
    /// 삭제 버튼 드래그 활성 상태를 표시하는 overlay
    private lazy var deleteDragIndicatorView: CursorDragIndicatorView = {
        let view = CursorDragIndicatorView(
            symbolName: CursorDragIndicatorSymbolFactory.deleteSymbolName
        )
        view.isHidden = true
        return view
    }()
    /// 삭제 touchDown·반복·pan과 삭제 확정 파이프라인을 맡는다. `TextDeletionHost` 채택은 파일 끝의 extension에 있다
    private lazy var textDeletionCoordinator = TextDeletionCoordinator(
        deleteDragIndicatorView: deleteDragIndicatorView,
        suggestionController: suggestionController,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )

    // MARK: - Initializer

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.suggestionController = SuggestionController()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// - Parameters:
    ///   - language: 키보드 언어. `UITextChecker` 언어로도 쓴다
    ///   - nGramLanguage: NGram 엔진 식별자. `nil`이면 `language`를 따른다
    public init(language: String, nGramLanguage: String? = nil) {
        self.suggestionController = SuggestionController(language: language, nGramLanguage: nGramLanguage)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.left, .right]
    }

    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }

    // MARK: - Lifecycle

    open override func loadView() {
        logger.debug("loadView")
        let state = performanceSignposter.beginInterval("KeyboardLoadView")
        defer { performanceSignposter.endInterval("KeyboardLoadView", state) }

        self.view = keyboardView
    }

    open override func viewDidLoad() {
        let state = performanceSignposter.beginInterval("KeyboardViewDidLoad")
        defer { performanceSignposter.endInterval("KeyboardViewDidLoad", state) }

        super.viewDidLoad()
        logger.debug("viewDidLoad")
        KeyboardDiagnostics.installConstraintConflictLogging()
        resetInputBuffer()
        setupUI()
        // 레이아웃마다 읽으면 호스트가 문서 상태를 교체하는 순간과 겹쳐 UIKit 내부에서 크래시가 나므로 한 번만 읽는다
        setNextKeyboardButton()
        clipboardHistoryCoordinator.registerNotificationObservers()
        updateShowingKeyboard()
        if BaseKeyboardViewController.isPreview { updateReturnButtonType() }

        if keyboardSettingsManager.isOneHandedKeyboardEnabled { updateOneHandModekeyboard() }

        // 사용자 설정을 SuggestionController에 전달 — 엔진 생성은 첫 표시 이후로 지연
        suggestionController.isTextReplacementEnabled = keyboardSettingsManager.isTextReplacementEnabled
        suggestionController.isPredictiveTextEnabled = keyboardSettingsManager.isPredictiveTextEnabled
        suggestionController.isShowMathResultsEnabled = suggestionSelectionCoordinator.shouldShowMathResults()

        if KeyboardSuggestionSelectionPolicy.shouldStartLexiconLoadBeforeFirstAppearance(
            isTextReplacementEnabled: keyboardSettingsManager.isTextReplacementEnabled
        ) {
            suggestionController.loadLexicon(from: self)
        }

        updateSuggestionBarHidden()
        updateEdgeTouchSystemGesturePolicy()

        // 키보드 뷰 위에 덮어야 하므로 마지막에 올린다. 앱 미리보기에서는 표시하지 않는다
        if !BaseKeyboardViewController.isPreview, needToShowFullAccessGuide {
            requestFullAccessOverlayView.install(
                in: view,
                onClose: { [weak self] in self?.keyboardExtensionLocalStateStore.isClosed = true },
                onOpenSettings: { [weak self] url in self?.openURLThroughResponderChain(url) }
            )
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        let state = performanceSignposter.beginInterval("KeyboardViewWillAppear")
        defer { performanceSignposter.endInterval("KeyboardViewWillAppear", state) }

        super.viewWillAppear(animated)
        logger.debug("viewWillAppear")
        if !BaseKeyboardViewController.isPreview { setKeyboardHeight() }
        clipboardHistoryCoordinator.synchronizeIfNeeded()
        // 시뮬레이터(iOS 18.6)에서는 키보드가 나타날 때마다 새 VC라 엔진 캐시도 새로 읽지만, 같은 VC가 다시 나타나는 경우에 대비한다
        suggestionController.invalidateLearnedWordsCache()
        FeedbackManager.shared.prepareHaptic()
        updateEdgeTouchSystemGesturePolicy()
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // 언어별로 캐시해 둔 예측 엔진 중 지금 쓰지 않는 것부터 버린다
        suggestionController.releaseInactiveLanguageEngines()
        // 클립보드 패널 썸네일은 파일에서 다시 읽을 수 있다
        clipboardHistoryPanelView.purgeThumbnailCache()
    }

    open override func viewDidAppear(_ animated: Bool) {
        logger.debug("viewDidAppear")
        let state = performanceSignposter.beginInterval("KeyboardViewDidAppear")
        defer { performanceSignposter.endInterval("KeyboardViewDidAppear", state) }

        super.viewDidAppear(animated)
        KeyboardDiagnostics.log("keyboard appeared")
        updateEdgeTouchSystemGesturePolicy()
        startDeferredSuggestionPreparationIfNeeded()
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        logger.debug("viewWillTransition")
        coordinator.animate { [weak self] _ in self?.setKeyboardHeight() }
    }

    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        logger.debug("textWillChange")
        // 콜백 한 번에 같은 프록시 값을 다시 읽지 않는다. 문서 상태 교체와 겹친 읽기는 크래시한다
        textDocument.withReadCaching {
            let inputIdentifier = textInputIdentifier(for: textInput)
            if let inputIdentifier,
               inputIdentifier != lastNotifiedTextInputIdentifier {
                lastNotifiedTextInputIdentifier = inputIdentifier
                textInputDidChange(textInput)
            }
            suggestionSelectionCoordinator.synchronizeTextInputTraits()
            textDeletionCoordinator.synchronizeInputIdentifier(inputIdentifier)
            undoRedoCoordinator.prepareForTextWillChange(inputIdentifier: inputIdentifier)
            suggestionSelectionCoordinator.captureSentTextSnapshot()
            resetInputBuffer()
            updateKeyboardType()
            updateReturnButtonType()
            updateReturnButtonEnabled()
            updateSuggestionBarHidden()
            clipboardHistoryCoordinator.closePanelIfNeeded()
            clipboardHistoryCoordinator.synchronizeIfNeeded()
        }
    }

    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        logger.debug("textDidChange")
        // 보류된 삭제를 이어 가며 프록시에 쓰면 캐시가 비워져 그 뒤 읽기는 삭제가 반영된 값을 본다
        textDocument.withReadCaching {
            suggestionSelectionCoordinator.synchronizeTextInputTraits()
            let inputIdentifier = textInputIdentifier(for: textInput)
            textDeletionCoordinator.synchronizeInputIdentifier(inputIdentifier)
            // `textWillChange`에서 떠 둔 스냅샷과 지금 문맥을 비교해 전송으로 비워졌으면 기록한다
            suggestionSelectionCoordinator.recordSentTextIfNeeded()
            let currentTextContext = textDocument.contextSnapshot
            if KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: isPrimaryCursorDragging,
                pendingRequestContext: pendingCursorDragHapticContext,
                currentContext: currentTextContext
            ) {
                FeedbackManager.shared.playHaptic(isForcing: true)
            }
            pendingCursorDragHapticContext = nil
            textDeletionCoordinator.completeAfterTextChange(currentContext: currentTextContext)
            undoRedoCoordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: inputIdentifier)
            updateKeyboardType()
            // iOS는 키보드 확장에 textWillChange/textDidChange의 textInput을 항상 nil로 준다.
            // 그래서 필드 객체 동일성으로는 포커스가 다른 필드로 옮겨졌는지 알 수 없다.
            // keyboardType/textContentType 변화를 대신 신호로 써서 언어 재판정 같은 훅을 부른다
            let inputTraitsDidChange = textDocument.keyboardType != oldKeyboardType
                || textDocument.textContentType != oldTextContentType
            oldKeyboardType = textDocument.keyboardType
            oldTextContentType = textDocument.textContentType
            if inputTraitsDidChange { self.inputTraitsDidChange() }
            updateReturnButtonType()
            updateReturnButtonEnabled()
            updateSuggestionBarHidden()
            if KeyboardSuggestionSelectionPolicy.shouldUpdateSuggestionsOnTextDidChange(
                isPrimaryCursorDragging: isPrimaryCursorDragging
            ) {
                updateSuggestions()
            }
        }
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
        KeyboardDiagnostics.log("keyboard will disappear")
        textDeletionCoordinator.stopRepeatInputTracking()
        clipboardHistoryCoordinator.closePanelIfNeeded()
        suggestionSelectionCoordinator.hideSuggestionRemovalConfirmation()
        textDeletionCoordinator.resetInputIdentifier()
        lastNotifiedTextInputIdentifier = nil
        undoRedoCoordinator.removeAllHistory()
        suggestionSelectionCoordinator.discardSentTextSnapshot()
        resetInputBuffer()
        suggestionController.saveNGramData()
    }

    // MARK: - Overridable Methods

    open func didSetCurrentKeyboard() {
        updateShowingKeyboard()
        updateReturnButtonType()
    }

    /// 현재 host text input이 바뀐 뒤 실행되는 메서드
    open func textInputDidChange(_ textInput: (any UITextInput)?) {}

    /// 입력 필드의 `keyboardType` 또는 `textContentType`이 바뀌면 호출된다.
    ///
    /// iOS는 키보드 확장에 `textWillChange`/`textDidChange`의 `textInput`을 nil로 주므로
    /// 필드 객체의 동일성으로는 포커스 변경을 알 수 없다. trait 변화가 대신 쓸 수 있는 신호다
    open func inputTraitsDidChange() {}

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

        textDeletionCoordinator.clearPanRestoreState()
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

    /// undo/redo 또는 클립보드 붙여넣기로 텍스트가 직접 변경된 후 내부 입력 상태를 동기화하기 위한 hook입니다.
    ///
    /// 한글 VC는 이 hook에서 조합 상태를 비운다. 붙여넣기 뒤에 다음 자모가 새 글자로 시작하는 근거다.
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

    /// smartQuotesType이 `.default`일 때 smart quotes를 적용할지 결정합니다.
    open var treatsDefaultSmartQuotesAsEnabled: Bool {
        return true
    }

    /// Smart Quotes 입력 규칙을 결정합니다.
    open var smartQuoteRule: KeyboardSmartQuoteRule {
        return .koreanSystem
    }

    /// 반복 텍스트 상호작용이 일어나기 전 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func repeatTextInteractionWillPerform(button: TextInteractable) {
        textDeletionCoordinator.beginRepeatInput()

        // 삭제 버튼은 첫 입력을 touchDown에서 처리하거나 하위 클래스가 별도 경로로 처리한다
        guard !(button is DeleteButton) else { return }
        performInitialRepeatTextInteraction(for: button)
    }
    /// 길게 누르기가 인식된 직후 첫 글자를 입력하는 메서드 (삭제 버튼 제외)
    ///
    /// 반복 타이머의 첫 tick을 기다리지 않고 인식 시점에 바로 입력한다
    open func performInitialRepeatTextInteraction(for button: TextInteractable) {
        performTextInteraction(for: button)
        button.playFeedback()
    }
    /// 반복 텍스트 상호작용이 일어난 후 실행되는 메서드
    ///
    /// > 하위 클래스에서 오버라이드 시 반드시 `super`로 호출 필요
    open func repeatTextInteractionDidPerform(button: TextInteractable) {
        let isDeleteButton: Bool
        if case .deleteButton = button.type {
            isDeleteButton = true
        } else {
            isDeleteButton = false
        }
        textDeletionCoordinator.endRepeatInput(isDeleteButton: isDeleteButton)

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
        insertTypedText(primaryKey)
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
        insertTypedText(secondaryKey)
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
        insertTypedText(primaryKey)
    }

    /// 공백 문자를 입력하는 메서드
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    open func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }

        suggestionController.recordUncommittedWords(from: learnableInputBuffer)

        insertText(" ")
        commitUndoRedoGroupIfPossible()
    }

    /// 개행 문자를 입력하는 메서드
    /// - `BaseKeyboardViewController.isPreview == true`이면 즉시 리턴
    open func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }

        suggestionController.endSentence(inputBuffer: learnableInputBuffer)

        textDocument.insertText("\n")
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
        guard let lastBeforeCursor = deleteButtonPanPreviousCharacter else { return nil }

        deleteText()
        return (lastBeforeCursor, true)
    }

    /// 삭제 버튼 팬 제스처가 다음에 지울 커서 앞 글자
    ///
    /// 입력창이 늦게 보낸 낡은 문맥을 읽지 않도록 `documentContextBeforeInput` 대신 드래그 시작 때 읽은 모델을 따릅니다.
    public var deleteButtonPanPreviousCharacter: Character? {
        return textDeletionCoordinator.panPreviousCharacter
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

    /// 미리보기에서 글자 열 너비 배율을 실시간으로 반영합니다.
    ///
    /// 숫자 키패드는 `primaryKeyboardViews`에 포함되지 않으므로 따로 갱신합니다
    public func updateLetterColumnWidthForPreview(to multiplier: Double) {
        primaryKeyboardViews.forEach { $0.updateLetterColumnWidthMultiplier(multiplier) }
        numericKeyboardView.updateLetterColumnWidthMultiplier(multiplier)
        self.view.layoutIfNeeded()
    }

    /// 미리보기는 `setKeyboardHeight()`를 거치지 않으므로 숫자 행 높이를 직접 갱신한다.
    /// 주 자판과 기호 자판에 같은 높이를 전달하며, 숫자 행이 없는 뷰는 무시한다
    public func updateNumberRowHeightForPreview(to height: CGFloat) {
        updateNumberRowHeight(height)
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
        captureInputBufferLeadingContextIfNeeded()
        textDocument.insertText(text)
        inputBuffer.append(text)
        recordUndoRedoChange(deletedText: "", insertedText: text)
    }

    /// 사용자가 키를 눌러 입력한 텍스트에만 Smart Punctuation을 적용합니다.
    public func insertTypedText(_ text: String) {
        let transform = KeyboardSmartInputPolicy.transformTypedText(
            text,
            documentContextBeforeInput: typedTextContextBeforeInput(),
            isSmartPunctuationEnabled: keyboardSettingsManager.isSmartPunctuationEnabled,
            smartQuotesType: textDocument.smartQuotesType ?? .default,
            smartDashesType: textDocument.smartDashesType ?? .default,
            isDefaultSmartQuotesEnabled: treatsDefaultSmartQuotesAsEnabled,
            quoteRule: smartQuoteRule,
            nextDoubleQuoteIsOpening: smartQuoteState.nextDoubleQuoteIsOpening
        )

        if transform.deleteCount > 0 {
            replaceText(deleteCount: transform.deleteCount, insert: transform.insertText)
        } else {
            insertText(transform.insertText)
        }
        smartQuoteState.consume(transform)
    }

    /// `textDocumentProxy`에서 1글자를 삭제하고 `inputBuffer`를 동기화합니다.
    ///
    /// `textDocumentProxy.deleteBackward()`를 직접 호출하는 대신 이 메서드를 사용하여
    /// 입력 버퍼가 항상 실제 입력과 일치하도록 보장합니다.
    public func deleteText() {
        let wasSpaceAtEnd = inputBuffer.last?.isWhitespace == true
        let selectedText = textDocument.selectedText
        let panDeletedTextOverride = textDeletionCoordinator.takePanDeletedTextOverride()
        // 선택 영역을 지우는 경우에는 모델 글자 대신 선택 영역을 기록한다
        let panDeletedText = (selectedText ?? "").isEmpty ? panDeletedTextOverride : nil
        let deletedText = panDeletedText
            ?? KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: selectedText,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )

        textDocument.deleteBackward()
        if !inputBuffer.isEmpty {
            inputBuffer.removeLast()
        }
        let reliability: RepeatDeleteMutationReliability =
            selectedText?.isEmpty == false ? .authoritative : .proxyContext
        recordUndoRedoChange(
            deletedText: deletedText,
            insertedText: "",
            reliability: reliability
        )

        if inputBuffer.isEmpty {
            // 모든 입력을 지운 경우 → 문장 버퍼 전체 초기화
            suggestionController.resetSentenceBuffer()
            inputBufferLeadingContext = nil
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
        captureInputBufferLeadingContextIfNeeded()
        let inputBufferCountBeforeReplacement = inputBuffer.count
        let deletedText = textBeforeCursorSuffix(count: deleteCount)
        replaceTextInDocument(deleteCount: deleteCount, insert: text)
        replaceInputBufferSuffix(deleteCount: deleteCount, insert: text)
        inputBufferLeadingContext = KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement(
            inputBufferLeadingContext,
            inputBufferCount: inputBufferCountBeforeReplacement,
            deleteCount: deleteCount
        )
        recordUndoRedoChange(deletedText: deletedText, insertedText: text)
    }

    /// 입력 버퍼를 초기화합니다.
    ///
    /// 커서 이동, 키보드 열림/닫힘 등 버퍼와 실제 텍스트 위치가
    /// 어긋날 수 있는 상황에서 호출합니다.
    public func resetInputBuffer() {
        inputBuffer = ""
        inputBufferLeadingContext = nil
        smartQuoteState.reset()
        suggestionController.resetSentenceBuffer()
    }

    /// 예측 엔진 언어만 갱신합니다.
    public final func updateSuggestionLanguage(to language: String) {
        suggestionController.updateLanguage(to: language)
    }

    /// 언어 전환 전에 진행 중인 반복·삭제·버튼 상호작용을 종료합니다.
    public final func stopInputInteractionsForLanguageChange() {
        textDeletionCoordinator.stopRepeatInputTracking()
        buttonStateController.currentPressedButton = nil
        buttonStateController.isShiftButtonPressed = false
    }

    /// 조합 확정 지연 요청이 있었고 현재 확정 가능한 상태라면 pending undo 단위를 stack에 반영합니다.
    public final func commitDeferredUndoRedoGroupIfNeeded() {
        undoRedoCoordinator.commitDeferredGroupIfNeeded()
    }

    /// 스페이스/리턴처럼 사용자가 명시적인 편집 경계를 만든 경우 pending undo 단위를 확정합니다.
    public final func commitUndoRedoGroupIfPossible() {
        undoRedoCoordinator.commitPendingGroup()
    }

    /// 삭제 시작처럼 조합 중이어도 이전 편집 단위를 끊어야 하는 경우 pending undo 단위를 확정합니다.
    public final func commitUndoRedoGroupIgnoringCompositionDeferral() {
        undoRedoCoordinator.commitPendingGroupIgnoringDeferral()
    }

    /// 선택 영역을 `insertText`로 대치하고 `inputBuffer`와 undo 기록을 맞춘다. 후보 선택과 수식 결과 대치가 쓴다
    func replaceSelectedText(_ selectedText: String, with insertText: String) {
        captureInputBufferLeadingContextIfNeeded()
        textDocument.insertText(insertText)
        inputBuffer.append(insertText)
        recordUndoRedoChange(
            deletedText: selectedText,
            insertedText: insertText
        )
    }
}

// MARK: - Text Proxy Wrapper Helper Methods

private extension BaseKeyboardViewController {
    func replaceTextWithSmartInsertDeleteSpacing(deleteCount: Int, insert text: String) {
        replaceText(
            deleteCount: deleteCount,
            insert: textWithSmartInsertDeleteLeadingSpace(
                deleteCount: deleteCount,
                insert: text
            )
        )
    }

    func textWithSmartInsertDeleteLeadingSpace(deleteCount: Int, insert text: String) -> String {
        return KeyboardSmartInputPolicy.smartInsertDeleteLeadingSpacePrefix(
            textBeforeInsertion: textBeforeInsertionAfterDeletingSuffix(deleteCount: deleteCount),
            isSmartPunctuationEnabled: keyboardSettingsManager.isSmartPunctuationEnabled,
            smartInsertDeleteType: textDocument.smartInsertDeleteType ?? .default
        ) + text
    }

    func textBeforeInsertionAfterDeletingSuffix(deleteCount: Int) -> String {
        let textBeforeCursor = inputBuffer.isEmpty
            ? KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(
                textDocument.documentContextBeforeInput
            )
            : inputBuffer

        guard deleteCount > 0 else { return textBeforeCursor }
        guard textBeforeCursor.count >= deleteCount else { return "" }
        return String(textBeforeCursor.dropLast(deleteCount))
    }

    func replaceTextInDocument(deleteCount: Int, insert text: String) {
        for _ in 0..<deleteCount {
            textDocument.deleteBackward()
        }
        if !text.isEmpty {
            textDocument.insertText(text)
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

    func typedTextContextBeforeInput() -> String {
        if !inputBuffer.isEmpty { return inputBuffer }
        return KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(
            textDocument.documentContextBeforeInput
        )
    }

}

// MARK: - UI Methods

private extension BaseKeyboardViewController {
    func setupUI() {
        setCursorDragOverlays()
        setDelegates()
        setActions()
    }

    func setDelegates() {
        textInteractionGestureController.delegate = self
        switchGestureController.delegate = self
        suggestionController.delegate = suggestionSelectionCoordinator
        suggestionBarView.suggestionDelegate = suggestionSelectionCoordinator
        clipboardHistoryPanelView.delegate = clipboardHistoryCoordinator
        clipboardHistoryPanelView.imageStore = clipboardHistoryStore?.imageStore
    }

    func setActions() {
        setButtonFeedbackAction()
        setTextInteractableButtonAction()
        setSwitchButtonAction()
        setExclusiveButtonAction()
        setChevronButtonAction()
    }

    func setCursorDragOverlays() {
        [cursorDragIndicatorView, deleteDragIndicatorView].forEach {
            keyboardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: keyboardHStackView.topAnchor),
                $0.leadingAnchor.constraint(equalTo: keyboardHStackView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: keyboardHStackView.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: keyboardHStackView.bottomAnchor)
            ])
        }
    }

    func setKeyboardHeight() {
        guard let window = self.view.window else { return }
        let windowScene = window.windowScene
        let orientation = windowScene?.effectiveGeometry.interfaceOrientation ?? .unknown

        let isSuggestionBarVisible = !shouldHideSuggestionBar

        let isPortrait = KeyboardHeightPolicy.isPortrait(
            orientation: orientation,
            usesOrientation: usesInterfaceOrientationForKeyboardHeight,
            fallbackBounds: window.bounds,
            horizontalSizeClass: traitCollection.horizontalSizeClass,
            verticalSizeClass: traitCollection.verticalSizeClass
        )

        // 숫자 행 여부는 설정값이 아니라 실제로 만들어진 뷰를 기준으로 판단한다.
        // extension이 살아 있는 동안 설정이 바뀌어도 뷰와 프레임 높이가 어긋나지 않는다
        let numberRowHeight = KeyboardHeightPolicy.numberRowHeight(
            isEnabled: primaryKeyboardViews.contains { $0.showsNumberRow },
            isPortrait: isPortrait,
            keyboardSettingsHeight: keyboardSettingsManager.keyboardHeight
        )
        updateNumberRowHeight(numberRowHeight)

        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: keyboardSettingsManager.keyboardHeight,
            landscapeKeyboardHeight: KeyboardLayoutFigure.landscapeKeyboardHeight,
            suggestionBarHeight: KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing,
            isSuggestionBarVisible: isSuggestionBarVisible,
            isPortrait: isPortrait,
            numberRowHeight: numberRowHeight
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

    var usesInterfaceOrientationForKeyboardHeight: Bool {
        if #available(iOS 27.0, *) {
            return false
        }
        return true
    }

    func updateEdgeTouchSystemGesturePolicy() {
        guard !BaseKeyboardViewController.isPreview else { return }

        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        edgeTouchSystemGestureHostViews().forEach { hostView in
            hostView.gestureRecognizers?.forEach {
                KeyboardGesturePolicy.configureSystemGestureForEdgeTouch($0)
            }
        }
    }

    func edgeTouchSystemGestureHostViews() -> [UIView] {
        var hostViews: [UIView] = []
        var visitedIDs = Set<ObjectIdentifier>()

        func appendIfNeeded(_ view: UIView?) {
            guard let view else { return }
            let id = ObjectIdentifier(view)
            guard !visitedIDs.contains(id) else { return }
            visitedIDs.insert(id)
            hostViews.append(view)
        }

        appendIfNeeded(view.window)

        var parentView = view.superview
        while let currentView = parentView {
            appendIfNeeded(currentView)
            parentView = currentView.superview
        }

        return hostViews
    }

    func setNextKeyboardButton() {
        // 뷰마다 다시 조회하면 호스트 연결 전 경고 로그가 그만큼 반복되므로 한 번만 읽는다
        let needsInputModeSwitchKey = self.needsInputModeSwitchKey

        primaryKeyboardViews.forEach {
            $0.updateNextKeyboardButton(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                        nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        }
        [symbolKeyboardView, numericKeyboardView].forEach {
            $0.updateNextKeyboardButton(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                        nextKeyboardAction: #selector(self.handleInputModeList(from:with:)))
        }

        keyboardSettingsManager.needsInputModeSwitchKey = needsInputModeSwitchKey
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
            button.addAction(
                makeDeleteButtonReleaseAction(),
                for: [.touchUpInside, .touchUpOutside, .touchCancel]
            )
        } else if let spaceButton = button as? SpaceButton {
            button.addAction(inputAction, for: .touchUpInside)
            addPeriodShortcutActionToSpaceButton(spaceButton)
        } else {
            button.addAction(inputAction, for: .touchUpInside)
        }
    }

    func makeDeleteButtonReleaseAction() -> UIAction {
        return UIAction { [weak self] _ in
            self?.textDeletionCoordinator.finishTouchDown()
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
        case .keyButton where KeyboardSymbolInputPolicy.isApostropheKey(button.type):
            let switchToPrimaryKeyboard = UIAction { [weak self] _ in
                guard let self else { return }
                if KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
                    buttonType: button.type,
                    keyboardType: textDocument.keyboardType ?? .default,
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
                    keyboardType: textDocument.keyboardType ?? .default,
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
                    documentContextBeforeInput: textDocument.documentContextBeforeInput
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
        primaryKeyboardViews.forEach { primaryKeyboardView in
            let switchButton = primaryKeyboardView.switchButton
            let switchToSymbolKeyboard = UIAction { [weak self, weak switchButton] action in
                guard let self, let switchButton,
                      let sender = action.sender as? SwitchButton,
                      sender === switchButton,
                      buttonStateController.currentPressedButton === switchButton else { return }
                currentKeyboard = .symbol
            }
            switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        }

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

        (primaryKeyboardViews.map(\.switchButton)
         + [symbolKeyboardView.switchButton, numericKeyboardView.switchButton])
            .forEach { addGesturesToSwitchButton($0) }
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
    func updateNumberRowHeight(_ height: CGFloat) {
        primaryKeyboardViews.forEach { $0.updateNumberRowHeight(height) }
        // 기호 자판은 주 자판과 같은 높이를 써야 프레임과 어긋나지 않는다
        keyboardView.symbolKeyboardView.updateNumberRowHeight(height)
    }

    func updateOneHandModekeyboard() {
        keyboardView.updateOneHandedMode(currentOneHandedMode)
    }

    func updateShowingKeyboard() {
        primaryKeyboardViews.forEach { $0.isHidden = true }
        if currentKeyboard == primaryKeyboardView.keyboard {
            primaryKeyboardView.isHidden = false
        }
        symbolKeyboardView.isHidden = (currentKeyboard != .symbol)
        symbolKeyboardView.initShiftButton()
        isSymbolInput = false
        numericKeyboardView.isHidden = (currentKeyboard != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboard != .tenKey)
        if clipboardHistoryCoordinator.isPanelVisible {
            primaryKeyboardViews.forEach { $0.isHidden = true }
            symbolKeyboardView.isHidden = true
            numericKeyboardView.isHidden = true
            tenkeyKeyboardView.isHidden = true
        }
        clipboardHistoryPanelView.isHidden = !clipboardHistoryCoordinator.isPanelVisible
    }

    func updateReturnButtonType() {
        let type = ReturnButton.ReturnKeyType(type: textDocument.returnKeyType)
        returnButtonList.forEach { $0.update(for: type) }
    }

    func updateReturnButtonEnabled() {
        let isEnabled = KeyboardPresentationStatePolicy.isReturnButtonEnabled(
            enablesReturnKeyAutomatically: textDocument.enablesReturnKeyAutomatically == true,
            documentContextBeforeInput: textDocument.documentContextBeforeInput,
            selectedText: textDocument.selectedText,
            documentContextAfterInput: textDocument.documentContextAfterInput
        )
        returnButtonList.forEach { $0.updateEnabled(isEnabled) }
    }

    func updateSuggestionBarHidden() {
        // VC가 살아 있는 동안 설정이 바뀔 수 있으므로 컨트롤러 쪽 값을 함께 맞춘다.
        // didSet에 idempotence 가드가 있어 값이 같으면 비용이 없다.
        // 설정이 바뀌면 엔진은 다음 updateSuggestions에서 재생성되지만 UILexicon 재로드는 하지 않는다
        suggestionController.isPredictiveTextEnabled = keyboardSettingsManager.isPredictiveTextEnabled

        let prevSuggestionHiddenState = suggestionBarView.isHidden

        let shouldHideBar = shouldHideSuggestionBar
        // 바가 남아 있어도 autocorrection이 막혀 있으면 후보 영역만 비운다
        let shouldHideSuggestions = KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
            isSuggestionBarHidden: shouldHideBar,
            isPredictiveTextEnabled: keyboardSettingsManager.isPredictiveTextEnabled,
            autocorrectionType: suggestionSelectionCoordinator.currentAutocorrectionType
        )

        suggestionBarView.isHidden = shouldHideBar
        suggestionBarView.updateSuggestionArea(isVisible: !shouldHideSuggestions)
        suggestionController.isSuspended = shouldHideSuggestions
        undoRedoCoordinator.refreshControls()

        if prevSuggestionHiddenState != shouldHideBar {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.setKeyboardHeight()
            }
        }
    }

    func updateSuggestionPreviewHighlight() {
        // 수식 모드가 아니면 mathResultAction은 선택 텍스트를 보지 않고 nil이다.
        // 비동기 후보 결과가 문서 상태 교체와 겹쳐 프록시를 읽으면 크래시하므로 이때는 읽지 않는다
        if suggestionController.currentMode == .mathExpression,
           suggestionController.mathResultAction(
               at: 1,
               selectedText: textDocument.selectedText
           ) != nil {
            suggestionBarView.updatePreviewHighlight(index: 1)
            return
        }

        suggestionBarView.updatePreviewHighlight(
            index: suggestionController.textReplacementPreviewSuggestionIndex(
                baseText: inputBuffer
            )
        )
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

        if case .deleteButton = button.type {
            textDeletionCoordinator.performTouchDown(for: button)
            return
        } else {
            textDeletionCoordinator.cancelPendingInteractions()
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
            // 길게 누르기가 인식되면 첫 글자를 이 경로로 바로 입력한다 (performInitialRepeatTextInteraction)
            if isRepeatingInput {
                markSymbolInputAfterLongPressIfNeeded(for: button)
            }
        case .deleteButton:
            assertionFailure("삭제 버튼은 semantic hook 경로에서 먼저 처리됩니다.")
        case .spaceButton:
            if let action = suggestionController.mathResultAction(
                at: 1,
                selectedText: textDocument.selectedText
            ), suggestionSelectionCoordinator.applyMathResultSuggestionAction(action) {
                // 수식 action을 적용한 경우 일반 텍스트 대치를 건너뜁니다.
            } else {
                if let replacement = suggestionController.attemptTextReplacement(
                    baseText: inputBuffer,
                    documentContextBeforeInput: textDocument.documentContextBeforeInput
                ) {
                    // 텍스트 대치: 래핑 메서드 사용
                    replaceTextWithSmartInsertDeleteSpacing(
                        deleteCount: replacement.deleteCount,
                        insert: replacement.insertText
                    )
                }
            }
            insertSpaceText()
        case .returnButton:
            performReturnButtonTextInteraction()
        }
    }

    final public func performRepeatTextInteraction(for button: TextInteractable) {
        guard self.view.window != nil else { return }

        if case .deleteButton = button.type {
            textDeletionCoordinator.performRepeatTick(for: button)
            return
        }

        textDeletionCoordinator.cancelPendingInteractions()
        textInteractionWillPerform(button: button)
        defer { textInteractionDidPerform(button: button) }

        switch button.type {
        case .keyButton:
            repeatInsertPrimaryKeyText(from: button)
            markSymbolInputAfterLongPressIfNeeded(for: button)
            button.playFeedback()
        case .deleteButton:
            assertionFailure("삭제 버튼은 semantic hook 경로에서 먼저 처리됩니다.")
        case .spaceButton:
            insertSpaceText()
            button.playFeedback()
        case .returnButton:
            performRepeatReturnButtonTextInteraction(for: button)
        }
    }

    /// 한글 조합 상태를 보존하는 첫 반복 삭제에 실제 삭제 기준 피드백을 적용합니다.
    final public func performInitialRepeatDeleteTextInteraction(for button: TextInteractable) {
        guard self.view.window != nil else { return }

        textDeletionCoordinator.performInitialRepeatDelete(for: button)
    }
}

// MARK: - Private Methods

private extension BaseKeyboardViewController {
    /// 래퍼가 수행한 편집을 기록한다. 삭제 파이프라인이 먼저 capture를 시도하고, 삭제 요청 중이 아니면 undo에 기록한다
    func recordUndoRedoChange(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability = .authoritative
    ) {
        if textDeletionCoordinator.captureMutation(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        ) { return }
        undoRedoCoordinator.record(deletedText: deletedText, insertedText: insertedText)
    }

    func updateClipboardControl() {
        let shouldShowClipboard = KeyboardPresentationStatePolicy.shouldShowClipboardControl(
            isSuggestionBarHidden: suggestionBarView.isHidden,
            isClipboardHistoryEnabled: isClipboardControlAvailable
        )
        suggestionBarView.updateClipboardControl(
            isVisible: shouldShowClipboard,
            isPanelVisible: clipboardHistoryCoordinator.isPanelVisible
        )
    }

    func textBeforeCursorSuffix(count: Int) -> String {
        guard count > 0,
              let beforeInput = textDocument.documentContextBeforeInput else { return "" }
        return String(beforeInput.suffix(count))
    }

    func textInputIdentifier(for textInput: (any UITextInput)?) -> ObjectIdentifier? {
        guard let textInput else { return nil }
        return ObjectIdentifier(textInput as AnyObject)
    }

    func updateSuggestions() {
        if !didEmitFirstSuggestionUpdateSignpost {
            didEmitFirstSuggestionUpdateSignpost = true
            performanceSignposter.emitEvent("FirstUpdateSuggestions")
        }

        updateSuggestionsForCurrentContext()
    }

    func updateSuggestionsForCursorContext() {
        updateSuggestionsForCurrentContext()
    }

    func updateSuggestionsForCurrentContext() {
        suggestionController.isShowMathResultsEnabled = suggestionSelectionCoordinator.shouldShowMathResults()

        let selectedText = textDocument.selectedText
        let action = KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
            isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
            selectedText: selectedText,
            baseText: generalSuggestionBaseText
        )
        let mathExpressionText = KeyboardSuggestionSelectionPolicy
            .mathExpressionDetectionText(
                selectedText: selectedText,
                inputBuffer: inputBuffer,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )

        switch action {
        case .none:
            break
        case .update(let text):
            suggestionController.updateSuggestions(
                for: text,
                selectedText: selectedText,
                mathExpressionText: mathExpressionText,
                // 선택 텍스트 후보는 선택한 단어 그대로 대치를 찾는다
                textReplacementBaseText: selectedText?.isEmpty == false ? text : inputBuffer
            )
        case .clear:
            suggestionController.clearSuggestions()
        }
    }

    func handlePeriodShortcutOnDelete() {
        // 정책이 커서 앞 텍스트를 실제로 보는 상태에서만 프록시를 조회한다.
        // 삭제 tick마다 무효화된 텍스트 입력 세션에 접근할 여지를 줄이고, 프록시 왕복도 줄인다
        let requiresDocumentContext = KeyboardPeriodShortcutPolicy.requiresDocumentContextAfterDelete(
            isPeriodShortcutEnabled: keyboardSettingsManager.isPeriodShortcutEnabled,
            performedPeriodShortcut: performedPeriodShortcut,
            preventsNextPeriodShortcut: preventNextPeriodShortcut
        )
        let state = KeyboardPeriodShortcutPolicy.stateAfterDelete(
            isPeriodShortcutEnabled: keyboardSettingsManager.isPeriodShortcutEnabled,
            performedPeriodShortcut: performedPeriodShortcut,
            preventsNextPeriodShortcut: preventNextPeriodShortcut,
            documentContextBeforeInput: requiresDocumentContext
            ? textDocument.documentContextBeforeInput
            : nil
        )

        performedPeriodShortcut = state.performedPeriodShortcut
        preventNextPeriodShortcut = state.preventsNextPeriodShortcut
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

// MARK: - Cursor Context Suggestions

private extension BaseKeyboardViewController {
    /// 버퍼가 비어 있으면 첫 글자를 넣기 직전의 커서 앞 문맥을 떠 둔다
    func captureInputBufferLeadingContextIfNeeded() {
        guard inputBuffer.isEmpty else { return }
        inputBufferLeadingContext = KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(
            textDocument.documentContextBeforeInput
        )
    }

    /// 일반 후보(n-gram·TextChecker)의 기준 텍스트
    ///
    /// 버퍼가 있으면 떠 둔 앞 문맥을 쓰므로 프록시 문맥을 읽지 않는다(키 입력마다 프록시 왕복을 늘리지 않음)
    var generalSuggestionBaseText: String {
        KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
            leadingContext: inputBufferLeadingContext,
            inputBuffer: inputBuffer,
            documentContextBeforeInput: inputBuffer.isEmpty ? textDocument.documentContextBeforeInput : nil
        )
    }

    /// 앞 글자에 붙어 시작한 조각을 뺀 버퍼. NGram 기록과 현재 단어 확정에 쓴다
    var learnableInputBuffer: String {
        KeyboardSuggestionSelectionPolicy.learnableInputBuffer(
            inputBuffer,
            isAttachedToLeadingContext: KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext(
                inputBufferLeadingContext
            )
        )
    }
}

// MARK: - TextInteractionGestureControllerDelegate

extension BaseKeyboardViewController: TextInteractionGestureControllerDelegate {
    final func primaryButtonCursorDragActivated(_ controller: TextInteractionGestureController) {
        showCursorDragOverlays()
    }

    final func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection, steps: Int) {
        isPrimaryCursorDragging = true

        // 커서 이동 시 입력 버퍼 초기화
        resetInputBuffer()
        _ = moveCursorIfPossible(to: direction, steps: steps)
    }

    final func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {
        textDeletionCoordinator.handlePan(to: direction)
    }

    final func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        textDeletionCoordinator.handlePanStop()
    }

    final func primaryButtonPanStopped(_ controller: TextInteractionGestureController) {
        hideCursorDragOverlays()
        isPrimaryCursorDragging = false
        updateReturnButtonEnabled()
        updateSuggestionsForCursorContext()
    }

    final func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {
        let isDeleteButton = button is DeleteButton
        didInputApostropheByLongPress = false

        if KeyboardGesturePolicy.shouldPerformRepeatInputOnLongPress(
            selectedLongPressAction: keyboardSettingsManager.selectedLongPressAction,
            isDeleteButton: isDeleteButton
        ) {
            repeatTextInteractionWillPerform(button: button)
            guard isRepeatingInput else { return }
            textDeletionCoordinator.startRepeatInputTimer(for: button)
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
        switchToPrimaryAfterApostropheLongPressIfNeeded(for: button)
    }
}

private extension BaseKeyboardViewController {
    func showCursorDragOverlays() {
        cursorDragIndicatorView.isHidden = false
    }

    func hideCursorDragOverlays() {
        cursorDragIndicatorView.isHidden = true
    }

    func moveCursorIfPossible(to direction: PanDirection, steps: Int) -> Int {
        let actualSteps = CursorDragAccelerationPolicy.applicableSteps(
            to: direction,
            requestedSteps: steps,
            documentContextBeforeInput: textDocument.documentContextBeforeInput,
            documentContextAfterInput: textDocument.documentContextAfterInput
        )
        guard actualSteps > 0 else { return 0 }

        pendingCursorDragHapticContext = textDocument.contextSnapshot
        switch direction {
        case .left:
            textDocument.adjustTextPosition(byCharacterOffset: -actualSteps)
        case .right:
            textDocument.adjustTextPosition(byCharacterOffset: actualSteps)
        default:
            pendingCursorDragHapticContext = nil
            assertionFailure("도달할 수 없는 case 입니다.")
            return 0
        }

        undoRedoCoordinator.refreshControls()
        return actualSteps
    }

    func performNumberInputLongPress(for button: TextInteractable) {
        performTextInteraction(for: button, insertSecondaryKeyIfAvailable: true)
        markSymbolInputAfterLongPressIfNeeded(for: button)
        button.isGesturing = false
        textInteractionGestureController.releaseButtonGesture(for: button)
    }

    func markSymbolInputAfterLongPressIfNeeded(for button: TextInteractable) {
        if KeyboardSymbolInputPolicy.shouldMarkSymbolInputAfterLongPressInput(
            buttonType: button.type,
            currentKeyboard: currentKeyboard
        ) {
            isSymbolInput = true
        } else if KeyboardSymbolInputPolicy.shouldRecordApostropheLongPressInput(
            buttonType: button.type,
            currentKeyboard: currentKeyboard
        ) {
            didInputApostropheByLongPress = true
        }
    }

    /// 길게 누르기로 작은따옴표를 입력했다면 탭과 같은 조건으로 기본 키보드로 전환
    func switchToPrimaryAfterApostropheLongPressIfNeeded(for button: TextInteractable) {
        guard didInputApostropheByLongPress else { return }
        didInputApostropheByLongPress = false

        if KeyboardSymbolInputPolicy.shouldSwitchToPrimaryAfterApostropheInput(
            buttonType: button.type,
            keyboardType: textDocument.keyboardType ?? .default,
            isAutoChangeToPrimaryEnabled: keyboardSettingsManager.isAutoChangeToPrimaryEnabled
        ) {
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }
}

// MARK: - SuggestionSelectionHost

extension BaseKeyboardViewController: SuggestionSelectionHost {
    var currentInputBuffer: String { inputBuffer }
    var suggestionBaseText: String { generalSuggestionBaseText }
    var learnableWordText: String { learnableInputBuffer }
    var overlayContainerView: UIView { view }

    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String) {
        replaceTextWithSmartInsertDeleteSpacing(deleteCount: deleteCount, insert: text)
    }

    func smartSpacedText(deleteCount: Int, insert text: String) -> String {
        textWithSmartInsertDeleteLeadingSpace(deleteCount: deleteCount, insert: text)
    }

    func refreshSuggestionPreviewHighlight() { updateSuggestionPreviewHighlight() }
    func undoLastEdit() { undoRedoCoordinator.undo() }
    func redoLastEdit() { undoRedoCoordinator.redo() }
    func toggleClipboardPanel() { clipboardHistoryCoordinator.togglePanel() }
}

// MARK: - ClipboardHistoryHost

extension BaseKeyboardViewController: ClipboardHistoryHost {
    var isPreviewMode: Bool { BaseKeyboardViewController.isPreview }
    var isViewInWindow: Bool { viewIfLoaded?.window != nil }

    func refreshShowingKeyboard() { updateShowingKeyboard() }
    func refreshClipboardControl() { updateClipboardControl() }
    func refreshReturnButtonEnabled() { updateReturnButtonEnabled() }
    func refreshSuggestions() { updateSuggestions() }
    func interruptPendingDeleteInteractions() { textDeletionCoordinator.cancelPendingInteractions() }
    func openURL(_ url: URL) { openURLThroughResponderChain(url) }
}

// MARK: - TextDeletionHost

extension BaseKeyboardViewController: TextDeletionHost {
    func performDeleteTextInteraction(for button: TextInteractable) { performTextInteraction(for: button) }

    func recordEditForUndo(deletedText: String, insertedText: String) {
        recordUndoRedoChange(deletedText: deletedText, insertedText: insertedText)
    }
}

// MARK: - UndoRedoHost

extension BaseKeyboardViewController: UndoRedoHost {}
