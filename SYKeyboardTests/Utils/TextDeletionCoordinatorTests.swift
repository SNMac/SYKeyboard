//
//  TextDeletionCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("삭제 상호작용 Coordinator", .sharedUserDefaults)
@MainActor
struct TextDeletionCoordinatorTests {

    @Test("삭제 touchDown은 hook 사이에서 지우고 release 확정 뒤 undo 기록을 요청")
    func testTouchDownHooksAndRelease() {
        let fixture = makeFixture()

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])
        #expect(fixture.proxy.writes == ["deleteBackward"])
        // 지운 글자는 파이프라인이 capture했으므로 아직 undo에 기록되지 않는다
        #expect(fixture.host.uncapturedEdits.isEmpty)

        fixture.coordinator.finishTouchDown()

        #expect(fixture.host.calls.last == "recordEditForUndo(녕, )")
    }

    @Test("대치 복구가 있으면 삭제 대신 replaceText를 부름")
    func testRestoreReplacementTakesPrecedence() {
        let fixture = makeFixture()
        fixture.service.restoreReplacementResult = (deleteCount: 1, insertText: "abc")

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "replaceText(1, abc)", "textInteractionDidPerform"])
    }

    @Test("확정 전 두 번째 touchDown은 보류되고 textDidChange 뒤에 drain")
    func testSecondTouchDownIsDrainedAfterTextChange() {
        let fixture = makeFixture()

        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.performTouchDown(for: fixture.button)
        #expect(fixture.proxy.writes == ["deleteBackward"])

        fixture.coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
    }

    @Test("pan 왼쪽은 모델 글자를 override로 넘겨 지우고 오른쪽은 되살리며 종료 시 훅과 인디케이터를 정리")
    func testPanDeleteRestoreStop() {
        let fixture = makeFixture()

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.indicator.isHidden == false)
        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText", "refreshSuggestions"])
        #expect(fixture.host.panDeletedTextOverrides == ["녕"])
        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.coordinator.panPreviousCharacter == "안")

        fixture.coordinator.handlePan(to: .right)

        #expect(fixture.host.calls.suffix(2) == ["deleteButtonPanRestoreText(녕)", "refreshSuggestions"])
        #expect(fixture.proxy.writes == ["deleteBackward", "insertText(녕)"])

        fixture.coordinator.handlePanStop()

        #expect(fixture.host.calls.last == "deleteButtonPanDidStop")
        #expect(fixture.indicator.isHidden)
    }

    @Test("첨부 토큰 앞에서는 pan 삭제를 요청하지 않음")
    func testPanStopsBeforeAttachment() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "a\u{FFFC}"

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls.isEmpty)
        #expect(fixture.proxy.writes.isEmpty)
    }

    @Test("선택 영역이 있으면 모델 글자를 떼지 않고 복구 버퍼에도 넣지 않음")
    func testPanWithSelectionDoesNotTrackStep() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "안"
        fixture.proxy.selected = "녕"

        fixture.coordinator.handlePan(to: .left)
        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.coordinator.panPreviousCharacter == "안")

        fixture.coordinator.handlePan(to: .right)

        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.host.calls.contains("deleteButtonPanRestoreText(녕)") == false)
    }

    @Test("입력창 식별자가 바뀌면 보류된 pan을 끝내고 인디케이터를 숨김")
    func testInputChangeCancelsPendingPan() {
        let fixture = makeFixture()
        // 임시 객체는 바로 해제돼 다음 객체가 같은 주소를 받을 수 있으므로 필드를 살려 둔다
        let firstField = UITextField()
        let secondField = UITextField()
        let first = ObjectIdentifier(firstField)
        let second = ObjectIdentifier(secondField)
        fixture.coordinator.synchronizeInputIdentifier(first)
        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.handlePan(to: .left)
        #expect(fixture.indicator.isHidden == false)

        fixture.coordinator.synchronizeInputIdentifier(second)

        #expect(fixture.host.calls.last == "deleteButtonPanDidStop")
        #expect(fixture.indicator.isHidden)
        #expect(fixture.proxy.writes == ["deleteBackward"])
    }

    @Test("반복 타이머는 host에 틱을 보내고 창 밖이면 멈춤")
    func testRepeatTimerTicksAndStopsOutsideWindow() {
        let fixture = makeFixture()
        // 0.25초 동안 바닥나지 않도록 긴 문맥을 둔다
        fixture.proxy.beforeInput = String(repeating: "가", count: 50)
        fixture.coordinator.beginRepeatInput()
        #expect(fixture.coordinator.isRepeatingInput)

        fixture.coordinator.startRepeatInputTimer(for: fixture.button)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.25))

        #expect(fixture.host.calls.contains("performRepeatTextInteraction"))
        #expect(fixture.proxy.writes.isEmpty == false)

        fixture.host.isViewInWindow = false
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        #expect(fixture.coordinator.isRepeatingInput == false)
    }

    @Test("반복 종료는 마지막 틱을 확정하고 반복 상태를 끝냄")
    func testEndRepeatInputCompletesLastTick() {
        let fixture = makeFixture()
        fixture.coordinator.beginRepeatInput()
        fixture.coordinator.performRepeatTick(for: fixture.button)
        #expect(fixture.proxy.writes == ["deleteBackward"])

        fixture.coordinator.endRepeatInput(isDeleteButton: true)

        #expect(fixture.coordinator.isRepeatingInput == false)
        #expect(fixture.host.calls.contains("recordEditForUndo(녕, )"))
    }

    @Test("연속된 반복 틱은 직전 틱을 확정하고 이어 지움")
    func testConsecutiveRepeatTicksContinueDeleting() {
        let fixture = makeFixture()
        fixture.coordinator.beginRepeatInput()

        fixture.coordinator.performRepeatTick(for: fixture.button)
        fixture.coordinator.performRepeatTick(for: fixture.button)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])

        fixture.coordinator.endRepeatInput(isDeleteButton: true)

        #expect(fixture.coordinator.isRepeatingInput == false)
    }

    @Test("captureMutation은 진행 중 요청이 없으면 false")
    func testCaptureMutationWithoutRequestReturnsFalse() {
        let fixture = makeFixture()

        let captured = fixture.coordinator.captureMutation(deletedText: "a", insertedText: "", reliability: .proxyContext)

        #expect(captured == false)
    }

    @Test("host가 해제된 뒤에는 어떤 진입점도 쓰지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        var host: RecordingTextDeletionHost? = RecordingTextDeletionHost(proxy: fixture.proxy)
        let coordinator = TextDeletionCoordinator(
            deleteDragIndicatorView: fixture.indicator,
            suggestionController: fixture.service,
            keyboardSettingsManager: .shared,
            host: host!
        )
        host = nil

        coordinator.performTouchDown(for: fixture.button)
        coordinator.finishTouchDown()
        coordinator.handlePan(to: .left)
        coordinator.handlePan(to: .right)
        coordinator.handlePanStop()
        coordinator.beginRepeatInput()
        coordinator.performRepeatTick(for: fixture.button)
        coordinator.performInitialRepeatDelete(for: fixture.button)
        coordinator.startRepeatInputTimer(for: fixture.button)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
        coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)
        coordinator.endRepeatInput(isDeleteButton: true)

        #expect(fixture.proxy.writes.isEmpty)
    }

    @Test("타이머와 경계 대기가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: TextDeletionCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            fixture.coordinator.beginRepeatInput()
            fixture.coordinator.startRepeatInputTimer(for: fixture.button)
            // 모델이 바닥난 상태에서 pan을 보내 줄 경계 요청과 타임아웃(asyncAfter)을 예약한다
            fixture.proxy.beforeInput = ""
            fixture.coordinator.handlePan(to: .left)
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        // 예약된 타이머 틱·타임아웃 클로저가 실행돼도 크래시가 없어야 한다
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
    }

    // MARK: - 줄 경계·취소 시나리오

    @Test("panStop 뒤 late callback이 줄바꿈을 확정한 후 tracking을 종료")
    func testPanStopBeforeLateCallbackConfirmsNewlineAndFinishesTracking() async throws {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = ""
        fixture.proxy.afterInput = "라마바"

        fixture.coordinator.handlePan(to: .left)

        // 모델이 비어 줄 경계 요청을 보내고, 지운 글자는 파이프라인이 capture한다
        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])
        #expect(fixture.host.uncapturedEdits.isEmpty)

        fixture.coordinator.handlePanStop()

        // 경계 확인 전이라 panStop은 보류되고, 손을 뗀 시점의 문맥으로는 확정되지 않는다
        #expect(fixture.host.calls.contains("deleteButtonPanDidStop") == false)
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.proxy.writes == ["deleteBackward"])

        fixture.proxy.beforeInput = "가나다"
        fixture.coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)

        // 이전 줄이 나타나 줄바꿈 삭제로 확정되고, 복구할 줄바꿈이 생겨 모델을 이전 줄로 다시 채운다
        #expect(fixture.host.calls.last == "recordEditForUndo(\n, )")
        #expect(fixture.coordinator.panPreviousCharacter == "다")

        // 줄바꿈 삭제 뒤에는 입력창의 늦은 callback을 기다렸다가 보류된 panStop을 재생한다.
        // 예약 블록은 main 큐에서 돌므로 runloop를 돌리지 않고 main actor를 비켜 준다
        try await Task.sleep(for: .milliseconds(100))

        #expect(fixture.host.calls.filter { $0 == "deleteButtonPanDidStop" }.count == 1)
        #expect(fixture.coordinator.panPreviousCharacter == nil)

        // 진행·보류 중인 삭제가 없으므로 다음 touchDown은 보류되지 않고 새 요청으로 바로 지운다
        let uncapturedEdits = fixture.host.uncapturedEdits
        fixture.coordinator.performTouchDown(for: fixture.button)
        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
        #expect(fixture.host.calls.suffix(3) == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])
        #expect(fixture.host.uncapturedEdits == uncapturedEdits)
    }

    @Test("문서 시작 panStop no-op은 후속 checkpoint에서 coordinator를 정리")
    func testDocumentStartPanStopNoOpCheckpointCleansCoordinator() async throws {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = ""
        fixture.proxy.afterInput = "가나다"

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])

        fixture.coordinator.handlePanStop()

        #expect(fixture.host.calls.contains("deleteButtonPanDidStop") == false)
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)

        // 손을 뗀 뒤 예약된 checkpoint가 앞 문맥이 그대로 빈 것을 보고 삭제 없음으로 확정한다
        try await Task.sleep(for: .milliseconds(50))

        // 삭제 없음은 undo를 남기지 않고, 보류된 panStop만 한 번 재생한다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.host.uncapturedEdits.isEmpty)
        #expect(fixture.host.calls.filter { $0 == "deleteButtonPanDidStop" }.count == 1)

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
        #expect(fixture.host.calls.suffix(3) == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])
        #expect(fixture.host.uncapturedEdits.isEmpty)
    }

    @Test("문서 시작 no-op pan 경계가 확정되면 보류된 선행 left는 버리고 right부터 재생")
    func testNoOpPanBoundaryResolutionDiscardsLeadingLeft() async throws {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = ""
        fixture.proxy.afterInput = "가나다"

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])

        fixture.coordinator.handlePan(to: .left)
        fixture.coordinator.handlePan(to: .right)
        fixture.coordinator.handlePan(to: .left)
        fixture.coordinator.handlePanStop()

        // 경계 확인 전 이벤트는 모두 보류되고 손을 뗀 시점에는 확정되지 않는다
        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])
        #expect(fixture.proxy.writes == ["deleteBackward"])

        try await Task.sleep(for: .milliseconds(50))

        // 삭제 없음으로 확정돼 undo가 없고, 문서 맨 앞이라 경계를 다시 묻지 않는다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.proxy.writes == ["deleteBackward"])
        // 선행 left는 버려지고 right·left·panStop만 재생된다. right는 복구할 글자가 없어 host를 부르지 않는다.
        // 재생 순서 자체는 `DeleteInteractionCoordinatorTests`가 갖는다
        #expect(Array(fixture.host.calls.dropFirst(2)) == ["deleteButtonPanDeleteText(false)", "deleteButtonPanDidStop"])

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
        #expect(fixture.host.calls.suffix(3) == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])
    }

    @Test("문서 시작 pan 경계에 앞 문맥이 그대로인 callback이 오면 복구 문자 없이 선행 left를 버림")
    func testDocumentStartPanBoundaryCallbackDoesNotRestoreNewline() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = nil
        fixture.proxy.afterInput = "가나다"

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])

        fixture.coordinator.handlePan(to: .left)
        fixture.coordinator.handlePan(to: .left)
        fixture.coordinator.handlePan(to: .right)
        fixture.coordinator.handlePanStop()

        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText"])

        fixture.coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)

        // 앞 문맥이 그대로인 callback은 삭제 없음으로 확정돼 undo를 남기지 않는다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.host.uncapturedEdits.isEmpty)
        // 복구 문자가 없어 right는 아무것도 되살리지 않고, 선행 left 둘은 버려져 panStop만 남는다
        #expect(fixture.host.calls.contains { $0.hasPrefix("deleteButtonPanRestoreText") } == false)
        #expect(Array(fixture.host.calls.dropFirst(2)) == ["deleteButtonPanDidStop"])
    }

    @Test("non-delete mutation 경계는 lifecycle과 coordinator를 함께 취소")
    func testNonDeleteMutationBoundaryCancelsLifecycleAndCoordinator() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "가"
        fixture.proxy.afterInput = ""

        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.handlePan(to: .left)

        // touchDown 확인 전이라 pan은 보류된다
        #expect(fixture.host.calls == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])

        fixture.coordinator.cancelPendingInteractions()
        fixture.coordinator.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        )

        // 취소된 touchDown은 늦은 callback으로 확정되지 않고, 보류된 pan도 재생되지 않는다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.host.calls.contains("deleteButtonPanDeleteText(false)") == false)
        // pan tracking 종료는 취소 때 한 번만 요청한다
        #expect(fixture.host.calls.filter { $0 == "deleteButtonPanDidStop" }.count == 1)
        #expect(fixture.indicator.isHidden)

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
    }

    /// 하네스 시절에는 새 touchDown을 시작한 뒤 capture 전에 늦은 callback을 넣었다.
    /// production touchDown은 시작과 capture가 동기로 이어져 그 틈이 없으므로, 늦은 callback은 새 touchDown 전에 온다
    @Test("focus 변경 뒤 늦은 callback은 새 입력 대상을 mutate하지 않음")
    func testFocusChangeDoesNotMutateNewInputIdentifier() {
        let fixture = makeFixture()
        // 임시 객체는 바로 해제돼 다음 객체가 같은 주소를 받을 수 있으므로 필드를 살려 둔다
        let firstField = UITextField()
        let secondField = UITextField()
        fixture.proxy.beforeInput = "가"
        fixture.proxy.afterInput = ""
        fixture.coordinator.synchronizeInputIdentifier(ObjectIdentifier(firstField))

        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])

        fixture.coordinator.synchronizeInputIdentifier(ObjectIdentifier(secondField))
        fixture.coordinator.completeAfterTextChange(
            currentContext: KeyboardTextContextSnapshot(beforeInput: "", afterInput: "")
        )

        // 이전 입력 대상의 요청은 취소돼 늦은 callback으로 확정되지 않는다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.host.calls.filter { $0 == "deleteButtonPanDidStop" }.count == 1)

        fixture.proxy.beforeInput = "새"
        fixture.coordinator.performTouchDown(for: fixture.button)

        // 새 입력 대상의 touchDown은 보류되지 않고 바로 지운 뒤 자기 callback을 기다린다
        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
        #expect(fixture.host.uncapturedEdits.isEmpty)

        fixture.coordinator.handlePan(to: .left)

        // 기다리는 동안 들어온 pan은 보류되고, 이전 입력 대상의 pan은 끝까지 재생되지 않는다
        #expect(fixture.host.calls.contains("deleteButtonPanDeleteText(false)") == false)
    }

    @Test("active captured 요청의 관련 없는 callback은 generation과 FIFO를 취소")
    func testActiveCapturedRequestUnrelatedCallbackCancelsGeneration() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "가"
        fixture.proxy.afterInput = ""

        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])

        fixture.proxy.beforeInput = "가"
        fixture.proxy.afterInput = "외부 변경"
        fixture.coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)

        // 관련 없는 callback은 요청을 취소한다. undo를 남기지 않고 pan tracking을 한 번 끝낸다
        #expect(fixture.host.calls.contains { $0.hasPrefix("recordEditForUndo") } == false)
        #expect(fixture.host.calls.filter { $0 == "deleteButtonPanDidStop" }.count == 1)
        #expect(fixture.indicator.isHidden)
        // 보류된 pan은 재생되지 않는다
        #expect(fixture.host.calls.contains("deleteButtonPanDeleteText(false)") == false)

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
    }
}

