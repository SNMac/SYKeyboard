//
//  BottomSpaceLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 이 파일의 세 suite가 같은 키보드 크기·자판 생성·좌표 변환을 쓰게 한다
@MainActor
private protocol BottomSpaceLayoutTesting {}

extension BottomSpaceLayoutTesting {
    static var keyboardWidth: CGFloat { 390 }
    static var keyboardHeight: CGFloat { 216 }

    static func makeCheonjiinView(usesBottomSpaceLayout: Bool) -> CheonjiinKeyboardView {
        layOut(CheonjiinKeyboardView(showsLanguageSwitchButton: true,
                                     usesBottomSpaceLayout: usesBottomSpaceLayout,
                                     showsNumberRow: false))
    }

    static func makeNumericView(usesBottomSpaceLayout: Bool) -> NumericKeyboardView {
        layOut(NumericKeyboardView(showsLanguageSwitchButton: true,
                                   usesBottomSpaceLayout: usesBottomSpaceLayout))
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 `midY`가 전부 같다.
    /// 행을 가로질러 비교하려면 키보드 뷰 좌표계로 변환해야 한다
    static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    private static func layOut<View: NormalKeyboardLayoutProvider>(_ view: View) -> View {
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        return view
    }
}

@MainActor
@Suite("스페이스 하단 배치 공통 동작")
struct BottomSpaceLayoutTests: BottomSpaceLayoutTesting {
    /// 스페이스 하단 배치를 지원하는 두 자판
    enum Fixture: CustomTestStringConvertible {
        case cheonjiin
        case numeric

        var testDescription: String {
            switch self {
            case .cheonjiin: return "천지인"
            case .numeric: return "숫자 키패드"
            }
        }

        /// controller처럼 프로토콜 타입으로 다룬다. 한/영 버튼은 주 자판·숫자 프로토콜에 따로 있어 함께 돌려준다
        @MainActor
        func makeView(usesBottomSpaceLayout: Bool)
        -> (view: NormalKeyboardLayoutProvider, languageSwitchButton: LanguageSwitchButton?) {
            switch self {
            case .cheonjiin:
                let view = BottomSpaceLayoutTests.makeCheonjiinView(usesBottomSpaceLayout: usesBottomSpaceLayout)
                return (view, view.languageSwitchButton)
            case .numeric:
                let view = BottomSpaceLayoutTests.makeNumericView(usesBottomSpaceLayout: usesBottomSpaceLayout)
                return (view, view.languageSwitchButton)
            }
        }
    }

    /// 지구본을 숨겨 modifier 스택에 한/영과 전환 버튼 2개만 남긴다
    @MainActor
    private static func hideNextKeyboardButton(_ view: NormalKeyboardLayoutProvider) {
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()
    }

    @Test("꺼짐 상태는 스페이스가 리턴보다 위, 전환 버튼이 우측 끝",
          arguments: [Fixture.cheonjiin, .numeric])
    func testDefaultLayoutKeepsSpaceAboveReturn(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: false)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(space.midY < returnRect.midY)
        #expect(returnRect.midY < switchRect.midY)
        // 꺼짐 배치의 modifier 스택은 4행 우측 끝에 붙는다
        #expect(abs(switchRect.maxX - Self.keyboardWidth) < 0.5)
    }

