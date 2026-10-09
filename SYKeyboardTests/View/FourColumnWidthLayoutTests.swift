//
//  FourColumnWidthLayoutTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing
import UIKit

@testable import SYKeyboardCore
@testable import HangeulKeyboardCore

/// 최대 배율 1.15에서 키보드 폭 대비 열 비율. 배율별 진리표는 `KeyboardColumnWidthPolicyTests`가 갖고,
/// 레이아웃 테스트는 이 값이 실제 뷰에 적용되는지만 본다
enum WidenedColumnRatio {
    /// 1·2·3열(글자 열) 하나의 폭. 1.15 / 4
    static let letterColumn: CGFloat = 0.2875
    /// 4열(기능 열)의 폭. 1 - 0.2875 × 3
    static let functionColumn: CGFloat = 0.1375
    /// 4열이 시작하는 x. 0.2875 × 3
    static let functionColumnStart: CGFloat = 0.8625
}

@MainActor
@Suite("4열 격자 열 너비 레이아웃")
struct FourColumnWidthLayoutTests {
    static let rowWidth: CGFloat = 400
    static let rowHeight: CGFloat = 50
    /// @2x 기기에서 열 폭이 픽셀 그리드에 반올림되면 형제 버튼 사이에 최대 0.5pt 차이가
    /// 생긴다(53.625 → 53.5 → 26.5/27.0). 레이아웃 오류가 아니므로 그보다 크게 잡는다
    static let tolerance: CGFloat = 1.0

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
        let (_, row, _) = Self.makeRow(multiplier: 1.15)
        let widths = row.arrangedSubviews.map(\.frame.width)

        #expect(abs(widths[0] - widths[1]) < Self.tolerance)
        #expect(abs(widths[1] - widths[2]) < Self.tolerance)
        #expect(abs(widths[0] - Self.rowWidth * WidenedColumnRatio.letterColumn) < Self.tolerance)
        #expect(abs(widths[3] - Self.rowWidth * WidenedColumnRatio.functionColumn) < Self.tolerance)
        #expect(abs(widths.reduce(0, +) - Self.rowWidth) < Self.tolerance)
    }

    @Test("update로 배율을 바꾸면 폭이 다시 계산된다")
    func testUpdateRecalculatesWidths() {
        let (container, row, controller) = Self.makeRow(multiplier: 1.0)

        controller.update(multiplier: 1.15)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth * WidenedColumnRatio.functionColumn) < Self.tolerance)

        controller.update(multiplier: 1.0)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth / 4) < Self.tolerance)
    }
}

@MainActor
@Suite("나랏글 열 너비 레이아웃")
struct NaratgeulColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 1.0

    @MainActor
    private static func makeView(multiplier: Double) -> NaratgeulKeyboardView {
        let view = NaratgeulKeyboardView(showsLanguageSwitchButton: true, showsNumberRow: false)
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

    @Test("프로토콜 타입으로 호출해도 배율이 적용된다")
    func testUpdateThroughProtocolDispatch() {
        let view = Self.makeView(multiplier: 1.0)
        let provider: PrimaryKeyboardRepresentable = view

        provider.updateLetterColumnWidthMultiplier(1.15)
        view.layoutIfNeeded()

        // 기본 no-op 구현이 witness로 잡히면 이 단언이 실패한다
        #expect(abs(Self.rect(view.deleteButton, in: view).width
                    - Self.keyboardWidth * WidenedColumnRatio.functionColumn) < Self.tolerance)
    }
}

@MainActor
@Suite("천지인 열 너비 레이아웃")
struct CheonjiinColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 1.0

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool, multiplier: Double) -> CheonjiinKeyboardView {
        let view = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
                                        usesBottomSpaceLayout: usesBottomSpaceLayout,
                                        showsNumberRow: false)
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

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.15)
        let expectedColumnStart = Self.keyboardWidth * WidenedColumnRatio.functionColumnStart

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

    @Test("하단 스페이스 배치도 배율을 되돌리면 균등 분할로 돌아온다")
    func testBottomSpaceLayoutUpdatingBackRestoresEqualColumns() {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.15)

        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
    }
}

@MainActor
@Suite("숫자 키패드 열 너비 레이아웃")
struct NumericColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 1.0

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

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.15)
        let expectedColumnStart = Self.keyboardWidth * WidenedColumnRatio.functionColumnStart

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
}

