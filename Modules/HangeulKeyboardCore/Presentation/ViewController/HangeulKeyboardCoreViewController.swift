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
    
    /// 조합이 완료되어 더 이상 변경되지 않는 문자열.
    /// `textDocumentProxy`에 이미 확정 입력되어 있으므로 delete/insert 대상이 아닙니다.
    private var committedBuffer: String = ""
    
    /// 현재 오토마타가 조합 중인 문자열 (최대 1~2글자).
    /// 입력 시마다 이 부분만 delete → 재입력하므로 항상 O(1)입니다.
    private var composingBuffer: String = ""
    
    /// 마지막으로 입력한 문자
    private var lastInputText: String?
    /// 글자가 입력되었는지 확인하는 플래그
    private var is글자Input: Bool = false
    /// 스페이스(확정)로 보호된 `committedBuffer` 내의 글자 수
    private var protectedCommittedCount: Int = 0
    
    /// 끌어온 글자가 보호 상태였는지 추적하는 플래그.
    ///
    /// `pullFromCommittedIfNeeded`에서 보호된 글자를 끌어오면 `true`로 설정됩니다.
    /// 이후 `applyCompositionResult`에서 해당 글자가 committed로 돌아갈 때
    /// `protectedCommittedCount`를 복원하여 보호 상태를 유지합니다.
    private var isPulledFromProtected: Bool = false
    
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
    
    public init() {
        SwitchButton.previewPrimaryLanguage = "ko-KR"
        super.init(language: "ko-KR")
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override Methods
    
    open override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
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
    
    open override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)
        is글자Input = true
        if !isRepeatingInput { updateShiftButton() }
    }
    
    open override func suggestionDidApply() {
        super.suggestionDidApply()
        clearAllBuffers()
        processor.reset한글조합()
        lastInputText = nil
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
        
        // 반복 삭제 후 composing이 비고 committed에 한글이 있으면 끌어오기
        if button is DeleteButton && composingBuffer.isEmpty && !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            let lastStr = String(lastCommitted)
            if lastCommitted.isHangeul {
                
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                // 끌어오기: 글자 자체는 변경되지 않으므로 replaceText 사용
                replaceText(deleteCount: 1, insert: lastStr)
                composingBuffer = lastStr
                
                if !isProtected {
                    processor.start한글조합()
                }
            }
        }
        
        updateShiftButton()
    }
    
    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let primaryKey = button.type.primaryKeyList.first else { fatalError("primaryKeyList 배열이 비어있습니다.") }
        
        applyCompositionResult(
            processor.inputWithRestore종성(
                글자Input: primaryKey,
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )
        )
    }
    
    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }
        
        applyCompositionResult(
            processor.inputWithRestore종성(
                글자Input: secondaryKey,
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )
        )
    }
    
    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        
        guard let lastInputText else {
            super.repeatTextInteractionDidPerform(button: button)
            button.isGesturing = false
            return
        }
        
        if !composingBuffer.isEmpty {
            commitComposingBuffer()
        }
        
        insertText(lastInputText)
        composingBuffer = lastInputText
    }
    
    open override func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }
        
        if currentKeyboard == .naratgeul
            || currentKeyboard == .cheonjiin
            || currentKeyboard == .dubeolsik {
            let result = processor.inputSpace(composing: composingBuffer)
            switch result {
            case .insertSpace:
                super.insertSpaceText()
                clearAllBuffers()
                processor.reset한글조합()
                lastInputText = nil
                
            case .commitCombination:
                commitComposingBuffer()
                protectedCommittedCount = committedBuffer.count
                lastInputText = nil
            }
        } else {
            super.insertSpaceText()
            clearAllBuffers()
            processor.reset한글조합()
            lastInputText = nil
        }
        
        updateSpaceButtonImage()
    }
    
    open override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }
        
        super.insertReturnText()
        
        clearAllBuffers()
        processor.reset한글조합()
        lastInputText = nil
        updateSpaceButtonImage()
    }
    
    open override func deleteBackward() {
        if BaseKeyboardViewController.isPreview { return }
        
        deleteBackwardWillPerform()
        
        if !composingBuffer.isEmpty {
            let oldComposingCount = composingBuffer.count
            
            let deleteResult = processor.deleteWithRestore종성(
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )
            
            // 기존 composing + 소비된 committed를 한 번에 삭제하고 새 composing 삽입
            let totalDeleteCount = oldComposingCount + deleteResult.consumedCommittedCount
            replaceText(deleteCount: totalDeleteCount, insert: deleteResult.composing)
            
            // committedBuffer 동기화
            applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
            
            composingBuffer = deleteResult.composing
            
            if composingBuffer.isEmpty {
                pullFromCommittedIfNeeded()
            }
            
        } else if !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            
            if lastCommitted.isHangeul {
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                
                let deleteResult = processor.deleteWithRestore종성(
                    composing: String(lastCommitted),
                    committedTail: String(committedBuffer.suffix(2)),
                    isProtected: committedBuffer.count <= protectedCommittedCount
                )
                
                // committed에서 꺼낸 글자(1) + 추가 소비분을 한 번에 삭제하고 새 composing 삽입
                let totalDeleteCount = 1 + deleteResult.consumedCommittedCount
                replaceText(deleteCount: totalDeleteCount, insert: deleteResult.composing)
                
                applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
                
                composingBuffer = deleteResult.composing
                
                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                } else if !isProtected {
                    processor.start한글조합()
                }
            } else {
                deleteText()
                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                processor.reset한글조합()
            }
        } else {
            deleteText()
            processor.reset한글조합()
        }
        updateSpaceButtonImage()
        lastInputText = nil
    }
    
    open override func repeatDeleteBackward() {
        if BaseKeyboardViewController.isPreview { return }
        
        repeatDeleteBackwardWillPerform()
        
        deleteText()
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
    
    /// `CompositionResult`를 `textDocumentProxy`와 `inputBuffer`에 반영합니다.
    func applyCompositionResult(_ result: CompositionResult) {
        let oldComposing = composingBuffer
        let oldComposingCount = oldComposing.count
        
        // 최적화: 기존 composing이 변경 없이 그대로 확정된 경우 (예: 숫자/기호 입력)
        // delete → reinsert를 건너뛰고 새 글자만 append
        if result.committed == oldComposing && result.consumedCommittedCount == 0 {
            committedBuffer.append(result.committed)
            
            if isPulledFromProtected {
                protectedCommittedCount = committedBuffer.count
                isPulledFromProtected = false
            }
            
            composingBuffer = result.composing
            
            if !result.composing.isEmpty {
                // 기존 composing은 그대로 committed → inputBuffer 변경 없음, 새 composing만 추가
                insertText(result.composing)
            }
            
            lastInputText = result.input글자
            updateSpaceButtonImage()
            return
        }
        
        // 일반 경로: 기존 composing + 소비된 committed를 지우고 새 결과를 입력
        let totalDeleteCount = oldComposingCount + result.consumedCommittedCount
        let textToInsert = result.committed + result.composing
        replaceText(deleteCount: totalDeleteCount, insert: textToInsert)
        
        // committedBuffer 동기화 (textDocumentProxy 삭제는 replaceText에서 이미 수행)
        applyConsumedCommitted(count: result.consumedCommittedCount)
        
        if !result.committed.isEmpty {
            committedBuffer.append(result.committed)
            
            if isPulledFromProtected {
                protectedCommittedCount = committedBuffer.count
                isPulledFromProtected = false
            }
        } else {
            isPulledFromProtected = false
        }
        
        composingBuffer = result.composing
        
        lastInputText = result.input글자
        updateSpaceButtonImage()
    }
    
    /// 프로세서가 소비한 committed 글자를 `committedBuffer`에서 제거합니다.
    ///
    /// `textDocumentProxy` 삭제는 `replaceText`에서 이미 수행되었으므로,
    /// 이 메서드는 `committedBuffer`만 동기화합니다.
    func applyConsumedCommitted(count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            committedBuffer.removeLast()
        }
        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
    }
    
    /// composing이 비었을 때 committed에서 마지막 한글을 끌어옵니다.
    ///
    /// 삭제 후 composing이 빈 상태에서 committed에 한글이 있으면,
    /// 마지막 글자를 composing으로 옮겨서 다음 삭제 시 자소 단위 분해가 가능하도록 합니다.
    ///
    /// 끌어오기는 proxy 상 delete→insert이지만 실제 글자가 변경되지 않으므로
    /// `replaceText`를 사용하여 inputBuffer도 자동 동기화됩니다.
    func pullFromCommittedIfNeeded() {
        guard composingBuffer.isEmpty, !committedBuffer.isEmpty else {
            if composingBuffer.isEmpty {
                processor.reset한글조합()
            }
            return
        }
        
        let lastCommitted = committedBuffer.last!
        let lastStr = String(lastCommitted)
        
        if lastCommitted.isHangeul {
            let isProtected = committedBuffer.count <= protectedCommittedCount
            
            committedBuffer.removeLast()
            protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
            replaceText(deleteCount: 1, insert: lastStr)
            composingBuffer = lastStr
            
            isPulledFromProtected = isProtected
            
            if !isProtected {
                processor.start한글조합()
            }
        } else {
            processor.reset한글조합()
        }
    }
    
    /// `composingBuffer`를 `committedBuffer`로 이동시킵니다 (조합 확정).
    func commitComposingBuffer() {
        committedBuffer.append(composingBuffer)
        composingBuffer.removeAll()
        isPulledFromProtected = false
    }
    
    /// 모든 버퍼를 초기화합니다.
    func clearAllBuffers() {
        committedBuffer.removeAll()
        composingBuffer.removeAll()
        protectedCommittedCount = 0
        isPulledFromProtected = false
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
