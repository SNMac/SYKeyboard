//
//  NaratgeulDelegate.swift
//  Naratgeul
//
//  Created by 서동환 on 9/11/24.
//

protocol NaratgeulDelegate: AnyObject {
    func getBufferSize() -> Int
    func flushBuffer()
    func inputLastHangeul()
    func inputLastSymbol()
    func hangulKeypadTap(letter: String)
    func otherKeypadTap(letter: String)
    func hoegKeypadTap()
    func ssangKeypadTap()
    func removeKeypadTap(isLongPress: Bool) -> Bool
    func enterKeypadTap()
    func spaceKeypadTap()
    func dragToLeft() -> Bool
    func dragToRight() -> Bool
}
