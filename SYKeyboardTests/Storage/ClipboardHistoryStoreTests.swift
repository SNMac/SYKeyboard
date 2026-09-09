//
//  ClipboardHistoryStoreTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 저장소 검증")
struct ClipboardHistoryStoreTests {

    @Test("기록 후 다시 읽으면 같은 텍스트가 최신순으로 반환")
    func test기록후_다시읽으면_최신순반환() {
        let fixture = makeFixture(name: "roundtrip")

        fixture.store.record("first", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("second", now: Date(timeIntervalSince1970: 2))

        #expect(fixture.store.load().map(\.text) == ["second", "first"])
        #expect(fixture.store.load().first?.createdAt == Date(timeIntervalSince1970: 2))
    }

    @Test("정책상 저장하지 않는 텍스트는 파일을 만들지 않음")
    func test저장대상이아니면_파일을만들지않음() {
        let fixture = makeFixture(name: "skip")

        fixture.store.record("   ")

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
        #expect(fixture.store.load().isEmpty)
    }

    @Test("텍스트 삭제는 해당 항목만 제거하고 없는 텍스트는 무시")
    func test텍스트삭제는_해당항목만제거() {
        let fixture = makeFixture(name: "remove")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))
        fixture.store.record("c", now: Date(timeIntervalSince1970: 3))

        fixture.store.remove(texts: ["b", "zzz"])

        #expect(fixture.store.load().map(\.text) == ["c", "a"])
    }

    @Test("전체 삭제 후에는 빈 배열")
    func test전체삭제후_빈배열() {
        let fixture = makeFixture(name: "remove-all")
        fixture.store.record("a")

        fixture.store.removeAll()

        #expect(fixture.store.load().isEmpty)
    }

    @Test("고정 토글은 파일에 반영되고 고정 항목이 맨 앞으로 이동")
    func test고정토글은_파일에반영() {
        let fixture = makeFixture(name: "pin")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))

        fixture.store.togglePin(at: 1, now: Date(timeIntervalSince1970: 3))

        let items = fixture.store.load()
        #expect(items.map(\.text) == ["a", "b"])
        #expect(items[0].pinnedAt == Date(timeIntervalSince1970: 3))
        #expect(items[1].pinnedAt == nil)

        fixture.store.togglePin(at: 0, now: Date(timeIntervalSince1970: 4))

        #expect(fixture.store.load().map(\.text) == ["b", "a"])
        #expect(fixture.store.load().allSatisfy { !$0.isPinned })
    }

    @Test("고정으로 순서가 바뀐 뒤에도 텍스트로 삭제하면 그 항목이 지워짐")
    func test고정재정렬후_텍스트삭제는_해당항목제거() {
        let fixture = makeFixture(name: "pin-then-remove")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))

        fixture.store.togglePin(at: 1, now: Date(timeIntervalSince1970: 3))
        fixture.store.remove(texts: ["a"])

        #expect(fixture.store.load().map(\.text) == ["b"])
    }

    @Test("직접 추가한 항목은 고정 상태로 파일에 저장")
    func test직접추가는_고정상태로저장() {
        let fixture = makeFixture(name: "record-pinned")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))

        fixture.store.recordPinned("manual", now: Date(timeIntervalSince1970: 2))

        let items = fixture.store.load()
        #expect(items.map(\.text) == ["manual", "a"])
        #expect(items[0].isPinned)
    }

    @Test("선택한 텍스트를 한 번에 고정하면 파일에 목록 순서대로 고정 저장")
    func test일괄고정은_파일에저장() {
        let fixture = makeFixture(name: "toggle-pins")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))
        fixture.store.record("c", now: Date(timeIntervalSince1970: 3))

        fixture.store.togglePins(selectedTexts: ["c", "a"], now: Date(timeIntervalSince1970: 10))

        let items = fixture.store.load()
        #expect(items.map(\.text) == ["c", "a", "b"])
        #expect(items.map(\.isPinned) == [true, true, false])
    }

    @Test("내용을 바꾸면 같은 자리에 새 텍스트로 저장되고 중복이면 그대로")
    func test내용편집은_같은자리에저장() {
        let fixture = makeFixture(name: "replace")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))

        fixture.store.replaceText("a", with: "a2")
        fixture.store.replaceText("b", with: "a2")

        #expect(fixture.store.load().map(\.text) == ["b", "a2"])
    }

    @Test("pinnedAt 키가 없는 기존 파일은 미고정 항목으로 읽힘")
    func test기존파일은_미고정으로읽힘() throws {
        let fixture = makeFixture(name: "legacy")
        let legacy: [[String: Any]] = [["text": "old", "createdAt": Date(timeIntervalSince1970: 1)]]
        let data = try PropertyListSerialization.data(fromPropertyList: legacy, format: .binary, options: 0)
        try data.write(to: fixture.url)

        let items = fixture.store.load()

        #expect(items.map(\.text) == ["old"])
        #expect(items.first?.isPinned == false)
    }

    @Test("파일에 같은 텍스트가 중복돼 있어도 첫 항목만 읽음")
    func test중복텍스트파일은_첫항목만읽음() throws {
        let fixture = makeFixture(name: "duplicate")
        let duplicated = [ClipboardHistoryItem(text: "dup", createdAt: Date(timeIntervalSince1970: 2)),
                          ClipboardHistoryItem(text: "dup", createdAt: Date(timeIntervalSince1970: 1))]
        try PropertyListEncoder().encode(duplicated).write(to: fixture.url)

        let items = fixture.store.load()

        #expect(items.map(\.text) == ["dup"])
        #expect(items.first?.createdAt == Date(timeIntervalSince1970: 2))
    }

    @Test("손상된 파일이면 빈 배열을 반환하고 crash하지 않음")
    func test손상된파일이면_빈배열() throws {
        let fixture = makeFixture(name: "corrupt")
        try Data("not a plist".utf8).write(to: fixture.url)

        #expect(fixture.store.load().isEmpty)
    }
}

private struct StoreFixture {
    let store: ClipboardHistoryStore
    let url: URL
}

private func makeFixture(name: String) -> StoreFixture {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    return StoreFixture(store: ClipboardHistoryStore(fileURL: url), url: url)
}
