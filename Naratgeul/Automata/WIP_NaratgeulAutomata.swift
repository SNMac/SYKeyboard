//
//  NaratgeulAutomata.swift
//  Naratgeul
//
//  Created by 서동환 on 9/9/24.
//

import Foundation

enum HangeulKind {
    case jaeum
    case moeum
    case hangeul  // 완성된 한글
    case other  // 한글이 아닌 글자
}

final class WIP_NaratgeulAutomata {
    private var nowGeulja: String = ""
    private var nowGeuljaKind: HangeulKind = .other
    private var nowGeuljaIndex: Int = 0
    private var d_nowGeuljaIndex: Int = 0
    private var nowGeuljaDecomposedIndexArr: [Int] = []
    
    private var oldGeulja: String = ""
    private var oldGeuljaKind: HangeulKind = .other
    private var oldGeuljaIndex: Int = 0
    private var oldGeuljaDecomposedIndexArr: [Int] = []
    
    private var buffer: [String] = []
    
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
    
//    private func isHangeul(char: Character) -> Bool {
//        let unicodeValue = char.unicodeScalars.first!.value
//        if unicodeValue >= 0xAC00 && unicodeValue <= 0xD7A3 {
//            return true
//        }
//        return false
//    }
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
    
    private func dJungsungToJungsung(jungsungIndex: Int) -> Int {  // removeAutomata()에서만 사용
        var result: Int = jungsungIndex
        for i in 0..<D_JUNG_SUNG.count {
            if D_JUNG_SUNG[i][2] == JUNG_SUNG[jungsungIndex] {
                result = JUNG_SUNG.firstIndex(of: D_JUNG_SUNG[i][0]) ?? 0
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
    
    private func combinationHangeul(chosungIndex: Int, jungsungIndex: Int, jongsungIndex: Int = 0) -> String {
        let composed = (((UInt32(chosungIndex) * 21) + UInt32(jungsungIndex)) * 28) + UInt32(jongsungIndex) + 0xAC00
        return String(Unicode.Scalar(composed) ?? Unicode.Scalar(0))
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
    
    private func setupOldGeuljaKind() {
        if CHO_SUNG.contains(oldGeulja) {
            oldGeuljaKind = .jaeum
            oldGeuljaIndex = CHO_SUNG.firstIndex(of: oldGeulja) ?? 0
        } else if JUNG_SUNG.contains(oldGeulja) {
            oldGeuljaKind = .moeum
            oldGeuljaIndex = JUNG_SUNG.firstIndex(of: oldGeulja) ?? 0
        } else {
            oldGeuljaDecomposedIndexArr = decomposeHangeul(char: Character(oldGeulja))
            if oldGeuljaDecomposedIndexArr.count > 1 {  // oldGeulja가 완성된 한글임
                oldGeuljaKind = .hangeul
            } else {  // oldGeulja가 기호 문자임
                oldGeuljaKind = .other
            }
        }
    }
    
    private func setupNowGeuljaKind() {
        if CHO_SUNG.contains(nowGeulja) {
            nowGeuljaKind = .jaeum
            nowGeuljaIndex = CHO_SUNG.firstIndex(of: nowGeulja) ?? 0
        } else if JUNG_SUNG.contains(nowGeulja) {
            nowGeuljaKind = .moeum
            nowGeuljaIndex = JUNG_SUNG.firstIndex(of: nowGeulja) ?? 0
        } else {
            nowGeuljaDecomposedIndexArr = decomposeHangeul(char: Character(nowGeulja))
            if nowGeuljaDecomposedIndexArr.count > 1 {  // nowGeulja가 완성된 한글임
                nowGeuljaKind = .hangeul
            } else {  // nowGeulja가 기호 문자임
                nowGeuljaKind = .other
            }
        }
    }
    
    func resetAutomata() {
        nowGeulja = ""
        nowGeuljaKind = .other
        nowGeuljaIndex = 0
        d_nowGeuljaIndex = 0
        nowGeuljaDecomposedIndexArr = []
        
        oldGeulja = ""
        oldGeuljaKind = .other
        oldGeuljaIndex = 0
        oldGeuljaDecomposedIndexArr = []
    }
    
    func flushBuffer() {
        buffer = []
    }
}

extension WIP_NaratgeulAutomata {
    func naratgeulAutomata(now: String) -> [String] {
        var result: [String] = []
        
        if now == "" {
            return result
        }
        
        oldGeulja = buffer.last ?? ""
        nowGeulja = now
        
        setupNowGeuljaKind()
        
        if oldGeulja.isEmpty {
            result.append(nowGeulja)
        } else {
            setupOldGeuljaKind()
            
            switch oldGeuljaKind {
            case .jaeum:
                if nowGeuljaKind == .moeum {  // oldGeulja가 자음 + nowGeulja가 모음
                    // => 한글 조합
                    result.append(combinationHangeul(chosungIndex: oldGeuljaIndex,
                                                     jungsungIndex: nowGeuljaIndex))
                    
                } else {  // oldGeulja가 자음 + nowGeulja가 자음 or 기호
                    // => 새로운 글자
                    result = [oldGeulja, nowGeulja]
                }
                
            case .moeum:
                if nowGeuljaKind == .moeum {  // oldGeulja가 모음 + nowGeulja가 모음 or 겹중성
                    if attemptPairingJungsung(oldKeyIndex: oldGeuljaIndex, nowKeyIndex: nowGeuljaIndex) {
                        // => 겹중성
                        result.append(JUNG_SUNG[d_nowGeuljaIndex])
                        
                    } else {
                        // => 새로운 글자
                        result = [oldGeulja, nowGeulja]
                    }
                } else {  // oldGeulja가 모음 + nowGeulja가 자음 or 기호
                    // => 새로운 글자
                    result = [oldGeulja, nowGeulja]
                }
                
            case .hangeul:
                if nowGeuljaKind == .moeum {
                    if oldGeuljaDecomposedIndexArr.count == 2 {  // oldGeulja에 초성과 중성(겹중성)만 존재 + nowGeulja가 모음
                        if attemptPairingJungsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[1], nowKeyIndex: nowGeuljaIndex) {
                            // => 겹중성
                            result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                             jungsungIndex: d_nowGeuljaIndex))
                        } else {
                            // => 새로운 글자
                            result = [oldGeulja, nowGeulja]
                        }
                        
                    } else if oldGeuljaDecomposedIndexArr.count == 3 {  // oldGeulja에 초성, 중성, 종성 존재 + nowGeulja가 모음
                        // => 새로운 한글 조합
                        result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: oldGeuljaDecomposedIndexArr[1]))
                        
                        let newChosungIndex = CHO_SUNG.firstIndex(of: JONG_SUNG[oldGeuljaDecomposedIndexArr[2]]) ?? 0
                        result.append(combinationHangeul(chosungIndex: newChosungIndex,
                                                         jungsungIndex: nowGeuljaIndex))
                        
                    } else {  // oldGeulja에 초성, 중성, 겹종성 존재 + nowGeulja가 모음
                        // => 새로운 한글 조합
                        result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                         jongsungIndex: oldGeuljaDecomposedIndexArr[2]))
                        
                        let newChosungIndex = CHO_SUNG.firstIndex(of: JONG_SUNG[oldGeuljaDecomposedIndexArr[3]]) ?? 0
                        result.append(combinationHangeul(chosungIndex: newChosungIndex, jungsungIndex: nowGeuljaIndex))
                    }
                    
                } else if nowGeuljaKind == .jaeum {
                    if oldGeuljaDecomposedIndexArr.count == 2 {  // oldGeulja에 초성과 중성(겹중성)만 존재 + nowGeulja가 자음
                        // => 종성
                        nowGeuljaIndex = JONG_SUNG.firstIndex(of: nowGeulja) ?? 0
                        result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                         jongsungIndex: nowGeuljaIndex))
                        
                    } else if oldGeuljaDecomposedIndexArr.count == 3 {  // oldGeulja에 초성, 중성, 종성 존재 + nowGeulja가 자음
                        if attemptPairingJongsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[2], nowKeyIndex: nowGeuljaIndex) {
                            // => 겹종성
                            result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                             jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                             jongsungIndex: d_nowGeuljaIndex))
                            
                        } else {
                            // => 새로운 글자
                            result = [oldGeulja, nowGeulja]
                        }
                        
                    } else {  // oldGeulja에 초성, 중성, 겹종성 존재 + nowGeulja가 자음
                        // => 새로운 글자
                        result = [oldGeulja, nowGeulja]
                    }
                } else {  // nowGeulja가 기호 문자
                    // => 새로운 글자
                    result = [oldGeulja, nowGeulja]
                }
            case .other:  // oldGeulja가 기호 문자
                // => 새로운 글자
                result = [oldGeulja, nowGeulja]
            }
        }
        if oldGeulja != "" {
            buffer.removeLast()
        }
        buffer += result
        print(buffer)
        resetAutomata()
        return result
    }
    
    func removeAutomata() -> [String] {
        var result: [String] = []
        let suffixTwoGeulja: [String] = buffer.suffix(2)
        
        if suffixTwoGeulja.count == 1 {
            self.oldGeulja = ""
            self.nowGeulja = String(suffixTwoGeulja.last!)
            
            setupNowGeuljaKind()
            
            switch nowGeuljaKind {
            case .moeum:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 모음 or 겹중성
                let newJungsungIndex = dJungsungToJungsung(jungsungIndex: nowGeuljaIndex)
                if newJungsungIndex != nowGeuljaIndex {
                    // 겹중성 => 중성
                    result.append(JUNG_SUNG[newJungsungIndex])
                    
                } else {
                    // 모음 => 삭제
                    result = []
                }
                
            case .hangeul:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 완성된 한글
                if nowGeuljaDecomposedIndexArr.count == 2 {  // nowGeulja에 초성과 중성(겹중성)만 존재
                    let newJungsungIndex = dJungsungToJungsung(jungsungIndex: nowGeuljaDecomposedIndexArr[1])
                    if newJungsungIndex != nowGeuljaDecomposedIndexArr[1] {
                        // nowGeulja에 겹중성 => 초성 + 중성
                        result.append(combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                         jungsungIndex: newJungsungIndex))
                    } else {
                        // nowGeulja에 중성 => 초성
                        result.append(CHO_SUNG[nowGeuljaDecomposedIndexArr[0]])
                    }
                    
                } else if nowGeuljaDecomposedIndexArr.count == 3 {  // nowGeulja에 초성, 중성, 종성 존재
                    // => 초성 + 중성
                    result.append(combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                     jungsungIndex: nowGeuljaDecomposedIndexArr[1]))
                    
                } else {  // nowGeulja에 초성, 중성, 겹종성 존재
                    // => 초성 + 중성 + 종성
                    result.append(combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                     jungsungIndex: nowGeuljaDecomposedIndexArr[1],
                                                     jongsungIndex: nowGeuljaDecomposedIndexArr[2]))
                }
                
            default:  // buffer에 nowGeulja 하나만 존재 + nowGeulja가 자음 or 기호
                // => 삭제
                result = []
            }
            
        } else if suffixTwoGeulja.count == 2 {
            self.oldGeulja = String(suffixTwoGeulja.first!)
            self.nowGeulja = String(suffixTwoGeulja.last!)
            
            setupOldGeuljaKind()
            setupNowGeuljaKind()
            
            switch nowGeuljaKind {
            case .moeum:  // buffer에 oldGeulja, nowGeulja 모두 존재 + nowGeulja가 모음 or 겹중성
                let newJungsungIndex = dJungsungToJungsung(jungsungIndex: nowGeuljaIndex)
                if newJungsungIndex != nowGeuljaIndex {
                    // 겹중성 => 중성
                    result = [oldGeulja, JUNG_SUNG[newJungsungIndex]]
                    
                } else {
                    // 모음 => 삭제
                    result = [oldGeulja]
                }
                
            case .hangeul:  // buffer에 oldGeulja, nowGeulja 모두 존재 + nowGeulja가 완성된 한글
                if oldGeuljaKind == .hangeul {
                    if nowGeuljaDecomposedIndexArr.count == 2 {  // nowGeulja에 초성과 중성(겹중성)만 존재
                        let newJungsungIndex = dJungsungToJungsung(jungsungIndex: nowGeuljaDecomposedIndexArr[1])
                        if newJungsungIndex != nowGeuljaDecomposedIndexArr[1] {
                            // 겹중성 => 중성
                            result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                    jungsungIndex: newJungsungIndex)]
                            
                        } else {
                            // 중성 => 삭제, 초성을 oldGeulja와 조합
                            let newJongsungIndex = JONG_SUNG.firstIndex(of: CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]) ?? 0
                            if oldGeuljaDecomposedIndexArr.count == 2 {  // oldGeulja에 초성과 중성(겹중성)만 존재
                                // => 초성 + 중성 + 종성
                                result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                                 jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                                 jongsungIndex: newJongsungIndex))
                                
                            } else if oldGeuljaDecomposedIndexArr.count == 3 {  // oldGeulja에 초성, 중성, 종성 존재
                                if attemptPairingJongsung(oldKeyIndex: oldGeuljaDecomposedIndexArr[2], nowKeyIndex: newJongsungIndex) {
                                    // 종성 => 겹종성
                                    result.append(combinationHangeul(chosungIndex: oldGeuljaDecomposedIndexArr[0],
                                                                     jungsungIndex: oldGeuljaDecomposedIndexArr[1],
                                                                     jongsungIndex: d_nowGeuljaIndex))
                                } else {
                                    // 겹종성 불가 => nowGeulja에 초성만 남김
                                    result = [oldGeulja, CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]]
                                }
                            } else {  // oldGeulja에 초성, 중성, 겹종성 존재
                                result = [oldGeulja, CHO_SUNG[nowGeuljaDecomposedIndexArr[0]]]
                            }
                        }
                        
                    } else if nowGeuljaDecomposedIndexArr.count == 3 {  // nowGeulja에 초성, 중성, 종성 존재
                        // => 초성 + 중성
                        result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                jungsungIndex: nowGeuljaDecomposedIndexArr[1])]
                        
                    } else {  // nowGeulja에 초성, 중성, 겹종성 존재
                        // 겹종성 => 종성
                        result = [oldGeulja, combinationHangeul(chosungIndex: nowGeuljaDecomposedIndexArr[0],
                                                                jungsungIndex: nowGeuljaDecomposedIndexArr[1],
                                                                jongsungIndex: nowGeuljaDecomposedIndexArr[2])]
                    }
                    
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
        resetAutomata()
        return result
    }
}
