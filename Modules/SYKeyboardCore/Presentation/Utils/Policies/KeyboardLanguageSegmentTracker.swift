//
//  KeyboardLanguageSegmentTracker.swift
//  SYKeyboardCore
//
//  Created by Codex on 8/13/26.
//

import Foundation

/// 언어 전환 경계 이후에 편집된 구간만 추적한다.
///
/// 한영 통합 키보드는 하나의 `inputBuffer`를 두 언어가 공유하므로,
/// 자동완성이 이전 언어 구간까지 보지 않도록 경계 이후 길이만 센다
struct KeyboardLanguageSegmentTracker {
    private var currentSegmentCount: Int?

    mutating func markLanguageBoundary() {
        currentSegmentCount = 0
    }

    mutating func insert(_ text: String) {
        guard let currentSegmentCount else { return }
        self.currentSegmentCount = currentSegmentCount + text.count
    }

    mutating func delete(count: Int) {
        guard let currentSegmentCount else { return }
        self.currentSegmentCount = max(0, currentSegmentCount - count)
    }

    mutating func replace(deleteCount: Int, insertText: String) {
        delete(count: deleteCount)
        insert(insertText)
    }

    mutating func resetForExternalContext() {
        currentSegmentCount = nil
    }

    func currentSegment(in inputBuffer: String) -> String {
        guard let currentSegmentCount else { return inputBuffer }
        return String(inputBuffer.suffix(currentSegmentCount))
    }
}
