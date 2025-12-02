//
//  CheonjiinProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/2/25.
//

/// 천지인 입력기 프로세서
///
/// 천지인 키보드 방식(10키)의 입력을 처리합니다.
/// - **특징**:
///   1. **모음 조합**: 천(ㆍ), 지(ㅡ), 인(ㅣ) 3개의 키 조합으로 모든 모음을 생성합니다.
///   2. **자음 멀티탭**: 하나의 키를 여러 번 눌러 자음을 순환시킵니다 (예: ㄱ -> ㅋ -> ㄲ).
///   3. **조합 끊기**: 스페이스바를 통해 현재 조합 중인 글자를 확정하고 다음 글자로 넘어갑니다.
final class CheonjiinProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    /// 표준 한글 오토마타 (자소 분해/조합 담당)
    ///
    /// 천지인 특유의 로직(순환, 특수 조합)을 거친 후, 최종적인 한글 조립은 이 오토마타에게 위임합니다.
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    /// 조합 끊기 대기 상태 플래그
    ///
    /// `true`일 경우, 다음 입력은 앞 글자와 결합되지 않고 새로운 글자로 시작됩니다.
    /// 스페이스바를 눌렀을 때 활성화됩니다.
    private var is한글조합Stopped: Bool = false
    
    /// 천지인 'ㆍ' (아래아) 문자
    private let 아래아문자 = "ㆍ"
    
    /// 천지인 'ᆢ' (쌍아래아) 문자
    ///
    /// 'ㆍ'을 두 번 연속 입력했을 때 생성되는 특수 상태입니다.
    /// - 예: `ㆍ` + `ㆍ` = `ᆢ`
    /// - 예: `ᆢ` + `ㅣ` = `ㅕ`
    /// - 예: `ᆢ` + `ㅡ` = `ㅛ`
    private let 쌍아래아문자 = "ᆢ"
    
    /// 자음 순환 테이블 (멀티탭)
    ///
    /// 동일한 자음 키를 연속으로 입력했을 때 변환될 순서를 정의합니다.
    /// - Key: 현재 입력된 자음
    /// - Value: 순환될 자음 목록 (예: ["ㄱ", "ㅋ", "ㄲ"])
    private let 자음CycleTable: [String: [String]] = [
        "ㄱ": ["ㄱ", "ㅋ", "ㄲ"],
        "ㄴ": ["ㄴ", "ㄹ"],
        "ㄷ": ["ㄷ", "ㅌ", "ㄸ"],
        "ㅂ": ["ㅂ", "ㅍ", "ㅃ"],
        "ㅅ": ["ㅅ", "ㅎ", "ㅆ"],
        "ㅈ": ["ㅈ", "ㅊ", "ㅉ"],
        "ㅇ": ["ㅇ", "ㅁ"]
    ]
    
    /// 겹받침 조합 테이블
    ///
    /// 자음 순환 후, 변환된 자음이 앞 글자의 받침과 결합하여 겹받침을 형성할 수 있는지 확인할 때 사용합니다.
    /// - 구성: (앞받침, 뒷받침, 결과)
    private let 겹자음조합Table: [(String, String, String)] = [
        ("ㄱ", "ㅅ", "ㄳ"), ("ㄴ", "ㅈ", "ㄵ"), ("ㄴ", "ㅎ", "ㄶ"),
        ("ㄹ", "ㄱ", "ㄺ"), ("ㄹ", "ㅁ", "ㄻ"), ("ㄹ", "ㅂ", "ㄼ"),
        ("ㄹ", "ㅅ", "ㄽ"), ("ㄹ", "ㅌ", "ㄾ"), ("ㄹ", "ㅍ", "ㄿ"),
        ("ㄹ", "ㅎ", "ㅀ"), ("ㅂ", "ㅅ", "ㅄ")
    ]
    
    /// 모음 삭제 시 역분해를 위한 매핑 테이블
    ///
    /// `delete` 호출 시 복합 모음을 분해하여 이전 단계로 되돌리기 위해 사용합니다.
    ///
    /// - Note: **기본 모음(ㅏ, ㅑ, ㅗ, ㅛ, ㅜ, ㅠ 등)은 이 테이블에 포함되지 않습니다.**
    ///         테이블에 없는 모음은 삭제 시 분해되지 않고 한 번에 지워집니다 (통째 삭제).
    private var 모음역분해Table: [String: String] {
        [
            // [3차 조합 분해] ㅙ -> ㅘ, ㅞ -> ㅝ
            "ㅙ": "ㅘ", "ㅞ": "ㅝ",
            
            // [2차 조합 분해] 복합 모음 분해
            "ㅘ": "ㅗ", "ㅝ": "ㅜ",
            "ㅚ": "ㅗ", "ㅟ": "ㅜ",
            "ㅢ": "ㅡ",
            
            // [ㅣ 결합 모음 분해]
            "ㅐ": "ㅏ", "ㅔ": "ㅓ",
            "ㅒ": "ㅑ", "ㅖ": "ㅕ",
            
            // [특수 문자] 쌍아래아 분해
            쌍아래아문자: 아래아문자 // ㆍ + ㆍ
        ]
    }
    
    // MARK: - Delegate Methods
    
    /// 사용자의 입력을 처리하여 변환된 텍스트를 반환합니다.
    ///
    /// 1. **조합 끊기 확인**: `is한글조합Stopped`가 참이면 결합 없이 문자를 추가합니다.
    /// 2. **자음 입력**: 자음 순환(멀티탭) 및 겹받침 결합을 시도합니다.
    /// 3. **모음 입력**: 천지인 모음 조합 규칙(ㆍ, ㅡ, ㅣ)을 적용합니다.
    /// 4. **기타**: 위 로직에 해당하지 않으면 표준 오토마타(`add글자`)를 통해 처리합니다.
    ///
    /// - Parameters:
    ///   - 글자Input: 입력된 글자 (자음, 모음, 또는 'ㆍ')
    ///   - beforeText: 현재까지 입력된 전체 텍스트
    /// - Returns: (처리된 전체 텍스트, 화면에 표시할 입력 글자)
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        
        // [0] 조합 끊기 상태 처리
        // 스페이스바 직후에는 오토마타 결합을 하지 않고 단순 추가합니다.
        // 예: '학' + (Space) + 'ㄱ' -> '학ㄱ' (학교 입력 시나리오)
        if is한글조합Stopped {
            is한글조합Stopped = false // 상태 초기화
            return (beforeText + 글자Input, 글자Input)
        }
        
        // [1] 자음 입력 처리
        if is자음(글자Input) {
            // 자음 순환 시도 (예: ㄱ 입력 시 ㄱ->ㅋ->ㄲ)
            if let cycledText = cycle자음(글자input: 글자Input, beforeText: beforeText) {
                // 순환된 자음이 앞 글자의 받침과 결합 가능한지 확인 (예: 흴+ㅁ -> 흶)
                let mergedText = try종성결합(text: cycledText)
                return (mergedText, 글자Input)
            }
        }
        
        // [2] 모음 입력 처리
        if is모음(글자Input) || 글자Input == 아래아문자 {
            // 천지인 모음 조합 시도 (예: ㆍ+ㅣ -> ㅓ, ᆢ+ㅡ -> ㅛ)
            if let combinedText = combine모음(글자input: 글자Input, beforeText: beforeText) {
                return (combinedText, 글자Input)
            }
        }
        
        // [3] 표준 오토마타 처리 (새로운 글자 추가 또는 일반 결합)
        let processedText = automata.add글자(글자Input: 글자Input, beforeText: beforeText)
        return (processedText, 글자Input)
    }
    
    /// 스페이스바 입력을 처리합니다.
    ///
    /// - Returns:
    ///   - `.commitCombination`: 텍스트가 있는 경우, 조합을 확정하고 끊습니다. (실제 공백 입력 안 함)
    ///   - `.insertSpace`: 텍스트가 없거나 이미 끊긴 경우, 실제 공백을 입력합니다.
    func inputSpace(beforeText: String) -> SpaceInputResult {
        if !beforeText.isEmpty {
            // 버퍼에 글자가 있으면 -> 조합 끊기 모드 진입
            is한글조합Stopped = true
            return .commitCombination
        } else {
            // 버퍼가 없으면 -> 실제 공백 입력
            is한글조합Stopped = false
            return .insertSpace
        }
    }
    
    /// 마지막 글자를 삭제하거나 분해합니다.
    ///
    /// - **복합 모음**(ㅘ, ㅢ, ㅐ 등): 역순으로 분해됩니다. (예: 의 -> 으, 와 -> 오)
    /// - **기본 모음**(ㅏ, ㅑ, ㅗ 등) & **받침**: 한 번에 삭제됩니다. (예: 가 -> ㄱ, 각 -> 가)
    ///
    ///
    func delete(beforeText: String) -> String {
        guard let lastChar = beforeText.last else { return beforeText }
        var newText = beforeText
        
        // 1. 완성형 한글인 경우 분해 시도
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            
            // 1-1. 종성이 있는 경우: 표준 오토마타 삭제 (받침 삭제)
            // 예: '각' -> '가'
            if 종성Index != 0 {
                return automata.delete글자(beforeText: beforeText)
            }
            
            // 1-2. 종성이 없고 중성이 있는 경우: 모음 역분해 시도
            let current모음 = automata.중성Table[중성Index]
            
            // 역분해 테이블에 있는 복합 모음인 경우 (예: '의' -> '으')
            if let prev모음 = 모음역분해Table[current모음] {
                newText.removeLast()
                
                // 분해된 모음으로 재조립
                if let new모음Index = automata.중성Table.firstIndex(of: prev모음),
                   let newChar = automata.combine(초성Index: 초성Index, 중성Index: new모음Index, 종성Index: 0) {
                    newText.append(newChar) // 완성형 유지 (예: 의 -> 으)
                } else {
                    // 표준 중성이 아닌 경우(예: 'ᆢ') 자음+모음으로 분리
                    let 초성 = automata.초성Table[초성Index]
                    newText.append(초성)
                    newText.append(prev모음)
                }
                return newText
            } else {
                // [통째 삭제] 테이블에 없는 기본 모음(ㅏ, ㅑ 등)은 중성 자체를 삭제
                // 예: '가' -> 'ㄱ'
                newText.removeLast()
                newText.append(automata.초성Table[초성Index])
                return newText
            }
        }
        
        // 2. 낱자 모음/자음인 경우
        let lastString = String(lastChar)
        newText.removeLast()
        
        // 낱자 상태에서도 분해 가능한지 확인 (예: ㅢ -> ㅡ)
        if let prev모음 = 모음역분해Table[lastString] {
            newText.append(prev모음)
            return newText
        }
        
        // 분해 불가 시 삭제된 상태 반환
        return newText
    }
}

