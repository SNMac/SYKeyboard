//
//  NGramPredictiveTextEngineRankingTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram unigram 후보 순위 검증")
struct NGramPredictiveTextEngineRankingTests {

    @Test("항목 수가 상한보다 적으면 있는 만큼 빈도순으로 반환")
    func test항목수가상한보다적으면_있는만큼빈도순으로반환() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-fewer").engine
        record(engine, word: "alpha", times: 5)
        record(engine, word: "bravo", times: 4)
        record(engine, word: "charlie", times: 3)
        record(engine, word: "delta", times: 2)
        record(engine, word: "echo", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie", "delta", "echo"])
    }

    @Test("항목 수가 상한과 같으면 전부 빈도순으로 반환")
    func test항목수가상한과같으면_전부빈도순으로반환() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-exact").engine
        let words = (1...10).map { "word\($0)" }
        for (index, word) in words.enumerated() {
            record(engine, word: word, times: 20 - index)
        }

        #expect(engine.suggestions(for: "") == words)
    }

    @Test("항목 수가 상한보다 많으면 상위 10개만 빈도순으로 반환")
    func test항목수가상한보다많으면_상위10개만_빈도순으로반환() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-more").engine
        let words = (1...14).map { "word\($0)" }
        for (index, word) in words.enumerated() {
            record(engine, word: word, times: 30 - index)
        }

        #expect(engine.suggestions(for: "") == Array(words.prefix(10)))
    }

    @Test("학습으로 순위가 바뀌면 후보가 갱신")
    func test학습으로순위가바뀌면_후보가갱신() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-invalidate").engine
        record(engine, word: "alpha", times: 3)
        record(engine, word: "bravo", times: 2)
        record(engine, word: "charlie", times: 1)
        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])

        record(engine, word: "delta", times: 4)

        #expect(engine.suggestions(for: "") == ["delta", "alpha", "bravo", "charlie"])
    }

    @Test("초기화 후에는 후보가 없음")
    func test초기화후에는_후보가없음() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-reset").engine
        record(engine, word: "alpha", times: 2)
        #expect(engine.suggestions(for: "") == ["alpha"])

        engine.resetAllData()

        #expect(engine.suggestions(for: "") == [])
    }

    @Test("unigram 상한을 넘으면 최소 빈도 단어가 제거")
    func testUnigram상한을넘으면_최소빈도단어가제거() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-prune", maxKeys: 3).engine
        record(engine, word: "alpha", times: 4)
        record(engine, word: "bravo", times: 3)
        record(engine, word: "charlie", times: 2)
        record(engine, word: "delta", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])
    }

    @Test("문맥이 있으면 trigram → bigram → unigram 순으로 10칸을 채우고 중복을 제거")
    func test문맥이있으면_trigram다음bigram다음unigram순으로_10칸을채우고중복을제거() async {
        let engine = await makeLoadedNGramFixture(name: "ranking-backfill").engine

        // trigram "alpha bravo" → t1(3) t2(2) t3(1).
        // 같은 기록이 bigram "bravo" → t1/t2/t3도 함께 남긴다
        recordSentence(engine, words: ["alpha", "bravo", "t1"], times: 3)
        recordSentence(engine, words: ["alpha", "bravo", "t2"], times: 2)
        recordSentence(engine, words: ["alpha", "bravo", "t3"], times: 1)

        // bigram "bravo" → b1(5) b2(4). trigram에는 없는 후보다
        recordSentence(engine, words: ["bravo", "b1"], times: 5)
        recordSentence(engine, words: ["bravo", "b2"], times: 4)

        // unigram 보충용. 위 단어들보다 빈도가 높아 상위에 온다
        for (index, word) in ["u1", "u2", "u3", "u4", "u5", "u6"].enumerated() {
            recordSentence(engine, words: [word], times: 30 - index)
        }

        let results = engine.suggestions(for: "alpha bravo")

        // trigram 3개 → bigram에서 중복되지 않은 2개 → unigram으로 나머지 5칸
        #expect(results == ["t1", "t2", "t3", "b1", "b2", "u1", "u2", "u3", "u4", "u5"])
        #expect(results.count == 10)
        #expect(Set(results).count == results.count)
    }
}

private func record(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
    for _ in 0..<times {
        engine.addWord(word)
    }
}

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
