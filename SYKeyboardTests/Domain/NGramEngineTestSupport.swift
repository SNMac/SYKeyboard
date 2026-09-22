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
    let gate = NGramLoadGate()
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyScheduler: gate.schedule,
        maxKeys: maxKeys,
        saveQueue: saveQueue
    )
    await gate.finishLoading()
    return NGramEngineFixture(engine: engine, url: url, saveQueue: saveQueue)
}

/// 엔진이 디스크를 읽은 뒤 메모리 반영을 테스트가 정한 시점까지 미룬다.
/// `NGramPredictiveTextEngine(loadApplyScheduler: gate.schedule)`로 넘긴다
final class NGramLoadGate: @unchecked Sendable {
    private let lock = NSLock()
    private var pendingApply: (() -> Void)?
    private var readWaiter: CheckedContinuation<Void, Never>?

    func schedule(_ apply: @escaping () -> Void) {
        lock.lock()
        pendingApply = apply
        let waiter = readWaiter
        readWaiter = nil
        lock.unlock()
        waiter?.resume()
    }

    /// 디스크 읽기가 끝날 때까지 기다린다. 아직 메모리에는 반영되지 않은 상태다
    func waitForRead() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if pendingApply != nil {
                lock.unlock()
                continuation.resume()
            } else {
                readWaiter = continuation
                lock.unlock()
            }
        }
    }

    /// 읽은 데이터를 main에서 메모리에 반영한다
    func finishLoading() async {
        await waitForRead()
        lock.lock()
        let apply = pendingApply
        pendingApply = nil
        lock.unlock()
        await MainActor.run { apply?() }
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
