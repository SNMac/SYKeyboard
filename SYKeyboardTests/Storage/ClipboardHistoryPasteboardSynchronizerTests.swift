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

@Suite("클립보드 pasteboard 동기화 검증", .serialized, .sharedUserDefaults)
struct ClipboardHistoryPasteboardSynchronizerTests {

    @Test("changeCount가 바뀌었을 때만 pasteboard 텍스트를 기록")
    func testChangeCount가바뀌었을때만_기록() {
        let fixture = makeFixture(name: "sync")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().map(\.text) == ["hello"])
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
        // 공유 값은 직접 쓴 경우에만 맞춘다. 동기화가 쓰면 다른 프로세스가 자기 카운터와 비교해 새 복사를 건너뛸 수 있다
        #expect(UserDefaultsManager.shared.lastSeenPasteboardChangeCount == DefaultValues.lastSeenPasteboardChangeCount)

        fixture.store.removeAll()
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().isEmpty)

        fixture.pasteboard.string = "world"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().map(\.text) == ["world"])
    }

    @Test("다른 프로세스가 공유 확인값을 다른 changeCount로 덮어써도 이 프로세스가 이미 본 내용은 다시 읽지 않음")
    func test다른프로세스가_공유확인값을덮어써도_다시읽지않음() {
        let fixture = makeFixture(name: "other-process")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        fixture.store.removeAll()

        // 키보드 extension이 자기에게 보인 다른 changeCount로 공유 값을 덮어쓴 상황
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = fixture.pasteboard.changeCount + 100
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().isEmpty)

        fixture.pasteboard.string = "world"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        #expect(fixture.store.load().map(\.text) == ["world"])
    }

    @Test("다른 프로세스가 이미 읽은 changeCount여도 이 프로세스가 본 적 없으면 읽음")
    func test다른프로세스가읽은값이어도_이프로세스는읽음() {
        let fixture = makeFixture(name: "other-process-read")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        fixture.store.removeAll()

        // 확인값이 없는 다른 프로세스(번들). 카운터가 프로세스마다 달라 이 값이 새 복사일 수 있으므로 건너뛰면 안 된다
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)

        #expect(fixture.store.load().map(\.text) == ["hello"])
    }

    @Test("다른 프로세스가 맞춰 둔 공유 확인값과 같으면 이 프로세스도 읽지 않음")
    func test공유확인값과같으면_읽지않음() {
        let fixture = makeFixture(name: "shared-seen")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"
        // 앱이나 키보드가 직접 복사한 뒤 공유 값을 맞춰 둔 상황
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = fixture.pasteboard.changeCount

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)

        #expect(fixture.store.load().isEmpty)
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("이 프로세스의 확인값은 App Group이 아니라 프로세스별 standard 저장소의 키에 저장")
    func test프로세스확인값_저장위치와키() {
        let fixture = makeFixture(name: "process-key")
        defer { fixture.restore() }
        let key = UserDefaultsKeys.processLastSeenPasteboardChangeCount
        #expect(key == "processLastSeenPasteboardChangeCount")
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == -1)

        fixture.pasteboard.string = "hello"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)

        #expect(UserDefaults.standard.integer(forKey: key) == fixture.pasteboard.changeCount)
        #expect(UserDefaultsManager.shared.storage.object(forKey: key) == nil)
    }

    @Test("텍스트도 이미지도 없는 pasteboard는 확인값을 갱신하지 않음")
    func test빈pasteboard는_확인값을갱신하지않음() {
        let fixture = makeFixture(name: "empty")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        let seenChangeCount = fixture.pasteboard.changeCount

        fixture.pasteboard.items = []
        #expect(fixture.pasteboard.changeCount != seenChangeCount)
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)

        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == seenChangeCount)
    }

    @Test("접근이 거부돼 changeCount가 0으로 보이면 읽지 않고 확인값도 갱신하지 않음")
    func test접근거부_changeCount0은_읽지않음() {
        let fixture = makeFixture(name: "denied")
        defer { fixture.restore() }
        fixture.pasteboard.string = "hello"
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: fixture.store, pasteboard: fixture.pasteboard)
        let seenChangeCount = ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: DeniedAccessPasteboard()
        )

        #expect(fixture.store.load().map(\.text) == ["hello"])
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == seenChangeCount)
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
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("텍스트 없이 이미지만 있으면 파일로 받아 이미지 항목을 기록하고 완료 알림을 게시")
    func test이미지만있으면_이미지항목기록() async throws {
        let fixture = makeFixture(name: "image")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        await performAndWait(for: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification, from: fixture.store) {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                decodeMemoryBudget: .max
            )
        }

        let items = fixture.store.load()
        let reference = try #require(items.first?.image)
        #expect(items.count == 1)
        #expect(reference.typeIdentifier == "public.png")
        #expect(reference.pixelWidth == 8)
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.originalURL(for: reference).path))
        #expect(FileManager.default.fileExists(atPath: fixture.store.imageStore!.thumbnailURL(for: reference).path))
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("텍스트와 이미지가 함께 있으면 텍스트만 기록")
    func test텍스트와이미지_함께면_텍스트만기록() async {
        let fixture = makeFixture(name: "text-and-image")
        defer { fixture.restore() }
        fixture.pasteboard.setItems([["public.utf8-plain-text": "hello", "public.png": makePNGData()]])

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, decodeMemoryBudget: .max
        )
        #expect(fixture.store.load().map(\.id) == ["hello"])

        await recordFollowUpImage(in: fixture)

        // 8px 이미지가 잘못 저장됐다면 뒤따른 16px 이미지보다 먼저 기록되어 여기 함께 남는다
        #expect(fixture.store.load().compactMap(\.image).map(\.pixelWidth) == [16])
    }

    @Test("이미지 기록 설정이 꺼져 있으면 이미지를 기록하지 않고 changeCount만 갱신")
    func test이미지설정OFF는_기록없음() async {
        let fixture = makeFixture(name: "image-disabled")
        defer { fixture.restore() }
        UserDefaultsManager.shared.isClipboardImageHistoryEnabled = false
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, decodeMemoryBudget: .max
        )

        #expect(fixture.store.load().isEmpty)
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)

        UserDefaultsManager.shared.isClipboardImageHistoryEnabled = true
        await recordFollowUpImage(in: fixture)

        // 설정이 꺼진 동안의 8px 이미지가 잘못 저장됐다면 여기 함께 남는다
        #expect(fixture.store.load().compactMap(\.image).map(\.pixelWidth) == [16])
    }

    @Test("키보드가 예산 초과로 건너뛰면 기록하지 않고 changeCount를 갱신하며 건너뛴 changeCount를 남김")
    func test키보드예산초과는_건너뛴changeCount를남김() async {
        let fixture = makeFixture(name: "low-budget")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")

        await performAndWait(for: ClipboardHistoryPasteboardSynchronizer.didSkipImageForBudgetNotification, from: fixture.store) {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                decodeMemoryBudget: 0
            )
        }

        #expect(fixture.store.load().isEmpty)
        #expect(ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount == fixture.pasteboard.changeCount)
        #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == fixture.pasteboard.changeCount)
    }

    @Test("키보드가 건너뛴 pasteboard를 앱 예산으로 다시 시도하면 기록하고 건너뜀 표시를 지움")
    func test앱은_건너뛴이미지를_다시시도해기록() async throws {
        let fixture = makeFixture(name: "budget-retry")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")
        // 이 프로세스가 이미 확인했고 키보드가 예산 초과로 건너뛴 상태
        ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount = fixture.pasteboard.changeCount
        UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount = fixture.pasteboard.changeCount

        // 다시 시도 플래그가 없으면(키보드) 같은 changeCount는 건너뛴다
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store, pasteboard: fixture.pasteboard, decodeMemoryBudget: .max
        )
        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == fixture.pasteboard.changeCount)

        await performAndWait(for: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification, from: fixture.store) {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                decodeMemoryBudget: ClipboardImagePolicy.appDecodeMemoryBudget,
                retriesBudgetSkipped: true
            )
        }

        let reference = try #require(fixture.store.load().first?.image)
        #expect(reference.pixelWidth == 8)
        #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == DefaultValues.budgetSkippedPasteboardChangeCount)
    }

    @Test("앱이 다시 시도하는 pasteboard를 또 예산 초과로 건너뛰면 표시를 남기지 않아 반복하지 않음")
    func test앱재시도에서_또건너뛰면_표시없음() async {
        let fixture = makeFixture(name: "budget-retry-skip")
        defer { fixture.restore() }
        fixture.pasteboard.setData(makePNGData(), forPasteboardType: "public.png")
        ClipboardHistoryPasteboardSynchronizer.processLastSeenPasteboardChangeCount = fixture.pasteboard.changeCount
        UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount = fixture.pasteboard.changeCount

        await performAndWait(for: ClipboardHistoryPasteboardSynchronizer.didSkipImageForBudgetNotification, from: fixture.store) {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: fixture.store,
                pasteboard: fixture.pasteboard,
                decodeMemoryBudget: 0,
                retriesBudgetSkipped: true
            )
        }

        #expect(fixture.store.load().isEmpty)
        #expect(UserDefaultsManager.shared.budgetSkippedPasteboardChangeCount == DefaultValues.budgetSkippedPasteboardChangeCount)
    }
}

