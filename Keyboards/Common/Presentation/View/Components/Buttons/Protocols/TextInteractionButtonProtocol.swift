//
//  TextInteractionButtonProtocol.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit

/// 입력 상호작용 버튼 프로토콜
protocol TextInteractionButtonProtocol: BaseKeyboardButton {
    var button: TextInteractionButton { get }
}
