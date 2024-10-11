//
//  NaratgeulIOManager.swift
//  Naratgeul
//
//  Created by CHUBBY on 7/13/22.
//  Edited by 서동환 on 7/31/24.
//  - Downloaded from https://github.com/Kim-Junhwan/IOS-CustomKeyboard - KeyboardIOManager.swift
//

import Foundation

final class NaratgeulIOManager {
    private let hangeulAutomata = HangeulAutomata()
    private var lastLetter: String = ""
    private var prevAutomataBufferSize = 0
    private var curAutomataBufferSize = 0
    private var isCommaInput: Bool = false
    
    var isHoegSsangAvailiable: Bool = false
    var isEditingLastCharacter: Bool = false
    var isSymbolInput: Bool = false
    
    private var inputHangeul: String = "" {
        didSet {
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
            
            lastLetter = inputHangeul
            updateAutomataBufferSize()
        }
    }
    
    private var inputOther: String = "" {
        didSet {
            hangeulAutomata.otherAutomata(key: inputOther)
            curAutomataBufferSize = getBufferSize()
            inputText?(inputOther)
            isEditingLastCharacter = true
            
            lastLetter = inputOther
            updateAutomataBufferSize()
        }
    }
    
    var inputText: ((String) -> Void)?
    var deleteForInput: (() -> Void)?
    var deleteText: (() -> Bool)?
    var inputForDelete: ((String) -> Void)?
    var attemptRestoreWord: (() -> Bool)?
    var onlyUpdateHoegSsang: (() -> Void)?
    var moveCursorToLeft: (() -> Bool)?
    var moveCursorToRight: (() -> Bool)?
    
    private func updateAutomataBufferSize() {
        prevAutomataBufferSize = curAutomataBufferSize
    }
    
    func deleteOneWholeLetter() {
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
    }
}

extension NaratgeulIOManager: NaratgeulDelegate {
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
    
    func inputLastHangeul() {
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
    
    func otherKeypadTap(letter: String) {
        isHoegSsangAvailiable = false
        lastLetter = letter
        inputOther = lastLetter
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
                        deleteOneWholeLetter()
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
