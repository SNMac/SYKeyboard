//
//  HangeulEnglishKeyboardCoreViewController.swift
//  HangeulEnglishKeyboardCore
//
//  Created by Claude on 10/9/26.
//

import UIKit

import EnglishKeyboardCore
import HangeulKeyboardCore
import SYKeyboardCore

/// 한글과 영어 입력/UI를 함께 제공하는 통합 키보드 컨트롤러
///
/// Firebase 설정과 진단 기록은 extension의 `HangeulEnglishKeyboardViewController`가 맡는다.
/// Core는 Firebase를 모르므로 `languageModeDecisionDidResolve(requiresLatinInput:resolved:)` 훅만 제공한다
open class HangeulEnglishKeyboardCoreViewController: BaseKeyboardViewController {

    // MARK: - Properties

    private let hangeulAdapter = HangeulKeyboardInputAdapter(
        selectedKeyboard: UserDefaultsManager.shared.selectedHangeulKeyboard,
        showsLanguageSwitchButton: true
    )
    private let englishAdapter = EnglishKeyboardInputAdapter(
        showsLanguageSwitchButton: true
    )
    /// 키보드가 뜰 때 결정한 시작 언어
    private let initialLanguageMode: HangeulEnglishLanguageMode
    private lazy var modeCoordinator = HangeulEnglishKeyboardModeCoordinator(
        initialMode: initialLanguageMode
    )

    open override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        return hangeulAdapter.primaryKeyboardViews + [englishAdapter.primaryKeyboardView]
    }

    open override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        switch modeCoordinator.currentMode {
        case .hangeul:
            return hangeulAdapter.primaryKeyboardView
        case .english:
            return englishAdapter.primaryKeyboardView
        }
    }

    open override var hangeulSwitchGestureKeyboardView: SwitchGestureHandling {
        return hangeulAdapter.primaryKeyboardView
    }

    open override var englishSwitchGestureKeyboardView: SwitchGestureHandling {
        return englishAdapter.primaryKeyboardView
    }

    open override var shouldDeferUndoRedoCommit: Bool {
        return modeCoordinator.currentMode == .hangeul
            && hangeulAdapter.shouldDeferUndoRedoCommit
    }

    open override var treatsDefaultSmartQuotesAsEnabled: Bool {
        return modeCoordinator.currentMode == .hangeul
    }

    open override var smartQuoteRule: KeyboardSmartQuoteRule {
        return modeCoordinator.currentMode == .hangeul ? .koreanSystem : .englishSystem
    }

    // MARK: - Initializer

    public init() {
        // 저장된 언어가 없으면 OS 언어 설정을 따른다.
        // 이 시점에는 textDocumentProxy에 접근하지 않는다(수명주기 크래시 경로)
        let mode = KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: Self.storedLanguageMode(),
            preferredLanguages: Locale.preferredLanguages
        )
        initialLanguageMode = mode
        SwitchButton.previewPrimaryLanguage = mode.languageIdentifier
        super.init(
            language: mode.languageIdentifier,
            nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage
        )
        primaryLanguage = mode.languageIdentifier
    }

    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        setupLanguageSwitchActions()
        applyLanguageMode(modeCoordinator.currentMode, persist: false)
    }

    // MARK: - Diagnostics Hook

    /// 시작 언어 판정 근거를 남길 자리. Core는 Firebase를 모르므로 extension이 구현한다.
    /// `inputTraitsDidChange()`에서 `applyLanguageMode` **앞**에 불린다
    open func languageModeDecisionDidResolve(
        requiresLatinInput: Bool,
        resolved: HangeulEnglishLanguageMode
    ) {}

    // MARK: - Override Methods

    /// 이 훅은 `textDidChange`에서 `updateKeyboardType()` **뒤에** 불린다.
    /// 그래서 `updateKeyboardType()`이 아직 바뀌기 전 언어로 `currentKeyboard`를 한 번 정하고,
    /// 아래 `applyLanguageMode`가 새 언어로 다시 정한다. 두 번째가 항상 정정해 주는 근거는
    /// `KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard`가 문자 자판 네 종류 모두에
    /// `true`를 돌려준다는 것이고, 그 성질은 `testAutomaticSwitchUpdatesPrimaryKeyboard`가 고정한다
    open override func inputTraitsDidChange() {
        let previousMode = modeCoordinator.currentMode
        let requiresLatinInput = KeyboardLanguageModePolicy.requiresLatinInput(
            keyboardType: textDocument.keyboardType,
            textContentType: textDocument.textContentType
        )
        let mode = modeCoordinator.modeForInputTraitsChange(
            requiresLatinInput: requiresLatinInput,
            lastMode: Self.storedLanguageMode(),
            preferredLanguages: Locale.preferredLanguages
        )
        languageModeDecisionDidResolve(requiresLatinInput: requiresLatinInput, resolved: mode)

        // 필드가 강제한 영어는 사용자의 선택이 아니므로 마지막 언어로 저장하지 않는다
        applyLanguageMode(
            mode,
            persist: !requiresLatinInput,
            outgoingMode: previousMode
        )
    }

    open override func textWillChange(_ textInput: (any UITextInput)?) {
        // 영어 모드의 shift 자동 대문자 판정도 Base 콜백과 같은 범위에서 읽는다
        textDocument.withReadCaching {
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
    }

    open override func undoRedoEditDidApply() {
        super.undoRedoEditDidApply()
        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
        updateShiftButtonForCurrentMode()
    }

    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearLetterInputState()
        }
        updateShiftButtonForCurrentMode()
    }

    open override func updateKeyboardType() {
        guard textDocument.keyboardType != oldKeyboardType else { return }

        symbolKeyboardView.currentSymbolKeyboardMode = SymbolKeyboardMode(
            keyboardType: textDocument.keyboardType
        )
        hangeulAdapter.updateLayout(for: textDocument.keyboardType)
        englishAdapter.updateLayout(for: textDocument.keyboardType)

        switch textDocument.keyboardType {
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

    open override func textInteractionWillPerform(button: TextInteractable) {
        if modeCoordinator.currentMode == .hangeul {
            if button is DeleteButton {
                hangeulAdapter.beginDeleteTouchDown()
            } else {
                hangeulAdapter.cancelDeleteTouchDown()
            }
        }
        super.textInteractionWillPerform(button: button)
    }

    open override func textInteractionDidPerform(button: TextInteractable) {
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

    open override func suggestionDidApply() {
        super.suggestionDidApply()
        guard modeCoordinator.currentMode == .hangeul else { return }

        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
    }

    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.repeatTextInteractionWillPerform(button: button)
        guard modeCoordinator.currentMode == .hangeul else { return }

        if button is DeleteButton {
            performInitialRepeatDeleteTextInteraction(for: button)
        }
    }

    open override func performInitialRepeatTextInteraction(for button: TextInteractable) {
        guard modeCoordinator.currentMode == .hangeul else {
            super.performInitialRepeatTextInteraction(for: button)
            return
        }

        performTextInteraction(for: button)
        if hangeulAdapter.hasRepeatableInput || button is SpaceButton {
            button.playFeedback()
        }
    }

    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
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

    open override func insertPrimaryKeyText(from button: TextInteractable) {
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

    open override func insertSecondaryKeyText(from button: TextInteractable) {
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

    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
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

    open override func insertSpaceText() {
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

    open override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }

        super.insertReturnText()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearForExternalTextChange()
            commitUndoRedoGroupIfPossible()
            updateHangeulSpaceButton()
        }
    }

    open override func deleteBackwardWillPerform() {
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

    open override func repeatDeleteBackwardWillPerform() {
        super.repeatDeleteBackwardWillPerform()
        guard modeCoordinator.currentMode == .hangeul,
              !isRepeatingInput else { return }
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    open override func deleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        deleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.delete())
        updateHangeulSpaceButton()
    }

    open override func repeatDeleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.repeatDeleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        repeatDeleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.repeatDelete())
        updateHangeulSpaceButton()
    }

    open override func deleteButtonPanDeleteText(
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

        guard let character = deleteButtonPanPreviousCharacter else { return nil }
        deleteText()
        updateHangeulSpaceButton()
        return (character, true)
    }

    open override func deleteButtonPanRestoreText(_ character: Character) {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteButtonPanRestoreText(character)
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        applyCompositionTransition(hangeulAdapter.restoreDeletePan(character))
        updateHangeulSpaceButton()
    }

    open override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.finishDeletePan()
        }
    }
}