/// 접근이 거부된 pasteboard. `pasted`가 거부하면 `changeCount`는 0으로 보이면서 `hasStrings`는 참을 돌려주는데,
/// 실제 `UIPasteboard`로는 이 조합을 만들 수 없다
private final class DeniedAccessPasteboard: ClipboardPasteboard {
    let changeCount = 0
    let hasStrings = true
    let hasImages = false
    let string: String? = "denied"
    let types = ["public.utf8-plain-text"]
    let itemProviders: [NSItemProvider] = []
    func contains(pasteboardTypes: [String]) -> Bool { false }
}

/// `body`를 실행하고 `store`가 게시한 `name` 알림이 한 번 올 때까지 기다린다. 동기화기의 백그라운드 이미지 저장이 끝나는 시점을 잡는다.
/// observer를 `body`보다 먼저 등록해 알림을 놓치지 않고, object를 store로 한정해 테스트 호스트 앱이 실제 store로 게시한 알림에 깨어나지 않는다.
/// 알림이 끝내 오지 않으면 테스트가 멈추는 대신 실패하도록 상한을 둔다. 상한은 성공 조건이 아니라 정지를 잡기 위한 값이다
@discardableResult
private func performAndWait(
    for name: Notification.Name,
    from store: ClipboardHistoryStore,
    timeout: TimeInterval = 30,
    _ body: () -> Void
) async -> Bool {
    let waiter = NotificationWaiter()
    let observer = NotificationCenter.default.addObserver(forName: name, object: store, queue: nil) { _ in
        waiter.finish(true)
    }
    defer { NotificationCenter.default.removeObserver(observer) }

    body()
    let didReceive = await withCheckedContinuation { continuation in
        waiter.setContinuation(continuation)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { waiter.finish(false) }
    }
    #expect(didReceive, "\(name.rawValue) 알림이 \(Int(timeout))초 안에 오지 않음")
    return didReceive
}

