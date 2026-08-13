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
        adapter.updateShiftAfterInput(isShiftButtonPressed: false)

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
}
