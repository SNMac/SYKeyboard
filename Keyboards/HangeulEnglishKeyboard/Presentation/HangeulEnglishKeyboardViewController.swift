//
//  HangeulEnglishKeyboardViewController.swift
//  HangeulEnglishKeyboard
//
//  Created by 서동환 on 6/28/26.
//

import UIKit
import OSLog

import EnglishKeyboardCore
import HangeulKeyboardCore
import SYKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 한글과 영어 입력/UI를 함께 제공하는 통합 키보드 컨트롤러
final class HangeulEnglishKeyboardViewController: BaseKeyboardViewController {

    // MARK: - Properties

    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )

    private let hangeulAdapter = HangeulKeyboardInputAdapter(
        selectedKeyboard: UserDefaultsManager.shared.selectedHangeulKeyboard,
        showsLanguageSwitchButton: true
    )
    private let englishAdapter = EnglishKeyboardInputAdapter(
        showsLanguageSwitchButton: true
    )
    private lazy var modeCoordinator = HangeulEnglishKeyboardModeCoordinator(
        initialMode: keyboardSettingsManager.lastHangeulEnglishLanguageMode
    )

    // MARK: - UI Components

    private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()

    override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        return hangeulAdapter.primaryKeyboardViews + [englishAdapter.primaryKeyboardView]
    }

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        switch modeCoordinator.currentMode {
        case .hangeul:
            return hangeulAdapter.primaryKeyboardView
        case .english:
            return englishAdapter.primaryKeyboardView
        }
    }

    override var hangeulSwitchGestureKeyboardView: SwitchGestureHandling {
        return hangeulAdapter.primaryKeyboardView
    }

    override var englishSwitchGestureKeyboardView: SwitchGestureHandling {
        return englishAdapter.primaryKeyboardView
    }

    override var shouldDeferUndoRedoCommit: Bool {
        return modeCoordinator.currentMode == .hangeul
            && hangeulAdapter.shouldDeferUndoRedoCommit
    }

    override var treatsDefaultSmartQuotesAsEnabled: Bool {
        return modeCoordinator.currentMode == .hangeul
    }

    override var smartQuoteRule: KeyboardSmartQuoteRule {
        return modeCoordinator.currentMode == .hangeul ? .koreanSystem : .englishSystem
    }

    // MARK: - Initializer

    init() {
        let mode = UserDefaultsManager.shared.lastHangeulEnglishLanguageMode
        SwitchButton.previewPrimaryLanguage = mode.languageIdentifier
        super.init(language: mode.languageIdentifier)
        primaryLanguage = mode.languageIdentifier
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLanguageSwitchActions()
        applyLanguageMode(modeCoordinator.currentMode, persist: false)
        setupFirebase()

        if needToShowFullAccessGuide {
            setupRequestFullAccessOverlayView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        let message = "Memory Warning Received in \(Bundle.main.bundleIdentifier ?? "Unknown Bundle")"
        logger.fault("\(message)")
        Crashlytics.crashlytics().log(message)
        Crashlytics.crashlytics().setCustomValue(true, forKey: "did_receive_memory_warning")
    }

    // MARK: - Override Methods

    override func textInputDidChange(_ textInput: (any UITextInput)?) {
        let previousMode = modeCoordinator.currentMode
        let mode = modeCoordinator.modeForTextInputChange(
            identifier: textInput.map { ObjectIdentifier($0 as AnyObject) },
            documentPrimaryLanguage: textDocumentProxy.documentInputMode?.primaryLanguage,
            lastMode: keyboardSettingsManager.lastHangeulEnglishLanguageMode
        )

        applyLanguageMode(
            mode,
            persist: true,
            outgoingMode: previousMode
        )
    }

    override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)

        switch modeCoordinator.currentMode {
        case .hangeul:
            hangeulAdapter.clearForExternalTextChange()
            updateHangeulSpaceButton()
            updateHangeulShiftButton()
        case .english:
            updateEnglishShiftButton()
        }
    }

    override func undoRedoEditDidApply() {
        super.undoRedoEditDidApply()
        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
        updateShiftButtonForCurrentMode()
    }

    override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearLetterInputState()
        }
        updateShiftButtonForCurrentMode()
    }

    override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }

        symbolKeyboardView.currentSymbolKeyboardMode = SymbolKeyboardMode(
            keyboardType: textDocumentProxy.keyboardType
        )
        hangeulAdapter.updateLayout(for: textDocumentProxy.keyboardType)
        englishAdapter.updateLayout(for: textDocumentProxy.keyboardType)

        switch textDocumentProxy.keyboardType {
        case .default, nil, .asciiCapable, .URL, .emailAddress, .twitter, .webSearch:
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            currentKeyboard = .symbol
        case .numberPad, .phonePad, .namePhonePad, .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        @unknown default:
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }

    override func textInteractionWillPerform(button: TextInteractable) {
        if modeCoordinator.currentMode == .hangeul {
            if button is DeleteButton {
                hangeulAdapter.beginDeleteTouchDown()
            } else {
                hangeulAdapter.cancelDeleteTouchDown()
            }
        }
        super.textInteractionWillPerform(button: button)
    }

    override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)

        switch modeCoordinator.currentMode {
        case .hangeul:
            if button is DeleteButton {
                hangeulAdapter.endDeleteTouchDown()
            } else {
                hangeulAdapter.cancelDeleteTouchDown()
            }
            hangeulAdapter.recordTextInteraction()
            if !hangeulAdapter.shouldDeferUndoRedoCommit {
                commitDeferredUndoRedoGroupIfNeeded()
            }
        case .english:
            if let primaryKey = button.type.primaryKeyList.first {
                englishAdapter.recordInsertedText(primaryKey)
            }
        }

        if !isRepeatingInput {
            updateShiftButtonForCurrentMode()
        }
    }

    override func suggestionDidApply() {
        super.suggestionDidApply()
        guard modeCoordinator.currentMode == .hangeul else { return }

        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
    }

    override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.repeatTextInteractionWillPerform(button: button)
        guard modeCoordinator.currentMode == .hangeul else { return }

        if button is DeleteButton {
            performInitialRepeatDeleteTextInteraction(for: button)
            return
        }

        super.performTextInteraction(for: button)
        if hangeulAdapter.hasRepeatableInput || button is SpaceButton {
            button.playFeedback()
        }
    }

    override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)

        if modeCoordinator.currentMode == .hangeul {
            if button is DeleteButton {
                applyCompositionTransition(hangeulAdapter.finishRepeatDelete())
            }
            if !hangeulAdapter.shouldDeferUndoRedoCommit {
                commitDeferredUndoRedoGroupIfNeeded()
            }
        }
        updateShiftButtonForCurrentMode()
    }

    override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        switch modeCoordinator.currentMode {
        case .hangeul:
            if currentKeyboard == .symbol {
                hangeulAdapter.clearForExternalTextChange()
                super.insertPrimaryKeyText(from: button)
                updateHangeulSpaceButton()
                return
            }
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            applyCompositionTransition(hangeulAdapter.input(primaryKey))
        case .english:
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            insertTypedText(primaryKey)
        }
    }

    override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }

        if modeCoordinator.currentMode == .hangeul {
            applyCompositionTransition(hangeulAdapter.input(secondaryKey))
        } else {
            insertTypedText(secondaryKey)
        }
    }

    override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        switch modeCoordinator.currentMode {
        case .hangeul:
            if currentKeyboard == .symbol {
                super.repeatInsertPrimaryKeyText(from: button)
                updateHangeulSpaceButton()
                return
            }
            guard hangeulAdapter.hasRepeatableInput else {
                super.repeatTextInteractionDidPerform(button: button)
                button.isGesturing = false
                return
            }
            applyCompositionTransition(hangeulAdapter.repeatInput())
        case .english:
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            insertTypedText(primaryKey)
        }
    }

    override func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }

        let isHangeulPrimaryKeyboard = currentKeyboard == .naratgeul
            || currentKeyboard == .cheonjiin
            || currentKeyboard == .dubeolsik
        if modeCoordinator.currentMode == .hangeul,
           isHangeulPrimaryKeyboard {
            let transition = hangeulAdapter.space()
            if transition.proxyEdit == .insert(" ") {
                super.insertSpaceText()
            } else {
                applyCompositionTransition(transition)
            }
            commitUndoRedoGroupIfPossible()
            updateHangeulSpaceButton()
            return
        }

        super.insertSpaceText()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearForExternalTextChange()
            updateHangeulSpaceButton()
        }
    }

    override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }

        super.insertReturnText()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearForExternalTextChange()
            commitUndoRedoGroupIfPossible()
            updateHangeulSpaceButton()
        }
    }

    override func deleteBackwardWillPerform() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteBackwardWillPerform()
            return
        }

        if isRepeatingInput {
            super.repeatDeleteBackwardWillPerform()
            return
        }

        super.deleteBackwardWillPerform()
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    override func repeatDeleteBackwardWillPerform() {
        super.repeatDeleteBackwardWillPerform()
        guard modeCoordinator.currentMode == .hangeul,
              !isRepeatingInput else { return }
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    override func deleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        deleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.delete())
        updateHangeulSpaceButton()
    }

    override func repeatDeleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.repeatDeleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        repeatDeleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.repeatDelete())
        updateHangeulSpaceButton()
    }

    override func deleteButtonPanDeleteText(
        hasPendingRestoreText: Bool
    ) -> (character: Character, shouldRestore: Bool)? {
        guard modeCoordinator.currentMode == .hangeul else {
            return super.deleteButtonPanDeleteText(
                hasPendingRestoreText: hasPendingRestoreText
            )
        }
        if BaseKeyboardViewController.isPreview { return nil }

        if let result = hangeulAdapter.beginDeletePan() {
            applyCompositionTransition(result.transition)
            updateHangeulSpaceButton()
            return (result.character, result.shouldRestore)
        }

        guard let character = textDocumentProxy.documentContextBeforeInput?.last else { return nil }
        deleteText()
        updateHangeulSpaceButton()
        return (character, true)
    }

    override func deleteButtonPanRestoreText(_ character: Character) {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteButtonPanRestoreText(character)
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        applyCompositionTransition(hangeulAdapter.restoreDeletePan(character))
        updateHangeulSpaceButton()
    }

    override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.finishDeletePan()
        }
    }
}