/// 알림과 상한 중 먼저 온 쪽으로 continuation을 한 번만 재개한다
private final class NotificationWaiter: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?
    private var result: Bool?

    func setContinuation(_ continuation: CheckedContinuation<Bool, Never>) {
        lock.lock()
        if let result {
            lock.unlock()
            continuation.resume(returning: result)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func finish(_ value: Bool) {
        lock.lock()
        guard result == nil else {
            lock.unlock()
            return
        }
        result = value
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}

/// 이미지 저장은 비동기라 "기록하지 않음"을 호출 직후에 단언하면 저장이 끝나기 전이라 늘 통과한다.
/// 크기가 다른 이미지를 뒤이어 기록하고 그 완료를 기다려, 앞선 이미지 저장이 시작됐다면 끝났을 시점에 단언하게 한다.
/// 같은 바이트면 해시가 같아 한 항목으로 합쳐지므로 크기를 다르게 한다.
/// 같은 pasteboard의 내용을 바꾸면 진행 중이던 앞선 로드가 취소되어 잘못된 기록이 드러나지 않으므로 별도 pasteboard를 쓴다.
/// 두 로드의 완료 순서는 시스템이 정하므로, 앞선 저장이 후속 이미지보다 늦게 끝나는 경우까지는 잡지 못한다
private func recordFollowUpImage(in fixture: SyncFixture) async {
    let name = UIPasteboard.Name("SYKeyboardTests.follow-up.\(UUID().uuidString)")
    let followUpPasteboard = UIPasteboard(name: name, create: true)!
    defer { UIPasteboard.remove(withName: name) }
    followUpPasteboard.setData(makePNGData(side: 16), forPasteboardType: "public.png")
    // 새 pasteboard의 changeCount가 마지막 확인값과 우연히 같아 건너뛰지 않게 한다
    UserDefaultsManager.shared.storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)

    await performAndWait(for: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification, from: fixture.store) {
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
            store: fixture.store,
            pasteboard: followUpPasteboard,
            decodeMemoryBudget: .max
        )
    }
}

