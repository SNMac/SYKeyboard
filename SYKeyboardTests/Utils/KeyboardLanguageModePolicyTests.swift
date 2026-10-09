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

    @Test("ASCII를 요구하는 키보드 타입과 계정·주소 contentType만 라틴 입력으로 판정하고 나머지는 라틴 입력이 아님",
          arguments: [
            // (keyboardType, textContentType, requiresLatinInput)
            // ASCII를 요구하는 키보드 타입은 라틴 입력으로 판정
            (UIKeyboardType?.some(.asciiCapable), UITextContentType?.none, true),
            (.asciiCapableNumberPad, nil, true),
            (.emailAddress, nil, true),
            (.URL, nil, true),
            // 한글 입력이 자연스러운 키보드 타입은 라틴 입력이 아님.
            // `.alphabet`은 `.asciiCapable`의 deprecated 별칭이라 여기에 넣지 않는다
            (.default, nil, false),
            (.webSearch, nil, false),
            (.twitter, nil, false),
            (.namePhonePad, nil, false),
            (.numberPad, nil, false),
            (.numbersAndPunctuation, nil, false),
            (.phonePad, nil, false),
            (.decimalPad, nil, false),
            // 계정·주소 관련 contentType은 라틴 입력으로 판정
            (.default, .emailAddress, true),
            (.default, .URL, true),
            (.default, .username, true),
            (.default, .password, true),
            (.default, .newPassword, true),
            (.default, .oneTimeCode, true),
            (.default, .creditCardNumber, true),
            // 이름·주소 contentType은 한글일 수 있으므로 라틴 입력이 아님
            (.default, .name, false),
            (.default, .familyName, false),
            (.default, .givenName, false),
            (.default, .addressCity, false),
            (.default, .fullStreetAddress, false),
            (.default, .jobTitle, false),
            (.default, .organizationName, false),
            // trait가 없으면 라틴 입력이 아님
            (nil, nil, false)
          ])
    func testRequiresLatinInput(
        keyboardType: UIKeyboardType?,
        textContentType: UITextContentType?,
        requiresLatinInput: Bool
    ) {
        #expect(KeyboardLanguageModePolicy.requiresLatinInput(
            keyboardType: keyboardType,
            textContentType: textContentType
        ) == requiresLatinInput)
    }

    @Test("시작 언어는 라틴 입력 요구 → 마지막 언어 → OS 언어 순으로 정함",
          arguments: [
            // (requiresLatinInput, lastMode, preferredLanguages, initialMode)
            // 라틴 입력을 요구하면 마지막 언어와 무관하게 영어로 시작
            (true, HangeulEnglishLanguageMode?.some(.hangeul), ["ko-KR"], HangeulEnglishLanguageMode.english),
            (true, .english, ["ko-KR"], .english),
            (true, nil, ["ko-KR"], .english),
            // 라틴 입력이 아니면 마지막 언어로 시작
            (false, .english, ["ko-KR"], .english),
            (false, .hangeul, ["en-US"], .hangeul),
            // 마지막 언어가 없으면 OS 언어 설정을 따름
            (false, nil, ["ko-KR", "en-US"], .hangeul),
            (false, nil, ["en-US", "ko-KR"], .english)
          ])
    func testInitialMode(
        requiresLatinInput: Bool,
        lastMode: HangeulEnglishLanguageMode?,
        preferredLanguages: [String],
        initialMode: HangeulEnglishLanguageMode
    ) {
        #expect(KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: requiresLatinInput,
            lastMode: lastMode,
            preferredLanguages: preferredLanguages
        ) == initialMode)
    }

    @Test("OS 언어 목록에서 처음 만나는 한국어·영어를 따르고 둘 다 없으면 한글",
          arguments: [
            // (preferredLanguages, mode)
            // OS 언어가 한국어면 한글, 영어면 영어
            (["ko"], HangeulEnglishLanguageMode.hangeul),
            (["ko-KR"], .hangeul),
            (["ko-Kore-KR"], .hangeul),
            (["en"], .english),
            (["en-GB"], .english),
            (["EN-US"], .english),
            // OS 언어가 한국어도 영어도 아니면 한글
            (["ja-JP"], .hangeul),
            (["fr-FR", "de-DE"], .hangeul),
            ([], .hangeul),
            // 지원하지 않는 언어가 앞서도 뒤의 한국어·영어를 사용
            (["ja-JP", "en-US"], .english),
            (["fr-FR", "ko-KR"], .hangeul)
          ])
    func testPreferredLanguageMapping(preferredLanguages: [String], mode: HangeulEnglishLanguageMode) {
        #expect(KeyboardLanguageModePolicy.mode(forPreferredLanguages: preferredLanguages) == mode)
    }

    @Test("수동 전환은 항상 문자 키보드로 돌아가고 자동 전환은 문자 화면일 때만 갱신",
          arguments: [
            // (isManualSwitch, currentKeyboard, shouldReturnToPrimaryKeyboard)
            // 수동 전환은 숫자·기호 화면에서도 문자 키보드로 돌아감
            (true, SYKeyboardType.symbol, true),
            (true, .numeric, true),
            (true, .tenKey, true),
            (true, .dubeolsik, true),
            (true, .qwerty, true),
            // 자동 전환은 숫자·기호 화면을 유지
            (false, .symbol, false),
            (false, .numeric, false),
            (false, .tenKey, false),
            // 자동 전환이라도 문자 화면이면 새 언어의 문자 키보드로 갱신
            (false, .naratgeul, true),
            (false, .cheonjiin, true),
            (false, .dubeolsik, true),
            (false, .qwerty, true)
          ])
    func testShouldReturnToPrimaryKeyboard(
        isManualSwitch: Bool,
        currentKeyboard: SYKeyboardType,
        shouldReturnToPrimaryKeyboard: Bool
    ) {
        #expect(KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
            isManualSwitch: isManualSwitch,
            currentKeyboard: currentKeyboard
        ) == shouldReturnToPrimaryKeyboard)
    }
}
