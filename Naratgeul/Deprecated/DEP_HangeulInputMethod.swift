//
//  DEP_HangeulInputMethod.swift
//  Naratgeul
//
//  Created by 서동환 on 9/9/24.
//
//  Deprecated) 기존 오토마타에 비해 뚜렷한 장점이 없음
//

import Foundation

enum GeuljaKind {
    case jaeum
    case moeum
    case hangeul  // 완성된 한글
    case other  // 한글이 아닌 글자
}

enum HangeulKind {
    case choJung
    case choJungJong
    case choJungDJong
}

final class DEP_HangeulInputMethod {
    private var nowGeulja: String = ""
    private var nowGeuljaKind: GeuljaKind = .other
    private var nowHangeulKind: HangeulKind? = nil
    private var nowGeuljaIndex: Int = 0
    private var d_nowGeuljaIndex: Int = 0
    private var nowGeuljaDecomposedIndexArr: [Int] = []
    
    private var oldGeulja: String = ""
    private var oldGeuljaKind: GeuljaKind = .other
    private var oldHangeulKind: HangeulKind? = nil
    private var oldGeuljaIndex: Int = 0
    private var oldGeuljaDecomposedIndexArr: [Int] = []
    
    private var buffer: [String] = []
    
    private var lastInput: String = ""
    
    private let CHO_SUNG: [String] = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let JUNG_SUNG: [String] = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    
    private let JONG_SUNG: [String] = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let D_JUNG_SUNG: [[String]] = [
        ["ㅗ","ㅏ","ㅘ"],
        ["ㅘ","ㅣ","ㅙ"],
        ["ㅗ","ㅐ","ㅙ"],
        ["ㅗ","ㅣ","ㅚ"],
        ["ㅜ","ㅓ","ㅝ"],
        ["ㅜ","ㅔ","ㅞ"],
        ["ㅝ","ㅣ","ㅞ"],
        ["ㅜ","ㅣ","ㅟ"],
        ["ㅡ","ㅣ","ㅢ"],
        ["ㅏ","ㅣ","ㅐ"],
        ["ㅓ","ㅣ","ㅔ"],
        ["ㅕ","ㅣ","ㅖ"],
        ["ㅑ","ㅣ","ㅒ"],
    ]
    
    private let D_JONG_SUNG: [[String]] = [
        ["ㄱ","ㅅ","ㄳ"],
        ["ㄴ","ㅈ","ㄵ"],
        ["ㄴ","ㅎ","ㄶ"],
        ["ㄹ","ㄱ","ㄺ"],
        ["ㄹ","ㅁ","ㄻ"],
        ["ㄹ","ㅂ","ㄼ"],
        ["ㄹ","ㅅ","ㄽ"],
        ["ㄹ","ㅌ","ㄾ"],
        ["ㄹ","ㅍ","ㄿ"],
        ["ㄹ","ㅎ","ㅀ"],
        ["ㅂ","ㅅ","ㅄ"]
    ]
    
    private func combinationHangeul(chosungIndex: Int, jungsungIndex: Int, jongsungIndex: Int = 0) -> String {
        let composed = (((UInt32(chosungIndex) * 21) + UInt32(jungsungIndex)) * 28) + UInt32(jongsungIndex) + 0xAC00
        return String(Unicode.Scalar(composed) ?? Unicode.Scalar(0))
    }

    private func isHangeul(unicodeValue: UInt32) -> Bool {
        if unicodeValue >= 0xAC00 && unicodeValue <= 0xD7A3 {
            return true
        }
        return false
    }
    
    private func attemptPairingJungsung(oldKeyIndex: Int, nowKeyIndex: Int) -> Bool {
        for i in 0..<D_JUNG_SUNG.count {
            if D_JUNG_SUNG[i][0] == JUNG_SUNG[oldKeyIndex] && D_JUNG_SUNG[i][1] == JUNG_SUNG[nowKeyIndex] {
                d_nowGeuljaIndex = JUNG_SUNG.firstIndex(of: D_JUNG_SUNG[i][2]) ?? 0
                return true
            }
        }
        return false
    }
    
