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
    let isEnabled: Bool
    /// 숫자 키 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    let buttonList: [PrimaryKeyButton]
    /// 숫자 행 높이 제약. 방향에 따라 `updateHeight(_:)`가 상수를 바꾼다
    private var heightConstraint: NSLayoutConstraint?

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
    /// 꺼져 있으면 `contentView`를 `container` 맨 위에 붙인다
    func install(in container: UIView, above contentView: UIView) {
        guard isEnabled else {
            contentView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            return
        }

        container.addSubview(hStackView)
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

    func updateHeight(_ height: CGFloat) {
        guard let heightConstraint,
              heightConstraint.constant != height else { return }
        heightConstraint.constant = height
    }
}
