//
//  KeyboardPrimaryViewCollectionTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("주 키보드 view collection 검증", .sharedUserDefaults)
@MainActor
struct KeyboardPrimaryViewCollectionTests {

    @Test("KeyboardView는 전달된 primary view를 모두 자기 계층에 유지")
    func testKeyboardViewKeepsAllPrimaryViews() {
        let first = TestPrimaryKeyboardView(keyboard: .dubeolsik)
        let second = TestPrimaryKeyboardView(keyboard: .qwerty)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])

        #expect(view.primaryKeyboardViews.count == 2)
        #expect(view.primaryKeyboardViews[0] === first)
        #expect(view.primaryKeyboardViews[1] === second)
        #expect(first.isDescendant(of: view))
        #expect(second.isDescendant(of: view))
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
        // numericKeyboardView는 isBottomSpaceEnabled 저장값에 따라
        // modifier 순서가 달라지므로, 이 테스트가 기대하는 꺼짐 순서로 고정한다
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isBottomSpaceEnabled
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

    @Test("기호 자판은 주 자판에 숫자 행이 있으면 숫자 행도 표시한다")
    func test기호자판_주자판숫자행있으면_표시() {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsNumberRow: true)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])

        #expect(view.symbolKeyboardView.showsNumberRow)
    }

    @Test("기호 자판은 주 자판에 숫자 행이 없으면 숫자 행도 숨긴다")
    func test기호자판_주자판숫자행없으면_숨김() {
        let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsNumberRow: false)

        let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])

        #expect(view.symbolKeyboardView.showsNumberRow == false)
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
