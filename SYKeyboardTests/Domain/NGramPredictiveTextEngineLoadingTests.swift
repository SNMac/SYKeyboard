//
//  NGramPredictiveTextEngineLoadingTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/16/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 로딩 중 기록 검증")
struct NGramPredictiveTextEngineLoadingTests {

    @Test("로딩 전에 기록한 단어는 로딩 완료 후 학습에 반영")
    func test로딩전기록한단어는_로딩완료후_학습에반영() async throws {
        let url = temporaryFileURL(name: "pending-word.plist")
        let engine = NGramPredictiveTextEngine(
            language: "test-pending-word",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyDelay: .milliseconds(100)
        )

        engine.addWord("hello")
        await waitForLoadCompletion(of: engine)

        #expect(engine.suggestions(for: "") == ["hello"])
    }

    @Test("reset 이후 완료된 이전 로딩 결과는 메모리에 반영하지 않음")
    func testReset이후완료된_이전로딩결과는_메모리에반영하지않음() async throws {
        let url = temporaryFileURL(name: "reset-generation.plist")
        try writeNGramData(
            unigram: ["stale": 3],
            bigram: [:],
            trigram: [:],
            to: url
        )
        let engine = NGramPredictiveTextEngine(
            language: "test-reset-generation",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyDelay: .milliseconds(100)
        )

        engine.resetAllData()
        try await Task.sleep(for: .milliseconds(200))

        #expect(engine.suggestions(for: "") == [])
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }
}

private struct TestNGramData: Codable {
    var unigram: [String: Int]
    var bigram: [String: [String: Int]]
    var trigram: [String: [String: Int]]
}

private func temporaryFileURL(name: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name)")
}

private func writeNGramData(
    unigram: [String: Int],
    bigram: [String: [String: Int]],
    trigram: [String: [String: Int]],
    to url: URL
) throws {
    let data = TestNGramData(
        unigram: unigram,
        bigram: bigram,
        trigram: trigram
    )
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    try encoder.encode(data).write(to: url, options: .atomic)
}

private func waitForLoadCompletion(of engine: NGramPredictiveTextEngine) async {
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
}
