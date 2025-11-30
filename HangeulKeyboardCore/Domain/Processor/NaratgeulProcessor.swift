//
//  NaratgeulProcessor.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 9/19/25.
//

/// 나랏글 입력기
final class NaratgeulProcessor: HangeulProcessable {
    
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
    
    private let 이중모음결합Table: [String: String] = [
        "ㅗ": "ㅘ",
        "ㅜ": "ㅝ"
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
        
        // 3. 이중모음 결합 처리 (예: 무 + ㅏ/ㅓ -> 뭐, 보 + ㅏ/ㅓ -> 봐)
        // 'ㅏ'나 'ㅓ'가 입력되었을 때 앞 글자가 'ㅗ'나 'ㅜ'라면 결합을 시도
        if 글자Input == "ㅏ" || 글자Input == "ㅓ" {
            if let (combinedText, combined글자) = combine이중모음(글자Input: 글자Input, beforeText: beforeText) {
                return (combinedText, combined글자)
            }
        }
        
        // 4. 모음 토글 처리 (ㅏ<->ㅓ, ㅗ<->ㅜ)
        if 모음ToggleTable.keys.contains(글자Input) {
            if let (toggledText, toggled글자) = toggle모음(글자Input: 글자Input, beforeText: beforeText) {
                return (toggledText, toggled글자)
            }
        }
        
        // 5. 일반 자모 입력 (표준 오토마타 위임)
        return (automata.add글자(글자Input: 글자Input, beforeText: beforeText), 글자Input)
    }
    
    func delete(beforeText: String) -> String {
        // 1. 'ㅣ' 결합 분해 시도 (예: '애' -> '아')
        if let decomposedText = decompose모음(beforeText: beforeText) { return decomposedText }
        
        // 2. 이중모음 분해 시도 (예: '뭐' 지우기 -> '무')
        if let decomposed이중모음 = decompose이중모음(beforeText: beforeText) { return decomposed이중모음 }
        
        // 3. 일반 삭제는 오토마타에게 위임 (예: '가' -> 'ㄱ')
        return automata.delete글자(beforeText: beforeText)
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
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환 (예: '각' -> '갘')
                if let converted종성 = 획추가Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 변환
                // 예: '갊'(ㄹㅁ) + 획 -> '갈' + 'ㅂ' -> '갋'(ㄹㅂ)
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 획추가Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        // 1. 앞받침만 있는 글자를 만듭니다 (예: '갈')
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            // 2. 오토마타에게 합치기를 위임
                            let combinedText = automata.add글자(글자Input: converted뒷받침, beforeText: newText + String(prevChar))
                            return (combinedText, converted뒷받침)
                        }
                    }
                }
                
                return (beforeText, nil)
            }
            
            // [2순위] 중성(모음) 변환
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 획추가Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return (newText + String(new글자), converted중성)
            }
            
            return (beforeText, nil)
        }
        
        // 2. 낱자 변환
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 획추가Table[last글자String] {
                let processedText = automata.add글자(글자Input: converted글자, beforeText: newText)
                return (processedText, converted글자)
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
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                
                // A. 단순 종성 변환
                if let converted종성 = 쌍자음Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return (newText + String(new글자), converted종성)
                }
                
                // B. 겹받침 분해 후 변환
                // 예: '닭'(ㄹㄱ) + 쌍 -> '달' + 'ㄲ' -> '닭'(ㄹㄱ) (변화 없음 or ㄺ 유지)
                if let (앞받침, 뒷받침) = automata.decompose겹받침(종성: 종성글자) {
                    if let converted뒷받침 = 쌍자음Table[뒷받침],
                       let 앞받침Index = automata.종성Table.firstIndex(of: 앞받침) {
                        
                        if let prevChar = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) {
                            // 오토마타에게 재결합 위임
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
    
    /// 'ㅣ' 결합된 모음을 분해 (예: '애' -> '아', 'ㅐ' -> 'ㅏ')
    func decompose모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 한글 글자 분해 (예: '애', '게')
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
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
        
        // 2. 낱자 모음 분해 (예: 'ㅐ')
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
    
    /// 이중모음 결합 (ㅏ/ㅓ 입력 시, ㅗ->ㅘ, ㅜ->ㅝ)
    func combine이중모음(글자Input: String, beforeText: String) -> (String, String)? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 글자에서 결합 (예: 무 -> 뭐)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            // 받침이 없을 때만 결합 가능
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
                // 현재 중성이 테이블에 있는지 확인 (ㅗ 또는 ㅜ)
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
    
    /// 이중모음 분해 (예: 뭐 -> 무)
    func decompose이중모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                
                // 현재 중성이 결과값(value)에 있는지 확인 (ㅘ, ㅝ)
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
