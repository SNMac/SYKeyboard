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
            availableWidth: CGFloat(availableWidth)
        )

        #expect(minWidth == CGFloat(expected))
    }
}
