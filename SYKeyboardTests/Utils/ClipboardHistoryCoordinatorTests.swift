//
//  ClipboardHistoryCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("클립보드 기록 Coordinator", .sharedUserDefaults)
@MainActor
struct ClipboardHistoryCoordinatorTests {

    @Test("패널 토글은 삭제 보류를 끊고 열었다가 다시 닫음")
    func testTogglePanelOpensThenCloses() {
        let fixture = makeFixture()
        defer { fixture.restore() }

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible)
        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "refreshShowingKeyboard", "refreshClipboardControl"])

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible == false)
        #expect(fixture.host.calls.suffix(2) == ["refreshShowingKeyboard", "refreshClipboardControl"])
    }

    @Test("닫힌 패널에 closePanelIfNeeded는 아무 것도 하지 않음")
    func testClosePanelIfNeededWhenClosedDoesNothing() {
        let fixture = makeFixture()
        defer { fixture.restore() }

        fixture.coordinator.closePanelIfNeeded()

        #expect(fixture.host.calls.isEmpty)
        #expect(fixture.coordinator.isPanelVisible == false)
    }

    @Test("열린 패널에 closePanelIfNeeded는 닫고 자판과 클립보드 버튼을 갱신")
    func testClosePanelIfNeededWhenOpenCloses() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.coordinator.togglePanel()
        fixture.host.calls.removeAll()

        fixture.coordinator.closePanelIfNeeded()

        #expect(fixture.coordinator.isPanelVisible == false)
        #expect(fixture.host.calls == ["refreshShowingKeyboard", "refreshClipboardControl"])
    }

    @Test("텍스트 항목 탭은 undo 1단위로 삽입하고 기록 맨 위로 올리고 패널을 닫음")
    func testTextItemTapInsertsAsOneUndoGroupAndRecords() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.store.record("이전")
        fixture.coordinator.togglePanel()
        fixture.host.calls.removeAll()
        fixture.panel.configure(state: .items([
            ClipboardHistoryItem(text: "이전", createdAt: Date()),
            ClipboardHistoryItem(text: "복사", createdAt: Date())
        ]))

        fixture.coordinator.clipboardPanel(fixture.panel, didSelectItemAt: 1)

        #expect(fixture.host.calls == [
            "commitUndoRedoGroupIgnoringCompositionDeferral",
            "insertText(복사)",
            "undoRedoEditDidApply",
            "commitUndoRedoGroupIgnoringCompositionDeferral",
            "refreshShowingKeyboard",
            "refreshClipboardControl",
            "refreshReturnButtonEnabled",
            "refreshSuggestions"
        ])
        #expect(fixture.coordinator.isPanelVisible == false)
        #expect(fixture.store.load().first?.text == "복사")
    }

    @Test("항목 삭제는 저장소에서 id로 지우고 패널을 다시 읽음")
    func testDeleteItemsRemovesFromStore() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.hasFullAccess = true
        fixture.store.record("하나")
        fixture.store.record("둘")
        fixture.coordinator.togglePanel()
        #expect(fixture.panel.items.map(\.text) == ["둘", "하나"])

        fixture.coordinator.clipboardPanel(fixture.panel, didDeleteItemsAt: [0])

        #expect(fixture.store.load().map(\.text) == ["하나"])
        #expect(fixture.panel.items.map(\.text) == ["하나"])
    }

    @Test("Full Access가 없으면 패널은 안내 상태로 열림")
    func testPanelShowsFullAccessRequiredWithoutFullAccess() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.store.record("하나")

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible)
        #expect(fixture.panel.items.isEmpty)
    }

    @Test("URL 항목 탭은 host에 열기를 요청")
    func testOpenURLRequestForwardsToHost() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.panel.configure(state: .items([
            ClipboardHistoryItem(text: "https://example.com", createdAt: Date())
        ]))

        fixture.coordinator.clipboardPanel(fixture.panel, didRequestOpenURLAt: 0)

        #expect(fixture.host.openedURLs == [URL(string: "https://example.com")!])
    }

    @Test("미리보기에서는 Full Access가 있어도 pasteboard를 복사하지 않음")
    func testPreviewDoesNotWriteToPasteboard() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.hasFullAccess = true
        fixture.host.isPreviewMode = true
        let settings = UserDefaultsManager.shared
        settings.lastSeenPasteboardChangeCount = -1
        fixture.panel.configure(state: .items([ClipboardHistoryItem(text: "복사", createdAt: Date())]))

        fixture.coordinator.clipboardPanel(fixture.panel, didSelectItemAt: 0)

        // 복사했다면 changeCount를 갱신한다. 미리보기는 복사 자체를 건너뛴다
        #expect(settings.lastSeenPasteboardChangeCount == -1)
        #expect(fixture.host.calls.contains("insertText(복사)"))
    }

    @Test("host가 해제된 뒤에는 토글·알림이 아무 것도 하지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        var host: RecordingClipboardHistoryHost? = RecordingClipboardHistoryHost()
        host?.hasFullAccess = true
        let coordinator = ClipboardHistoryCoordinator(
            clipboardHistoryStore: fixture.store,
            clipboardHistoryPanelView: fixture.panel,
            keyboardSettingsManager: .shared,
            host: host!
        )
        fixture.store.record("하나")
        host = nil

        coordinator.togglePanel()
        coordinator.synchronizeIfNeeded()
        coordinator.hostDidBecomeActive()
        coordinator.clipboardImageDidRecord()
        // pasteboard 변경 알림은 다음 런루프에서 처리하므로 한 틱 돌린 뒤 확인한다
        coordinator.pasteboardDidChange()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        #expect(coordinator.isPanelVisible == false)
        #expect(fixture.panel.items.isEmpty)
    }

    @Test("observer와 예약 작업이 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: ClipboardHistoryCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            defer { fixture.restore() }
            fixture.coordinator.registerNotificationObservers()
            fixture.coordinator.pasteboardDidChange()
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        NotificationCenter.default.post(name: UIPasteboard.changedNotification, object: nil)
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingClipboardHistoryHost: ClipboardHistoryHost {
    var calls: [String] = []
    var openedURLs: [URL] = []
    /// 기본 false. 켜면 저장소 읽기와 pasteboard 복사 경로가 열린다
    var hasFullAccess = false
    var isPreviewMode = false
    var isViewInWindow = true

    func insertText(_ text: String) { calls.append("insertText(\(text))") }
    func commitUndoRedoGroupIgnoringCompositionDeferral() { calls.append("commitUndoRedoGroupIgnoringCompositionDeferral") }
    func undoRedoEditDidApply() { calls.append("undoRedoEditDidApply") }
    func refreshShowingKeyboard() { calls.append("refreshShowingKeyboard") }
    func refreshClipboardControl() { calls.append("refreshClipboardControl") }
    func refreshReturnButtonEnabled() { calls.append("refreshReturnButtonEnabled") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
    func openURL(_ url: URL) { openedURLs.append(url) }
}

@MainActor
private struct Fixture {
    let coordinator: ClipboardHistoryCoordinator
    let host: RecordingClipboardHistoryHost
    let store: ClipboardHistoryStore
    let panel: ClipboardHistoryPanelView
    private let oldClipboardEnabled: Bool
    private let oldChangeCount: Int

    init(
        coordinator: ClipboardHistoryCoordinator,
        host: RecordingClipboardHistoryHost,
        store: ClipboardHistoryStore,
        panel: ClipboardHistoryPanelView,
        oldClipboardEnabled: Bool,
        oldChangeCount: Int
    ) {
        self.coordinator = coordinator
        self.host = host
        self.store = store
        self.panel = panel
        self.oldClipboardEnabled = oldClipboardEnabled
        self.oldChangeCount = oldChangeCount
    }

    /// fixture가 바꾼 설정을 되돌린다. 각 테스트가 `defer`로 부른다
    func restore() {
        UserDefaultsManager.shared.isClipboardHistoryEnabled = oldClipboardEnabled
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = oldChangeCount
    }
}

/// 임시 디렉터리의 저장소, 실제 패널 뷰, 기록용 host.
/// 클립보드 설정은 켜고, pasteboard 동기화가 `string`을 읽지 않도록 `changeCount`를 현재 값으로 맞춘다(`changeCount` 읽기는 권한 알림을 띄우지 않는다)
@MainActor
private func makeFixture() -> Fixture {
    let settings = UserDefaultsManager.shared
    let oldClipboardEnabled = settings.isClipboardHistoryEnabled
    let oldChangeCount = settings.lastSeenPasteboardChangeCount
    settings.isClipboardHistoryEnabled = true
    settings.lastSeenPasteboardChangeCount = UIPasteboard.general.changeCount

    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ClipboardHistoryCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let store = ClipboardHistoryStore(
        fileURL: directory.appendingPathComponent("history.plist"),
        imageStore: ClipboardImageStore(directoryURL: directory.appendingPathComponent("images", isDirectory: true))
    )
    let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let host = RecordingClipboardHistoryHost()
    let coordinator = ClipboardHistoryCoordinator(
        clipboardHistoryStore: store,
        clipboardHistoryPanelView: panel,
        keyboardSettingsManager: settings,
        host: host
    )
    panel.delegate = coordinator
    return Fixture(
        coordinator: coordinator,
        host: host,
        store: store,
        panel: panel,
        oldClipboardEnabled: oldClipboardEnabled,
        oldChangeCount: oldChangeCount
    )
}