    private func attemptPairingJongsung(oldKeyIndex: Int, nowKeyIndex: Int) -> Bool {
        for i in 0..<D_JONG_SUNG.count {
            if D_JONG_SUNG[i][0] == JONG_SUNG[oldKeyIndex] && D_JONG_SUNG[i][1] == CHO_SUNG[nowKeyIndex] {
                d_nowGeuljaIndex = JONG_SUNG.firstIndex(of: D_JONG_SUNG[i][2]) ?? 0
                return true
            }
        }
        return false
    }
    
    private func attemptDecomposingDJungsung(jungsungIndex: Int) -> [Int] {
        var result: [Int] = [jungsungIndex]
        for i in 0..<D_JUNG_SUNG.count {
            if D_JUNG_SUNG[i][2] == JUNG_SUNG[jungsungIndex] {
                result.removeAll()
                result.append(JUNG_SUNG.firstIndex(of: D_JUNG_SUNG[i][0]) ?? 0)
                result.append(JUNG_SUNG.firstIndex(of: D_JUNG_SUNG[i][1]) ?? 0)
                break
            }
        }
        return result
    }
    
    private func attemptDecomposingDJongsung(jongsungIndex: Int) -> [Int] {
        var result: [Int] = [jongsungIndex]
        for i in 0..<D_JONG_SUNG.count {
            if D_JONG_SUNG[i][2] == JONG_SUNG[jongsungIndex] {
                result.removeAll()
                result.append(JONG_SUNG.firstIndex(of: D_JONG_SUNG[i][0]) ?? 0)
                result.append(JONG_SUNG.firstIndex(of: D_JONG_SUNG[i][1]) ?? 0)
                break
            }
        }
        return result
    }
    
    private func decomposeHangeul(char: Character) -> [Int] {
        //  리턴이 1개면 한글 X, 2개 이상이면 한글 O
        let unicodeValue = char.unicodeScalars.first!.value
        if isHangeul(unicodeValue: unicodeValue) {
            let hangeulBase = unicodeValue - 0xAC00
            let chosungIndex = Int(hangeulBase / 28 / 21)
            let jungsungIndex = Int((hangeulBase % (21 * 28)) / 28)
            let jongsungIndex = Int(hangeulBase % 28)
            
            var result = [chosungIndex, jungsungIndex]
            if jongsungIndex > 0 {
                result += attemptDecomposingDJongsung(jongsungIndex: jongsungIndex)
            }
            return result
        }
        return []
    }
    
    private func setupGeuljaKind() {
        if CHO_SUNG.contains(nowGeulja) {
            nowGeuljaKind = .jaeum
            nowGeuljaIndex = CHO_SUNG.firstIndex(of: nowGeulja) ?? 0
        } else if JUNG_SUNG.contains(nowGeulja) {
            nowGeuljaKind = .moeum
            nowGeuljaIndex = JUNG_SUNG.firstIndex(of: nowGeulja) ?? 0
        } else {
            nowGeuljaKind = .hangeul
            nowGeuljaDecomposedIndexArr = decomposeHangeul(char: Character(nowGeulja))
            switch nowGeuljaDecomposedIndexArr.count {
            case 2:
                nowHangeulKind = .choJung
            case 3:
                nowHangeulKind = .choJungJong
            case 4:
                nowHangeulKind = .choJungDJong
            default:  // nowGeulja가 기호 문자임
                nowGeuljaKind = .other
            }
        }
        
        if !oldGeulja.isEmpty {
            if CHO_SUNG.contains(oldGeulja) {
                oldGeuljaKind = .jaeum
                oldGeuljaIndex = CHO_SUNG.firstIndex(of: oldGeulja) ?? 0
            } else if JUNG_SUNG.contains(oldGeulja) {
                oldGeuljaKind = .moeum
                oldGeuljaIndex = JUNG_SUNG.firstIndex(of: oldGeulja) ?? 0
            } else {
                oldGeuljaKind = .hangeul
                oldGeuljaDecomposedIndexArr = decomposeHangeul(char: Character(oldGeulja))
                switch oldGeuljaDecomposedIndexArr.count {
                case 2:
                    oldHangeulKind = .choJung
                case 3:
                    oldHangeulKind = .choJungJong
                case 4:
                    oldHangeulKind = .choJungDJong
                default:  // oldGeulja가 기호 문자임
                    oldGeuljaKind = .other
                }
            }
        }
    }
    
