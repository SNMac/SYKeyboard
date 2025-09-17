//
//  TextInteractionButtonGestureHandler.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/7/25.
//

import UIKit

/// 입력 상호작용 버튼 제스처 핸들러 프로토콜
protocol TextInteractionButtonGestureHandler: UIView {
    /// `TextInteractionButton` 프로토콜을 채택한(입력 상호작용이 있는) 버튼들의 배열
    var totalTextInteractionButtonList: [TextInteractionButton] { get }
}
