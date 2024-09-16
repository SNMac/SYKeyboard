//
//  SYKeyboardIOManager.swift
//  Naratgeul
//
//  Created by CHUBBY on 7/13/22.
//  Edited by 서동환 on 7/31/24.
//  - Downloaded from https://github.com/Kim-Junhwan/IOS-CustomKeyboard - KeyboardIOManager.swift
//

import Foundation
import SwiftUI

final class SYKeyboardIOManager {
    private let hangeulAutomata = HangeulAutomata()
    private var lastLetter: String = ""
    var prevAutomataBufferSize = 0
    var curAutomataBufferSize = 0
    var isEditingLastCharacter: Bool = false
    var isHoegSsangAvailiable: Bool = false
    
    private var inputHangeul: String = "" {
        didSet {
            lastLetter = inputHangeul
            if inputHangeul == "" {
                onlyUpdateHoegSsang?()
            } else {
                var text: String = ""
                
                hangeulAutomata.hangeulAutomata(key: inputHangeul)
                curAutomataBufferSize = getBufferSize()
                
                if prevAutomataBufferSize < curAutomataBufferSize {
                    hangeulAutomata.buffer.suffix(2).forEach { geulja in
                        text += geulja
                    }
                    deleteForInput?()
                } else if prevAutomataBufferSize == curAutomataBufferSize {
                    text = hangeulAutomata.buffer.last ?? ""
                    deleteForInput?()
                } else {
                    text = hangeulAutomata.buffer.last ?? ""
                    deleteForInput?()
                    deleteForInput?()
                }
                inputText?(text)
                isEditingLastCharacter = true  // 순서 중요함
            }
            
            updateAutomataBufferSize()
        }
    }
    
    private var inputOther: String = "" {
        didSet {
            lastLetter = inputOther
            hangeulAutomata.otherAutomata(key: inputOther)
            curAutomataBufferSize = getBufferSize()
            inputText?(inputOther)
            isEditingLastCharacter = true
            
            updateAutomataBufferSize()
        }
    }
    
    var inputText: ((String) -> Void)?
    var deleteForInput: (() -> Void)?
    var deleteText: (() -> Bool)?
    var inputForDelete: ((String) -> Void)?
    var attemptRestoreWord: (() -> Bool)?
    var hoegComma: (() -> Void)?
    var ssangPeriod: (() -> Void)?
    var onlyUpdateHoegSsang: (() -> Void)?
    var moveCursorToLeft: (() -> Bool)?
    var moveCursorToRight: (() -> Bool)?
    
    private func updateAutomataBufferSize() {
        prevAutomataBufferSize = curAutomataBufferSize
    }
}

extension SYKeyboardIOManager: SYKeyboardDelegate {
    func getBufferSize() -> Int {
        return hangeulAutomata.buffer.count
    }
    
    func flushBuffer() {
        print("flushBuffer()")
        hangeulAutomata.buffer.removeAll()
        hangeulAutomata.bufferTypingCount.removeAll()
        hangeulAutomata.inpStack.removeAll()
        hangeulAutomata.curHanStatus = nil
        isEditingLastCharacter = false
        isHoegSsangAvailiable = false
        lastLetter = ""
        curAutomataBufferSize = getBufferSize()
        updateAutomataBufferSize()
    }
    
    func inputLastHangul() {
        inputHangeul = lastLetter
    }
    
    func inputLastSymbol() {
        inputOther = lastLetter
    }
    
    func hangulKeypadTap(letter: String) {
        let curLetter: String
        
        switch letter {
        case "ㅏ" :
            if lastLetter == "ㅏ" {
                if hangeulAutomata.inpStack.last?.keyKind == .moeum
                    && hangeulAutomata.inpStack.last?.keyIndex == 9 {  // ㅘ
                    curLetter = "ㅏ"
                } else {
                    hangeulAutomata.deleteBufferLastInput()
                    curLetter = "ㅓ"
                }
            } else if lastLetter == "ㅓ" {
                if hangeulAutomata.inpStack.last?.keyKind == .moeum
                    && hangeulAutomata.inpStack.last?.keyIndex == 14 {  // ㅝ
                    curLetter = "ㅏ"
                } else {
                    hangeulAutomata.deleteBufferLastInput()
                    curLetter = "ㅏ"
                }
            } else if lastLetter == "ㅜ" {
                curLetter = "ㅓ"
            } else {
                curLetter = "ㅏ"
            }
            
        case "ㅗ" :
            if lastLetter == "ㅗ" {
                hangeulAutomata.deleteBufferLastInput()
                curLetter = "ㅜ"
            } else if lastLetter == "ㅜ" {
                hangeulAutomata.deleteBufferLastInput()
                curLetter = "ㅗ"
            } else {
                curLetter = "ㅗ"
            }
            
        default:
            curLetter = letter
        }
        
        inputHangeul = curLetter
    }
    
