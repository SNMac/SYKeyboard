//
//  HangeulEnglishKeyboardModeCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Foundation
import Testing

import SYKeyboardCore

@Suite("한영 통합 키보드 mode coordinator")
struct HangeulEnglishKeyboardModeCoordinatorTests {

    @Test("새 focus만 필드 trait로 시작 mode를 다시 판정")
    func testNewFocusReevaluatesFieldTrait() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)
        let first = NSObject()
        let second = NSObject()

        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first),
            requiresLatinInput: true,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .english)

        coordinator.selectModeManually(.hangeul)

        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first),
            requiresLatinInput: true,
            lastMode: .english,
            preferredLanguages: ["ko-KR"]
        ) == .hangeul)
        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(second),
            requiresLatinInput: true,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .english)
    }

    @Test("nil identifier는 현재 mode를 유지")
    func testNilIdentifierDoesNotForceMode() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .english)

        #expect(coordinator.modeForTextInputChange(
            identifier: nil,
            requiresLatinInput: false,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .english)
    }

    // 시작 언어 판정 규칙(라틴 입력·마지막 언어·OS 언어)은 KeyboardLanguageModePolicyTests가 소유한다.
    // 여기서는 Policy를 올바른 입력으로 불러 결과가 달라지는 것만 본다 (docs/adr/0003)
    @Test("trait 변화 재판정은 호출마다 반복되며 이전 focus 식별자에 의존하지 않음")
    func testInputTraitsChangeReevaluatesOnEveryCall() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)

        #expect(coordinator.modeForInputTraitsChange(
            requiresLatinInput: true,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .english)
        #expect(coordinator.modeForInputTraitsChange(
            requiresLatinInput: false,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .hangeul)
    }
}
