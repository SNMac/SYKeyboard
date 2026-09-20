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
        let keyList = SymbolKeyboardMode.default.keyList(usesNumberRow: false)

        #expect(keyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(keyList[0][1].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[1][0].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
    }

    @Test("숫자 행이 켜지면 기본 자판 첫 줄이 기존 둘째 줄로 올라오고 도형 줄이 생김")
    func test기본자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.default.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[0][1].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
        #expect(keyList[0][2].map(\.first) == [".", ",", "?", "!", "’"])
        #expect(keyList[1][0].map(\.first) == ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•"])
        #expect(keyList[1][1].map(\.first) == ["※", "☆", "★", "○", "●", "□", "■", "△", "▲", "♡"])
        #expect(keyList[1][2].map(\.first) == [".", ",", "?", "!", "’"])
    }

    @Test("웹 검색 자판은 기본 자판과 같은 배열을 쓴다")
    func test웹검색자판_기본자판과동일() {
        #expect(SymbolKeyboardMode.webSearch.keyList(usesNumberRow: true)
                == SymbolKeyboardMode.default.keyList(usesNumberRow: true))
        #expect(SymbolKeyboardMode.webSearch.keyList(usesNumberRow: false)
                == SymbolKeyboardMode.default.keyList(usesNumberRow: false))
    }

    @Test("모든 배열이 행별 10·10·5개를 지킨다")
    func test모든배열_행별키개수() {
        let modes: [SymbolKeyboardMode] = [.default, .webSearch, .URL, .emailAddress]
        for mode in modes {
            for usesNumberRow in [true, false] {
                let keyList = mode.keyList(usesNumberRow: usesNumberRow)
                for layer in keyList {
                    #expect(layer.map(\.count) == [10, 10, 5])
                }
            }
        }
    }

    @Test("숫자 행이 켜지면 URL 자판이 한 페이지로 합쳐진다")
    func testURL자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.URL.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["@", "&", "%", "?", ",", "=", "[", "]", nil, nil])
        #expect(keyList[0][1].map(\.first) == ["*", "$", "#", "!", "’", "^", "~", ";", "(", ")"])
        #expect(keyList[0][2].map(\.first) == ["_", ":", "-", "+", nil])
        #expect(keyList[1] == keyList[0])
    }

    @Test("숫자 행이 켜지면 이메일 자판이 한 페이지로 합쳐진다")
    func test이메일자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.emailAddress.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["$", "!", "~", "&", "=", "#", "[", "]", nil, nil])
        #expect(keyList[0][1].map(\.first) == ["’", "|", "{", "}", "?", "%", "^", "*", "/", nil])
        #expect(keyList[0][2].map(\.first) == [".", "_", "-", "+", nil])
        #expect(keyList[1] == keyList[0])
    }

    @Test("합친 URL·이메일 자판은 기호를 더하거나 빼지 않는다")
    func test합친자판_기호집합유지() {
        for mode in [SymbolKeyboardMode.URL, .emailAddress] {
            let before = Set(mode.keyList(usesNumberRow: false).flatMap { $0.flatMap { $0.flatMap { $0 } } })
                .subtracting(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            let after = Set(mode.keyList(usesNumberRow: true).flatMap { $0.flatMap { $0.flatMap { $0 } } })

            #expect(before == after)
        }
    }

    @Test("숫자 행이 꺼지면 URL·이메일 자판은 두 페이지 그대로다")
    func testURL이메일자판_숫자행꺼짐() {
        let urlKeyList = SymbolKeyboardMode.URL.keyList(usesNumberRow: false)
        #expect(urlKeyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(urlKeyList[1][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])

        let emailKeyList = SymbolKeyboardMode.emailAddress.keyList(usesNumberRow: false)
        #expect(emailKeyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(emailKeyList[1][0].map(\.first) == ["’", "|", "{", "}", "?", "%", "^", "*", "/", "’"])
    }
}
