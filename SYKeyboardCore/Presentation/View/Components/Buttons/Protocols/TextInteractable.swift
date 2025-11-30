//
//  TextInteractable.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/3/25.
//

import UIKit

/// 입력 상호작용 프로토콜
public protocol TextInteractable: BaseKeyboardButton {
    var type: TextInteractableType { get }
}
