//
//  CheonjiinProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 12/2/25.
//

/// 천지인 입력기
///
/// 천지인 방식(10키)의 입력을 처리합니다.
/// - **특징**:
///   1. **자음 순환**: 버튼 반복 입력 시 자음이 순환합니다 (예: `ㄱ` -> `ㅋ` -> `ㄲ`).
///   2. **모음 조합**: 천(`ㆍ`), 지(`ㅡ`), 인(`ㅣ`) 3개 키의 조합으로 모음을 생성합니다.
///   3. **스페이스**: 조합 중일 땐 글자 확정(Commit), 아닐 땐 띄어쓰기를 수행합니다.
final class CheonjiinProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    /// 현재 한글 조합(순환 또는 모음 조합)이 진행 중인지 여부
    /// - `true`: 자음 순환 중이거나 모음이 막 입력되어 조합 가능한 상태
    /// - `false`: 스페이스바로 확정되었거나 초기 상태
    var is한글조합OnGoing: Bool = false
    
    /// 조합이 확정된 텍스트의 길이
    ///
    /// 삭제(Backspace) 시 확정된 글자를 보호하고, 종성 복원(합치기) 범위를 제한하는 데 사용됩니다.
    private var committedLength: Int = 0
    
    /// 표준 한글 오토마타 (자소 합치기/나누기 담당)
    private let automata: HangeulAutomataProtocol
    
    /// 자음 순환 테이블
    ///
    /// 키 입력 시 순환될 자음의 순서를 정의합니다.
    /// - Key: 입력 키 (예: "ㄱ")
    /// - Value: 순환 리스트 (예: ["ㄱ", "ㅋ", "ㄲ"])
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
    ///
    /// 현재 상태(마지막 글자)와 입력된 키에 따라 생성될 모음을 정의합니다.
    /// - Key: 현재 마지막 글자 (또는 중성)
    /// - Value: [입력키 : 결과모음]
    private let 모음조합Table: [String: [String: String]] = [
        // ㅣ 계열
        "ㅣ": ["ㆍ": "ㅏ"],
        "ㅏ": ["ㆍ": "ㅑ", "ㅣ": "ㅐ"],
        "ㅑ": ["ㅣ": "ㅒ"],
        "ㅐ": ["ㆍ": "ㅒ"],
        
        // ㆍ(아래아) 계열
        "ㆍ": ["ㆍ": "ᆢ", "ㅣ": "ㅓ", "ㅡ": "ㅗ"],
        
        // ᆢ(쌍아래아) 계열
        // ᆢ + ㅡ = ㅛ (교, 아뇨 등 입력을 위함)
        "ᆢ": ["ㆍ": "ㆍ", "ㅣ": "ㅕ", "ㅡ": "ㅛ"],
        
        // ㅓ 계열
        "ㅓ": ["ㆍ": "ㅕ", "ㅣ": "ㅔ"],
        "ㅕ": ["ㅣ": "ㅖ"],
        "ㅔ": ["ㆍ": "ㅖ"],
        
        // ㅡ 계열
        "ㅡ": ["ㆍ": "ㅜ", "ㅣ": "ㅢ"],
        "ㅜ": ["ㆍ": "ㅠ", "ㅣ": "ㅟ", "ㅓ": "ㅝ", "ㅔ": "ㅞ"],
        "ㅠ": ["ㅣ": "ㅝ"],
        
        // ㅗ 계열
        "ㅗ": ["ㅣ": "ㅚ", "ㅏ": "ㅘ", "ㅐ": "ㅙ", "ㆍ": "ㅛ"],
        
        // 기타 결합
        "ㅚ": ["ㆍ": "ㅘ"], // 괴 + ㆍ -> 과
        "ㅘ": ["ㅣ": "ㅙ"],
        "ㅝ": ["ㅣ": "ㅞ"]
    ]
    
    init(automata: HangeulAutomataProtocol) {
        self.automata = automata
    }
    
    // MARK: - Protocol Implementation
    
    /// 사용자의 입력을 처리하여 변환된 텍스트를 반환합니다.
    ///
    /// 1. **확정 상태**: 조합이 확정된 경우, 오토마타를 거치지 않고 바로 새 글자를 추가합니다.
    /// 2. **모음 입력**: 천지인 조합 테이블을 확인하여 모음을 합치거나 새로 추가합니다.
    /// 3. **자음 입력**: 이전 키와 동일하면 순환(Cycle)하고, 아니면 새로 추가합니다.
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        // [확정 상태 체크]
        // 조합이 확정(false)된 상태라면, 오토마타 합치기를 시도하지 않고 바로 새 글자로 붙입니다.
        // 예: "가"(확정) + "ㄴ" -> "간"(X) -> "가ㄴ"(O)
        if !is한글조합OnGoing {
            committedLength = beforeText.count
            is한글조합OnGoing = true
            return (beforeText + 글자Input, 글자Input)
        }
        
        // 1. [모음 입력] (ㆍ, ㅡ, ㅣ)
        if ["ㆍ", "ㅡ", "ㅣ"].contains(글자Input) {
            // 모음 조합 시도
            if let (prefix, combined모음) = tryCombine모음(input: 글자Input, beforeText: beforeText) {
                // 조합된 모음을 오토마타에 입력하여 연음 및 자모 결합 처리
                // 예: "닭" + "ㅓ"(조합됨) -> "달거"
                let newText = automata.add글자(글자Input: combined모음, beforeText: prefix)
                is한글조합OnGoing = true
                
                var nextRepeatChar = combined모음
                switch combined모음 {
                case "ㅘ":
                    nextRepeatChar = "ㅏ"
                case "ㅝ":
                    nextRepeatChar = "ㅓ"
                case "ㅙ":
                    nextRepeatChar = "ㅐ"
                case "ㅞ":
                    nextRepeatChar = "ㅔ"
                default:
                    break
                }
                return (newText, nextRepeatChar)
            }
            
            // 조합 실패 시 단순 추가
            let newText = automata.add글자(글자Input: 글자Input, beforeText: beforeText)
            is한글조합OnGoing = true
            return (newText, 글자Input)
        }
        
        // 2. [자음 입력]
        else {
            // 조합 중이고, 순환 가능한 자음이면 순환 시도
            if let cycleList = 자음순환Table[글자Input] {
                return cycle자음(inputKey: 글자Input, cycleList: cycleList, beforeText: beforeText)
            }
            
            // 순환 불가능 -> 새로 추가
            let newText = automata.add글자(글자Input: 글자Input, beforeText: beforeText)
            is한글조합OnGoing = true
            return (newText, 글자Input)
        }
    }
    
    /// 스페이스바 입력을 처리합니다.
    ///
    /// - 조합 중: 조합 상태를 해제하고 현재 길이를 확정합니다 (Commit).
    /// - 조합 완료: 실제 공백을 입력합니다.
    func inputSpace(beforeText: String) -> SpaceInputResult {
        if is한글조합OnGoing {
            reset한글조합()
            committedLength = beforeText.count
            return .commitCombination
        } else {
            return .insertSpace
        }
    }
    
    /// 마지막 글자를 삭제합니다.
    ///
    /// 1. **기본 삭제**: 오토마타를 통해 자소 단위로 분해합니다.
    /// 2. **종성 복원**: 삭제 후 남은 자음이 앞 글자의 받침이 될 수 있다면 결합합니다. (예: 가니 -> 간)
    /// 3. **확정 보호**: 이미 확정된(`committedLength` 이전) 글자는 합치지 않습니다.
    func delete(beforeText: String) -> String {
        guard !beforeText.isEmpty else {
            committedLength = 0
            is한글조합OnGoing = false
            return ""
        }
        
        // 1. 오토마타를 이용한 기본 삭제
        let deletedText = automata.delete글자(beforeText: beforeText)
        
        // 텍스트가 줄어들면 확정 길이도 그에 맞춰 줄여줌 (Index Out of Bounds 방지)
        if deletedText.count < committedLength {
            committedLength = deletedText.count
        }
        
        // 2. 종성 복원 로직 (Jongseong Restoration)
        if let lastChar = deletedText.last {
            let lastCharString = String(lastChar)
            
            // 종성 테이블에 있고 공백이 아닌 경우에만 복원 시도
            if automata.종성Table.contains(lastCharString) && lastCharString != " " {
                let prefix = String(deletedText.dropLast())
                
                // 앞 글자가 확정된 영역이 아닐 때만 합치기 시도
                let isInsideCommittedArea = (prefix.count <= committedLength)
                
                if !isInsideCommittedArea,
                   let prefixLast = prefix.last,
                   let _ = automata.decompose(한글Char: prefixLast) {
                     
                     // 예: "가" + "ㄴ" -> "간"
                     let restoredText = automata.add글자(글자Input: lastCharString, beforeText: prefix)
                     
                     // 복원에 성공했으므로 여전히 조합 중인 상태입니다.
                     is한글조합OnGoing = true
                     return restoredText
                }
            }
        }
        
        // 3. 조합 상태 결정
        // 삭제 후 남은 글자가 모두 확정된 글자라면 조합 상태를 해제합니다.
        if deletedText.count == committedLength {
            is한글조합OnGoing = false
        } else {
            // 글자가 남아있고 확정된 영역 밖이라면 조합 중 유지
            is한글조합OnGoing = true
        }
        
        return deletedText
    }
    
    /// 한글 조합 상태를 초기화합니다.
    func reset한글조합() {
        is한글조합OnGoing = false
        committedLength = 0
    }
}

