//
//  KeyboardUndoRedoManagerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 5/21/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("키보드 undo/redo 기록 검증")
struct KeyboardUndoRedoManagerTests {

    @Test("debounce commit 전 입력은 pending undo 단위로 묶임")
    func testDebounceCommit전_연속입력_그룹화() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)

        #expect(manager.canUndo == true)
        #expect(manager.canRedo == false)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 2, insertText: ""))

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "ab"))
    }

    @Test("debounce commit 이후 입력은 별도 undo 단위로 남음")
    func testDebounceCommit후_별도Undo단위() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        manager.commitPendingGroup()
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)
        manager.commitPendingGroup()

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "b"))
    }

    @Test("삭제는 undo에서 복구되고 redo에서 다시 삭제됨")
    func test삭제_undoRedo() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "글", insertedText: "", targetContext: nil)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "글"))

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))
    }

    @Test("undo 이후 새 입력은 redo 기록을 비움")
    func testUndo후_새입력_Redo초기화() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        _ = manager.undo()
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)

        #expect(manager.redo() == nil)
    }

    @Test("치환은 삭제와 입력을 하나의 undo/redo 단위로 기록함")
    func test치환_undoRedo() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "hello", insertedText: "hi", targetContext: nil)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 2, insertText: "hello"))

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 5, insertText: "hi"))
    }

    @Test("조합 입력의 연속 치환은 마지막 조합 상태 기준으로 하나의 undo 단위가 됨")
    func test조합입력_연속치환_단일Undo단위() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "ㄷ", targetContext: nil)
        manager.record(deletedText: "ㄷ", insertedText: "도", targetContext: nil)
        manager.record(deletedText: "도", insertedText: "돈", targetContext: nil)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "돈"))
    }

    @Test("undo 후 redo 적용 위치는 undo 완료 시점의 context로 갱신됨")
    func testUndo후_RedoContext갱신() {
        var manager = KeyboardUndoRedoManager()
        let undoTarget = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
        let redoTarget = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")

        manager.record(deletedText: "", insertedText: "abc", targetContext: undoTarget)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 3, insertText: "", targetContext: undoTarget))

        manager.updateLastRedoTargetContext(redoTarget)

        let redo = manager.redo()
        #expect(redo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "abc", targetContext: redoTarget))
    }

    @Test("입력 후 삭제로 전환되면 삭제를 별도 undo 단위로 기록함")
    func test입력후삭제전환_삭제Undo단위분리() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        manager.record(deletedText: "a", insertedText: "", targetContext: nil)

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "a"))
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))
    }

    @Test("삭제 후 입력으로 전환되면 입력을 별도 undo 단위로 기록함")
    func test삭제후입력전환_입력Undo단위분리() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "a", insertedText: "", targetContext: nil)
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "a"))
    }

    @Test("삭제와 입력이 같은 단일 치환은 undo 단위를 만들지 않음")
    func test동일텍스트치환_NoOp제거() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "글", insertedText: "글", targetContext: nil)

        #expect(manager.canUndo == false)
        #expect(manager.undo() == nil)
    }

    @Test("치환 후 원래 텍스트로 돌아오면 undo 단위를 만들지 않음")
    func test치환후원복_NoOp제거() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "돈", insertedText: "도", targetContext: nil)
        manager.record(deletedText: "도", insertedText: "돈", targetContext: nil)

        #expect(manager.canUndo == false)
        #expect(manager.undo() == nil)
    }

    @Test("연속 삭제는 undo에서 원래 순서로 복구됨")
    func test연속삭제_원래순서복구() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "c", insertedText: "", targetContext: nil)
        manager.record(deletedText: "b", insertedText: "", targetContext: nil)

        let undo = manager.undo()
        #expect(undo == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "bc"))
    }

    @Test("history 최대 개수를 넘으면 오래된 undo 단위를 버림")
    func testMaxHistory초과_오래된기록제거() {
        var manager = KeyboardUndoRedoManager(maxHistoryCount: 2)

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        manager.commitPendingGroup()
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)
        manager.commitPendingGroup()
        manager.record(deletedText: "", insertedText: "c", targetContext: nil)
        manager.commitPendingGroup()

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: ""))
        #expect(manager.undo() == nil)
    }
}

@Suite("키보드 undo/redo cursor context 검증")
struct KeyboardTextContextNavigatorTests {

    @Test("커서가 왼쪽으로 이동한 뒤 원래 편집 위치까지 오른쪽 offset을 반환함")
    func testCursorOffset_왼쪽이동후복원() {
        let current = KeyboardTextContextSnapshot(beforeInput: "ab", afterInput: "cdef")
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "def")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == 1)
    }

    @Test("커서가 오른쪽으로 이동한 뒤 원래 편집 위치까지 왼쪽 offset을 반환함")
    func testCursorOffset_오른쪽이동후복원() {
        let current = KeyboardTextContextSnapshot(beforeInput: "abcd", afterInput: "ef")
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "def")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == -1)
    }

    @Test("현재 위치가 target context와 같으면 offset 0을 반환함")
    func testCursorOffset_같은위치() {
        let current = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "def")
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "def")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == 0)
    }

    @Test("host context가 바뀌어 커서 이동으로 설명할 수 없으면 nil을 반환함")
    func testCursorOffset_외부변경감지() {
        let current = KeyboardTextContextSnapshot(beforeInput: "hello", afterInput: "")
        let target = KeyboardTextContextSnapshot(beforeInput: "world", afterInput: "")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == nil)
    }

    @Test("짧은 target context는 현재 context의 suffix prefix로 매칭함")
    func testCursorOffset_짧은TargetContext매칭() {
        let current = KeyboardTextContextSnapshot(beforeInput: "012345abc", afterInput: "defXYZ")
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "def")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == 0)
    }

    @Test("nil과 빈 after context는 문서 끝으로 동일하게 취급함")
    func testCursorOffset_nilEmptyAfterContext동일취급() {
        let current = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: nil)
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == 0)
    }
}
