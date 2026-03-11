//
//  DubeolsikProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 1/23/26.
//

/// 두벌식 입력기
///
/// 표준 두벌식 입력을 처리합니다.
/// - **특징**:
///   1. **직관적 매핑**: 입력된 자모가 곧바로 오토마타를 통해 결합됩니다.
final class DubeolsikProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    /// 두벌식 입력기는 별도의 '조합 끊기' 단계 없이 스페이스가 항상 공백으로 동작하므로 항상 `false`를 반환합니다.
    var is한글조합OnGoing: Bool { false }
    
    /// 표준 한글 오토마타
    let automata: HangeulAutomataProtocol
    
    // MARK: - Initializer
    
    init(automata: HangeulAutomataProtocol) {
        self.automata = automata
    }
    
    // MARK: - HangeulProcessable Methods
    
    /// 사용자의 입력을 처리합니다.
    func input(글자Input: String, composing: String) -> CompositionResult {
        let (committed, newComposing) = automata.add글자(글자Input: 글자Input, composing: composing)
        return CompositionResult(committed: committed, composing: newComposing, input글자: 글자Input)
    }
    
    /// 스페이스바 입력을 처리합니다.
    func inputSpace(composing: String) -> SpaceInputResult {
        return .insertSpace
    }
    
    /// 마지막 글자를 삭제합니다.
    ///
    /// `composing` 내에서 자소 단위로 삭제하고, `composing`이 2글자 이상이면
    /// 종성 복원(예: '갈가' → 삭제 → '갈ㄱ' → '갉')을 시도합니다.
    /// 두벌식은 비표준 모음이 없으므로 `committedTail`/`isProtected`를 사용하지 않습니다.
    /// committed와의 종성 합치기는 `deleteWithRestore종성`(프로토콜 기본 구현)에서 처리합니다.
    func delete(composing: String, committedTail: String, isProtected: Bool) -> DeleteResult {
        // 1. 기본 오토마타 삭제 수행
        let deletedText = automata.delete글자(composing: composing)
        
        // 텍스트가 2글자 미만이면 결합할 대상이 없으므로 반환
        if deletedText.count < 2 {
            return DeleteResult(composing: deletedText, consumedCommittedCount: 0)
        }
        
        // 2. 분리 (Prefix + LastChar)
        let lastIndex = deletedText.index(before: deletedText.endIndex)
        let lastChar = deletedText[lastIndex]
        let lastCharString = String(lastChar)
        let prefixText = String(deletedText[..<lastIndex])
        
        // 남은 마지막 글자가 실제로 '종성(받침)'으로 쓰일 수 있는 자음인지 확인합니다.
        guard automata.종성Table.contains(lastCharString) && lastCharString != " " else {
            return DeleteResult(composing: deletedText, consumedCommittedCount: 0)
        }
        
        // 3. 결합 시도
        let (committed, merged) = automata.add글자(글자Input: lastCharString, composing: prefixText)
        let mergedText = committed + merged
        
        // 4. 병합 성공 확인
        if mergedText.count < deletedText.count {
            return DeleteResult(composing: mergedText, consumedCommittedCount: 0)
        }
        
        return DeleteResult(composing: deletedText, consumedCommittedCount: 0)
    }
    
    // 두벌식은 별도의 조합 상태 플래그를 관리하지 않으므로 빈 구현으로 둡니다.
    func start한글조합() {}
    func reset한글조합() {}
}