// MARK: - Private Methods

private extension CheonjiinProcessor {
    
    /// 모음 조합 로직
    ///
    /// 현재 텍스트의 마지막 글자와 입력된 모음을 조합하여 새로운 모음을 만듭니다.
    /// - Parameters:
    ///   - input: 입력된 모음 키 (ㆍ, ㅡ, ㅣ)
    ///   - beforeText: 입력 전 전체 텍스트
    /// - Returns: (조합에 사용되지 않은 앞부분 텍스트, 결합된 모음 글자)
    func tryCombine모음(input: String, beforeText: String) -> (String, String)? {
        guard let lastChar = beforeText.last else { return nil }
        let lastCharString = String(lastChar)
        let prefixText = String(beforeText.dropLast())
        
        // 1. 단순 모음/특수문자 조합
        // 예: ㆍ + ㆍ = ᆢ, ㅗ + ㆍ = ㅛ
        if let targetDict = 모음조합Table[lastCharString],
           let combined모음 = targetDict[input] {
            return (prefixText, combined모음)
        }
        
        // 2. 완성형 글자 내부 중성 조합
        // 예: 고 + ㆍ -> (ㄱ + ㅗ) + ㆍ -> ㄱ + (ㅗ + ㆍ) -> ㄱ + ㅛ -> 교
        // 종성이 없을 때만 중성을 변환합니다.
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar), 종성Index == 0 {
            let current모음 = automata.중성Table[중성Index]
            
            if let targetDict = 모음조합Table[current모음],
               let combined모음 = targetDict[input] {
                
                // 초성만 남기고(prefix), 새 모음(combined모음)을 리턴
                // 이후 input()에서 add글자(combined모음, 초성)가 실행되어 합체됩니다.
                let 초성Char = automata.초성Table[초성Index]
                return (prefixText + 초성Char, combined모음)
            }
        }
        
