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

    @Test("통합 숫자 화면은 globe → 한/영 → 전환 순서이고 한/영은 두벌식과 같은 너비")
    func testUnifiedNumericModifierOrder() throws {
        let width: CGFloat = 390
        let view = NumericKeyboardView(showsLanguageSwitchButton: true)
        view.frame = CGRect(x: 0, y: 0, width: width, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        #expect(view.nextKeyboardButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.switchButton.frame.minX + 0.5)
        // 열 개수와 무관하게 두벌식 한/영 버튼(글자 버튼 한 칸)과 같은 너비
        #expect(
            abs(languageButton.frame.width
                - width * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 남는 너비는 globe와 전환 버튼이 나눠 갖는다.
        // 홀수 폭을 둘로 나누면 픽셀 정렬로 한 칸(최대 1pt) 차이가 날 수 있다
        #expect(abs(view.nextKeyboardButton.frame.width - view.switchButton.frame.width) < 1.0)
        #expect(view.allButtonList.contains { $0 === languageButton })
    }

    @Test("전용 숫자 화면은 Language 버튼을 만들지 않음")
    func testDedicatedNumericDoesNotCreateLanguageButton() {
        let view = NumericKeyboardView(showsLanguageSwitchButton: false)

        #expect(view.languageSwitchButton == nil)
    }

    @Test("한/영 글자 크기는 기본값을 넘지 않고 좁은 버튼에서 줄어듦")
    func testLanguageSwitchLabelFontShrinksOnNarrowKey() {
        let maximum: CGFloat = 14.0

        // 일반 폭(390pt / 10열 = 39pt)에서는 기본 크기를 유지
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 39, maximum: maximum) == maximum)
        // 한 손 키보드 최소 폭(300pt / 10열 = 30pt)에서는 줄어듦
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum) < maximum)
        // 좁을수록 더 작아짐
        #expect(
            LanguageSwitchButton.labelFontSize(forKeyWidth: 24, maximum: maximum)
            < LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum)
        )
        // 레이아웃 전 폭이 0이어도 기본 크기로 떨어짐
        #expect(LanguageSwitchButton.labelFontSize(forKeyWidth: 0, maximum: maximum) == maximum)
    }

    @Test("구분선 두께는 글자 크기에 비례")
    func testDividerLineWidthScalesWithFontSize() {
        let maximum: CGFloat = 14.0
        let wideFont = LanguageSwitchButton.labelFontSize(forKeyWidth: 39, maximum: maximum)
        let narrowFont = LanguageSwitchButton.labelFontSize(forKeyWidth: 30, maximum: maximum)

        // 기본 글자 크기에서 기존 두께 1.5를 유지
        #expect(abs(LanguageSwitchButton.dividerLineWidth(forFontSize: maximum) - 1.5) < 0.01)
        // 글자가 줄면 구분선도 함께 얇아짐
        #expect(
            LanguageSwitchButton.dividerLineWidth(forFontSize: narrowFont)
            < LanguageSwitchButton.dividerLineWidth(forFontSize: wideFont)
        )
        // 글자 크기와의 비율은 폭과 무관하게 일정
        #expect(
            abs(LanguageSwitchButton.dividerLineWidth(forFontSize: narrowFont) / narrowFont
                - LanguageSwitchButton.dividerLineWidth(forFontSize: wideFont) / wideFont) < 0.001
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
        // 4열 레이아웃이어도 두벌식 한/영 버튼과 같은 너비를 유지한다
        #expect(
            abs(languageButton.frame.width
                - view.frame.width * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 남는 너비는 globe와 전환 버튼이 나눠 갖는다.
        // 홀수 폭을 둘로 나누면 픽셀 정렬로 한 칸(최대 1pt) 차이가 날 수 있다
        #expect(
            abs(primaryView.nextKeyboardButton.frame.width
                - primaryView.switchButton.frame.width) < 1.0
        )
    }

    @Test(arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testDedicatedFourByFourDoesNotCreateLanguageButton(_ fixture: FourByFourFixture) {
        let primaryView = fixture.makeView(showsLanguageSwitchButton: false)

        #expect(primaryView.languageSwitchButton == nil)
    }
}
