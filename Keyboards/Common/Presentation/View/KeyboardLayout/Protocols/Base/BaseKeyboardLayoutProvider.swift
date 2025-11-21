//
//  BaseKeyboardLayoutProvider.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/4/25.
//

import UIKit

/// 키보드 레이아웃 원형 프로토콜
protocol BaseKeyboardLayoutProvider: UIView {
    /// 키보드 종류
    var keyboard: SYKeyboardType { get }
    /// 모든 버튼 배열
    var allButtonList: [BaseKeyboardButton] { get }
    /// 주 키보드 버튼 배열
    var primaryButtonList: [PrimaryButton] { get }
    /// 보조 키보드 버튼 배열
    var secondaryButtonList: [SecondaryButton] { get }
    /// `TextInteractable` 프로토콜을 채택한(입력 상호작용이 있는) 버튼들의 배열
    var totalTextInterableButtonList: [TextInteractable] { get }
    /// 삭제 버튼
    var deleteButton: DeleteButton { get }
}
