//
//  BaseKeyboardLayout.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/4/25.
//

import UIKit

/// 키보드 레이아웃 원형 프로토콜
protocol BaseKeyboardLayout: UIView {
    /// 키보드 종류
    var keyboard: Keyboard { get }
    /// `TextInteractionButton` 프로토콜을 채택한 버튼들의 배열(리턴 버튼 제외)
    var totalTextInteractionButtonList: [TextInteractionButtonProtocol] { get }
    /// 삭제 버튼
    var deleteButton: DeleteButton { get }
}