        return nil
    }
    
    /// 자음 순환 로직
    ///
    /// 같은 자음 키가 연속 입력되었을 때, 자음을 순환하거나 겹받침을 만듭니다.
    /// - Returns: (처리된 전체 텍스트, 변경된 글자)
    func cycle자음(inputKey: String, cycleList: [String], beforeText: String) -> (String, String?) {
        guard !beforeText.isEmpty else { return (beforeText + inputKey, inputKey) }
        
        // [Step 1] 영역 분리 (Isolation)
        // 오토마타가 확정된 글자('달')를 보지 못하게 아예 잘라냅니다.
        // 예: beforeText="달ㅇ", committedLength=1
        // -> committedPrefix = "달"
        // -> editableSuffix = "ㅇ"
        let splitIndex = beforeText.index(beforeText.startIndex, offsetBy: committedLength)
        let committedPrefix = String(beforeText[..<splitIndex])
        let editableSuffix = String(beforeText[splitIndex...])
        
        // 편집할 글자가 없으면(방어코드) 그냥 추가
        if editableSuffix.isEmpty {
            return (beforeText + inputKey, inputKey)
        }
        
        // [Step 2] 편집 영역(Suffix) 내에서만 순환 로직 수행
        var baseText = editableSuffix
        var targetCharString = ""
        
        let lastChar = baseText.last!
        let lastCharString = String(lastChar)
        
        // A. 낱자 순환
        if cycleList.contains(lastCharString) {
            baseText.removeLast()
            targetCharString = lastCharString
        }
        // B. 종성 순환
        else if let (초, 중, 종) = automata.decompose(한글Char: lastChar), 종 != 0 {
            let current종성 = automata.종성Table[종]
            
            if cycleList.contains(current종성) {
                baseText.removeLast()
                if let baseChar = automata.combine(초성Index: 초, 중성Index: 중, 종성Index: 0) {
                    baseText.append(baseChar)
                }
                targetCharString = current종성
            }
            else if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: current종성),
                    cycleList.contains(뒷받침) {
                baseText.removeLast()
                if let 앞받침Idx = automata.종성Table.firstIndex(of: 앞받침),
                   let baseChar = automata.combine(초성Index: 초, 중성Index: 중, 종성Index: 앞받침Idx) {
                    baseText.append(baseChar)
                    targetCharString = 뒷받침
                }
            }
        }
        
        // 순환 대상 없음 -> 그냥 추가
        if targetCharString.isEmpty {
            let newText = automata.add글자(글자Input: inputKey, beforeText: beforeText)
            return (newText, inputKey)
        }
        
        // [Step 3] 다음 글자 계산 및 재결합
        guard let currentIndex = cycleList.firstIndex(of: targetCharString) else {
            return (beforeText, nil)
        }
        let nextIndex = (currentIndex + 1) % cycleList.count
        let nextChar = cycleList[nextIndex]
        
        // editableSuffix 내부에서만 결합을 시도합니다. (예: "ㅇ" -> "ㅁ")
        let processedSuffix = automata.add글자(글자Input: nextChar, beforeText: baseText)
        
        // 최종적으로 확정된 앞부분과 합칩니다. ("달" + "ㅁ")
        // 오토마타를 거치지 않고 String 결합을 하므로 절대 섞이지 않습니다.
        return (committedPrefix + processedSuffix, nextChar)
    }
}
