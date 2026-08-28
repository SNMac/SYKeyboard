//
//  FourColumnWidthLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import SYKeyboardCore
@testable import HangeulKeyboardCore

@MainActor
@Suite("4열 격자 열 너비 레이아웃")
struct FourColumnWidthLayoutTests {
    static let rowWidth: CGFloat = 400
    static let rowHeight: CGFloat = 50
    static let tolerance: CGFloat = 0.5

    /// 4열 스택 하나를 만들고 컨트롤러로 폭 제약을 설치한 뒤 레이아웃한다
    @MainActor
    private static func makeRow(multiplier: Double)
    -> (container: UIView, row: UIStackView, controller: FourColumnWidthLayoutController) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: rowWidth, height: rowHeight))
        let row = KeyboardRowHStackView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        (0..<4).forEach { _ in row.addArrangedSubview(UIView()) }

        let controller = FourColumnWidthLayoutController()
        controller.install(rows: [row],
                           languageSwitchButton: nil,
                           referenceView: container,
                           multiplier: multiplier)
        container.layoutIfNeeded()

        return (container, row, controller)
    }

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierSplitsEqually() {
        let (_, row, _) = Self.makeRow(multiplier: 1.0)
        let widths = row.arrangedSubviews.map(\.frame.width)

        widths.forEach { #expect(abs($0 - Self.rowWidth / 4) < Self.tolerance) }
    }

    @Test("배율을 올리면 1~3열이 등폭으로 넓어지고 4열이 좁아진다")
    func testHigherMultiplierWidensFirstThreeColumns() {
        let (_, row, _) = Self.makeRow(multiplier: 1.2)
        let widths = row.arrangedSubviews.map(\.frame.width)

        #expect(abs(widths[0] - widths[1]) < Self.tolerance)
        #expect(abs(widths[1] - widths[2]) < Self.tolerance)
        #expect(abs(widths[0] - Self.rowWidth * 0.3) < Self.tolerance)
        #expect(abs(widths[3] - Self.rowWidth * 0.1) < Self.tolerance)
        #expect(abs(widths.reduce(0, +) - Self.rowWidth) < Self.tolerance)
    }

    @Test("update로 배율을 바꾸면 폭이 다시 계산된다")
    func testUpdateRecalculatesWidths() {
        let (container, row, controller) = Self.makeRow(multiplier: 1.0)

        controller.update(multiplier: 1.2)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth * 0.1) < Self.tolerance)

        controller.update(multiplier: 1.0)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth / 4) < Self.tolerance)
    }

    @Test("한영 전환 버튼 폭은 기능 열에 연동된다")
    func testLanguageSwitchButtonWidthFollowsFunctionColumn() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: Self.rowWidth, height: Self.rowHeight))
        let row = KeyboardRowHStackView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        (0..<3).forEach { _ in row.addArrangedSubview(UIView()) }

        let modifierStack = KeyboardRowHStackView()
        modifierStack.distribution = .fill
        let languageSwitchButton = UIView()
        modifierStack.addArrangedSubview(languageSwitchButton)
        modifierStack.addArrangedSubview(UIView())
        row.addArrangedSubview(modifierStack)

        let controller = FourColumnWidthLayoutController()
        controller.install(rows: [row],
                           languageSwitchButton: languageSwitchButton,
                           referenceView: container,
                           multiplier: 1.0)
        container.layoutIfNeeded()

        // 기본 배율에서는 기존 상수와 같은 폭이다
        #expect(abs(languageSwitchButton.frame.width
                    - Self.rowWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < Self.tolerance)

        controller.update(multiplier: 1.2)
        container.layoutIfNeeded()

        // 기능 열이 좁아지면 한영 전환 버튼도 좁아지고, 같은 열의 다른 버튼 폭이 남는다
        #expect(languageSwitchButton.frame.width < Self.rowWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio)
        #expect(languageSwitchButton.frame.width < modifierStack.frame.width)
        #expect(modifierStack.arrangedSubviews[1].frame.width > 0)
    }
}

@MainActor
@Suite("나랏글 열 너비 레이아웃")
struct NaratgeulColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(multiplier: Double) -> NaratgeulKeyboardView {
        let view = NaratgeulKeyboardView(showsLanguageSwitchButton: true)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 행을 가로질러 비교하려면 변환해야 한다
    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let view = Self.makeView(multiplier: 1.0)
        let expected = Self.keyboardWidth / 4

        #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        #expect(abs(Self.rect(view.spaceButton, in: view).width - expected) < Self.tolerance)
        #expect(abs(Self.rect(view.returnButtonHStackView, in: view).width - expected) < Self.tolerance)
    }

    @Test("배율을 올리면 기능 열이 좁아지고 열 경계가 행마다 일치한다")
    func testHigherMultiplierNarrowsFunctionColumn() {
        let view = Self.makeView(multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnStack.width - expectedFunctionWidth) < Self.tolerance)

        // 1~4행 모두 4열이 같은 x에서 시작한다
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("배율을 올리면 글자 버튼이 넓어진다")
    func testHigherMultiplierWidensKeyButtons() throws {
        let defaultView = Self.makeView(multiplier: 1.0)
        let widenedView = Self.makeView(multiplier: 1.2)

        let defaultKey = try #require(defaultView.primaryButtonList.first as? PrimaryKeyButton)
        let widenedKey = try #require(widenedView.primaryButtonList.first as? PrimaryKeyButton)

        #expect(widenedKey.frame.width > defaultKey.frame.width)
        #expect(abs(widenedKey.frame.width - Self.keyboardWidth * 0.3) < Self.tolerance)
    }

    @Test("프로토콜 타입으로 호출해도 배율이 적용된다")
    func testUpdateThroughProtocolDispatch() {
        let view = Self.makeView(multiplier: 1.0)
        let provider: PrimaryKeyboardRepresentable = view

        provider.updateLetterColumnWidthMultiplier(1.2)
        view.layoutIfNeeded()

        // 기본 no-op 구현이 witness로 잡히면 이 단언이 실패한다
        #expect(abs(Self.rect(view.deleteButton, in: view).width
                    - Self.keyboardWidth * 0.1) < Self.tolerance)
    }

    @Test("배율을 되돌리면 균등 분할로 돌아온다")
    func testUpdatingBackRestoresEqualColumns() {
        let view = Self.makeView(multiplier: 1.2)

        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
    }
}

