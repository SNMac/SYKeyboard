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

    @Test("저장된 언어가 없는 새 focus는 OS 언어 설정을 따름")
    func testNewFocusWithoutStoredModeUsesPreferredLanguages() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)

        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(NSObject()),
            requiresLatinInput: false,
            lastMode: nil,
            preferredLanguages: ["en-US"]
        ) == .english)
    }

    @Test("trait 변화는 requiresLatinInput이 참이면 영어를 강제")
    func testInputTraitsChangeForcesEnglishWhenLatinRequired() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)

        #expect(coordinator.modeForInputTraitsChange(
            requiresLatinInput: true,
            lastMode: .hangeul,
            preferredLanguages: ["ko-KR"]
        ) == .english)
    }

    @Test("trait 변화는 requiresLatinInput이 거짓이면 마지막 언어를 따름")
    func testInputTraitsChangeFollowsLastModeWhenLatinNotRequired() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .english)

        #expect(coordinator.modeForInputTraitsChange(
            requiresLatinInput: false,
            lastMode: .hangeul,
            preferredLanguages: ["en-US"]
        ) == .hangeul)
    }

    @Test("trait 변화는 마지막 언어가 없으면 OS 언어 설정을 따름")
    func testInputTraitsChangeWithoutStoredModeUsesPreferredLanguages() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)

        #expect(coordinator.modeForInputTraitsChange(
            requiresLatinInput: false,
            lastMode: nil,
            preferredLanguages: ["en-US"]
        ) == .english)
    }

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
