//
//  SYKeyboardIOManager.swift
//  Naratgeul
//
//  Created by CHUBBY on 2022/07/13.
//  Edited by 서동환 on 7/31/24.
//  - Downloaded from https://github.com/Kim-Junhwan/IOS-CustomKeyboard - KeyboardIOManager.swift
//

import Foundation
import SwiftUI

protocol SYKeyboardDelegate: AnyObject {
    func getBufferSize() -> Int
    func flushBuffer()
    func inputLastHangul()
    func inputLastSymbol()
    func hangulKeypadTap(letter: String)
    func symbolKeypadTap(letter: String)
    func hoegKeypadTap()
    func hoegKeypadLongPress()
    func ssangKeypadTap()
    func ssangKeypadLongPress()
    func removeKeypadTap(isLongPress: Bool) -> Bool
    func enterKeypadTap()
    func spaceKeypadTap()
    func dragToLeft() -> Bool
    func dragToRight() -> Bool
}

final class SYKeyboardIOManager {
    
    private var hangulAutomata = HangulAutomata()
    private var lastLetter: String = ""
    var prevAutomataBufferSize = 0
    var curAutomataBufferSize = 0
    var isEditingLastCharacter: Bool = false
    var isHoegSsangAvailiable: Bool = false
    
    private var inputHangul: String = "" {
        didSet {
            if inputHangul == " " || inputHangul == "\n" {
                flushBuffer()
                inputText?(inputHangul)
            } else if inputHangul == "" {
                onlyUpdateHoegSsang?()
            } else {
                var text: String = ""
                
                hangulAutomata.hangulAutomata(key: inputHangul)
                curAutomataBufferSize = getBufferSize()
                
                if prevAutomataBufferSize < curAutomataBufferSize {
                    hangulAutomata.buffer.suffix(2).forEach { geulja in
                        text += geulja
                    }
                    deleteForInput?()
                } else if prevAutomataBufferSize == curAutomataBufferSize {
                    text = hangulAutomata.buffer.last ?? ""
                    deleteForInput?()
                } else {
                    text = hangulAutomata.buffer.last ?? ""
                    deleteForInput?()
                    deleteForInput?()
                }
                inputText?(text)
                isEditingLastCharacter = true  // 순서 중요함
            }
            lastLetter = inputHangul
            
            updateAutomataBufferSize()
        }
    }
    
    private var inputSymbol: String = "" {
        didSet {
            hangulAutomata.symbolAutomata(key: inputSymbol)
            curAutomataBufferSize = getBufferSize()
            inputText?(inputSymbol)
            lastLetter = inputSymbol
            isEditingLastCharacter = true
            
            updateAutomataBufferSize()
        }
    }
    
    var inputText: ((String) -> Void)?
    var deleteForInput: (() -> Void)?
    var deleteText: (() -> Bool)?
    var hoegPeriod: (() -> Void)?
    var ssangComma: (() -> Void)?
    var onlyUpdateHoegSsang: (() -> Void)?
    var moveCursorToLeft: (() -> Bool)?
    var moveCursorToRight: (() -> Bool)?
    
    private func updateAutomataBufferSize() {
        prevAutomataBufferSize = curAutomataBufferSize
    }
}

extension SYKeyboardIOManager: SYKeyboardDelegate {
    func getBufferSize() -> Int {
        return hangulAutomata.buffer.count
    }
    
    func flushBuffer() {
        print("flushBuffer()")
        hangulAutomata.buffer.removeAll()
        hangulAutomata.bufferTypingCount.removeAll()
        hangulAutomata.inpStack.removeAll()
        isEditingLastCharacter = false
        isHoegSsangAvailiable = false
        hangulAutomata.curHanStatus = nil
        lastLetter = ""
    }
    
    func inputLastHangul() {
        inputHangul = lastLetter
    }
    
    func inputLastSymbol() {
        inputSymbol = lastLetter
    }
    
    func hangulKeypadTap(letter: String) {
        let curLetter: String
        
        switch letter {
        case "ㅏ" :
            if lastLetter == "ㅏ" {
                if hangulAutomata.inpStack.last?.keyKind == .moeum
                    && hangulAutomata.inpStack.last?.keyIndex == 9 {  // ㅘ
                    curLetter = "ㅏ"
                } else {
                    hangulAutomata.deleteBufferLastInput()
                    curLetter = "ㅓ"
                }
            } else if lastLetter == "ㅓ" {
                if hangulAutomata.inpStack.last?.keyKind == .moeum
                    && hangulAutomata.inpStack.last?.keyIndex == 14 {  // ㅝ
                    curLetter = "ㅏ"
                } else {
                    hangulAutomata.deleteBufferLastInput()
                    curLetter = "ㅏ"
                }
            } else if lastLetter == "ㅜ" {
                curLetter = "ㅓ"
            } else {
                curLetter = "ㅏ"
            }
            
        case "ㅗ" :
            if lastLetter == "ㅗ" {
                hangulAutomata.deleteBufferLastInput()
                curLetter = "ㅜ"
            } else if lastLetter == "ㅜ" {
                hangulAutomata.deleteBufferLastInput()
                curLetter = "ㅗ"
            } else {
                curLetter = "ㅗ"
            }
            
        default:
            curLetter = letter
        }
        
        inputHangul = curLetter
    }
    
    func symbolKeypadTap(letter: String) {
        isHoegSsangAvailiable = false
        lastLetter = letter
        inputSymbol = lastLetter
    }
    
