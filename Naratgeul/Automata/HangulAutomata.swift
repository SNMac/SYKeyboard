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
enum AutomataStatus {
    case start  //s0
    case chosung  //s1
    case jungsung, dJungsung  //s2,s3
    case jongsung, dJongsung  //s4, s5
    case endOne, endTwo  //s6,s7
}

// 입력된 키의 종류 판별 정의
enum HangulCHKind {
    case jaeum  // 자음
    case moeum  // 모음
    case symbol  // 기호
}

// 키 입력마다 쌓이는 입력 스택 정의
struct InpStack {
    var hangulStatus: AutomataStatus  // 상태
    var keyKind: HangulCHKind  // 입력된 키가 자음 or 모음 or 기호인지
    var keyIndex: UInt32  // 방금 입력된 키의 테이블 인덱스
    var geulja: String  // 조합된 글자
    var hasChosung: Bool  // 조합된 글자가 초성을 갖고있는지
}

final class HangulAutomata {
    
    var buffer: [String] = []
    var bufferTypingCount: [Int] = []
    
    var inpStack: [InpStack] = []
    
    var curHanStatus: AutomataStatus?
    
    private var oldKeyKind: HangulCHKind?
    private var oldKeyIndex: UInt32 = 0
    private var curKeyKind = HangulCHKind.moeum
    private var curKeyIndex: UInt32 = 0
    private var curGeulja: String = ""
    private var curHasChosung: Bool = false
    
    private let chosungTable: [String] = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let jungsungTable: [String] = ["ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ", "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"]
    
