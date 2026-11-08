//
//  BaseKeyboardViewControllerHeightLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// 키보드 높이 계산과 시스템이 늘린 높이를 언제 키 영역에 더할지는 `KeyboardHeightPolicyTests`가 갖고,
/// 여기서는 iPhone Duo 안쪽 화면(regular×regular)에서 VC가 그 규칙을 키보드 생명주기에 맞춰 적용하는지만 본다
@MainActor
@Suite("키보드 높이에 따른 자동완성 바·키 영역 배치")
struct BaseKeyboardViewControllerHeightLayoutTests {
    private static let width: CGFloat = 375
    private static let tolerance: CGFloat = 0.5

    /// window에 올리고 `viewWillAppear`로 높이 제약을 건 키보드 뷰
    private func makeAppearedKeyboardView() throws -> (KeyboardView, UIWindow, HeightTestViewController) {
        let controller = HeightTestViewController()
        // iPhone Duo 안쪽 화면
        controller.traitOverrides.horizontalSizeClass = .regular
        controller.traitOverrides.verticalSizeClass = .regular
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(controller.view)
        // 확장에서는 시스템이 부르는 콜백이다. 높이 제약은 여기서 처음 걸린다
        controller.viewWillAppear(false)

        return (try #require(controller.view as? KeyboardView), window, controller)
    }

    /// VC가 키 영역에 건 높이(요청 높이에서 자동완성 바를 뺀 값)
    private func requestedKeyAreaHeight(_ keyboardView: KeyboardView) throws -> CGFloat {
        let constraint = keyboardView.keyboardHStackView.constraints.first {
            $0.firstItem === keyboardView.keyboardHStackView && $0.firstAttribute == .height && $0.secondItem == nil
        }
        return try #require(constraint).constant
    }

    private func frames(in keyboardView: KeyboardView, height: CGFloat) -> (bar: CGRect, keys: CGRect) {
        keyboardView.frame = CGRect(x: 0, y: 0, width: Self.width, height: height)
        keyboardView.layoutIfNeeded()
        let bar = keyboardView.suggestionBarView
        let keys = keyboardView.keyboardHStackView

        return (bar.isHidden ? .zero : bar.convert(bar.bounds, to: keyboardView),
                keys.convert(keys.bounds, to: keyboardView))
    }

    @Test("요청한 높이 그대로면 키 영역은 VC가 건 높이를 쓰고 키보드 아래에 붙음")
    func test요청높이_키영역높이그대로() throws {
        let (keyboardView, window, _) = try makeAppearedKeyboardView()
        defer { window.removeFromSuperview() }
        let keyAreaHeight = try requestedKeyAreaHeight(keyboardView)
        let requestedHeight = keyAreaHeight + KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing

        let (_, keys) = frames(in: keyboardView, height: requestedHeight)

        #expect(abs(keys.height - keyAreaHeight) < Self.tolerance)
        #expect(abs(keys.maxY - requestedHeight) < Self.tolerance)
    }

    @Test("다 올라온 뒤 시스템이 키보드를 요청보다 키우면 키 영역이 늘어나 자동완성 바 위에 빈 띠가 남지 않음")
    func test키보드가커지면_키영역이채움() throws {
        let (keyboardView, window, controller) = try makeAppearedKeyboardView()
        defer { window.removeFromSuperview() }
        let keyAreaHeight = try requestedKeyAreaHeight(keyboardView)
        controller.viewDidAppear(false)
        // iPhone Duo를 반쯤 펼친 세로에서 시스템이 키보드를 37pt 키운 상황(284 → 321)
        let enlargedHeight = keyAreaHeight + KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing + 37

        let (bar, keys) = frames(in: keyboardView, height: enlargedHeight)

        #expect(abs(bar.minY) < Self.tolerance)
        #expect(abs(keys.minY - bar.maxY) < Self.tolerance)
        #expect(abs(keys.maxY - enlargedHeight) < Self.tolerance)
        #expect(abs(keys.height - (keyAreaHeight + 37)) < Self.tolerance)
    }

    @Test("올라오는 동안 시스템이 잠깐 키보드를 크게 잡아도 키 영역은 요청한 높이 그대로 아래에 붙음")
    func test올라오는동안_키영역고정() throws {
        let (keyboardView, window, _) = try makeAppearedKeyboardView()
        defer { window.removeFromSuperview() }
        let keyAreaHeight = try requestedKeyAreaHeight(keyboardView)
        // iPhone Duo 바깥 화면에서 키보드가 미끄러져 올라오는 첫 프레임처럼 아주 높게 잡힌 상황
        let transientHeight: CGFloat = 600

        let (_, keys) = frames(in: keyboardView, height: transientHeight)

        #expect(abs(keys.height - keyAreaHeight) < Self.tolerance)
        #expect(abs(keys.maxY - transientHeight) < Self.tolerance)
    }

}

private final class HeightTestViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}
}
