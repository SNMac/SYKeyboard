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
    func inputLastLetter()
    func hangulKeypadTap(letter: String)
    func otherKeypadTap(letter: String)
    func hoegKeypadTap()
    func hoegKeypadLongPress()
    func ssangKeypadTap()
    func ssangKeypadLongPress()
    func removeKeypadTap()
    func enterKeypadTap()
    func spaceKeypadTap()
}

final class SYKeyboardIOManager {
    
    private var hangulAutomata = HangulAutomata()
    private var lastLetter: String = ""
    var isEditingLastCharacter: Bool = false
    var isHoegSsangAvailiable: Bool = false
    
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
    var hoegPeriod: (() -> Void)?
    var ssangComma: (() -> Void)?
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
    
    func inputLastLetter() {
        inputHangul = lastLetter
    }
    
    func hangulKeypadTap(letter: String) {
        let curLetter: String
        
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
        
        lastLetter = curLetter
        inputHangul = lastLetter
    }
    
    func otherKeypadTap(letter: String) {
        isHoegSsangAvailiable = false
        lastLetter = letter
        inputOther = lastLetter
    }
    
    func hoegKeypadTap() {
        hangulAutomata.deleteBuffer()
        var isHoegAvailable: Bool = true
        
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
            isHoegAvailable = false
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
            isHoegAvailable = false
            curLetter = "ㅣ"
            
        case "ㅡ":
            isHoegAvailable = false
            curLetter = "ㅡ"
            
        default:
            isHoegAvailable = false
            curLetter = ""
        }
        
        isHoegSsangAvailiable = isHoegAvailable
        lastLetter = curLetter
        inputHangul = lastLetter
    }
    
    func hoegKeypadLongPress() {
        hoegPeriod?()
    }
    
    func ssangKeypadTap() {
        hangulAutomata.deleteBuffer()
        var isSsangAvailable: Bool = true
        
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
            isSsangAvailable = false
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
            isSsangAvailable = false
            curLetter = "ㅣ"
        case "ㅡ":
            isSsangAvailable = false
            curLetter = "ㅡ"
            
        default:
            isSsangAvailable = false
            curLetter = ""
        }
        
        isHoegSsangAvailiable = isSsangAvailable
        lastLetter = curLetter
        inputHangul = lastLetter
    }
    
    func ssangKeypadLongPress() {
        ssangComma?()
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
        isHoegSsangAvailiable = false
        lastLetter = "\n"
        inputHangul = lastLetter
    }
    
    func spaceKeypadTap() {
        isHoegSsangAvailiable = false
        lastLetter = " "
        inputHangul = lastLetter
    }
}
