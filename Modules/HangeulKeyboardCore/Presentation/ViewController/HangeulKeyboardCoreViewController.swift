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
    /// 현재 반복 입력 동작 중인지 확인하는 플래그
    private var isRepeatingInput: Bool = false
    /// 글자가 입력되었는지 확인하는 플래그
    private var is글자Input: Bool = false
    /// 스페이스(확정)로 보호된 `committedBuffer` 내의 글자 수
    private var protectedCommittedCount: Int = 0
    
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
        
        // 반복 삭제 후 composing이 비고 committed에 한글이 있으면 끌어오기
        if button is DeleteButton && composingBuffer.isEmpty && !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            let lastStr = String(lastCommitted)
            if lastCommitted.isHangeul {
                
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                committedBuffer.removeLast()
                // 확정 영역이 삭제(분해)되면 보호 해제
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                textDocumentProxy.deleteBackward()
                textDocumentProxy.insertText(lastStr)
                composingBuffer = lastStr
                
                if !isProtected {
                    processor.start한글조합()
                }
            }
        }
        
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
        
        if !composingBuffer.isEmpty {
            commitComposingBuffer()
        }
        
        textDocumentProxy.insertText(lastInputText)
        composingBuffer = lastInputText
    }
    
    open override func insertSpaceText() {
        if isPreview { return }
        
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
        if isPreview { return }
        
        super.insertReturnText()
        
        clearAllBuffers()
        processor.reset한글조합()
        lastInputText = nil
        updateSpaceButtonImage()
    }
    
    open override func deleteBackward() {
        if isPreview { return }
        
        deleteBackwardWillPerform()
        
        if !composingBuffer.isEmpty {
            let oldComposingCount = composingBuffer.count
            for _ in 0..<oldComposingCount { textDocumentProxy.deleteBackward() }
            
            let remaining = processor.delete(composing: composingBuffer)
            
            // 종성 복원: 삭제 후 낱자 자음 1개만 남고 committed에 한글이 있으면 합치기 시도
            if let restored = tryRestore종성(자음: remaining, committed: &committedBuffer) {
                // committed에서 마지막 글자가 제거되었으므로 화면에서도 제거
                textDocumentProxy.deleteBackward()
                textDocumentProxy.insertText(restored)
                composingBuffer = restored
            } else {
                if !remaining.isEmpty {
                    textDocumentProxy.insertText(remaining)
                }
                composingBuffer = remaining
            }
            
            if composingBuffer.isEmpty {
                if !committedBuffer.isEmpty {
                    let lastCommitted = committedBuffer.last!
                    let lastStr = String(lastCommitted)
                    if lastCommitted.isHangeul {
                        
                        let isProtected = committedBuffer.count <= protectedCommittedCount
                        
                        committedBuffer.removeLast()
                        // 확정 영역이 삭제(분해)되면 보호 해제
                        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                        textDocumentProxy.deleteBackward()
                        textDocumentProxy.insertText(lastStr)
                        composingBuffer = lastStr
                        
                        if !isProtected {
                            // 보호되지 않은 글자만 조합 시작
                            processor.start한글조합()
                        }
                    }
                }
                
                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                }
            }
            
        } else if !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            
            // 한글이면 composing으로 옮겨서 자소 단위 분해 삭제
            if lastCommitted.isHangeul {
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                textDocumentProxy.deleteBackward()
                committedBuffer.removeLast()
                // 확정 영역이 삭제(분해)되면 보호 해제
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                
                let decomposed = processor.delete(composing: String(lastCommitted))
                if !decomposed.isEmpty {
                    textDocumentProxy.insertText(decomposed)
                }
                composingBuffer = decomposed
                
                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                } else if !isProtected {
                    // 보호되지 않은 글자만 조합 시작
                    processor.start한글조합()
                }
            } else {
                // 비한글(숫자, 기호 등)은 통째로 삭제
                textDocumentProxy.deleteBackward()
                committedBuffer.removeLast()
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                processor.reset한글조합()
            }
        } else {
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
        let oldComposing = composingBuffer
        let oldComposingCount = oldComposing.count
        let hadPreviousComposing = oldComposingCount > 0
        
        // 최적화: 기존 composing이 변경 없이 그대로 확정된 경우 (예: 숫자/기호 입력)
        // delete → reinsert를 건너뛰고 새 글자만 append
        if result.committed == oldComposing {
            // 기존 composing이 그대로 committed → 화면에서 지우고 다시 넣을 필요 없음
            committedBuffer.append(result.committed)
            composingBuffer = result.composing
            
            // 새 composing 부분만 입력
            if !result.composing.isEmpty {
                textDocumentProxy.insertText(result.composing)
            }
            
            lastInputText = result.input글자
            updateSpaceButtonImage()
            return
        }
        
        // 일반 경로: 기존 composing을 지우고 새 결과를 입력
        for _ in 0..<oldComposingCount { textDocumentProxy.deleteBackward() }
        
        let finalCommitted = result.committed
        let finalComposing = result.composing
        
        // 입력 시 종성 복원: composing이 낱자 자음 1개이고 committed가 비어있으면
        // committedBuffer의 마지막 한글과 합치기 시도
        // 단, 이전 composing이 있었을 때만 (변환의 결과). 이전 composing이 비었으면 새 입력이므로 복원 안 함.
        if hadPreviousComposing && finalCommitted.isEmpty && finalComposing.count == 1 && !committedBuffer.isEmpty {
            if let restored = tryRestore종성(자음: finalComposing, committed: &committedBuffer) {
                textDocumentProxy.deleteBackward()
                textDocumentProxy.insertText(restored)
                composingBuffer = restored
                lastInputText = result.input글자
                updateSpaceButtonImage()
                return
            }
        }
        
        let textToInsert = finalCommitted + finalComposing
        if !textToInsert.isEmpty {
            textDocumentProxy.insertText(textToInsert)
        }
        
        committedBuffer.append(finalCommitted)
        composingBuffer = finalComposing
        
        lastInputText = result.input글자
        updateSpaceButtonImage()
    }
    
    /// 낱자 자음 1개를 `committed`의 마지막 한글에 종성으로 합치는 시도
    ///
    /// 성공하면 합쳐진 글자를 반환하고 `committed`에서 마지막 글자를 제거합니다.
    /// 실패하면 `nil`을 반환하고 `committed`를 변경하지 않습니다.
    func tryRestore종성(자음: String, committed: inout String) -> String? {
        guard 자음.count == 1, !committed.isEmpty else { return nil }
        guard automata.종성Table.contains(자음) && 자음 != " " else { return nil }
        guard committed.count > protectedCommittedCount else { return nil }
        guard let lastCommitted = committed.last,
              let _ = automata.decompose(한글Char: lastCommitted) else { return nil }
        
        let lastCommittedStr = String(lastCommitted)
        let (committed2, merged) = automata.add글자(글자Input: 자음, composing: lastCommittedStr)
        let mergedText = committed2 + merged
        
        // 2글자 → 1글자로 합쳐진 경우만 성공
        if mergedText.count == 1 {
            committed.removeLast()
            return mergedText
        }
        
        return nil
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
        protectedCommittedCount = 0
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
