//
//  PrimaryKeyboardRepresentable.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

/// 주 키보드가 채택해야 하는 프로토콜
public protocol PrimaryKeyboardRepresentable: NormalKeyboardLayoutProvider {
    var switchButton: SwitchButton { get }
    var returnButton: ReturnButton { get }
    var totalTextInterableButtonList: [TextInteractable] { get }
    
    func updateNextKeyboardButton(needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector)
    func initShiftButton()
    func updateShiftButton(isShifted: Bool)
}
