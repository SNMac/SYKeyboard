//
//  FourColumnWidthLayoutController.swift
//  SYKeyboardCore
//

import UIKit

/// 4열 격자 키보드 행의 열 폭 비율을 관리한다.
///
/// 각 행의 1~3열은 서로 등폭이고 4열만 배율에 따라 폭이 바뀐다.
/// 등폭 제약은 배율과 무관하므로 한 번만 만들고,
/// 4열 제약만 배율이 바뀔 때 다시 만든다.
///
/// 분할 자판에서는 2열과 3열 사이에 간격을 넣고 네 열을 등폭으로 둔다.
/// 배율을 그대로 쓰면 왼쪽 반쪽(글자 열 둘)과 오른쪽 반쪽(글자 열 + 기능 열)의 폭이 달라져
/// 간격이 접히는 선에서 벗어난다
final class FourColumnWidthLayoutController {

    // MARK: - Properties

    private var rows: [UIStackView] = []
    /// `install` 시점의 행별 4열. 분할 간격을 넣은 뒤에도 열 순서를 그대로 쓴다
    private var rowColumns: [[UIView]] = []
    private weak var referenceView: UIView?
    /// 배율이 바뀌면 다시 만들어야 하는 제약
    private var ratioConstraints: [NSLayoutConstraint] = []
    /// 분할 자판에서만 쓰는 4열 등폭 제약
    private var splitConstraints: [NSLayoutConstraint] = []
    /// 행별 분할 간격. `installSplitGaps()`를 부르기 전에는 비어 있다
    private var splitGaps: [KeyboardSpacer] = []
    /// 마지막으로 적용한 배율. 값이 그대로면 제약을 다시 만들지 않는다
    private var currentMultiplier: Double?
    /// 분할 자판 여부
    private var usesSplitLayout = false

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
        self.rowColumns = rows.map(\.arrangedSubviews)
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

    /// 각 행의 2열과 3열 사이에 분할 간격을 넣습니다. 간격은 분할 자판에서만 보입니다.
    ///
    /// `install(rows:referenceView:multiplier:)` 뒤에 한 번 호출해야 합니다
    func installSplitGaps() {
        guard splitGaps.isEmpty else { return }

        let gapRatio = KeyboardSplitLayoutPolicy.gapToColumnRatio(columnCount: KeyboardLayoutFigure.fourColumnCount)
        for (row, columns) in zip(rows, rowColumns) where columns.count == KeyboardLayoutFigure.fourColumnCount {
            let gap = KeyboardSplitViews.makeHiddenSpacer()
            row.insertArrangedSubview(gap, at: 2)
            KeyboardSplitViews.activateHideableWidth(of: gap, equalTo: columns[0], multiplier: gapRatio)
            splitGaps.append(gap)

            splitConstraints.append(columns[3].widthAnchor.constraint(equalTo: columns[0].widthAnchor))
        }
    }

    /// 분할 자판 여부를 바꿉니다. 분할하면 네 열을 등폭으로 두고 간격을 보이고,
    /// 돌아오면 배율 제약을 다시 씁니다
    func updateSplitLayout(_ usesSplitLayout: Bool) {
        guard usesSplitLayout != self.usesSplitLayout else { return }
        self.usesSplitLayout = usesSplitLayout

        splitGaps.forEach { $0.isHidden = !usesSplitLayout }
        if usesSplitLayout {
            NSLayoutConstraint.deactivate(ratioConstraints)
            NSLayoutConstraint.activate(splitConstraints)
        } else {
            NSLayoutConstraint.deactivate(splitConstraints)
            NSLayoutConstraint.activate(ratioConstraints)
        }

        rows.forEach { $0.setNeedsLayout() }
        referenceView?.setNeedsLayout()
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

        for (row, columns) in zip(rows, rowColumns) {
            guard columns.count == KeyboardLayoutFigure.fourColumnCount else { continue }

            ratioConstraints.append(
                columns[3].widthAnchor.constraint(equalTo: row.widthAnchor,
                                                  multiplier: functionColumnRatio)
            )
        }

        // 분할 중에는 등폭 제약을 쓰므로 만들어만 두고 돌아올 때 켠다
        guard !usesSplitLayout else { return }
        NSLayoutConstraint.activate(ratioConstraints)
    }
}
