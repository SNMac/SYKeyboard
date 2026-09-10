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

        fixture.store.remove(ids: ["b", "zzz"])

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
        fixture.store.remove(ids: ["a"])

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

        fixture.store.togglePins(selectedIDs: ["c", "a"], now: Date(timeIntervalSince1970: 10))

        let items = fixture.store.load()
        #expect(items.map(\.text) == ["c", "a", "b"])
        #expect(items.map(\.isPinned) == [true, true, false])
    }

    @Test("내용을 바꾸면 같은 자리에 새 텍스트로 저장되고, 중복이면 기존 항목만 맨 위로 남음")
    func test내용편집은_같은자리에저장() {
        let fixture = makeFixture(name: "replace")
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 2))

        fixture.store.replaceText("a", with: "a2", now: Date(timeIntervalSince1970: 3))
        #expect(fixture.store.load().map(\.text) == ["b", "a2"])

        fixture.store.replaceText("b", with: "a2", now: Date(timeIntervalSince1970: 4))
        #expect(fixture.store.load().map(\.text) == ["a2"])
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

    @Test("이미지 항목은 image 키로 저장되고 다시 읽으면 같은 참조와 id로 돌아옴")
    func test이미지항목_왕복저장() {
        let fixture = makeFixture(name: "image-roundtrip")
        let reference = ClipboardImageReference(hash: "abc", typeIdentifier: "public.jpeg", byteSize: 2_048, pixelWidth: 40, pixelHeight: 30)

        fixture.store.record("text", now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 2))

        let items = fixture.store.load()
        #expect(items.map(\.id) == ["image/abc", "text"])
        #expect(items.first?.image == reference)
        #expect(items.first?.text == nil)
        #expect(items.last?.image == nil)
    }

    @Test("text 키만 있는 기존 파일과 image 키가 있는 파일을 함께 읽음")
    func test기존텍스트파일과_이미지항목_혼합읽기() throws {
        let fixture = makeFixture(name: "mixed-legacy")
        let legacy: [[String: Any]] = [
            ["text": "old", "createdAt": Date(timeIntervalSince1970: 1)],
            ["image": ["hash": "h", "typeIdentifier": "public.png", "byteSize": 10, "pixelWidth": 1, "pixelHeight": 1],
             "createdAt": Date(timeIntervalSince1970: 2)]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: legacy, format: .binary, options: 0)
        try data.write(to: fixture.url)

        #expect(fixture.store.load().map(\.id) == ["old", "image/h"])
    }

    @Test("id로 삭제하면 텍스트·이미지 항목이 함께 지워짐")
    func testId삭제는_텍스트이미지_함께제거() {
        let fixture = makeFixture(name: "remove-ids")
        let reference = ClipboardImageReference(hash: "h", typeIdentifier: "public.png", byteSize: 10, pixelWidth: 1, pixelHeight: 1)
        fixture.store.record("a", now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 2))
        fixture.store.record("b", now: Date(timeIntervalSince1970: 3))

        fixture.store.remove(ids: ["image/h", "a"])

        #expect(fixture.store.load().map(\.id) == ["b"])
    }

    @Test("이미지 항목을 지우면 원본·썸네일 파일도 지워지고 남은 항목의 파일은 유지")
    func test이미지항목삭제는_파일도삭제() throws {
        let fixture = makeFixture(name: "delete-files")
        let keep = try makeStoredImage(hash: "keep", in: fixture)
        let gone = try makeStoredImage(hash: "gone", in: fixture)
        fixture.store.record(.image(keep), now: Date(timeIntervalSince1970: 1))
        fixture.store.record(.image(gone), now: Date(timeIntervalSince1970: 2))

        fixture.store.remove(ids: ["image/gone"])

        #expect(fixture.store.load().map(\.id) == ["image/keep"])
        #expect(try fixture.imageFiles() == ["keep.png", "keep.thumb.jpg"])
    }

    @Test("미고정 한도에 밀려난 이미지 항목의 파일도 지워짐")
    func test트리밍된이미지는_파일도삭제() throws {
        let fixture = makeFixture(name: "trim-files")
        let oldest = try makeStoredImage(hash: "oldest", in: fixture)
        fixture.store.record(.image(oldest), now: Date(timeIntervalSince1970: 0))
        for index in 1...ClipboardHistoryPolicy.maxItemCount {
            fixture.store.record("t\(index)", now: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        #expect(fixture.store.load().contains(where: { $0.id == "image/oldest" }) == false)
        #expect(try fixture.imageFiles().isEmpty)
    }

    @Test("전체 삭제는 이미지 디렉터리도 비움")
    func test전체삭제는_이미지파일도삭제() throws {
        let fixture = makeFixture(name: "remove-all-files")
        let reference = try makeStoredImage(hash: "h", in: fixture)
        fixture.store.record(.image(reference))
        fixture.store.record("a")

        fixture.store.removeAll()

        #expect(fixture.store.load().isEmpty)
        #expect(try fixture.imageFiles().isEmpty)
    }

    @Test("텍스트만 바뀐 저장은 이미지 파일을 건드리지 않음")
    func test텍스트만변경은_이미지파일유지() throws {
        let fixture = makeFixture(name: "text-only-save")
        let reference = try makeStoredImage(hash: "h", in: fixture)
        fixture.store.record(.image(reference), now: Date(timeIntervalSince1970: 1))

        fixture.store.record("a", now: Date(timeIntervalSince1970: 2))
        fixture.store.remove(ids: ["a"])

        #expect(try fixture.imageFiles() == ["h.png", "h.thumb.jpg"])
    }

    @Test("plist 쓰기가 실패하면 전체 삭제여도 이미지 파일을 지우지 않음")
    func test전체삭제_쓰기실패시_이미지파일유지() throws {
        // 부모 디렉터리가 없으면 Data.write(..., options: .atomic)이 실패한다. 같은 imageStore를 공유하는
        // 쓰기 불가능한 store로 removeAll()을 호출해, plist 쓰기 실패 시 파일 정리를 건너뛰는지 확인한다
        let fixture = makeFixture(name: "remove-all-write-fails")
        _ = try makeStoredImage(hash: "h", in: fixture)
        let unwritableURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-missing-parent", isDirectory: true)
            .appendingPathComponent("history.plist")
        let unwritableStore = ClipboardHistoryStore(fileURL: unwritableURL, imageStore: fixture.store.imageStore)

        unwritableStore.removeAll()

        #expect(try fixture.imageFiles() == ["h.png", "h.thumb.jpg"])
    }

    @Test("id가 같은 텍스트 항목과 이미지 항목이 섞인 파일은 첫 항목만 읽음")
    func testId충돌파일은_첫항목만읽음() throws {
        let fixture = makeFixture(name: "id-collision")
        // text가 "image/h"인 텍스트 항목의 id는 이미지 항목 hash "h"의 id "image/h"와 충돌한다
        let legacy: [[String: Any]] = [
            ["text": "image/h", "createdAt": Date(timeIntervalSince1970: 1)],
            ["image": ["hash": "h", "typeIdentifier": "public.png", "byteSize": 10, "pixelWidth": 1, "pixelHeight": 1],
             "createdAt": Date(timeIntervalSince1970: 2)]
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: legacy, format: .binary, options: 0)
        try data.write(to: fixture.url)

        let items = fixture.store.load()

        #expect(items.count == 1)
        #expect(items.first?.text == "image/h")
    }
}

private struct StoreFixture {
    let store: ClipboardHistoryStore
    let url: URL
    let imageDirectoryURL: URL

    func imageFiles() throws -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: imageDirectoryURL.path)) ?? []).sorted()
    }
}

private func makeFixture(name: String) -> StoreFixture {
    let base = "SYKeyboardTests-\(UUID().uuidString)-\(name)"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(base).plist")
    let imageDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(base, isDirectory: true)
    let imageStore = ClipboardImageStore(directoryURL: imageDirectoryURL)
    return StoreFixture(store: ClipboardHistoryStore(fileURL: url, imageStore: imageStore), url: url, imageDirectoryURL: imageDirectoryURL)
}

/// 이미지 저장소 디렉터리에 해시 이름의 원본·썸네일 빈 파일을 만들어 실제 저장을 흉내 낸다
private func makeStoredImage(hash: String, in fixture: StoreFixture) throws -> ClipboardImageReference {
    try FileManager.default.createDirectory(at: fixture.imageDirectoryURL, withIntermediateDirectories: true)
    let reference = ClipboardImageReference(hash: hash, typeIdentifier: "public.png", byteSize: 10, pixelWidth: 1, pixelHeight: 1)
    try Data("o".utf8).write(to: fixture.store.imageStore!.originalURL(for: reference))
    try Data("t".utf8).write(to: fixture.store.imageStore!.thumbnailURL(for: reference))
    return reference
}