// MARK: - Private Methods

private extension CheonjiinProcessor {
    
    // MARK: - Helper Checks
    
    func is자음(_ input: String) -> Bool {
        return automata.초성Table.contains(input)
    }
    
    func is모음(_ input: String) -> Bool {
        return input == "ㅡ" || input == "ㅣ" || input == 아래아문자 || input == 쌍아래아문자
    }
    
    // MARK: - Logic Implementation
    
    /// 순환된 자음이 앞 글자의 받침과 합쳐질 수 있는지 확인하고 처리합니다.
    ///
    /// - 예: '흴'(ㄹ) 상태에서 'ㅁ' 입력 -> '흶'(ㄻ)
    /// - 예: '흷'(ㄼ) 상태에서 'ㅂ' -> 'ㅍ'(순환) -> '흺'(ㄿ) (교체)
    func try종성결합(text: String) -> String {
        guard text.count >= 2 else { return text }
        
        let lastIndex = text.index(before: text.endIndex)
        let prevIndex = text.index(before: lastIndex)
        
        let lastChar = text[lastIndex] // 순환된 자음 (예: "ㅁ" 또는 "ㅍ")
        let prevChar = text[prevIndex] // 앞 글자 (예: "흴" 또는 "흷")
        
        let lastString = String(lastChar)
        
        // 마지막 글자가 낱자 자음이어야 결합 시도 가능
        guard automata.초성Table.contains(lastString) else { return text }
        
        // 앞 글자가 완성형 한글이고 종성이 있어야 함
        guard let (초성Idx, 중성Idx, 종성Idx) = automata.decompose(한글Char: prevChar),
              종성Idx != 0 else { return text }
        
        let current종성 = automata.종성Table[종성Idx]
        
        // Case A: 홑받침 + 자음 -> 겹받침 (예: 흴(ㄹ) + ㅁ -> 흶(ㄻ))
        if let combined종성 = findCombinable종성(앞받침: current종성, 뒷받침: lastString),
           let new종성Index = automata.종성Table.firstIndex(of: combined종성),
           let newChar = automata.combine(초성Index: 초성Idx, 중성Index: 중성Idx, 종성Index: new종성Index) {
            
            var newText = text
            newText.removeLast() // 자음 제거
            newText.removeLast() // 앞 글자 제거
            newText.append(newChar)
            return newText
        }
        
        // Case B: 겹받침 + 자음 -> 겹받침 교체 (예: 흷(ㄹㅂ) + ㅍ -> 흺(ㄹㅍ))
        // 기존 겹받침(ㄼ)을 분해하여 앞부분(ㄹ)과 새로운 자음(ㅍ)의 결합을 시도
        if let (앞받침, _) = automata.decompose겹받침(종성: current종성) {
            if let combined종성 = findCombinable종성(앞받침: 앞받침, 뒷받침: lastString),
               let new종성Index = automata.종성Table.firstIndex(of: combined종성),
               let newChar = automata.combine(초성Index: 초성Idx, 중성Index: 중성Idx, 종성Index: new종성Index) {
                
                var newText = text
                newText.removeLast()
                newText.removeLast()
                newText.append(newChar)
                return newText
            }
        }
        
        return text
    }
    
