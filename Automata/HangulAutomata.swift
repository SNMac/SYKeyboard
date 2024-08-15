//
//  HangulAutomata.swift
//  SYKeyboard
//
//  Created by JunHwan Kim on 2022/07/14.
//  Edited by 서동환 on 7/31/24.
//  - Downloaded from https://github.com/Kim-Junhwan/IOS-CustomKeyboard - HangulAutomata.swift
//

import Foundation

// 오토마타의 상태를 정의
enum HangulStatus {
    case start //s0
    case chosung //s1
    case jungsung, dJungsung //s2,s3
    case jongsung, dJongsung //s4, s5
    case endOne, endTwo //s6,s7
}

// 입력된 키의 종류 판별 정의
enum HangulCHKind {
    case jaeum  // 자음
    case moeum  // 모음
    case symbol  // 기호
}

// 키 입력마다 쌓이는 입력 스택 정의
struct InpStack {
    var hangulStatus: HangulStatus  // 상태
    var keyKind: HangulCHKind  // 입력된 키가 자음인지 모임인지
    var keyIndex: UInt32  // 방금 입력된 키의 테이블 인덱스
    var geulja: String  // 조합된 글자
    var hasChosung: Bool
}

final class HangulAutomata {
    
    var buffer: [String] = []
    
    var inpStack: [InpStack] = []
    
    var curHanStatus: HangulStatus?
    
    private var oldKeyKind: HangulCHKind?
    private var oldKeyIndex: UInt32 = 0
    private var curKeyKind = HangulCHKind.moeum
    private var curKeyIndex: UInt32 = 0
    private var curGeulja: String = ""
    private var curHasChosung: Bool = false
    
