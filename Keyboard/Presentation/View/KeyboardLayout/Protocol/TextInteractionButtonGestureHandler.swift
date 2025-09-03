//
//  TextInteractionButtonGestureHandler.swift
//  Keyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit

/// 입력 상호작용 버튼 제스처 핸들러 프로토콜
protocol TextInteractionButtonGestureHandler: UIView {
    /// `TextInteractionButton` 프로토콜을 채택한 버튼들의 배열(리턴 버튼 제외)
    var totalTextInteractionButtonList: [TextInteractionButtonProtocol] { get }
}
