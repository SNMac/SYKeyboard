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
open class HangeulKeyboardCoreViewController: BaseKeyboardViewController {
    
    // MARK: - Properties
    
    /// 조합이 완료되어 더 이상 변경되지 않는 문자열.
    /// `textDocumentProxy`에 이미 확정 입력되어 있으므로 delete/insert 대상이 아닙니다.
    private var committedBuffer: String = ""
    
    /// 현재 오토마타가 조합 중인 문자열 (최대 1~2글자).
    private var composingBuffer: String = ""
    
    /// 마지막으로 입력한 문자
    private var lastInputText: String?
    /// 현재 반복 입력 동작 중인지 확인하는 플래그
    private var isRepeatingInput: Bool = false
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
    
    // MARK: - Initializer
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        SwitchButton.previewPrimaryLanguage = "ko-KR"
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textWillChange(_ textInput: (any UITextInput)?) {
        super.textWillChange(textInput)
        clearAllBuffers()
        lastInputText = nil
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
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapable:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = .symbol
        case .URL:
            hangeulKeyboardView.currentHangeulKeyboardMode = .URL
            symbolKeyboardView.currentSymbolKeyboardMode = .URL
            currentKeyboard = primaryKeyboardView.keyboard
        case .numberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .phonePad, .namePhonePad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .emailAddress:
            hangeulKeyboardView.currentHangeulKeyboardMode = .emailAddress
            symbolKeyboardView.currentSymbolKeyboardMode = .emailAddress
            currentKeyboard = primaryKeyboardView.keyboard
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        case .twitter:
            hangeulKeyboardView.currentHangeulKeyboardMode = .twitter
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        case .webSearch:
            hangeulKeyboardView.currentHangeulKeyboardMode = .webSearch
            symbolKeyboardView.currentSymbolKeyboardMode = .webSearch
            currentKeyboard = primaryKeyboardView.keyboard
        case .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        @unknown default:
            assertionFailure("구현이 필요한 case 입니다.")
            hangeulKeyboardView.currentHangeulKeyboardMode = .default
            symbolKeyboardView.currentSymbolKeyboardMode = .default
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }
    
    open override func textInteractionDidPerform(button: any TextInteractable) {
        super.textInteractionDidPerform(button: button)
        is글자Input = true
        if !isRepeatingInput { updateShiftButton() }
    }
    
    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        isRepeatingInput = true
        super.repeatTextInteractionWillPerform(button: button)
        super.performTextInteraction(for: button)
        if lastInputText != nil || button is DeleteButton || button is SpaceButton {
            button.playFeedback()
        }
    }
    
    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)
        isRepeatingInput = false
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("primaryKeyList 배열이 비어있습니다.") }
        
        applyCompositionResult(processor.input(글자Input: primaryKey, composing: composingBuffer))
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        
        applyCompositionResult(processor.input(글자Input: secondaryKey, composing: composingBuffer))
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if isPreview { return }
        
        guard let lastInputText else {
            super.repeatTextInteractionDidPerform(button: button)
            button.isGesturing = false
            return
        }
        
        textDocumentProxy.insertText(lastInputText)
        // 반복 입력은 조합과 무관하므로 committed에 직접 추가
        committedBuffer.append(lastInputText)
    }
    
    open override func insertSpaceText() {
        if isPreview { return }
        
        if currentKeyboard == .naratgeul ||
            currentKeyboard == .cheonjiin ||
            currentKeyboard == .dubeolsik {
            let result = processor.inputSpace(composing: composingBuffer)
            switch result {
            case .insertSpace:
                super.insertSpaceText()
                commitComposingBuffer()
                committedBuffer.append(" ")
                lastInputText = nil
                
            case .commitCombination:
                commitComposingBuffer()
                lastInputText = nil
            }
        } else {
            super.insertSpaceText()
            commitComposingBuffer()
            committedBuffer.append(" ")
            lastInputText = nil
        }
        
        updateSpaceButtonImage()
    }
    
    open override func insertReturnText() {
        if isPreview { return }
        
        super.insertReturnText()
        commitComposingBuffer()
        processor.reset한글조합()
        lastInputText = nil
        updateSpaceButtonImage()
    }
    
    open override func deleteBackward() {
        if isPreview { return }
        
        deleteBackwardWillPerform()
        
        if !composingBuffer.isEmpty {
            // 조합 중인 글자가 있으면 composingBuffer에서만 삭제 처리
            for _ in 0..<composingBuffer.count { textDocumentProxy.deleteBackward() }
            let remaining = processor.delete(composing: composingBuffer)
            if !remaining.isEmpty {
                textDocumentProxy.insertText(remaining)
            }
            composingBuffer = remaining
            
            if composingBuffer.isEmpty {
                processor.reset한글조합()
            }
        } else if !committedBuffer.isEmpty {
            // 조합 중인 글자가 없고 확정된 버퍼가 있으면 마지막 확정 글자 삭제
            textDocumentProxy.deleteBackward()
            committedBuffer.removeLast()
            processor.reset한글조합()
        } else {
            // 버퍼가 모두 비어있으면 일반 삭제
            textDocumentProxy.deleteBackward()
            processor.reset한글조합()
        }
        updateSpaceButtonImage()
        lastInputText = nil
    }
    
    open override func repeatDeleteBackward() {
        if isPreview { return }
        
        repeatDeleteBackwardWillPerform()
        
        textDocumentProxy.deleteBackward()
        if !composingBuffer.isEmpty {
            composingBuffer.removeLast()
            
            if composingBuffer.isEmpty {
                processor.reset한글조합()
            }
        } else if !committedBuffer.isEmpty {
            committedBuffer.removeLast()
            processor.reset한글조합()
        } else {
            processor.reset한글조합()
        }
        updateSpaceButtonImage()
        lastInputText = nil
    }
}

// MARK: - Private Methods

private extension HangeulKeyboardCoreViewController {
    
    /// `CompositionResult`를 `textDocumentProxy`에 반영합니다.
    func applyCompositionResult(_ result: CompositionResult) {
        // 1. 기존 composingBuffer를 화면에서 제거 (최대 1~2글자)
        for _ in 0..<composingBuffer.count { textDocumentProxy.deleteBackward() }
        
        // 2. 확정된 글자 + 새 조합 글자를 한 번에 입력
        let textToInsert = result.committed + result.composing
        if !textToInsert.isEmpty {
            textDocumentProxy.insertText(textToInsert)
        }
        
        // 3. 버퍼 업데이트
        committedBuffer.append(result.committed)
        composingBuffer = result.composing
        
        // 4. 반복 입력 정보 저장
        lastInputText = result.input글자
        updateSpaceButtonImage()
    }
    
    /// `composingBuffer`를 `committedBuffer`로 이동시킵니다 (조합 확정).
    func commitComposingBuffer() {
        committedBuffer.append(composingBuffer)
        composingBuffer.removeAll()
    }
    
    /// 모든 버퍼를 초기화합니다.
    func clearAllBuffers() {
        committedBuffer.removeAll()
        composingBuffer.removeAll()
    }
    
    func updateSpaceButtonImage() {
        if processor.is한글조합OnGoing {
            primaryKeyboardView.updateSpaceButtonImage(systemName: "arrow.right")
        } else {
            primaryKeyboardView.updateSpaceButtonImage(systemName: "space")
        }
    }
    
    /// Shift 버튼을 상황에 맞게 업데이트하는 메서드
    func updateShiftButton() {
        guard !buttonStateController.isShiftButtonPressed else { return }
        primaryKeyboardView.updateShiftButton(isShifted: false)
        is글자Input = false
    }
}
