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

    @Test("인덱스 삭제는 해당 항목만 제거하고 범위 밖 인덱스는 무시")
    func test인덱스삭제는_해당항목만제거() {
        let fixture = makeFixture(name: "remove")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))
        fixture.store.record("c", now: Date(timeIntervalSince1970: 3))

        fixture.store.remove(at: [1, 99])

        #expect(fixture.store.load().map(\.text) == ["c", "a"])
    }

    @Test("전체 삭제 후에는 빈 배열")
    func test전체삭제후_빈배열() {
        let fixture = makeFixture(name: "remove-all")
        fixture.store.record("a")

        fixture.store.removeAll()

        #expect(fixture.store.load().isEmpty)
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
