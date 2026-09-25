//
//  NGramPredictiveTextEngineCompletionTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 입력 중 단어 완성 조회 검증")
struct NGramPredictiveTextEngineCompletionTests {

    @Test("접두어가 맞는 unigram을 빈도순으로 limit개까지 반환")
    func test접두어가맞는unigram을_빈도순으로_limit개까지반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-unigram").engine
        recordAlone(engine, "키보드", times: 3)
        recordAlone(engine, "키보드로", times: 5)
        recordAlone(engine, "키위", times: 4)
        recordAlone(engine, "키보드를", times: 2)
        recordAlone(engine, "마우스", times: 9)

        #expect(engine.completions(forTypedWord: "키보", previousWord: nil, limit: 3) == ["키보드로", "키보드", "키보드를"])
        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == ["키보드로", "키위", "키보드"])
    }

    @Test("받침이 다음 글자 초성일 수 있는 조합 중 단어도 완성 후보를 찾음")
    func test받침이다음글자초성일수있는_조합중단어도_완성후보를찾음() async {
        let engine = await makeLoadedNGramFixture(name: "completion-jamo").engine
        recordAlone(engine, "키보드", times: 1)
        recordAlone(engine, "달걀", times: 1)

        #expect(engine.completions(forTypedWord: "키볻", previousWord: nil, limit: 3) == ["키보드"])
        #expect(engine.completions(forTypedWord: "닭", previousWord: nil, limit: 3) == ["달걀"])
    }

    @Test("대소문자를 무시하고 저장된 표기 그대로 반환")
    func test대소문자를무시하고_저장된표기그대로반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-case").engine
        recordAlone(engine, "SY키보드", times: 1)

        #expect(engine.completions(forTypedWord: "sy", previousWord: nil, limit: 3) == ["SY키보드"])
        #expect(engine.completions(forTypedWord: "sy키", previousWord: nil, limit: 3) == ["SY키보드"])
    }

    @Test("입력 중인 단어와 같은 단어는 빼고 반환")
    func test입력중인단어와같은단어는_빼고반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-exclude-typed").engine
        recordAlone(engine, "키보드", times: 5)
        recordAlone(engine, "키보드로", times: 1)
        recordAlone(engine, "KEYBOARD", times: 5)
        recordAlone(engine, "keyboards", times: 1)

        #expect(engine.completions(forTypedWord: "키보드", previousWord: nil, limit: 3) == ["키보드로"])
        #expect(engine.completions(forTypedWord: "keyboard", previousWord: nil, limit: 3) == ["keyboards"])
    }

    @Test("바로 앞 단어의 bigram 후보를 unigram 빈도보다 먼저 반환")
    func test바로앞단어의bigram후보를_unigram빈도보다먼저반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-bigram").engine
        recordPair(engine, "오늘", "날씨", times: 2)
        recordAlone(engine, "날개", times: 9)
        recordAlone(engine, "날짜", times: 5)

        #expect(engine.completions(forTypedWord: "날", previousWord: nil, limit: 3) == ["날개", "날짜", "날씨"])
        #expect(engine.completions(forTypedWord: "날", previousWord: "오늘", limit: 3) == ["날씨", "날개", "날짜"])
        #expect(engine.completions(forTypedWord: "날", previousWord: "오늘", limit: 1) == ["날씨"])
    }

    @Test("디스크 로딩 전에는 빈 배열을 반환하고 로딩 뒤에 찾음")
    func test디스크로딩전에는_빈배열을반환하고_로딩뒤에찾음() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-completion-loading.plist")
        try writeNGramData(unigram: ["키보드": 3], to: url)
        let gate = NGramLoadGate()
        let engine = NGramPredictiveTextEngine(
            language: "test-completion-loading",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyScheduler: gate.schedule
        )

        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == [])

        await gate.finishLoading()

        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == ["키보드"])
    }
}

/// 문맥 없이 unigram만 남도록 문장 버퍼를 비우고 기록한다
private func recordAlone(_ engine: NGramPredictiveTextEngine, _ word: String, times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        engine.addWord(word)
    }
}

/// `first` → `second` bigram을 남긴다
private func recordPair(_ engine: NGramPredictiveTextEngine, _ first: String, _ second: String, times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        engine.addWord(first)
        engine.addWord(second)
    }
}
