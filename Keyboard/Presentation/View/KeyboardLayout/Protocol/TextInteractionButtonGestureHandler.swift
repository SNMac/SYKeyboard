//
//  TextInteractionButtonGestureHandler.swift
//  Keyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit

protocol TextInteractionButtonGestureHandler: UIView {
    /// `TextInteractionButton` 프로토콜을 채택한 버튼들의 배열
    var totalTextInteractionButtonList: [TextInteractionButton] { get }
}
