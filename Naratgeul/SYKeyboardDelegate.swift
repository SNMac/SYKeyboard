//
//  SYKeyboardDelegate.swift
//  Naratgeul
//
//  Created by 서동환 on 9/11/24.
//

import Foundation

protocol SYKeyboardDelegate: AnyObject {
    func getBufferSize() -> Int
    func flushBuffer()
    func inputLastHangul()
    func inputLastSymbol()
    func hangulKeypadTap(letter: String)
    func symbolKeypadTap(letter: String)
    func checkHoegSsangAvailable()
    func hoegKeypadTap()
    func hoegToComma(isLongPress: Bool)
    func ssangKeypadTap()
    func ssangToPeriod(isLongPress: Bool)
    func removeKeypadTap(isLongPress: Bool) -> Bool
    func enterKeypadTap()
    func spaceKeypadTap()
    func dragToLeft() -> Bool
    func dragToRight() -> Bool
}