    func hoegKeypadTap() {
        var isHoegAvailable: Bool = true
        
        var curLetter: String = ""
        switch lastLetter {
        case "ㄱ":
            curLetter = "ㅋ"
        case "ㅋ", "ㄲ":
            curLetter = "ㄱ"
            
        case "ㄴ", "ㄸ":
            curLetter = "ㄷ"
        case "ㄷ":
            curLetter = "ㅌ"
        case "ㅌ":
            curLetter = "ㄴ"
            
        case "ㅏ":
            curLetter = "ㅑ"
        case "ㅑ":
            curLetter = "ㅏ"
        case "ㅓ":
            curLetter = "ㅕ"
        case "ㅕ":
            curLetter = "ㅓ"
            
        case "ㄹ":
            isHoegAvailable = false
            
        case "ㅁ", "ㅃ":
            curLetter = "ㅂ"
        case "ㅂ":
            curLetter = "ㅍ"
        case "ㅍ":
            curLetter = "ㅁ"
            
        case "ㅗ":
            curLetter = "ㅛ"
        case "ㅛ":
            curLetter = "ㅗ"
        case "ㅜ":
            curLetter = "ㅠ"
        case "ㅠ":
            curLetter = "ㅜ"
            
        case "ㅅ", "ㅆ":
            curLetter = "ㅈ"
        case "ㅈ":
            curLetter = "ㅊ"
        case "ㅊ":
            curLetter = "ㅉ"
        case "ㅉ":
            curLetter = "ㅅ"
            
        case "ㅇ":
            curLetter = "ㅎ"
        case "ㅎ":
            curLetter = "ㅇ"
            
        case "ㅣ":
            isHoegAvailable = false
            
        case "ㅡ":
            isHoegAvailable = false
            
        default:
            isHoegAvailable = false
        }
        
        isHoegSsangAvailiable = isHoegAvailable
        if curLetter != "" {
            hangulAutomata.deleteBufferLastInput()
        }
        inputHangul = curLetter
    }
    
    func hoegKeypadLongPress() {
        hoegPeriod?()
    }
    
    func ssangKeypadTap() {
        var isSsangAvailable: Bool = true
        
        var curLetter: String = ""
        switch lastLetter {
        case "ㄱ", "ㅋ":
            curLetter = "ㄲ"
        case "ㄲ":
            curLetter = "ㄱ"
            
        case "ㄴ", "ㄷ", "ㅌ":
            curLetter = "ㄸ"
        case "ㄸ":
            curLetter = "ㄷ"
            
        case "ㅏ":
            curLetter = "ㅑ"
        case "ㅑ":
            curLetter = "ㅏ"
        case "ㅓ":
            curLetter = "ㅕ"
        case "ㅕ":
            curLetter = "ㅓ"
            
        case "ㄹ":
            isSsangAvailable = false
            
        case "ㅁ", "ㅂ", "ㅍ":
            curLetter = "ㅃ"
        case "ㅃ":
            curLetter = "ㅁ"
            
        case "ㅗ":
            curLetter = "ㅛ"
        case "ㅛ":
            curLetter = "ㅗ"
        case "ㅜ":
            curLetter = "ㅠ"
        case "ㅠ":
            curLetter = "ㅜ"
            
        case "ㅅ":
            curLetter = "ㅆ"
        case "ㅈ", "ㅊ":
            curLetter = "ㅉ"
        case "ㅆ":
            curLetter = "ㅅ"
        case "ㅉ":
            curLetter = "ㅈ"
            
        case "ㅇ":
            curLetter = "ㅎ"
        case "ㅎ":
            curLetter = "ㅇ"
            
        case "ㅣ":
            isSsangAvailable = false
        case "ㅡ":
            isSsangAvailable = false
            
        default:
            isSsangAvailable = false
        }
        
        isHoegSsangAvailiable = isSsangAvailable
        if curLetter != "" {
            hangulAutomata.deleteBufferLastInput()
        }
        inputHangul = curLetter
    }
    
    func ssangKeypadLongPress() {
        ssangComma?()
    }
    
    func removeKeypadTap(isLongPress: Bool) -> Bool {
        if hangulAutomata.buffer.isEmpty {
            isEditingLastCharacter = false
            if let isDeleted = deleteText?() {
                return isDeleted
            } else {
                return false
            }
        } else {
            if isLongPress {
                if hangulAutomata.bufferTypingCount.count > 0 {
                    let count = hangulAutomata.bufferTypingCount[hangulAutomata.bufferTypingCount.count - 1]
                    for _ in 0..<count {
                        lastLetter = hangulAutomata.deleteBufferLastInput()
                        curAutomataBufferSize = getBufferSize()
                        if curAutomataBufferSize == 0 {
                            isEditingLastCharacter = false
                        }
                    }
                }
                let _ = deleteText?()
            } else {
                lastLetter = hangulAutomata.deleteBufferLastInput()
                curAutomataBufferSize = getBufferSize()
                if curAutomataBufferSize == 0 {
                    isEditingLastCharacter = false
                }
                if prevAutomataBufferSize > curAutomataBufferSize && curAutomataBufferSize > 0 {
                    let _ = deleteText?()
                    let _ = deleteText?()
                } else {
                    let _ = deleteText?()
                }
                inputText?(hangulAutomata.buffer.last ?? "")
            }
            updateAutomataBufferSize()
            return true
        }
    }
    
    func enterKeypadTap() {
        isHoegSsangAvailiable = false
        inputHangul = "\n"
    }
    
    func spaceKeypadTap() {
        isHoegSsangAvailiable = false
        inputHangul = " "
    }
    
    func dragToLeft() -> Bool {
        if let isMoved = moveCursorToLeft?() {
            return isMoved
        } else {
            return false
        }
    }
    
    func dragToRight() -> Bool {
        if let isMoved = moveCursorToRight?() {
            return isMoved
        } else {
            return false
        }
    }
}