@MainActor
@Suite("천지인 열 너비 레이아웃")
struct CheonjiinColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool, multiplier: Double) -> CheonjiinKeyboardView {
        let view = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
                                        usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @MainActor
    private static func keyButton(_ view: CheonjiinKeyboardView, primary: String) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        return try #require(keyButtons.first { $0.type.primaryKeyList.first == primary })
    }

    @Test("기본 배율은 두 배치 모두 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let expected = Self.keyboardWidth / 4

        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.0)
            #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        }
    }

    @Test("기본 배치에서 배율을 올리면 기능 열이 좁아지고 열 경계가 일치한다")
    func testDefaultLayoutNarrowsFunctionColumn() {
        let view = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnStack.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.2)
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        // 3행 4열은 '?' '!' 글자 스택, 4행 4열은 '.' ',' 글자 스택이다
        let question = Self.rect(try Self.keyButton(view, primary: "?"), in: view)
        let period = Self.rect(try Self.keyButton(view, primary: "."), in: view)

        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(question.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(period.minX - expectedColumnStart) < Self.tolerance)

        // 4행 1열의 modifier 스택은 넓어진 열에 놓인다
        #expect(abs(Self.rect(view.switchButton, in: view).minX) < Self.tolerance)
    }

    @Test("하단 스페이스 배치에서 한영 전환 버튼은 자기 열 폭에 비례한다")
    func testBottomSpaceLayoutScalesLanguageSwitchButtonWithItsColumn() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.2)
        let languageSwitchButton = try #require(view.languageSwitchButton)
        // 지구본이 숨겨져야 stack의 균등 분배가 아니라 폭 제약이 성립한다
        view.nextKeyboardButton.isHidden = true
        view.nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: false)
        view.layoutIfNeeded()

        // 하단 스페이스 배치의 modifier 스택은 4행 1열이므로 배율을 올리면 넓어진다
        let column = Self.rect(view.switchButton, in: view).union(Self.rect(languageSwitchButton, in: view))
        let buttonWidth = Self.rect(languageSwitchButton, in: view).width

        #expect(abs(column.width - Self.keyboardWidth * 0.3) < Self.tolerance)
        #expect(abs(buttonWidth - column.width
                    * KeyboardLayoutFigure.languageSwitchButtonFunctionColumnShare) < Self.tolerance)
        // 열이 넓어졌으므로 버튼도 기본 배율(0.1W)보다 넓어야 한다
        #expect(buttonWidth > Self.keyboardWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio)
    }

    @Test("배율을 되돌리면 두 배치 모두 균등 분할로 돌아온다")
    func testUpdatingBackRestoresEqualColumns() {
        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.2)

            view.updateLetterColumnWidthMultiplier(1.0)
            view.layoutIfNeeded()

            #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
        }
    }
}

@MainActor
@Suite("숫자 키패드 열 너비 레이아웃")
struct NumericColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool, multiplier: Double) -> NumericKeyboardView {
        let view = NumericKeyboardView(showsLanguageSwitchButton: true,
                                       usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @MainActor
    private static func keyButton(_ view: NumericKeyboardView, primary: String) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        return try #require(keyButtons.first { $0.type.primaryKeyList.first == primary })
    }

    @Test("기본 배율은 두 배치 모두 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let expected = Self.keyboardWidth / 4

        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.0)
            #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        }
    }

    @Test("기본 배치에서 배율을 올리면 기능 열이 좁아지고 열 경계가 일치한다")
    func testDefaultLayoutNarrowsFunctionColumn() {
        let view = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnRect.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnRect.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.2)
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        // 3행 4열은 '-' '/' 스택, 4행 4열은 '.' ',' 스택이다
        let minus = Self.rect(try Self.keyButton(view, primary: "-"), in: view)
        let period = Self.rect(try Self.keyButton(view, primary: "."), in: view)

        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnRect.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(minus.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(period.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(Self.rect(view.switchButton, in: view).minX) < Self.tolerance)
    }

    @Test("배율을 올리면 숫자 버튼이 넓어진다")
    func testHigherMultiplierWidensKeyButtons() throws {
        let defaultView = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.0)
        let widenedView = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)

        let defaultKey = try Self.keyButton(defaultView, primary: "1")
        let widenedKey = try Self.keyButton(widenedView, primary: "1")

        #expect(widenedKey.frame.width > defaultKey.frame.width)
        #expect(abs(widenedKey.frame.width - Self.keyboardWidth * 0.3) < Self.tolerance)
    }
}