    @Test("켜짐 상태는 리턴이 스페이스보다 위, 스페이스가 전환 버튼과 같은 행",
          arguments: [Fixture.cheonjiin, .numeric])
    func testBottomSpaceLayoutMovesSpaceToLastRow(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: true)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(returnRect.midY < space.midY)
        #expect(abs(space.midY - switchRect.midY) < 0.5)
        #expect(switchRect.maxX <= space.minX + 0.5)
        // 켜짐 배치의 modifier 스택은 4행 좌측 끝에 붙는다
        #expect(abs(switchRect.minX) < 0.5)
    }

    /// 기본 배치의 균등 분할은 `FourColumnKeyboardColumnWidthTests`가 검증한다
    @Test("켜짐 상태에서도 삭제·스페이스 버튼이 한 칸 폭을 유지",
          arguments: [Fixture.cheonjiin, .numeric])
    func testBottomSpaceLayoutKeepsDeleteAndSpaceSingleColumnWidth(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: true)
        let columnWidth = Self.keyboardWidth / 4

        // 폭은 좌표계와 무관하므로 변환이 필요 없다.
        // 스페이스가 4행으로 내려가도 삭제(1행)와 같은 한 칸 폭을 유지하는지 확인한다
        #expect(abs(view.deleteButton.frame.width - columnWidth) < 0.5)
        #expect(abs(view.spaceButton.frame.width - columnWidth) < 0.5)
    }

    /// 두 버튼의 폭은 `KeyboardModifierLayoutTests`의 지구본 숨김 arguments 테스트가 검증한다
    @Test("켜짐 상태에서 지구본을 숨기면 전환 버튼이 한/영 왼쪽에 놓임",
          arguments: [Fixture.cheonjiin, .numeric])
    func testBottomSpaceLayoutHiddenGlobeModifierOrder(fixture: Fixture) throws {
        let (view, languageSwitchButton) = fixture.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(languageSwitchButton)

        Self.hideNextKeyboardButton(view)

        // 좌→우 전환 → 한/영
        #expect(Self.rect(view.switchButton, in: view).maxX <= Self.rect(languageButton, in: view).minX + 0.5)
    }

    @Test("켜짐 상태의 키보드 선택 오버레이는 좌측에서 시작하고 취소 경계가 전환 버튼 우측 모서리 안쪽",
          arguments: [Fixture.cheonjiin, .numeric])
    func testBottomSpaceLayoutKeyboardSelectOverlayAnchors(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: true)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()
        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 ~32.5pt로 좁아지고 999가 양보하므로 숨긴다
        Self.hideNextKeyboardButton(view)

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

    @Test("켜짐 상태의 한 손 모드 오버레이는 전환 버튼 위 좌측에 놓임",
          arguments: [Fixture.cheonjiin, .numeric])
    func testBottomSpaceLayoutOneHandedOverlayAnchors(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: true)
        view.oneHandedModeSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        let overlay = view.oneHandedModeSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.minX - 4) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)
        #expect(abs(overlay.frame.width - KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth) < 0.5)
    }

    @Test("꺼짐 상태의 한 손 모드 오버레이는 전환 버튼 위 우측에 놓임",
          arguments: [Fixture.cheonjiin, .numeric])
    func testDefaultLayoutOneHandedOverlayAnchors(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: false)
        view.oneHandedModeSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        let overlay = view.oneHandedModeSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.maxX - (Self.keyboardWidth - 4)) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)
        #expect(abs(overlay.frame.width - KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth) < 0.5)
    }

    @Test("꺼짐 상태의 오버레이는 기존처럼 우측 정렬을 유지",
          arguments: [Fixture.cheonjiin, .numeric])
    func testDefaultLayoutOverlayKeepsTrailingAnchor(fixture: Fixture) {
        let (view, _) = fixture.makeView(usesBottomSpaceLayout: false)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()
        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 ~32.5pt로 좁아지고 999가 양보하므로 숨긴다
        Self.hideNextKeyboardButton(view)

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

@MainActor
@Suite("천지인 스페이스 하단 배치 고유 동작")
struct CheonjiinBottomSpaceLayoutTests: BottomSpaceLayoutTesting {
    @Test("켜짐 상태의 리턴은 2행, 물음표·느낌표는 3행, 마침표·쉼표는 4행")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: true)
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
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: false)
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

    @Test("켜짐 상태에서 지구본이 보이면 modifier 세 버튼이 균등 분배")
    func testBottomSpaceLayoutEqualModifierDistributionWithGlobe() throws {
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: true)
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
        // 좌→우 전환 → 한/영 → 🌐
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX + 0.5)
    }

    @Test("하단 배치에서도 리턴 표시 모드 4종은 스페이스·리턴을 함께 노출",
          arguments: [HangeulKeyboardMode.default, .URL, .emailAddress, .webSearch])
    func testBottomSpaceLayoutReturnVisibleModes(_ mode: HangeulKeyboardMode) {
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: true)

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
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: true)

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
        let view = Self.makeCheonjiinView(usesBottomSpaceLayout: false)

        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(view.returnButton.isHidden)
        #expect(!view.secondaryAtButton.isHidden)
        #expect(Self.rect(view.secondaryAtButton, in: view).midY
                > Self.rect(view.spaceButton, in: view).midY)
    }
}

@MainActor
@Suite("숫자 키패드 스페이스 하단 배치 고유 동작")
struct NumericBottomSpaceLayoutTests: BottomSpaceLayoutTesting {
    /// `numericKeyList[3]`의 문장부호 버튼을 표시 문자로 찾는다
    @MainActor
    private static func keyButton(_ key: String, in view: NumericKeyboardView) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }

        return try #require(keyButtons.first { $0.type.primaryKeyList.first == key })
    }

    @Test("켜짐 상태는 '-'·'/'가 3행 우측, '.'·','가 4행 끝")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeNumericView(usesBottomSpaceLayout: true)
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
        let view = Self.makeNumericView(usesBottomSpaceLayout: false)
        let hyphen = Self.rect(try Self.keyButton("-", in: view), in: view)
        let comma = Self.rect(try Self.keyButton(",", in: view), in: view)
        let zero = Self.rect(try Self.keyButton("0", in: view), in: view)
        let period = Self.rect(try Self.keyButton(".", in: view), in: view)
        let slash = Self.rect(try Self.keyButton("/", in: view), in: view)
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
}
