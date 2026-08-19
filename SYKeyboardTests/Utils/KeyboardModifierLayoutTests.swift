//
//  KeyboardModifierLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

enum FourByFourFixture: Sendable {
    case naratgeul
    case cheonjiin

    @MainActor
    func makeView(showsLanguageSwitchButton: Bool) -> PrimaryKeyboardRepresentable {
        switch self {
        case .naratgeul:
            NaratgeulKeyboardView(showsLanguageSwitchButton: showsLanguageSwitchButton)
        case .cheonjiin:
            CheonjiinKeyboardView(showsLanguageSwitchButton: showsLanguageSwitchButton)
        }
    }
}

@MainActor
@Suite("키보드 modifier row 레이아웃")
struct KeyboardModifierLayoutTests {
    @Test("통합 쿼티의 Language는 글자 버튼 너비이고 Switch와 합쳐 리턴 너비")
    func testUnifiedQwertyModifierFrames() throws {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true
        )
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        let primaryKeyButton = try #require(view.primaryButtonList.first)
        #expect(abs(languageButton.frame.width - primaryKeyButton.frame.width) < 0.5)
        #expect(
            abs(
                view.switchButton.frame.width + languageButton.frame.width
                - view.returnButtonHStackView.frame.width
            ) < 0.5
        )
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX + 0.5)
    }

    @Test("통합 쿼티의 숨겨진 globe는 접히고 flexible space가 넓어짐")
    func testUnifiedQwertyHiddenGlobeCollapsesIntoFlexibleSpace() throws {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true
        )
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        let primaryKeyButton = try #require(view.primaryButtonList.first)
        let visibleGlobeWidth = view.nextKeyboardButton.frame.width
        let visibleSpaceWidth = view.spaceButtonHStackView.frame.width

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            view.spaceButtonHStackView.frame.width
            >= visibleSpaceWidth + visibleGlobeWidth - 0.5
        )
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(abs(languageButton.frame.width - primaryKeyButton.frame.width) < 0.5)
    }

    @Test("통합 쿼티는 동일 globe 상태 반복 갱신 시 레이아웃을 다시 무효화하지 않음")
    func testUnifiedQwertyRepeatedGlobeStateDoesNotInvalidateLayout() throws {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true
        )
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(!view.layer.needsLayout())

        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )

        #expect(!view.layer.needsLayout())
    }

    @Test("전용 쿼티는 Language 없이 기존 Switch와 globe만 유지")
    func testDedicatedQwertyDoesNotCreateLanguageButton() {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false
        )
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let visibleModifierWidth = view.fourthRowLeftSecondaryButtonHStackView.frame.width
        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.languageSwitchButton == nil)
        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(view.fourthRowLeftSecondaryButtonHStackView.frame.width - visibleModifierWidth) < 0.5
        )
    }

    @Test("전용 두벌식은 Language 버튼을 만들지 않음")
    func testDedicatedDubeolsikDoesNotCreateLanguageButton() {
        let view = DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false
        )

        #expect(view.languageSwitchButton == nil)
    }

    @Test("통합 기호 화면의 Language는 글자 버튼 너비이고 Switch와 합쳐 리턴 너비")
    func testUnifiedSymbolModifierFrames() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: true)
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        let primaryKeyButton = try #require(view.primaryButtonList.first)
        #expect(abs(languageButton.frame.width - primaryKeyButton.frame.width) < 0.5)
        #expect(
            abs(
                view.switchButton.frame.width + languageButton.frame.width
                - view.returnButton.frame.width
            ) < 0.5
        )
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX + 0.5)
    }

    @Test("통합 기호 화면의 숨겨진 globe는 접히고 flexible space가 넓어짐")
    func testUnifiedSymbolHiddenGlobeCollapsesIntoFlexibleSpace() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: true)
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        let primaryKeyButton = try #require(view.primaryButtonList.first)
        let visibleGlobeWidth = view.nextKeyboardButton.frame.width
        let visibleSpaceWidth = view.spaceButtonHStackView.frame.width

        let symbolView: SymbolKeyboardLayoutProvider = view
        symbolView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            view.spaceButtonHStackView.frame.width
            >= visibleSpaceWidth + visibleGlobeWidth - 0.5
        )
        #expect(abs(languageButton.frame.width - primaryKeyButton.frame.width) < 0.5)
        #expect(
            abs(
                view.switchButton.frame.width + languageButton.frame.width
                - view.returnButton.frame.width
            ) < 0.5
        )
    }

    @Test("전용 기호 화면은 Language 버튼을 만들지 않음")
    func testDedicatedSymbolDoesNotCreateLanguageButton() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false)

        #expect(view.languageSwitchButton == nil)
    }

    @Test(arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testFourByFourModifierOrder(_ fixture: FourByFourFixture) throws {
        let primaryView = fixture.makeView(showsLanguageSwitchButton: true)
        let view = primaryView
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(primaryView.languageSwitchButton)
        #expect(primaryView.nextKeyboardButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= primaryView.switchButton.frame.minX + 0.5)
    }

    @Test(arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testDedicatedFourByFourDoesNotCreateLanguageButton(_ fixture: FourByFourFixture) {
        let primaryView = fixture.makeView(showsLanguageSwitchButton: false)

        #expect(primaryView.languageSwitchButton == nil)
    }
}
