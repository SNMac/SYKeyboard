//
//  KeyboardLanguageModePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing

import SYKeyboardCore

@Suite("한영 통합 키보드 시작 언어 정책")
struct KeyboardLanguageModePolicyTests {

    @Test("document 언어가 저장값보다 우선")
    func testDocumentLanguageOverridesLastMode() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: "ko-KR",
            lastMode: .english
        ) == .hangeul)
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: "en-US",
            lastMode: .hangeul
        ) == .english)
    }

    @Test("nil mul 기타 언어는 마지막 mode로 fallback")
    func testUnsupportedDocumentLanguageUsesLastMode() {
        for language in [nil, "", "mul", "ja-JP"] as [String?] {
            #expect(KeyboardLanguageModePolicy.initialMode(
                documentPrimaryLanguage: language,
                lastMode: .english
            ) == .english)
        }
    }

    @Test("hint와 저장값이 없으면 한글")
    func testDefaultModeIsHangeul() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: nil,
            lastMode: nil
        ) == .hangeul)
    }

    @Test("각 mode는 입력 언어 식별자를 제공")
    func testLanguageIdentifiers() {
        #expect(HangeulEnglishLanguageMode.hangeul.languageIdentifier == "ko-KR")
        #expect(HangeulEnglishLanguageMode.english.languageIdentifier == "en-US")
    }

    @Test("수동 전환은 숫자·기호 화면에서도 문자 키보드로 돌아감")
    func testManualSwitchAlwaysReturnsToPrimaryKeyboard() {
        for keyboard in [SYKeyboardType.symbol, .numeric, .tenKey, .dubeolsik, .qwerty] {
            #expect(KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
                isManualSwitch: true,
                currentKeyboard: keyboard
            ))
        }
    }

    @Test("자동 전환은 숫자·기호 화면을 유지")
    func testAutomaticSwitchKeepsSymbolAndNumericKeyboard() {
        for keyboard in [SYKeyboardType.symbol, .numeric, .tenKey] {
            #expect(!KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
                isManualSwitch: false,
                currentKeyboard: keyboard
            ))
        }
    }

    @Test("자동 전환이라도 문자 화면이면 새 언어의 문자 키보드로 갱신")
    func testAutomaticSwitchUpdatesPrimaryKeyboard() {
        for keyboard in [SYKeyboardType.naratgeul, .cheonjiin, .dubeolsik, .qwerty] {
            #expect(KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
                isManualSwitch: false,
                currentKeyboard: keyboard
            ))
        }
    }
}