// MARK: - Language Mode

private extension HangeulEnglishKeyboardViewController {
    func setupLanguageSwitchActions() {
        primaryKeyboardViews.compactMap(\.languageSwitchButton).forEach { button in
            button.addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    let newMode: HangeulEnglishLanguageMode =
                        modeCoordinator.currentMode == .hangeul ? .english : .hangeul
                    applyLanguageMode(newMode, persist: true)
                },
                for: .touchUpInside
            )
        }
    }

    func applyLanguageMode(
        _ mode: HangeulEnglishLanguageMode,
        persist: Bool,
        outgoingMode: HangeulEnglishLanguageMode? = nil
    ) {
        let previousMode = outgoingMode ?? modeCoordinator.currentMode

        stopInputInteractionsForLanguageChange()
        switch previousMode {
        case .hangeul:
            hangeulAdapter.finishForLanguageChange()
            commitDeferredUndoRedoGroupIfNeeded()
        case .english:
            englishAdapter.finishForLanguageChange()
        }

        modeCoordinator.selectModeManually(mode)
        if persist {
            keyboardSettingsManager.lastHangeulEnglishLanguageMode = mode
        }
        primaryLanguage = mode.languageIdentifier
        updateSuggestionLanguage(to: mode.languageIdentifier)

        primaryKeyboardViews.compactMap(\.languageSwitchButton).forEach {
            $0.updateLanguageMode(mode)
        }
        symbolKeyboardView.switchButton.updatePrimaryLanguageMode(mode)
        numericKeyboardView.switchButton.updatePrimaryLanguageMode(mode)

        if currentKeyboard != .symbol
            && currentKeyboard != .numeric
            && currentKeyboard != .tenKey {
            currentKeyboard = primaryKeyboardView.keyboard
        }

        clearSuggestionsForLanguageChange()
        markCurrentInputBufferAsLanguageBoundary()
        updateShiftButtonForCurrentMode()
        updateHangeulSpaceButton()
    }
}

