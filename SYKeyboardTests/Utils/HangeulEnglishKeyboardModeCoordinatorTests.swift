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

    @Test("새 focus만 document hint로 시작 mode를 다시 판정")
    func testNewFocusReevaluatesLanguageHint() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)
        let first = NSObject()
        let second = NSObject()

        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first),
            documentPrimaryLanguage: "en-US",
            lastMode: .hangeul
        ) == .english)

        coordinator.selectModeManually(.hangeul)

        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first),
            documentPrimaryLanguage: "en-US",
            lastMode: .english
        ) == .hangeul)
        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(second),
            documentPrimaryLanguage: "en-US",
            lastMode: .hangeul
        ) == .english)
    }

    @Test("nil identifier는 현재 mode를 유지")
    func testNilIdentifierDoesNotForceMode() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .english)

        #expect(coordinator.modeForTextInputChange(
            identifier: nil,
            documentPrimaryLanguage: "ko-KR",
            lastMode: .hangeul
        ) == .english)
    }
}
