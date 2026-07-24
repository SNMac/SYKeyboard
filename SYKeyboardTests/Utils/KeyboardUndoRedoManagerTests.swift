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

    @Test("커서 드래그 후 전체 반복 삭제 undo는 마지막 줄바꿈까지 원문 복원")
    func test반복삭제_커서드래그후전체삭제_원문복원() {
        var manager = KeyboardUndoRedoManager()
        let confirmedDeletedTexts = [
            "\n", "바", "마", "\n", "라", "다", "\n", "나", "가"
        ]

        for deletedText in confirmedDeletedTexts {
            manager.record(deletedText: deletedText, insertedText: "", targetContext: nil)
        }

        #expect(
            manager.undo()
            == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "가나\n다라\n마바\n")
        )
        #expect(
            manager.redo()
            == KeyboardUndoRedoEdit(deleteCount: 9, insertText: "")
        )
    }

    @Test("undo 이후 새 입력은 redo 기록을 비움")
    func testUndo후_새입력_Redo초기화() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "a", targetContext: nil)
        _ = manager.undo()
        manager.record(deletedText: "", insertedText: "b", targetContext: nil)

        #expect(manager.redo() == nil)
    }

    @Test("undo 이후 새 치환은 redo 기록을 비움")
    func testUndo후_새치환_Redo초기화() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "ㄷ", insertedText: "돈", targetContext: nil)
        _ = manager.undo()
        manager.record(deletedText: "ㄴ", insertedText: "난", targetContext: nil)

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

    @Test("pending group commit 후에도 undo 적용 위치 context를 유지함")
    func testPendingGroupCommit후_UndoContext유지() {
        var manager = KeyboardUndoRedoManager()
        let target = KeyboardTextContextSnapshot(beforeInput: "안녕", afterInput: "하세요")

        manager.record(deletedText: "", insertedText: "돈", targetContext: target)
        manager.commitPendingGroup()

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: "", targetContext: target))
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

    @Test("반복 삭제 경계에서 확인된 줄바꿈은 같은 그룹 순서로 한 번만 복구")
    func test반복삭제_확인된줄바꿈_UndoRedo순서와중복방지() {
        var manager = KeyboardUndoRedoManager()
        var request = RepeatDeleteRequest()

        manager.record(deletedText: "c", insertedText: "", targetContext: nil)
        request.begin(
            context: KeyboardTextContextSnapshot(
                beforeInput: nil,
                afterInput: ""
            ),
            selectedText: nil
        )
        let captureResult = request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
        let completion = request.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "ab",
                afterInput: ""
            ),
            currentSelectedText: nil
        )
        if case .mutations(let drafts) = completion {
            for draft in drafts {
                manager.record(
                    deletedText: draft.deletedText,
                    insertedText: draft.insertedText,
                    targetContext: nil
                )
            }
        }
        if case .mutations(let drafts) = request.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "ab",
                afterInput: ""
            ),
            currentSelectedText: nil
        ) {
            for draft in drafts {
                manager.record(
                    deletedText: draft.deletedText,
                    insertedText: draft.insertedText,
                    targetContext: nil
                )
            }
        }
        manager.record(deletedText: "b", insertedText: "", targetContext: nil)

        #expect(captureResult == .awaitingTextChange)
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "b\nc"))
        #expect(manager.redo() == KeyboardUndoRedoEdit(deleteCount: 3, insertText: ""))
    }

    @Test("문서 시작의 무효 반복 삭제는 undo mutation을 만들지 않음")
    func test반복삭제_문서시작무효요청_Undo없음() {
        var manager = KeyboardUndoRedoManager()
        var request = RepeatDeleteRequest()

        manager.record(deletedText: "", insertedText: "", targetContext: nil)
        request.begin(
            context: KeyboardTextContextSnapshot(
                beforeInput: nil,
                afterInput: ""
            ),
            selectedText: nil
        )
        #expect(request.completeWithoutDeletion() == .noDeletion)

        #expect(manager.canUndo == false)
        #expect(manager.undo() == nil)
        #expect(manager.redo() == nil)
    }

    @Test("반복 삭제 undo 후 다시 반복 삭제해도 복구 개수를 유지함")
    func test반복삭제_undo후재반복삭제_복구개수유지() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "ㅏㅏㅏㅏㅏㅏ", targetContext: nil)
        manager.commitPendingGroup()

        for _ in 0..<3 {
            manager.record(deletedText: "ㅏ", insertedText: "", targetContext: nil)
            manager.record(deletedText: "ㅏ", insertedText: "", targetContext: nil)
            manager.record(deletedText: "ㅏ", insertedText: "", targetContext: nil)

            #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "ㅏㅏㅏ"))
        }

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 6, insertText: ""))
    }

    @Test("한글 입력 후 삭제 경계가 확정되면 undo는 삭제만 되돌림")
    func test한글입력후삭제경계_삭제만Undo() {
        var manager = KeyboardUndoRedoManager()

        manager.record(deletedText: "", insertedText: "안녕핫", targetContext: nil)
        manager.commitPendingGroup()
        manager.record(deletedText: "핫", insertedText: "하", targetContext: nil)

        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: "핫"))
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 3, insertText: ""))
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

    @Test("다음 undo 적용 가능성은 기록을 제거하지 않고 현재 context 기준으로 판단함")
    func testCanApplyUndo_현재Context기준_기록유지() {
        var manager = KeyboardUndoRedoManager()
        let target = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
        let unreachable = KeyboardTextContextSnapshot(beforeInput: "xyz", afterInput: "")

        manager.record(deletedText: "", insertedText: "d", targetContext: target)
        manager.commitPendingGroup()

        #expect(manager.canUndo == true)
        #expect(manager.canApplyUndo(from: unreachable) == false)
        #expect(manager.canUndo == true)
        #expect(manager.undo() == KeyboardUndoRedoEdit(deleteCount: 1, insertText: "", targetContext: target))
    }

    @Test("다음 redo 적용 가능성은 기록을 제거하지 않고 현재 context 기준으로 판단함")
    func testCanApplyRedo_현재Context기준_기록유지() {
        var manager = KeyboardUndoRedoManager()
        let undoTarget = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
        let redoTarget = KeyboardTextContextSnapshot(beforeInput: "", afterInput: "abc")
        let unreachable = KeyboardTextContextSnapshot(beforeInput: "xyz", afterInput: "")

        manager.record(deletedText: "", insertedText: "abc", targetContext: undoTarget)
        _ = manager.undo()
        manager.updateLastRedoTargetContext(redoTarget)

        #expect(manager.canRedo == true)
        #expect(manager.canApplyRedo(from: unreachable) == false)
        #expect(manager.canRedo == true)
        #expect(manager.redo() == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "abc", targetContext: redoTarget))
    }
}

