//
//  DEP_SYKeyboardIOManager.swift
//  Naratgeul
//
//  Created by 서동환 on 9/11/24.
//
//  Deprecated) HangeulInputMethod가 deprecated됨
//

import Foundation
import SwiftUI

final class DEP_SYKeyboardIOManager {
    private let hangeulInputMethod = DEP_HangeulInputMethod()
    var isHoegSsangAvailiable: Bool = false
    
    private var inputKey: String = "" {
        didSet {
            if inputKey == "" {
                onlyUpdateHoegSsang?()
            } else {
                if !hangeulInputMethod.getBufferIsEmpty() {
                    let _ = deleteText?()
                }
                let textArr = hangeulInputMethod.inputMethod(key: inputKey)
                for t in textArr {
                    inputText?(t)
                }
            }
        }
    }
    
    var inputText: ((String) -> Void)?
    var deleteText: (() -> Bool)?
    var attemptRestoreWord: (() -> Bool)?
    var hoegPeriod: (() -> Void)?
    var ssangComma: (() -> Void)?
    var onlyUpdateHoegSsang: (() -> Void)?
    var moveCursorToLeft: (() -> Bool)?
    var moveCursorToRight: (() -> Bool)?
}

extension DEP_SYKeyboardIOManager: DEP_SYKeyboardDelegate {
    func inputLastInput() {
        inputKey = hangeulInputMethod.getLastInput()
    }
    
    func keypadTap(letter: String) {
        let curLetter: String
        let lastLetter = hangeulInputMethod.getLastInput()
        
        switch letter {
        case "ㅏ" :
            if lastLetter == "ㅏ" {
                let _ = hangeulInputMethod.removeMethod()
                if hangeulInputMethod.getLastInput() == "ㅗ" {  // ㅘ
                    let _ = hangeulInputMethod.inputMethod(key: "ㅏ")
                    curLetter = "ㅏ"
                } else {
                    curLetter = "ㅓ"
                }
            } else if lastLetter == "ㅓ" {
                let _ = hangeulInputMethod.removeMethod()
                if hangeulInputMethod.getLastInput() == "ㅜ" {  // ㅝ
                    let _ = hangeulInputMethod.inputMethod(key: "ㅓ")
                    curLetter = "ㅏ"
                } else {
                    curLetter = "ㅏ"
                }
            } else if lastLetter == "ㅜ" {
                curLetter = "ㅓ"
            } else {
                curLetter = "ㅏ"
            }
            
        case "ㅗ" :
            if lastLetter == "ㅗ" {
                let _ = hangeulInputMethod.removeMethod()
                curLetter = "ㅜ"
            } else if lastLetter == "ㅜ" {
                let _ = hangeulInputMethod.removeMethod()
                curLetter = "ㅗ"
            } else {
                curLetter = "ㅗ"
            }
            
        default:
            curLetter = letter
        }
        
        inputKey = curLetter
    }
    
    func hoegKeypadTap() {
        var curLetter: String = ""
        let lastLetter = hangeulInputMethod.getLastInput()
        var isHoegAvailable: Bool = true
        
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
            let _ = hangeulInputMethod.removeMethod()
        }
        inputKey = curLetter
    }
    
    func hoegKeypadLongPress() {
        hoegPeriod?()
    }
    
    func ssangKeypadTap() {
        var curLetter: String = ""
        let lastLetter = hangeulInputMethod.getLastInput()
        var isSsangAvailable: Bool = true
        
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
            let _ = hangeulInputMethod.removeMethod()
        }
        inputKey = curLetter
    }
    
    func ssangKeypadLongPress() {
        ssangComma?()
    }
    
    func removeKeypadTap(isLongPress: Bool) -> Bool {
        if let isRestored = attemptRestoreWord?() {
            if !isRestored {
                if hangeulInputMethod.getBufferIsEmpty() {
                    if let isDeleted = deleteText?() {
                        return isDeleted
                    } else {
                        return false
                    }
                } else {
                    if isLongPress {
                        hangeulInputMethod.deleteBufferLast()
                        let _ = deleteText?()
                    } else {
                        let _ = deleteText?()
                        let _ = deleteText?()
                        
                        let textArr = hangeulInputMethod.removeMethod()
                        for t in textArr {
                            inputText?(t)
                        }
                    }
                    return true
                }
            }
            return true
        }
        return false
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

