//
//  BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// VC 수준에서 삭제·반복 삭제·삭제 드래그·undo/redo 동작을 고정한다. 진입점은 VC의 public 메서드, 삭제 버튼의 production release
/// `UIAction`, 제스처 delegate 메서드, 후보 바 delegate이며, 삭제 파이프라인 상태나 인디케이터 뷰 같은 내부 멤버는 참조하지 않는다
@Suite("BaseKeyboardViewController 삭제·undo/redo 동작 고정", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerDeleteUndoBehaviorTests {

    @Test("삭제 탭은 즉시 한 글자를 지우고 release 뒤 undo가 복원")
    func testDeleteTapThenUndoRestores() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton

        controller.performTextInteraction(for: deleteButton)
        #expect(controller.proxy.writes == ["deleteBackward"])

        // release는 setupUI가 붙인 production UIAction이 받는다
        deleteButton.sendActions(for: .touchUpInside)
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)

        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("확정 전 두 번째 탭은 보류되고 textDidChange 뒤에 이어 지움")
    func testSecondTapWaitsForTextChange() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton

        controller.performTextInteraction(for: deleteButton)
        controller.performTextInteraction(for: deleteButton)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.textDidChange(nil)

        #expect(controller.proxy.writes == ["deleteBackward", "deleteBackward"])
    }

    @Test("반복 삭제 틱은 프록시 문맥을 한 번씩만 읽고 종료 훅은 반복 상태를 끝냄")
    func testRepeatDeleteTickReadsContextOnce() {
        let controller = TestDeleteUndoViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(controller.view)
        let deleteButton = controller.primaryView.deleteButton
        controller.repeatTextInteractionWillPerform(button: deleteButton)
        #expect(controller.isRepeatingInput)
        controller.proxy.resetReadCounts()

        controller.performRepeatTextInteraction(for: deleteButton)

        #expect(controller.proxy.writes == ["deleteBackward"])
        // 추출 전 측정값(2026-10-08, f14e15e0): 틱 시작 스냅샷(앞·뒤·선택 1회씩)과 deleteText()의 선택·앞 문맥 읽기
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 2)
        #expect(controller.proxy.readCount(of: "documentContextAfterInput") == 1)
        #expect(controller.proxy.readCount(of: "selectedText") == 2)

        // 연속 틱 동작은 TextDeletionCoordinatorTests가 소유한다. 여기서는 종료 훅이 반복 상태를 끝내는 연결만 본다
        controller.repeatTextInteractionDidPerform(button: deleteButton)

        #expect(controller.isRepeatingInput == false)
        window.removeFromSuperview()
    }

    @Test("삭제 드래그는 왼쪽에서 지우고 오른쪽에서 되살리며 끝나면 훅을 한 번 부름")
    func testDeletePanDeleteRestoreStop() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let gesture = makeGestureController()

        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.deleteButtonPanning(gesture, to: .right)
        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])

        controller.deleteButtonPanStopped(gesture)
        #expect(controller.panDidStopCount == 1)
    }

    // 첨부 토큰 앞 멈춤은 TextDeletionCoordinatorTests.testPanStopsBeforeAttachment가 소유한다 (docs/adr/0003)
    @Test("선택 영역이 있으면 드래그 삭제가 선택 영역을 지우고 undo가 선택 텍스트를 되살림")
    func testDeletePanDeletesSelectionAndUndoRestoresIt() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.proxy.beforeInput = "안"
        controller.proxy.selected = "녕"
        controller.loadViewIfNeeded()
        let gesture = makeGestureController()

        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        // 선택 영역 삭제는 복구 버퍼에 들어가지 않으므로 오른쪽 드래그는 아무것도 쓰지 않는다
        controller.deleteButtonPanning(gesture, to: .right)
        #expect(controller.proxy.writes == ["deleteBackward"])

        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)
        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("undo 뒤 redo는 같은 편집을 다시 적용")
    func testUndoThenRedo() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar

        controller.insertText("가")
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)
        #expect(controller.proxy.writes == ["insertText(가)", "deleteBackward"])

        bar.suggestionDelegate?.suggestionBarDidTapRedo(bar)
        #expect(controller.proxy.writes == ["insertText(가)", "deleteBackward", "insertText(가)"])
    }

    @Test("undo/redo 설정이 꺼져 있으면 undo 탭이 쓰지 않음")
    func testUndoDisabledDoesNotWrite() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = false
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar

        controller.insertText("가")
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)

        #expect(controller.proxy.writes == ["insertText(가)"])
    }

    @Test("삭제 중 입력창이 바뀌면 보류된 드래그를 끝내고 훅을 한 번 부름")
    func testTextInputChangeCancelsPendingPan() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton
        let gesture = makeGestureController()
        let first = UITextField()
        let second = UITextField()

        controller.textWillChange(first)
        controller.performTextInteraction(for: deleteButton)
        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.textWillChange(second)
        #expect(controller.panDidStopCount == 1)

        controller.textDidChange(second)
        #expect(controller.proxy.writes == ["deleteBackward"])
    }

    @Test("삭제·반복·undo를 거친 VC는 참조를 놓으면 해제됨")
    func testControllerIsReleased() {
        weak var weakController: TestDeleteUndoViewController?
        autoreleasepool {
            let controller = TestDeleteUndoViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.addSubview(controller.view)
            let deleteButton = controller.primaryView.deleteButton
            let gesture = makeGestureController()

            controller.textInteractableButtonLongPressing(gesture, button: deleteButton)
            controller.deleteButtonPanning(gesture, to: .left)
            controller.insertText("가")
            controller.view.removeFromSuperview()
            weakController = controller
        }
        // 창에 올렸던 VC는 UIKit이 예약한 main queue 작업이 끝난 뒤 해제되므로 런루프를 한 번 돌린다
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        #expect(weakController == nil)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestDeleteUndoViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()
    /// 하위 VC가 보는 pan 종료 훅 호출 횟수
    private(set) var panDidStopCount = 0

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }

    /// `loadView`가 `view`에 넣는 `KeyboardView`의 후보 바. VC의 `suggestionBarView`는 private이라 뷰 계층으로 얻는다
    var suggestionBar: SuggestionBarView {
        (view as! KeyboardView).suggestionBarView
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}

    override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        panDidStopCount += 1
    }
}

/// 제스처 delegate 메서드는 `controller` 인자를 쓰지 않으므로 빈 컨트롤러를 넘긴다
@MainActor
private func makeGestureController() -> TextInteractionGestureController {
    TextInteractionGestureController(
        keyboardHStackView: UIStackView(),
        getCurrentPressedButton: { nil },
        setCurrentPressedButton: { _ in }
    )
}
