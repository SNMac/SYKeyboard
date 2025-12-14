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
        "ㅑ": ["ㅣ": "ㅒ", "ㆍ": "ㅏ"],
        "ㅐ": ["ㆍ": "ㅒ"],
        
        // ㆍ(아래아) 계열
        "ㆍ": ["ㆍ": "ᆢ", "ㅣ": "ㅓ", "ㅡ": "ㅗ"],
        
        // ᆢ(쌍아래아) 계열
        "ᆢ": ["ㆍ": "ㆍ", "ㅣ": "ㅕ", "ㅡ": "ㅛ"],
        
        // ㅓ 계열
        "ㅓ": ["ㆍ": "ㅕ", "ㅣ": "ㅔ"],
        "ㅕ": ["ㅣ": "ㅖ"],
        "ㅔ": ["ㆍ": "ㅖ"],
        
        // ㅡ 계열
        "ㅡ": ["ㆍ": "ㅜ", "ㅣ": "ㅢ"],
        "ㅜ": ["ㆍ": "ㅠ", "ㅣ": "ㅟ", "ㅓ": "ㅝ", "ㅔ": "ㅞ"],
        "ㅠ": ["ㅣ": "ㅝ", "ㆍ": "ㅜ"],
        
        // ㅗ 계열
        "ㅗ": ["ㅣ": "ㅚ", "ㅏ": "ㅘ", "ㅐ": "ㅙ"],
        
        // 기타 결합
        "ㅚ": ["ㆍ": "ㅘ"],
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
        // [1. 한글 키 유효성 검사]
        // 천지인 모음 키이거나, 자음 순환 테이블에 정의된 자음 키인지 확인
        let is천지인모음 = ["ㆍ", "ㅡ", "ㅣ"].contains(글자Input)
        let is천지인자음 = 자음순환Table.keys.contains(글자Input)
        
        // [2. 비한글(기호, 숫자 등) 입력 처리]
        // 한글 조합에 참여하지 않는 글자가 들어오면, 무조건 확정 짓고 조합 상태를 끕니다.
        if !is천지인모음 && !is천지인자음 {
            // 지금까지의 텍스트를 모두 확정 처리
            committedLength = beforeText.count
            // 조합 상태 해제
            is한글조합OnGoing = false
            
            // 단순 추가 후 반환 (오토마타를 거칠 필요 없음)
            // 예: "가" + "1" -> "가1" (조합 끝)
            return (beforeText + 글자Input, 글자Input)
        }
        
        // [3. 한글 입력 처리]
        // [확정 상태 체크]
        if !is한글조합OnGoing {
            committedLength = beforeText.count
            is한글조합OnGoing = true
            return (beforeText + 글자Input, 글자Input)
        }
        
        // 1. [모음 입력] (ㆍ, ㅡ, ㅣ)
        if ["ㆍ", "ㅡ", "ㅣ"].contains(글자Input) {
            
            // A. 모음 조합 시도
            if let (prefix, combined모음) = tryCombine모음(input: 글자Input, beforeText: beforeText) {
                
                // 헬퍼 메서드 사용
                let newText = separateCommittedText(input: combined모음, to: prefix)
                
                is한글조합OnGoing = true
                
                // 반복 문자 설정
                var nextRepeatChar = combined모음
                switch combined모음 {
                case "ㅘ": nextRepeatChar = "ㅏ"
                case "ㅝ": nextRepeatChar = "ㅓ"
                case "ㅙ": nextRepeatChar = "ㅐ"
                case "ㅞ": nextRepeatChar = "ㅔ"
                default: break
                }
                return (newText, nextRepeatChar)
            }
            
            // B. 모음 단순 추가 (조합 실패)
            // 헬퍼 메서드 사용: beforeText의 확정 영역을 보호하며 글자Input을 붙임
            let newText = separateCommittedText(input: 글자Input, to: beforeText)
            is한글조합OnGoing = true
            return (newText, 글자Input)
        }
        
        // 2. [자음 입력]
        else {
            // 자음 순환 (내부 로직 독자적이므로 유지)
            if let cycleList = 자음순환Table[글자Input] {
                return cycle자음(inputKey: 글자Input, cycleList: cycleList, beforeText: beforeText)
            }
            
            // C. 순환 불가능 자음 추가
            // 헬퍼 메서드 사용
            let newText = separateCommittedText(input: 글자Input, to: beforeText)
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
        
        // 삭제 전, 현재 텍스트 길이가 확정 길이보다 긴지 확인합니다.
        let isDeletingNewChar = beforeText.count > committedLength
        
        // 1. 오토마타를 이용한 기본 삭제
        let deletedText = automata.delete글자(beforeText: beforeText)
        
        // 2. 상황별 상태 업데이트
        if isDeletingNewChar {
            // [상황 A] 확정된 글자 뒤에 붙은 새 글자('ㄴ')만 지우는 경우
            // 확정된 길이는 건드리지 않아야 합니다.
            
            // 다만, 삭제 결과가 확정 길이보다 짧아졌다면(예외 상황) 확정 길이를 맞춥니다.
            if deletedText.count < committedLength {
                committedLength = deletedText.count
            }
            
            // 만약 삭제 후 남은 글자가 정확히 확정된 글자라면 ("가"),
            // 다시 '확정 상태(조합 끊김)'로 돌아가야 합니다.
            // 그래야 다음 'ㄴ' 입력 시 '간'이 아니라 '가ㄴ'이 됩니다.
            if deletedText.count == committedLength {
                is한글조합OnGoing = false
            } else {
                // 아직 조합중인 글자가 남아있다면(예: "가낙" -> "가나") 조합 중 유지
                is한글조합OnGoing = true
            }
            
        } else {
            // [상황 B] 확정된 영역에 대한 삭제
            
            // 방금 지워진 글자가 한글인지 확인
            let isDeletedCharHangeul = beforeText.last?.isHangeul ?? false
            if isDeletedCharHangeul {
                // 한글을 지운 경우: 수정 모드로 진입 ("가" -> "ㄱ")
                committedLength = max(0, deletedText.count - 1)
                is한글조합OnGoing = true
            } else {
                // 숫자/기호를 지운 경우: 앞 글자 확정 유지 ("각4" -> "각")
                committedLength = deletedText.count
                is한글조합OnGoing = false
            }
        }
        
        // 3. 종성 복원 로직
        if let lastChar = deletedText.last {
            let lastCharString = String(lastChar)
            
            if automata.종성Table.contains(lastCharString) && lastCharString != " " {
                let prefix = String(deletedText.dropLast())
                
                // prefix(앞 글자)의 길이가 committedLength(확정 길이)와 같다면,
                // 이는 앞 글자가 '확정된 블록'이라는 뜻입니다.
                // 따라서 뒤에 남은 자음을 확정된 앞 글자의 받침으로 붙이면 안 됩니다.
                // 예: "가"(확정) + "ㄴ"(나머지) -> "간"(X) -> "가ㄴ"(O)
                if prefix.count == committedLength {
                    return deletedText
                }
                
                let isInsideCommittedArea = (prefix.count < committedLength)
                
                if !isInsideCommittedArea,
                   let prefixLast = prefix.last,
                   let _ = automata.decompose(한글Char: prefixLast) {
                    
                    let restoredText = automata.add글자(글자Input: lastCharString, beforeText: prefix)
                    
                    // 복원 성공 시에는 다시 조합 중 상태가 됩니다.
                    is한글조합OnGoing = true
                    return restoredText
                }
            }
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
    
    /// 확정된 영역(`committedLength`)을 보호하면서 오토마타를 통해 글자를 추가합니다.
    /// - Parameters:
    ///   - input: 추가할 글자 (자음 또는 모음)
    ///   - targetText: 대상 텍스트 (`beforeText` 또는 `prefix`)
    /// - Returns: 처리가 완료된 전체 텍스트
    func separateCommittedText(input: String, to targetText: String) -> String {
        // 방어 코드: 혹시 모를 Index Out of Bounds 방지
        let safeSplitIndex = min(committedLength, targetText.count)
        
        let splitIndex = targetText.index(targetText.startIndex, offsetBy: safeSplitIndex)
        let committedPrefix = String(targetText[..<splitIndex]) // 확정된 앞부분 ("간")
        let editableSuffix = String(targetText[splitIndex...])   // 수정 가능한 뒷부분 ("")
        
        // 오토마타 실행 (뒷부분만 넘김)
        let processedSuffix = automata.add글자(글자Input: input, beforeText: editableSuffix)
        
        // 다시 결합 ("간" + "ㅏ" -> "간ㅏ")
        return committedPrefix + processedSuffix
    }
    
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
