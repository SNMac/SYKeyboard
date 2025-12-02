//
//  CheonjiinProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/2/25.
//

/// 천지인 입력기
final class CheonjiinProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    /// 천지인 'ㆍ' (아래아) 문자
    private let 아래아문자 = "ㆍ"
    
    /// 자음 순환 테이블 (멀티탭)
    /// 예: ㄱ을 계속 누르면 ㄱ -> ㅋ -> ㄲ -> ㄱ 순서로 변경
    private let 자음CycleTable: [String: [String]] = [
        "ㄱ": ["ㄱ", "ㅋ", "ㄲ"],
        "ㄴ": ["ㄴ", "ㄹ"],
        "ㄷ": ["ㄷ", "ㅌ", "ㄸ"],
        "ㅂ": ["ㅂ", "ㅍ", "ㅃ"],
        "ㅅ": ["ㅅ", "ㅎ", "ㅆ"],
        "ㅈ": ["ㅈ", "ㅊ", "ㅉ"],
        "ㅇ": ["ㅇ", "ㅁ"]
    ]
    
    // MARK: - Delegate Methods
    
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        
        // 1. 자음 입력 처리 (순환 로직)
        if is자음(글자Input) {
            // 이전 글자와 비교하여 순환 가능한지 확인
            if let cycledText = cycle자음(글자input: 글자Input, beforeText: beforeText) {
                return (cycledText, 글자Input)
            }
        }
        
        // 2. 모음 입력 처리 (천지인 조합 로직)
        if is모음(글자Input) || 글자Input == 아래아문자 {
            if let combinedText = combine모음(글자input: 글자Input, beforeText: beforeText) {
                return (combinedText, 글자Input)
            }
        }
        
        // 3. 특수 규칙에 해당하지 않으면 표준 오토마타로 처리
        let processedText = automata.add글자(글자Input: 글자Input, beforeText: beforeText)
        return (processedText, 글자Input)
    }
    
    func delete(beforeText: String) -> String {
        guard beforeText.last != nil else { return beforeText }
        
        // 표준 오토마타 삭제 로직을 수행합니다.
        // 결과: '가' -> 'ㄱ', 'ㅑ' -> 삭제됨 (종성이 없으면 중성 전체 삭제)
        return automata.delete글자(beforeText: beforeText)
    }
}

// MARK: - Private Methods

private extension CheonjiinProcessor {
    
    func is자음(_ input: String) -> Bool {
        return automata.초성Table.contains(input)
    }
    
    func is모음(_ input: String) -> Bool {
        return input == "ㅡ" || input == "ㅣ" || input == 아래아문자
    }
    
