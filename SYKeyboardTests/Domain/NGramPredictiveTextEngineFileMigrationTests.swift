//
//  NGramPredictiveTextEngineFileMigrationTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 파일 위치 이동 검증")
struct NGramPredictiveTextEngineFileMigrationTests {

    @Test("옛 위치 파일만 있으면 새 위치로 옮기고 학습 데이터를 유지")
    func test옛파일만있으면_새위치로옮기고_데이터유지() async throws {
        let paths = try makeContainer(name: "legacy-only")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)

        let engine = makeEngine(paths: paths, name: "legacy-only")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.fileURL.path))
        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
        #expect(engine.suggestions(for: "") == ["legacy"])
    }

    @Test("새 위치 파일이 이미 있으면 옛 파일을 옮기지 않고 새 파일을 읽음")
    func test새파일이있으면_옛파일을옮기지않음() async throws {
        let paths = try makeContainer(name: "both")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try writeNGramData(unigram: ["new": 3], to: paths.fileURL)

        let engine = makeEngine(paths: paths, name: "both")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path))
        #expect(engine.suggestions(for: "") == ["new"])
    }

    @Test("두 위치 모두 파일이 없으면 저장할 때 새 위치에 디렉터리를 만들어 저장")
    func test파일이없으면_새위치에저장() async throws {
        let paths = try makeContainer(name: "none")
        let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.migration.none")

        let engine = makeEngine(paths: paths, name: "none", saveQueue: saveQueue)
        await waitForLoadCompletion(of: engine)
        engine.addWord("hello")
        engine.endSentence()
        saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: paths.fileURL.path))
        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
    }

    @Test("옮기기에 실패하면 옛 위치 파일을 계속 읽음")
    func test옮기기실패하면_옛파일을읽음() async throws {
        let paths = try makeContainer(name: "move-failed")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try blockApplicationSupportDirectory(in: paths)

        let engine = makeEngine(paths: paths, name: "move-failed")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path))
        #expect(engine.suggestions(for: "") == ["legacy"])
    }

    @Test("초기화하면 옮기지 못한 옛 위치 파일도 삭제")
    func test초기화는_옛파일도삭제() throws {
        let paths = try makeContainer(name: "reset")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try blockApplicationSupportDirectory(in: paths)

        let engine = makeEngine(paths: paths, name: "reset")
        engine.resetAllData()

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
    }
}

private struct ContainerPaths {
    let containerURL: URL
    /// 새 위치: `Library/Application Support/ngram_test.plist`
    let fileURL: URL
    /// 옛 위치: 컨테이너 루트의 `ngram_test.plist`
    let legacyURL: URL
}

private func makeContainer(name: String) throws -> ContainerPaths {
    let containerURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name)", isDirectory: true)
    try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
    return ContainerPaths(
        containerURL: containerURL,
        fileURL: containerURL.appendingPathComponent("Library/Application Support/ngram_test.plist"),
        legacyURL: containerURL.appendingPathComponent("ngram_test.plist")
    )
}

/// `Library` 자리에 일반 파일을 둬서 `Application Support` 디렉터리 생성과 이동이 실패하게 만든다
private func blockApplicationSupportDirectory(in paths: ContainerPaths) throws {
    try Data().write(to: paths.containerURL.appendingPathComponent("Library"))
}

private func makeEngine(
    paths: ContainerPaths,
    name: String,
    saveQueue: DispatchQueue = DispatchQueue(label: "SYKeyboardTests.ngram.migration")
) -> NGramPredictiveTextEngine {
    NGramPredictiveTextEngine(
        language: "test-migration-\(name)",
        fileURL: paths.fileURL,
        legacyFileURL: paths.legacyURL,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        saveQueue: saveQueue
    )
}
