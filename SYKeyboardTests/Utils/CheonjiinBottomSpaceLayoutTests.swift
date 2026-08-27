//
//  CheonjiinBottomSpaceLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@MainActor
@Suite("천지인 스페이스 하단 배치")
struct CheonjiinBottomSpaceLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool) -> CheonjiinKeyboardView {
        let view = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
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

    @Test("꺼짐 상태는 스페이스가 리턴보다 위, !#1이 우측 끝")
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

    @Test("켜짐 상태는 리턴이 스페이스보다 위, 스페이스가 !#1과 같은 행")
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

    @Test("켜짐 상태의 리턴은 2행, 마침표·쉼표는 3행")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        let periodButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "." })
        let questionButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "?" })

        let deleteRect = Self.rect(view.deleteButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let periodRect = Self.rect(periodButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let questionRect = Self.rect(questionButton, in: view)

        // 1행(삭제) < 2행(리턴) < 3행(마침표) < 4행(스페이스)
        #expect(deleteRect.midY < returnRect.midY)
        #expect(returnRect.midY < periodRect.midY)
        #expect(periodRect.midY < space.midY)
        // '?'·'!'는 4행 우측 끝에 남는다
        #expect(abs(questionRect.midY - space.midY) < 0.5)
        #expect(questionRect.minX >= space.maxX - 0.5)
    }

    @Test("두 배치 모두 네 행이 4칸 균등 분할을 유지",
          arguments: [false, true])
    func testAllRowsKeepFourEqualColumns(_ usesBottomSpaceLayout: Bool) {
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

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(languageButton.frame.width
                - Self.keyboardWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 남는 너비는 전환 버튼이 채운다
        #expect(languageButton.frame.width < view.switchButton.frame.width)
        // 같은 modifier 스택 안이라 변환 없이 비교한다. 좌→우 !#1 → 한/영
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
    }

    @Test("켜짐 상태에서 지구본이 보이면 modifier 세 버튼이 균등 분배")
    func testBottomSpaceLayoutEqualModifierDistributionWithGlobe() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(view.languageSwitchButton)

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: true,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(!view.nextKeyboardButton.isHidden)
        #expect(abs(view.switchButton.frame.width - languageButton.frame.width) < 1.0)
        #expect(abs(languageButton.frame.width - view.nextKeyboardButton.frame.width) < 1.0)
        // 좌→우 !#1 → 한/영 → 🌐
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX + 0.5)
    }
}
