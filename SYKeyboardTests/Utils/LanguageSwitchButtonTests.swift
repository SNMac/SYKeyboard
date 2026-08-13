//
//  LanguageSwitchButtonTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Foundation
import Testing

import EnglishKeyboardCore
import HangeulKeyboardCore
import SYKeyboardCore

@MainActor
@Suite("한영 전환 버튼")
struct LanguageSwitchButtonTests {

    @Test("한글 mode는 한 슬래시 active 영 muted")
    func testHangeulModeAttributedRanges() {
        let button = LanguageSwitchButton(mode: .hangeul)

        #expect(button.attributedTitleForCurrentMode.string == "한/영")
        #expect(button.activeTitleRange == NSRange(location: 0, length: 2))
        #expect(button.mutedTitleRange == NSRange(location: 2, length: 1))
    }

    @Test("영어 mode는 한 muted 슬래시 영 active")
    func testEnglishModeAttributedRanges() {
        let button = LanguageSwitchButton(mode: .english)

        #expect(button.attributedTitleForCurrentMode.string == "한/영")
        #expect(button.activeTitleRange == NSRange(location: 1, length: 2))
        #expect(button.mutedTitleRange == NSRange(location: 0, length: 1))
    }

    @Test("SwitchButton은 symbol 복귀 언어를 mode에 맞게 갱신")
    func testSwitchButtonUsesActiveLanguageMode() {
        let button = SwitchButton(keyboard: .symbol)
        button.updatePrimaryLanguageMode(.hangeul)
        #expect(button.titleForCurrentKeyboard == "한글")
        button.updatePrimaryLanguageMode(.english)
        #expect(button.titleForCurrentKeyboard == "ABC")

        let primaryButton = SwitchButton(keyboard: .qwerty)
        primaryButton.updatePrimaryLanguageMode(.hangeul)
        #expect(primaryButton.titleForCurrentKeyboard == "!#1")
        primaryButton.updatePrimaryLanguageMode(.english)
        #expect(primaryButton.titleForCurrentKeyboard == "!#1")
    }

    @Test("한글 adapter는 opt-in view에만 언어 버튼을 제공")
    func testHangeulAdapterLanguageSwitchButtonOptIn() {
        let dedicatedAdapter = HangeulKeyboardInputAdapter(selectedKeyboard: .dubeolsik)
        let unifiedAdapter = HangeulKeyboardInputAdapter(
            selectedKeyboard: .dubeolsik,
            showsLanguageSwitchButton: true
        )

        #expect(dedicatedAdapter.primaryKeyboardView.languageSwitchButton == nil)
        #expect(unifiedAdapter.primaryKeyboardView.languageSwitchButton != nil)
    }

    @Test("영어 adapter는 opt-in view에만 언어 버튼을 제공")
    func testEnglishAdapterLanguageSwitchButtonOptIn() {
        let dedicatedAdapter = EnglishKeyboardInputAdapter()
        let unifiedAdapter = EnglishKeyboardInputAdapter(showsLanguageSwitchButton: true)

        #expect(dedicatedAdapter.primaryKeyboardView.languageSwitchButton == nil)
        #expect(unifiedAdapter.primaryKeyboardView.languageSwitchButton != nil)
    }
}
