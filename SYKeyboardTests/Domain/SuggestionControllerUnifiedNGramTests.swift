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

        // 언어 전환 자체가 NGram 후보를 새 문자 종류로 한 번 다시 조회한다
        #expect(factory.lastNGramProvider?.queriedPreferredScripts == [.hangeul, .latin, .latin])
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

    @Test("통합 NGram 후보를 보이는 중 언어를 바꾸면 새 언어의 문자 종류 순서로 다시 보냄")
    func test통합NGram후보를보이는중_언어를바꾸면_새언어순서로다시보냄() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate
        factory.lastNGramProvider?.resultsByPreferredScript = [
            .hangeul: ["아", "ok"],
            .latin: ["ok", "아"]
        ]
        controller.updateSuggestions(for: "")
        factory.lastNGramProvider?.completeLoad(suggestions: [])
        await waitForMainQueue()
        #expect(delegate.updates.last?.suggestions == ["아", "ok"])

        controller.updateLanguage(to: "en-US")

        #expect(delegate.updates.last?.suggestions == ["ok", "아"])
        #expect(controller.currentMode == .nGram)
        #expect(controller.nGramSuggestionText(at: 0) == "ok")
    }

    @Test("입력 중 후보를 보이는 중에는 언어를 바꿔도 후보를 다시 계산하지 않음")
    func test입력중후보를보이는중에는_언어를바꿔도_다시계산하지않음() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let queue = DispatchQueue(label: "SuggestionControllerUnifiedNGramTests.textChecker")
        let controller = makeUnifiedController(factory: factory, textCheckerQueue: queue)
        controller.delegate = delegate
        factory.lastNGramProvider?.completeLoad(suggestions: [])
        // 로딩 완료 콜백의 재갱신이 "sy" 요청 뒤에 돌면 TextChecker 결과가 한 번 더 늦게 온다
        await waitForMainQueue()
        controller.updateSuggestions(for: "sy")
        // TextChecker 결과 전달까지 끝난 뒤의 횟수를 기준으로 삼는다
        queue.sync {}
        await waitForMainQueue()
        let updateCount = delegate.updates.count
        let queryCount = factory.lastNGramProvider?.queriedPreferredScripts.count

        controller.updateLanguage(to: "en-US")
        queue.sync {}
        await waitForMainQueue()

        #expect(controller.currentMode == .typing)
        #expect(delegate.updates.count == updateCount)
        #expect(factory.lastNGramProvider?.queriedPreferredScripts.count == queryCount)
    }

    @Test("수식 후보를 보이는 중에는 언어를 바꿔도 NGram 후보로 덮지 않음")
    func test수식후보를보이는중에는_언어를바꿔도_NGram후보로덮지않음() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate
        controller.isShowMathResultsEnabled = true
        factory.lastNGramProvider?.completeLoad(suggestions: ["ok"])
        await waitForMainQueue()
        controller.updateSuggestions(for: "3-1=")
        let mathUpdate = delegate.updates.last
        let updateCount = delegate.updates.count

        controller.updateLanguage(to: "en-US")

        #expect(controller.currentMode == .mathExpression)
        #expect(delegate.updates.count == updateCount)
        #expect(delegate.updates.last == mathUpdate)
    }
}

// MARK: - Helpers

/// 한영 통합 키보드 설정의 컨트롤러. 자동완성을 켜고 엔진을 준비한다
private func makeUnifiedController(
    factory: CountingSuggestionEngineFactory,
    textCheckerQueue: DispatchQueue = DispatchQueue(label: "SuggestionControllerUnifiedNGramTests.default")
) -> SuggestionController {
    let controller = SuggestionController(
        language: "ko-KR",
        nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage,
        engineFactory: factory.makeFactory(),
        textCheckerQueue: textCheckerQueue
    )
    controller.isPredictiveTextEnabled = true
    controller.preparePredictiveEnginesIfNeeded()
    return controller
}
