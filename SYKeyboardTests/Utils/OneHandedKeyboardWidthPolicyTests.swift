//
//  OneHandedKeyboardWidthPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/14/26.
//

import CoreFoundation
import Testing

@testable import SYKeyboardCore

@Suite("한 손 키보드 너비 정책 검증")
struct OneHandedKeyboardWidthPolicyTests {

    @Test("중앙 모드에서는 고정 너비를 적용하지 않음")
    func test중앙모드_고정너비미적용() {
        let width = KeyboardPresentationStatePolicy.oneHandedKeyboardFixedWidth(
            configuredWidth: 320,
            availableWidth: 390,
            accessoryWidth: 30,
            isOneHandedMode: false
        )

        #expect(width == nil)
    }

    @Test("한 손 모드에서 가용 폭이 충분하면 설정 너비를 적용")
    func test한손모드_설정너비적용() {
        let width = KeyboardPresentationStatePolicy.oneHandedKeyboardFixedWidth(
            configuredWidth: 320,
            availableWidth: 390,
            accessoryWidth: 30,
            isOneHandedMode: true
        )

        #expect(width == 320)
    }

    @Test("한 손 모드에서 가용 폭이 좁으면 accessory 공간을 제외한 폭으로 제한")
    func test한손모드_가용너비제한() {
        let width = KeyboardPresentationStatePolicy.oneHandedKeyboardFixedWidth(
            configuredWidth: 340,
            availableWidth: 320,
            accessoryWidth: 30,
            isOneHandedMode: true
        )

        #expect(width == 290)
    }

    @Test("가로 화면의 한 손 모드에서도 설정 너비를 적용")
    func test가로화면_한손모드_설정너비적용() {
        let width = KeyboardPresentationStatePolicy.oneHandedKeyboardFixedWidth(
            configuredWidth: 320,
            availableWidth: 844,
            accessoryWidth: 30,
            isOneHandedMode: true
        )

        #expect(width == 320)
    }
}
