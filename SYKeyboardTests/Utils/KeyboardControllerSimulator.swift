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
/// 종성 복원 로직은 프로세서의 `inputWithRestore종성`(입력)과 `deleteWithRestore종성`(삭제)에서
/// 모두 처리하므로, 이 시뮬레이터에는 종성 복원 코드가 없습니다.
///
/// > 이 클래스의 버퍼 관리 로직은 `HangeulKeyboardCoreViewController`와 동일한 구현을
/// > 의도적으로 유지하고 있습니다. 컨트롤러의 해당 로직을 수정할 경우 이 파일도 함께 수정하세요.
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
    /// 끌어온 글자가 보호 상태였는지 추적
    private var isPulledFromProtected: Bool = false
    
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
        let result = processor.inputWithRestore종성(
            글자Input: char,
            composing: composingBuffer,
            committedTail: String(committedBuffer.suffix(2)),
            isProtected: committedBuffer.count <= protectedCommittedCount
        )
        
        applyCompositionResult(result)
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
            isPulledFromProtected = false
            
        case .insertSpace:
            committedBuffer.removeAll()
            composingBuffer.removeAll()
            protectedCommittedCount = 0
            isPulledFromProtected = false
            processor.reset한글조합()
            lastInputText = nil
        }
    }
    
    /// 삭제 (컨트롤러의 `deleteBackward` 시뮬레이션)
    func delete() {
        if !composingBuffer.isEmpty {
            // 프로세서에 committed 꼬리(최대 2글자)와 보호 여부를 전달
            let deleteResult = processor.deleteWithRestore종성(
                composing: composingBuffer,
                committedTail: String(committedBuffer.suffix(2)),
                isProtected: committedBuffer.count <= protectedCommittedCount
            )
            
            // 프로세서가 committed를 소비했으면 제거
            applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
            composingBuffer = deleteResult.composing
            
            // composing이 비었으면 committed에서 끌어오기
            if composingBuffer.isEmpty {
                pullFromCommittedIfNeeded()
            }
            
        } else if !committedBuffer.isEmpty {
            let lastCommitted = committedBuffer.last!
            
            // 한글이면 composing으로 옮겨서 자소 단위 분해 삭제
            if lastCommitted.isHangeul {
                let isProtected = committedBuffer.count <= protectedCommittedCount
                
                committedBuffer.removeLast()
                // 확정 영역이 삭제(분해)되면 보호 해제
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                
                // 끌어온 글자를 삭제 처리
                let deleteResult = processor.deleteWithRestore종성(
                    composing: String(lastCommitted),
                    committedTail: String(committedBuffer.suffix(2)),
                    isProtected: committedBuffer.count <= protectedCommittedCount
                )
                
                applyConsumedCommitted(count: deleteResult.consumedCommittedCount)
                composingBuffer = deleteResult.composing
                
                if composingBuffer.isEmpty {
                    processor.reset한글조합()
                } else if !isProtected {
                    // 보호되지 않은 글자만 조합 시작
                    processor.start한글조합()
                }
            } else {
                // 비한글(숫자, 기호 등)은 통째로 삭제
                committedBuffer.removeLast()
                // 확정 영역이 삭제되면 보호 해제
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
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
        isPulledFromProtected = false
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
            // 확정 영역이 삭제되면 보호 해제
            protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
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
                // 확정 영역이 삭제(분해)되면 보호 해제
                protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
                composingBuffer = lastStr
                
                // 보호 상태를 기억
                isPulledFromProtected = isProtected
                
                if !isProtected {
                    processor.start한글조합()
                }
            }
        }
    }
    
    /// 반복 입력 시작 시 조합 (컨트롤러의 `insertPrimaryKeyText`에서 repeat 시작 시뮬레이션)
    func repeatStart(_ primaryKey: String) {
        let result = processor.inputWithRestore종성(
            글자Input: primaryKey,
            composing: composingBuffer,
            committedTail: String(committedBuffer.suffix(2)),
            isProtected: committedBuffer.count <= protectedCommittedCount
        )
        
        applyCompositionResult(result)
    }
}

// MARK: - Private Methods

private extension KeyboardControllerSimulator {
    
    /// `CompositionResult`를 버퍼에 반영합니다.
    func applyCompositionResult(_ result: CompositionResult) {
        applyConsumedCommitted(count: result.consumedCommittedCount)
        
        if !result.committed.isEmpty {
            committedBuffer.append(result.committed)
            
            // 끌어온 보호 글자가 committed로 돌아가면 보호 카운트 복원
            if isPulledFromProtected {
                protectedCommittedCount = committedBuffer.count
                isPulledFromProtected = false
            }
        } else {
            // committed 추가 없이 composing만 변경된 경우 (종성 복원 등)
            isPulledFromProtected = false
        }
        
        composingBuffer = result.composing
        lastInputText = result.input글자
    }
    
    /// 프로세서가 소비한 committed 글자를 `committedBuffer`에서 제거합니다.
    func applyConsumedCommitted(count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            committedBuffer.removeLast()
        }
        protectedCommittedCount = min(protectedCommittedCount, committedBuffer.count)
    }
    
    /// composing이 비었을 때 committed에서 마지막 한글을 끌어옵니다.
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
            composingBuffer = lastStr
            
            // 보호 상태를 기억하여 이후 committed로 돌아갈 때 복원
            isPulledFromProtected = isProtected
            
            if !isProtected {
                processor.start한글조합()
            }
        } else {
            processor.reset한글조합()
        }
    }
}
