//
//  FourColumnWidthLayoutController.swift
//  SYKeyboardCore
//

import UIKit

/// 4열 격자 키보드 행의 열 폭 비율을 관리한다.
///
/// 각 행의 1~3열은 서로 등폭이고 4열만 배율에 따라 폭이 바뀐다.
/// 등폭 제약은 배율과 무관하므로 한 번만 만들고,
/// 4열 제약만 배율이 바뀔 때 다시 만든다
final class FourColumnWidthLayoutController {

    // MARK: - Properties

    private var rows: [UIStackView] = []
    private weak var referenceView: UIView?
    /// 배율이 바뀌면 다시 만들어야 하는 제약
    private var ratioConstraints: [NSLayoutConstraint] = []
    /// 마지막으로 적용한 배율. 값이 그대로면 제약을 다시 만들지 않는다
    private var currentMultiplier: Double?

    // MARK: - Internal Methods

    /// 행 스택을 `.fill`로 바꾸고 열 폭 제약을 설치합니다.
    ///
    /// `setHierarchy()`가 끝나 각 행에 4개의 `arrangedSubviews`가 채워진 뒤 호출해야 합니다.
    /// - Parameters:
    ///   - rows: 각각 4열을 가진 행 스택
    ///   - referenceView: 배율이 바뀔 때 레이아웃을 무효화할 키보드 뷰
    ///   - multiplier: 글자 열 너비 배율
    func install(rows: [UIStackView],
                 referenceView: UIView,
                 multiplier: Double) {
        self.rows = rows
        self.referenceView = referenceView

        for row in rows {
            let columns = row.arrangedSubviews
            assert(columns.count == KeyboardLayoutFigure.fourColumnCount,
                   "4열 격자 행이 아닙니다: \(columns.count)열")
            guard columns.count == KeyboardLayoutFigure.fourColumnCount else { continue }

            row.distribution = .fill
            // 1~3열은 배율과 무관하게 서로 등폭이다.
            // 행 간격이 0이므로(`KeyboardRowHStackView.spacing == 0`)
            // 배율 1.0에서 이 제약들의 해는 `.fillEqually`와 정확히 같다
            NSLayoutConstraint.activate([
                columns[0].widthAnchor.constraint(equalTo: columns[1].widthAnchor),
                columns[1].widthAnchor.constraint(equalTo: columns[2].widthAnchor)
            ])
        }

        currentMultiplier = multiplier
        activateRatioConstraints(multiplier: multiplier)
    }

    /// 배율이 바뀌면 4열 제약만 다시 만듭니다.
    ///
    /// `NSLayoutConstraint.multiplier`가 읽기 전용이므로 재생성이 필요합니다.
    /// 제약만 바꾸면 프레임이 갱신되지 않으므로 영향받는 뷰의 레이아웃을 함께 무효화합니다
    func update(multiplier: Double) {
        guard multiplier != currentMultiplier else { return }
        currentMultiplier = multiplier

        NSLayoutConstraint.deactivate(ratioConstraints)
        ratioConstraints.removeAll()
        activateRatioConstraints(multiplier: multiplier)

        rows.forEach { $0.setNeedsLayout() }
        referenceView?.setNeedsLayout()
    }
}

// MARK: - Private Methods

private extension FourColumnWidthLayoutController {
    func activateRatioConstraints(multiplier: Double) {
        let functionColumnRatio = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

        for row in rows {
            let columns = row.arrangedSubviews
            guard columns.count == KeyboardLayoutFigure.fourColumnCount else { continue }

            ratioConstraints.append(
                columns[3].widthAnchor.constraint(equalTo: row.widthAnchor,
                                                  multiplier: functionColumnRatio)
            )
        }

        NSLayoutConstraint.activate(ratioConstraints)
    }
}
