//
//  BaseKeyboardLayoutProtocols.swift
//  Keyboard
//
//  Created by 서동환 on 9/4/25.
//

import UIKit

/// 키보드 레이아웃 원형 프로토콜
protocol BaseKeyboardLayout: UIView {
    /// `TextInteractionButton` 프로토콜을 채택한 버튼들의 배열(리턴 버튼 제외)
    var totalTextInteractionButtonList: [TextInteractionButtonProtocol] { get }
    /// 삭제 버튼
    var deleteButton: DeleteButton { get }
}

/// 일반적인 상황에 나타나는 키보드 레이아웃 프로토콜
protocol DefaultKeyboardLayout: BaseKeyboardLayout {
    /// 스페이스 버튼
    var spaceButton: SpaceButton { get }
    /// 리턴 버튼
    var returnButton: ReturnButton { get }
    /// 키보드 전환 버튼
    var switchButton: SwitchButton { get }
    /// iPhone SE용 키보드 전환 버튼
    var nextKeyboardButton: NextKeyboardButton { get }
}
