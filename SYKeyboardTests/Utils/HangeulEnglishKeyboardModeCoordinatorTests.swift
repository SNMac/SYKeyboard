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
}
