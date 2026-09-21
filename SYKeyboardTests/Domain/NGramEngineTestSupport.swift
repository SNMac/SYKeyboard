//
//  NGramEngineTestSupport.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import Foundation

@testable import SYKeyboardCore

struct NGramEngineFixture {
    let engine: NGramPredictiveTextEngine
    let url: URL
    let saveQueue: DispatchQueue
}

/// 임시 파일을 쓰는 엔진을 만들고 초기 로딩이 끝날 때까지 기다린다
func makeLoadedNGramFixture(name: String, maxKeys: Int = 5000) async -> NGramEngineFixture {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.save.\(name)")
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        maxKeys: maxKeys,
        saveQueue: saveQueue
    )
    await waitForLoadCompletion(of: engine)
    return NGramEngineFixture(engine: engine, url: url, saveQueue: saveQueue)
}

func waitForLoadCompletion(of engine: NGramPredictiveTextEngine) async {
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
}

struct TestNGramData: Codable {
    var unigram: [String: Int]
    var bigram: [String: [String: Int]]
    var trigram: [String: [String: Int]]
}

/// 엔진이 읽는 형식(binary plist)으로 학습 데이터를 쓴다. 상위 디렉터리가 없으면 만든다
func writeNGramData(
    unigram: [String: Int],
    bigram: [String: [String: Int]] = [:],
    trigram: [String: [String: Int]] = [:],
    to url: URL
) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(TestNGramData(unigram: unigram, bigram: bigram, trigram: trigram))
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}