// MARK: - Language Mode

private extension HangeulEnglishKeyboardCoreViewController {
    var languageSwitchButtons: [LanguageSwitchButton] {
        primaryKeyboardViews.compactMap(\.languageSwitchButton)
        + [
            symbolKeyboardView.languageSwitchButton,
            numericKeyboardView.languageSwitchButton
        ].compactMap { $0 }
    }

    /// 저장된 마지막 언어. 한 번도 저장된 적이 없으면 `nil`
    static func storedLanguageMode() -> HangeulEnglishLanguageMode? {
        let manager = UserDefaultsManager.shared
        guard manager.hasLastHangeulEnglishLanguageMode else { return nil }

        return manager.lastHangeulEnglishLanguageMode
    }

    func setupLanguageSwitchActions() {
        languageSwitchButtons.forEach { button in
            button.addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    let newMode: HangeulEnglishLanguageMode =
                        modeCoordinator.currentMode == .hangeul ? .english : .hangeul
                    applyLanguageMode(newMode, persist: true, isManualSwitch: true)
                },
                for: .touchUpInside
            )
        }
    }

    func applyLanguageMode(
        _ mode: HangeulEnglishLanguageMode,
        persist: Bool,
        outgoingMode: HangeulEnglishLanguageMode? = nil,
        isManualSwitch: Bool = false
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

        languageSwitchButtons.forEach {
            $0.updateLanguageMode(mode)
        }
        symbolKeyboardView.switchButton.updatePrimaryLanguageMode(mode)
        numericKeyboardView.switchButton.updatePrimaryLanguageMode(mode)

        if KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
            isManualSwitch: isManualSwitch,
            currentKeyboard: currentKeyboard
        ) {
            currentKeyboard = primaryKeyboardView.keyboard
        }

        updateShiftButtonForCurrentMode()
        updateHangeulSpaceButton()
    }
}

// MARK: - Adapter Routing

private extension HangeulEnglishKeyboardCoreViewController {
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
        englishAdapter.updateAutocapitalization(
            type: textDocument.autocapitalizationType ?? .none,
            documentContextBeforeInput: textDocument.documentContextBeforeInput,
            isEnabled: keyboardSettingsManager.isAutoCapitalizationEnabled,
            isShiftButtonPressed: isShiftButtonPressed
        )
    }
}
