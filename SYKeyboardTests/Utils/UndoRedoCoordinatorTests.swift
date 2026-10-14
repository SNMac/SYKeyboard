//
//  UndoRedoCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("undo/redo Coordinator", .sharedUserDefaults)
@MainActor
struct UndoRedoCoordinatorTests {

    @Test("기록한 삽입을 undo하면 삭제 취소 → 쓰기 → 훅 → 갱신 순서로 적용")
    func testUndoAppliesInOrder() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.host.calls.removeAll()

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward"])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "undoRedoEditDidApply",
            "refreshReturnButtonEnabled",
            "refreshSuggestions",
            "refreshClipboardControl"
        ])
    }

    @Test("undo 뒤 redo는 삽입을 다시 적용")
    func testRedoAfterUndo() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.undo()

        fixture.coordinator.redo()

        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward", "insertText(가)"])
    }

    @Test("삭제 기록을 undo하면 지운 텍스트를 다시 삽입")
    func testUndoOfDeletionReinserts() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.beforeInput = "안녕"
        fixture.proxy.deleteBackward()
        fixture.coordinator.record(deletedText: "녕", insertedText: "")

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("미리보기에서는 적용하지 않고 이력을 비움")
    func testPreviewBlocksApply() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.host.isPreviewMode = true

        fixture.coordinator.undo()
        fixture.host.isPreviewMode = false
        fixture.coordinator.redo()

        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("설정이 꺼져 있으면 기록도 undo도 하지 않음")
    func testFeatureDisabled() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        UserDefaultsManager.shared.isUndoRedoEnabled = false
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["insertText(가)"])
        #expect(fixture.host.calls.isEmpty)
    }

    @Test("조합 지연 중에는 그룹 확정을 미루고 지연 확정이 풀리면 반영")
    func testDeferredCommit() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.shouldDeferUndoRedoCommit = true
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.commitPendingGroup()
        fixture.host.calls.removeAll()

        fixture.host.shouldDeferUndoRedoCommit = false
        fixture.coordinator.commitDeferredGroupIfNeeded()

        #expect(fixture.host.calls == ["refreshClipboardControl"])
        fixture.coordinator.undo()
        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward"])
    }

    @Test("입력창 식별자가 바뀐 textDidChange는 이력과 대치 이력을 비움")
    func testInputChangeInvalidatesHistory() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        // 임시 객체는 바로 해제돼 다음 객체가 같은 주소를 받을 수 있으므로 필드를 살려 둔다
        let firstField = UITextField()
        let secondField = UITextField()
        let first = ObjectIdentifier(firstField)
        let second = ObjectIdentifier(secondField)
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.prepareForTextWillChange(inputIdentifier: first)
        fixture.coordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: first)
        #expect(fixture.service.calls.contains("clearReplacementHistory") == false)

        fixture.coordinator.prepareForTextWillChange(inputIdentifier: second)
        fixture.coordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: second)
        fixture.coordinator.undo()

        #expect(fixture.service.calls.contains("clearReplacementHistory"))
        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("이력이 없으면 컨트롤 갱신이 프록시를 읽지 않음")
    func testRefreshControlsWithoutHistoryDoesNotReadProxy() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.resetReadCounts()

        fixture.coordinator.refreshControls()
        fixture.coordinator.removeAllHistory()

        #expect(fixture.proxy.contextReadCount == 0)
        #expect(fixture.host.calls == ["refreshClipboardControl", "refreshClipboardControl"])
    }

    @Test("host가 해제된 뒤에는 아무 것도 쓰지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        var host: RecordingUndoRedoHost? = RecordingUndoRedoHost(proxy: fixture.proxy)
        let coordinator = UndoRedoCoordinator(
            suggestionBarView: fixture.bar,
            suggestionController: fixture.service,
            keyboardSettingsManager: .shared,
            host: host!
        )
        fixture.proxy.insertText("가")
        coordinator.record(deletedText: "", insertedText: "가")
        host = nil

        coordinator.undo()
        coordinator.redo()
        coordinator.commitPendingGroup()
        coordinator.commitPendingGroupIgnoringDeferral()
        coordinator.commitDeferredGroupIfNeeded()
        coordinator.refreshControls()
        coordinator.removeAllHistory()

        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("디바운스 타이머가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: UndoRedoCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            defer { fixture.restore() }
            fixture.proxy.insertText("가")
            fixture.coordinator.record(deletedText: "", insertedText: "가")
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingUndoRedoHost: UndoRedoHost {
    var calls: [String] = []
    var isPreviewMode = false
    var shouldDeferUndoRedoCommit = false
    let textDocument: CachingTextDocumentProxy

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func undoRedoEditDidApply() { calls.append("undoRedoEditDidApply") }
    func refreshReturnButtonEnabled() { calls.append("refreshReturnButtonEnabled") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func refreshClipboardControl() { calls.append("refreshClipboardControl") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
}

@MainActor
private struct Fixture {
    let coordinator: UndoRedoCoordinator
    let host: RecordingUndoRedoHost
    let service: FakeSuggestionService
    let bar: SuggestionBarView
    let proxy: CountingTextDocumentProxy
    private let oldUndoEnabled: Bool

    init(
        coordinator: UndoRedoCoordinator,
        host: RecordingUndoRedoHost,
        service: FakeSuggestionService,
        bar: SuggestionBarView,
        proxy: CountingTextDocumentProxy,
        oldUndoEnabled: Bool
    ) {
        self.coordinator = coordinator
        self.host = host
        self.service = service
        self.bar = bar
        self.proxy = proxy
        self.oldUndoEnabled = oldUndoEnabled
    }

    /// fixture가 켠 undo/redo 설정을 되돌린다. 각 테스트가 `defer`로 부른다
    func restore() {
        UserDefaultsManager.shared.isUndoRedoEnabled = oldUndoEnabled
    }
}

/// undo/redo 설정을 켜고, 빈 문서(`beforeInput = nil`)의 프록시와 기록용 host로 Coordinator를 만든다
@MainActor
private func makeFixture() -> Fixture {
    let settings = UserDefaultsManager.shared
    let oldUndoEnabled = settings.isUndoRedoEnabled
    settings.isUndoRedoEnabled = true
    let proxy = CountingTextDocumentProxy()
    proxy.beforeInput = nil
    let host = RecordingUndoRedoHost(proxy: proxy)
    let service = FakeSuggestionService()
    let bar = SuggestionBarView(keyboardHStackView: UIStackView())
    bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
    let coordinator = UndoRedoCoordinator(
        suggestionBarView: bar,
        suggestionController: service,
        keyboardSettingsManager: settings,
        host: host
    )
    return Fixture(coordinator: coordinator, host: host, service: service, bar: bar, proxy: proxy, oldUndoEnabled: oldUndoEnabled)
}
