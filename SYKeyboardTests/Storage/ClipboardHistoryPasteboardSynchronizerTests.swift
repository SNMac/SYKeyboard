//
//  ClipboardHistoryPasteboardSynchronizerTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/9/26.
//

import Foundation
import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("클립보드 pasteboard 동기화 검증", .serialized)
struct ClipboardHistoryPasteboardSynchronizerTests {

    @Test("changeCount가 바뀌었을 때만 pasteboard 텍스트를 기록")
    func testChangeCount가바뀌었을때만_기록() {
        let fixture = makeFixture(name: "sync")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().map(\.text) == ["hello"])
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)

        fixture.store.removeAll()
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().isEmpty)

        fixture.pasteboard.string = "world"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().map(\.text) == ["world"])
    }

    @Test("concealed 타입이 있는 항목은 기록하지 않고 changeCount만 갱신")
    func testConcealed항목은_기록하지않음() {
        let fixture = makeFixture(name: "concealed")
        defer { fixture.restore() }
        fixture.pasteboard.setItems([[
            ClipboardHistoryPasteboardSynchronizer.concealedPasteboardType: "1",
            "public.utf8-plain-text": "secret"
        ]])

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }
}

private struct SyncFixture {
    let store: ClipboardHistoryStore
    let pasteboard: UIPasteboard
    let originalChangeCount: Any?

    func restore() {
        let storage = UserDefaultsManager.shared.storage
        if let originalChangeCount {
            storage.set(originalChangeCount, forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        }
        UIPasteboard.remove(withName: pasteboard.name)
    }
}

private func makeFixture(name: String) -> SyncFixture {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    let pasteboard = UIPasteboard(name: UIPasteboard.Name("SYKeyboardTests.\(name).\(UUID().uuidString)"), create: true)!
    let storage = UserDefaultsManager.shared.storage
    let original = storage.object(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    return SyncFixture(store: ClipboardHistoryStore(fileURL: url), pasteboard: pasteboard, originalChangeCount: original)
}
