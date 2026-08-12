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
    
    private let inputAdapter: HangeulKeyboardInputAdapter

    // MARK: - UI Components

    open override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        return inputAdapter.primaryKeyboardViews
    }

    open override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        return inputAdapter.primaryKeyboardView
    }

    open override var shouldDeferUndoRedoCommit: Bool {
        return inputAdapter.shouldDeferUndoRedoCommit
    }
    
    // MARK: - Initializer
    
    public init() {
        inputAdapter = HangeulKeyboardInputAdapter(
            selectedKeyboard: UserDefaultsManager.shared.selectedHangeulKeyboard
        )
        SwitchButton.previewPrimaryLanguage = "ko-KR"
        super.init(language: "ko-KR")
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        inputAdapter.clearForExternalTextChange()
        updateSpaceButtonImage()
        updateShiftButton()
    }

    open override func undoRedoEditDidApply() {
        super.undoRedoEditDidApply()
        inputAdapter.clearForExternalTextChange()
        updateSpaceButtonImage()
        updateShiftButton()
    }
    
    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        inputAdapter.clearLetterInputState()
        updateShiftButton()
    }
    
    open override func updateKeyboardType() {
        guard textDocumentProxy.keyboardType != oldKeyboardType else { return }
        let symbolKeyboardMode = SymbolKeyboardMode(keyboardType: textDocumentProxy.keyboardType)
        symbolKeyboardView.currentSymbolKeyboardMode = symbolKeyboardMode
        inputAdapter.updateLayout(for: textDocumentProxy.keyboardType)
        
        switch textDocumentProxy.keyboardType {
        case .default, nil:
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapable:
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            currentKeyboard = .symbol
        case .URL:
            currentKeyboard = primaryKeyboardView.keyboard
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            currentKeyboard = primaryKeyboardView.keyboard
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            currentKeyboard = primaryKeyboardView.keyboard
        case .webSearch:
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }

    open override func textInteractionWillPerform(button: TextInteractable) {
        if button is DeleteButton {
            inputAdapter.beginDeleteTouchDown()
        } else {
            inputAdapter.cancelDeleteTouchDown()
        }
        super.textInteractionWillPerform(button: button)
    }
    
    open override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)
        if button is DeleteButton {
            inputAdapter.endDeleteTouchDown()
        } else {
            inputAdapter.cancelDeleteTouchDown()
        }
        inputAdapter.recordTextInteraction()
        if !inputAdapter.shouldDeferUndoRedoCommit {
            commitDeferredUndoRedoGroupIfNeeded()
        }
        if !isRepeatingInput { updateShiftButton() }
    }
    
    open override func suggestionDidApply() {
        super.suggestionDidApply()
        inputAdapter.clearForExternalTextChange()
        updateSpaceButtonImage()
    }
    
    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.repeatTextInteractionWillPerform(button: button)
        if button is DeleteButton {
            performInitialRepeatDeleteTextInteraction(for: button)
            return
        }

        super.performTextInteraction(for: button)
        if inputAdapter.hasRepeatableInput || button is SpaceButton {
            button.playFeedback()
        }
    }
    
    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)
        
        if button is DeleteButton {
            let transition = inputAdapter.finishRepeatDelete()
            if transition.proxyEdit != .none {
                applyCompositionTransition(transition)
            }
        }
        
        if !inputAdapter.shouldDeferUndoRedoCommit {
            commitDeferredUndoRedoGroupIfNeeded()
        }
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        if currentKeyboard == .symbol {
            inputAdapter.clearForExternalTextChange()
            super.insertPrimaryKeyText(from: button)
            updateSpaceButtonImage()
            return
        }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("primaryKeyList 배열이 비어있습니다.") }
        
        applyCompositionTransition(inputAdapter.input(primaryKey))
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        
        applyCompositionTransition(inputAdapter.input(secondaryKey))
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        if currentKeyboard == .symbol {
            super.repeatInsertPrimaryKeyText(from: button)
            updateSpaceButtonImage()
            return
        }
        
        guard inputAdapter.hasRepeatableInput else {
            super.repeatTextInteractionDidPerform(button: button)
            button.isGesturing = false
            return
        }
        
        applyCompositionTransition(inputAdapter.repeatInput())
    }
    
    open override func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }
        
        if currentKeyboard == .naratgeul
            || currentKeyboard == .cheonjiin
            || currentKeyboard == .dubeolsik {
            let transition = inputAdapter.space()
            if transition.proxyEdit == .insert(" ") {
                super.insertSpaceText()
            } else {
                applyCompositionTransition(transition)
            }
        } else {
            super.insertSpaceText()
            inputAdapter.clearForExternalTextChange()
        }
        
        commitUndoRedoGroupIfPossible()
        updateSpaceButtonImage()
    }
    
    open override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }
        
        super.insertReturnText()
        
        inputAdapter.clearForExternalTextChange()
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

        applyCompositionTransition(inputAdapter.delete())
        updateSpaceButtonImage()
    }

    open override func deleteButtonPanDeleteText(hasPendingRestoreText _: Bool) -> (character: Character, shouldRestore: Bool)? {
        if BaseKeyboardViewController.isPreview { return nil }

        let result = inputAdapter.beginDeletePan()
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

        applyCompositionTransition(inputAdapter.restoreDeletePan(character))
        updateSpaceButtonImage()
    }

    open override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        inputAdapter.finishDeletePan()
    }

    open override func repeatDeleteBackward() {
        if BaseKeyboardViewController.isPreview { return }
        
        repeatDeleteBackwardWillPerform()
        
        applyCompositionTransition(inputAdapter.repeatDelete())
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

    func updateSpaceButtonImage() {
        inputAdapter.updateSpaceButtonImage()
    }
    
    func updateShiftButton() {
        guard !buttonStateController.isShiftButtonPressed else { return }
        inputAdapter.resetShiftState()
    }
}
