//
//  PrimaryKeyboardView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

protocol PrimaryKeyboardView: UIView {
    var switchButton: SwitchButton { get }
    var returnButton: ReturnButton { get }
    var totalTextInteractionButtonList: [TextInteractionButtonProtocol] { get }
    
    func updateNextKeyboardButton(needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector)
    
    // 영어 키보드에만 필요한 기능이지만, 프로토콜 확장에서 기본 구현을 제공하여 선택적으로 구현하도록 합니다.
    func initShiftButton()
}
