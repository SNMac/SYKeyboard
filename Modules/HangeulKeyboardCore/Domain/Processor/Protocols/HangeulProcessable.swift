//
//  HangeulProcessable.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 11/21/25.
//

/// 오토마타/프로세서의 처리 결과
///
/// 입력, 삭제 등의 결과를 **확정(`committed`)**과 **조합 중(`composing`)**으로 분리하여 반환합니다.
/// 프로세서가 종성 복원 등의 이유로 `committedTail`의 글자를 소비할 수 있으며,
/// 그 경우 `consumedCommittedCount`로 VC에 알립니다.
///
/// - 예: "간" + "ㅏ" → `committed`: "가", `composing`: "나", `consumedCommittedCount`: 0
/// - 예: committed="가", composing="ㄴ" (새 자음) → 종성 복원 → `committed`: "", `composing`: "간", `consumedCommittedCount`: 1
struct CompositionResult {
    /// 조합이 확정되어 더 이상 변경되지 않는 문자열.
    /// ViewController의 `committedBuffer`에 추가됩니다.
    let committed: String
    
    /// 현재 오토마타가 조합 중인 문자열 (최대 1~2글자).
    /// ViewController의 `composingBuffer`를 이 값으로 교체합니다.
    let composing: String
    
    /// 반복 입력(long press)을 위한 실제 입력 글자.
    /// `nil`이면 반복 입력이 불가능합니다.
    let input글자: String?
    
    /// 프로세서가 `committedTail`에서 소비한 글자 수 (0, 1, 또는 2).
    /// VC는 `committedBuffer`에서 뒤에서 이 수만큼 글자를 제거하고,
    /// 화면(`textDocumentProxy`)에서도 해당 글자를 지워야 합니다.
    let consumedCommittedCount: Int
    
    init(committed: String, composing: String, input글자: String?, consumedCommittedCount: Int = 0) {
        self.committed = committed
        self.composing = composing
        self.input글자 = input글자
        self.consumedCommittedCount = consumedCommittedCount
    }
    
    /// 편의 생성자: `committed` 없이 `composing`만 있는 경우
    static func composingOnly(_ composing: String, input글자: String? = nil) -> CompositionResult {
        CompositionResult(committed: "", composing: composing, input글자: input글자)
    }
    
    /// 편의 생성자: 조합 없이 그대로 확정되는 경우
    static func commitAll(_ text: String, input글자: String? = nil) -> CompositionResult {
        CompositionResult(committed: text, composing: "", input글자: input글자)
    }
}

/// `delete` 메서드의 반환 타입
///
/// 삭제 결과를 composing 변경뿐만 아니라 committed 소비까지 포함하여 반환합니다.
///
/// - 예: composing="ㄴ", committedTail="가" → 종성 복원 → `composing: "간"`, `consumedCommittedCount: 1`
/// - 예: composing="ㄷ", committedTail="간ㆍ" → 비표준 모음 연음 → `composing: "간ㆍㄷ"`, `consumedCommittedCount: 2`
/// - 예: composing="간" → 삭제 → `composing: "가"`, `consumedCommittedCount: 0`
struct DeleteResult {
    /// 삭제 후 남은 조합 문자열
    let composing: String
    
    /// 프로세서가 `committedTail`에서 소비한 글자 수 (0, 1, 또는 2).
    let consumedCommittedCount: Int
}

/// 스페이스바 입력 시 동작 결과
enum SpaceInputResult {
    case insertSpace        // 실제 공백 텍스트(" ")를 입력
    case commitCombination  // 조합을 끊고 대기 (입력 없음)
}

/// 한글 입력기 프로토콜
///
/// 각 프로세서는 `input()`과 `delete()`만 구현하면 됩니다.
/// VC는 프로토콜 기본 구현인 `inputWithRestore종성()`과 `deleteWithRestore종성()`을 호출합니다.
/// 이 기본 구현들이 committed와의 종성 합치기를 공통으로 처리합니다.
protocol HangeulProcessable: AnyObject {
    /// 프로세서가 사용하는 오토마타
    var automata: HangeulAutomataProtocol { get }
    
    /// 현재 한글 조합이 진행 중인지 여부
    /// - `true`: 조합 중 (예: 천지인에서 '화살표' 버튼 표시)
    /// - `false`: 조합 대기/완료 (예: 천지인에서 '스페이스' 버튼 표시)
    var is한글조합OnGoing: Bool { get }
    
    /// 한글 입력을 처리합니다 (프로세서 고유 로직만 담당).
    ///
    /// 종성 복원은 이 메서드가 아닌 `inputWithRestore종성`(프로토콜 기본 구현)에서 처리합니다.
    /// 각 프로세서는 이 메서드만 구현하면 됩니다.
    ///
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자 (`String` 타입)
    ///   - composing: 현재 조합 중인 문자열 (최대 1~2글자)
    /// - Returns: 확정/조합 분리된 결과
    func input(글자Input: String, composing: String) -> CompositionResult
    
    /// 스페이스바 입력을 처리합니다.
    /// - Parameter composing: 현재 조합 중인 문자열
    func inputSpace(composing: String) -> SpaceInputResult
    
