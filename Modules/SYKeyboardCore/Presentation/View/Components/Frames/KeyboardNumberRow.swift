//
//  KeyboardNumberRow.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/23/26.
//

import UIKit

/// 자판 맨 윗줄 숫자 행(1~0).
///
/// 꺼져 있으면 버튼을 만들지 않고, `install(in:above:)`가 아래 레이아웃을 컨테이너 맨 위에 붙인다
@MainActor
final class KeyboardNumberRow {

    // MARK: - Properties

    /// 숫자 행 표시 여부
    private let isEnabled: Bool
    /// 숫자 키 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    let buttonList: [PrimaryKeyButton]
    /// 숫자 행 높이 제약. 방향에 따라 `updateHeight(_:)`가 상수를 바꾼다
    private var heightConstraint: NSLayoutConstraint?
    /// 분할 자판에서 5와 6 사이를 비우는 간격. 숫자 행이 꺼져 있거나 설치 전이면 `nil`이다
    private var splitGap: KeyboardSpacer?

    // MARK: - UI Components

    private let hStackView = KeyboardRowHStackView()

    // MARK: - Initializer

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        // 숫자 키는 어느 자판에 붙든 같은 크기로 보여야 한다.
        // 버튼 여백은 자판 종류로 정해지므로, 4x4 자판에서도 기호 자판과 같은 여백을 쓰도록 `.symbol`로 만든다
        self.buttonList = isEnabled
        ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map {
            PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: [$0], secondary: nil))
        }
        : []
    }

    // MARK: - Methods

    /// 숫자 행을 `container` 맨 위에 붙이고 `contentView`를 그 아래에 둔다.
    /// 꺼져 있으면 `contentView`를 `container` 맨 위에 붙인다.
    /// `contentView`는 이미 `container`의 subview여야 한다
    func install(in container: UIView, above contentView: UIView) {
        guard isEnabled else {
            contentView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            return
        }

        // 자판 선택·한 손 모드 오버레이가 숫자 행을 덮을 수 있도록 콘텐츠 바로 위에 둔다
        container.insertSubview(hStackView, aboveSubview: contentView)
        buttonList.forEach { hStackView.addArrangedSubview($0) }

        hStackView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = hStackView.heightAnchor.constraint(
            equalToConstant: KeyboardHeightPolicy.portraitNumberRowHeight
        )
        NSLayoutConstraint.activate([
            hStackView.topAnchor.constraint(equalTo: container.topAnchor),
            hStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            heightConstraint,
            contentView.topAnchor.constraint(equalTo: hStackView.bottomAnchor)
        ])
        self.heightConstraint = heightConstraint
    }

    /// 5와 6 사이에 분할 간격을 넣습니다. 간격은 분할 자판에서만 보입니다.
    ///
    /// 간격을 넣으려면 행을 `.fill`로 바꿔야 하므로 숫자 키끼리 등폭 제약을 건다.
    /// 간격이 숨겨진 평소에는 `.fillEqually`와 같은 해가 나온다.
    /// `install(in:above:)` 뒤에 한 번 호출해야 합니다
    /// - Parameter gapToKeyRatio: 간격 폭이 숫자 키 하나의 몇 배인지. 표준 자판은 첫 줄과
    ///   가장자리를 맞추려고 첫 줄과 같은 값을, 4열 격자 자판은 간격 폭을 맞춘 값을 준다
    func installSplitGap(gapToKeyRatio: CGFloat) {
        guard isEnabled, splitGap == nil,
              let firstButton = buttonList.first else { return }

        hStackView.distribution = .fill
        buttonList.dropFirst().forEach {
            $0.widthAnchor.constraint(equalTo: firstButton.widthAnchor).isActive = true
        }

        let gap = KeyboardSplitViews.makeHiddenSpacer()
        hStackView.insertArrangedSubview(gap, at: buttonList.count / 2)
        KeyboardSplitViews.activateHideableWidth(of: gap, equalTo: firstButton, multiplier: gapToKeyRatio)
        splitGap = gap
    }

    /// 분할 자판 여부에 따라 간격을 보이거나 숨깁니다
    func updateSplitLayout(_ usesSplitLayout: Bool) {
        splitGap?.isHidden = !usesSplitLayout
    }

    func updateHeight(_ height: CGFloat) {
        guard let heightConstraint,
              heightConstraint.constant != height else { return }
        heightConstraint.constant = height
    }
}
