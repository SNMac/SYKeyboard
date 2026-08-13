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
    var languageSwitchButton: LanguageSwitchButton? { get }
    var returnButton: ReturnButton { get }
    var totalTextInterableButtonList: [TextInteractable] { get }
    
    func initShiftButton()
    func updateShiftButton(to isShifted: Bool)
    func updateSpaceButtonImage(systemName: String)
}

public extension PrimaryKeyboardRepresentable {
    var languageSwitchButton: LanguageSwitchButton? { nil }

    func updateSpaceButtonImage(systemName: String) {
        spaceButton.updateImage(systemName: systemName)
    }
}
