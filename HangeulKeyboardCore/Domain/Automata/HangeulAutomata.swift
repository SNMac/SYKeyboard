//
//  HangeulAutomata.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 9/19/25.
//

/// 한글 오토마타 프로토콜
protocol HangeulAutomataProtocol {
    var 초성Table: [String] { get }
    var 중성Table: [String] { get }
    var 종성Table: [String] { get }
    
    /// 새로운 글자를 입력받아 처리된 전체 문자열을 반환합니다.
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자 (`String` 타입)
    ///   - beforeText: 입력 전의 전체 문자열
    func add글자(글자Input: String, beforeText: String) -> String
    /// 마지막 글자를 지우거나 분해합니다.
    /// - Parameters:
    ///   - beforeText: 삭제 전의 전체 문자열
    func delete글자(beforeText: String) -> String
    
    /// 초성, 중성, 종성 인덱스를 조합하여 완성된 한글 문자 하나를 생성합니다.
    ///
    /// 유니코드 공식: `0xAC00 + (초성 * 21 * 28) + (중성 * 28) + 종성`
    ///
    /// - Parameters:
    ///   - 초성Index: 초성 테이블의 인덱스 (0 ~ 18)
    ///   - 중성Index: 중성 테이블의 인덱스 (0 ~ 20)
    ///   - 종성Index: 종성 테이블의 인덱스 (0 ~ 27). 종성이 없는 경우 0입니다.
    /// - Returns: 조합된 한글 `Character`. 인덱스가 범위를 벗어나거나 유효하지 않은 유니코드인 경우 `nil`을 반환합니다.
    func combine(초성Index: Int, 중성Index: Int, 종성Index: Int) -> Character?
    /// 완성된 한글 문자를 초성, 중성, 종성 인덱스로 분해합니다.
    ///
    /// 입력된 문자가 '가'(0xAC00) ~ '힣'(0xD7A3) 범위 내의 완성형 한글 글자일 때만 동작합니다.
    /// 자음이나 모음 단독(예: 'ㄱ', 'ㅏ')일 경우 `nil`을 반환합니다.
    ///
    /// - Parameter 한글Char: 분해할 한글 문자 (Character)
    /// - Returns: (초성Index, 중성Index, 종성Index) 형태의 튜플. 분해 실패 시 `nil`을 반환합니다.
    func decompose(한글Char: Character) -> (초성Index: Int, 중성Index: Int, 종성Index: Int)?
    
    /// 겹받침을 구성하는 두 개의 낱자 자음으로 분해합니다.
    ///
    /// 입력된 종성이 겹받침(예: 'ㄳ', 'ㄺ')인 경우, 이를 앞받침과 뒷받침으로 나누어 반환합니다.
    /// 겹받침이 아니거나 분해할 수 없는 경우 `nil`을 반환합니다.
    ///
    /// - Parameter 종성: 분해할 종성 문자열 (예: "ㄳ")
    /// - Returns: (앞받침, 뒷받침) 형태의 튜플 (예: ("ㄱ", "ㅅ")). 분해 실패 시 `nil`.
    func decompose겹받침(종성: String) -> (String, String)?
}

/// 표준 두벌식 한글 오토마타
final class HangeulAutomata: HangeulAutomataProtocol {
    
    // MARK: - Properties
    
    private let 한글UnicodeStart: UInt32 = 0xAC00
    private let 한글UnicodeEnd: UInt32 = 0xD7A3
    