// MARK: - Test Helpers

/// VC의 래퍼 계약을 흉내 내는 host: 프록시에 쓰고, 지운 글자를 Coordinator의 `captureMutation`에 넘기며,
/// 반복 틱·touchDown 요청은 Coordinator로 되돌려 보낸다.
///
/// 이 계약(`deleteText()`의 override·reliability 처리)의 권위는 VC를 실제로 거치는
/// `BaseKeyboardViewControllerDeleteUndoBehaviorTests`에 있다. VC 쪽 계약이 바뀌면 그 suite가 먼저 깨지고,
/// 이 가짜도 같이 고쳐야 한다. 여기서는 Coordinator가 host를 부르는 순서와 프록시 쓰기만 단언한다
@MainActor
private final class RecordingTextDeletionHost: TextDeletionHost {
    var calls: [String] = []
    /// 파이프라인이 capture하지 않아 undo에 바로 기록됐을 편집
    var uncapturedEdits: [String] = []
    /// `deleteText()`가 `takePanDeletedTextOverride()`로 받은 값
    var panDeletedTextOverrides: [String?] = []
    var currentInputBuffer = ""
    var isViewInWindow = true
    let textDocument: CachingTextDocumentProxy
    weak var coordinator: TextDeletionCoordinator?

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func textInteractionWillPerform(button: TextInteractable) { calls.append("textInteractionWillPerform") }
    func textInteractionDidPerform(button: TextInteractable) { calls.append("textInteractionDidPerform") }
    func deleteBackward() { calls.append("deleteBackward"); performSingleDelete() }
    func repeatDeleteBackward() { calls.append("repeatDeleteBackward"); performSingleDelete() }
    func deleteText() { calls.append("deleteText"); performSingleDelete() }