    func symbolKeypadTap(letter: String) {
        isHoegSsangAvailiable = false
        lastLetter = letter
        inputOther = lastLetter
    }
    
    func checkHoegSsangAvailable() {
        switch lastLetter {
        case "ㄱ":
            isHoegSsangAvailiable = true
        case "ㅋ", "ㄲ":
            isHoegSsangAvailiable = true
            
        case "ㄴ", "ㄸ":
            isHoegSsangAvailiable = true
        case "ㄷ":
            isHoegSsangAvailiable = true
        case "ㅌ":
            isHoegSsangAvailiable = true
            
        case "ㅏ":
            isHoegSsangAvailiable = true
        case "ㅑ":
            isHoegSsangAvailiable = true
        case "ㅓ":
            isHoegSsangAvailiable = true
        case "ㅕ":
            isHoegSsangAvailiable = true
            
        case "ㅁ", "ㅃ":
            isHoegSsangAvailiable = true
        case "ㅂ":
            isHoegSsangAvailiable = true
        case "ㅍ":
            isHoegSsangAvailiable = true
            
        case "ㅗ":
            isHoegSsangAvailiable = true
        case "ㅛ":
            isHoegSsangAvailiable = true
        case "ㅜ":
            isHoegSsangAvailiable = true
        case "ㅠ":
            isHoegSsangAvailiable = true
            
        case "ㅅ", "ㅆ":
            isHoegSsangAvailiable = true
        case "ㅈ":
            isHoegSsangAvailiable = true
        case "ㅊ":
            isHoegSsangAvailiable = true
        case "ㅉ":
            isHoegSsangAvailiable = true
            
        case "ㅇ":
            isHoegSsangAvailiable = true
        case "ㅎ":
            isHoegSsangAvailiable = true
            
        default:
            isHoegSsangAvailiable = false
        }
    }
    
    func hoegKeypadTap() {
        isHoegSsangAvailiable = true
        
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
            isHoegSsangAvailiable = false
            
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
            isHoegSsangAvailiable = false
            
        case "ㅡ":
            isHoegSsangAvailiable = false
            
        default:
            isHoegSsangAvailiable = false
        }
        
        if curLetter != "" {
            hangeulAutomata.deleteBufferLastInput()
        }
        inputHangeul = curLetter
    }
    
    func hoegToComma(isLongPress: Bool) {
        if isLongPress {
            inputOther = ","
            inputOther = ","
            inputOther = ","
        } else {
            inputOther = ","
        }
    }
    
    func ssangKeypadTap() {
        isHoegSsangAvailiable = true
        
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
            isHoegSsangAvailiable = false
            
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
            isHoegSsangAvailiable = false
        case "ㅡ":
            isHoegSsangAvailiable = false
            
        default:
            isHoegSsangAvailiable = false
        }
        
        if curLetter != "" {
            hangeulAutomata.deleteBufferLastInput()
        }
        inputHangeul = curLetter
    }
    
    func ssangToPeriod(isLongPress: Bool) {
        if isLongPress {
            inputOther = "."
            inputOther = "."
            inputOther = "."
        } else {
            inputOther = "."
        }
    }
    
    func removeKeypadTap(isLongPress: Bool) -> Bool {
        if let isRestored = attemptRestoreWord?() {
            if !isRestored {
                if hangeulAutomata.buffer.isEmpty {
                    isEditingLastCharacter = false
                    if let isDeleted = deleteText?() {
                        return isDeleted
                    } else {
                        return false
                    }
                } else {
                    if isLongPress {
                        if hangeulAutomata.bufferTypingCount.count > 0 {
                            let count = hangeulAutomata.bufferTypingCount[hangeulAutomata.bufferTypingCount.count - 1]
                            for _ in 0..<count {
                                lastLetter = hangeulAutomata.deleteBufferLastInput()
                                curAutomataBufferSize = getBufferSize()
                                if curAutomataBufferSize == 0 {
                                    isEditingLastCharacter = false
                                }
                            }
                        }
                        let _ = deleteText?()
                    } else {
                        lastLetter = hangeulAutomata.deleteBufferLastInput()
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
                        inputForDelete?(hangeulAutomata.buffer.last ?? "")
                    }
                    updateAutomataBufferSize()
                    return true
                }
            }
            return true
        }
        return false
    }
    
    func enterKeypadTap() {
        lastLetter = "\n"
        inputText?("\n")
        flushBuffer()
        
        updateAutomataBufferSize()
    }
    
    func spaceKeypadTap() {
        lastLetter = " "
        inputText?(" ")
        flushBuffer()
        
        updateAutomataBufferSize()
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