    private func removeNowGeuljaOnly() -> [String] {
        var result: [String] = []
        
        switch nowGeuljaKind {
        case .moeum:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 모음 or 겹중성
            let newJungsungIndexArr = attemptDecomposingDJungsung(jungsungIndex: nowGeuljaIndex)
            if newJungsungIndexArr.count == 1 {
                // nowGeulja가 모음 => 삭제
                result = []
            } else {
                // nowGeulja가 겹중성 => 중성
                result = [JUNG_SUNG[newJungsungIndexArr[0]]]
            }
        case .hangeul:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 완성된 한글
            switch nowHangeulKind {
            case .choJung:  // nowGeulja에 초성과 중성(겹중성)만 존재
                let newJungsungIndexArr = attemptDecomposingDJungsung(jungsungIndex: nowGeuljaDecomposedIndexArr[1])
                if newJungsungIndexArr.count == 1 {
                    // nowGeulja에 중성 => 초성
                    result = [CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]]
                } else {
                    // nowGeulja에 겹중성 => 초성 + 중성
                    result = [combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                 jungsungIndex: newJungsungIndexArr[0])]
                }
            case .choJungJong:  // nowGeulja에 초성, 중성, 종성 존재
                // nowGeulja 종성 삭제 => 초성 + 중성
                result = [combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                            jungsungIndex: nowGeuljaDecomposedIndexArr[1])]
            case .choJungDJong:  // nowGeulja에 초성, 중성, 겹종성 존재
                // nowGeulja 겹종성 삭제 => 초성 + 중성 + 종성
                result = [combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                             jungsungIndex: nowGeuljaDecomposedIndexArr[1],
                                             jongsungIndex: nowGeuljaDecomposedIndexArr[2])]
            default:
                break
            }
        default:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 자음 or 기호
            // => 삭제
            result = []
        }
        
        return result
    }
    
    private func getLastInputFromGeulja(_ geulja: String) -> String {
        if CHO_SUNG.contains(geulja) || JUNG_SUNG.contains(geulja) {
            return geulja
        } else {
            let decomposeIndexArr = decomposeHangeul(char: Character(geulja))
            switch decomposeIndexArr.count {
            case 2:
                let newJungsungIndexArr = attemptDecomposingDJungsung(jungsungIndex: decomposeIndexArr[1])
                if newJungsungIndexArr.count == 1 {
                    return JUNG_SUNG[newJungsungIndexArr[0]]
                } else {
                    return JUNG_SUNG[newJungsungIndexArr[1]]
                }
            case 3:
                return JONG_SUNG[decomposeIndexArr[2]]
            case 4:
                return JONG_SUNG[decomposeIndexArr[3]]
            default:  // geulja가 기호 문자임
                return geulja
            }
        }
    }
}

extension DEP_HangeulInputMethod {
    func getLastInput() -> String {
        return lastInput
    }
    
    func deleteBufferLast() {
        if !buffer.isEmpty {
            buffer.removeLast()
        }
    }
    
    func resetAutomata() {
        nowGeulja = ""
        nowGeuljaKind = .other
        nowHangeulKind = nil
        nowGeuljaIndex = 0
        d_nowGeuljaIndex = 0
        nowGeuljaDecomposedIndexArr = []
        
        oldGeulja = ""
        oldGeuljaKind = .other
        oldHangeulKind = nil
        oldGeuljaIndex = 0
        oldGeuljaDecomposedIndexArr = []
    }
    
    func getBufferIsEmpty() -> Bool {
        return buffer.isEmpty
    }
    
    func flushBuffer() {
        buffer.removeAll()
        lastInput.removeAll()
    }
    
