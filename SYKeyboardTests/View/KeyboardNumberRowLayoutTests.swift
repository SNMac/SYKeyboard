//
//  KeyboardNumberRowLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/18/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@MainActor
@Suite("주 자판 숫자 행 레이아웃과 보조 키")
struct KeyboardNumberRowLayoutTests {

    /// 기본 높이 설정(240)에서의 세로 숫자 행 높이(52.75). 실제 키보드처럼 정책 값으로 갱신한다
    private static let defaultPortraitNumberRowHeight = KeyboardHeightPolicy.numberRowHeight(
        isEnabled: true,
        isPortrait: true,
        keyboardSettingsHeight: DefaultValues.keyboardHeight
    )

    private static let numberKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    private func makeDubeolsik(showsNumberRow: Bool) -> DubeolsikKeyboardView {
        DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: showsNumberRow
        )
    }

    private func makeQwerty(showsNumberRow: Bool) -> EnglishKeyboardView {
        EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: showsNumberRow
        )
    }

    private func makeNaratgeul(showsNumberRow: Bool) -> NaratgeulKeyboardView {
        NaratgeulKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: showsNumberRow)
    }

    private func makeCheonjiin(showsNumberRow: Bool) -> CheonjiinKeyboardView {
        CheonjiinKeyboardView(
            showsLanguageSwitchButton: false,
            usesBottomSpaceLayout: false,
            showsNumberRow: showsNumberRow
        )
    }

    @Test("숫자 행이 켜지면 1~0 키가 입력 버튼 목록 맨 앞에 들어감")
    func test숫자행_버튼목록() {
        let view = makeDubeolsik(showsNumberRow: true)

        let numberButtons = view.totalTextInterableButtonList.prefix(10)
        #expect(numberButtons.map(\.type.primaryKeyList) == Self.numberKeys.map { [$0] })
        #expect(numberButtons.allSatisfy { $0.type.secondaryKey == nil })
        #expect(view.showsNumberRow)
    }

    @Test("숫자 행이 꺼지면 숫자 키가 없고 첫 줄 보조 키는 기존 숫자")
    func test숫자행꺼짐_기존보조키유지() {
        let view = makeQwerty(showsNumberRow: false)

        #expect(view.totalTextInterableButtonList.first?.type.primaryKeyList == ["q"])
        #expect(view.totalTextInterableButtonList.first?.type.secondaryKey == "1")
        #expect(view.showsNumberRow == false)
    }

    @Test("세로 기본 높이 설정(240)에서 숫자 행은 52.75, 글자 행은 59")
    func test숫자행_세로높이() throws {
        let view = makeDubeolsik(showsNumberRow: true)
        view.updateNumberRowHeight(Self.defaultPortraitNumberRowHeight)
        // keyboardHStackView(240 + 52.75)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 288.75)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 52.75) < 0.5)
        #expect(abs(letterButton.frame.height - 59) < 0.5)
        #expect(abs(letterButton.convert(letterButton.bounds, to: view).minY - 52.75) < 0.5)
    }

    @Test("가로 숫자 행 높이로 갱신하면 숫자 행은 35")
    func test숫자행_가로높이갱신() throws {
        let view = makeQwerty(showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
        // 가로 keyboardHStackView(188 - 44 + 35)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 35) < 0.5)
        #expect(abs(letterButton.frame.height - 35) < 0.5)
    }

    @Test("숫자 행이 켜진 쿼티는 길게 누르기 보조 키가 대문자, shift 중에는 소문자")
    func test쿼티_보조키교체() {
        let view = makeQwerty(showsNumberRow: true)
        let qButton = view.totalTextInterableButtonList[10]
        let aButton = view.totalTextInterableButtonList[20]

        #expect(qButton.type.primaryKeyList == ["q"])
        #expect(qButton.type.secondaryKey == "Q")
        #expect(aButton.type.secondaryKey == "A")

        view.isShifted = true
        #expect(qButton.type.primaryKeyList == ["Q"])
        #expect(qButton.type.secondaryKey == "q")
    }

    @Test("숫자 행이 켜진 두벌식은 쌍자음·ㅒㅖ 자리만 보조 키가 생김")
    func test두벌식_보조키교체() {
        let view = makeDubeolsik(showsNumberRow: true)
        let firstRow = view.totalTextInterableButtonList[10..<20]
        let mButton = view.totalTextInterableButtonList[20]

        #expect(firstRow.map(\.type.secondaryKey) == ["ㅃ", "ㅉ", "ㄸ", "ㄲ", "ㅆ", nil, nil, nil, "ㅒ", "ㅖ"])
        #expect(mButton.type.primaryKeyList == ["ㅁ"])
        #expect(mButton.type.secondaryKey == nil)

        view.isShifted = true
        #expect(firstRow.map(\.type.secondaryKey) == ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ", nil, nil, nil, "ㅐ", "ㅔ"])
    }

    // MARK: - 나랏글·천지인

    @Test("숫자 행이 켜진 나랏글은 1~0 키가 맨 앞에 들어가고 글자 키 보조 키는 숫자 그대로")
    func test나랏글_숫자행_버튼목록() {
        let view = makeNaratgeul(showsNumberRow: true)

        let numberButtons = view.totalTextInterableButtonList.prefix(10)
        #expect(numberButtons.map(\.type.primaryKeyList) == Self.numberKeys.map { [$0] })
        #expect(numberButtons.allSatisfy { $0.type.secondaryKey == nil })
        #expect(view.showsNumberRow)

        let letterButtons = view.totalTextInterableButtonList[10..<13]
        #expect(letterButtons.map(\.type.primaryKeyList) == [["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"]])
        #expect(letterButtons.map(\.type.secondaryKey) == ["1", "2", "3"])
    }

    @Test("숫자 행이 켜진 천지인은 1~0 키가 맨 앞에 들어가고 글자 키 보조 키는 숫자 그대로")
    func test천지인_숫자행_버튼목록() {
        let view = makeCheonjiin(showsNumberRow: true)

        let numberButtons = view.totalTextInterableButtonList.prefix(10)
        #expect(numberButtons.map(\.type.primaryKeyList) == Self.numberKeys.map { [$0] })
        #expect(numberButtons.allSatisfy { $0.type.secondaryKey == nil })
        #expect(view.showsNumberRow)

        let letterButtons = view.totalTextInterableButtonList[10..<13]
        #expect(letterButtons.map(\.type.primaryKeyList) == [["ㅣ"], ["ㆍ"], ["ㅡ"]])
        #expect(letterButtons.map(\.type.secondaryKey) == ["1", "2", "3"])
    }

    @Test("숫자 행이 꺼진 나랏글·천지인은 숫자 키가 없다")
    func test4x4_숫자행꺼짐() {
        let naratgeul = makeNaratgeul(showsNumberRow: false)
        let cheonjiin = makeCheonjiin(showsNumberRow: false)

        #expect(naratgeul.showsNumberRow == false)
        #expect(naratgeul.totalTextInterableButtonList.first?.type.primaryKeyList == ["ㄱ"])
        #expect(cheonjiin.showsNumberRow == false)
        #expect(cheonjiin.totalTextInterableButtonList.first?.type.primaryKeyList == ["ㅣ"])
    }

    @Test("나랏글 세로 기본 높이 설정(240)에서 숫자 행은 52.75로 전체 너비를 10칸으로 나누고, 글자 행은 59")
    func test나랏글_숫자행_세로높이() throws {
        let view = makeNaratgeul(showsNumberRow: true)
        view.updateNumberRowHeight(Self.defaultPortraitNumberRowHeight)
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 288.75)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 52.75) < 0.5)
        #expect(abs(numberButton.frame.width - 37.5) < 0.5)
        #expect(abs(letterButton.frame.height - 59) < 0.5)
        #expect(abs(letterButton.convert(letterButton.bounds, to: view).minY - 52.75) < 0.5)
    }

    @Test("나랏글·천지인도 프로토콜 타입으로 가로 숫자 행 높이를 갱신하면 숫자 행은 35")
    func test4x4_프로토콜로_숫자행_가로높이갱신() throws {
        // controller는 프로토콜 타입으로 호출하므로 기본 no-op 구현이 witness로 잡히면 실패해야 한다
        let views: [PrimaryKeyboardRepresentable] = [
            makeNaratgeul(showsNumberRow: true),
            makeCheonjiin(showsNumberRow: true)
        ]

        for view in views {
            #expect(view.showsNumberRow)
            view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
            view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
            view.layoutIfNeeded()

            let numberButton = try #require(view.totalTextInterableButtonList.first)
            let letterButton = view.totalTextInterableButtonList[10]
            #expect(abs(numberButton.frame.height - 35) < 0.5)
            #expect(abs(letterButton.frame.height - 35) < 0.5)
        }
    }

    @Test("나랏글·천지인 숫자 키는 기호 자판 숫자 키와 보이는 크기가 같다")
    func test4x4_숫자키크기_기호자판과같음() throws {
        let numberRowHeight = Self.defaultPortraitNumberRowHeight
        let frame = CGRect(x: 0, y: 0, width: 375, height: 288.75)
        let symbol = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        symbol.updateNumberRowHeight(numberRowHeight)
        symbol.frame = frame
        symbol.layoutIfNeeded()
        let symbolKey = try #require(symbol.numberRowPrimaryKeyButtonList.first).backgroundView.bounds.size

        let views: [PrimaryKeyboardRepresentable] = [
            makeNaratgeul(showsNumberRow: true),
            makeCheonjiin(showsNumberRow: true)
        ]
        for view in views {
            view.updateNumberRowHeight(numberRowHeight)
            view.frame = frame
            view.layoutIfNeeded()
            let numberButton = try #require(view.totalTextInterableButtonList.first as? PrimaryKeyButton)
            let key = numberButton.backgroundView.bounds.size

            // 숫자 행 52.75에서 위아래 여백 4를 뺀 높이
            #expect(abs(key.height - 44.75) < 0.5)
            #expect(abs(key.height - symbolKey.height) < 0.5)
            #expect(abs(key.width - symbolKey.width) < 0.5)
        }
    }

    @Test("글자 열 너비 배율은 4열 글자 키에만 적용되고 숫자 행은 10칸 균등 분할을 유지한다")
    func test4x4_글자열너비배율_숫자행미적용() throws {
        let frame = CGRect(x: 0, y: 0, width: 390, height: 282.5)
        let views: [PrimaryKeyboardRepresentable] = [
            makeNaratgeul(showsNumberRow: true),
            makeCheonjiin(showsNumberRow: true)
        ]
        for view in views {
            view.frame = frame
            view.updateLetterColumnWidthMultiplier(1.15)
            view.layoutIfNeeded()

            let numberButton = try #require(view.totalTextInterableButtonList.first)
            let letterButton = view.totalTextInterableButtonList[10]
            #expect(abs(numberButton.frame.width - 39) < 0.5)
            #expect(abs(letterButton.frame.width - 390 * 0.2875) < 1.0)
        }
    }
}