    /// 두 자음이 겹받침으로 결합될 수 있는지 테이블에서 확인합니다.
    func findCombinable종성(앞받침: String, 뒷받침: String) -> String? {
        for (f, s, result) in 겹자음조합Table {
            if f == 앞받침 && s == 뒷받침 { return result }
        }
        return nil
    }
    
    /// 자음 입력 시 순환(멀티탭)을 처리합니다.
    ///
    /// - 예: 'ㄱ' 입력 시 'ㄱ' -> 'ㅋ' -> 'ㄲ' -> 'ㄱ' 순서로 변환
    /// - 특징: 겹받침의 뒷부분 순환도 처리합니다 (예: ㄼ + ㅂ -> ㄿ).
    func cycle자음(글자input: String, beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        guard let cycleGroup = 자음CycleTable[글자input] else { return nil }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글 (종성 순환)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index != 0 {
                let current종성 = automata.종성Table[종성Index]
                
                // 1-1. 종성 자체가 순환 그룹에 있는 경우 (예: ㄱ -> ㅋ)
                if cycleGroup.contains(current종성) {
                    let next종성 = getNextCycle문자(current: current종성, group: cycleGroup)
                    if let next종성Index = automata.종성Table.firstIndex(of: next종성),
                       let newChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: next종성Index) {
                        return newText + String(newChar)
                    }
                }
                // 1-2. 겹받침의 뒷부분이 순환 그룹에 있는 경우 (예: ㄼ + ㅂ -> ㄿ)
                else if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: current종성) {
                    if cycleGroup.contains(뒷받침) {
                        let next뒷받침 = getNextCycle문자(current: 뒷받침, group: cycleGroup)
                        // 바뀐 뒷받침으로 다시 결합 시도 (예: ㄹ + ㅍ -> ㄿ)
                        if let newCombined종성 = findCombinable종성(앞받침: 앞받침, 뒷받침: next뒷받침),
                           let new종성Index = automata.종성Table.firstIndex(of: newCombined종성),
                           let newChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: new종성Index) {
                            return newText + String(newChar)
                        }
                    }
                }
            } else { return nil } // 종성이 없으면 순환 불가 (input 메서드에서 add글자로 처리)
        }
        // 2. 낱자 자음 (초성 순환)
        else {
            let lastString = String(beforeTextLast글자Char)
            if cycleGroup.contains(lastString) {
                let nextChar = getNextCycle문자(current: lastString, group: cycleGroup)
                return newText + nextChar
            }
        }
        return nil
    }
    
    /// 순환 그룹에서 다음 문자를 가져옵니다.
    func getNextCycle문자(current: String, group: [String]) -> String {
        if let index = group.firstIndex(of: current) {
            let nextIndex = (index + 1) % group.count
            return group[nextIndex]
        }
        return current
    }
    
    /// 천지인 모음 조합 규칙에 따라 모음을 변환합니다.
    ///
    ///
    /// - 예: `ㆍ`+`ㅣ` -> `ㅓ`
    /// - 예: `ㆍ`+`ㆍ` -> `ᆢ`
    /// - 예: `ᆢ`+`ㅡ` -> `ㅛ` (속기 입력)
    func combine모음(글자input: String, beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        var newText = beforeText
        
        let decomposed = automata.decompose(한글Char: beforeTextLast글자Char)
        let has종성 = (decomposed?.종성Index ?? 0) != 0
        
        // 종성이 있으면 모음 조합 불가
        if has종성 { return nil }
        
        // 현재 중성(모음) 가져오기
        var current모음: String?
        if let (_, 중성Index, _) = decomposed {
            current모음 = automata.중성Table[중성Index]
        } else {
            // 낱자 모음이거나 특수문자(ㆍ, ᆢ)인 경우
            let lastStr = String(beforeTextLast글자Char)
            if automata.중성Table.contains(lastStr) || lastStr == 아래아문자 || lastStr == 쌍아래아문자 {
                current모음 = lastStr
            }
        }
        
        guard let target모음 = current모음 else { return nil }
        
        var next모음: String?
        
        switch (target모음, 글자input) {
        // [1] 기본 천지인 조합 (ㅣ, ㆍ, ㅡ 기반)
        case ("ㅣ", 아래아문자): next모음 = "ㅏ"
        case (아래아문자, "ㅣ"): next모음 = "ㅓ"
        case ("ㅡ", 아래아문자): next모음 = "ㅜ"
        case (아래아문자, "ㅡ"): next모음 = "ㅗ"
            
        // [2] 획 추가 (기본 모음 + ㆍ)
        case ("ㅏ", 아래아문자): next모음 = "ㅑ"
        case ("ㅓ", 아래아문자): next모음 = "ㅕ"
        case ("ㅜ", 아래아문자): next모음 = "ㅠ"
        case ("ㅗ", 아래아문자): next모음 = "ㅛ"
            
        // [3] 쌍아래아(ᆢ) 기반 조합 (속기)
        case (아래아문자, 아래아문자): next모음 = 쌍아래아문자 // ㆍ+ㆍ=ᆢ
        case (쌍아래아문자, "ㅣ"): next모음 = "ㅕ" // ᆢ+ㅣ=ㅕ
        case (쌍아래아문자, "ㅡ"): next모음 = "ㅛ" // ᆢ+ㅡ=ㅛ (교 입력 지원)
        case ("ㅣ", 쌍아래아문자): next모음 = "ㅑ" // ㅣ+ᆢ=ㅑ (대칭)
            
        // [4] 복합 모음 (ㅏ+ㅣ=ㅐ 등)
        case ("ㅏ", "ㅣ"): next모음 = "ㅐ"
        case ("ㅓ", "ㅣ"): next모음 = "ㅔ"
        case ("ㅑ", "ㅣ"): next모음 = "ㅒ"
        case ("ㅕ", "ㅣ"): next모음 = "ㅖ"
            
        case ("ㅠ", "ㅣ"): next모음 = "ㅝ"
        case ("ㅝ", "ㅣ"): next모음 = "ㅞ"
        case ("ㅘ", "ㅣ"): next모음 = "ㅙ"
        case ("ㅜ", "ㅣ"): next모음 = "ㅟ"
        case ("ㅗ", "ㅣ"): next모음 = "ㅚ"
        
        case ("ㅚ", 아래아문자): next모음 = "ㅘ"
        case ("ㅟ", 아래아문자): next모음 = "ㅝ"
            
        // [5] 기타
        case ("ㅡ", "ㅣ"): next모음 = "ㅢ"
        case (쌍아래아문자, 아래아문자): next모음 = 아래아문자 // ᆢ+ㆍ=ㆍ (순환)
            
        default: return nil
        }
        
        guard let result모음 = next모음 else { return nil }
        
        newText.removeLast() // 기존 모음(또는 특수문자) 제거
        
        // 1. 완성형 한글 내에서 변환된 경우 (예: '가' -> '개')
        if let (초성Index, _, _) = decomposed {
            if let new모음Index = automata.중성Table.firstIndex(of: result모음),
               let newChar = automata.combine(초성Index: 초성Index, 중성Index: new모음Index, 종성Index: 0) {
                return newText + String(newChar)
            } else {
                // 표준 중성 테이블에 없는 경우 (예: 'ᆢ') 자음+모음으로 분리
                let 초성 = automata.초성Table[초성Index]
                return newText + 초성 + result모음
            }
        }
        // 2. 낱자 상태였던 경우 (예: 'ㅏ', 'ㆍ', 'ᆢ')
        else {
            // 낱자 모음을 바꾼 뒤, 바로 앞글자가 자음(초성)이라면 합치기 시도
            // 예: "ㄱ" + "ᆢ" 상태에서 "ᆢ"가 "ㅛ"로 바뀌면 -> "ㄱ" + "ㅛ" -> "교"
            if let prevChar = newText.last,
               let 초성Index = automata.초성Table.firstIndex(of: String(prevChar)),
               let new모음Index = automata.중성Table.firstIndex(of: result모음),
               let combinedChar = automata.combine(초성Index: 초성Index, 중성Index: new모음Index, 종성Index: 0) {
                newText.removeLast() // 앞의 자음 제거
                return newText + String(combinedChar) // 합쳐진 글자 반환 ("교")
            }
            // 합칠 자음이 없거나 실패하면 그냥 모음 교체
            return newText + result모음
        }
    }
}
