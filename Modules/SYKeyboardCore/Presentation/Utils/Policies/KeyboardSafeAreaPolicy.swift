//
//  KeyboardSafeAreaPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 11/1/26.
//

import UIKit

/// 키보드 뷰의 safe area 중 키 영역 여백에 반영할 부분
enum KeyboardSafeAreaPolicy {

    /// 키 영역 여백에 더할 safe area. 위·좌·우는 그대로 반영하고 아래는 반영하지 않는다.
    ///
    /// iOS는 홈 인디케이터 자리를 키보드 뷰 아래에 따로 비우면서, iPhone Duo에서는 뷰 안에도 아래 safe area
    /// (바깥 화면 가로는 키보드 window에 따라 66pt 또는 18pt)를 알려 준다. 이를 더하면 같은 높이 안에서 글자 행이
    /// 눌리고, 시스템 키보드보다 아래 빈 공간이 커진다
    static func keyAreaInsets(safeAreaInsets: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: safeAreaInsets.top,
            left: safeAreaInsets.left,
            bottom: 0,
            right: safeAreaInsets.right
        )
    }
}
