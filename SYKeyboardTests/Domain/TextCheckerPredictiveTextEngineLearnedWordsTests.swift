//
//  TextCheckerPredictiveTextEngineLearnedWordsTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

/// `UITextChecker.learnWord`는 시뮬레이터 전역 사전을 바꾸므로 부르지 않고,
/// 저장소에 쓴 학습 단어 목록으로 삭제 가능 여부를 판단하는지만 확인한다
@Suite("TextChecker 학습 단어 목록 기반 삭제 판정 검증")
struct TextCheckerPredictiveTextEngineLearnedWordsTests {

    @Test("삭제 가능 여부는 무효화 전까지 처음 읽은 목록을 유지하고, 무효화 후 저장소를 다시 읽음")
    func test삭제가능여부는_무효화전까지처음읽은목록을유지하고_무효화후다시읽음() {
        let (suiteName, storage) = makeStorage()
        defer { storage.removePersistentDomain(forName: suiteName) }
        let key = TextCheckerPredictiveTextEngine.learnedWordsKey
        storage.set(["alpha"], forKey: key)
        let engine = TextCheckerPredictiveTextEngine(language: "en_US", storage: storage)

        #expect(engine.canUnlearn(word: "alpha"))
        #expect(!engine.canUnlearn(word: "beta"))

        // 다른 프로세스가 목록을 바꾼 상황
        storage.set(["beta"], forKey: key)
        #expect(engine.canUnlearn(word: "alpha"))
        #expect(!engine.canUnlearn(word: "beta"))

        engine.invalidateLearnedWordsCache()
        #expect(!engine.canUnlearn(word: "alpha"))
        #expect(engine.canUnlearn(word: "beta"))
    }

    @Test("시스템 사전에 없는 목록 단어도 삭제하면 목록에서 빠짐")
    func test시스템사전에없는목록단어도_삭제하면목록에서빠짐() {
        // iOS 키보드 사전 재설정으로 시스템 사전에서만 빠진 단어
        let word = "zzsyk161resetonly"
        let (suiteName, storage) = makeStorage()
        defer { storage.removePersistentDomain(forName: suiteName) }
        let key = TextCheckerPredictiveTextEngine.learnedWordsKey
        storage.set([word, "keep"], forKey: key)
        let engine = TextCheckerPredictiveTextEngine(language: "en_US", storage: storage)
        #expect(engine.canUnlearn(word: word))

        engine.unlearn(word: word)

        #expect(!engine.canUnlearn(word: word))
        #expect(storage.stringArray(forKey: key) == ["keep"])
    }

    @Test("전체 초기화 뒤에는 목록에 있던 단어도 삭제 대상이 아님")
    func test전체초기화뒤에는_목록에있던단어도_삭제대상이아님() {
        // 시스템 사전에 없는 단어라 unlearnWord가 전역 사전을 바꾸지 않는다
        let word = "zzsyk161resetall"
        let (suiteName, storage) = makeStorage()
        defer { storage.removePersistentDomain(forName: suiteName) }
        let key = TextCheckerPredictiveTextEngine.learnedWordsKey
        storage.set([word], forKey: key)
        let engine = TextCheckerPredictiveTextEngine(language: "en_US", storage: storage)
        #expect(engine.canUnlearn(word: word))

        engine.unlearnAllWords()

        #expect(!engine.canUnlearn(word: word))
        #expect(storage.stringArray(forKey: key) == [])
    }

    private func makeStorage() -> (String, UserDefaults) {
        let suiteName = "TextCheckerPredictiveTextEngineLearnedWordsTests-\(UUID().uuidString)"
        return (suiteName, UserDefaults(suiteName: suiteName)!)
    }
}
