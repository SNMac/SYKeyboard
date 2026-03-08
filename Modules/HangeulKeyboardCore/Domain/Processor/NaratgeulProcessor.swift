//
//  NaratgeulProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 9/19/25.
//

/// 나랏글 입력기
///
/// 나랏글 키보드 방식의 입력을 처리합니다.
/// - **특징**:
///   1. **기본 자모**: 12개의 키에 기본 자음과 모음이 배치되어 있습니다.
///   2. **획추가**: '획' 키를 눌러 기본 자모에 획을 더해 다른 문자로 변환합니다 (예: ㄱ -> ㅋ, ㅏ -> ㅑ).
///   3. **쌍자음**: '쌍' 키를 눌러 된소리(쌍자음)를 만듭니다 (예: ㄱ -> ㄲ, ㅏ -> ㅑ).
///   4. **모음 토글**: 같은 모음 키를 반복해서 눌러 `ㅏ` <-> `ㅓ`, `ㅗ` <-> `ㅜ`를 전환합니다.
final class NaratgeulProcessor: HangeulProcessable {
    
    // MARK: - Properties
    
    /// 나랏글 입력기는 별도의 '조합 끊기' 단계 없이 스페이스가 항상 공백으로 동작하므로 항상 `false`를 반환합니다.
    var is한글조합OnGoing: Bool { false }
    
    /// 표준 한글 오토마타 (자소 분해/조합 담당)
    private let automata: HangeulAutomataProtocol
    