@MainActor
@Suite("4열 자판 공통 열 너비 레이아웃")
struct FourColumnKeyboardColumnWidthTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 1.0

    /// 배율을 적용해 레이아웃한 자판과 비교 대상 버튼들. 배율은 controller처럼 프로토콜 타입으로 바꾼다
    struct Layout {
        let view: NormalKeyboardLayoutProvider
        /// 리턴 자리. 숫자 키패드만 단일 버튼이고 나머지는 스택이다
        let returnView: UIView
        /// 1열 맨 위 키. 숫자 키패드는 숫자 키다
        let firstColumnKey: PrimaryKeyButton?
    }

    /// 4열 격자를 공유하는 세 자판. 천지인·숫자는 기본 배치다
    enum Fixture: CustomTestStringConvertible {
        case naratgeul
        case cheonjiin
        case numeric

        var testDescription: String {
            switch self {
            case .naratgeul: return "나랏글"
            case .cheonjiin: return "천지인 기본 배치"
            case .numeric: return "숫자 키패드 기본 배치"
            }
        }

        @MainActor
        func makeLayout(width: CGFloat, height: CGFloat, multiplier: Double) -> Layout {
            let view: NormalKeyboardLayoutProvider
            let returnView: UIView
            let firstColumnKeyText: String
            switch self {
            case .naratgeul:
                let naratgeul = NaratgeulKeyboardView(showsLanguageSwitchButton: true, showsNumberRow: false)
                (view, returnView, firstColumnKeyText) = (naratgeul, naratgeul.returnButtonHStackView, "ㄱ")
            case .cheonjiin:
                let cheonjiin = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
                                                      usesBottomSpaceLayout: false,
                                                      showsNumberRow: false)
                (view, returnView, firstColumnKeyText) = (cheonjiin, cheonjiin.returnButtonHStackView, "ㅣ")
            case .numeric:
                let numeric = NumericKeyboardView(showsLanguageSwitchButton: true, usesBottomSpaceLayout: false)
                (view, returnView, firstColumnKeyText) = (numeric, numeric.returnButton, "1")
            }
            view.frame = CGRect(x: 0, y: 0, width: width, height: height)
            view.updateLetterColumnWidthMultiplier(multiplier)
            view.layoutIfNeeded()

            let firstColumnKey = view.primaryButtonList
                .compactMap { $0 as? PrimaryKeyButton }
                .first { $0.type.primaryKeyList.first == firstColumnKeyText }
            return Layout(view: view, returnView: returnView, firstColumnKey: firstColumnKey)
        }
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 행을 가로질러 비교하려면 변환해야 한다
    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @Test("기본 배율은 세 자판 모두 네 열을 균등 분할한다",
          arguments: [Fixture.naratgeul, .cheonjiin, .numeric])
    func testDefaultMultiplierKeepsEqualColumns(fixture: Fixture) {
        let layout = fixture.makeLayout(width: Self.keyboardWidth, height: Self.keyboardHeight, multiplier: 1.0)
        let view = layout.view
        let expected = Self.keyboardWidth / 4
        // 배율 1.0의 열 폭(97.5)은 픽셀 그리드에 맞아 반올림 오차가 없으므로 0.5로 고정한다
        let tolerance: CGFloat = 0.5

        #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < tolerance)
        #expect(abs(Self.rect(view.spaceButton, in: view).width - expected) < tolerance)
        #expect(abs(Self.rect(layout.returnView, in: view).width - expected) < tolerance)
    }

    @Test("배율을 되돌리면 세 자판 모두 균등 분할로 돌아온다",
          arguments: [Fixture.naratgeul, .cheonjiin, .numeric])
    func testUpdatingBackRestoresEqualColumns(fixture: Fixture) {
        let view = fixture.makeLayout(width: Self.keyboardWidth, height: Self.keyboardHeight, multiplier: 1.15).view

        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
    }

    @Test("배율을 올리면 세 자판 모두 기능 열이 좁아지고 열 경계가 행마다 일치한다",
          arguments: [Fixture.naratgeul, .cheonjiin, .numeric])
    func test배율올리면_기능열좁아지고_열경계일치(fixture: Fixture) {
        let layout = fixture.makeLayout(width: Self.keyboardWidth, height: Self.keyboardHeight, multiplier: 1.15)
        let view = layout.view
        let expectedFunctionWidth = Self.keyboardWidth * WidenedColumnRatio.functionColumn
        let expectedColumnStart = Self.keyboardWidth * WidenedColumnRatio.functionColumnStart

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(layout.returnView, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnRect.width - expectedFunctionWidth) < Self.tolerance)

        // 1~4행 모두 4열이 같은 x에서 시작한다
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnRect.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("배율을 올리면 세 자판 모두 1열 키(숫자 키패드는 숫자 키)가 넓어진다",
          arguments: [Fixture.naratgeul, .cheonjiin, .numeric])
    func testHigherMultiplierWidensKeyButtons(fixture: Fixture) throws {
        let defaultLayout = fixture.makeLayout(width: Self.keyboardWidth, height: Self.keyboardHeight, multiplier: 1.0)
        let widenedLayout = fixture.makeLayout(width: Self.keyboardWidth, height: Self.keyboardHeight, multiplier: 1.15)

        let defaultKey = try #require(defaultLayout.firstColumnKey)
        let widenedKey = try #require(widenedLayout.firstColumnKey)

        #expect(widenedKey.frame.width > defaultKey.frame.width)
        #expect(abs(widenedKey.frame.width - Self.keyboardWidth * WidenedColumnRatio.letterColumn) < Self.tolerance)
    }
}
