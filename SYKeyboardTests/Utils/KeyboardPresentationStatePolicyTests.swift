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
            selectedText: nil,
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
                selectedText: nil,
                documentContextAfterInput: nil
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: "가",
                selectedText: nil,
                documentContextAfterInput: nil
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: nil,
                selectedText: nil,
                documentContextAfterInput: "나"
            ) == true
        )
    }

    @Test("return 자동 활성화가 켜져 있으면 선택된 텍스트만 있어도 활성화")
    func testReturn자동활성화켜짐_선택텍스트존재시활성화() {
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: nil,
                selectedText: "전체 선택",
                documentContextAfterInput: nil
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: "",
                selectedText: " ",
                documentContextAfterInput: ""
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: true,
                documentContextBeforeInput: "",
                selectedText: "",
                documentContextAfterInput: ""
            ) == false
        )
    }

    @Test("텐키이거나 바 안에 쓸 수 있는 것이 없으면 suggestion bar를 숨김")
    func testSuggestionBar숨김조건() {
        // 텐키는 무엇이 켜져 있어도 숨긴다
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .default,
                currentKeyboard: .tenKey,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: true
            ) == true
        )
        // 셋 다 쓸 수 없으면 숨긴다
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: false,
                autocorrectionType: .default,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: false
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: false
            ) == true
        )
        // 후보 영역만 쓸 수 있어도 표시한다
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .default,
                currentKeyboard: .qwerty,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: nil,
                currentKeyboard: .qwerty,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: false
            ) == false
        )
    }

    @Test("자동완성이 꺼져 있어도 undo redo나 클립보드가 켜져 있으면 suggestion bar를 유지")
    func testSuggestionBar자동완성꺼짐시표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: false,
                autocorrectionType: .default,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: false,
                autocorrectionType: .default,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: true
            ) == false
        )
        // 텐키는 예외 없이 숨긴다
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: false,
                autocorrectionType: .default,
                currentKeyboard: .tenKey,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: true
            ) == true
        )
    }

    @Test("autocorrection이 no여도 undo redo나 클립보드가 켜져 있으면 suggestion bar를 유지")
    func testSuggestionBarAutocorrection차단시표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: false,
                isClipboardHistoryEnabled: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .naratgeul,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: .no,
                currentKeyboard: .tenKey,
                isUndoRedoEnabled: true,
                isClipboardHistoryEnabled: true
            ) == true
        )
    }

    @Test("후보 영역은 바가 숨겨졌거나 자동완성이 꺼졌거나 autocorrection이 no일 때 숨김")
    func testSuggestionButtons숨김조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
                isSuggestionBarHidden: false,
                isPredictiveTextEnabled: true,
                autocorrectionType: .default
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
                isSuggestionBarHidden: false,
                isPredictiveTextEnabled: true,
                autocorrectionType: nil
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
                isSuggestionBarHidden: false,
                isPredictiveTextEnabled: true,
                autocorrectionType: .no
            ) == true
        )
        // 바가 보여도 자동완성이 꺼져 있으면 후보 영역은 비운다
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
                isSuggestionBarHidden: false,
                isPredictiveTextEnabled: false,
                autocorrectionType: .default
            ) == true
        )
        // 바가 숨겨졌으면 나머지와 무관하게 숨김
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionButtons(
                isSuggestionBarHidden: true,
                isPredictiveTextEnabled: true,
                autocorrectionType: .default
            ) == true
        )
    }

    @Test("undo redo controls는 suggestion bar가 보이고 기능이 활성화된 경우에만 표시")
    func testUndoRedoControls표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
                isSuggestionBarHidden: false,
                isUndoRedoFeatureAvailable: true
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
                isSuggestionBarHidden: true,
                isUndoRedoFeatureAvailable: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
                isSuggestionBarHidden: false,
                isUndoRedoFeatureAvailable: false
            ) == false
        )
    }

    @Test("클립보드 버튼은 suggestion bar가 보이고 클립보드 기록 설정이 켜진 경우에만 표시")
    func test클립보드버튼표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: false,
                isClipboardHistoryEnabled: true
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: true,
                isClipboardHistoryEnabled: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: false,
                isClipboardHistoryEnabled: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowClipboardControl(
                isSuggestionBarHidden: true,
                isClipboardHistoryEnabled: false
            ) == false
        )
    }

    @Test("수식 결과는 사용자 설정과 host 허용 상태가 모두 켜진 경우에만 표시")
    func test수식결과표시조건() {
        #expect(
            KeyboardPresentationStatePolicy.shouldShowMathResults(
                isSettingEnabled: true,
                isHostCompletionAllowed: true
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowMathResults(
                isSettingEnabled: false,
                isHostCompletionAllowed: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowMathResults(
                isSettingEnabled: true,
                isHostCompletionAllowed: false
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.shouldShowMathResults(
                isSettingEnabled: false,
                isHostCompletionAllowed: false
            ) == false
        )
    }
}
