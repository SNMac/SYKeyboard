//
//  KeyboardPresentationStatePolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("키보드 표시 상태 정책 검증")
struct KeyboardPresentationStatePolicyTests {

    @Test("return 자동 활성화가 꺼져 있으면 문맥과 무관하게 활성화")
    func testReturn자동활성화꺼짐_항상활성화() {
        let isEnabled = KeyboardPresentationStatePolicy.isReturnButtonEnabled(
            enablesReturnKeyAutomatically: false,
            documentContextBeforeInput: nil,
            documentContextAfterInput: nil
        )

        #expect(isEnabled == true)
    }

    @Test("return 자동 활성화가 켜져 있으면 커서 앞뒤 텍스트가 있을 때만 활성화")
    func testReturn자동활성화켜짐_문맥텍스트존재시활성화() {
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: nil,
                documentContextAfterInput: nil
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: "가",
                documentContextAfterInput: nil
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: nil,
                documentContextAfterInput: "나"
            ) == true
        )
    }

    @Test("자동완성이 꺼졌거나 autocorrection이 no이거나 tenKey이면 suggestion bar를 숨김")
    func testSuggestionBar숨김조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: false,
                autocorrectionType: .default,
                currentKeyboard: .naratgeul
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .naratgeul
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .default,
                currentKeyboard: .tenKey
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .default,
                currentKeyboard: .qwerty
            ) == false
        )
    }
}
