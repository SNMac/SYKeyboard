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
            // 기본 인자가 영속 설정값(App Group UserDefaults)을 읽으므로
            // 기존 배치를 검증하는 이 fixture는 값을 명시해 시뮬레이터 상태와 무관하게 만든다
            CheonjiinKeyboardView(showsLanguageSwitchButton: showsLanguageSwitchButton, usesBottomSpaceLayout: false)
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
        // 기본 인자가 영속 설정값(App Group UserDefaults)을 읽으므로
        // 기존 배치를 검증하는 이 테스트는 값을 명시해 시뮬레이터 상태와 무관하게 만든다
        let view = NumericKeyboardView(showsLanguageSwitchButton: true, usesBottomSpaceLayout: false)
        view.frame = CGRect(x: 0, y: 0, width: width, height: 216)
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        #expect(view.nextKeyboardButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.switchButton.frame.minX + 0.5)
        // modifier 영역 폭이 고정이므로 globe가 보이면 세 버튼이 균등하게 나눠 갖는다.
        // 폭을 셋으로 나누면 픽셀 정렬로 한 칸(최대 1pt) 차이가 날 수 있다
        #expect(abs(view.nextKeyboardButton.frame.width - languageButton.frame.width) < 1.0)
        #expect(abs(languageButton.frame.width - view.switchButton.frame.width) < 1.0)
        #expect(view.allButtonList.contains { $0 === languageButton })
    }

    @Test("숨겨진 globe 상태의 숫자 화면은 modifier 두 버튼이 균등 분배")
    func testUnifiedNumericHiddenGlobeSplitsModifierStackEqually() throws {
        let width: CGFloat = 390
        // 기본 인자가 영속 설정값(App Group UserDefaults)을 읽으므로
        // 기존 배치를 검증하는 이 테스트는 값을 명시해 시뮬레이터 상태와 무관하게 만든다
        let view = NumericKeyboardView(showsLanguageSwitchButton: true, usesBottomSpaceLayout: false)
        view.frame = CGRect(x: 0, y: 0, width: width, height: 216)
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let modifierStack = try #require(languageButton.superview)
        // 지구본이 숨겨져 한/영과 전환 버튼 2개만 남는다
        let visibleButtonCount: CGFloat = 2
        // 열 자체가 무너져도 두 버튼이 반씩 나눠 가지면 상대 단언은 통과한다.
        // 배율 1.0에서 modifier 열은 키보드 폭의 1/4이므로 절대값을 함께 고정한다
        let expectedButtonWidth = width / CGFloat(4) / visibleButtonCount

        #expect(view.nextKeyboardButton.isHidden)
        #expect(abs(modifierStack.frame.width - width / 4) < 0.5)
        #expect(abs(languageButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(abs(view.switchButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(
            abs(languageButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
        #expect(
            abs(view.switchButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
    }

    @Test("전용 숫자 화면은 Language 버튼을 만들지 않음")
    func testDedicatedNumericDoesNotCreateLanguageButton() {
        // 기본 인자가 영속 설정값(App Group UserDefaults)을 읽으므로
        // 기존 배치를 검증하는 이 테스트는 값을 명시해 시뮬레이터 상태와 무관하게 만든다
        let view = NumericKeyboardView(showsLanguageSwitchButton: false, usesBottomSpaceLayout: false)

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
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        let languageButton = try #require(primaryView.languageSwitchButton)
        #expect(primaryView.nextKeyboardButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= primaryView.switchButton.frame.minX + 0.5)
        // modifier 영역 폭이 고정이므로 globe가 보이면 세 버튼이 균등하게 나눠 갖는다.
        // 폭을 셋으로 나누면 픽셀 정렬로 한 칸(최대 1pt) 차이가 날 수 있다
        #expect(
            abs(primaryView.nextKeyboardButton.frame.width - languageButton.frame.width) < 1.0
        )
        #expect(
            abs(languageButton.frame.width - primaryView.switchButton.frame.width) < 1.0
        )
    }

    @Test(arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testFourByFourHiddenGlobeSplitsModifierStackEqually(_ fixture: FourByFourFixture) throws {
        let width: CGFloat = 390
        let primaryView = fixture.makeView(showsLanguageSwitchButton: true)
        let view = primaryView
        view.frame = CGRect(x: 0, y: 0, width: width, height: 216)
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        let languageButton = try #require(primaryView.languageSwitchButton)
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let modifierStack = try #require(languageButton.superview)
        // globe가 빠지면 한/영과 전환 버튼 2개가 modifier 스택을 균등하게 나눈다
        let visibleButtonCount: CGFloat = 2
        // 배율 1.0에서 modifier 열은 키보드 폭의 1/4이다. 열 붕괴를 잡으려면 절대값이 필요하다
        let expectedButtonWidth = width / CGFloat(4) / visibleButtonCount

        #expect(primaryView.nextKeyboardButton.isHidden)
        #expect(abs(modifierStack.frame.width - width / 4) < 0.5)
        #expect(abs(languageButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(abs(primaryView.switchButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(
            abs(languageButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
        #expect(
            abs(primaryView.switchButton.frame.width
                - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
    }

    @Test(arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testDedicatedFourByFourDoesNotCreateLanguageButton(_ fixture: FourByFourFixture) {
        let primaryView = fixture.makeView(showsLanguageSwitchButton: false)

        #expect(primaryView.languageSwitchButton == nil)
    }

    @Test("globe 표시를 전환해도 modifier 스택은 보이는 버튼끼리 균등 분배",
          arguments: [FourByFourFixture.naratgeul, .cheonjiin])
    func testFourByFourGlobeToggleKeepsDistributionConsistent(_ fixture: FourByFourFixture) throws {
        let primaryView = fixture.makeView(showsLanguageSwitchButton: true)
        let view = primaryView
        view.frame = CGRect(x: 0, y: 0, width: 420, height: 216)
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        let languageButton = try #require(primaryView.languageSwitchButton)
        let modifierStack = try #require(languageButton.superview)
        let action = NSSelectorFromString("unusedNextKeyboardAction:")

        for visible in [false, true, false, true] {
            primaryView.updateNextKeyboardButton(needsInputModeSwitchKey: visible,
                                                 nextKeyboardAction: action)
            view.layoutIfNeeded()

            // 지구본이 보이면 세 버튼, 숨겨지면 두 버튼이 스택을 나눠 갖는다.
            // 폭을 셋으로 나누면 픽셀 정렬로 한 칸(최대 1pt) 차이가 날 수 있다
            let visibleButtonCount: CGFloat = visible ? 3 : 2
            let expected = modifierStack.frame.width / visibleButtonCount

            #expect(abs(languageButton.frame.width - expected) < 1.0)
            #expect(abs(primaryView.switchButton.frame.width - expected) < 1.0)
        }
    }
}

@MainActor
@Suite("전환 버튼 라벨 크기")
struct SwitchButtonLabelFontSizeTests {
    private static let fullSize: CGFloat = 8.0

    @Test("세로 모드 키 크기에서는 기본 크기를 유지한다")
    func testPortraitKeepsFullSize() {
        // 임계값(40) 이상이면 어떤 크기든 상한을 유지하는지 보는 순수 함수 검증값이다.
        // 실제 세로 배경 높이는 4x4 56pt, 쿼티 52pt다 (testPortraitBackgroundHeightsKeepFullSize 참고)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 44) - Self.fullSize) < 0.01)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 33.0, keyHeight: 40) - Self.fullSize) < 0.01)
    }

    @Test("실제 세로 모드 배경 크기에서도 기본 크기를 유지한다")
    func testPortraitBackgroundHeightsKeepFullSize() {
        // 기본 keyboardHeight(240)에서 세로 모드 행 높이는 60pt.
        // 세로 4x4 배경: 60 - insetDy 2 * 2 = 56, 세로 쿼티 배경: 60 - insetDy 4 * 2 = 52
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 42.75, keyHeight: 56) - Self.fullSize) < 0.01)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 33, keyHeight: 52) - Self.fullSize) < 0.01)
    }

    @Test("가로 모드 낮은 키에서는 높이에 비례해 줄인다")
    func testLandscapeShrinksWithHeight() {
        // 순수 함수 임계값 검증값이다. 실제 가로 모드 배경 높이는 행 높이 36pt 기준으로
        // 4x4 36 - 2 * 2 = 32, 쿼티 36 - 4 * 2 = 28에 더 가깝다
        let fourByFour = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 31)
        let qwerty = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 27)

        #expect(abs(fourByFour - Self.fullSize * 31 / 40) < 0.01)
        #expect(abs(qwerty - Self.fullSize * 27 / 40) < 0.01)
        #expect(qwerty < fourByFour)
        #expect(fourByFour < Self.fullSize)
    }

    @Test("좁은 키에서는 너비 기준 축소가 그대로 유지된다")
    func testNarrowKeyStillShrinksByWidth() {
        // 한 손 키보드처럼 좁은 키는 높이가 넉넉해도 너비 때문에 줄어야 한다
        let narrow = SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 44)

        #expect(abs(narrow - Self.fullSize * 20 / 25) < 0.01)
        #expect(narrow < Self.fullSize)
    }

    @Test("너비와 높이 중 좁은 쪽이 결과를 결정한다")
    func testUsesSmallerOfWidthAndHeightRule() {
        // 너비 20 -> 6.4, 높이 27 -> 5.4. 더 작은 5.4가 나와야 한다
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 27) - Self.fullSize * 27 / 40) < 0.01)
    }

    @Test("크기가 0이면 기본 크기로 되돌린다")
    func testNonPositiveSizeFallsBackToFullSize() {
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 0, keyHeight: 44) == Self.fullSize)
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 0) == Self.fullSize)
    }

    @Test("세로 모드 높이에서는 너비 사다리를 그대로 유지한다")
    func testPrimaryLabelKeepsWidthLadderInPortrait() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 49.6, keyHeight: 56) == 16)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 40, keyHeight: 56) == 14)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 36, keyHeight: 56) == 12)
    }

    @Test("슬라이더 최소값의 세로 모드 높이(39.5)는 줄지 않는다")
    func testPrimaryLabelNotReducedAtSliderMinimumPortraitHeight() {
        // 39.5는 keyboardHeight 슬라이더 최하단(190), 쿼티 계열, insetDy 4에서 나오는
        // 가장 작은 세로 모드 배경 높이다
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 39.5) == 16)
    }

    @Test("가로 모드 높이에서는 한 단계 낮춘 크기를 쓴다")
    func testPrimaryLabelDropsOneRungInLandscape() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 49.6, keyHeight: 32) == 14)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 40, keyHeight: 32) == 12)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 36, keyHeight: 32) == 10)
    }

    @Test("임계값 36은 포함되지 않고, 그 아래인 35.9는 낮춘다")
    func testPrimaryLabelThresholdIsExclusive() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 36) == 16)
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 35.9) == 14)
    }

    @Test("높이가 0 이하면 사다리 크기로 되돌린다")
    func testPrimaryLabelFallsBackToLadderForNonPositiveHeight() {
        #expect(SwitchButton.primaryLabelFontSize(forKeyWidth: 44, keyHeight: 0) == 16)
    }
}

