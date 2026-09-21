//
//  NGramPredictiveTextEngineRemovalTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 단어 삭제 검증")
struct NGramPredictiveTextEngineRemovalTests {

    @Test("삭제한 단어는 unigram·bigram 예측에서 사라짐")
    func test삭제한단어는_unigram_bigram예측에서사라짐() async {
        let fixture = await makeLoadedNGramFixture(name: "removal-suggestions")
        fixture.engine.addWord("오늘")
        fixture.engine.addWord("날씨")
        fixture.engine.endSentence()
        #expect(fixture.engine.suggestions(for: "오늘 ") == ["날씨", "오늘"])

        fixture.engine.removeWord("날씨")

        #expect(fixture.engine.suggestions(for: "오늘 ") == ["오늘"])
        #expect(fixture.engine.suggestions(for: "") == ["오늘"])
    }

    @Test("삭제하면 값과 문맥 키에서 모두 지우고 바로 저장")
    func test삭제하면_값과문맥키에서모두지우고_바로저장() async throws {
        let fixture = await makeLoadedNGramFixture(name: "removal-file")
        fixture.engine.addWord("오늘")
        fixture.engine.addWord("날씨")
        fixture.engine.addWord("좋다")
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        fixture.engine.removeWord("날씨")
        fixture.saveQueue.sync {}

        let data = try Data(contentsOf: fixture.url)
        let plist = try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        #expect(plist["unigram"] as? [String: Int] == ["오늘": 1, "좋다": 1])
        #expect(plist["bigram"] as? [String: [String: Int]] == [:])
        #expect(plist["trigram"] as? [String: [String: Int]] == [:])
    }

    @Test("대소문자가 다른 같은 단어도 함께 삭제")
    func test대소문자가다른같은단어도_함께삭제() async {
        let fixture = await makeLoadedNGramFixture(name: "removal-case")
        fixture.engine.addWord("Hello")
        fixture.engine.endSentence()
        fixture.engine.addWord("hello")
        fixture.engine.endSentence()

        fixture.engine.removeWord("hello")

        #expect(fixture.engine.suggestions(for: "") == [])
    }
}
