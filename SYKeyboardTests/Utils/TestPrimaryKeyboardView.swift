//
//  TestPrimaryKeyboardView.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// 쿼티와 같은 10/9/7 열 구성을 가진 primary keyboard view. 어떤 자판인지는 주입한 `keyboard`로 정한다
@MainActor
final class TestPrimaryKeyboardView: StandardKeyboardView, PrimaryKeyboardRepresentable {
    private let keyboardType: SYKeyboardType

    override var keyboard: SYKeyboardType { keyboardType }

    // 열 개수가 `switchButtonWidthMultiplier` 계산에 쓰이므로 실제 쿼티와 같은 10/9/7을 유지한다
    override var primaryKeyList: [[[[String]]]] {
        [
            [
                [ ["q"], ["w"], ["e"], ["r"], ["t"], ["y"], ["u"], ["i"], ["o"], ["p"] ],
                [ ["a"], ["s"], ["d"], ["f"], ["g"], ["h"], ["j"], ["k"], ["l"] ],
                [ ["z"], ["x"], ["c"], ["v"], ["b"], ["n"], ["m"] ]
            ],
            [
                [ ["Q"], ["W"], ["E"], ["R"], ["T"], ["Y"], ["U"], ["I"], ["O"], ["P"] ],
                [ ["A"], ["S"], ["D"], ["F"], ["G"], ["H"], ["J"], ["K"], ["L"] ],
                [ ["Z"], ["X"], ["C"], ["V"], ["B"], ["N"], ["M"] ]
            ]
        ]
    }

    override var secondaryKeyList: [[[[String]]]] {
        [
            [
                [ [], [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [] ]
            ],
            [
                [ [], [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [], [], [] ],
                [ [], [], [], [], [], [], [] ]
            ]
        ]
    }

    init(keyboard: SYKeyboardType, showsLanguageSwitchButton: Bool = false, showsNumberRow: Bool = false) {
        self.keyboardType = keyboard
        super.init(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: showsLanguageSwitchButton,
            showsNumberRow: showsNumberRow
        )
    }

    func initShiftButton() {
        updateShiftButton(to: false)
    }

    func updateShiftButton(to isShifted: Bool) {
        self.isShifted = isShifted
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
