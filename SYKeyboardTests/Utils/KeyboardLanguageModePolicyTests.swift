//
//  KeyboardLanguageModePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing
import UIKit

import SYKeyboardCore

@Suite("한영 통합 키보드 시작 언어 정책")
struct KeyboardLanguageModePolicyTests {

    @Test("ASCII를 요구하는 키보드 타입은 라틴 입력으로 판정")
    func testLatinKeyboardTypes() {
        for keyboardType in [
            UIKeyboardType.asciiCapable,
            .asciiCapableNumberPad,
            .emailAddress,
            .URL
        ] {
            #expect(KeyboardLanguageModePolicy.requiresLatinInput(
                keyboardType: keyboardType,
                textContentType: nil
            ))
        }
    }

    @Test("한글 입력이 자연스러운 키보드 타입은 라틴 입력이 아님")
    func testNonLatinKeyboardTypes() {
        // `.alphabet`은 `.asciiCapable`의 deprecated 별칭이라 여기에 넣지 않는다
        for keyboardType in [
            UIKeyboardType.default,
            .webSearch,
            .twitter,
            .namePhonePad,
            .numberPad,
            .numbersAndPunctuation,
            .phonePad,
            .decimalPad
        ] {
            #expect(!KeyboardLanguageModePolicy.requiresLatinInput(
                keyboardType: keyboardType,
                textContentType: nil
            ))
        }
    }

    @Test("계정·주소 관련 contentType은 라틴 입력으로 판정")
    func testLatinTextContentTypes() {
        for contentType in [
            UITextContentType.emailAddress,
            .URL,
            .username,
            .password,
            .newPassword,
            .oneTimeCode,
            .creditCardNumber
        ] {
            #expect(KeyboardLanguageModePolicy.requiresLatinInput(
                keyboardType: .default,
                textContentType: contentType
            ))
        }
    }

    @Test("이름·주소 contentType은 한글일 수 있으므로 라틴 입력이 아님")
    func testAmbiguousTextContentTypesAreNotLatin() {
        for contentType in [
            UITextContentType.name,
            .familyName,
            .givenName,
            .addressCity,
            .fullStreetAddress,
            .jobTitle,
            .organizationName
        ] {
            #expect(!KeyboardLanguageModePolicy.requiresLatinInput(
                keyboardType: .default,
                textContentType: contentType
            ))
        }
    }

    @Test("trait가 없으면 라틴 입력이 아님")
    func testMissingTraitsAreNotLatin() {
        #expect(!KeyboardLanguageModePolicy.requiresLatinInput(
            keyboardType: nil,
            textContentType: nil
        ))
    }

    @Test("라틴 입력을 요구하면 마지막 언어와 무관하게 영어로 시작")
    func testLatinInputOverridesLastMode() {
        for lastMode in [HangeulEnglishLanguageMode.hangeul, .english, nil] as [HangeulEnglishLanguageMode?] {
            #expect(KeyboardLanguageModePolicy.initialMode(
                requiresLatinInput: true,
                lastMode: lastMode,
                preferredLanguages: ["ko-KR"]
            ) == .english)
        }
    }

    @Test("라틴 입력이 아니면 마지막 언어로 시작")
    func testUsesLastModeWhenNotLatin() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: .english,
            preferredLanguages: ["ko-KR"]
        ) == .english)
        #expect(KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: .hangeul,
            preferredLanguages: ["en-US"]
        ) == .hangeul)
    }

    @Test("마지막 언어가 없으면 OS 언어 설정을 따름")
    func testFallsBackToPreferredLanguages() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: nil,
            preferredLanguages: ["ko-KR", "en-US"]
        ) == .hangeul)
        #expect(KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: nil,
            preferredLanguages: ["en-US", "ko-KR"]
        ) == .english)
    }

    @Test("OS 언어가 한국어면 한글, 영어면 영어")
    func testPreferredLanguageMapping() {
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["ko"]) == .hangeul)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["ko-KR"]) == .hangeul)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["ko-Kore-KR"]) == .hangeul)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["en"]) == .english)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["en-GB"]) == .english)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["EN-US"]) == .english)
    }

    @Test("OS 언어가 한국어도 영어도 아니면 한글")
    func testUnsupportedPreferredLanguageUsesHangeul() {
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["ja-JP"]) == .hangeul)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["fr-FR", "de-DE"]) == .hangeul)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: []) == .hangeul)
    }

    @Test("지원하지 않는 언어가 앞서도 뒤의 한국어·영어를 사용")
    func testScansPreferredLanguageOrder() {
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["ja-JP", "en-US"]) == .english)
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: ["fr-FR", "ko-KR"]) == .hangeul)
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