    func inputMethod(key: String) -> [String] {
        var result: [String] = []
        
        if key == "" {
            return result
        }
        
        oldGeulja = buffer.last ?? ""
        nowGeulja = key
        
        setupGeuljaKind()
        
        if oldGeulja.isEmpty {
            result.append(nowGeulja)
        } else {
            switch oldGeuljaKind {
            case .jaeum:
                if nowGeuljaKind == .moeum {  // oldGeulja가 자음 + nowGeulja가 모음
                    // 한글 조합 => oldGeulja + nowGeulja
                    result = [combinationHangeul(chosungIndex: oldGeuljaIndex,
                                                 jungsungIndex: nowGeuljaIndex)]

                } else {  // oldGeulja가 자음 + nowGeulja가 자음 or 기호
                    // => 새로운 글자 추가
                    result = [oldGeulja, nowGeulja]
                }
            case .moeum:
                if nowGeuljaKind == .moeum {  // oldGeulja가 모음 + nowGeulja가 모음 or 겹중성
                    if attemptPairingJungsung(oldKeyIndex: oldGeuljaIndex, nowKeyIndex: nowGeuljaIndex) {
                        // 겹중성 가능 => 겹중성 조합
                        result = [JUNG_SUNG[d_nowGeuljaIndex]]
                    } else {
                        // 겹중성 불가 => 새로운 글자 추가
                        result = [oldGeulja, nowGeulja]
                    }
              
                } else {  // oldGeulja가 모음 + nowGeulja가 자음 or 기호
                    // => 새로운 글자 추가
                    result = [oldGeulja, nowGeulja]
                }
            case .hangeul:
                if nowGeuljaKind == .moeum {
                    switch oldHangeulKind {
                    case .choJung:  // oldGeulja에 초성과 중성(겹중성)만 존재 + nowGeulja가 모음
                        if attemptPairingJungsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[1], nowKeyIndex: nowGeuljaIndex) {
                            // 겹중성 가능 => 겹중성으로 한글 결합
                            result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: d_nowGeuljaIndex)]
                        } else {
                            // 겹중성 불가 => 새로운 글자 추가
                            result = [oldGeulja, nowGeulja]
                        }
                    case .choJungJong:  // oldGeulja에 초성, 중성, 종성 존재 + nowGeulja가 모음
                        // 한글 조합 => oldGeulja 종성 + nowGeulja
                        let newChosungIndex = CHO_SUNG.firstIndex(of: JONG_SUNG[oldGeuljaDecomposedIndexArr[2]]) ?? 0
                        result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                     jungsungIndex: oldGeuljaDecomposedIndexArr[1]),
                                  combinationHangeul(chosungIndex: newChosungIndex,
                                                     jungsungIndex: nowGeuljaIndex)]
                    case .choJungDJong:  // oldGeulja에 초성, 중성, 겹종성 존재 + nowGeulja가 모음
                        // 한글 조합 => oldGeulja 겹종성 분리 + nowGeulja
                        let newChosungIndex = CHO_SUNG.firstIndex(of: JONG_SUNG[oldGeuljaDecomposedIndexArr[3]]) ?? 0
                        result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                     jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                     jongsungIndex: oldGeuljaDecomposedIndexArr[2]),
                                  combinationHangeul(chosungIndex: newChosungIndex,
                                                     jungsungIndex: nowGeuljaIndex)]
                    default:
                        break
                    }
                    
                } else if nowGeuljaKind == .jaeum {
                    switch oldHangeulKind {
                    case .choJung:  // oldGeulja에 초성과 중성(겹중성)만 존재 + nowGeulja가 자음
                        // 한글 조합 => oldGeulja + nowGeulja
                        nowGeuljaIndex = JONG_SUNG.firstIndex(of: nowGeulja) ?? 0
                        result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                     jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                     jongsungIndex: nowGeuljaIndex)]
                    case .choJungJong:  // oldGeulja에 초성, 중성, 종성 존재 + nowGeulja가 자음
                        if attemptPairingJongsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[2], nowKeyIndex: nowGeuljaIndex) {
                            // 겹종성 가능 => 겹종성으로 한글 결합
                            result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                         jongsungIndex: d_nowGeuljaIndex)]
                        } else {
                            // 겹종성 불가 => 새로운 글자 추가
                            result = [oldGeulja, nowGeulja]
                        }
                    case .choJungDJong:  // oldGeulja에 초성, 중성, 겹종성 존재 + nowGeulja가 자음
                        // => 새로운 글자 추가
                        result = [oldGeulja, nowGeulja]
                    default:
                        break
                    }
                    
                } else {  // nowGeulja가 한글 or 기호 문자
                    // => 새로운 글자 추가
                    result = [oldGeulja, nowGeulja]
                }
            case .other:  // oldGeulja가 기호 문자
                // => 새로운 글자 추가
                result = [oldGeulja, nowGeulja]
            }
        }
        if oldGeulja != "" {
            buffer.removeLast()
        }
        
        lastInput = key
        buffer += result
        print(buffer)
        
        resetAutomata()
        return result
    }
    
    func removeMethod() -> [String] {
        var result: [String] = []
        let suffixTwoGeulja: [String] = buffer.suffix(2)
        
        
        if suffixTwoGeulja.count == 1 {
            self.oldGeulja = ""
            self.nowGeulja = String(suffixTwoGeulja.last!)
            
            setupGeuljaKind()
            result = removeNowGeuljaOnly()
            
        } else if suffixTwoGeulja.count == 2 {
            self.oldGeulja = String(suffixTwoGeulja.first!)
            self.nowGeulja = String(suffixTwoGeulja.last!)
            
            setupGeuljaKind()
            
            switch nowGeuljaKind {
            case .moeum:  // buffer에 oldGeulja, nowGeulja 모두 존재 + nowGeulja가 모음 or 겹중성
                let newJungsungIndexArr = attemptDecomposingDJungsung(jungsungIndex: nowGeuljaIndex)
                if newJungsungIndexArr.count == 1 {
                    // nowGeulja가 모음 => 삭제
                    result = [oldGeulja]
                } else {
                    // nowGeulja가 겹중성 => 중성
                    result = [oldGeulja, JUNG_SUNG[newJungsungIndexArr[0]]]
                }
            case .hangeul:  // buffer에 oldGeulja, nowGeulja 모두 존재 + nowGeulja가 완성된 한글
                if oldGeuljaKind == .hangeul {  // oldGeulja가 한글
                    switch nowHangeulKind {
                    case .choJung:  // nowGeulja에 초성과 중성(겹중성)만 존재
                        let newJungsungIndexArr = attemptDecomposingDJungsung(jungsungIndex: nowGeuljaDecomposedIndexArr[1])
                        if newJungsungIndexArr.count == 1 {
                            // nowGeulja에 중성 => 삭제, 초성을 oldGeulja와 조합
                            switch oldHangeulKind {
                            case .choJung:  // oldGeulja에 초성과 중성(겹중성)만 존재
                                // => oldGeulja에 종성 결합
                                let newJongsungIndex = JONG_SUNG.firstIndex(of: CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]) ?? 0
                                result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                             jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                             jongsungIndex: newJongsungIndex)]
                            case .choJungJong:  // oldGeulja에 초성, 중성, 종성 존재
                                if attemptPairingJongsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[2], nowKeyIndex: nowGeuljaDecomposedIndexArr[0]) {
                                    // 겹종성 가능 => oldGeulja에 겹종성 결합
                                    result = [combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                                 jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                                 jongsungIndex: d_nowGeuljaIndex)]
                                } else {
                                    // 겹종성 불가 => nowGeulja에 초성만 남김
                                    result = [oldGeulja, CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]]
                                }
                            case .choJungDJong:  // oldGeulja에 초성, 중성, 겹종성 존재
                                // nowGeulja에 초성만 남김
                                result = [oldGeulja, CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]]
                            default:
                                break
                            }
                        } else {
                            // nowGeulja에 겹중성 => 초성 + 중성
                            result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                    jungsungIndex: newJungsungIndexArr[0])]
                        }
                    case .choJungJong:  // nowGeulja에 초성, 중성, 종성 존재
                        // => nowGeulja에 초성 + 중성만 님김
                        result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                jungsungIndex: nowGeuljaDecomposedIndexArr[1])]
                    case.choJungDJong:  // nowGeulja에 초성, 중성, 겹종성 존재
                        // nowGeulja의 겹종성 => 종성
                        result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                jungsungIndex: nowGeuljaDecomposedIndexArr[1],
                                                                jongsungIndex: nowGeuljaDecomposedIndexArr[2])]
                    default:
                        break
                    }
                } else {  // oldGeulja가 자음 or 모음 or 기호
                    result = [oldGeulja] + removeNowGeuljaOnly()
                }
            default:  // buffer에 oldGeulja, nowGeulja 모두 존재 + nowGeulja가 자음 or 기호
                // => 삭제
                result = [oldGeulja]
            }
            
        } else {  // buffer가 비어있음
            result = []
        }
        
        for _ in 0..<suffixTwoGeulja.count {
            buffer.removeLast()
        }
        buffer += result
        print(buffer)
        
        if let lastGeulja = result.last {
            lastInput = getLastInputFromGeulja(lastGeulja)
        } else {
            lastInput = ""
        }
        resetAutomata()
        return result
    }
}
