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
    private let automata: HangeulAutomataProtocol
    
    // MARK: - Initialization
    
    init(automata: HangeulAutomataProtocol) {
        self.automata = automata
    }
    
    // MARK: - Protocol Implementation
    
    /// 사용자의 입력을 처리합니다.
    ///
    /// 두벌식은 입력된 키가 자음/모음인지 확인하여 오토마타에 그대로 전달합니다.
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        
        // 1. 오토마타를 통해 결합 시도
        // 두벌식은 별도의 순환/변환 로직 없이 오토마타의 add글자 로직을 그대로 사용합니다.
        let newText = automata.add글자(글자Input: 글자Input, beforeText: beforeText)
        
        return (newText, 글자Input)
    }
    
    /// 스페이스바 입력을 처리합니다.
    ///
    /// 두벌식은 조합 상태 여부와 관계없이 항상 실제 공백을 입력합니다.
    func inputSpace(beforeText: String) -> SpaceInputResult {
        return .insertSpace
    }
    
    /// 마지막 글자를 삭제합니다.
    ///
    /// 1. 오토마타를 통해 삭제를 수행합니다.
    /// 2. [종성 복원] 삭제 후 남은 마지막 글자가 '자음'이고, 앞 글자의 받침으로 들어갈 수 있다면 합칩니다.
    ///    예: '갈가' -> Delete -> '갈ㄱ' -> '갉'
    func delete(beforeText: String) -> String {
        // 1. 기본 오토마타 삭제 수행
        let deletedText = automata.delete글자(beforeText: beforeText)
        
        // 텍스트가 2글자 미만이면 결합할 대상이 없으므로 반환
        if deletedText.count < 2 { return deletedText }
        
        // 2. 분리 (Prefix + LastChar)
        let lastIndex = deletedText.index(before: deletedText.endIndex)
        let lastChar = deletedText[lastIndex]
        let lastCharString = String(lastChar)
        let prefixText = String(deletedText[..<lastIndex])
        
        // 남은 마지막 글자가 실제로 '종성(받침)'으로 쓰일 수 있는 자음인지 확인합니다.
        guard automata.종성Table.contains(lastCharString) && lastCharString != " " else {
            return deletedText
        }
        
        // 3. 결합 시도
        // 앞 글자(Prefix)에 자음(LastChar)을 더해봅니다.
        let mergedText = automata.add글자(글자Input: lastCharString, beforeText: prefixText)
        
        // 4. 병합 성공 확인
        // 두 글자가 한 글자로 합쳐졌다면(길이가 줄어들었다면) 성공으로 간주
        if mergedText.count < deletedText.count {
            return mergedText
        }
        
        return deletedText
    }
    
    /// 두벌식은 별도의 조합 상태 플래그를 관리하지 않으므로 빈 구현으로 둡니다.
    func reset한글조합() {}
}
