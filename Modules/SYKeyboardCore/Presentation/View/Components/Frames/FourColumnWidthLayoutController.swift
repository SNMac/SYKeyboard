//
//  FourColumnWidthLayoutController.swift
//  SYKeyboardCore
//

import UIKit

/// 4열 격자 키보드 행의 열 폭 비율을 관리한다.
///
/// 각 행의 1~3열은 서로 등폭이고 4열만 배율에 따라 폭이 바뀐다.
/// 등폭 제약은 배율과 무관하므로 한 번만 만들고,
/// 4열 제약과 한영 전환 버튼 제약만 배율이 바뀔 때 다시 만든다
final class FourColumnWidthLayoutController {

    // MARK: - Properties

    private var rows: [UIStackView] = []
    private weak var languageSwitchButton: UIView?
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
    ///   - languageSwitchButton: 한영 전환 버튼. 없으면 `nil`
    ///   - referenceView: 한영 전환 버튼 폭의 기준이 되는 키보드 뷰
    ///   - multiplier: 글자 열 너비 배율
    func install(rows: [UIStackView],
                 languageSwitchButton: UIView?,
                 referenceView: UIView,
                 multiplier: Double) {
        self.rows = rows
        self.languageSwitchButton = languageSwitchButton
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

    /// 배율이 바뀌면 4열 제약과 한영 전환 버튼 제약만 다시 만듭니다.
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

        if let languageSwitchButton, let referenceView {
            languageSwitchButton.translatesAutoresizingMaskIntoConstraints = false
            // 한영 전환 버튼은 자기가 속한 열의 폭에 비례해야 한다.
            // 하단 스페이스 배치에서는 modifier 스택이 1열(배율을 올리면 넓어지는 열)에 오므로,
            // 전체 폭을 기준으로 삼으면 열은 넓어지는데 버튼만 좁아진다
            let columnView = languageSwitchButton.superview ?? referenceView
            let languageSwitchWidth = languageSwitchButton.widthAnchor.constraint(
                equalTo: columnView.widthAnchor,
                multiplier: KeyboardLayoutFigure.languageSwitchButtonFunctionColumnShare
            )
            // 지구본이 보이면 stack의 균등 분배(required)가 이기고 이 제약은 양보해야 하므로
            // required보다 낮춘다. 지구본이 숨겨지면 경쟁하는 제약이 없어 그대로 성립한다
            languageSwitchWidth.priority = .init(999)
            ratioConstraints.append(languageSwitchWidth)
        }

        NSLayoutConstraint.activate(ratioConstraints)
    }
}