@Suite("키보드 undo/redo cursor context 검증")
struct KeyboardTextContextNavigatorTests {

    @Test("커서 복원 최대 거리는 256자임")
    func testMaximumCursorRestoreDistance_256() {
        #expect(KeyboardTextContextNavigator.maximumCursorRestoreDistance == 256)
    }

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

    @Test("최대 복원 거리 안쪽의 커서 이동은 복원 offset을 반환함")
    func testCursorOffset_최대복원거리내_복원() {
        let moveText = String(repeating: "a", count: KeyboardTextContextNavigator.maximumCursorRestoreDistance)
        let current = KeyboardTextContextSnapshot(beforeInput: moveText, afterInput: "tail")
        let target = KeyboardTextContextSnapshot(beforeInput: "", afterInput: moveText + "tail")

        #expect(
            KeyboardTextContextNavigator.cursorOffset(from: current, to: target)
            == -KeyboardTextContextNavigator.maximumCursorRestoreDistance
        )
    }

    @Test("최대 복원 거리를 넘는 커서 이동은 탐색을 중단함")
    func testCursorOffset_최대복원거리초과_nil() {
        let moveText = String(repeating: "a", count: KeyboardTextContextNavigator.maximumCursorRestoreDistance + 1)
        let current = KeyboardTextContextSnapshot(beforeInput: moveText, afterInput: "tail")
        let target = KeyboardTextContextSnapshot(beforeInput: "", afterInput: moveText + "tail")

        #expect(KeyboardTextContextNavigator.cursorOffset(from: current, to: target) == nil)
    }
}

@Suite("키보드 undo/redo session 검증")
struct KeyboardUndoRedoSessionTests {

    @Test("복원 가능 범위를 벗어난 context 변화만으로는 history를 무효화하지 않음")
    func testTextChange_복원범위초과Context변화_History유지() {
        let session = KeyboardUndoRedoSession()
        let source = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
        let unreachable = KeyboardTextContextSnapshot(beforeInput: "xyz", afterInput: "")

        session.record(
            deletedText: "",
            insertedText: "d",
            targetContext: source,
            shouldDeferCommit: { false },
            debouncedCommitDidFinish: {}
        )
        session.commitPendingGroup(shouldDeferCommit: false)
        session.prepareForTextWillChange(inputIdentifier: nil, context: source)

        #expect(
            session.shouldInvalidateAfterTextChange(
                inputIdentifier: nil,
                currentContext: unreachable
            ) == false
        )
        #expect(session.canUndo == true)
        #expect(session.canApplyUndo(from: unreachable) == false)
    }

    @Test("undo/redo 적용 중 text change는 history를 무효화하지 않음")
    func testApplyingEdit중_TextChange_History유지() {
        let session = KeyboardUndoRedoSession()
        let firstInput = NSObject()
        let secondInput = NSObject()
        let firstID = ObjectIdentifier(firstInput)
        let secondID = ObjectIdentifier(secondInput)
        let source = KeyboardTextContextSnapshot(beforeInput: "abc", afterInput: "")
        let changed = KeyboardTextContextSnapshot(beforeInput: "xyz", afterInput: "")

        session.record(
            deletedText: "",
            insertedText: "d",
            targetContext: source,
            shouldDeferCommit: { false },
            debouncedCommitDidFinish: {}
        )
        session.commitPendingGroup(shouldDeferCommit: false)
        session.prepareForTextWillChange(inputIdentifier: firstID, context: source)
        #expect(
            session.shouldInvalidateAfterTextChange(
                inputIdentifier: firstID,
                currentContext: source
            ) == false
        )

        let didApply = session.performApplyingEdit {
            session.prepareForTextWillChange(inputIdentifier: firstID, context: source)
            return session.shouldInvalidateAfterTextChange(
                inputIdentifier: secondID,
                currentContext: changed
            ) == false
        }

        #expect(didApply)
        #expect(session.canUndo)
    }
}
