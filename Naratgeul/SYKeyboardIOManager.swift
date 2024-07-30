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
    
    private var input: String = "" {
        didSet {
            if input == " " {
                hangulAutomata.buffer.append(" ")
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
    func hangulKeypadTap(char: String) {
        self.input = char
    }
    
    func deleteKeypadTap() {
        hangulAutomata.deleteBuffer()
        updateTextView?(hangulAutomata.buffer.reduce("", { $0 + $1 }))
    }
    
    func enterKeypadTap() {
        dismiss?()
    }
    
    func spaceKeypadTap() {
        self.input = " "
    }
}
