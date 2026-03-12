//
//  HangeulProcessorTestable.swift
//  SYKeyboardTests
//
//  Created by 서동환 on 3/6/26.
//

import Testing

@testable import HangeulKeyboardCore

/// 한글 입력기 테스트를 위한 공통 헬퍼 프로토콜
///
/// `NaratgeulProcessorTests`, `CheonjiinProcessorTests`, `DubeolsikProcessorTests`에서
/// 공통으로 사용하는 `applyInput`, `applyDelete` 로직을 한곳에서 관리합니다.
///
/// 종성 복원 로직은 프로세서의 `inputWithRestore종성`(입력)과 `deleteWithRestore종성`(삭제)에서
/// 모두 처리하므로, 이 헬퍼에는 종성 복원 코드가 없습니다.
///
/// > Note: 이 헬퍼는 프로세서 단위 테스트용입니다. `protectedCommittedCount` 등
/// > 컨트롤러 레벨의 확정 보호 로직은 `KeyboardControllerSimulator`를 사용하는
/// > 통합 테스트에서 검증합니다.
protocol HangeulProcessorTestable {
    var automata: HangeulAutomataProtocol { get }
    var processor: HangeulProcessable { get }
}

extension HangeulProcessorTestable {
    
    /// 프로세서 입력 후 `committed`/`composing`을 누적하는 헬퍼
    ///
    /// 프로세서의 `inputWithRestore종성`을 호출하므로 종성 복원도 자동으로 처리됩니다.
    /// 프로세서 단위 테스트에서는 `isProtected`를 항상 `false`로 전달합니다.
    func applyInput(_ char: String, committed: String, composing: String) -> (committed: String, composing: String) {
        let result = processor.inputWithRestore종성(
            글자Input: char,
            composing: composing,
            committedTail: String(committed.suffix(2)),
            isProtected: false
        )
        
        var c = committed
        
        // 프로세서가 committed를 소비했으면 제거
        if result.consumedCommittedCount > 0 {
            c = String(c.dropLast(result.consumedCommittedCount))
        }
        
        c.append(result.committed)
        return (c, result.composing)
    }
    
    /// ViewController의 `deleteBackward`를 시뮬레이션하는 삭제 헬퍼
    ///
    /// 프로세서의 `deleteWithRestore종성`을 호출하므로 종성 복원도 자동으로 처리됩니다.
    /// 프로세서 단위 테스트에서는 `isProtected`를 항상 `false`로 전달합니다.
    func applyDelete(committed: String, composing: String) -> (committed: String, composing: String) {
        var c = committed
        var p = composing
        
        if !p.isEmpty {
            let deleteResult = processor.deleteWithRestore종성(
                composing: p,
                committedTail: String(c.suffix(2)),
                isProtected: false
            )
            
            // 프로세서가 committed를 소비했으면 제거
            if deleteResult.consumedCommittedCount > 0 {
                c = String(c.dropLast(deleteResult.consumedCommittedCount))
            }
            p = deleteResult.composing
            
            // composing이 비었으면 committed에서 끌어오기
            if p.isEmpty && !c.isEmpty {
                let lastChar = c.last!
                let lastStr = String(lastChar)
                if automata.초성Table.contains(lastStr) || automata.중성Table.contains(lastStr)
                    || automata.decompose(한글Char: lastChar) != nil {
                    c.removeLast()
                    p = lastStr
                    processor.start한글조합()
                }
            }
            
        } else if !c.isEmpty {
            let lastCommitted = c.last!
            // 한글이면 composing으로 옮겨서 자소 단위 분해 삭제
            if automata.decompose(한글Char: lastCommitted) != nil {
                c.removeLast()
                let deleteResult = processor.deleteWithRestore종성(
                    composing: String(lastCommitted),
                    committedTail: String(c.suffix(2)),
                    isProtected: false
                )
                if deleteResult.consumedCommittedCount > 0 {
                    c = String(c.dropLast(deleteResult.consumedCommittedCount))
                }
                p = deleteResult.composing
            } else {
                // 비한글(숫자, 기호 등)은 통째로 삭제
                c.removeLast()
            }
        }
        
        return (c, p)
    }
}