    /// 자음 입력 시 순환(ㄱ -> ㅋ -> ㄲ) 처리
    func cycle자음(글자input: String, beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        guard let cycleGroup = 자음CycleTable[글자input] else { return nil }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글인 경우 (종성 순환)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            // 종성이 있는 경우
            if 종성Index != 0 {
                let current종성 = automata.종성Table[종성Index]
                
                // 현재 종성이 입력된 키의 순환 그룹에 포함되는지 확인
                // (주의: 종성 테이블과 초성 테이블의 문자가 같더라도 인덱스는 다름)
                if cycleGroup.contains(current종성) {
                    let next종성 = getNextCycle문자(current: current종성, group: cycleGroup)
                    
                    // 순환된 문자가 종성 테이블에 존재하는지 확인
                    if let next종성Index = automata.종성Table.firstIndex(of: next종성),
                       let newChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: next종성Index) {
                        return newText + String(newChar)
                    }
                }
            } else {
                // 종성이 없는 경우
                // (새로 종성을 추가할지, 다음 글자로 갈지는 input()의 add글자가 처리하지만, 여기서는 순환이 아니므로 nil을 반환하여 add글자로 넘김)
                return nil
            }
        }
        // 2. 낱자 자음인 경우 (초성 순환)
        else {
            let lastString = String(beforeTextLast글자Char)
            if cycleGroup.contains(lastString) {
                let nextChar = getNextCycle문자(current: lastString, group: cycleGroup)
                return newText + nextChar
            }
        }
        
        return nil
    }
    
    /// 순환 그룹에서 다음 문자를 가져옴
    func getNextCycle문자(current: String, group: [String]) -> String {
        if let index = group.firstIndex(of: current) {
            let nextIndex = (index + 1) % group.count
            return group[nextIndex]
        }
        return current
    }
    
    /// 천지인 모음 조합 처리
    func combine모음(글자input: String, beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        var newText = beforeText
        
        // 마지막 글자 분해
        let decomposed = automata.decompose(한글Char: beforeTextLast글자Char)
        let has종성 = (decomposed?.종성Index ?? 0) != 0
        
        // 종성이 있으면 모음 조합 불가 (새로운 글자의 시작으로 처리해야 함 -> nil 반환)
        if has종성 { return nil }
        
        // 현재 중성(모음) 가져오기
        var current모음: String?
        if let (_, 중성Index, _) = decomposed {
            current모음 = automata.중성Table[중성Index]
        } else if automata.중성Table.contains(String(beforeTextLast글자Char)) || String(beforeTextLast글자Char) == 아래아문자 {
            current모음 = String(beforeTextLast글자Char)
        }
        
        guard let target모음 = current모음 else { return nil }
        
        // 조합 결과 계산
        var next모음: String?
        
        // [천지인 공식]
        // 1. ㅣ + ㆍ = ㅏ
        // 2. ㆍ + ㅣ = ㅓ
        // 3. ㅡ + ㆍ = ㅜ
        // 4. ㆍ + ㅡ = ㅗ
        // 5. ㅏ + ㆍ = ㅑ
        // 6. ㅓ + ㆍ = ㅕ
        // 7. ㅜ + ㆍ = ㅠ
        // 8. ㅗ + ㆍ = ㅛ
        
        switch (target모음, 글자input) {
        case ("ㅣ", 아래아문자): next모음 = "ㅏ"
        case (아래아문자, "ㅣ"): next모음 = "ㅓ"
        case ("ㅡ", 아래아문자): next모음 = "ㅜ"
        case (아래아문자, "ㅡ"): next모음 = "ㅗ"
            
        case ("ㅏ", 아래아문자): next모음 = "ㅑ"
        case ("ㅓ", 아래아문자): next모음 = "ㅕ"
        case ("ㅜ", 아래아문자): next모음 = "ㅠ"
        case ("ㅗ", 아래아문자): next모음 = "ㅛ"
            
            // 예외: ㅡ + ㅣ = ㅢ (천지인에서도 지원하는 경우가 많음)
        case ("ㅡ", "ㅣ"): next모음 = "ㅢ"
            
        default: return nil
        }
        
        guard let result모음 = next모음 else { return nil }
        
        // 결과 적용
        newText.removeLast()
        
        // 1. 완성형 한글이었던 경우 업데이트
        if let (초성Index, _, _) = decomposed,
           let new모음Index = automata.중성Table.firstIndex(of: result모음),
           let newChar = automata.combine(초성Index: 초성Index, 중성Index: new모음Index, 종성Index: 0) {
            return newText + String(newChar)
        }
        // 2. 낱자였던 경우 교체
        else {
            return newText + result모음
        }
    }
    
    /// 천지인 모음 역분해 (삭제 시 동작)
    func decompose모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        var newText = beforeText
        
        // 마지막 글자 분석
        let decomposed = automata.decompose(한글Char: beforeTextLast글자Char)
        
        // 종성이 있으면 표준 삭제(종성 지우기)로 위임
        if let (_, _, 종성Index) = decomposed, 종성Index != 0 {
            return nil
        }
        
        // 현재 모음 추출
        var current모음: String?
        if let (_, 중성Index, _) = decomposed {
            current모음 = automata.중성Table[중성Index]
        } else if automata.중성Table.contains(String(beforeTextLast글자Char)) {
            current모음 = String(beforeTextLast글자Char)
        }
        
        guard let target모음 = current모음 else { return nil }
        
        // 역분해 로직 (생성의 역순)
        var prev모음: String?
        
        switch target모음 {
        case "ㅑ": prev모음 = "ㅏ"
        case "ㅕ": prev모음 = "ㅓ"
        case "ㅠ": prev모음 = "ㅜ"
        case "ㅛ": prev모음 = "ㅗ"
            
        case "ㅏ": prev모음 = "ㅣ"
        case "ㅓ": prev모음 = 아래아문자
        case "ㅜ": prev모음 = "ㅡ"
        case "ㅗ": prev모음 = 아래아문자 // 혹은 'ㅡ' (순서에 따라 다르나 보통 ㆍ + ㅡ = ㅗ 이므로 ㆍ를 남김)
            
        case "ㅢ": prev모음 = "ㅡ"
            
        default: return nil // 분해할 수 없는 단모음 등은 표준 삭제로 위임
        }
        
        guard let result모음 = prev모음 else { return nil }
        
        newText.removeLast()
        
        // 1. 완성형 한글 업데이트
        if let (초성Index, _, _) = decomposed {
            // 결과가 'ㆍ'인 경우 완성형 한글이 깨짐 (초성 + ㆍ 형태는 표준 유니코드 완성형 아님)
            if result모음 == 아래아문자 {
                // 초성만 남기고 'ㆍ'는 따로 분리하거나, 그냥 초성만 남김.
                // 여기서는 직관적으로 'ㆍ'를 제거한 셈 치고 초성만 복원 (표준 삭제와 유사 효과)
                // 하지만 천지인 특성상 'ㆍ' 단계로 돌아가는 것을 보여주려면 분리해야 함
                // 예: '고' -> delete -> 'ㄱ' + 'ㆍ'
                // TODO: ᆢ
                newText.append(automata.초성Table[초성Index])
                newText.append(아래아문자)
                return newText
            }
            
            if let new모음Index = automata.중성Table.firstIndex(of: result모음),
               let newChar = automata.combine(초성Index: 초성Index, 중성Index: new모음Index, 종성Index: 0) {
                return newText + String(newChar)
            }
        }
        // 2. 낱자 교체
        else {
            return newText + result모음
        }
        
        return nil
    }
}
