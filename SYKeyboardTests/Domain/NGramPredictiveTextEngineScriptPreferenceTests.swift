//
//  NGramPredictiveTextEngineScriptPreferenceTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram unigram 후보 문자 종류 우선 정렬 검증")
struct NGramPredictiveTextEngineScriptPreferenceTests {

    @Test("선호 문자 종류가 없으면 기존처럼 빈도순")
    func test선호문자종류가없으면_기존처럼빈도순() async {
        let engine = await makeMixedEngine(name: "script-none")

        #expect(engine.suggestions(for: "") == ["meeting", "오늘", "123", "SY키보드", "hello"])
        #expect(engine.suggestions(for: "", preferredScript: nil) == ["meeting", "오늘", "123", "SY키보드", "hello"])
    }

    @Test("선호 문자 종류를 앞에 두고 각 묶음 안은 빈도순")
    func test선호문자종류를앞에두고_각묶음안은빈도순() async {
        let engine = await makeMixedEngine(name: "script-prefer")

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == ["오늘", "SY키보드", "meeting", "123", "hello"])
        #expect(engine.suggestions(for: "", preferredScript: .latin) == ["meeting", "hello", "오늘", "123", "SY키보드"])
    }

    @Test("학습으로 순위가 바뀌면 선호 정렬 후보도 갱신")
    func test학습으로순위가바뀌면_선호정렬후보도갱신() async {
        let engine = await makeMixedEngine(name: "script-invalidate")
        #expect(engine.suggestions(for: "", preferredScript: .latin).first == "meeting")

        record(engine, word: "hello", times: 10)

        #expect(engine.suggestions(for: "", preferredScript: .latin) == ["hello", "meeting", "오늘", "123", "SY키보드"])
    }

    @Test("선호 문자 종류 단어가 부족하면 나머지를 빈도순으로 채움")
    func test선호문자종류단어가부족하면_나머지를빈도순으로채움() async {
        let engine = await makeLoadedNGramFixture(name: "script-fill").engine
        record(engine, word: "alpha", times: 9)
        record(engine, word: "bravo", times: 8)
        record(engine, word: "가나", times: 1)

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == ["가나", "alpha", "bravo"])
    }

    @Test("선호 문자 종류 단어가 10개 이상이면 상위 10개만")
    func test선호문자종류단어가10개이상이면_상위10개만() async {
        let engine = await makeLoadedNGramFixture(name: "script-overflow").engine
        let hangeulWords = ["가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타"]
        for (index, word) in hangeulWords.enumerated() {
            record(engine, word: word, times: 20 - index)
        }
        record(engine, word: "meeting", times: 50)

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == Array(hangeulWords.prefix(10)))
    }

    @Test("문맥 후보는 선호 문자 종류와 무관하게 빈도순")
    func test문맥후보는_선호문자종류와무관하게빈도순() async {
        let engine = await makeLoadedNGramFixture(name: "script-context").engine
        recordSentence(engine, words: ["오늘", "meeting"])
        recordSentence(engine, words: ["오늘", "날씨"])
        recordSentence(engine, words: ["오늘", "날씨"])

        #expect(Array(engine.suggestions(for: "오늘 ", preferredScript: .latin).prefix(2)) == ["날씨", "meeting"])
        #expect(Array(engine.suggestions(for: "오늘 ", preferredScript: .hangeul).prefix(2)) == ["날씨", "meeting"])
    }

    @Test("통합 식별자만 키 상한이 10000")
    func test통합식별자만_키상한이10000() {
        #expect(NGramPredictiveTextEngine.hangeulEnglishLanguage == "ko-en")
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "ko-en") == 10000)
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "ko-KR") == 5000)
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "en-US") == 5000)
    }
}

// MARK: - Helpers

/// 빈도: meeting 5, 오늘 4, 123 3, SY키보드 2, hello 1
private func makeMixedEngine(name: String) async -> NGramPredictiveTextEngine {
    let engine = await makeLoadedNGramFixture(name: name).engine
    record(engine, word: "meeting", times: 5)
    record(engine, word: "오늘", times: 4)
    record(engine, word: "123", times: 3)
    record(engine, word: "SY키보드", times: 2)
    record(engine, word: "hello", times: 1)
    return engine
}

private func record(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
    for _ in 0..<times {
        engine.addWord(word)
    }
}

private func recordSentence(_ engine: NGramPredictiveTextEngine, words: [String]) {
    for word in words {
        engine.addWord(word)
    }
    engine.endSentence()
}
