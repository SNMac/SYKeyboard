//
//  NormalKeyboardLayoutProvider.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

/// 일반적인 상황에 나타나는 키보드의 레이아웃 프로토콜
public protocol NormalKeyboardLayoutProvider: BaseKeyboardLayoutProvider {
    /// 스페이스 버튼
    var spaceButton: SpaceButton { get }
    /// 리턴 버튼
    var returnButton: ReturnButton { get }
    /// 키보드 전환 버튼
    var switchButton: SwitchButton { get }
    /// iPhone SE용 키보드 전환 버튼
    var nextKeyboardButton: NextKeyboardButton { get }
}

// MARK: - Protocol Properties & Methods

public extension NormalKeyboardLayoutProvider {
    func updateNextKeyboardButton(needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector) {
        nextKeyboardButton.addTarget(nil, action: nextKeyboardAction, for: .allTouchEvents)
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    }
}
