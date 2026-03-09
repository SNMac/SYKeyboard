//
//  KeyboardControllerSimulator.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/8/26.
//

import Testing

@testable import HangeulKeyboardCore

/// `HangeulKeyboardCoreViewController`의 버퍼 관리 로직을 시뮬레이션하는 테스트 헬퍼
///
/// `textDocumentProxy` 등 iOS 시스템 의존성 없이 컨트롤러의 핵심 로직을 검증합니다.
/// `committedBuffer`/`composingBuffer`/`protectedCommittedCount` 관리를 재현하여
/// 프로세서 단위 테스트에서 검증할 수 없는 컨트롤러 레벨 동작을 테스트합니다.
///
/// > 이 클래스의 버퍼 관리 로직(`tryRestore종성`, 끌어오기, `protectedCommittedCount` 체크 등)은
/// `HangeulKeyboardCoreViewController`와 동일한 구현을 의도적으로 유지하고 있습니다.
/// 컨트롤러의 해당 로직을 수정할 경우 이 파일도 함께 수정하세요.
final class KeyboardControllerSimulator {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol
    private let processor: HangeulProcessable
    
    /// 조합이 완료되어 더 이상 변경되지 않는 문자열
    private(set) var committedBuffer: String = ""
    /// 현재 오토마타가 조합 중인 문자열
    private(set) var composingBuffer: String = ""
    
    /// 스페이스(확정)로 보호된 `committedBuffer` 내의 글자 수
    private var protectedCommittedCount: Int = 0
    /// 마지막으로 입력한 문자 (반복 입력용)
    private var lastInputText: String?
    
    /// 현재 화면에 표시되는 전체 텍스트
    var text: String { committedBuffer + composingBuffer }
    
    // MARK: - Initializer
    
    init(automata: HangeulAutomataProtocol, processor: HangeulProcessable) {
        self.automata = automata
        self.processor = processor
    }
    
    // MARK: - Internal Methods
    
    /// 글자 입력 (컨트롤러의 `insertPrimaryKeyText` 시뮬레이션)
    func input(_ char: String) {
        let hadPreviousComposing = !composingBuffer.isEmpty
        let result = processor.input(글자Input: char, composing: composingBuffer)
        
        let finalCommitted = result.committed
        let finalComposing = result.composing
        
        // 입력 시 종성 복원
        if hadPreviousComposing && finalCommitted.isEmpty && finalComposing.count == 1 && !committedBuffer.isEmpty {
            if let restored = tryRestore종성(자음: finalComposing, committed: &committedBuffer) {
                composingBuffer = restored
                lastInputText = result.input글자
                return
            }
        }
        
        committedBuffer.append(finalCommitted)
        composingBuffer = finalComposing
        lastInputText = result.input글자
    }
    
    /// 스페이스 입력 (컨트롤러의 `insertSpaceText` 시뮬레이션)
    func space() {
        let result = processor.inputSpace(composing: composingBuffer)
        switch result {
        case .commitCombination:
            committedBuffer.append(composingBuffer)
            composingBuffer.removeAll()
            protectedCommittedCount = committedBuffer.count
            lastInputText = nil
            
        case .insertSpace:
            committedBuffer.removeAll()
            composingBuffer.removeAll()
            protectedCommittedCount = 0
            processor.reset한글조합()
            lastInputText = nil
        }
    }
    
    /// 삭제 (컨트롤러의 `deleteBackward` 시뮬레이션)
    func delete() {
        if !composingBuffer.isEmpty {
            let remaining = processor.delete(composing: composingBuffer)
            
            // 종성 복원
            if let restored = tryRestore종성(자음: remaining, committed: &committedBuffer) {
                composingBuffer = restored
            } else {
                composingBuffer = remaining
            }
            
            // composing이 비었으면 committed에서 끌어오기
            if composingBuffer.isEmpty {
                if !committedBuffer.isEmpty {
                    let lastCommitted = committedBuffer.last!
                    let lastStr = String(lastCommitted)
                    if lastCommitted.isHangeul {
                        
                        let isProtected = committedBuffer.count <= protectedCommittedCount
                        
                        committedBuffer.removeLast()
                        composingBuffer = lastStr
                        
                        if !isProtected {
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
                
                committedBuffer.removeLast()
                let decomposed = processor.delete(composing: String(lastCommitted))
                composingBuffer = decomposed
                
                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                } else if !isProtected {
                    processor.start한글조합()
                }
            } else {
                // 비한글(숫자, 기호 등)은 통째로 삭제
                committedBuffer.removeLast()
                processor.reset한글조합()
            }
        } else {
            processor.reset한글조합()
        }
        
        lastInputText = nil
    }
    
    /// 반복 입력 (컨트롤러의 `repeatInsertPrimaryKeyText` 시뮬레이션)
    func repeatInsert(_ char: String) {
        if !composingBuffer.isEmpty {
            committedBuffer.append(composingBuffer)
            composingBuffer.removeAll()
        }
        composingBuffer = char
    }
    
    /// 반복 삭제 (컨트롤러의 `repeatDeleteBackward` 시뮬레이션)
    func repeatDelete() {
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
        lastInputText = nil
    }
    
    /// 반복 삭제 종료 후 끌어오기 (컨트롤러의 `repeatTextInteractionDidPerform` 시뮬레이션)
    func finishRepeatDelete() {
        if composingBuffer.isEmpty && !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            let lastStr = String(lastCommitted)
            if lastCommitted.isHangeul {
                
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                committedBuffer.removeLast()
                composingBuffer = lastStr
                
                if !isProtected {
                    processor.start한글조합()
                }
            }
        }
    }
    
    /// 반복 입력 시작 시 조합 (컨트롤러의 `insertPrimaryKeyText`에서 repeat 시작 시뮬레이션)
    func repeatStart(_ primaryKey: String) {
        let result = processor.input(글자Input: primaryKey, composing: composingBuffer)
        
        let finalCommitted = result.committed
        let finalComposing = result.composing
        
        // 입력 시 종성 복원
        let hadPreviousComposing = !composingBuffer.isEmpty
        if hadPreviousComposing && finalCommitted.isEmpty && finalComposing.count == 1 && !committedBuffer.isEmpty {
            if let restored = tryRestore종성(자음: finalComposing, committed: &committedBuffer) {
                composingBuffer = restored
                lastInputText = result.input글자
                return
            }
        }
        
        committedBuffer.append(finalCommitted)
        composingBuffer = finalComposing
        lastInputText = result.input글자
    }
}

// MARK: - Private Methods

private extension KeyboardControllerSimulator {
    func tryRestore종성(자음: String, committed: inout String) -> String? {
        guard 자음.count == 1, !committed.isEmpty else { return nil }
        guard automata.종성Table.contains(자음) && 자음 != " " else { return nil }
        guard committed.count > protectedCommittedCount else { return nil }
        guard let lastCommitted = committed.last,
              let _ = automata.decompose(한글Char: lastCommitted) else { return nil }
        
        let lastCommittedStr = String(lastCommitted)
        let (committed2, merged) = automata.add글자(글자Input: 자음, composing: lastCommittedStr)
        let mergedText = committed2 + merged
        
        if mergedText.count == 1 {
            committed.removeLast()
            return mergedText
        }
        return nil
    }
}
