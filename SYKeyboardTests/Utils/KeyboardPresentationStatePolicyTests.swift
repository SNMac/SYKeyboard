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
        #expect(
            KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
                isPredictiveTextEnabled: true,
                autocorrectionType: nil,
                currentKeyboard: .qwerty
            ) == false
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

    @Test("undo redo 기능은 자동완성과 undo redo 설정이 모두 켜진 경우에만 활성화")
    func testUndoRedo기능활성화조건() {
        #expect(
            KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable(
                isPredictiveTextEnabled: true,
                isUndoRedoEnabled: true
            ) == true
        )
        #expect(
            KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable(
                isPredictiveTextEnabled: false,
                isUndoRedoEnabled: true
            ) == false
        )
        #expect(
            KeyboardPresentationStatePolicy.isUndoRedoFeatureAvailable(
                isPredictiveTextEnabled: true,
                isUndoRedoEnabled: false
            ) == false
        )
    }
}
