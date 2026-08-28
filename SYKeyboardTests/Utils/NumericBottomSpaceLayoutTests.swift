//
//  NumericBottomSpaceLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("숫자 키패드 스페이스 하단 배치")
struct NumericBottomSpaceLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool) -> NumericKeyboardView {
        let view = NumericKeyboardView(showsLanguageSwitchButton: true,
                                       usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.layoutIfNeeded()

        return view
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 `midY`가 전부 같다.
    /// 행을 가로질러 비교하려면 키보드 뷰 좌표계로 변환해야 한다
    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    /// `numericKeyList[3]`의 문장부호 버튼을 표시 문자로 찾는다
    @MainActor
    private static func keyButton(_ key: String, in view: NumericKeyboardView) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }

        return try #require(keyButtons.first { $0.type.primaryKeyList.first == key })
    }

    @Test("꺼짐 상태는 스페이스가 리턴보다 위, 전환 버튼이 우측 끝")
    func testDefaultLayoutKeepsSpaceAboveReturn() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(space.midY < returnRect.midY)
        #expect(returnRect.midY < switchRect.midY)
        // 꺼짐 배치의 modifier 스택은 4행 우측 끝에 붙는다
        #expect(abs(switchRect.maxX - Self.keyboardWidth) < 0.5)
    }

    @Test("켜짐 상태는 리턴이 스페이스보다 위, 스페이스가 전환 버튼과 같은 행")
    func testBottomSpaceLayoutMovesSpaceToLastRow() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(returnRect.midY < space.midY)
        #expect(abs(space.midY - switchRect.midY) < 0.5)
        #expect(switchRect.maxX <= space.minX + 0.5)
        // 켜짐 배치의 modifier 스택은 4행 좌측 끝에 붙는다
        #expect(abs(switchRect.minX) < 0.5)
    }

    @Test("두 배치 모두 삭제·스페이스 버튼이 한 칸 폭을 유지",
          arguments: [false, true])
    func testDeleteAndSpaceKeepSingleColumnWidth(_ usesBottomSpaceLayout: Bool) {
        let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout)
        let columnWidth = Self.keyboardWidth / 4

        // 폭은 좌표계와 무관하므로 변환이 필요 없다
        #expect(abs(view.deleteButton.frame.width - columnWidth) < 0.5)
        #expect(abs(view.spaceButton.frame.width - columnWidth) < 0.5)
    }

    @Test("켜짐 상태에서도 지구본 숨김 시 한/영이 글자 버튼 한 칸 너비")
    func testBottomSpaceLayoutKeepsLanguageSwitchWidthContract() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(view.languageSwitchButton)

        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(languageButton.frame.width
                - Self.keyboardWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 같은 modifier 스택 안이라 변환 없이 비교한다. 좌→우 전환 → 한/영
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
    }

    @Test("켜짐 상태는 '-'·'/'가 3행 우측, '.'·','가 4행 끝")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let hyphen = Self.rect(try Self.keyButton("-", in: view), in: view)
        let slash = Self.rect(try Self.keyButton("/", in: view), in: view)
        let period = Self.rect(try Self.keyButton(".", in: view), in: view)
        let comma = Self.rect(try Self.keyButton(",", in: view), in: view)
        let zero = Self.rect(try Self.keyButton("0", in: view), in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)

        // 2행(리턴) < 3행('-'·'/') < 4행('.'·',')
        #expect(returnRect.midY < hyphen.midY)
        #expect(hyphen.midY < period.midY)
        // 3행 우측 칸 안에서 좌→우 '-' → '/'
        #expect(abs(slash.midY - hyphen.midY) < 0.5)
        #expect(hyphen.maxX <= slash.minX + 0.5)
        #expect(abs(slash.maxX - Self.keyboardWidth) < 0.5)
        // 4행 안에서 좌→우 modifier → '0' → space → '.' → ','
        #expect(abs(comma.midY - period.midY) < 0.5)
        #expect(abs(zero.midY - period.midY) < 0.5)
        #expect(zero.maxX <= space.minX + 0.5)
        #expect(space.maxX <= period.minX + 0.5)
        #expect(period.maxX <= comma.minX + 0.5)
        #expect(abs(comma.maxX - Self.keyboardWidth) < 0.5)
    }

    @Test("꺼짐 상태는 4행이 좌→우 '-' ',' '0' '.' '/' modifier 순서를 유지")
    func testDefaultLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let hyphen = Self.rect(try Self.keyButton("-", in: view), in: view)
        let comma = Self.rect(try Self.keyButton(",", in: view), in: view)
        let zero = Self.rect(try Self.keyButton("0", in: view), in: view)
        let period = Self.rect(try Self.keyButton(".", in: view), in: view)
        let slash = Self.rect(try Self.keyButton("/", in: view), in: view)
        let switchRect = Self.rect(view.switchButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)

        // 다섯 글자 버튼이 모두 4행이고 리턴(3행)보다 아래다
        #expect(returnRect.midY < hyphen.midY)
        [comma, zero, period, slash].forEach { #expect(abs($0.midY - hyphen.midY) < 0.5) }
        #expect(abs(hyphen.minX) < 0.5)
        #expect(hyphen.maxX <= comma.minX + 0.5)
        #expect(comma.maxX <= zero.minX + 0.5)
        #expect(zero.maxX <= period.minX + 0.5)
        #expect(period.maxX <= slash.minX + 0.5)
        #expect(slash.maxX <= switchRect.minX + 0.5)
    }
}
