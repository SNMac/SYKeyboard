//
//  CheonjiinProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/2/25.
//

/// 천지인 입력기
///
/// 천지인 방식의 입력을 처리합니다.
/// - **특징**:
///   1. **자음 순환**: 버튼 반복 입력 시 자음이 순환합니다 (예: ㄱ -> ㅋ -> ㄲ).
///   2. **모음 조합**: 천(ㆍ), 지(ㅡ), 인(ㅣ) 3개 키의 조합으로 모음을 생성합니다.
///   3. **스페이스**: 조합 중일 땐 글자 확정(Commit), 아닐 땐 띄어쓰기를 수행합니다.
final class CheonjiinProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    /// 현재 한글 조합(순환 또는 모음 조합)이 진행 중인지 여부
    var is한글조합OnGoing: Bool = false
    
    /// 표준 한글 오토마타 (자소 합치기/나누기 담당)
    private let automata: HangeulAutomataProtocol
    
    /// 자음 순환 테이블
    private let 자음순환Table: [String: [String]] = [
        "ㄱ": ["ㄱ", "ㅋ", "ㄲ"],
        "ㄴ": ["ㄴ", "ㄹ"],
        "ㄷ": ["ㄷ", "ㅌ", "ㄸ"],
        "ㅂ": ["ㅂ", "ㅍ", "ㅃ"],
        "ㅅ": ["ㅅ", "ㅎ", "ㅆ"],
        "ㅈ": ["ㅈ", "ㅊ", "ㅉ"],
        "ㅇ": ["ㅇ", "ㅁ"]
    ]
    
    /// 천지인 모음 조합 테이블
    private let 모음조합Table: [String: [String: String]] = [
        "ㅣ": ["ㆍ": "ㅏ"],
        "ㅏ": ["ㆍ": "ㅑ", "ㅣ": "ㅐ"],
        "ㅑ": ["ㅣ": "ㅒ", "ㆍ": "ㅏ"],
        "ㅐ": ["ㆍ": "ㅒ"],
        "ㆍ": ["ㆍ": "ᆢ", "ㅣ": "ㅓ", "ㅡ": "ㅗ"],
        "ᆢ": ["ㆍ": "ㆍ", "ㅣ": "ㅕ", "ㅡ": "ㅛ"],
        "ㅓ": ["ㆍ": "ㅕ", "ㅣ": "ㅔ"],
        "ㅕ": ["ㅣ": "ㅖ"],
        "ㅔ": ["ㆍ": "ㅖ"],
        "ㅡ": ["ㆍ": "ㅜ", "ㅣ": "ㅢ"],
        "ㅜ": ["ㆍ": "ㅠ", "ㅣ": "ㅟ", "ㅓ": "ㅝ", "ㅔ": "ㅞ"],
        "ㅠ": ["ㅣ": "ㅝ", "ㆍ": "ㅜ"],
        "ㅗ": ["ㅣ": "ㅚ", "ㅏ": "ㅘ", "ㅐ": "ㅙ"],
        "ㅚ": ["ㆍ": "ㅘ"],
        "ㅘ": ["ㅣ": "ㅙ"],
        "ㅝ": ["ㅣ": "ㅞ"]
    ]
    
    init(automata: HangeulAutomataProtocol) {
        self.automata = automata
    }
    
    // MARK: - Protocol Implementation
    
    func input(글자Input: String, composing: String) -> CompositionResult {
        let is천지인모음 = ["ㆍ", "ㅡ", "ㅣ"].contains(글자Input)
        let is천지인자음 = 자음순환Table.keys.contains(글자Input)
        
        // [비한글 입력 처리]
        if !is천지인모음 && !is천지인자음 {
            is한글조합OnGoing = false
            return .commitAll(composing + 글자Input, input글자: 글자Input)
        }
        
        // [확정 상태 체크]
        if !is한글조합OnGoing {
            is한글조합OnGoing = true
            return CompositionResult(committed: composing, composing: 글자Input, input글자: 글자Input)
        }
        
        // 1. [모음 입력] (ㆍ, ㅡ, ㅣ)
        if is천지인모음 {
            
            // A. 모음 조합 시도
            if let (prefix, combined모음) = tryCombine모음(input: 글자Input, composing: composing) {
                // prefix에 자음이나 완성형 한글이 남아있을 수 있으므로
                // 오토마타가 결합하게 함 (예: "닭" 뒤의 "ㆍ"+"ㅣ"="ㅓ" → "달"+"거" 연음)
                let is표준중성 = automata.중성Table.contains(combined모음)
                
                if is표준중성 {
                    // 표준 모음 → 오토마타에 위임 (연음 가능)
                    let (committed, newComposing) = automata.add글자(글자Input: combined모음, composing: prefix)
                    is한글조합OnGoing = true
                    
                    var nextRepeatChar = combined모음
                    switch combined모음 {
                    case "ㅘ": nextRepeatChar = "ㅏ"
                    case "ㅝ": nextRepeatChar = "ㅓ"
                    case "ㅙ": nextRepeatChar = "ㅐ"
                    case "ㅞ": nextRepeatChar = "ㅔ"
                    default: break
                    }
                    return CompositionResult(committed: committed, composing: newComposing, input글자: nextRepeatChar)
                } else {
                    // 비표준 모음 (ㆍ, ᆢ 등) → composing에 직접 붙임
                    is한글조합OnGoing = true
                    return .composingOnly(prefix + combined모음, input글자: combined모음)
                }
            }
            
            // B. 모음 단순 추가 (조합 실패)
            let is표준중성 = automata.중성Table.contains(글자Input)
            if is표준중성 {
                // 표준 모음(ㅣ, ㅡ) → 오토마타에 위임 (자음+모음 결합, 연음 가능)
                let (committed, newComposing) = automata.add글자(글자Input: 글자Input, composing: composing)
                is한글조합OnGoing = true
                return CompositionResult(committed: committed, composing: newComposing, input글자: 글자Input)
            } else {
                // 천지인 특수문자(ㆍ) → composing에 이어붙여서 다음 tryCombine모음에서 조합
                is한글조합OnGoing = true
                return .composingOnly(composing + 글자Input, input글자: 글자Input)
            }
        }
        
        // 2. [자음 입력]
        else {
            // 자음 순환
            if let cycleList = 자음순환Table[글자Input] {
                return cycle자음(inputKey: 글자Input, cycleList: cycleList, composing: composing)
            }
            
            // C. 순환 불가능 자음 추가
            let (committed, newComposing) = automata.add글자(글자Input: 글자Input, composing: composing)
            is한글조합OnGoing = true
            return CompositionResult(committed: committed, composing: newComposing, input글자: 글자Input)
        }
    }
    
    func inputSpace(composing: String) -> SpaceInputResult {
        if is한글조합OnGoing {
            reset한글조합()
            return .commitCombination
        } else {
            return .insertSpace
        }
    }
    
    func delete(composing: String) -> String {
        guard !composing.isEmpty else {
            is한글조합OnGoing = false
            return ""
        }
        
        // 마지막 글자가 천지인 특수문자(ㆍ, ᆢ)이면 직접 제거
        if let lastChar = composing.last {
            let lastCharString = String(lastChar)
            if lastCharString == "ㆍ" || lastCharString == "ᆢ" {
                let result = String(composing.dropLast())
                if result.isEmpty {
                    is한글조합OnGoing = false
                }
                return result
            }
        }
        
        // 오토마타를 이용한 기본 삭제
        let deletedText = automata.delete글자(composing: composing)
        
        if deletedText.isEmpty {
            is한글조합OnGoing = false
        } else {
            is한글조합OnGoing = true
        }
        
        // 종성 복원 로직: 삭제 후 남은 자음이 앞 글자의 받침이 될 수 있는지 확인
        if let lastChar = deletedText.last {
            let lastCharString = String(lastChar)
            
            if automata.종성Table.contains(lastCharString) && lastCharString != " " {
                let prefix = String(deletedText.dropLast())
                
                if let prefixLast = prefix.last,
                   let _ = automata.decompose(한글Char: prefixLast) {
                    let (committed, merged) = automata.add글자(글자Input: lastCharString, composing: prefix)
                    let restoredText = committed + merged
                    is한글조합OnGoing = true
                    return restoredText
                }
            }
        }
        
        return deletedText
    }
    
    func reset한글조합() {
        is한글조합OnGoing = false
    }
}