    let 초성Table: [String] = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ",
                             "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    let 중성Table: [String] = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ",
                             "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    
    let 종성Table: [String] = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ","ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ",
                             "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let 겹모음조합Table: [(앞모음: String, 뒷모음: String, 결과: String)] = [
        ("ㅗ", "ㅏ", "ㅘ"),
        ("ㅘ", "ㅣ", "ㅙ"),
        ("ㅗ", "ㅐ", "ㅙ"),
        ("ㅗ", "ㅣ", "ㅚ"),
        ("ㅜ", "ㅓ", "ㅝ"),
        ("ㅜ", "ㅔ", "ㅞ"),
        ("ㅝ", "ㅣ", "ㅞ"),
        ("ㅜ", "ㅣ", "ㅟ"),
        ("ㅡ", "ㅣ", "ㅢ")
    ]
    
    private let 겹자음조합Table: [(앞자음: String, 뒷자음: String, 결과: String)] = [
        ("ㄱ", "ㅅ", "ㄳ"),
        ("ㄴ", "ㅈ", "ㄵ"),
        ("ㄴ", "ㅎ", "ㄶ"),
        ("ㄹ", "ㄱ", "ㄺ"),
        ("ㄹ", "ㅁ", "ㄻ"),
        ("ㄹ", "ㅂ", "ㄼ"),
        ("ㄹ", "ㅅ", "ㄽ"),
        ("ㄹ", "ㅌ", "ㄾ"),
        ("ㄹ", "ㅍ", "ㄿ"),
        ("ㄹ", "ㅎ", "ㅀ"),
        ("ㅂ", "ㅅ", "ㅄ")
    ]
    
    // MARK: - Internal Methods
    
    func add글자(글자Input: String, beforeText: String) -> String {
        guard !글자Input.isEmpty else { return beforeText }
        guard let beforeTextLast글자Char = beforeText.last else { return beforeText + 글자Input }
        
        var newText = beforeText
        
        // 1. 입력이 모음인 경우
        if 중성Table.contains(글자Input) {
            // 마지막 글자가 완성된 한글인 경우
            if let (초성Index, 중성Index, 종성Index) = decompose(한글Char: beforeTextLast글자Char) {
                // 1-1. 종성이 있는 경우 (예: '각' + 'ㅏ')
                if 종성Index != 0 {
                    let 종성글자 = 종성Table[종성Index]
                    
                    // 겹받침인지 확인 (예: '닭' -> 'ㄹ', 'ㄱ')
                    if let (앞받침, 뒷받침) = decompose겹받침(종성: 종성글자) {
                        guard let 앞받침Index = 종성Table.firstIndex(of: 앞받침),
                              let 뒷받침Index = 초성Table.firstIndex(of: 뒷받침),
                              let 중성InputIndex = 중성Table.firstIndex(of: 글자Input),
                              let 앞글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index),
                              let 뒷글자 = combine(초성Index: 뒷받침Index, 중성Index: 중성InputIndex, 종성Index: 0) else {
                            
                            assertionFailure("[\(#function)] Critical Error: 겹받침 분해/조합 실패 (Input: \(글자Input))")
                            return newText + 글자Input
                        }
                        
                        newText.removeLast()
                        newText.append(앞글자)
                        newText.append(뒷글자)
                        return newText
                    } else {
                        // 홑받침인 경우 (예: '각' + 'ㅏ' -> '가' + '가')
                        if let next글자초성Index = 초성Table.firstIndex(of: 종성글자) {
                            guard let 중성InputIndex = 중성Table.firstIndex(of: 글자Input),
                                  let 앞글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 0),
                                  let 뒷글자 = combine(초성Index: next글자초성Index, 중성Index: 중성InputIndex, 종성Index: 0) else {
                                
                                assertionFailure("[\(#function)] Critical Error: 종성 연음 조합 실패")
                                return newText + 글자Input
                            }
                            
                            newText.removeLast()
                            newText.append(앞글자)
                            newText.append(뒷글자)
                            return newText
                        }
                    }
                }
                // 1-2. 종성이 없는 경우 (예: '고' + 'ㅏ') -> 복모음 확인
                else {
                    let existing중성 = 중성Table[중성Index]
                    if let combined중성 = find겹모음(앞모음: existing중성, 뒷모음: 글자Input) {
                        guard let combined중성Index = 중성Table.firstIndex(of: combined중성),
                              let new글자 = combine(초성Index: 초성Index, 중성Index: combined중성Index, 종성Index: 0) else {
                            
                            assertionFailure("[\(#function)] Critical Error: 복모음 조합 실패")
                            return newText + 글자Input
                        }
                        
                        newText.removeLast()
                        newText.append(new글자)
                        return newText
                    }
                }
            }
            // 마지막 글자가 낱자 자음인 경우 (예: 'ㄱ' + 'ㅏ' -> '가')
            else if let last글자초성Index = 초성Table.firstIndex(of: String(beforeTextLast글자Char)) {
                guard let 중성Index = 중성Table.firstIndex(of: 글자Input),
                      let new글자 = combine(초성Index: last글자초성Index, 중성Index: 중성Index, 종성Index: 0) else {
                    
                    assertionFailure("[\(#function)] Critical Error: 자음+모음 결합 실패")
                    return newText + 글자Input
                }
                
                newText.removeLast()
                newText.append(new글자)
                return newText
            }
            // 마지막 글자가 낱자 모음인 경우 (예: 'ㅜ' + 'ㅓ' -> 'ㅝ')
            else if 중성Table.contains(String(beforeTextLast글자Char)) {
                if let combined중성 = find겹모음(앞모음: String(beforeTextLast글자Char), 뒷모음: 글자Input) {
                    newText.removeLast()
                    newText.append(combined중성)
                    return newText
                }
            }
        }
        
        // 2. 입력이 자음인 경우
        else if 초성Table.contains(글자Input) {
            // 마지막 글자가 완성된 한글인 경우
            if let (초성Index, 중성Index, 종성Index) = decompose(한글Char: beforeTextLast글자Char) {
                // 2-1. 종성이 없는 경우 (예: '가' + 'ㄱ' -> '각')
                if 종성Index == 0 {
                    // 입력된 자음이 종성으로 쓰일 수 있는지 확인
                    if let input종성Index = 종성Table.firstIndex(of: 글자Input) {
                        guard let new글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: input종성Index) else {
                            assertionFailure("[\(#function)] Critical Error: 종성 추가 실패")
                            return newText + 글자Input
                        }
                        
                        newText.removeLast()
                        newText.append(new글자)
                        return newText
                    }
                }
                // 2-2. 종성이 있는 경우 (예: '각' + 'ㅅ' -> 'ㄳ') -> 겹받침 확인
                else {
                    let existing종성 = 종성Table[종성Index]
                    if let combined종성 = find겹자음(앞자음: existing종성, 뒷자음: 글자Input) {
                        guard let combined종성Index = 종성Table.firstIndex(of: combined종성),
                              let new글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: combined종성Index) else {
                            
                            assertionFailure("[\(#function)] Critical Error: 겹받침 생성 실패")
                            return newText + 글자Input
                        }
                        
                        newText.removeLast()
                        newText.append(new글자)
                        return newText
                    }
                }
            }
        }
        
        // 위의 어떤 결합 조건에도 해당하지 않으면 그냥 추가
        return newText + 글자Input
    }
    
    func delete글자(beforeText: String) -> String {
        guard let beforeTextLast글자Char = beforeText.last else { return beforeText }
        
        var newText = beforeText
        
        // 1. 완성된 한글인 경우 분해 시도
        if let (초성Index, 중성Index, 종성Index) = decompose(한글Char: beforeTextLast글자Char) {
            newText.removeLast()
            
            // 1-1. 종성이 있는 경우
            if 종성Index != 0 {
                let 종성글자 = 종성Table[종성Index]
                
                // 겹받침이면 앞부분만 남김 (예: '닭' -> '달')
                if let (앞받침, _) = decompose겹받침(종성: 종성글자) {
                    guard let 앞받침Index = 종성Table.firstIndex(of: 앞받침),
                          let new글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 앞받침Index) else {
                        
                        assertionFailure("[\(#function)] Critical Error: 겹받침 삭제 분해 실패")
                        return beforeText
                    }
                    newText.append(new글자)
                } else {
                    // 홑받침이면 종성 제거 (예: '각' -> '가')
                    guard let new글자 = combine(초성Index: 초성Index, 중성Index: 중성Index, 종성Index: 0) else {
                        assertionFailure("[\(#function)] Critical Error: 홑받침 삭제 실패")
                        return beforeText
                    }
                    newText.append(new글자)
                }
            }
            // 1-2. 종성이 없고 중성만 있는 경우
            else {
                let 중성글자 = 중성Table[중성Index]
                
                // 겹모음이면 앞부분만 남김 (예: '와' -> '오')
                if let (앞모음, _) = decompose겹모음(중성: 중성글자) {
                    guard let 앞모음Index = 중성Table.firstIndex(of: 앞모음),
                          let new글자 = combine(초성Index: 초성Index, 중성Index: 앞모음Index, 종성Index: 0) else {
                        
                        assertionFailure("[\(#function)] Critical Error: 겹모음 삭제 분해 실패")
                        return beforeText
                    }
                    newText.append(new글자)
                } else {
                    // 단모음이면 모음 제거 후 초성만 남김 (예: '가' -> 'ㄱ')
                    newText.append(초성Table[초성Index])
                }
            }
        }
        // 2. 완성된 한글이 아닌 경우 (낱자 자음/모음, 혹은 특수문자)
        else {
            newText.removeLast()
            
            let last글자String = String(beforeTextLast글자Char)
            
            // 겹모음 낱자 분해 (예: 'ㅘ' -> 'ㅗ')
            if 중성Table.contains(last글자String),
               let (앞모음, _) = decompose겹모음(중성: last글자String) {
                newText.append(앞모음)
            }
        }
        
        return newText
    }
    
    func combine(초성Index: Int, 중성Index: Int, 종성Index: Int) -> Character? {
        let 한글Unicode = 한글UnicodeStart + UInt32(초성Index * 21 * 28) + UInt32(중성Index * 28) + UInt32(종성Index)
        guard let 한글Scalar = Unicode.Scalar(한글Unicode) else { return nil }
        return Character(한글Scalar)
    }
    
    func decompose(한글Char: Character) -> (초성Index: Int, 중성Index: Int, 종성Index: Int)? {
        guard let 한글Scalar = 한글Char.unicodeScalars.first,
              한글Scalar.value >= 한글UnicodeStart && 한글Scalar.value <= 한글UnicodeEnd else { return nil }
        
        let 한글unicode = 한글Scalar.value - 한글UnicodeStart
        let 초성Index = Int(한글unicode / (21 * 28))
        let 중성Index = Int((한글unicode % (21 * 28)) / 28)
        let 종성Index = Int(한글unicode % 28)
        
        return (초성Index, 중성Index, 종성Index)
    }
    
    // "ㄳ" -> ("ㄱ", "ㅅ")
    func decompose겹받침(종성: String) -> (String, String)? {
        for 조합 in 겹자음조합Table {
            if 조합.결과 == 종성 { return (조합.앞자음, 조합.뒷자음) }
        }
        return nil
    }
}

// MARK: - Private Methods

private extension HangeulAutomata {
    // ["ㅗ","ㅏ","ㅘ"] 형식의 테이블에서 조합 찾기
    func find겹모음(앞모음: String, 뒷모음: String) -> String? {
        for 조합 in 겹모음조합Table {
            if 조합.앞모음 == 앞모음 && 조합.뒷모음 == 뒷모음 { return 조합.결과 }
        }
        return nil
    }
    
    // "ㅘ" -> ("ㅗ", "ㅏ")
    func decompose겹모음(중성: String) -> (String, String)? {
        for 조합 in 겹모음조합Table {
            if 조합.결과 == 중성 { return (조합.앞모음, 조합.뒷모음) }
        }
        return nil
    }
    
    // ["ㄱ","ㅅ","ㄳ"] 형식의 테이블에서 조합 찾기
    func find겹자음(앞자음: String, 뒷자음: String) -> String? {
        for 조합 in 겹자음조합Table {
            if 조합.앞자음 == 앞자음 && 조합.뒷자음 == 뒷자음 { return 조합.결과 }
        }
        return nil
    }
}
