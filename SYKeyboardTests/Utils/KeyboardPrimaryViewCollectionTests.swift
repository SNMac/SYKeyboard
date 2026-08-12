//
//  KeyboardPrimaryViewCollectionTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("주 키보드 view collection 검증")
@MainActor
struct KeyboardPrimaryViewCollectionTests {

    @Test("KeyboardView는 전달된 primary view를 모두 같은 container에 유지")
    func testKeyboardViewKeepsAllPrimaryViews() {
        let first = TestPrimaryKeyboardView(keyboard: .dubeolsik)
        let second = TestPrimaryKeyboardView(keyboard: .qwerty)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])

        #expect(view.primaryKeyboardViews.count == 2)
        #expect(view.primaryKeyboardViews[0] === first)
        #expect(view.primaryKeyboardViews[1] === second)
        #expect(first.superview === second.superview)
        #expect(first.translatesAutoresizingMaskIntoConstraints == false)
        #expect(second.translatesAutoresizingMaskIntoConstraints == false)
    }
}

@MainActor
private final class TestPrimaryKeyboardView: StandardKeyboardView, PrimaryKeyboardRepresentable {
    private let keyboardType: SYKeyboardType

    override var keyboard: SYKeyboardType { keyboardType }

    override var primaryKeyList: [[[[String]]]] {
        [
            [
                [["a"]], [["b"]], [["c"]]
            ],
            [
                [["A"]], [["B"]], [["C"]]
            ]
        ]
    }

    override var secondaryKeyList: [[[[String]]]] {
        [
            [
                [[]], [[]], [[]]
            ],
            [
                [[]], [[]], [[]]
            ]
        ]
    }

    init(keyboard: SYKeyboardType) {
        self.keyboardType = keyboard
        super.init(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in }
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
