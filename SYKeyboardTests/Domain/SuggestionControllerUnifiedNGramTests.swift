//
//  SuggestionControllerUnifiedNGramTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 통합 NGram 식별자 검증")
struct SuggestionControllerUnifiedNGramTests {

    @Test("통합 NGram은 언어를 바꿔도 같은 엔진과 문장 버퍼를 씀")
    func test통합NGram은_언어를바꿔도_같은엔진과문장버퍼를씀() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.recordWord("오늘")
        controller.updateLanguage(to: "en-US")
        controller.recordWord("meeting")

        #expect(factory.nGramLanguages == ["ko-en"])
        #expect(factory.textCheckerLanguages == ["ko-KR", "en-US"])
        #expect(factory.lastNGramProvider?.saveCount == 0)
        #expect(factory.lastNGramProvider?.currentSentenceWordsCount == 2)
    }

    @Test("통합 NGram 조회는 현재 언어 모드의 문자 종류를 넘김")
    func test통합NGram조회는_현재언어모드의문자종류를넘김() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestions(for: "")
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")

        #expect(factory.lastNGramProvider?.queriedPreferredScripts == [.hangeul, .latin])
    }

    @Test("언어별 NGram은 선호 문자 종류 없이 조회하고 전환 때 저장")
    func test언어별NGram은_선호문자종류없이조회하고_전환때저장() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "")
        let koreanEngine = factory.lastNGramProvider
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")

        #expect(koreanEngine?.queriedPreferredScripts == [nil])
        #expect(koreanEngine?.saveCount == 1)
        #expect(factory.nGramLanguages == ["ko-KR", "en-US"])
    }

    @Test("통합 NGram 로딩 중 언어를 바꿔도 로딩 완료 뒤 후보를 갱신")
    func test통합NGram로딩중언어를바꿔도_로딩완료뒤후보를갱신() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate

        controller.updateSuggestions(for: "")
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()

        #expect(delegate.updates.last?.suggestions == ["meeting"])
    }

    @Test("비활성 언어 엔진 해제는 통합 NGram 엔진을 남김")
    func test비활성언어엔진해제는_통합NGram엔진을남김() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateLanguage(to: "en-US")
        controller.releaseInactiveLanguageEngines()
        controller.preparePredictiveEnginesIfNeeded()

        #expect(factory.nGramCreationCount == 1)
    }

    @Test("통합 NGram은 언어를 바꿔도 후보를 비우지 않음")
    func test통합NGram은_언어를바꿔도_후보를비우지않음() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate
        controller.updateSuggestions(for: "오늘 ")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()
        let updateCount = delegate.updates.count

        controller.updateLanguage(to: "en-US")

        #expect(delegate.updates.count == updateCount)
        #expect(controller.currentMode == .nGram)
        #expect(controller.nGramSuggestionText(at: 0) == "meeting")
    }
}

// MARK: - Helpers

/// 한영 통합 키보드 설정의 컨트롤러. 자동완성을 켜고 엔진을 준비한다
private func makeUnifiedController(factory: CountingSuggestionEngineFactory) -> SuggestionController {
    let controller = SuggestionController(
        language: "ko-KR",
        nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage,
        engineFactory: factory.makeFactory()
    )
    controller.isPredictiveTextEnabled = true
    controller.preparePredictiveEnginesIfNeeded()
    return controller
}
