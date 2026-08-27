//
//  KeyboardSelectDirectionPolicyTests.swift
//  SYKeyboardTests
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 선택 오버레이 방향 정책")
struct KeyboardSelectDirectionPolicyTests {
    @Test("천지인 기본 배치는 왼쪽으로 열린다")
    func testCheonjiinDefaultOpensLeft() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .cheonjiin, usesBottomSpaceLayout: false) == .left
        )
    }

    @Test("천지인 하단 배치는 오른쪽으로 열린다")
    func testCheonjiinBottomSpaceOpensRight() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .cheonjiin, usesBottomSpaceLayout: true) == .right
        )
    }

    @Test("나랏글은 하단 배치 플래그와 무관하게 항상 왼쪽",
          arguments: [false, true])
    func testNaratgeulAlwaysOpensLeft(_ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .naratgeul,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .left
        )
    }

    @Test("숫자 키보드는 하단 배치 플래그와 무관하게 항상 왼쪽",
          arguments: [false, true])
    func testNumericAlwaysOpensLeft(_ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .left
        )
    }

    @Test("두벌식·쿼티·기호는 하단 배치 플래그와 무관하게 항상 오른쪽",
          arguments: [SYKeyboardType.dubeolsik, .qwerty, .symbol], [false, true])
    func testRightOpeningKeyboards(_ keyboard: SYKeyboardType, _ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: keyboard,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .right
        )
    }
}
