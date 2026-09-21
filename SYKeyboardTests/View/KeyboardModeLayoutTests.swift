//
//  KeyboardModeLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/21/26.
//

import Testing
import UIKit

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 자판 타입(`UIKeyboardType`) 전환 시 이전 모드가 켜 둔 키가 남는 회귀를 막는 테스트.
/// 실기기에서 URL → twitter 전환 시 발견된 버그를 다룬다.
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
}
