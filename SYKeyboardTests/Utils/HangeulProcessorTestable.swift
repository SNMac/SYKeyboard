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
/// 공통으로 사용하는 `applyInput`, `applyDelete`, `tryRestore종성` 로직을 한곳에서 관리합니다.
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
    /// ViewController의 `applyCompositionResult`와 동일한 종성 복원 로직을 포함합니다.
    func applyInput(_ char: String, committed: String, composing: String) -> (committed: String, composing: String) {
        let hadPreviousComposing = !composing.isEmpty
        let result = processor.input(글자Input: char, composing: composing)
        var c = committed + result.committed
        let p = result.composing
        
        // 입력 시 종성 복원
        if hadPreviousComposing && result.committed.isEmpty && p.count == 1 && !c.isEmpty {
            if let restored = tryRestore종성(자음: p, committed: &c) {
                return (c, restored)
            }
        }
        
        return (c, p)
    }
    
    /// ViewController의 `deleteBackward`를 시뮬레이션하는 삭제 헬퍼
    func applyDelete(committed: String, composing: String) -> (committed: String, composing: String) {
        var c = committed
        var p = composing
        
        if !p.isEmpty {
            p = processor.delete(composing: p)
            
            // 삭제 시 종성 복원
            if let restored = tryRestore종성(자음: p, committed: &c) {
                return (c, restored)
            }
            
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
                p = processor.delete(composing: String(lastCommitted))
            } else {
                // 비한글(숫자, 기호 등)은 통째로 삭제
                c.removeLast()
            }
        }
        
        return (c, p)
    }
    
    /// 낱자 자음 1개를 `committed`의 마지막 한글에 종성으로 합치기 시도
    ///
    /// 성공하면 합쳐진 글자를 반환하고 `committed`에서 마지막 글자를 제거합니다.
    /// 실패하면 `nil`을 반환하고 `committed`를 변경하지 않습니다.
    func tryRestore종성(자음: String, committed: inout String) -> String? {
        guard 자음.count == 1, !committed.isEmpty else { return nil }
        guard automata.종성Table.contains(자음) && 자음 != " " else { return nil }
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
}
