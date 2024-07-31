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
    
    private var input: String = "" {
        didSet {
            if input == " " {
                hangulAutomata.buffer.append(" ")
                hangulAutomata.inpStack.removeAll()
                hangulAutomata.currentHangulState = nil
            } else if input == "\n" {
                hangulAutomata.buffer.append("\n")
                hangulAutomata.inpStack.removeAll()
                hangulAutomata.currentHangulState = nil
            } else {
                hangulAutomata.hangulAutomata(key: input)
            }
            updateTextView?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
        }
    }
    
    var updateTextView: ((String) -> Void)?
    var dismiss: (() -> Void)?
}

extension SYKeyboardIOManager: SYKeyboardDelegate {
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
    
    func deleteKeypadTap() {
        hangulAutomata.deleteBuffer()
        updateTextView?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
    }
    
    func enterKeypadTap() {
//        dismiss?()
        self.input = "\n"
    }
    
    func spaceKeypadTap() {
        self.input = " "
    }
    
    func numKeypadTap() {
        
    }
}
