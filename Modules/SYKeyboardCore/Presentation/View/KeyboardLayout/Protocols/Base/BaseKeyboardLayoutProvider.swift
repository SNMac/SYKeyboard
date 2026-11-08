//
//  BaseKeyboardLayoutProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/4/25.
//

import UIKit

/// 키보드 레이아웃 원형 프로토콜
public protocol BaseKeyboardLayoutProvider: UIView {
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
    /// 분할 자판 여부를 적용한다. 분할 여부는 `KeyboardSplitLayoutPolicy`가 정한다.
    /// 새 자판이 빠뜨리지 않도록 기본 구현을 두지 않는다
    func updateSplitLayout(_ usesSplitLayout: Bool)
}
