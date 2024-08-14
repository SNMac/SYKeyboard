//
//  SYKeyboardIOManager.swift
//  Naratgeul
//
//  Created by CHUBBY on 2022/07/13.
//  Edited by 서동환 on 7/31/24.
//  - Downloaded from https://github.com/Kim-Junhwan/IOS-CustomKeyboard - KeyboardIOManager.swift
//

import Foundation


final class SYKeyboardIOManager {
    
    private var hangulAutomata = HangulAutomata()
    private var lastLetter: String = ""
    var isEditingLastCharacter: Bool = false
    
    private var inputHangul: String = "" {
        didSet {
            if inputHangul == " " || inputHangul == "\n" {
                hangulAutomata.buffer.removeAll()
                hangulAutomata.inpStack.removeAll()
                isEditingLastCharacter = false
                hangulAutomata.curHanStatus = nil
                inputText?(inputHangul)
            } else if inputHangul == "" {
                hangulAutomata.buffer.removeAll()
                hangulAutomata.inpStack.removeAll()
                isEditingLastCharacter = false
                hangulAutomata.curHanStatus = nil
            } else {
                isEditingLastCharacter = true
                hangulAutomata.hangulAutomata(key: inputHangul)
                inputText?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
            }
        }
    }
    
    private var inputOther: String = "" {
        didSet {
            isEditingLastCharacter = true
            hangulAutomata.symbolAutomata(key: inputOther)
            inputText?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
        }
    }
    
    var inputText: ((String) -> Void)?
    var deleteText: (() -> Void)?
    var dismiss: (() -> Void)?
}

extension SYKeyboardIOManager: SYKeyboardDelegate {
    func getBufferSize() -> Int {
        return hangulAutomata.buffer.count
    }
    
    func flushBuffer() {
        hangulAutomata.buffer.removeAll()
        hangulAutomata.inpStack.removeAll()
        isEditingLastCharacter = false
        hangulAutomata.curHanStatus = nil
        lastLetter = ""
    }
    
    func inputlastLetter() {
        self.inputHangul = lastLetter
    }
    
    func hangulKeypadTap(letter: String) {
        var curLetter: String
        switch letter {
        case "ㅏ" :
            if lastLetter == "ㅏ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅓ"
            } else if lastLetter == "ㅓ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅏ"
            } else {
                curLetter = "ㅏ"
            }
            
        case "ㅗ" :
            if lastLetter == "ㅗ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅜ"
            } else if lastLetter == "ㅜ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅗ"
            } else {
                curLetter = "ㅗ"
            }
            
        default:
            curLetter = letter
        }
        
        self.inputHangul = curLetter
        lastLetter = curLetter
    }
    
    func hoegKeypadTap() {
        hangulAutomata.deleteBuffer()
        
        let curLetter: String
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
            curLetter = "ㄹ"
            
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
            curLetter = "ㅣ"
            
        case "ㅡ":
            curLetter = "ㅡ"
            
        default:
            curLetter = ""
        }
        
        self.inputHangul = curLetter
        lastLetter = curLetter
    }
    
    func ssangKeypadTap() {
        hangulAutomata.deleteBuffer()
        
        let curLetter: String
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
            curLetter = "ㄹ"
            
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
            curLetter = "ㅣ"
            
        case "ㅡ":
            curLetter = "ㅡ"
            
        default:
            curLetter = ""
        }
        
        self.inputHangul = curLetter
        lastLetter = curLetter
    }
    
    func removeKeypadTap() {
        if hangulAutomata.buffer.isEmpty {
            isEditingLastCharacter = false
            deleteText?()
        } else {
            lastLetter = hangulAutomata.deleteBuffer()
            inputText?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
        }
    }
    
    func enterKeypadTap() {
        //        dismiss?()
        inputHangul = "\n"
        lastLetter = inputHangul
    }
    
    func spaceKeypadTap() {
        inputHangul = " "
        lastLetter = inputHangul
    }
    
    func otherKeypadTap(letter: String) {
        inputOther = letter
        lastLetter = inputHangul
    }
    
    func numKeypadTap() {
        
    }
}