// MARK: - Adapter Routing

private extension HangeulEnglishKeyboardViewController {
    func applyCompositionTransition(_ transition: HangeulCompositionTransition?) {
        guard let transition else { return }

        for proxyEdit in transition.proxyEdits {
            switch proxyEdit {
            case .none:
                break
            case .insert(let text):
                insertText(text)
            case .delete(let count):
                if count == 1 {
                    deleteText()
                } else {
                    replaceText(deleteCount: count, insert: "")
                }
            case .replace(let deleteCount, let insertText):
                replaceText(deleteCount: deleteCount, insert: insertText)
            }
        }

        updateHangeulSpaceButton()
    }

    func updateShiftButtonForCurrentMode() {
        switch modeCoordinator.currentMode {
        case .hangeul:
            updateHangeulShiftButton()
        case .english:
            updateEnglishShiftButton()
        }
    }

    func updateHangeulSpaceButton() {
        hangeulAdapter.updateSpaceButtonImage()
    }

    func updateHangeulShiftButton() {
        guard !buttonStateController.isShiftButtonPressed else { return }
        hangeulAdapter.resetShiftState()
    }

    func updateEnglishShiftButton() {
        let isShiftButtonPressed = buttonStateController.isShiftButtonPressed
        englishAdapter.updateShiftAfterInput(
            isShiftButtonPressed: isShiftButtonPressed
        )
        englishAdapter.updateAutocapitalization(
            type: textDocumentProxy.autocapitalizationType ?? .none,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput,
            isEnabled: keyboardSettingsManager.isAutoCapitalizationEnabled,
            isShiftButtonPressed: isShiftButtonPressed
        )
    }
}

// MARK: - Extension UI

private extension HangeulEnglishKeyboardViewController {
    func setupRequestFullAccessOverlayView() {
        view.addSubview(requestFullAccessOverlayView)

        requestFullAccessOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            requestFullAccessOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            requestFullAccessOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            requestFullAccessOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            requestFullAccessOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        requestFullAccessOverlayView.closeButton.addAction(
            UIAction { [weak self] _ in
                self?.keyboardExtensionLocalStateStore.isClosed = true
                self?.requestFullAccessOverlayView.isHidden = true
            },
            for: .touchUpInside
        )
        requestFullAccessOverlayView.goToSettingsButton.addAction(
            UIAction { [weak self] _ in
                let urlString = "sykeyboard://"
                guard let url = URL(string: urlString) else {
                    assertionFailure("올바르지 않은 URL 형식입니다.")
                    Crashlytics.crashlytics().record(
                        error: KeyboardError.invalidSettingsURL(url: urlString)
                    )
                    return
                }
                self?.openURL(url)
            },
            for: .touchUpInside
        )
    }

    func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Crashlytics.crashlytics().setUserID(
            UIDevice.current.identifierForVendor?.uuidString
        )
    }

    func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }
}
