//
//  NGramPredictiveTextEngineSentenceBufferTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 문장 버퍼 복원 검증")
struct NGramPredictiveTextEngineSentenceBufferTests {

    @Test("복원한 문장 버퍼 뒤에 기록한 단어는 앞 단어와 bigram으로 이어짐")
    func test복원한문장버퍼뒤에기록한단어는_앞단어와bigram으로이어짐() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-restore").engine
        recordSeparately(engine, word: "zulu", times: 3)
        engine.addWord("안녕")
        let words = engine.currentSentenceWords
        engine.resetSentenceBuffer()

        engine.restoreSentenceBuffer(words)
        engine.addWord("ㅋㅋ")

        #expect(words == ["안녕"])
        // bigram이 없으면 unigram 점수가 높은 zulu가 먼저 나온다
        #expect(engine.suggestions(for: "안녕 ").first == "ㅋㅋ")
    }

    @Test("복원하지 않으면 리셋 뒤 단어는 앞 단어와 이어지지 않음")
    func test복원하지않으면_리셋뒤단어는_앞단어와이어지지않음() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-no-restore").engine
        recordSeparately(engine, word: "zulu", times: 3)
        engine.addWord("안녕")
        engine.resetSentenceBuffer()

        engine.addWord("ㅋㅋ")

        #expect(engine.suggestions(for: "안녕 ").first == "zulu")
    }

    @Test("복원만 하면 아무것도 기록하지 않음")
    func test복원만하면_아무것도기록하지않음() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-restore-only").engine

        engine.restoreSentenceBuffer(["alpha", "bravo"])

        #expect(engine.currentSentenceWords == ["alpha", "bravo"])
        #expect(engine.suggestions(for: "") == [])
    }

    /// 단어를 매번 다른 문장으로 기록해 unigram 점수만 올린다
    private func recordSeparately(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
        for _ in 0..<times {
            engine.addWord(word)
            engine.endSentence()
        }
    }
}
