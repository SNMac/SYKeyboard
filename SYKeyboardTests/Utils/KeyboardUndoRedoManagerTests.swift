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
}
