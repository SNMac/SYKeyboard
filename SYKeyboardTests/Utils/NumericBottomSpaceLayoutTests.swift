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
        // '-'·'/' 쌍은 3행 4칸 중 4분의 3 지점(우측 칸)에서 시작한다
        #expect(abs(hyphen.minX - Self.keyboardWidth * 0.75) < 0.5)
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
        // modifier 스택의 첫 버튼(nextKeyboardButton)을 경계로 써야
        // 스택 내부 순서가 바뀌어도 실제로 경계를 고정한다
        #expect(slash.maxX <= Self.rect(view.nextKeyboardButton, in: view).minX + 0.5)
    }

    @Test("켜짐 상태의 키보드 선택 오버레이는 좌측에서 시작하고 취소 경계가 전환 버튼 우측 모서리 안쪽")
    func testBottomSpaceLayoutKeyboardSelectOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 좁아지고 999가 양보하므로 숨긴다
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let overlay = view.keyboardSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        // 오버레이는 키보드 뷰의 직접 subview라 frame이 이미 뷰 좌표계다
        #expect(abs(overlay.frame.minX - 4) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)

        let xmarkInView = overlay.convert(overlay.xmarkImageContainerView.frame, to: view)
        #expect(
            abs(xmarkInView.maxX
                - (switchRect.maxX - KeyboardLayoutFigure.keyboardSelectBoundaryInset)) < 0.5
        )
        #expect(xmarkInView.width >= KeyboardLayoutFigure.keyboardSelectCancelMinWidth)
        // `.right` 방향이면 X가 스택의 첫 칸이라 오버레이 왼쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.minX
                - overlay.directionalLayoutMargins.leading) < 0.5
        )
    }

    @Test("켜짐 상태의 한 손 모드 오버레이는 전환 버튼 위 좌측에 놓임")
    func testBottomSpaceLayoutOneHandedOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.oneHandedModeSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        let overlay = view.oneHandedModeSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.minX - 4) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)
        #expect(abs(overlay.frame.width - KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth) < 0.5)
    }

    @Test("꺼짐 상태의 한 손 모드 오버레이는 전환 버튼 위 우측에 놓임")
    func testDefaultLayoutOneHandedOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        view.oneHandedModeSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        let overlay = view.oneHandedModeSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.maxX - (Self.keyboardWidth - 4)) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)
        #expect(abs(overlay.frame.width - KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth) < 0.5)
    }

    @Test("꺼짐 상태의 오버레이는 기존처럼 우측 정렬을 유지")
    func testDefaultLayoutOverlayKeepsTrailingAnchor() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let overlay = view.keyboardSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.maxX - (Self.keyboardWidth - 4)) < 0.5)

        let xmarkInView = overlay.convert(overlay.xmarkImageContainerView.frame, to: view)
        #expect(
            abs(xmarkInView.minX
                - (switchRect.minX + KeyboardLayoutFigure.keyboardSelectBoundaryInset)) < 0.5
        )
        #expect(xmarkInView.width >= KeyboardLayoutFigure.keyboardSelectCancelMinWidth)
        // `.left` 방향이면 X가 스택의 마지막 칸이라 오버레이 오른쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.maxX
                - (overlay.bounds.width - overlay.directionalLayoutMargins.trailing)) < 0.5
        )
    }
}