    func replaceText(deleteCount: Int, insert text: String) {
        calls.append("replaceText(\(deleteCount), \(text))")
        let deletedText = String((textDocument.documentContextBeforeInput ?? "").suffix(deleteCount))
        for _ in 0..<deleteCount { textDocument.deleteBackward() }
        if !text.isEmpty { textDocument.insertText(text) }
        capture(deletedText: deletedText, insertedText: text, reliability: .authoritative)
    }

    func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)? {
        calls.append("deleteButtonPanDeleteText(\(hasPendingRestoreText))")
        // Base VC의 기본 구현과 같다: 모델 글자가 없으면 nil, 있으면 deleteText()
        guard let character = coordinator?.panPreviousCharacter else { return nil }
        deleteText()
        return (character, true)
    }

    func deleteButtonPanRestoreText(_ character: Character) {
        calls.append("deleteButtonPanRestoreText(\(character))")
        textDocument.insertText(String(character))
        capture(deletedText: "", insertedText: String(character), reliability: .authoritative)
    }

    func deleteButtonPanDidStop() { calls.append("deleteButtonPanDidStop") }

    func performRepeatTextInteraction(for button: TextInteractable) {
        calls.append("performRepeatTextInteraction")
        coordinator?.performRepeatTick(for: button)
    }

    func performDeleteTextInteraction(for button: TextInteractable) {
        calls.append("performDeleteTextInteraction")
        coordinator?.performTouchDown(for: button)
    }

    func recordEditForUndo(deletedText: String, insertedText: String) {
        calls.append("recordEditForUndo(\(deletedText), \(insertedText))")
        capture(deletedText: deletedText, insertedText: insertedText, reliability: .authoritative)
    }

    func refreshSuggestions() { calls.append("refreshSuggestions") }

    /// VC `deleteText()`의 계약: 선택 영역이 비었으면 pan override, 아니면 선택 텍스트·앞 글자를 지운 글자로 삼는다
    private func performSingleDelete() {
        let selectedText = textDocument.selectedText
        let override = coordinator?.takePanDeletedTextOverride()
        panDeletedTextOverrides.append(override)
        let deletedText = ((selectedText ?? "").isEmpty ? override : nil)
            ?? KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: selectedText,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )
        textDocument.deleteBackward()
        capture(
            deletedText: deletedText,
            insertedText: "",
            reliability: selectedText?.isEmpty == false ? .authoritative : .proxyContext
        )
    }

    private func capture(deletedText: String, insertedText: String, reliability: RepeatDeleteMutationReliability) {
        let captured = coordinator?.captureMutation(
            deletedText: deletedText, insertedText: insertedText, reliability: reliability
        ) ?? false
        if !captured { uncapturedEdits.append("\(deletedText)/\(insertedText)") }
    }
}

@MainActor
private struct Fixture {
    let coordinator: TextDeletionCoordinator
    let host: RecordingTextDeletionHost
    let service: FakeSuggestionService
    let indicator: CursorDragIndicatorView
    let proxy: CountingTextDocumentProxy
    let button: DeleteButton
}

/// 앞 문맥 "안녕", 선택 없음, 보이지 않는 인디케이터로 시작한다
@MainActor
private func makeFixture() -> Fixture {
    let proxy = CountingTextDocumentProxy()
    let host = RecordingTextDeletionHost(proxy: proxy)
    let service = FakeSuggestionService()
    let indicator = CursorDragIndicatorView(symbolName: CursorDragIndicatorSymbolFactory.deleteSymbolName)
    indicator.isHidden = true
    let coordinator = TextDeletionCoordinator(
        deleteDragIndicatorView: indicator,
        suggestionController: service,
        keyboardSettingsManager: .shared,
        host: host
    )
    host.coordinator = coordinator
    return Fixture(
        coordinator: coordinator,
        host: host,
        service: service,
        indicator: indicator,
        proxy: proxy,
        button: DeleteButton(keyboard: .dubeolsik)
    )
}