private struct SyncFixture {
    let store: ClipboardHistoryStore
    let fileURL: URL
    let imageDirectoryURL: URL
    let pasteboard: UIPasteboard
    let originalChangeCount: Any?
    let originalProcessChangeCount: Any?
    let originalBudgetSkipped: Any?
    let originalImageEnabled: Any?

    func restore() {
        let storage = UserDefaultsManager.shared.storage
        if let originalChangeCount {
            storage.set(originalChangeCount, forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
        }
        if let originalProcessChangeCount {
            UserDefaults.standard.set(originalProcessChangeCount, forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)
        } else {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)
        }
        if let originalBudgetSkipped {
            storage.set(originalBudgetSkipped, forKey: UserDefaultsKeys.budgetSkippedPasteboardChangeCount)
        } else {
            storage.removeObject(forKey: UserDefaultsKeys.budgetSkippedPasteboardChangeCount)
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
    // 갓 만든 pasteboard는 changeCount가 0이고 동기화기는 0을 접근 거부로 보고 건너뛴다(#154).
    // 내용을 쓰면 1 이상이 되므로, 쓰기 전에 동기화를 부르는 테스트는 아무 일도 하지 않는다
    let pasteboard = UIPasteboard(name: UIPasteboard.Name("SYKeyboardTests.\(name).\(UUID().uuidString)"), create: true)!
    let storage = UserDefaultsManager.shared.storage
    let originalChangeCount = storage.object(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    let originalProcessChangeCount = UserDefaults.standard.object(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)
    let originalBudgetSkipped = storage.object(forKey: UserDefaultsKeys.budgetSkippedPasteboardChangeCount)
    let originalImageEnabled = storage.object(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    storage.removeObject(forKey: UserDefaultsKeys.lastSeenPasteboardChangeCount)
    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount)
    storage.removeObject(forKey: UserDefaultsKeys.budgetSkippedPasteboardChangeCount)
    storage.removeObject(forKey: UserDefaultsKeys.isClipboardImageHistoryEnabled)
    let store = ClipboardHistoryStore(fileURL: url, imageStore: ClipboardImageStore(directoryURL: imageDirectoryURL))
    return SyncFixture(
        store: store, fileURL: url, imageDirectoryURL: imageDirectoryURL, pasteboard: pasteboard,
        originalChangeCount: originalChangeCount, originalProcessChangeCount: originalProcessChangeCount,
        originalBudgetSkipped: originalBudgetSkipped,
        originalImageEnabled: originalImageEnabled
    )
}

/// 정사각형 PNG 바이트(기본 8×8). ImageIO로 인코드해 pasteboard에 넣는다
private func makePNGData(side: Int = 8) -> Data {
    let context = CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: side, height: side))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
}