    /// 마지막 글자를 지우거나 분해합니다 (프로세서 고유 로직만 담당).
    ///
    /// committed와의 종성 합치기는 `deleteWithRestore종성`(프로토콜 기본 구현)에서 처리합니다.
    /// 천지인의 비표준 모음(ㆍ, ᆢ) 처리 등 프로세서 고유 로직만 여기서 구현합니다.
    ///
    /// - Parameters:
    ///   - composing: 현재 조합 중인 문자열
    ///   - committedTail: `committedBuffer`의 마지막 최대 2글자 (빈 문자열이면 committed 없음)
    ///   - isProtected: `committedTail`의 마지막 글자가 스페이스 확정으로 보호되었는지 여부
    /// - Returns: 삭제 결과 (composing 변경 + committed 소비 글자 수)
    func delete(composing: String, committedTail: String, isProtected: Bool) -> DeleteResult
    
    /// 한글 조합 상태를 시작합니다.
    func start한글조합()
    
    /// 한글 조합 상태를 리셋합니다.
    func reset한글조합()
}

// MARK: - 종성 복원 기본 구현

extension HangeulProcessable {
    
    /// 입력 처리 + committed와의 종성 복원을 수행하는 통합 메서드
    ///
    /// 1. 각 프로세서의 `input(글자Input:composing:)`을 호출
    /// 2. 결과가 "committed 비어있음 + composing 낱자 자음 1개"이고
    ///    이전 composing이 있었으면(변환 결과), committed 마지막 한글에 종성으로 합치기 시도
    ///
    /// VC는 `input()`이 아닌 이 메서드를 호출해야 합니다.
    ///
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자
    ///   - composing: 현재 조합 중인 문자열
    ///   - committedTail: `committedBuffer`의 마지막 최대 2글자
    ///   - isProtected: committed가 스페이스 확정으로 보호되었는지 여부
    /// - Returns: 종성 복원이 적용된 `CompositionResult`
    func inputWithRestore종성(
        글자Input: String,
        composing: String,
        committedTail: String,
        isProtected: Bool
    ) -> CompositionResult {
        let hadPreviousComposing = !composing.isEmpty
        let result = input(글자Input: 글자Input, composing: composing)
        
        // 종성 복원 조건:
        // - 이전 composing이 있었음 (변환의 결과로 자음이 남은 것)
        // - committed가 비어있음 (프로세서가 확정한 게 없음)
        // - composing이 낱자 자음 1개
        // - committedTail이 비어있지 않고 보호되지 않음
        guard hadPreviousComposing,
              result.committed.isEmpty,
              result.composing.count == 1,
              !committedTail.isEmpty,
              !isProtected else {
            return result
        }
        
        if let merged = tryMerge종성(자음: result.composing, committedTail: committedTail) {
            return CompositionResult(
                committed: "",
                composing: merged,
                input글자: result.input글자,
                consumedCommittedCount: 1
            )
        }
        
        return result
    }
    
    /// 삭제 처리 + committed와의 종성 복원을 수행하는 통합 메서드
    ///
    /// 1. 각 프로세서의 `delete(composing:committedTail:isProtected:)`를 호출
    /// 2. 프로세서가 이미 committed를 소비하지 않았고(`consumedCommittedCount == 0`),
    ///    결과가 낱자 자음 1개이면 committed 마지막 한글에 종성으로 합치기 시도
    ///
    /// VC는 `delete()`이 아닌 이 메서드를 호출해야 합니다.
    ///
    /// - Parameters:
    ///   - composing: 현재 조합 중인 문자열
    ///   - committedTail: `committedBuffer`의 마지막 최대 2글자
    ///   - isProtected: committed가 스페이스 확정으로 보호되었는지 여부
    /// - Returns: 종성 복원이 적용된 `DeleteResult`
    func deleteWithRestore종성(
        composing: String,
        committedTail: String,
        isProtected: Bool
    ) -> DeleteResult {
        let result = delete(composing: composing, committedTail: committedTail, isProtected: isProtected)
        
        // 프로세서가 이미 committed를 소비했으면 추가 복원 안 함
        guard result.consumedCommittedCount == 0,
              result.composing.count == 1,
              !committedTail.isEmpty,
              !isProtected else {
            return result
        }
        
        if let merged = tryMerge종성(자음: result.composing, committedTail: committedTail) {
            return DeleteResult(composing: merged, consumedCommittedCount: 1)
        }
        
        return result
    }
    
    /// 낱자 자음 1개를 committed의 마지막 한글에 종성으로 합치기 시도 (공통 로직)
    ///
    /// 성공하면 합쳐진 글자(1글자)를 반환합니다.
    /// 실패하면 `nil`을 반환합니다.
    private func tryMerge종성(자음: String, committedTail: String) -> String? {
        guard 자음.count == 1 else { return nil }
        guard automata.종성Table.contains(자음) && 자음 != " " else { return nil }
        guard let lastCommitted = committedTail.last,
              let _ = automata.decompose(한글Char: lastCommitted) else { return nil }
        
        let lastCommittedStr = String(lastCommitted)
        let (committed2, merged) = automata.add글자(글자Input: 자음, composing: lastCommittedStr)
        let mergedText = committed2 + merged
        
        // 2글자 → 1글자로 합쳐진 경우만 성공 (예: "가" + "ㄴ" → "간")
        if mergedText.count == 1 {
            return mergedText
        }
        
        return nil
    }
}
