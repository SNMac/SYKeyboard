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

    @Test("세로 기본 높이에서 숫자 행은 46.5, 글자 행은 59")
    func test숫자행_세로높이() throws {
        let view = makeDubeolsik(showsNumberRow: true)
        // keyboardHStackView(240 + 46.5)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 46.5) < 0.5)
        #expect(abs(letterButton.frame.height - 59) < 0.5)
        #expect(abs(letterButton.convert(letterButton.bounds, to: view).minY - 46.5) < 0.5)
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

    @Test("나랏글 세로 기본 높이에서 숫자 행은 46.5로 전체 너비를 10칸으로 나누고, 글자 행은 59")
    func test나랏글_숫자행_세로높이() throws {
        let view = makeNaratgeul(showsNumberRow: true)
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 46.5) < 0.5)
        #expect(abs(numberButton.frame.width - 37.5) < 0.5)
        #expect(abs(letterButton.frame.height - 59) < 0.5)
        #expect(abs(letterButton.convert(letterButton.bounds, to: view).minY - 46.5) < 0.5)
    }

    @Test("천지인 가로 숫자 행 높이로 갱신하면 숫자 행은 35")
    func test천지인_숫자행_가로높이갱신() throws {
        let view = makeCheonjiin(showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
        view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first)
        let letterButton = view.totalTextInterableButtonList[10]
        #expect(abs(numberButton.frame.height - 35) < 0.5)
        #expect(abs(letterButton.frame.height - 35) < 0.5)
    }
}