    private let jongsungTable: [String] = [" ", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ", "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    private let dJungsungTable: [[String]] = [
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
    
    private func bufferRemoveLast() {
        buffer.removeLast()
        bufferTypingCount.removeLast()
    }
    
    private func getAutomataContextFromStack() -> String {
        var lastLetter: String = ""
        
        curHanStatus = inpStack[inpStack.count - 1].hangulStatus
        oldKeyIndex = inpStack[inpStack.count - 1].keyIndex
        oldKeyKind = inpStack[inpStack.count - 1].keyKind
        curGeulja = inpStack[inpStack.count - 1].geulja
        
        switch oldKeyKind {
        case .jaeum:
            if curHanStatus == .chosung {
                lastLetter = chosungTable[Int(oldKeyIndex)]
            } else if curHanStatus == .jongsung {
                lastLetter = jongsungTable[Int(oldKeyIndex)]
            } else if curHanStatus == .dJongsung {
                let oldOldKeyIndex = inpStack[inpStack.count - 2].keyIndex
                for i in 0..<dJongsungTable.count {
                    if dJongsungTable[i][0] == jongsungTable[Int(oldOldKeyIndex)]
                        && dJongsungTable[i][1] == jongsungTable[Int(oldKeyIndex)] {
                        lastLetter = dJongsungTable[i][1]
                        break
                    }
                }
            }
        case .moeum:
            if curHanStatus == .dJungsung {
                for i in 0..<dJungsungTable.count {
                    if dJungsungTable[i][2] == jungsungTable[Int(oldKeyIndex)] {
                        lastLetter = dJungsungTable[i][1]
                        break
                    }
                }
            } else {
                var isdJungsung = false
                for i in 0..<dJungsungTable.count {
                    if dJungsungTable[i][2] == jungsungTable[Int(oldKeyIndex)] {
                        lastLetter = dJungsungTable[i][1]
                        isdJungsung = true
                        break
                    }
                }
                if !isdJungsung {
                    lastLetter = jungsungTable[Int(oldKeyIndex)]
                }
            }
        case .symbol:
            lastLetter = curGeulja
        case nil:
            lastLetter = ""
        }
        
        return lastLetter
    }
    
    @discardableResult
    func deleteBufferLastInput() -> String {
        var lastLetter: String = ""
        
        if buffer.count > 0 {
            if let popHangul = inpStack.popLast() {
                if popHangul.hangulStatus == .chosung {
                    bufferRemoveLast()
                } else if popHangul.hangulStatus == .jungsung || popHangul.hangulStatus == .dJungsung {
                    var isRemoved: Bool = false
                    if inpStack[inpStack.count - 1].hangulStatus == .jongsung || inpStack[inpStack.count - 1].hangulStatus == .dJongsung {
                        bufferRemoveLast()
                        bufferTypingCount[bufferTypingCount.count - 1] += 1
                        isRemoved = true
                    }
                    buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                    if !isRemoved {
                        bufferTypingCount[bufferTypingCount.count - 1] -= 1
                    }
                } else {
                    if inpStack.isEmpty {
                        bufferRemoveLast()
                    } else if popHangul.keyKind == .moeum {
                        if inpStack[inpStack.count - 1].hangulStatus == .jongsung {
                            if inpStack[inpStack.count - 1].keyKind == .moeum {
                                if isJungsungPair(
                                    first: jungsungTable[Int(inpStack[inpStack.count - 1].keyIndex)],
                                    result: jungsungTable[Int(popHangul.keyIndex)]) {
                                    buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                                    bufferTypingCount[bufferTypingCount.count - 1] -= 1
                                } else {
                                    bufferRemoveLast()
                                }
                            }
                        } else {
                            bufferRemoveLast()
                        }
                    } else if popHangul.keyKind == .jaeum {
                        buffer[buffer.count - 1] = inpStack[inpStack.count - 1].geulja
                        bufferTypingCount[bufferTypingCount.count - 1] -= 1
                    } else {  // popHanguel.keyKind == .symbol
                        bufferRemoveLast()
                    }
                }
                if inpStack.isEmpty {
                    curHanStatus = nil
                } else {
                    lastLetter = getAutomataContextFromStack()
                }
            }
        }
        
        print("deleteBufferLastInput()->buffer =", buffer)
        print("deleteBufferLastInput()->bufferTypingCount =", bufferTypingCount)
        print("lastLetter =", lastLetter)
        return lastLetter
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
            appendingBuffer()
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
            appendingBuffer()
        case .endTwo:
            if oldKeyKind == .jaeum {
                oldKeyIndex = UInt32(chosungTable.firstIndex(of: jongsungTable[Int(oldKeyIndex)]) ?? 0)
                curGeulja = String(Unicode.Scalar(combinationHangul(chosungIndex: oldKeyIndex, jungsungIndex: curKeyIndex)) ?? Unicode.Scalar(0))
                curHanStatus = .jungsung
                
                // 이전 글자
                buffer[buffer.count - 1] = inpStack[inpStack.count - 2].geulja
                bufferTypingCount[bufferTypingCount.count - 1] -= 1
                
                appendingBuffer()
                
                // 현재 글자
                bufferTypingCount[bufferTypingCount.count - 1] += 1
                curHasChosung = true
            } else {
                if !jungsungPair() {
                    appendingBuffer()
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
        curKeyIndex = 0
        curGeulja = key
        
        checkCurHanState(isSymbol: true)
        appendingBuffer()
        storeStackAndBuffer()
        curHanStatus = nil
    }
    
    func checkCurHanState(isSymbol: Bool) {
        if curHanStatus != nil {
            oldKeyIndex = inpStack[inpStack.count - 1].keyIndex
            oldKeyKind = inpStack[inpStack.count - 1].keyKind
            curHasChosung = inpStack[inpStack.count - 1].hasChosung
            if isSymbol {
                curHanStatus = nil
            }
        } else {
            curHanStatus = .start
        }
    }
    
    func appendingBuffer() {
        buffer.append("")
        bufferTypingCount.append(0)
    }
    
    func storeStackAndBuffer() {
        inpStack.append(InpStack(hangulStatus: curHanStatus ?? .start,
                                 keyKind: curKeyKind,
                                 keyIndex: curKeyIndex,
                                 geulja: String(Unicode.Scalar(curGeulja) ?? Unicode.Scalar(0)),
                                 hasChosung: curHasChosung
                                ))
        buffer[buffer.count - 1] = curGeulja
        bufferTypingCount[bufferTypingCount.count - 1] += 1
        print("storeStackAndBuffer()->buffer =", buffer)
        print("storeStackAndBuffer()->bufferTypingCount =", bufferTypingCount)
    }
}
