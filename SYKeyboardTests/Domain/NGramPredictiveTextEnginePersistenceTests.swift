//
//  NGramPredictiveTextEnginePersistenceTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 저장 조건 검증")
struct NGramPredictiveTextEnginePersistenceTests {

    @Test("변경이 없으면 저장을 건너뜀")
    func test변경이없으면_저장을건너뜀() async {
        let fixture = await makeLoadedNGramFixture(name: "persistence-skip")

        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
    }

    @Test("학습 후 문장을 끝내면 파일을 저장")
    func test학습후문장을끝내면_파일을저장() async {
        let fixture = await makeLoadedNGramFixture(name: "persistence-save")

        fixture.engine.addWord("hello")
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path))
    }

    @Test("초기화 후에는 저장해도 파일을 만들지 않음")
    func test초기화후에는_저장해도_파일을만들지않음() async {
        let fixture = await makeLoadedNGramFixture(name: "persistence-reset")
        fixture.engine.addWord("hello")

        fixture.engine.resetAllData()
        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
    }
}
