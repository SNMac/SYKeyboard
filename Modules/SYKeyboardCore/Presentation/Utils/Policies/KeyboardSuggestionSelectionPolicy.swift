//
//  KeyboardSuggestionSelectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/1/26.
//

import Foundation

enum KeyboardSuggestionSelectionPolicy {

    /// 자동완성 후보 삭제 확인을 띄우는 길게 누르기 시간
    ///
    /// 사용자 설정 `longPressDuration`과 별개인 고정값이다. 실기기 확인 결과 0.7초는
    /// 길게 느껴져 0.5초로 조정했다. 후보를 가로로 끌면 `UIScrollView`가 터치를 가져가
    /// 타이머가 취소되므로 스크롤 중에는 삭제 확인이 뜨지 않는다
    static let removalLongPressDuration: TimeInterval = 0.5

    enum SuggestionUpdateAction: Equatable {
        case none
        case update(String)
        case clear
    }

    static func shouldInsertLeadingSpaceBeforeNGramSuggestion(inputBuffer: String) -> Bool {
        return !inputBuffer.isEmpty && inputBuffer.last?.isWhitespace != true
    }

    static func currentWordForConfirmation(inputBuffer: String) -> String {
        return inputBuffer.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
    }

    static func shouldLoadLexicon(
        isTextReplacementEnabled: Bool,
        isPredictiveTextEnabled: Bool
    ) -> Bool {
        return isTextReplacementEnabled || isPredictiveTextEnabled
    }

    static func shouldStartLexiconLoadBeforeFirstAppearance(
        isTextReplacementEnabled: Bool
    ) -> Bool {
        return isTextReplacementEnabled
    }

    static func shouldUpdateInitialSuggestionsAfterDeferredPreparation(
        shouldPreparePredictiveEngines: Bool
    ) -> Bool {
        return shouldPreparePredictiveEngines
    }

    static func shouldUpdateSuggestionsOnTextDidChange(
        isPrimaryCursorDragging: Bool
    ) -> Bool {
        return !isPrimaryCursorDragging
    }

    static func limitedDocumentContextBeforeInput(_ context: String?) -> String {
        guard let context else { return "" }
        return String(context.suffix(KeyboardTextContextNavigator.maximumCursorRestoreDistance))
    }

    static func mathExpressionDetectionText(
        selectedText: String?,
        inputBuffer: String,
        documentContextBeforeInput: String?
    ) -> String {
        if let selectedText, !selectedText.isEmpty {
            return selectedText
        }
        if !inputBuffer.isEmpty {
            return inputBuffer
        }
        return limitedDocumentContextBeforeInput(documentContextBeforeInput)
    }

    static func suggestionUpdateAction(
        isPredictiveTextEnabled: Bool,
        selectedText: String?,
        inputBuffer: String
    ) -> SuggestionUpdateAction {
        guard isPredictiveTextEnabled else { return .none }

        if let selectedText, !selectedText.isEmpty {
            if selectedText.contains(where: { $0.isWhitespace }),
               MathExpressionCompletionEvaluator.completion(
                   for: selectedText
               ) == nil {
                return .clear
            }
            return .update(selectedText)
        }

        return .update(inputBuffer)
    }

}
