//
//  KeyboardSafeAreaPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/1/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("키보드 safe area 정책 검증")
struct KeyboardSafeAreaPolicyTests {

    // iPhone Duo 바깥 화면 가로에서 키보드 뷰가 받는 safe area
    @Test("키 영역은 위·좌·우 safe area만 반영하고 아래는 반영하지 않는다")
    func testKeyAreaInsetsIgnoreBottom() {
        let insets = KeyboardSafeAreaPolicy.keyAreaInsets(
            safeAreaInsets: UIEdgeInsets(top: 1, left: 2, bottom: 66, right: 3)
        )

        #expect(insets == UIEdgeInsets(top: 1, left: 2, bottom: 0, right: 3))
    }
}
