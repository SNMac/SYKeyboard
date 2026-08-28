//
//  FourColumnWidthLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import SYKeyboardCore

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
