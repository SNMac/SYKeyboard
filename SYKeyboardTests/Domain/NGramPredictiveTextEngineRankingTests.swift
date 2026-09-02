//
//  NGramPredictiveTextEngineRankingTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram unigram 후보 순위 검증")
struct NGramPredictiveTextEngineRankingTests {

    @Test("문맥이 없으면 빈도 상위 3개를 빈도순으로 반환")
    func test문맥이없으면_빈도상위3개를_빈도순으로반환() async {
        let engine = await makeLoadedEngine(name: "ranking-top3")
        record(engine, word: "alpha", times: 5)
        record(engine, word: "bravo", times: 4)
        record(engine, word: "charlie", times: 3)
        record(engine, word: "delta", times: 2)
        record(engine, word: "echo", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])
    }

    @Test("학습으로 순위가 바뀌면 후보가 갱신")
    func test학습으로순위가바뀌면_후보가갱신() async {
        let engine = await makeLoadedEngine(name: "ranking-invalidate")
        record(engine, word: "alpha", times: 3)
        record(engine, word: "bravo", times: 2)
        record(engine, word: "charlie", times: 1)
        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])

        record(engine, word: "delta", times: 4)

        #expect(engine.suggestions(for: "") == ["delta", "alpha", "bravo"])
    }

    @Test("초기화 후에는 후보가 없음")
    func test초기화후에는_후보가없음() async {
        let engine = await makeLoadedEngine(name: "ranking-reset")
        record(engine, word: "alpha", times: 2)
        #expect(engine.suggestions(for: "") == ["alpha"])

        engine.resetAllData()

        #expect(engine.suggestions(for: "") == [])
    }

    @Test("unigram 상한을 넘으면 최소 빈도 단어가 제거")
    func testUnigram상한을넘으면_최소빈도단어가제거() async {
        let engine = await makeLoadedEngine(name: "ranking-prune", maxKeys: 3)
        record(engine, word: "alpha", times: 4)
        record(engine, word: "bravo", times: 3)
        record(engine, word: "charlie", times: 2)
        record(engine, word: "delta", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])
    }
}

private func makeLoadedEngine(name: String, maxKeys: Int = 5000) async -> NGramPredictiveTextEngine {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        maxKeys: maxKeys
    )
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
    return engine
}

private func record(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
    for _ in 0..<times {
        engine.addWord(word)
    }
}