    private let chosungTable: [String] = ["ㄱ","ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let jungsungTable: [String] = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    
    private let jongsungTable: [String] = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ","ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let dJungsungTable: [[String]] = [
        ["ㅗ","ㅏ","ㅘ"],
        ["ㅗ","ㅐ","ㅙ"],
        ["ㅗ","ㅣ","ㅚ"],
        ["ㅜ","ㅓ","ㅝ"],
        ["ㅜ","ㅔ","ㅞ"],
        ["ㅜ","ㅣ","ㅟ"],
        ["ㅡ","ㅣ","ㅢ"],
        ["ㅏ","ㅣ","ㅐ"],
        ["ㅓ","ㅣ","ㅔ"],
        ["ㅕ","ㅣ","ㅖ"],
        ["ㅑ","ㅣ","ㅒ"],
        ["ㅘ","ㅣ","ㅙ"]
    ]
    
    private let dJongsungTable: [[String]] = [
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
    
    private let symbolTable: [String] = [
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
        "-", "/", ":", ";", "(", ")", "₩", "&", "@", "\"",
        "[", "]", "{", "}", "#", "%", "^", "*", "+", "=",
        "_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•",
                    ".", ",", "?", "!", "'"
    ]
    
    private func jungsungPair() -> Bool {
        for i in 0..<dJungsungTable.count {
            if dJungsungTable[i][0] == jungsungTable[Int(oldKeyIndex)] && dJungsungTable[i][1] == jungsungTable[Int(curKeyIndex)] {
                curKeyIndex = UInt32(jungsungTable.firstIndex(of: dJungsungTable[i][2]) ?? 0)
                return true
            }
        }
        return false
    }
    
    private func jongsungPair() -> Bool {
        for i in 0..<dJongsungTable.count {
            if dJongsungTable[i][0] == jongsungTable[Int(oldKeyIndex)] && dJongsungTable[i][1] == chosungTable[Int(curKeyIndex)] {
                curKeyIndex = UInt32(jongsungTable.firstIndex(of: dJongsungTable[i][2]) ?? 0)
                return true
            }
        }
        return false
    }
    
    private func isJungsungPair(first: String, result: String) -> Bool {
        for i in 0..<dJungsungTable.count {
            if dJungsungTable[i][0] == first && dJungsungTable[i][2] == result {
                return true
            }
        }
        return false
    }
    
    private func decompositionChosung(charCode: UInt32) -> UInt32 {
        let unicodeHangul = charCode - 0xAC00
        let jongsung = (unicodeHangul) % 28
        let jungsung = ((unicodeHangul - jongsung) / 28) % 21
        let chosung = (((unicodeHangul - jongsung) / 28) - jungsung) / 21
        return chosung
    }
    
    private func decompositionChosungJungsung(charCode: UInt32) -> UInt32 {
        let unicodeHangul = charCode - 0xAC00
        let jongsung = (unicodeHangul) % 28
        let jungsung = ((unicodeHangul - jongsung) / 28) % 21
        let chosung = (((unicodeHangul - jongsung) / 28) - jungsung) / 21
        return combinationHangul(chosungIndex: chosung, jungsungIndex: jungsung, jongsungIndex: curKeyIndex)
    }
    
    private func combinationHangul(chosungIndex: UInt32 = 0, jungsungIndex: UInt32, jongsungIndex: UInt32 = 0) -> UInt32 {
        return (((chosungIndex * 21) + jungsungIndex) * 28) + jongsungIndex + 0xAC00
    }
    
    @discardableResult
    func deleteBuffer() -> String {
        var ret: String = ""
        
        if inpStack.count == 0 {
            if buffer.count > 0 {
                buffer.removeLast()
            }
        } else {
            if let popHanguel = inpStack.popLast() {
                if popHanguel.hangulStatus == .chosung {
                    buffer.removeLast()
                } else if popHanguel.hangulStatus == .jungsung || popHanguel.hangulStatus == .dJungsung {
                    if inpStack[inpStack.count - 1].hangulStatus == .jongsung || inpStack[inpStack.count - 1].hangulStatus == .dJongsung {
                        buffer.removeLast()
                    }
                    buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                } else {
                    if inpStack.isEmpty {
                        buffer.removeLast()
                    } else if popHanguel.keyKind == .moeum {
                        if inpStack[inpStack.count - 1].hangulStatus == .jongsung {
                            if inpStack[inpStack.count - 1].keyKind == .moeum {
                                if isJungsungPair(
                                    first: jungsungTable[Int(inpStack[inpStack.count - 1].keyIndex)], result: jungsungTable[Int(popHanguel.keyIndex)]) {
                                    buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                                } else {
                                    buffer.removeLast()
                                }
                            }
                        } else {
                            buffer.removeLast()
                        }
                    } else if popHanguel.keyKind == .jaeum {
                        buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                    } else {  // popHanguel.chKind == .symbol
                        buffer.removeLast()
                    }
                }
                if inpStack.isEmpty {
                    curHanStatus = nil
                } else {
                    curHanStatus = inpStack[inpStack.count - 1].hangulStatus
                    oldKeyIndex = inpStack[inpStack.count - 1].keyIndex
                    oldKeyKind = inpStack[inpStack.count - 1].keyKind
                    curGeulja = inpStack[inpStack.count - 1].geulja
                    
                    switch oldKeyKind {
                    case .jaeum:
                        if curHanStatus == .chosung {
                            ret = chosungTable[Int(oldKeyIndex)]
                        } else if curHanStatus == .jongsung {
                            ret = jongsungTable[Int(oldKeyIndex)]
                        } else if curHanStatus == .dJongsung {
                            for i in 0..<dJongsungTable.count {
                                if dJongsungTable[i][2] == jongsungTable[Int(oldKeyIndex)] {
                                    ret = dJongsungTable[i][1]
                                }
                            }
                        }
                    case .moeum:
                        if curHanStatus == .jungsung {
                            ret = jungsungTable[Int(oldKeyIndex)]
                        } else if curHanStatus == .dJungsung {
                            for i in 0..<dJungsungTable.count {
                                if dJungsungTable[i][2] == jungsungTable[Int(oldKeyIndex)] {
                                    ret = dJungsungTable[i][1]
                                }
                            }
                        }
                    case .symbol:
                        ret = symbolTable[Int(oldKeyIndex)]
                    case nil:
                        ret = ""
                    }
                }
            }
        }
        print("buffer) ", buffer)
        return ret
    }
}

extension HangulAutomata {
    func hangulAutomata(key: String) {
        
        var canBeJongsung: Bool = false
        
        if jungsungTable.contains(key) {
            curKeyKind = .moeum
            curKeyIndex = UInt32(jungsungTable.firstIndex(of: key) ?? 0)
        } else {
            curKeyKind = .jaeum
            curKeyIndex = UInt32(chosungTable.firstIndex(of: key) ?? 0)
            if !((key == "ㄸ") || (key == "ㅉ") || (key == "ㅃ")) {
                canBeJongsung = true
            }
        }
        
        checkCurHanState(isSymbol: false)
        
        // MARK: - 오토마타 전이 알고리즘
        switch curHanStatus {
        case .start:
            if curKeyKind == .jaeum {
                curHanStatus = .chosung
                curHasChosung = true
            } else {
                curHanStatus = .jongsung
                curHasChosung = false
            }
        case .chosung:
            if curKeyKind == .moeum {
                curHanStatus = .jungsung
            } else {
                curHanStatus = .endOne
            }
        case .jungsung:
            if canBeJongsung {
                curHanStatus = .jongsung
            } else if jungsungPair() {
                curHanStatus = .dJungsung
            } else {
                curHanStatus = .endOne
            }
        case .dJungsung:
            // 추가
            if jungsungPair() {
                curHanStatus = .dJungsung
            } else if canBeJongsung {
                curHanStatus = .jongsung
            } else {
                curHanStatus = .endOne
            }
        case .jongsung:
            if curHasChosung && curKeyKind == .jaeum && jongsungPair() {
                curHanStatus = .dJongsung
            } else if curKeyKind == .moeum {
                curHanStatus = .endTwo
            } else {
                curHanStatus = .endOne
            }
        case .dJongsung:
            if curKeyKind == .moeum {
                curHanStatus = .endTwo
            } else {
                curHanStatus = .endOne
            }
        default:
            break
        }
        
        // MARK: - 오토마타 작업 알고리즘
        switch curHanStatus {
        case .chosung:
            curGeulja = chosungTable[Int(curKeyIndex)]
        case .jungsung:
            curGeulja = String(Unicode.Scalar(combinationHangul(chosungIndex: oldKeyIndex, jungsungIndex: curKeyIndex)) ?? Unicode.Scalar(0))
        case .dJungsung:
            if curHasChosung {
                let currentChosung = decompositionChosung(charCode: Unicode.Scalar(curGeulja)?.value ?? 0)
                curGeulja = String(Unicode.Scalar(combinationHangul(chosungIndex: currentChosung, jungsungIndex: curKeyIndex)) ?? Unicode.Scalar(0))
            } else {
                curGeulja = jungsungTable[Int(curKeyIndex)]
                curHanStatus = .jongsung
            }
        case .jongsung:
            if canBeJongsung {
                curKeyIndex = UInt32(jongsungTable.firstIndex(of: key) ?? 0)
                let currentCharCode =  Unicode.Scalar(curGeulja)?.value ?? 0
                curGeulja = String(Unicode.Scalar(decompositionChosungJungsung(charCode: currentCharCode)) ?? Unicode.Scalar(0))
            } else {
                curGeulja = key
            }
        case .dJongsung:
            let currentCharCode = Unicode.Scalar(curGeulja)?.value ?? 0
            curGeulja = String(Unicode.Scalar(decompositionChosungJungsung(charCode: currentCharCode)) ?? Unicode.Scalar(0))
            curKeyIndex = UInt32(jongsungTable.firstIndex(of: key) ?? 0)
        case .endOne:
            if curKeyKind == .jaeum {
                curGeulja = chosungTable[Int(curKeyIndex)]
                curHanStatus = .chosung
                curHasChosung = true
            } else {
                curGeulja = jungsungTable[Int(curKeyIndex)]
                curHanStatus = .jongsung
                curHasChosung = false
            }
            buffer.append("")
        case .endTwo:
            if oldKeyKind == .jaeum {
                oldKeyIndex = UInt32(chosungTable.firstIndex(of: jongsungTable[Int(oldKeyIndex)]) ?? 0)
                curGeulja = String(Unicode.Scalar(combinationHangul(chosungIndex: oldKeyIndex, jungsungIndex: curKeyIndex)) ?? Unicode.Scalar(0))
                curHanStatus = .jungsung
                buffer[buffer.count - 1] = inpStack[inpStack.count - 2].geulja
                buffer.append("")
                curHasChosung = true
            } else {
                if !jungsungPair() {
                    buffer.append("")
                    curHasChosung = false
                }
                curGeulja = jungsungTable[Int(curKeyIndex)]
                curHanStatus = .jongsung
            }
        default:
            break
        }
        
        storeStackAndBuffer()
    }
    
    func symbolAutomata(key: String) {
        curKeyKind = .symbol
        curKeyIndex = UInt32(symbolTable.firstIndex(of: key) ?? 0)
        curGeulja = symbolTable[Int(curKeyIndex)]
        
        checkCurHanState(isSymbol: true)
        storeStackAndBuffer()
        curHanStatus = nil
    }
    
    func checkCurHanState(isSymbol: Bool) {
        if curHanStatus != nil {
            oldKeyIndex = inpStack[inpStack.count - 1].keyIndex
            oldKeyKind = inpStack[inpStack.count - 1].keyKind
            curHasChosung = inpStack[inpStack.count - 1].hasChosung
            if isSymbol {
                buffer.append("")
                curHanStatus = nil
            }
        } else {
            curHanStatus = .start
            buffer.append("")
        }
    }
    
    func storeStackAndBuffer() {
        inpStack.append(InpStack(hangulStatus: curHanStatus ?? .start, keyKind: curKeyKind, keyIndex: curKeyIndex, geulja: String(Unicode.Scalar(curGeulja) ?? Unicode.Scalar(0)), hasChosung: curHasChosung))
        buffer[buffer.count - 1] = curGeulja
        print("buffer) ", buffer)
    }
}
