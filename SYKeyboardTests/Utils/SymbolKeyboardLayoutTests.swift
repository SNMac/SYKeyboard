//
//  SymbolKeyboardLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/20/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("기호 자판 배열과 정렬")
struct SymbolKeyboardLayoutTests {

    /// 세로 기본 높이(240)에서 프레임 여백 4를 뺀 키 영역
    private func makeView(mode: SymbolKeyboardMode) -> SymbolKeyboardView {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false)
        view.currentSymbolKeyboardMode = mode
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 236)
        view.layoutIfNeeded()

        return view
    }

    /// 숫자 행을 켠 기호 자판. 첫 줄에 빈 키가 섞이는 배열(URL·이메일)에서 폭 기준을
    /// 검증하기 위해 언어 전환 버튼 표시 여부를 선택할 수 있게 한다
    private func makeNumberRowView(mode: SymbolKeyboardMode, showsLanguageSwitchButton: Bool) -> SymbolKeyboardView {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: showsLanguageSwitchButton, showsNumberRow: true)
        view.currentSymbolKeyboardMode = mode
        view.updateNumberRowHeight(KeyboardHeightPolicy.portraitNumberRowHeight)
        // keyboardHStackView(240 + 46.5)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        return view
    }

    /// 셋째 줄에서 보이는 키들의 좌우 여백. 버튼 프레임이 아니라 실제로 그려지는
    /// `backgroundView` 기준이어야 한다. 프레임은 스택이 항상 꽉 채우므로 늘 0이 나온다
    private func thirdRowSideMargins(_ view: SymbolKeyboardView) -> (left: CGFloat, right: CGFloat)? {
        let visibleButtons = view.thirdRowPrimaryKeyButtonList.filter { !$0.isHidden }
        guard let firstButton = visibleButtons.first,
              let lastButton = visibleButtons.last else { return nil }

        func visualFrame(_ button: BaseKeyboardButton) -> CGRect {
            button.backgroundView.convert(button.backgroundView.bounds, to: view)
        }

        return (visualFrame(firstButton).minX - visualFrame(view.shiftButton).maxX,
                visualFrame(view.deleteButton).minX - visualFrame(lastButton).maxX)
    }

    @Test("셋째 줄이 다 찬 기본 자판은 좌우 여백이 같다")
    func test셋째줄_기본자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .default)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }

    @Test("셋째 줄에 빈 키가 있는 URL 자판도 좌우 여백이 같다")
    func test셋째줄_URL자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .URL)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }

    @Test("셋째 줄에 빈 키가 있는 이메일 자판도 좌우 여백이 같다")
    func test셋째줄_이메일자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .emailAddress)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }

    @Test("숫자 행이 꺼지면 기본 자판 배열은 그대로다")
    func test기본자판_숫자행꺼짐() {
        let keyList = SymbolKeyboardMode.keyList(usesNumberRow: false)

        #expect(keyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(keyList[0][1].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[1][0].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
    }

    @Test("숫자 행이 켜지면 기본 자판 첫 줄이 기존 둘째 줄로 올라오고 도형 줄이 생김")
    func test기본자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[0][1].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
        #expect(keyList[0][2].map(\.first) == [".", ",", "?", "!", "’"])
        #expect(keyList[1][0].map(\.first) == ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•"])
        #expect(keyList[1][1].map(\.first) == ["※", "☆", "★", "○", "●", "□", "■", "△", "▲", "♡"])
        #expect(keyList[1][2].map(\.first) == [".", ",", "?", "!", "’"])
    }

    @Test("네 모드가 같은 배열을 돌려준다")
    func test네모드_같은배열() {
        let modes: [SymbolKeyboardMode] = [.default, .webSearch, .URL, .emailAddress]
        for usesNumberRow in [true, false] {
            let expectedFirstRow = SymbolKeyboardMode.keyList(usesNumberRow: usesNumberRow)[0][0]
            let expectedThirdRow = SymbolKeyboardMode.keyList(usesNumberRow: usesNumberRow)[0][2]

            for mode in modes {
                let view = usesNumberRow
                    ? makeNumberRowView(mode: mode, showsLanguageSwitchButton: false)
                    : makeView(mode: mode)

                #expect(view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList) == expectedFirstRow)
                #expect(view.thirdRowPrimaryKeyButtonList.map(\.type.primaryKeyList) == expectedThirdRow)
            }
        }
    }

    @Test("2페이지 첫 줄에 전용 주소 기호가 없다")
    func test2페이지_주소전용기호없음() {
        let removedCharacters: Set<String> = ["€", "±", "°", "×"]
        let onCharacters = Set(SymbolKeyboardMode.keyList(usesNumberRow: true).flatMap { $0.flatMap { $0.flatMap { $0 } } })
        let offCharacters = Set(SymbolKeyboardMode.keyList(usesNumberRow: false).flatMap { $0.flatMap { $0.flatMap { $0 } } })

        #expect(onCharacters.isDisjoint(with: removedCharacters))
        #expect(offCharacters.isDisjoint(with: removedCharacters))
    }

    @Test("모든 배열이 행별 10·10·5개를 지킨다")
    func test모든배열_행별키개수() {
        for usesNumberRow in [true, false] {
            let keyList = SymbolKeyboardMode.keyList(usesNumberRow: usesNumberRow)
            for layer in keyList {
                #expect(layer.map(\.count) == [10, 10, 5])
            }
        }
    }

    @Test("숫자 행을 켜면 숫자 키가 생기고 기본 자판 배열이 바뀐다")
    func test기호자판_숫자행표시() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.portraitNumberRowHeight)
        // keyboardHStackView(240 + 46.5)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        #expect(view.showsNumberRow)
        #expect(view.numberRowPrimaryKeyButtonList.map(\.type.primaryKeyList)
                == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map { [$0] })
        #expect(view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])

        let numberButton = try #require(view.numberRowPrimaryKeyButtonList.first)
        #expect(abs(numberButton.frame.height - 46.5) < 0.5)
    }

    @Test("가로 높이를 주면 숫자 행만 35로 줄고 배열은 그대로다")
    func test기호자판_가로높이() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
        // 가로 keyboardHStackView(188 - 44 + 35)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
        view.layoutIfNeeded()

        let numberButton = try #require(view.numberRowPrimaryKeyButtonList.first)
        #expect(abs(numberButton.frame.height - 35) < 0.5)
        #expect(view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
    }

    @Test("숫자 행이 켜진 URL·이메일 자판에서도 페이지 전환 버튼을 숨기지 않는다")
    func test합친자판_shift유지() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)

        view.currentSymbolKeyboardMode = .URL
        #expect(view.shiftButton.isHidden == false)

        view.currentSymbolKeyboardMode = .default
        #expect(view.shiftButton.isHidden == false)

        view.currentSymbolKeyboardMode = .emailAddress
        #expect(view.shiftButton.isHidden == false)

        // 숫자 행이 꺼지면 합치지 않으므로 두 페이지가 그대로 살아 있다
        let withoutNumberRow = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: false)
        withoutNumberRow.currentSymbolKeyboardMode = .URL
        #expect(withoutNumberRow.shiftButton.isHidden == false)
    }

    @Test("주 자판에 숫자 행이 없으면 기호 자판에도 숫자 행이 없다")
    func test기호자판_주자판을따라감() {
        let withoutNumberRow = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: false)
        withoutNumberRow.updateNumberRowHeight(KeyboardHeightPolicy.portraitNumberRowHeight)

        #expect(withoutNumberRow.showsNumberRow == false)
        #expect(withoutNumberRow.numberRowPrimaryKeyButtonList.isEmpty)
        #expect(withoutNumberRow.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
    }

    @Test("숫자 행이 켜지면 숫자 키가 totalTextInterableButtonList와 primaryButtonList에 배선된다")
    func test기호자판_숫자행켜짐_버튼배선() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        let expectedNumberKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map { [$0] }

        let interactableLeadingKeys = view.totalTextInterableButtonList.prefix(10)
            .compactMap { $0 as? PrimaryKeyButton }
            .map(\.type.primaryKeyList)
        #expect(interactableLeadingKeys == expectedNumberKeys)

        let primaryLeadingKeys = view.primaryButtonList.prefix(10)
            .compactMap { $0 as? PrimaryKeyButton }
            .map(\.type.primaryKeyList)
        #expect(primaryLeadingKeys == expectedNumberKeys)
    }

    @Test("숫자 행이 꺼지면 배선 목록 앞부분은 첫째 줄 그대로다")
    func test기호자판_숫자행꺼짐_버튼배선_첫째줄유지() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: false)
        #expect(view.numberRowPrimaryKeyButtonList.isEmpty)

        let expectedFirstRowKeys = view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList)
        let interactableLeadingKeys = view.totalTextInterableButtonList.prefix(view.firstRowPrimaryKeyButtonList.count)
            .compactMap { $0 as? PrimaryKeyButton }
            .map(\.type.primaryKeyList)
        #expect(interactableLeadingKeys == expectedFirstRowKeys)
    }

    @Test("첫 줄에 빈 키가 섞여도 삭제 버튼 폭은 10칸 기준으로 유지된다")
    func test삭제버튼폭_첫줄빈키영향없음() {
        // 기본 자판은 첫 줄이 10칸 다 차 있고, URL 자판은 8칸만 차 있다(2칸은 빈 키)
        let defaultView = makeNumberRowView(mode: .default, showsLanguageSwitchButton: false)
        let urlView = makeNumberRowView(mode: .URL, showsLanguageSwitchButton: false)

        let expectedWidth = 375.0 * KeyboardLayoutFigure.shiftAndDeleteButtonWidthMultiplier / 10.0

        #expect(abs(defaultView.deleteButton.frame.width - urlView.deleteButton.frame.width) < 0.5)
        #expect(abs(defaultView.deleteButton.frame.width - expectedWidth) < 0.5)
        #expect(abs(urlView.deleteButton.frame.width - expectedWidth) < 0.5)
    }

    @Test("첫 줄에 빈 키가 섞여도 넷째 줄 왼쪽 버튼 묶음 폭은 10칸 기준으로 유지된다")
    func test넷째줄왼쪽버튼묶음폭_첫줄빈키영향없음() {
        let defaultView = makeNumberRowView(mode: .default, showsLanguageSwitchButton: true)
        let urlView = makeNumberRowView(mode: .URL, showsLanguageSwitchButton: true)

        #expect(abs(defaultView.fourthRowLeftSecondaryButtonHStackView.frame.width
                    - urlView.fourthRowLeftSecondaryButtonHStackView.frame.width) < 0.5)
    }
}
