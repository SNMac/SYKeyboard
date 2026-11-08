//
//  KeyboardSplitViews.swift
//  SYKeyboardCore
//
//  Created by Claude on 11/9/26.
//

import UIKit

/// 분할 자판에서만 보이는 뷰(가운데 간격, 경계 키 복제본, 왼쪽 반쪽 스페이스)를 만들고 제약을 거는 도우미.
///
/// 이 뷰들은 평소에는 숨겨 둔다. `UIStackView`는 숨긴 arranged subview의 폭을 0으로 묶으므로,
/// 폭 제약은 그보다 낮은 우선순위로 걸어 숨긴 동안 충돌 없이 지게 한다
enum KeyboardSplitViews {

    /// 숨긴 동안 `UIStackView`의 숨김 제약(폭 0)이 이기도록 쓰는 폭 제약 우선순위
    static let hideableWidthPriority = UILayoutPriority(999)

    /// 숨긴 채로 만든 빈 칸. 분할 간격이나 왼쪽 반쪽 빈칸으로 쓴다
    static func makeHiddenSpacer() -> KeyboardSpacer {
        let spacer = KeyboardSpacer()
        spacer.isHidden = true

        return spacer
    }

    /// 숨길 수 있는 뷰의 폭을 기준 뷰 폭의 배수로 건다
    static func activateHideableWidth(of view: UIView, equalTo referenceView: UIView, multiplier: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        let width = view.widthAnchor.constraint(equalTo: referenceView.widthAnchor, multiplier: multiplier)
        width.priority = hideableWidthPriority
        width.isActive = true
    }

    /// 분할 자판 넷째 줄 왼쪽 반쪽을 채운다.
    ///
    /// 스페이스가 있는 입력 모드면 왼쪽 반쪽에도 스페이스를, 스페이스가 없는 모드(URL)면 빈칸을 둔다.
    /// 왼쪽 반쪽이 비면 가운데 간격 위치를 정할 수 없어 둘 중 하나는 반드시 보여야 한다
    static func updateLeftHalfSpace(
        leftSpaceButton: UIView,
        filler: UIView,
        usesSplitLayout: Bool,
        isSpaceHidden: Bool
    ) {
        let showsLeftSpace = usesSplitLayout && !isSpaceHidden
        let showsFiller = usesSplitLayout && isSpaceHidden
        if leftSpaceButton.isHidden == showsLeftSpace { leftSpaceButton.isHidden = !showsLeftSpace }
        if filler.isHidden == showsFiller { filler.isHidden = !showsFiller }
    }
}
