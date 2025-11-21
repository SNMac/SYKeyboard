//
//  NaratgeulProcessor.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 9/19/25.
//

/// 나랏글 입력기
final class NaratgeulProcessor: HangeulKeyboardProcessable {
    
    // MARK: - Properties
    
    private let automata: HangeulAutomataProtocol = HangeulAutomata()
    
    private let 획추가Table: [String: String] = [
        // 자음
        // ㄱ 계열
        "ㄱ": "ㅋ", "ㅋ": "ㄱ", "ㄲ": "ㄱ",
        // ㄴ 계열
        "ㄴ": "ㄷ", "ㄷ": "ㅌ", "ㅌ": "ㄴ", "ㄸ": "ㄷ",
        // ㅁ 계열
        "ㅁ": "ㅂ", "ㅂ": "ㅍ", "ㅍ": "ㅁ", "ㅃ": "ㅂ",
        // ㅅ 계열
        "ㅅ": "ㅈ", "ㅈ": "ㅊ", "ㅊ": "ㅉ", "ㅉ": "ㅅ", "ㅆ": "ㅈ",
        // ㅇ 계열
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        // ㄹ 계열
        // 유지
        "ㄹ": "ㄹ",
        
        // 모음 (토글)
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        // 유지
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    private let 쌍자음Table: [String: String] = [
        // 자음
        // ㄱ 계열
        "ㄱ": "ㄲ", "ㅋ": "ㄲ", "ㄲ": "ㄱ",
        // ㄴ 계열
        "ㄴ": "ㄸ", "ㄷ": "ㄸ", "ㅌ": "ㄸ", "ㄸ": "ㄷ",
        // ㅁ 계열
        "ㅁ": "ㅃ", "ㅂ": "ㅃ", "ㅍ": "ㅃ", "ㅃ": "ㅁ",
        // ㅅ 계열
        "ㅅ": "ㅆ", "ㅆ": "ㅅ",
        // ㅈ 계열
        "ㅈ": "ㅉ", "ㅊ": "ㅉ", "ㅉ": "ㅈ",
        // ㅇ 계열
        "ㅇ": "ㅎ", "ㅎ": "ㅇ",
        // ㄹ 계열
        "ㄹ": "ㄹ",
        
        // 모음 (토글)
        "ㅏ": "ㅑ", "ㅑ": "ㅏ", "ㅓ": "ㅕ", "ㅕ": "ㅓ",
        "ㅗ": "ㅛ", "ㅛ": "ㅗ", "ㅜ": "ㅠ", "ㅠ": "ㅜ",
        // 유지
        "ㅣ": "ㅣ", "ㅡ": "ㅡ"
    ]
    
    private let 모음ToggleTable: [String: String] = [
        "ㅏ": "ㅓ", "ㅓ": "ㅏ",
        "ㅗ": "ㅜ", "ㅜ": "ㅗ"
    ]
    
    private let 모음결합Table: [String: String] = [
        "ㅏ": "ㅐ",
        "ㅓ": "ㅔ",
        "ㅕ": "ㅖ",
        "ㅑ": "ㅒ"
    ]
    
    // MARK: - Internal Methods
    
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?) {
        // 1. 획추가, 쌍자음 처리
        if 글자Input == "획" {
            return 획추가(beforeText: beforeText)
        } else if 글자Input == "쌍" {
            return 쌍자음(beforeText: beforeText)
        }
        
        // 2. 'ㅣ' 키 입력 시 모음 결합 처리
        if 글자Input == "ㅣ" {
            if let (combinedText, combined글자) = combine모음(beforeText: beforeText) {
                return (combinedText, combined글자)
            }
        }
        
        // 3. 모음 토글 처리 (ㅏ<->ㅓ, ㅗ<->ㅜ)
        if 모음ToggleTable.keys.contains(글자Input) {
            if let (toggledText, toggled글자) = toggle모음(글자Input: 글자Input, beforeText: beforeText) {
                return (toggledText, toggled글자)
            }
        }
        
        // 4. 일반 자모 입력 (표준 오토마타 위임)
        return (automata.add글자(글자Input: 글자Input, beforeText: beforeText), 글자Input)
    }
}

// MARK: - Private Methods

private extension NaratgeulProcessor {
    /// 획추가: 종성 -> [중성] 순서
    /// - Returns: (변경된 전체 텍스트, 변환된 글자)
    func 획추가(beforeText: String) -> (String, String?) {
        guard let beforeTextLast글자Char = beforeText.last else { return (beforeText, nil) }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글 글자 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환
            // A. 단순 종성 변환 (예: '각' -> '갘')
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                if let converted종성 = 획추가Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 변환 (예: '닭' + 획 -> '달' + 'ㅋ')
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 획추가Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            return (newText + String(prevChar) + converted뒷받침, converted뒷받침)
                        }
                    }
                }
                
                return (beforeText, nil)
            }
            
            // [2순위] 중성(모음) 변환 (예: '가' + 획 -> '갸', '그' + 획 -> '그')
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 획추가Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return (newText + String(new글자), converted중성)
            }
            
            return (beforeText, nil)
        }
        
        // 2. 낱자 변환 (예: 'ㄱ' -> 'ㅋ')
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 획추가Table[last글자String] {
                return (newText + converted글자, converted글자)
            }
            return (beforeText, nil)
        }
    }
    
    /// 쌍자음: 종성 -> [중성] 순서
    /// - Returns: (변경된 전체 텍스트, 변환된 글자)
    func 쌍자음(beforeText: String) -> (String, String?) {
        guard let beforeTextLast글자Char = beforeText.last else { return (beforeText, nil) }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글 글자 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환
            // A. 단순 종성 변환 (예: '각' -> '깎')
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                if let converted종성 = 쌍자음Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 변환 (예: '닭' + 쌍 -> '달' + 'ㄲ')
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 쌍자음Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            return (newText + String(prevChar) + converted뒷받침, converted뒷받침)
                        }
                    }
                }
                
                return (beforeText, nil)
            }
            
            // [2순위] 중성 변환 (예: '가' + 쌍 -> '갸')
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 쌍자음Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return (newText + String(new글자), converted중성)
            }
            
            return (beforeText, nil)
        }
        
        // 2. 낱자 변환 (예: 'ㄱ' -> 'ㄲ')
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 쌍자음Table[last글자String] {
                return (newText + converted글자, converted글자)
            }
            return (beforeText, nil)
        }
    }
    
    /// 모음 토글 (ㅏ<->ㅓ, ㅗ<->ㅜ)
    func toggle모음(글자Input: String, beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 낱자 모음 토글 (예: ㅏ -> ㅓ)
        let last글자String = String(beforeTextLast글자Char)
        if let toggled모음 = 모음ToggleTable[last글자String] {
            if 글자Input == last글자String || 글자Input == toggled모음 {
                var newText = beforeText
                newText.removeLast()
                newText.append(toggled모음)
                return (newText, toggled모음)
            }
        }
        
        // 2. 완성형 한글 글자 내 모음 토글 (예: 가 -> 거)
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
    
    /// 'ㅣ' 입력 시 앞 모음과 결합
    func combine모음(beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 한글 글자
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
        
        // 2. 낱자 모음
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
}
