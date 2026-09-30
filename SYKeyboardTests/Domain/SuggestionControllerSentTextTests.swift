//
//  SuggestionControllerSentTextTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 보낸 문장 기록 검증")
struct SuggestionControllerSentTextTests {

    @Test("문장 버퍼를 복원해 끝내면 기록하지 않은 단어만 추가하고 문장을 끝냄")
    func test문장버퍼를복원해끝내면_기록하지않은단어만추가하고_문장을끝냄() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()

        controller.endSentence(inputBuffer: "안녕 ㅋㅋ", restoringSentenceWords: snapshot)

        #expect(snapshot == ["안녕"])
        #expect(factory.lastNGramProvider?.addedWords == ["안녕", "ㅋㅋ"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
        #expect(factory.lastNGramProvider?.currentSentenceWordsCount == 0)
    }

    @Test("단어 하나만 보내면 그 단어를 기록")
    func test단어하나만보내면_그단어를기록() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)

        controller.endSentence(inputBuffer: "ㅇㅇ", restoringSentenceWords: controller.sentenceWordsSnapshot())

        #expect(factory.lastNGramProvider?.addedWords == ["ㅇㅇ"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
    }

    @Test("끝이 공백이면 이미 기록한 단어를 다시 세지 않고 문장만 끝냄")
    func test끝이공백이면_이미기록한단어를다시세지않고_문장만끝냄() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()

        controller.endSentence(inputBuffer: "안녕 ", restoringSentenceWords: snapshot)

        #expect(factory.lastNGramProvider?.addedWords == ["안녕"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
    }

    @Test("엔진을 만들기 전이면 빈 스냅샷을 반환")
    func test엔진을만들기전이면_빈스냅샷을반환() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)

        #expect(controller.sentenceWordsSnapshot() == [])
        #expect(factory.nGramCreationCount == 0)
    }

    @Test("예측 입력이 꺼져 있으면 기록하지 않음")
    func test예측입력이꺼져있으면_기록하지않음() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.isPredictiveTextEnabled = false

        controller.endSentence(inputBuffer: "ㅇㅇ", restoringSentenceWords: [])

        #expect(factory.nGramCreationCount == 0)
    }

    @Test("일시 중단 중이면 기록하지 않음")
    func test일시중단중이면_기록하지않음() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()
        controller.isSuspended = true

        controller.endSentence(inputBuffer: "안녕 ㅋㅋ", restoringSentenceWords: snapshot)

        #expect(factory.lastNGramProvider?.addedWords == ["안녕"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 0)
    }

    private func makeController(factory: CountingSuggestionEngineFactory) -> SuggestionController {
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
        controller.isPredictiveTextEnabled = true
        return controller
    }
}
