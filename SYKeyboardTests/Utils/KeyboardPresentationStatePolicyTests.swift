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

    @Test("return 자동 활성화가 꺼져 있으면 항상 활성화하고, 켜져 있으면 커서 앞뒤 텍스트나 선택 텍스트가 있을 때만 활성화",
          arguments: [
            // (enablesReturnKeyAutomatically, before, selectedText, after, isEnabled)
            // 자동 활성화가 꺼져 있으면 문맥과 무관하게 활성화
            (false, String?.none, String?.none, String?.none, true),
            // 자동 활성화가 켜져 있으면 커서 앞뒤 텍스트가 있을 때만 활성화
            (true, nil, nil, nil, false),
            (true, "가", nil, nil, true),
            (true, nil, nil, "나", true),
            // 자동 활성화가 켜져 있으면 선택된 텍스트만 있어도 활성화
            (true, nil, "전체 선택", nil, true),
            (true, "", " ", "", true),
            (true, "", "", "", false)
          ])
    func testReturn버튼활성화조건(
        enablesReturnKeyAutomatically: Bool,
        before: String?,
        selectedText: String?,
        after: String?,
        isEnabled: Bool
    ) {
        #expect(
            KeyboardPresentationStatePolicy.isReturnButtonEnabled(
                enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
                documentContextBeforeInput: before,
                selectedText: selectedText,
                documentContextAfterInput: after
            ) == isEnabled
        )
    }

    @Test("텐키이거나 후보·undo redo·클립보드 모두 쓸 수 없을 때만 suggestion bar를 숨김",
          arguments: [
            // (predictive, autocorrection, keyboard, undoRedo, clipboard, isHidden)
            // 텐키는 무엇이 켜져 있어도 숨긴다
            (true, UITextAutocorrectionType?.some(.default), SYKeyboardType.tenKey, true, true, true),
            // 셋 다 쓸 수 없으면 숨긴다
            (false, .default, .naratgeul, false, false, true),
            (true, .no, .naratgeul, false, false, true),
            // 후보 영역만 쓸 수 있어도 표시한다
            (true, .default, .qwerty, false, false, false),
            (true, nil, .qwerty, false, false, false),
            // 자동완성이 꺼져 있어도 undo redo나 클립보드가 켜져 있으면 유지한다
            (false, .default, .naratgeul, true, false, false),
            (false, .default, .naratgeul, false, true, false),
            // 텐키는 예외 없이 숨긴다
            (false, .default, .tenKey, true, true, true),
            // autocorrection이 no여도 undo redo나 클립보드가 켜져 있으면 유지한다
            (true, .no, .naratgeul, true, false, false),
            (true, .no, .naratgeul, false, true, false),
            (true, .no, .naratgeul, true, true, false),
            (true, .no, .tenKey, true, true, true)
          ])
    func testSuggestionBar숨김조건(
        predictive: Bool,
        autocorrection: UITextAutocorrectionType?,
        keyboard: SYKeyboardType,
        undoRedo: Bool,
        clipboard: Bool,
        isHidden: Bool
    ) {
        #expect(
            hidesBar(
                predictive: predictive,
                autocorrection: autocorrection,
                keyboard: keyboard,
                undoRedo: undoRedo,
                clipboard: clipboard
            ) == isHidden
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

    // MARK: - Helper

    private func hidesBar(
        predictive: Bool,
        autocorrection: UITextAutocorrectionType?,
        keyboard: SYKeyboardType,
        undoRedo: Bool,
        clipboard: Bool
    ) -> Bool {
        KeyboardPresentationStatePolicy.shouldHideSuggestionBar(
            isPredictiveTextEnabled: predictive,
            autocorrectionType: autocorrection,
            currentKeyboard: keyboard,
            isUndoRedoEnabled: undoRedo,
            isClipboardHistoryEnabled: clipboard
        )
    }
}
