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

    @Test("초기 setup은 active primary만 표시")
    func testInitialSetupShowsOnlyActivePrimaryView() {
        let controller = TestMultiplePrimaryViewController()

        controller.loadViewIfNeeded()

        #expect(controller.firstPrimaryKeyboardView.isHidden == false)
        #expect(controller.secondPrimaryKeyboardView.isHidden)
    }

    @Test("nil text input 뒤 같은 input은 다시 알리지 않음")
    func testNilTextInputKeepsLastNotifiedIdentity() {
        let controller = TestMultiplePrimaryViewController()
        let first = UITextField()
        let firstIdentifier: ObjectIdentifier? = ObjectIdentifier(first)
        controller.loadViewIfNeeded()

        controller.textWillChange(first)
        controller.textWillChange(nil)
        controller.textWillChange(first)

        #expect(controller.notifiedTextInputIdentifiers == [firstIdentifier])
    }

    @Test("nil text input 뒤 다른 input은 한 번 알림")
    func testDifferentTextInputAfterNilNotifiesOnce() {
        let controller = TestMultiplePrimaryViewController()
        let first = UITextField()
        let second = UITextField()
        let firstIdentifier: ObjectIdentifier? = ObjectIdentifier(first)
        let secondIdentifier: ObjectIdentifier? = ObjectIdentifier(second)
        controller.loadViewIfNeeded()

        controller.textWillChange(first)
        controller.textWillChange(nil)
        controller.textWillChange(second)

        #expect(controller.notifiedTextInputIdentifiers == [firstIdentifier, secondIdentifier])
    }
}

@MainActor
private final class TestMultiplePrimaryViewController: BaseKeyboardViewController {
    let firstPrimaryKeyboardView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let secondPrimaryKeyboardView = TestPrimaryKeyboardView(keyboard: .qwerty)
    private(set) var notifiedTextInputIdentifiers: [ObjectIdentifier?] = []

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        firstPrimaryKeyboardView
    }

    override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        [firstPrimaryKeyboardView, secondPrimaryKeyboardView]
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}

    override func textInputDidChange(_ textInput: (any UITextInput)?) {
        notifiedTextInputIdentifiers.append(textInput.map { ObjectIdentifier($0 as AnyObject) })
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
