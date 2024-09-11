//
//  DEP_SYKeyboardDelegate.swift
//  Naratgeul
//
//  Created by 서동환 on 9/11/24.
//
//  Deprecated) HangeulInputMethod가 deprecated됨
//

import Foundation

protocol DEP_SYKeyboardDelegate: AnyObject {
    func inputLastInput()
    func keypadTap(letter: String)
    func hoegKeypadTap()
    func hoegKeypadLongPress()
    func ssangKeypadTap()
    func ssangKeypadLongPress()
    func removeKeypadTap(isLongPress: Bool) -> Bool
    func dragToLeft() -> Bool
    func dragToRight() -> Bool
}