@MainActor
@Suite("한영 전환 버튼 구분선 기울기")
struct LanguageSwitchButtonDividerTests {
    /// `dividerHalfExtents`가 만드는 사선의 각도(도)
    private static func angleInDegrees(forKeySize size: CGSize) -> CGFloat {
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)
        return atan2(extents.height, extents.width) * 180 / .pi
    }

    @Test("세로 모드 배경 크기에서는 비율 그대로 나온다")
    func testPortraitExtentsMatchRatiosExactly() {
        // 기본 keyboardHeight(240)에서 세로 모드 행 높이는 60pt.
        // 세로 modifier 배경은 globe 숨김 42.75×56, globe 표시 26.5×56이며
        // 원래 각도(50.0°, 62.5°)가 이미 45° 이상이라 비율 그대로 나와야 한다(회귀 가드)
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56)] {
            let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

            #expect(abs(extents.width - size.width * 0.22) < 0.001)
            #expect(abs(extents.height - size.height * 0.20) < 0.001)
        }
    }

    @Test("각도는 45도 아래로 내려가지 않는다")
    func testAngleNeverGoesBelow45Degrees() {
        // 세로 modifier 배경(42.75×56, 26.5×56), 가로 modifier 배경(행 높이 36pt에서
        // 42.75×32, 26.5×32), 그리고 극단적으로 좁거나 넓은 키(20×60, 200×27)까지
        // 포함해 45° 바닥이 지켜지는지 확인한다
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56),
                     CGSize(width: 42.75, height: 32), CGSize(width: 26.5, height: 32),
                     CGSize(width: 20, height: 60), CGSize(width: 200, height: 27),
                     CGSize(width: 49.6, height: 32)] {
            #expect(Self.angleInDegrees(forKeySize: size) >= 45 - 0.01)
        }
    }

    @Test("가로 모드처럼 낮고 넓은 키는 45도로 잘리되, 너비·높이 예산 중 더 작은 쪽에 맞춘다")
    func testWideShortKeyIsClampedTo45Degrees() {
        // 가로 모드 globe 숨김 배경(42.75×32)은 원래 각도가 34.2°라 45°보다 누우므로 잘린다.
        // 세로 예산에 1.5배(다음 테스트의 dividerClampedHeightBoost)를 줘도 너비 예산(42.75 * 0.22)이
        // 더 작아 너비가 상한이 된다
        let widthBound = CGSize(width: 42.75, height: 32)
        let widthBoundExtents = LanguageSwitchButton.dividerHalfExtents(forKeySize: widthBound)

        #expect(abs(widthBoundExtents.width - 42.75 * 0.22) < 0.01)
        #expect(abs(widthBoundExtents.height - 42.75 * 0.22) < 0.01)

        // 실제 랜드스케이프 한/영 배경(49.6×32)은 반대로 세로 예산(32 * 0.20 * 1.5)이 더 작아
        // 세로 예산이 상한이 된다
        let heightBound = CGSize(width: 49.6, height: 32)
        let heightBoundExtents = LanguageSwitchButton.dividerHalfExtents(forKeySize: heightBound)

        #expect(abs(heightBoundExtents.width - 32 * 0.20 * 1.5) < 0.01)
        #expect(abs(heightBoundExtents.height - 32 * 0.20 * 1.5) < 0.01)
    }

    @Test("가로 모드 실기기 배경 크기에서는 획이 세로 예산 단순 클램프보다 길다")
    func testLandscapeStrokeIsLongerThanPlainHeightClamp() {
        // 회귀 가드: dividerClampedHeightBoost 도입 전에는 49.6×32 배경에서
        // 반길이가 32 * 0.20(=6.4)까지만 잘려 획이 세로 모드(25.0pt)보다 훨씬 짧은
        // 18.1pt로 뭉툭해 보였다. boost 적용 후에는 이 단순 클램프 값보다 커야 한다
        let size = CGSize(width: 49.6, height: 32)
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)
        let plainClamp = size.height * 0.20

        #expect(extents.height > plainClamp + 0.01)
        #expect(extents.width > plainClamp + 0.01)
    }

    @Test("이미 45도 이상인 키는 그대로 유지된다")
    func testKeyAboveThresholdIsUntouched() {
        // 가로 모드 globe 표시 배경(26.5×32)은 원래 각도가 47.7°로 이미 45° 이상이라 바뀌지 않는다
        let size = CGSize(width: 26.5, height: 32)
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

        #expect(abs(extents.width - 26.5 * 0.22) < 0.001)
        #expect(abs(extents.height - 32 * 0.20) < 0.001)
    }

    @Test("반길이는 너비·높이 비율 박스를 넘지 않고, 획은 키 안에 머문다")
    func testHalfExtentsStayInsideRatioBox() {
        for size in [CGSize(width: 42.75, height: 56), CGSize(width: 26.5, height: 56),
                     CGSize(width: 42.75, height: 32), CGSize(width: 26.5, height: 32),
                     CGSize(width: 20, height: 60), CGSize(width: 200, height: 27)] {
            let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

            #expect(extents.width <= size.width * 0.22 + 0.001)
            // 클램프 분기는 세로 예산에 dividerClampedHeightBoost(1.5)를 곱한 값까지 쓴다
            #expect(extents.height <= size.height * 0.20 * 1.5 + 0.001)
            #expect(extents.width > 0)
            #expect(extents.height > 0)
            // 확대된 획이라도 키 경계를 넘어서는 안 된다
            #expect(extents.height * 2 < size.height)
            #expect(extents.width * 2 < size.width)
        }
    }

    @Test("크기가 0이면 반길이도 0이다")
    func testZeroSizeYieldsZeroExtents() {
        #expect(LanguageSwitchButton.dividerHalfExtents(forKeySize: .zero) == .zero)
    }

    @Test("낮은 키에서도 두 글자가 버튼 안에 남는다")
    func testLabelsStayInsideShortKey() throws {
        let button = LanguageSwitchButton(mode: .hangeul)
        // 가로 모드 쿼티 키에 가까운 크기
        button.frame = CGRect(x: 0, y: 0, width: 39, height: 35)
        button.layoutIfNeeded()

        let labels = button.subviews.compactMap { $0 as? UILabel }.filter { $0.text == "한" || $0.text == "A" }
        #expect(labels.count == 2)

        for label in labels {
            #expect(label.frame.minX >= -0.5)
            #expect(label.frame.minY >= -0.5)
            #expect(label.frame.maxX <= button.bounds.width + 0.5)
            #expect(label.frame.maxY <= button.bounds.height + 0.5)
        }
    }
}
