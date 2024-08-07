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
    private var lastInputLetter: String = ""
    
    var isEditingLastCharacter: Bool = false
    
    private var input: String = "" {
        didSet {
            if input == " " || input == "\n" {
                hangulAutomata.buffer.removeAll()
                hangulAutomata.inpStack.removeAll()
                isEditingLastCharacter = false
                hangulAutomata.currentHangulState = nil
                inputText?(input)
            } else {
                isEditingLastCharacter = true
                hangulAutomata.hangulAutomata(key: input)
                inputText?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
            }
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
    
    func hangulKeypadTap(letter: String) {
        var curLetter: String = ""
        switch letter {
        case "ㅏ" :
            if lastInputLetter == "ㅏ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅓ"
            } else if lastInputLetter == "ㅓ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅏ"
            } else {
                curLetter = "ㅏ"
            }
            
        case "ㅗ" :
            if lastInputLetter == "ㅗ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅜ"
            } else if lastInputLetter == "ㅜ" {
                hangulAutomata.deleteBuffer()
                curLetter = "ㅗ"
            } else {
                curLetter = "ㅗ"
            }
            
        default:
            curLetter = letter
        }
        
        self.input = curLetter
        lastInputLetter = curLetter
    }
    
    func hoegKeypadTap() {
        hangulAutomata.deleteBuffer()
        
        let curLetter: String
        switch lastInputLetter {
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
        
        self.input = curLetter
        lastInputLetter = curLetter
    }
    
    func ssangKeypadTap() {
        hangulAutomata.deleteBuffer()
        
        let curLetter: String
        switch lastInputLetter {
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
        
        self.input = curLetter
        lastInputLetter = curLetter
    }
    
    func removeKeypadTap() {
        if hangulAutomata.buffer.isEmpty {
            isEditingLastCharacter = false
            deleteText?()
        } else {
            hangulAutomata.deleteBuffer()
            inputText?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
        }
    }
    
    func enterKeypadTap() {
//        dismiss?()
        self.input = "\n"
        lastInputLetter = "\n"
    }
    
    func spaceKeypadTap() {
        self.input = " "
        lastInputLetter = " "
    }
    
    func numKeypadTap() {
        
    }
}
