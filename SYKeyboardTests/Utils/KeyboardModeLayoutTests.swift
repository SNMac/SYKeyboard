//
//  KeyboardModeLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/21/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 자판 타입(`UIKeyboardType`) 전환 시 이전 모드가 켜 둔 키·제약이 남는 회귀를 막는 테스트.
/// 실기기에서 URL → twitter, URL → default 전환 시 발견된 버그를 다룬다.
@MainActor
@Suite("자판 모드 전환 시 안 쓰는 키 정리")
struct KeyboardModeLayoutTests {

    private static let frame = CGRect(x: 0, y: 0, width: 390, height: 216)

    private func makeDubeolsikView() -> DubeolsikKeyboardView {
        let view = DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: false
        )
        view.frame = Self.frame
        view.layoutIfNeeded()
        return view
    }

    private func makeEnglishView() -> EnglishKeyboardView {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: false
        )
        view.frame = Self.frame
        view.layoutIfNeeded()
        return view
    }

    private func makeSymbolView() -> SymbolKeyboardView {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false)
        view.frame = Self.frame
        view.layoutIfNeeded()
        return view
    }

    // MARK: - 수정 A: 두벌식에 twitter 레이아웃이 없어 URL 키가 남는 문제

    @Test("두벌식 자판은 URL에서 twitter로 가면 URL 전용 키를 숨긴다")
    func test두벌식_URL에서_twitter로가면_URL키숨김() {
        let view = makeDubeolsikView()

        view.currentHangeulKeyboardMode = .URL
        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(view.atButton.isHidden)
        #expect(view.periodButton.isHidden)
        #expect(view.slashButton.isHidden)
        #expect(view.dotComButton.isHidden)
        #expect(view.returnButton.isHidden)
        #expect(view.secondaryAtButton.isHidden == false)
        #expect(view.secondarySharpButton.isHidden == false)
    }

    @Test("두벌식 URL에서 twitter로 전환한 스페이스 폭은 바로 twitter로 간 경우와 같다")
    func test두벌식_URL에서_twitter로가면_스페이스폭이_직행과같다() {
        let viaURL = makeDubeolsikView()
        viaURL.currentHangeulKeyboardMode = .URL
        viaURL.currentHangeulKeyboardMode = .twitter
        viaURL.layoutIfNeeded()

        let direct = makeDubeolsikView()
        direct.currentHangeulKeyboardMode = .twitter
        direct.layoutIfNeeded()

        #expect(abs(viaURL.spaceButton.frame.width - direct.spaceButton.frame.width) < 0.5)
    }

    // MARK: - 수정 B: URL이 꺼 둔 마침표 키 폭 제약이 default/twitter 복귀 시 되살아나지 않는 문제
    //
    // `periodButton`은 default/twitter에서 숨겨지므로(UIStackView가 숨겨진 arranged
    // subview를 레이아웃에서 제외), 이 테스트 환경(직접 생성한 뷰 + 고정 프레임)에서는
    // 제약이 꺼진 채 남아도 `spaceButton.frame.width` 자체는 바뀌지 않는다. 대신
    // `updateLayoutToDefault()`/`updateLayoutToTwitter()`가 실제로 호출하는
    // `updatePeriodButtonWidthConstraint`의 결과, 즉 `periodButtonWidthConstraint`가
    // 다시 활성화되고 원래 배율(0.2)을 쓰는지를 직접 검증한다.

    @Test("두벌식은 URL을 거쳐 default로 오면 마침표 폭 제약이 되살아난다")
    func test두벌식_URL거쳐_default오면_마침표제약복원() throws {
        let view = makeDubeolsikView()
        view.currentHangeulKeyboardMode = .URL
        view.currentHangeulKeyboardMode = .default
        view.layoutIfNeeded()

        let constraint = try #require(view.periodButtonWidthConstraint)
        #expect(constraint.isActive)
        #expect(abs(constraint.multiplier - 0.2) < 0.001)
    }

    @Test("영어는 URL을 거쳐 default로 오면 마침표 폭 제약이 되살아난다")
    func test영어_URL거쳐_default오면_마침표제약복원() throws {
        let view = makeEnglishView()
        view.currentEnglishKeyboardMode = .URL
        view.currentEnglishKeyboardMode = .default
        view.layoutIfNeeded()

        let constraint = try #require(view.periodButtonWidthConstraint)
        #expect(constraint.isActive)
        #expect(abs(constraint.multiplier - 0.2) < 0.001)
    }

    @Test("영어는 URL을 거쳐 twitter로 오면 마침표 폭 제약이 되살아난다")
    func test영어_URL거쳐_twitter오면_마침표제약복원() throws {
        let view = makeEnglishView()
        view.currentEnglishKeyboardMode = .URL
        view.currentEnglishKeyboardMode = .twitter
        view.layoutIfNeeded()

        let constraint = try #require(view.periodButtonWidthConstraint)
        #expect(constraint.isActive)
        #expect(abs(constraint.multiplier - 0.2) < 0.001)
    }

    @Test("기호 자판은 URL을 거쳐 default로 오면 마침표 폭 제약이 되살아난다")
    func test기호_URL거쳐_default오면_마침표제약복원() throws {
        let view = makeSymbolView()
        view.currentSymbolKeyboardMode = .URL
        view.currentSymbolKeyboardMode = .default
        view.layoutIfNeeded()

        let constraint = try #require(view.periodButtonWidthConstraint)
        #expect(constraint.isActive)
        #expect(abs(constraint.multiplier - 0.2) < 0.001)
    }

    @Test("바로 default/twitter로 간 경우는 애초에 마침표 제약이 살아있다 (대조군)")
    func test직행_마침표제약_대조군() throws {
        let dubeolsik = makeDubeolsikView()
        let english = makeEnglishView()
        let symbol = makeSymbolView()

        #expect(try #require(dubeolsik.periodButtonWidthConstraint).isActive)
        #expect(try #require(english.periodButtonWidthConstraint).isActive)
        #expect(try #require(symbol.periodButtonWidthConstraint).isActive)
    }
}
