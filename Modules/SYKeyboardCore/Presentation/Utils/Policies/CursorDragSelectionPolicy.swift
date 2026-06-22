//
//  CursorDragSelectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/20/26.
//

import Foundation

/// 커서 드래그 중 텍스트 선택 범위 계산 정책
enum CursorDragSelectionPolicy {

    // MARK: - Types

    enum Mode {
        case preserveExpandedRange
        case anchor
    }

    struct Selection: Equatable {
        let startOffset: Int
        let length: Int
    }

    struct MarkedTextCommand: Equatable {
        let markedText: String
        let selectedRange: NSRange
    }

    struct State: Equatable {
        private(set) var minimumCursorOffset: Int
        private(set) var maximumCursorOffset: Int

        init(
            minimumCursorOffset: Int = 0,
            maximumCursorOffset: Int = 0
        ) {
            self.minimumCursorOffset = minimumCursorOffset
            self.maximumCursorOffset = maximumCursorOffset
        }

        var selection: Selection {
            Selection(
                startOffset: minimumCursorOffset,
                length: maximumCursorOffset - minimumCursorOffset
            )
        }
    }

    // MARK: - Internal Methods

    static func updatedState(
        _ state: State,
        cursorOffset: Int,
        mode: Mode
    ) -> State {
        switch mode {
        case .preserveExpandedRange:
            return State(
                minimumCursorOffset: min(state.minimumCursorOffset, cursorOffset),
                maximumCursorOffset: max(state.maximumCursorOffset, cursorOffset)
            )
        case .anchor:
            return State(
                minimumCursorOffset: min(0, cursorOffset),
                maximumCursorOffset: max(0, cursorOffset)
            )
        }
    }

    static func markedTextCommand(
        for selection: Selection,
        documentContextBeforeInput: String?,
        documentContextAfterInput: String?
    ) -> MarkedTextCommand? {
        guard selection.length > 0 else { return nil }

        let startOffset = selection.startOffset
        let endOffset = selection.startOffset + selection.length
        let selectedText: String

        if endOffset <= 0 {
            guard let beforeText = selectedSubstringBeforeCursor(
                startOffset: startOffset,
                length: selection.length,
                documentContextBeforeInput: documentContextBeforeInput
            ) else { return nil }
            selectedText = beforeText
        } else if startOffset >= 0 {
            guard let afterText = selectedSubstringAfterCursor(
                endOffset: endOffset,
                length: selection.length,
                documentContextAfterInput: documentContextAfterInput
            ) else { return nil }
            selectedText = afterText
        } else {
            guard let beforeText = documentContextBeforeInput?.suffix(-startOffset),
                  beforeText.count == -startOffset,
                  let afterText = documentContextAfterInput?.prefix(endOffset),
                  afterText.count == endOffset else { return nil }
            selectedText = String(beforeText) + String(afterText)
        }

        return MarkedTextCommand(
            markedText: selectedText,
            selectedRange: NSRange(
                location: 0,
                length: (selectedText as NSString).length
            )
        )
    }
}

private extension CursorDragSelectionPolicy {
    static func selectedSubstringBeforeCursor(
        startOffset: Int,
        length: Int,
        documentContextBeforeInput: String?
    ) -> String? {
        let requiredLength = -startOffset
        guard requiredLength >= length,
              let suffix = documentContextBeforeInput?.suffix(requiredLength),
              suffix.count == requiredLength else { return nil }
        return String(suffix.prefix(length))
    }

    static func selectedSubstringAfterCursor(
        endOffset: Int,
        length: Int,
        documentContextAfterInput: String?
    ) -> String? {
        guard endOffset >= length,
              let prefix = documentContextAfterInput?.prefix(endOffset),
              prefix.count == endOffset else { return nil }
        return String(prefix.suffix(length))
    }
}
