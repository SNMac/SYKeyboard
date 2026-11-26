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

    /// 이 자판이 들어 있는 `KeyboardView`. VC는 키보드 뷰를 private으로 갖고 첫 표시 때에야 루트 뷰에 붙이므로(#216)
    /// 테스트는 자판에서 위로 올라가 찾는다. VC가 뷰를 불러오기 전에는 nil이다
    var enclosingKeyboardView: KeyboardView? {
        var view = superview
        while let current = view {
            if let keyboardView = current as? KeyboardView { return keyboardView }
            view = current.superview
        }
        return nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
