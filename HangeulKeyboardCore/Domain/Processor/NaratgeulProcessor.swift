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
    
    /// 표준 한글 오토마타 (자소 분해/조합 담당)
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    /// 획추가 변환 테이블
    ///
    /// '획' 키 입력 시 변환될 규칙을 정의합니다.
    /// - Key: 원본 문자
    /// - Value: 획이 추가된 문자
    /// - 예: ㄱ -> ㅋ, ㄴ -> ㄷ, ㅏ -> ㅑ
    private let 획추가Table: [String: String] = [
        // 자음
        // ㄱ 계열: ㄱ -> ㅋ -> ㄱ (순환)
        "ㄱ": "ㅋ", "ㅋ": "ㄱ", "ㄲ": "ㄱ",
        // ㄴ 계열: ㄴ -> ㄷ -> ㅌ -> ㄴ (순환), ㄸ -> ㄷ
        "ㄴ": "ㄷ", "ㄷ": "ㅌ", "ㅌ": "ㄴ", "ㄸ": "ㄷ",
        // ㅁ 계열: ㅁ -> ㅂ -> ㅍ -> ㅁ (순환), ㅃ -> ㅂ
        "ㅁ": "ㅂ", "ㅂ": "ㅍ", "ㅍ": "ㅁ", "ㅃ": "ㅂ",
        // ㅅ 계열: ㅅ -> ㅈ -> ㅊ -> ㅉ -> ㅅ (순환, 4단계), ㅆ -> ㅈ
        "ㅅ": "ㅈ", "ㅈ": "ㅊ", "ㅊ": "ㅉ", "ㅉ": "ㅅ", "ㅆ": "ㅈ",
        // ㅇ 계열: ㅇ -> ㅎ -> ㅇ (순환)
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        // ㄹ 계열: 변화 없음
        "ㄹ": "ㄹ",
        
        // 모음 (토글 방식)
        // ㅏ <-> ㅑ, ㅓ <-> ㅕ
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        // ㅗ <-> ㅛ, ㅜ <-> ㅠ
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        // ㅣ, ㅡ 유지
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    /// 쌍자음 변환 테이블
    ///
    /// '쌍' 키 입력 시 변환될 규칙을 정의합니다.
    /// - Key: 원본 문자
    /// - Value: 된소리(쌍자음) 문자
    /// - 예: ㄱ -> ㄲ, ㅂ -> ㅃ
    private let 쌍자음Table: [String: String] = [
        // 자음
        // ㄱ 계열: ㄱ -> ㄲ, ㅋ -> ㄲ, ㄲ -> ㄱ (해제)
        "ㄱ": "ㄲ", "ㅋ": "ㄲ", "ㄲ": "ㄱ",
        // ㄴ 계열: ㄴ, ㄷ, ㅌ -> ㄸ (그룹핑), ㄸ -> ㄷ (해제)
        "ㄴ": "ㄸ", "ㄷ": "ㄸ", "ㅌ": "ㄸ", "ㄸ": "ㄷ",
        // ㅁ 계열: ㅁ, ㅂ, ㅍ -> ㅃ (그룹핑), ㅃ -> ㅁ (해제)
        "ㅁ": "ㅃ", "ㅂ": "ㅃ", "ㅍ": "ㅃ", "ㅃ": "ㅁ",
        // ㅅ 계열: ㅅ -> ㅆ, ㅆ -> ㅅ
        "ㅅ": "ㅆ", "ㅆ": "ㅅ",
        // ㅈ 계열: ㅈ, ㅊ -> ㅉ, ㅉ -> ㅈ
        "ㅈ": "ㅉ", "ㅊ": "ㅉ", "ㅉ": "ㅈ",
        // ㅇ 계열: ㅇ -> ㅎ (예외적 규칙)
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        // ㄹ 계열: 변화 없음
        "ㄹ": "ㄹ",
        
        // 모음 (획추가와 동일하게 동작)
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    /// 모음 토글 테이블
    ///
    /// 동일한 모음 키 반복 입력 시 변환 규칙입니다.
    /// - 예: `ㅏ` 키 반복 -> `ㅓ`, `ㅓ` 키 반복 -> `ㅏ`
    private let 모음ToggleTable: [String: String] = [
        "ㅏ": "ㅓ", "ㅓ": "ㅏ",
        "ㅗ": "ㅜ", "ㅜ": "ㅗ"
    ]
    
    /// 'ㅣ' 결합 테이블
    ///
    /// 'ㅣ' 키가 입력되었을 때 앞 모음과 결합하여 생성되는 모음입니다.
    /// - 예: `ㅏ` + `ㅣ` = `ㅐ`
    private let 모음결합Table: [String: String] = [
        "ㅏ": "ㅐ",
        "ㅓ": "ㅔ",
        "ㅕ": "ㅖ",
        "ㅑ": "ㅒ"
    ]
    
    /// 이중모음 결합 테이블
    ///
    /// `ㅏ` 또는 `ㅓ` 입력 시 앞 모음(`ㅗ` 또는 `ㅜ`)과 결합하여 생성되는 모음입니다.
    /// - 예: `ㅗ` + `ㅏ` = `ㅘ`
    private let 이중모음결합Table: [String: String] = [
        "ㅗ": "ㅘ",
        "ㅜ": "ㅝ"
    ]
    
    // MARK: - Internal Methods
    
    /// 사용자의 입력을 처리하여 변환된 텍스트를 반환합니다.
    ///
    /// 1. **특수 기능 키**: '획', '쌍' 키 입력 시 마지막 글자를 변환합니다.
    /// 2. **모음 결합**: 'ㅣ' 키나 이중모음 결합(ㅘ, ㅝ 등)을 처리합니다.
    /// 3. **모음 토글**: `ㅏ` <-> `ㅓ` 등 키 반복 입력을 처리합니다.
    /// 4. **기본 입력**: 위 경우가 아니면 표준 오토마타(`add글자`)를 통해 자소를 결합합니다.
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        
        // 1. [특수 기능] 획추가, 쌍자음 처리
        if 글자Input == "획" {
            return 획추가(beforeText: beforeText)
        } else if 글자Input == "쌍" {
            return 쌍자음(beforeText: beforeText)
        }
        
        // 2. [모음 결합] 'ㅣ' 키 입력 시 (예: 아 -> 애)
        if 글자Input == "ㅣ" {
            if let (combinedText, combined글자) = combine모음(beforeText: beforeText) {
                return (combinedText, combined글자)
            }
        }
        
        // 3. [이중모음] 'ㅏ'/'ㅓ' 입력 시 앞 글자와 결합 (예: 무+ㅓ -> 뭐, 보+ㅏ -> 봐)
        if 글자Input == "ㅏ" || 글자Input == "ㅓ" {
            if let (combinedText, combined글자) = combine이중모음(글자Input: 글자Input, beforeText: beforeText) {
                return (combinedText, combined글자)
            }
        }
        
        // 4. [모음 토글] ㅏ<->ㅓ, ㅗ<->ㅜ 반복 입력 처리
        if 모음ToggleTable.keys.contains(글자Input) {
            if let (toggledText, toggled글자) = toggle모음(글자Input: 글자Input, beforeText: beforeText) {
                return (toggledText, toggled글자)
            }
        }
        
        // 5. [기본 입력] 일반 자모 입력은 표준 오토마타에 위임
        return (automata.add글자(글자Input: 글자Input, beforeText: beforeText), 글자Input)
    }
    
    /// 스페이스바 입력을 처리합니다.
    ///
    /// 나랏글 입력기는 별도의 조합 끊기 로직 없이 항상 띄어쓰기를 수행합니다.
    func inputSpace(beforeText: String) -> SpaceInputResult {
        return .insertSpace
    }
    
    /// 마지막 글자를 삭제하거나 분해합니다.
    ///
    /// 1. **결합 분해**: 'ㅣ' 결합(`애` -> `아`)이나 이중모음(`뭐` -> `무`)을 우선적으로 분해합니다.
    /// 2. **표준 삭제**: 분해할 특수 모음이 없으면 표준 오토마타(`delete글자`)를 통해 자소를 삭제합니다.
    func delete(beforeText: String) -> String {
        // 1. 'ㅣ' 결합 분해 시도 (예: '애' -> '아')
        if let decomposedText = decompose모음(beforeText: beforeText) { return decomposedText }
        
        // 2. 이중모음 분해 시도 (예: '뭐' 지우기 -> '무')
        if let decomposed이중모음 = decompose이중모음(beforeText: beforeText) { return decomposed이중모음 }
        
        // 3. 일반 삭제는 오토마타에게 위임 (종성 삭제 -> 중성 삭제 -> 초성 삭제)
        return automata.delete글자(beforeText: beforeText)
    }
}

