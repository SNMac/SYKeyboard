//
//  KeyboardLanguageSegmentTrackerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 8/13/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("한영 입력 segment 추적")
struct KeyboardLanguageSegmentTrackerTests {

    @Test("언어 경계 뒤 삽입과 대치만 현재 segment에 반영")
    func testTracksOnlyEditsAfterBoundary() {
        var tracker = KeyboardLanguageSegmentTracker()
        tracker.insert("한글")
        tracker.markLanguageBoundary()
        tracker.insert("ab")
        tracker.replace(deleteCount: 1, insertText: "C")

        #expect(tracker.currentSegment(in: "한글aC") == "aC")
    }

    @Test("경계 이전 문서 삭제는 현재 segment를 음수로 만들지 않음")
    func testDeletionDoesNotCrossSegmentBoundary() {
        var tracker = KeyboardLanguageSegmentTracker()
        tracker.insert("한글")
        tracker.markLanguageBoundary()
        tracker.delete(count: 1)

        #expect(tracker.currentSegment(in: "한") == "")
    }

    @Test("외부 context reset은 전체 입력 buffer 추적으로 복귀")
    func testExternalContextResetRestoresFullBufferTracking() {
        var tracker = KeyboardLanguageSegmentTracker()
        tracker.markLanguageBoundary()
        tracker.insert("en")

        tracker.resetForExternalContext()

        #expect(tracker.currentSegment(in: "새 문맥") == "새 문맥")
    }
}
