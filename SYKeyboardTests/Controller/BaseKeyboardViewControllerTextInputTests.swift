//
//  BaseKeyboardViewControllerTextInputTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("BaseKeyboardViewController primary view 표시와 text input 변경 알림", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerTextInputTests {

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

// MARK: - Test Helpers

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
