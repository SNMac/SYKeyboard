//
//  CursorDragSelectionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/20/26.
//

import Testing
import Foundation

@testable import SYKeyboardCore

@Suite("커서 드래그 선택 정책 검증")
struct CursorDragSelectionPolicyTests {

    @Test("기본 정책은 왼쪽 선택 후 오른쪽으로 되돌아와도 기존 선택 범위를 줄이지 않음")
    func test기본정책_왼쪽선택후오른쪽_범위보존() {
        var state = CursorDragSelectionPolicy.State()

        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: -3,
            mode: .preserveExpandedRange
        )
        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: 2,
            mode: .preserveExpandedRange
        )

        #expect(state.selection == .init(startOffset: -3, length: 5))
    }

    @Test("기본 정책은 오른쪽 선택 후 왼쪽으로 되돌아와도 기존 선택 범위를 줄이지 않음")
    func test기본정책_오른쪽선택후왼쪽_범위보존() {
        var state = CursorDragSelectionPolicy.State()

        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: 4,
            mode: .preserveExpandedRange
        )
        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: -1,
            mode: .preserveExpandedRange
        )

        #expect(state.selection == .init(startOffset: -1, length: 5))
    }

    @Test("anchor 정책은 시작점으로 되돌아오면 선택 범위를 줄임")
    func testAnchor정책_시작점복귀_범위축소() {
        var state = CursorDragSelectionPolicy.State()

        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: -4,
            mode: .anchor
        )
        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: -1,
            mode: .anchor
        )

        #expect(state.selection == .init(startOffset: -1, length: 1))
    }

    @Test("anchor 정책은 시작점을 넘어가면 반대 방향 선택으로 전환")
    func testAnchor정책_시작점넘김_반대방향전환() {
        var state = CursorDragSelectionPolicy.State()

        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: -2,
            mode: .anchor
        )
        state = CursorDragSelectionPolicy.updatedState(
            state,
            cursorOffset: 3,
            mode: .anchor
        )

        #expect(state.selection == .init(startOffset: 0, length: 3))
    }

    @Test("선택 범위는 커서 앞뒤 문맥에서 marked text 후보를 만듦")
    func testMarkedTextCommand_앞뒤문맥결합() {
        let command = CursorDragSelectionPolicy.markedTextCommand(
            for: .init(startOffset: -3, length: 5),
            documentContextBeforeInput: "abc",
            documentContextAfterInput: "de"
        )

        #expect(command?.markedText == "abcde")
        #expect(command?.selectedRange == NSRange(location: 0, length: 5))
    }

    @Test("선택 범위에 필요한 문맥이 없으면 marked text 후보를 만들지 않음")
    func testMarkedTextCommand_문맥부족_nil() {
        let command = CursorDragSelectionPolicy.markedTextCommand(
            for: .init(startOffset: -3, length: 5),
            documentContextBeforeInput: "ab",
            documentContextAfterInput: "de"
        )

        #expect(command == nil)
    }
}
