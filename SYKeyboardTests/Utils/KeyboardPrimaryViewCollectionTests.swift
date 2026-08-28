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

    @Test("통합 primary collection은 symbol 언어 버튼도 opt-in")
    func testUnifiedPrimaryViewsOptInSymbolLanguageButton() throws {
        let first = TestPrimaryKeyboardView(keyboard: .dubeolsik, showsLanguageSwitchButton: true)
        let second = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: true)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])
        let button = try #require(view.symbolKeyboardView.languageSwitchButton)
        let symbolView = view.symbolKeyboardView
        let primaryKeyButton = try #require(view.symbolKeyboardView.primaryButtonList.first)

        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        symbolView.isHidden = false
        view.layoutIfNeeded()

        #expect(view.symbolKeyboardView.allButtonList.contains { $0 === button })
        #expect(button.frame.width + 0.5 >= primaryKeyButton.frame.width)
        #expect(view.symbolKeyboardView.switchButton.frame.maxX <= button.frame.minX + 0.5)
        #expect(button.frame.maxX <= view.symbolKeyboardView.nextKeyboardButton.frame.minX + 0.5)
        button.updateLanguageMode(.english)
        #expect(button.languageMode == .english)
    }

    @Test("통합 primary collection은 numeric 언어 버튼도 opt-in")
    func testUnifiedPrimaryViewsOptInNumericLanguageButton() throws {
        // numericKeyboardView는 isNumericKeypadBottomSpaceEnabled 저장값에 따라
        // modifier 순서가 달라지므로, 이 테스트가 기대하는 꺼짐 순서로 고정한다
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isNumericKeypadBottomSpaceEnabled
        let originalValue = storage.object(forKey: key)
        storage.set(false, forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        let first = TestPrimaryKeyboardView(keyboard: .dubeolsik, showsLanguageSwitchButton: true)
        let second = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: true)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])
        let button = try #require(view.numericKeyboardView.languageSwitchButton)
        let numericView = view.numericKeyboardView

        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        numericView.isHidden = false
        view.layoutIfNeeded()

        #expect(numericView.allButtonList.contains { $0 === button })
        #expect(numericView.nextKeyboardButton.frame.maxX <= button.frame.minX + 0.5)
        #expect(button.frame.maxX <= numericView.switchButton.frame.minX + 0.5)
        button.updateLanguageMode(.english)
        #expect(button.languageMode == .english)
    }

    @Test("전용 primary collection은 numeric 언어 버튼도 만들지 않음")
    func testDedicatedPrimaryViewDoesNotOptInNumericLanguageButton() {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: false)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])

        #expect(view.numericKeyboardView.languageSwitchButton == nil)
    }

    @Test("통합 symbol은 숨겨진 globe 폭을 space로 반환")
    func testUnifiedSymbolHiddenGlobeCollapsesIntoFlexibleSpace() throws {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: true)
        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])
        let symbolView = view.symbolKeyboardView

        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        symbolView.isHidden = false
        view.layoutIfNeeded()

        let visibleGlobeWidth = view.symbolKeyboardView.nextKeyboardButton.frame.width
        let visibleSpaceWidth = view.symbolKeyboardView.spaceButtonHStackView.frame.width
        view.symbolKeyboardView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        symbolView.layoutIfNeeded()

        #expect(view.symbolKeyboardView.nextKeyboardButton.isHidden)
        #expect(
            view.symbolKeyboardView.spaceButtonHStackView.frame.width
            >= visibleSpaceWidth + visibleGlobeWidth - 0.5
        )
    }

    @Test("통합 symbol은 동일 globe 상태 반복 갱신 시 레이아웃을 다시 무효화하지 않음")
    func testUnifiedSymbolRepeatedGlobeStateDoesNotInvalidateLayout() throws {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: true)
        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])
        let symbolView = view.symbolKeyboardView

        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        symbolView.isHidden = false
        view.layoutIfNeeded()

        view.symbolKeyboardView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        symbolView.layoutIfNeeded()

        #expect(!symbolView.layer.needsLayout())

        view.symbolKeyboardView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )

        #expect(!symbolView.layer.needsLayout())
    }

    @Test("전용 primary collection은 symbol 언어 버튼과 modifier 폭을 유지")
    func testDedicatedPrimaryViewDoesNotOptInSymbolLanguageButton() throws {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: false)
        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])
        let symbolView = view.symbolKeyboardView

        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        symbolView.isHidden = false
        view.layoutIfNeeded()

        let visibleModifierWidth = view.symbolKeyboardView.fourthRowLeftSecondaryButtonHStackView.frame.width
        view.symbolKeyboardView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        symbolView.layoutIfNeeded()

        #expect(view.symbolKeyboardView.languageSwitchButton == nil)
        #expect(view.symbolKeyboardView.nextKeyboardButton.isHidden)
        #expect(
            abs(
                view.symbolKeyboardView.fourthRowLeftSecondaryButtonHStackView.frame.width
                - visibleModifierWidth
            ) < 0.5
        )
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

// MARK: - Test Helpers

private extension KeyboardPrimaryViewCollectionTests {
    func restore(_ value: Any?, forKey key: String, in storage: UserDefaults) {
        if let value {
            storage.set(value, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
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

    init(keyboard: SYKeyboardType, showsLanguageSwitchButton: Bool = false) {
        self.keyboardType = keyboard
        super.init(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: showsLanguageSwitchButton
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
