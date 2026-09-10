//
//  ClipboardHistoryPasteboardSynchronizerTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/9/26.
//

import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers

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

    @Test("텍스트 없이 이미지만 있으면 파일로 받아 이미지 항목을 기록하고 완료 콜백을 부름")
    func test이미지만있으면_이미지항목기록() async throws {
        let fixture = makeFixture(name: "image")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                availableMemory: { .max },
                onImageRecorded: { continuation.resume() }
            )
        }

        let items = fixture.store.load()
        let reference = try #require(items.first?.image)
        #expect(items.count == 1)
        #expect(reference.typeIdentifier == "public.png")
        #expect(reference.pixelWidth == 8)
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.originalURL(for: reference).path))
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.thumbnailURL(for: reference).path))
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("텍스트와 이미지가 함께 있으면 텍스트만 기록")
    func test텍스트와이미지_함께면_텍스트만기록() {
        let fixture = makeFixture(name: "text-and-image")
        defer { fixture.restore() }
        fixture.pasteboard.setItems([["public.utf8-plain-text": "hello", "public.png": makePNGData()]])

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { .max }
        )

        #expect(fixture.store.load().map(\.id) == ["hello"])
    }

    @Test("이미지 기록 설정이 꺼져 있으면 이미지를 기록하지 않고 changeCount만 갱신")
    func test이미지설정OFF는_기록없음() {
        let fixture = makeFixture(name: "image-disabled")
        defer { fixture.restore() }
        UserDefaultsManager.shared.isClipboardImageHistoryEnabled = false
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { .max }
        )

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("남은 메모리가 부족하면 이미지를 기록하지 않고 changeCount만 갱신")
    func test메모리부족은_기록없음() {
        let fixture = makeFixture(name: "low-memory")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, availableMemory: { 0 }
        )

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }
}

private struct SyncFixture {
    let store: ClipboardHistoryStore
    let fileURL: URL
    let imageDirectoryURL: URL
    let pasteboard: UIPasteboard
    let originalChangeCount: Any?
    let originalImageEnabled: Any?

    func restore() {
        let storage = UserDefaultsManager.shared.storage
        if let originalChangeCount {
            storage.set(originalChangeCount, forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        }
        if let originalImageEnabled {
            storage.set(originalImageEnabled, forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
        }
        UIPasteboard.remove(withName: pasteboard.name)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: imageDirectoryURL)
    }
}

private func makeFixture(name: String) -> SyncFixture {
    let base = "SYKeyboardTests-\(UUID().uuidString)-\(name)"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(base).plist")
    let imageDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(base, isDirectory: true)
    let pasteboard = UIPasteboard(name: UIPasteboard.Name("SYKeyboardTests.\(name).\(UUID().uuidString)"), create: true)!
    let storage = UserDefaultsManager.shared.storage
    let originalChangeCount = storage.object(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    let originalImageEnabled = storage.object(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    storage.removeObject(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    let store = ClipboardHistoryStore(fileURL: url, imageStore: ClipboardImageStore(directoryURL: imageDirectoryURL))
    return SyncFixture(
        store: store, fileURL: url, imageDirectoryURL: imageDirectoryURL, pasteboard: pasteboard,
        originalChangeCount: originalChangeCount, originalImageEnabled: originalImageEnabled
    )
}

/// 8×8 PNG 바이트. ImageIO로 인코드해 pasteboard에 넣는다
private func makePNGData() -> Data {
    let context = CGContext(
        data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
}
