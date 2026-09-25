//
//  NGramPredictiveTextEnginePruneTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 문맥 키 상한 정리 검증")
struct NGramPredictiveTextEnginePruneTests {

    @Test("bigram 문맥 키가 상한을 넘으면 총 빈도가 가장 낮은 문맥이 제거")
    func testBigram문맥키가상한을넘으면_총빈도가가장낮은문맥이제거() async {
        let engine = await makeLoadedNGramFixture(name: "prune-bigram", maxKeys: 3).engine
        recordSentence(engine, words: ["a", "xa"], times: 4)
        recordSentence(engine, words: ["b", "xb"], times: 3)
        recordSentence(engine, words: ["c", "xc"], times: 2)
        recordSentence(engine, words: ["d", "xd"], times: 1)

        #expect(engine.suggestions(for: "a ").first == "xa")
        #expect(engine.suggestions(for: "b ").first == "xb")
        #expect(engine.suggestions(for: "c ").first == "xc")
        // 문맥이 지워졌으면 unigram 보충만 남는다
        #expect(engine.suggestions(for: "d ") == engine.suggestions(for: ""))
    }

    @Test("trigram 문맥 키가 상한을 넘으면 총 빈도가 가장 낮은 문맥이 제거")
    func testTrigram문맥키가상한을넘으면_총빈도가가장낮은문맥이제거() async {
        let engine = await makeLoadedNGramFixture(name: "prune-trigram", maxKeys: 3).engine
        recordSentence(engine, words: ["p", "a", "xa"], times: 4)
        recordSentence(engine, words: ["p", "b", "xb"], times: 3)
        recordSentence(engine, words: ["p", "c", "xc"], times: 2)
        recordSentence(engine, words: ["p", "d", "xd"], times: 1)

        #expect(engine.suggestions(for: "p a ").first == "xa")
        #expect(engine.suggestions(for: "p b ").first == "xb")
        #expect(engine.suggestions(for: "p c ").first == "xc")
        // trigram 문맥이 지워졌으면 bigram "d"부터 채운 결과와 같다
        #expect(engine.suggestions(for: "p d ") == engine.suggestions(for: "d "))
    }
}

// MARK: - Helpers

private func recordSentence(
    _ engine: NGramPredictiveTextEngine,
    words: [String],
    times: Int
) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        for word in words {
            engine.addWord(word)
        }
    }
}
