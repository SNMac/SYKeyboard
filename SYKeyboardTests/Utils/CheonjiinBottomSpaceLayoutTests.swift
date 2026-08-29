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

    @Test("켜짐 상태의 리턴은 2행, 물음표·느낌표는 3행, 마침표·쉼표는 4행")
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

        // 1행(삭제) < 2행(리턴) < 3행(물음표) < 4행(스페이스)
        #expect(deleteRect.midY < returnRect.midY)
        #expect(returnRect.midY < questionRect.midY)
        #expect(questionRect.midY < space.midY)
        // '.'·','가 4행 우측 끝으로 내려온다
        #expect(abs(periodRect.midY - space.midY) < 0.5)
        #expect(periodRect.minX >= space.maxX - 0.5)
    }

    @Test("꺼짐 상태의 스페이스는 2행, 리턴은 3행, 마침표·물음표는 4행")
    func testDefaultLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        let periodButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "." })
        let jamoButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "ㅇ" })
        let questionButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "?" })

        let deleteRect = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let periodRect = Self.rect(periodButton, in: view)
        let jamoRect = Self.rect(jamoButton, in: view)
        let questionRect = Self.rect(questionButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        // 1행(삭제) < 2행(스페이스) < 3행(리턴) < 4행(마침표)
        #expect(deleteRect.midY < space.midY)
        #expect(space.midY < returnRect.midY)
        #expect(returnRect.midY < periodRect.midY)
        // '?'도 '.'과 같은 4행에 있다
        #expect(abs(questionRect.midY - periodRect.midY) < 0.5)
        // 4행 안에서 좌→우 '.' → 'ㅇㅁ' → '?' → modifier 스택
        #expect(periodRect.maxX <= jamoRect.minX + 0.5)
        #expect(jamoRect.maxX <= questionRect.minX + 0.5)
        #expect(questionRect.maxX <= switchRect.minX + 0.5)
    }

    @Test("두 배치 모두 삭제·스페이스 버튼이 한 칸 폭을 유지",
          arguments: [false, true])
    func testDeleteAndSpaceKeepSingleColumnWidth(_ usesBottomSpaceLayout: Bool) {
        let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout)
        let columnWidth = Self.keyboardWidth / 4

        // 폭은 좌표계와 무관하므로 변환이 필요 없다.
        // 삭제는 항상 1행, 스페이스는 꺼짐 2행 / 켜짐 4행이므로
        // 두 배치에서 서로 다른 행이 한 칸 폭을 유지하는지 확인한다
        #expect(abs(view.deleteButton.frame.width - columnWidth) < 0.5)
        #expect(abs(view.spaceButton.frame.width - columnWidth) < 0.5)
    }

    @Test("켜짐 상태에서 지구본을 숨기면 modifier 두 버튼이 스택을 균등 분배")
    func testBottomSpaceLayoutSplitsModifierStackEqually() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(view.languageSwitchButton)

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        // 프로덕션은 `viewWillLayoutSubviews`에서 지구본 상태를 반영한 뒤 레이아웃 패스를 돌린다.
        // 오프스크린 뷰는 그 패스가 자동으로 돌지 않으므로 명시적으로 레이아웃을 무효화한다
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let modifierStack = try #require(languageButton.superview)
        // 지구본이 숨겨져 한/영과 전환 버튼 2개만 남는다
        let visibleButtonCount: CGFloat = 2

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(languageButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
        #expect(
            abs(view.switchButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
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

    @Test("켜짐 상태의 키보드 선택 오버레이는 좌측에서 시작하고 취소 경계가 !#1 우측 모서리 안쪽")
    func testBottomSpaceLayoutKeyboardSelectOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()
        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 ~32.5pt로 좁아지고 999가 양보하므로,
        // 이 파일의 다른 테스트들과 같이 지구본을 숨긴 상태에서 검증한다
        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        // 프로덕션은 `viewWillLayoutSubviews`에서 지구본 상태를 반영한 뒤 레이아웃 패스를 돌린다.
        // 오프스크린 뷰는 그 패스가 자동으로 돌지 않으므로 명시적으로 레이아웃을 무효화한다
        view.setNeedsLayout()
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

    @Test("켜짐 상태의 한 손 모드 오버레이는 !#1 위 좌측에 놓임")
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

    @Test("꺼짐 상태의 한 손 모드 오버레이는 !#1 위 우측에 놓임")
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
        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 ~32.5pt로 좁아지고 999가 양보하므로,
        // 이 파일의 다른 테스트들과 같이 지구본을 숨긴 상태에서 검증한다
        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        // 프로덕션은 `viewWillLayoutSubviews`에서 지구본 상태를 반영한 뒤 레이아웃 패스를 돌린다.
        // 오프스크린 뷰는 그 패스가 자동으로 돌지 않으므로 명시적으로 레이아웃을 무효화한다
        view.setNeedsLayout()
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

    @Test("하단 배치에서도 리턴 표시 모드 4종은 스페이스·리턴을 함께 노출",
          arguments: [HangeulKeyboardMode.default, .URL, .emailAddress, .webSearch])
    func testBottomSpaceLayoutReturnVisibleModes(_ mode: HangeulKeyboardMode) {
        let view = Self.makeView(usesBottomSpaceLayout: true)

        // `currentHangeulKeyboardMode`의 초기값이 `.default`이고 `didSet`이
        // `guard oldMode != currentHangeulKeyboardMode`로 시작하므로,
        // `.default`를 그대로 넣으면 레이아웃 갱신이 일어나지 않는다.
        // 다른 모드를 한 번 거쳐 실제 전이를 만든다
        view.currentHangeulKeyboardMode = .twitter
        view.currentHangeulKeyboardMode = mode
        view.layoutIfNeeded()

        #expect(!view.spaceButton.isHidden)
        #expect(!view.returnButton.isHidden)
        #expect(view.secondaryAtButton.isHidden)
        #expect(view.secondarySharpButton.isHidden)
    }

    @Test("하단 배치의 twitter 모드는 리턴 대신 @·#을 2행에 노출")
    func testBottomSpaceLayoutTwitterMode() {
        let view = Self.makeView(usesBottomSpaceLayout: true)

        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(!view.spaceButton.isHidden)
        #expect(view.returnButton.isHidden)
        #expect(!view.secondaryAtButton.isHidden)
        #expect(!view.secondarySharpButton.isHidden)
        // @·#은 리턴이 있던 2행 우측 칸에 그대로 남고 스페이스보다 위에 있다
        #expect(Self.rect(view.secondaryAtButton, in: view).midY
                < Self.rect(view.spaceButton, in: view).midY)
        // 둘은 같은 returnButtonHStackView 안이라 변환 없이 비교한다
        #expect(view.secondaryAtButton.frame.maxX <= view.secondarySharpButton.frame.minX + 0.5)
    }

    @Test("꺼짐 상태의 twitter 모드는 기존처럼 @·#이 스페이스보다 아래")
    func testDefaultLayoutTwitterMode() {
        let view = Self.makeView(usesBottomSpaceLayout: false)

        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(view.returnButton.isHidden)
        #expect(!view.secondaryAtButton.isHidden)
        #expect(Self.rect(view.secondaryAtButton, in: view).midY
                > Self.rect(view.spaceButton, in: view).midY)
    }
}