    /// 획추가 변환 테이블
    private let 획추가Table: [String: String] = [
        // 자음
        "ㄱ": "ㅋ", "ㅋ": "ㄱ", "ㄲ": "ㄱ",
        "ㄴ": "ㄷ", "ㄷ": "ㅌ", "ㅌ": "ㄴ", "ㄸ": "ㄷ",
        "ㅁ": "ㅂ", "ㅂ": "ㅍ", "ㅍ": "ㅁ", "ㅃ": "ㅂ",
        "ㅅ": "ㅈ", "ㅈ": "ㅊ", "ㅊ": "ㅉ", "ㅉ": "ㅅ", "ㅆ": "ㅈ",
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        "ㄹ": "ㄹ",
        // 모음
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    /// 쌍자음 변환 테이블
    private let 쌍자음Table: [String: String] = [
        "ㄱ": "ㄲ", "ㅋ": "ㄲ", "ㄲ": "ㄱ",
        "ㄴ": "ㄸ", "ㄷ": "ㄸ", "ㅌ": "ㄸ", "ㄸ": "ㄷ",
        "ㅁ": "ㅃ", "ㅂ": "ㅃ", "ㅍ": "ㅃ", "ㅃ": "ㅁ",
        "ㅅ": "ㅆ", "ㅆ": "ㅅ",
        "ㅈ": "ㅉ", "ㅊ": "ㅉ", "ㅉ": "ㅈ",
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        "ㄹ": "ㄹ",
        // 모음
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    /// 모음 토글 테이블
    private let 모음ToggleTable: [String: String] = [
        "ㅏ": "ㅓ", "ㅓ": "ㅏ",
        "ㅗ": "ㅜ", "ㅜ": "ㅗ"
    ]
    
    /// 'ㅣ' 결합 테이블
    private let 모음결합Table: [String: String] = [
        "ㅏ": "ㅐ", "ㅓ": "ㅔ", "ㅕ": "ㅖ", "ㅑ": "ㅒ",
        "ㅘ": "ㅙ", "ㅝ": "ㅞ"
    ]
    
    /// 이중모음 결합 테이블
    private let 이중모음결합Table: [String: String] = [
        "ㅗ": "ㅘ", "ㅜ": "ㅝ"
    ]
    
    // MARK: - Initializer
    
    init(automata: HangeulAutomataProtocol) {
        self.automata = automata
    }
    
    // MARK: - HangeulProcessable Methods
    
    func input(글자Input: String, composing: String) -> CompositionResult {
        
        // 1. [특수 기능] 획추가, 쌍자음 처리
        if 글자Input == "획" { return 획추가(composing: composing) }
        if 글자Input == "쌍" { return 쌍자음(composing: composing) }
        
        // 2. [모음 결합] 'ㅣ' 키 입력 시 (예: 아 -> 애)
        if 글자Input == "ㅣ" {
            if let result = combine모음(composing: composing) {
                return result
            }
        }
        
        // 3. [이중모음] 'ㅏ'/'ㅓ' 입력 시 앞 글자와 결합 (예: 무+ㅓ -> 뭐, 보+ㅏ -> 봐)
        if 글자Input == "ㅏ" || 글자Input == "ㅓ" {
            if let result = combine이중모음(글자Input: 글자Input, composing: composing) {
                return result
            }
        }
        
        // 4. [모음 토글] ㅏ<->ㅓ, ㅗ<->ㅜ 반복 입력 처리
        if 모음ToggleTable.keys.contains(글자Input) {
            if let result = toggle모음(글자Input: 글자Input, composing: composing) {
                return result
            }
        }
        
        // 5. [기본 입력] 일반 자모 입력은 표준 오토마타에 위임
        let (committed, newComposing) = automata.add글자(글자Input: 글자Input, composing: composing)
        return CompositionResult(committed: committed, composing: newComposing, input글자: 글자Input)
    }
    
    func inputSpace(composing: String) -> SpaceInputResult {
        return .insertSpace
    }
    
    func delete(composing: String) -> String {
        // 1. 'ㅣ' 결합 분해 시도 (예: '애' -> '아')
        if let result = decompose모음(composing: composing) { return result }
        
        // 2. 이중모음 분해 시도 (예: '뭐' -> '무')
        if let result = decompose이중모음(composing: composing) { return result }
        
        // 3. 일반 삭제는 오토마타에게 위임
        return automata.delete글자(composing: composing)
    }
    
    func canRestore종성(committedCount: Int) -> Bool { true }
    func setCommitProtection(committedCount: Int) { }
    
    // 나랏글은 별도의 조합 상태 플래그를 관리하지 않으므로 빈 구현으로 둡니다.
    func start한글조합() {}
    func reset한글조합() {}
}

// MARK: - Private Methods

private extension NaratgeulProcessor {
    
    /// 획추가 기능 구현
    func 획추가(composing: String) -> CompositionResult {
        guard let lastChar = composing.last else { return .composingOnly(composing) }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 한글인 경우
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            
            // [1순위] 종성 변환 시도
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환
                if let converted종성 = 획추가Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return .composingOnly(prefix + String(new글자), input글자: converted종성)
                }
                
                // B. 겹받침 분해 후 뒷부분 변환
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 획추가Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            let baseText = prefix + String(prevChar)
                            let (committed, newComposing) = automata.add글자(글자Input: converted뒷받침, composing: baseText)
                            return CompositionResult(committed: committed, composing: newComposing, input글자: converted뒷받침)
                        }
                    }
                }
                
                return .composingOnly(composing)
            }
            
            // [2순위] 중성 변환
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 획추가Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return .composingOnly(prefix + String(new글자), input글자: converted중성)
            }
            
            return .composingOnly(composing)
        }
        
        // 2. 낱자 자모인 경우
        else {
            let last글자String = String(lastChar)
            if let converted글자 = 획추가Table[last글자String] {
                let (committed, newComposing) = automata.add글자(글자Input: converted글자, composing: prefix)
                return CompositionResult(committed: committed, composing: newComposing, input글자: converted글자)
            }
            return .composingOnly(composing)
        }
    }
    
    /// 쌍자음 기능 구현
    func 쌍자음(composing: String) -> CompositionResult {
        guard let lastChar = composing.last else { return .composingOnly(composing) }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 한글인 경우
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            
            // [1순위] 종성 변환
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환
                if let converted종성 = 쌍자음Table[종성글자] {
                    // Case 1: 유효한 종성인 경우
                    if let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                       let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                        return .composingOnly(prefix + String(new글자), input글자: converted종성)
                    }
                    
                    // Case 2: 종성으로 쓸 수 없는 경우 (예: ㅁ -> ㅃ, '옴' -> '오ㅃ')
                    else if let prevCharWithout종성 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 0) {
                        // 앞 글자는 확정, 쌍자음은 새 조합
                        return CompositionResult(
                            committed: prefix + String(prevCharWithout종성),
                            composing: converted종성,
                            input글자: converted종성
                        )
                    }
                }
                
                // B. 겹받침 분해 후 변환
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 쌍자음Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            let baseText = prefix + String(prevChar)
                            let (committed, newComposing) = automata.add글자(글자Input: converted뒷받침, composing: baseText)
                            return CompositionResult(committed: committed, composing: newComposing, input글자: converted뒷받침)
                        }
                    }
                }
                
                return .composingOnly(composing)
            }
            
            // [2순위] 중성 변환
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 쌍자음Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return .composingOnly(prefix + String(new글자), input글자: converted중성)
            }
            
            return .composingOnly(composing)
        }
        
        // 2. 낱자 변환
        else {
            let last글자String = String(lastChar)
            if let converted글자 = 쌍자음Table[last글자String] {
                let (committed, newComposing) = automata.add글자(글자Input: converted글자, composing: prefix)
                return CompositionResult(committed: committed, composing: newComposing, input글자: converted글자)
            }
            return .composingOnly(composing)
        }
    }
    
    /// 모음 토글 (ㅏ<->ㅓ, ㅗ<->ㅜ)
    func toggle모음(글자Input: String, composing: String) -> CompositionResult? {
        guard let lastChar = composing.last else { return nil }
        
        let prefix = String(composing.dropLast())
        
        // 1. 낱자 모음 토글
        let last글자String = String(lastChar)
        if let toggled모음 = 모음ToggleTable[last글자String] {
            if 글자Input == last글자String || 글자Input == toggled모음 {
                return .composingOnly(prefix + toggled모음, input글자: toggled모음)
            }
        }
        
        // 2. 완성형 한글 내 모음 토글
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar), 종성Index == 0 {
            let 중성글자 = automata.중성Table[중성Index]
            
            if let toggled중성 = 모음ToggleTable[중성글자] {
                if 글자Input == 중성글자 || 글자Input == toggled중성 {
                    if let toggled중성Index = automata.중성Table.firstIndex(of: toggled중성),
                       let new글자 = automata.combine(초성Index: 초성Index, 중성Index: toggled중성Index, 종성Index: 0) {
                        return .composingOnly(prefix + String(new글자), input글자: toggled중성)
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 'ㅣ' 입력 시 앞 모음과 결합 (예: ㅏ + ㅣ = ㅐ)
    func combine모음(composing: String) -> CompositionResult? {
        guard let lastChar = composing.last else { return nil }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 한글에서 결합
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let combined중성 = 모음결합Table[중성글자],
                   let combined중성Index = automata.중성Table.firstIndex(of: combined중성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: combined중성Index, 종성Index: 0) {
                    
                    var repeatChar = combined중성
                    if combined중성 == "ㅙ" { repeatChar = "ㅐ" }
                    else if combined중성 == "ㅞ" { repeatChar = "ㅔ" }
                    return .composingOnly(prefix + String(new글자), input글자: repeatChar)
                }
            }
        }
        
        // 2. 낱자 모음에서 결합
        else {
            let last글자String = String(lastChar)
            if let combined중성 = 모음결합Table[last글자String] {
                var repeatChar = combined중성
                if combined중성 == "ㅙ" { repeatChar = "ㅐ" }
                else if combined중성 == "ㅞ" { repeatChar = "ㅔ" }
                return .composingOnly(prefix + combined중성, input글자: repeatChar)
            }
        }
        
        return nil
    }
    
    /// 'ㅣ' 결합된 모음을 분해 (예: '애' -> '아')
    func decompose모음(composing: String) -> String? {
        guard let lastChar = composing.last else { return nil }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 한글 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let original중성글자 = 모음결합Table.first(where: { $0.value == 중성글자 })?.key,
                   let original중성Index = automata.중성Table.firstIndex(of: original중성글자),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: original중성Index, 종성Index: 0) {
                    return prefix + String(new글자)
                }
            }
        }
        
        // 2. 낱자 모음 분해
        else {
            let last글자String = String(lastChar)
            if let original글자 = 모음결합Table.first(where: { $0.value == last글자String })?.key {
                return prefix + original글자
            }
        }
        
        return nil
    }
    
    /// 이중모음 결합 (예: 'ㅜ' + 'ㅓ' = 'ㅝ')
    func combine이중모음(글자Input: String, composing: String) -> CompositionResult? {
        guard let lastChar = composing.last else { return nil }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 글자에서 결합
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let target이중모음 = 이중모음결합Table[중성글자],
                   let targetIndex = automata.중성Table.firstIndex(of: target이중모음),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: targetIndex, 종성Index: 0) {
                    
                    var repeatChar = target이중모음
                    if target이중모음 == "ㅘ" { repeatChar = "ㅏ" }
                    else if target이중모음 == "ㅝ" { repeatChar = "ㅓ" }
                    return .composingOnly(prefix + String(new글자), input글자: repeatChar)
                }
            }
        }
        
        // 2. 낱자 결합
        else {
            let last글자String = String(lastChar)
            if let target이중모음 = 이중모음결합Table[last글자String] {
                var repeatChar = target이중모음
                if target이중모음 == "ㅘ" { repeatChar = "ㅏ" }
                else if target이중모음 == "ㅝ" { repeatChar = "ㅓ" }
                return .composingOnly(prefix + target이중모음, input글자: repeatChar)
            }
        }
        
        return nil
    }
    
    /// 이중모음 분해 (예: '뭐' -> '무')
    func decompose이중모음(composing: String) -> String? {
        guard let lastChar = composing.last else { return nil }
        
        let prefix = String(composing.dropLast())
        
        // 1. 완성형 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: lastChar) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let original중성글자 = 이중모음결합Table.first(where: { $0.value == 중성글자 })?.key,
                   let original중성Index = automata.중성Table.firstIndex(of: original중성글자),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: original중성Index, 종성Index: 0) {
                    return prefix + String(new글자)
                }
            }
        }
        
        // 2. 낱자 분해
        else {
            let last글자String = String(lastChar)
            if let original글자 = 이중모음결합Table.first(where: { $0.value == last글자String })?.key {
                return prefix + original글자
            }
        }
        
        return nil
    }
}
