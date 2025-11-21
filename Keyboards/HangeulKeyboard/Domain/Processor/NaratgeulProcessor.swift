//
//  NaratgeulProcessor.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 9/19/25.
//

/// 나랏글 입력기 프로토콜
protocol NaratgeulProcessorProtocol {
    /// 나랏글 자판 입력을 처리합니다.
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자 (`String` 타입)
    ///   - beforeText: 입력 전의 전체 문자열
    func input(글자Input: String, beforeText: String) -> String
}

/// 나랏글 입력기
final class NaratgeulProcessor: NaratgeulProcessorProtocol {
    
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
    
    func input(글자Input: String, beforeText: String) -> String {
        // 1. 특수 기능 키 처리 (획추가, 쌍자음)
        if 글자Input == "획" {
            return 획추가(beforeText: beforeText)
        } else if 글자Input == "쌍" {
            return 쌍자음(beforeText: beforeText)
        }
        
        // 2. 'ㅣ' 키 입력 시 모음 결합 처리 (예: '아' + 'ㅣ' -> '애')
        if 글자Input == "ㅣ" {
            if let combinedText = combine모음(beforeText: beforeText) {
                return combinedText
            }
        }
        
        // 3. 모음 토글 처리 (예: '아' + 'ㅏ' -> '어')
        if 모음ToggleTable.keys.contains(글자Input) {
            if let toggledText = toggle모음(글자Input: 글자Input, beforeText: beforeText) {
                return toggledText
            }
        }
        
        // 4. 일반 자모 입력은 오토마타에게 그대로 위임
        return automata.add글자(글자Input: 글자Input, beforeText: beforeText)
    }
}

// MARK: - Private Methods

private extension NaratgeulProcessor {
    /// 획추가: 종성 -> [중성] 순서
    func 획추가(beforeText: String) -> String {
        guard let beforeTextLast글자Char = beforeText.last else { return beforeText }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글 글자 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환 (예: '각' -> '갘')
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                if let converted종성 = 획추가Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return newText + String(new글자)
                }
                return beforeText
            }
            
            // [2순위] 중성(모음) 변환 (예: '가' + 획 -> '갸', '그' + 획 -> '그')
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 획추가Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return newText + String(new글자)
            }
            
            return beforeText
        }
        
        // 2. 낱자 변환 (예: 'ㄱ' -> 'ㅋ')
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 획추가Table[last글자String] {
                return newText + converted글자
            }
            return beforeText
        }
    }
    
    /// 쌍자음: 종성 -> [중성] 순서
    func 쌍자음(beforeText: String) -> String {
        guard let beforeTextLast글자Char = beforeText.last else { return beforeText }
        
        var newText = beforeText
        newText.removeLast()
        
        // 1. 완성형 한글 글자 분해
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            
            // [1순위] 종성 변환 (예: '각' -> '깎')
            if 종성Index != 0 {
                let 종성글자 = automata.종성Table[종성Index]
                if let converted종성 = 쌍자음Table[종성글자],
                   let converted종성Index = automata.종성Table.firstIndex(of: converted종성),
                   let new글자 = automata.combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: converted종성Index) {
                    return newText + String(new글자)
                }
                return beforeText
            }
            
            // [2순위] 중성 변환 (예: '가' + 쌍 -> '갸')
            let 중성글자 = automata.중성Table[중성Index]
            if let converted중성 = 쌍자음Table[중성글자],
               let converted중성Index = automata.중성Table.firstIndex(of: converted중성),
               let new글자 = automata.combine(초성Index: 초성Index, 중성Index: converted중성Index, 종성Index: 0) {
                return newText + String(new글자)
            }
            
            return beforeText
        }
        
        // 2. 낱자 변환 (예: 'ㄱ' -> 'ㄲ')
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let converted글자 = 쌍자음Table[last글자String] {
                return newText + converted글자
            }
            return beforeText
        }
    }
    
    /// 모음 토글 (ㅏ<->ㅓ, ㅗ<->ㅜ)
    func toggle모음(글자Input: String, beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 낱자 모음 토글 (예: ㅏ -> ㅓ)
        let last글자String = String(beforeTextLast글자Char)
        if let toggled모음 = 모음ToggleTable[last글자String] {
            if 글자Input == last글자String || 글자Input == toggled모음 {
                var newText = beforeText
                newText.removeLast()
                newText.append(toggled모음)
                return newText
            }
        }
        
        // 2. 완성형 한글 글자 내 모음 토글 (예: 가 -> 거)
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char), 종성Index == 0 {
            let 중성글자 = automata.중성Table[중성Index]
            
            if let toggled중성 = 모음ToggleTable[중성글자] {
                if 글자Input == 중성글자 || 글자Input == toggled중성 {
                    if let toggled중성Index = automata.중성Table.firstIndex(of: toggled중성),
                       let newChar = automata.combine(초성Index: 초성Index, 중성Index: toggled중성Index, 종성Index: 0) {
                        
                        var newText = beforeText
                        newText.removeLast()
                        newText.append(newChar)
                        return newText
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 'ㅣ' 입력 시 앞 모음과 결합
    func combine모음(beforeText: String) -> String? {
        guard let beforeTextLast글자Char = beforeText.last else { return nil }
        
        // 1. 완성형 한글 글자
        if let (초성Index, 중성Index, 종성Index) = automata.decompose(한글Char: beforeTextLast글자Char) {
            // 받침이 없을 때만 결합
            if 종성Index == 0 {
                let 중성글자 = automata.중성Table[중성Index]
                if let newJungChar = 모음결합Table[중성글자],
                   let newJungIndex = automata.중성Table.firstIndex(of: newJungChar),
                   let newChar = automata.combine(초성Index: 초성Index, 중성Index: newJungIndex, 종성Index: 0) {
                    
                    var newText = beforeText
                    newText.removeLast()
                    newText.append(newChar)
                    return newText
                }
            }
        }
        
        // 2. 낱자 모음
        else {
            let last글자String = String(beforeTextLast글자Char)
            if let newChar = 모음결합Table[last글자String] {
                var newText = beforeText
                newText.removeLast()
                newText.append(newChar)
                return newText
            }
        }
        
        return nil
    }
}
