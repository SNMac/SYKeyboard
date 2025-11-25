//
//  TextInteractionGestureHandling.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/7/25.
//

import UIKit

/// 입력 상호작용 버튼 제스처 핸들러 프로토콜
public protocol TextInteractionGestureHandling: UIView {
    /// `TextInteractable` 프로토콜을 채택한(입력 상호작용이 있는) 버튼들의 배열
    var totalTextInterableButtonList: [TextInteractable] { get }
}
