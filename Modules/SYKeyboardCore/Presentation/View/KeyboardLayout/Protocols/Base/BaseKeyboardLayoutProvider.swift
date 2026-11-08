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
    /// 분할 자판 여부를 적용한다. 분할 여부는 `KeyboardSplitLayoutPolicy`가 정한다
    func updateSplitLayout(_ usesSplitLayout: Bool)
}

public extension BaseKeyboardLayoutProvider {
    /// 기본값은 분할 배치가 없는 키보드(테스트용 자판 등)를 위한 것이다
    func updateSplitLayout(_ usesSplitLayout: Bool) {}
}
