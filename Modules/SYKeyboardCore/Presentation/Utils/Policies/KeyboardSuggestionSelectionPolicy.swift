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

    static func shouldInsertLeadingSpaceBeforeNGramSuggestion(baseText: String) -> Bool {
        return !baseText.isEmpty && baseText.last?.isWhitespace != true
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

    /// 일반 후보(n-gram·TextChecker)의 기준 텍스트
    ///
    /// 버퍼가 비면 그 순간의 커서 앞 문맥을, 버퍼가 있으면 버퍼가 시작될 때 떠 둔 앞 문맥에 버퍼를 이어 쓴다.
    /// 입력 직후의 프록시 문맥은 늦게 갱신될 수 있어, 입력 중에는 키보드가 직접 관리하는 버퍼를 믿는다.
    /// 리턴은 학습에서 문장 끝이므로 마지막 줄바꿈 앞 텍스트는 문맥으로 쓰지 않는다
    static func generalSuggestionBaseText(
        leadingContext: String?,
        inputBuffer: String,
        documentContextBeforeInput: String?
    ) -> String {
        let context = inputBuffer.isEmpty
            ? limitedDocumentContextBeforeInput(documentContextBeforeInput)
            : limitedDocumentContextBeforeInput((leadingContext ?? "") + inputBuffer)
        guard let lastNewline = context.lastIndex(where: { $0.isNewline }) else { return context }
        return String(context[context.index(after: lastNewline)...])
    }

    /// 버퍼 첫 단어가 앞 글자에 붙어 시작했는지 판정한다
    static func isInputBufferAttachedToLeadingContext(_ leadingContext: String?) -> Bool {
        guard let last = leadingContext?.last else { return false }
        return !last.isWhitespace
    }

    /// 학습에 넘길 버퍼. 앞 글자에 붙어 시작한 첫 조각을 뺀다
    ///
    /// 매번 같은 규칙으로 빼므로 `recordUncommittedWords`의 문장 단어 수 비교가 어긋나지 않는다
    static func learnableInputBuffer(_ inputBuffer: String, isAttachedToLeadingContext: Bool) -> String {
        guard isAttachedToLeadingContext else { return inputBuffer }
        return String(inputBuffer.drop(while: { !$0.isWhitespace }))
    }

    /// 교체 뒤의 앞 문맥. 지운 글자가 버퍼보다 많으면 넘친 글자 수만큼 앞 문맥 끝을 자른다
    static func leadingContextAfterReplacement(
        _ leadingContext: String?,
        inputBufferCount: Int,
        deleteCount: Int
    ) -> String? {
        guard let leadingContext else { return nil }
        let overflow = deleteCount - inputBufferCount
        guard overflow > 0 else { return leadingContext }
        return String(leadingContext.dropLast(overflow))
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
        baseText: String
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

        return .update(baseText)
    }

}
