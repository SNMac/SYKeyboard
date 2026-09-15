//
//  EnglishKeyboardInputAdapterTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
import SYKeyboardCore

@MainActor
@Suite("영어 입력 어댑터")
struct EnglishKeyboardInputAdapterTests {

    @Test("대문자 입력 후 임시 Shift는 해제")
    func testRecordedUppercaseInputResetsTemporaryShift() {
        let adapter = EnglishKeyboardInputAdapter()
        adapter.primaryKeyboardView.updateShiftButton(to: true)
        adapter.recordInsertedText("A")
        adapter.updateAutocapitalization(
            type: .sentences,
            documentContextBeforeInput: "A",
            isEnabled: true,
            isShiftButtonPressed: false
        )

        #expect(adapter.isShifted == false)
    }

    @Test("언어 전환 종료는 Shift와 caps를 초기화")
    func testFinishForLanguageChangeResetsShiftAndCaps() {
        let adapter = EnglishKeyboardInputAdapter()
        adapter.primaryKeyboardView.updateShiftButton(to: true)

        adapter.finishForLanguageChange()

        #expect(adapter.isShifted == false)
        #expect(adapter.isCapsLocked == false)
    }

    @Test("문장 시작 자동 대문자 정책을 실제 view에 반영")
    func testAutocapitalizationUpdatesProductionView() {
        let adapter = EnglishKeyboardInputAdapter()

        adapter.updateAutocapitalization(
            type: .sentences,
            documentContextBeforeInput: "Hello. ",
            isEnabled: true,
            isShiftButtonPressed: false
        )

        #expect(adapter.isShifted)
    }

    @Test("Shift를 두 번 눌러 caps lock을 켠 채 누르고 글자를 입력한 뒤 떼도 caps lock 유지")
    func testCapsLockHeldWhileTypingStaysLockedAfterRelease() throws {
        let adapter = EnglishKeyboardInputAdapter()
        let shiftButton = try #require(adapter.primaryKeyboardView as? EnglishKeyboardLayoutProvider).shiftButton

        shiftButton.sendActions(for: .touchDown)
        shiftButton.sendActions(for: .touchUpInside)
        shiftButton.sendActions(for: .touchDown)
        shiftButton.sendActions(for: .touchDownRepeat)
        typeLetterWhileShiftPressed("A", adapter: adapter)
        shiftButton.sendActions(for: .touchUpInside)

        #expect(adapter.isCapsLocked)
        #expect(adapter.isShifted)
    }

    @Test("Shift를 한 번 누른 채 글자를 입력한 뒤 떼면 대문자 해제")
    func testShiftHeldWhileTypingReleasesAfterRelease() throws {
        let adapter = EnglishKeyboardInputAdapter()
        let shiftButton = try #require(adapter.primaryKeyboardView as? EnglishKeyboardLayoutProvider).shiftButton

        shiftButton.sendActions(for: .touchDown)
        typeLetterWhileShiftPressed("A", adapter: adapter)
        shiftButton.sendActions(for: .touchUpInside)

        #expect(adapter.isCapsLocked == false)
        #expect(adapter.isShifted == false)
    }
}

/// `EnglishKeyboardCoreViewController.textInteractionDidPerform`이 Shift를 누른 채 글자를 입력했을 때 부르는 순서
@MainActor
private func typeLetterWhileShiftPressed(_ letter: String, adapter: EnglishKeyboardInputAdapter) {
    adapter.recordInsertedText(letter)
    adapter.updateAutocapitalization(
        type: .sentences,
        documentContextBeforeInput: letter,
        isEnabled: true,
        isShiftButtonPressed: true
    )
}
