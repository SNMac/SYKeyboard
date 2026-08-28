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

    @Test("숫자 키보드 기본 배치는 왼쪽으로 열린다")
    func testNumericDefaultOpensLeft() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric, usesBottomSpaceLayout: false) == .left
        )
    }

    @Test("숫자 키보드 하단 배치는 오른쪽으로 열린다")
    func testNumericBottomSpaceOpensRight() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric, usesBottomSpaceLayout: true) == .right
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

    // 텐키는 SwitchButton을 생성하지 않아 이 분기가 현재 호출되지 않지만,
    // exhaustive switch의 .tenKey 반환값(.left)이 나중에 실제로 연결될 때
    // 회귀를 잡을 수 있도록 검증해 둔다
    @Test("텐키는 하단 배치 플래그와 무관하게 항상 왼쪽",
          arguments: [false, true])
    func testTenKeyAlwaysOpensLeft(_ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .tenKey,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .left
        )
    }
}
