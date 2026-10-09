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
