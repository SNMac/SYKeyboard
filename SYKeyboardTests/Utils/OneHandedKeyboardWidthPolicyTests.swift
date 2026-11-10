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

    // 가용 폭 충분 / 회전 도중 가용 폭 부족 / 가용 폭 미정(0) / 음수 가용 폭
    @Test("최소 폭은 설정 폭을 넘지 않고 가용 폭과 0 사이로 제한",
          arguments: [(320, 402, 320), (340, 300, 300), (320, 0, 0), (320, -10, 0)])
    func test최소폭_가용폭범위로제한(configuredWidth: Int, availableWidth: Int, expected: Int) {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: CGFloat(configuredWidth),
            availableWidth: CGFloat(availableWidth),
            isSplitConditionMet: false
        )

        #expect(minWidth == CGFloat(expected))
    }

    // 안쪽 화면 가로(801)는 접히는 선까지 400.5라 설정 범위(300~340)에서는 걸리지 않는다 / 경계 / 접히는 선을 넘는 폭
    @Test("분할 조건에서는 가장자리에서 접히는 선(가용 폭의 절반)까지로 제한",
          arguments: [(340, 801, 340), (400, 800, 400), (420, 800, 400)])
    func test최소폭_분할조건_접히는선까지(configuredWidth: Int, availableWidth: Int, expected: Int) {
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: CGFloat(configuredWidth),
            availableWidth: CGFloat(availableWidth),
            isSplitConditionMet: true
        )

        #expect(minWidth == CGFloat(expected))
    }
}
