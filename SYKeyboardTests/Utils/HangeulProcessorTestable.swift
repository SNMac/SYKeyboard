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
/// 공통으로 사용하는 `applyInput` 로직을 한곳에서 관리합니다.
///
/// 종성 복원 입력 로직은 프로세서의 `inputWithRestore종성`에서 처리하므로,
/// 이 헬퍼에는 종성 복원 코드가 없습니다.
///
/// > Note: 이 헬퍼는 프로세서 단위 테스트용입니다. `protectedCommittedCount` 등
/// > 컨트롤러 레벨의 확정 보호 로직은 `HangeulCompositionTestHarness`를 사용하는
/// > `HangeulCompositionState` 기반 상태 시나리오에서 검증합니다.
protocol HangeulProcessorTestable {
    var automata: HangeulAutomataProtocol { get }
    var processor: HangeulProcessable { get }
}

extension HangeulProcessorTestable {
    
    /// 프로세서 입력 후 `committed`/`composing`을 누적하는 헬퍼
    ///
    /// 프로세서의 `inputWithRestore종성`을 호출하므로 종성 복원도 자동으로 처리됩니다.
    /// 프로세서 단위 테스트에서는 `isProtected`를 항상 `false`로 전달합니다.
    /// 컨트롤러 수준의 확정 보호나 committed 끌어오기는 이 헬퍼로 검증하지 않습니다.
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
    
}