// MARK: - Private Methods (Logic Implementation)

private extension NaratgeulProcessor {
    
    /// 획추가 기능 구현
    ///
    /// 마지막 글자의 종성, 중성, 초성 순서로 확인하여 획을 추가합니다.
    /// - 예: '각' -> '갘' (종성 변환)
    /// - 예: '가' -> '갸' (중성 변환)
    /// - 예: 'ㄱ' -> 'ㅋ' (초성/낱자 변환)
    func 획추가(beforeText: String) -> (String, String?) {
        guard let beforeTextLast글자Char = beforeText.last else { return (beforeText, nil) }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글인 경우 (가~힣)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환 시도
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환 (예: ㄱ -> ㅋ)
                if let converted종성 = 획추가Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 뒷부분 변환 (예: 갊(ㄹㅁ) -> 갈 + ㅂ -> 갈 + ㅍ(변환) -> 갚(ㄹㅍ))
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 획추가Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        // 1. 앞받침만 있는 글자를 만듭니다 (예: '갈')
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            // 2. 변환된 뒷자음을 추가하여 합치기를 시도 (오토마타 위임)
                            let combinedText = automata.add글자(글자Input: converted뒷받침, beforeText: newText + String(prevChar))
                            return (combinedText, converted뒷받침)
                        }
                    }
                }
                
                return (beforeText, nil) // 변환 불가 시 원본 유지
            }
            
            // [2순위] 중성(모음) 변환 시도 (종성이 없을 때)
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 획추가Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return (newText + String(new글자), converted중성)
            }
            
            return (beforeText, nil)
        }
        
        // 2. 낱자 자모인 경우
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 획추가Table[last글자String] {
                // 오토마타를 통해 안전하게 교체 (혹시 모를 결합 대비)
                let processedText = automata.add글자(글자Input: converted글자, beforeText: newText)
                return (processedText, converted글자)
            }
            return (beforeText, nil)
        }
    }
    
    /// 쌍자음 기능 구현
    ///
    /// 마지막 글자를 된소리(쌍자음)로 변환합니다. 우선순위와 로직은 획추가와 유사합니다.
    /// - 예: '각' -> '깎' (종성 우선이 아니므로 초성/종성 위치에 따라 다름, 나랏글은 보통 종성 우선)
    /// - 예: '가' -> '꺄' (중성 변환, 모음은 획추가와 동일)
    func 쌍자음(beforeText: String) -> (String, String?) {
        guard let beforeTextLast글자Char = beforeText.last else { return (beforeText, nil) }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글인 경우
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환
                if let converted종성 = 쌍자음Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 변환
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 쌍자음Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            let combinedText = automata.add글자(글자Input: converted뒷받침, beforeText: newText + String(prevChar))
                            return (combinedText, converted뒷받침)
                        }
                    }
                }
                
                return (beforeText, nil)
            }
            
            // [2순위] 중성 변환
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 쌍자음Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return (newText + String(new글자), converted중성)
            }
            
            return (beforeText, nil)
        }
        
        // 2. 낱자 변환
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 쌍자음Table[last글자String] {
                let processedText = automata.add글자(글자Input: converted글자, beforeText: newText)
                return (processedText, converted글자)
            }
            return (beforeText, nil)
        }
    }
    
    /// 모음 토글 (ㅏ<->ㅓ, ㅗ<->ㅜ)
    ///
    /// 사용자가 동일한 모음 키를 반복해서 눌렀을 때 다른 모음으로 교체합니다.
    func toggle모음(글자Input: String, beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 낱자 모음 토글 (예: 'ㅏ' 상태에서 'ㅏ' 입력 -> 'ㅓ')
        let last글자String = String(beforeTextLast글자Char)
        if let toggled모음 = 모음ToggleTable[last글자String] {
            if 글자Input == last글자String || 글자Input == toggled모음 {
                var newText = beforeText
                newText.removeLast()
                newText.append(toggled모음)
                return (newText, toggled모음)
            }
        }
        
        // 2. 완성형 한글 내 모음 토글 (예: '가' 상태에서 'ㅏ' 입력 -> '거')
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char), 종성Index == 0 {
            let 중성글자 = automata.중성Table[중성Index]
            
            if let toggled중성 = 모음ToggleTable[중성글자] {
                if 글자Input == 중성글자 || 글자Input == toggled중성 {
                    if let toggled중성Index = automata.중성Table.firstIndex(of: toggled중성),
                       let new글자 = automata.combine(초성Index: 초성Index, 중성Index: toggled중성Index, 종성Index: 0) {
                        
                        var newText = beforeText
                        newText.removeLast()
                        newText.append(new글자)
                        return (newText, toggled중성)
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 'ㅣ' 입력 시 앞 모음과 결합 (예: ㅏ + ㅣ = ㅐ)
    func combine모음(beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 한글에서 결합 (예: 아 + ㅣ -> 애)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            // 받침이 없을 때만 결합
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let combined중성 = 모음결합Table[중성글자],
                   let combined중성Index = automata.중성Table.firstIndex(of: combined중성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: combined중성Index, 종성Index: 0) {
                    
                    var newText = beforeText
                    newText.removeLast()
                    newText.append(new글자)
                    return (newText, combined중성)
                }
            }
        }
        
        // 2. 낱자 모음에서 결합 (예: ㅏ + ㅣ -> ㅐ)
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let combined중성 = 모음결합Table[last글자String] {
                var newText = beforeText
                newText.removeLast()
                newText.append(combined중성)
                return (newText, combined중성)
            }
        }
        
        return nil
    }
    
    /// 'ㅣ' 결합된 모음을 분해 (예: '애' -> '아', 'ㅐ' -> 'ㅏ')
    ///
    /// 삭제(Backspace) 시 동작합니다.
    func decompose모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 한글 분해 (예: '애' -> '아')
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
                // 모음결합Table에서 역으로 검색 (Value -> Key)
                if let original중성글자 = 모음결합Table.first(where: { $0.value == 중성글자 })?.key,
                   let original중성Index = automata.중성Table.firstIndex(of: original중성글자),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: original중성Index, 종성Index: 0) {
                    
                    var newText = beforeText
                    newText.removeLast()
                    newText.append(new글자)
                    return newText
                }
            }
        }
        
        // 2. 낱자 모음 분해 (예: 'ㅐ' -> 'ㅏ')
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let original글자 = 모음결합Table.first(where: { $0.value == last글자String })?.key {
                var newText = beforeText
                newText.removeLast()
                newText.append(original글자)
                return newText
            }
        }
        
        return nil
    }
    
    /// 이중모음 결합 (예: `ㅜ` + `ㅓ` = `ㅝ`, `고` + `ㅏ` = `과`)
    func combine이중모음(글자Input: String, beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 글자에서 결합 (예: 무 -> 뭐)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
                // 현재 중성이 테이블의 Key(ㅗ, ㅜ)에 있는지 확인하고, 결과값이 아닌 입력값과의 관계를 확인해야 함
                // 여기서는 `이중모음결합Table`이 `[ㅗ: ㅘ, ㅜ: ㅝ]`로 단순 매핑되어 있음.
                // 실제로는 입력값(ㅏ/ㅓ)에 따라 분기해야 정확하나, 나랏글 키 배치상 ㅗ->ㅏ, ㅜ->ㅓ가 자연스러움.
                if let target이중모음 = 이중모음결합Table[중성글자],
                   let targetIndex = automata.중성Table.firstIndex(of: target이중모음),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: targetIndex, 종성Index: 0) {
                    
                    var newText = beforeText
                    newText.removeLast()
                    newText.append(new글자)
                    return (newText, target이중모음)
                }
            }
        }
        
        // 2. 낱자 결합 (예: ㅜ -> ㅝ)
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let target이중모음 = 이중모음결합Table[last글자String] {
                var newText = beforeText
                newText.removeLast()
                newText.append(target이중모음)
                return (newText, target이중모음)
            }
        }
        
        return nil
    }
    
    /// 이중모음 분해 (예: `뭐` -> `무`)
    ///
    /// 삭제(Backspace) 시 동작합니다.
    func decompose이중모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
                // 역으로 검색 (Value -> Key)
                if let original중성글자 = 이중모음결합Table.first(where: { $0.value == 중성글자 })?.key,
                   let original중성Index = automata.중성Table.firstIndex(of: original중성글자),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: original중성Index, 종성Index: 0) {
                    
                    var newText = beforeText
                    newText.removeLast()
                    newText.append(new글자)
                    return newText
                }
            }
        }
        
        // 2. 낱자 분해
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let original글자 = 이중모음결합Table.first(where: { $0.value == last글자String })?.key {
                var newText = beforeText
                newText.removeLast()
                newText.append(original글자)
                return newText
            }
        }
        
        return nil
    }
}
