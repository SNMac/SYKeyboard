//
//  OneHandedKeyboardWidthPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/5/26.
//

import CoreFoundation
import Testing

@testable import SYKeyboardCore

@Suite("한 손 키보드 최소 폭 정책 검증")
struct OneHandedKeyboardWidthPolicyTests {

    @Test("가용 폭이 충분하면 설정 폭을 그대로 사용")
    func test가용폭충분_설정폭유지() {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: 320,
            availableWidth: 402
        )

        #expect(minWidth == 320)
    }

    @Test("회전 도중 가용 폭이 설정 폭보다 좁으면 가용 폭으로 낮춤")
    func test가용폭부족_가용폭으로제한() {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: 340,
            availableWidth: 300
        )

        #expect(minWidth == 300)
    }

    @Test("가용 폭이 아직 정해지지 않았으면 0으로 제한")
    func test가용폭없음_0으로제한() {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: 320,
            availableWidth: 0
        )

        #expect(minWidth == 0)
    }

    @Test("가용 폭이 음수여도 0 미만으로 내려가지 않음")
    func test가용폭음수_0으로보정() {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: 320,
            availableWidth: -10
        )

        #expect(minWidth == 0)
    }

    @Test("가로 화면처럼 가용 폭이 넓어도 설정 폭을 넘지 않음")
    func test가로화면_설정폭유지() {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: 320,
            availableWidth: 874
        )

        #expect(minWidth == 320)
    }
}
