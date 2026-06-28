//
//  HangeulKeyboardCoreViewController.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 7/29/24.
//

import UIKit

import SYKeyboardCore

/// 한글 키보드 입력/UI 컨트롤러
///
/// `committedBuffer`와 `composingBuffer`를 분리하여
/// `textDocumentProxy`에 대한 delete/insert를 `composingBuffer`(최대 1~2글자)로 한정합니다.
/// 이를 통해 버퍼 크기에 무관하게 항상 O(1) 성능을 보장합니다.
///
/// 한글 종성 복원 로직은 모두 프로세서(`HangeulProcessable`) 내부에서 처리하며,
/// VC는 반환된 결과(`CompositionResult`/`DeleteResult`)를 적용만 합니다.
///
/// `textDocumentProxy` 조작은 `BaseKeyboardViewController`의 래핑 메서드
/// (`insertText`, `deleteText`, `replaceText`)를 통해 수행하여
/// `inputBuffer`가 항상 자동 동기화됩니다.
open class HangeulKeyboardCoreViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    /// 한글 조합 상태 전이.
    private var compositionState = HangeulCompositionState()
    /// 글자가 입력되었는지 확인하는 플래그
    private var is글자Input: Bool = false
    /// 한글 오토마타
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    /// 나랏글 입력기
    private lazy var naratgeulProcessor: HangeulProcessable = NaratgeulProcessor(automata: automata)
    /// 천지인 입력기
    private lazy var cheonjiinProcessor: HangeulProcessable = CheonjiinProcessor(automata: automata)
    /// 두벌식 입력기
    private lazy var dubeolsikProcessor: HangeulProcessable = DubeolsikProcessor(automata: automata)
    
    /// 한글 키보드 입력기
    private var processor: HangeulProcessable {
        switch UserDefaultsManager.shared.selectedHangeulKeyboard {
        case .naratgeul:
            return naratgeulProcessor
        case .cheonjiin:
            return cheonjiinProcessor
        case .dubeolsik:
            return dubeolsikProcessor
        }
    }

    private var committedBuffer: String { compositionState.committedBuffer }

    private var composingBuffer: String { compositionState.composingBuffer }

    private var lastInputText: String? { compositionState.lastInputText }
    
    // MARK: - UI Components
    
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView: HangeulKeyboardLayoutProvider = NaratgeulKeyboardView()
    /// 천지인 키보드
    private lazy var cheonjiinKeyboardView: HangeulKeyboardLayoutProvider = CheonjiinKeyboardView()
    /// 두벌식 키보드
    private lazy var dubeolsikKeyboardView: HangeulKeyboardLayoutProvider = DubeolsikKeyboardView(
        getIsShiftedLetterInput: { [weak self] in return self?.is글자Input ?? false },
        setIsShiftedLetterInput: { [weak self] is글자Input in self?.is글자Input = is글자Input }
    )
    
    /// 사용자가 선택한 한글 키보드
    private var hangeulKeyboardView: HangeulKeyboardLayoutProvider {
        switch UserDefaultsManager.shared.selectedHangeulKeyboard {
        case .naratgeul:
            return naratgeulKeyboardView
        case .cheonjiin:
            return cheonjiinKeyboardView
        case .dubeolsik:
            return dubeolsikKeyboardView
        }
    }
    
    open override var primaryKeyboardView: PrimaryKeyboardRepresentable { hangeulKeyboardView }

    open override var shouldDeferUndoRedoCommit: Bool {
        return !composingBuffer.isEmpty
    }
    
    // MARK: - Initializer
    
    public init() {
        SwitchButton.previewPrimaryLanguage = "ko-KR"
        super.init(language: "ko-KR")
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        clearAllBuffers()
        processor.reset한글조합()
        updateSpaceButtonImage()
        updateShiftButton()
    }

    open override func undoRedoEditDidApply() {
        super.undoRedoEditDidApply()
        clearAllBuffers()
        processor.reset한글조합()
        updateSpaceButtonImage()
        updateShiftButton()
    }
    
    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        is글자Input = false
        updateShiftButton()
    }
    
    open override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapable:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .URL
            currentKeyboard = primaryKeyboardView.keyboard
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .emailAddress
            currentKeyboard = primaryKeyboardView.keyboard
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
            currentKeyboard = primaryKeyboardView.keyboard
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .webSearch
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }

    open override func textInteractionWillPerform(button: TextInteractable) {
        if button is DeleteButton {
            compositionState.beginDeleteButtonTouchDown()
        } else {
            compositionState.cancelDeleteButtonTouchDown()
        }
        super.textInteractionWillPerform(button: button)
    }
    
    open override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)
        if button is DeleteButton {
            compositionState.endDeleteButtonTouchDown()
        } else {
            compositionState.cancelDeleteButtonTouchDown()
        }
        is글자Input = true
        if composingBuffer.isEmpty {
            commitDeferredUndoRedoGroupIfNeeded()
        }
        if !isRepeatingInput { updateShiftButton() }
    }
    
    open override func suggestionDidApply() {
        super.suggestionDidApply()
        clearAllBuffers()
        processor.reset한글조합()
        updateSpaceButtonImage()
    }
    
    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.repeatTextInteractionWillPerform(button: button)
        super.performTextInteraction(for: button)
        if lastInputText != nil || button is DeleteButton || button is SpaceButton {
            button.playFeedback()
        }
    }
    
    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)
        
        if button is DeleteButton {
            applyCompositionTransition(compositionState.finishRepeatDelete(using: processor))
        }
        
        if composingBuffer.isEmpty {
            commitDeferredUndoRedoGroupIfNeeded()
        }
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("primaryKeyList 배열이 비어있습니다.") }
        
        applyCompositionTransition(compositionState.input(primaryKey, using: processor))
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        
        applyCompositionTransition(compositionState.input(secondaryKey, using: processor))
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard lastInputText != nil else {
            super.repeatTextInteractionDidPerform(button: button)
            button.isGesturing = false
            return
        }
        
        applyCompositionTransition(compositionState.repeatInsert(using: processor))
    }
    
    open override func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }
        
        if currentKeyboard == .naratgeul
            || currentKeyboard == .cheonjiin
            || currentKeyboard == .dubeolsik {
            let transition = compositionState.space(using: processor)
            if transition.proxyEdit == .insert(" ") {
                super.insertSpaceText()
            } else {
                applyCompositionTransition(transition)
            }
        } else {
            super.insertSpaceText()
            clearAllBuffers()
            processor.reset한글조합()
        }
        
        commitUndoRedoGroupIfPossible()
        updateSpaceButtonImage()
    }
    
    open override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }
        
        super.insertReturnText()
        
        clearAllBuffers()
        processor.reset한글조합()
        commitUndoRedoGroupIfPossible()
        updateSpaceButtonImage()
    }

    open override func deleteBackwardWillPerform() {
        if isRepeatingInput {
            super.repeatDeleteBackwardWillPerform()
            return
        }

        super.deleteBackwardWillPerform()
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    open override func repeatDeleteBackwardWillPerform() {
        super.repeatDeleteBackwardWillPerform()
        guard !isRepeatingInput else { return }
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }
    
    open override func deleteBackward() {
        if BaseKeyboardViewController.isPreview { return }

        deleteBackwardWillPerform()

        applyCompositionTransition(compositionState.delete(using: processor))
        updateSpaceButtonImage()
    }

    open override func deleteButtonPanDeleteText(hasPendingRestoreText _: Bool) -> (character: Character, shouldRestore: Bool)? {
        if BaseKeyboardViewController.isPreview { return nil }

        let result = compositionState.deleteButtonPanDelete(using: processor)
        if let result {
            applyCompositionTransition(result.transition)
            updateSpaceButtonImage()
            return (result.character, result.shouldRestore)
        }

        guard let deletedCharacter = textDocumentProxy.documentContextBeforeInput?.last else { return nil }
        deleteText()
        updateSpaceButtonImage()
        return (deletedCharacter, true)
    }

    open override func deleteButtonPanRestoreText(_ character: Character) {
        if BaseKeyboardViewController.isPreview { return }

        applyCompositionTransition(compositionState.deleteButtonPanRestore(character, using: processor))
        updateSpaceButtonImage()
    }

    open override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        compositionState.finishDeleteButtonPan()
    }

    open override func repeatDeleteBackward() {
        if BaseKeyboardViewController.isPreview { return }
        
        repeatDeleteBackwardWillPerform()
        
        applyCompositionTransition(compositionState.repeatDelete(using: processor))
        updateSpaceButtonImage()
    }
}

// MARK: - Private Methods

private extension HangeulKeyboardCoreViewController {

    /// 상태 전이가 요청한 proxy 편집만 수행합니다.
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

        updateSpaceButtonImage()
    }

    /// 모든 버퍼를 초기화합니다.
    func clearAllBuffers() {
        compositionState.clearAllBuffers()
    }
    
    func updateSpaceButtonImage() {
        if processor.is한글조합OnGoing {
            primaryKeyboardView.updateSpaceButtonImage(systemName: "arrow.right")
        } else {
            primaryKeyboardView.updateSpaceButtonImage(systemName: "space")
        }
    }
    
    func updateShiftButton() {
        guard !buttonStateController.isShiftButtonPressed else { return }
        primaryKeyboardView.updateShiftButton(to: false)
        is글자Input = false
    }
}
