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
    var keyboard: SYKeyboardType { get }
    /// `TextInteractionButton` 프로토콜을 채택한(입력 상호작용이 있는) 버튼들의 배열
    var totalTextInteractionButtonList: [TextInteractionButton] { get }
    /// 삭제 버튼
    var deleteButton: DeleteButton { get }
}