// MARK: - Private Methods

private extension CheonjiinProcessor {
    
    /// 모음 조합 로직
    func tryCombine모음(input: String, composing: String) -> (String, String)? {
        guard let lastChar = composing.last else { return nil }
        let lastCharString = String(lastChar)
        let prefixText = String(composing.dropLast())
        
        // 1. 단순 모음/특수문자 조합
        if let targetDict = 모음조합Table[lastCharString],
           let combined모음 = targetDict[input] {
            return (prefixText, combined모음)
        }
        
        // 2. 완성형 글자 내부 중성 조합
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar), 종성Index == 0 {
            let current모음 = automata.중성Table[중성Index]
            
            if let targetDict = 모음조합Table[current모음],
               let combined모음 = targetDict[input] {
                let 초성Char = automata.초성Table[초성Index]
                return (prefixText + 초성Char, combined모음)
            }
        }
        
        return nil
    }
    
    /// 자음 순환 로직
    func cycle자음(inputKey: String, cycleList: [String], composing: String) -> CompositionResult {
        guard !composing.isEmpty else {
            is한글조합OnGoing = true
            return .composingOnly(inputKey, input글자: inputKey)
        }
        
        let lastChar = composing.last!
        let lastCharString = String(lastChar)
        let basePrefix = String(composing.dropLast())
        
        var baseText = ""
        var targetCharString = ""
        
        // A. 낱자 순환
        if cycleList.contains(lastCharString) {
            baseText = basePrefix
            targetCharString = lastCharString
        }
        // B. 종성 순환
        else if let (초, 중, 종) = automata.decompose(한글Char: lastChar), 종 != 0 {
            let current종성 = automata.종성Table[종]
            
            if cycleList.contains(current종성) {
                if let baseChar = automata.combine(초성Index: 초, 중성Index: 중, 종성Index: 0) {
                    baseText = basePrefix + String(baseChar)
                }
                targetCharString = current종성
            }
            else if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: current종성),
                    cycleList.contains(뒷받침) {
                if let 앞받침Idx = automata.종성Table.firstIndex(of: 앞받침),
                   let baseChar = automata.combine(초성Index: 초, 중성Index: 중, 종성Index: 앞받침Idx) {
                    baseText = basePrefix + String(baseChar)
                    targetCharString = 뒷받침
                }
            }
        }
        
        // 순환 대상 없음 -> 그냥 추가
        if targetCharString.isEmpty {
            let (committed, newComposing) = automata.add글자(글자Input: inputKey, composing: composing)
            is한글조합OnGoing = true
            return CompositionResult(committed: committed, composing: newComposing, input글자: inputKey)
        }
        
        // 다음 글자 계산
        guard let currentIndex = cycleList.firstIndex(of: targetCharString) else {
            return .composingOnly(composing)
        }
        let nextIndex = (currentIndex + 1) % cycleList.count
        let nextChar = cycleList[nextIndex]
        
        // baseText에서만 결합 시도
        let (committed, newComposing) = automata.add글자(글자Input: nextChar, composing: baseText)
        
        is한글조합OnGoing = true
        return CompositionResult(committed: committed, composing: newComposing, input글자: nextChar)
    }
}
