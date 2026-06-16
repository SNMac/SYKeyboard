//
//  SuggestionControllerTextReplacementTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/16/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("텍스트 대치 컨트롤러 검증")
struct SuggestionControllerTextReplacementTests {

    @Test("단축어는 현재 단어 전체와 일치할 때만 대치")
    func test단축어는_현재단어전체와일치할때만_대치() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        #expect(controller.attemptTextReplacement(baseText: "paid") == nil)

        let replacement = controller.attemptTextReplacement(baseText: "id")
        #expect(replacement?.deleteCount == 2)
        #expect(replacement?.insertText == "identifier")
    }

    @Test("대치 복구는 마지막 대치 결과만 복구")
    func test대치복구는_마지막대치결과만_복구() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier"),
                TextReplacementEntry(userInput: "addr", documentText: "Seoul")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(baseText: "id")
        _ = controller.attemptTextReplacement(baseText: "addr")

        let staleRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "identifier",
            selectedText: nil
        )
        #expect(staleRestore == nil)

        let latestRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "Seoul",
            selectedText: nil
        )
        #expect(latestRestore?.deleteCount == 5)
        #expect(latestRestore?.insertText == "addr")
    }

    @Test("복구 이력을 지우면 같은 문구 뒤 삭제도 단축어로 복구하지 않음")
    func test복구이력을지우면_같은문구뒤삭제도_단축어로복구하지않음() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(baseText: "id")
        controller.clearReplacementHistory()

        let restore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "identifier",
            selectedText: nil
        )
        #expect(restore == nil)
    }

    private func makeController(entries: [TextReplacementEntry]) -> SuggestionController {
        let provider = StubLexiconSuggestionProvider(entries: entries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { provider },
            makeTextCheckerEngine: { _ in StubPredictiveTextProvider() },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        return SuggestionController(language: "en-US", engineFactory: factory)
    }
}

private final class StubLexiconSuggestionProvider: LexiconSuggestionProviding {

    // MARK: - Properties

    let textReplacementEntries: [TextReplacementEntry]
    var hasLoadedLexicon: Bool { true }

    // MARK: - Initializer

    init(entries: [TextReplacementEntry]) {
        self.textReplacementEntries = entries
    }

    // MARK: - Internal Methods

    func suggestions(for baseText: String) -> [String] {
        let currentWord = baseText.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
        return textReplacementEntries
            .filter { $0.userInput.lowercased() == currentWord.lowercased() }
            .map(\.documentText)
    }

    func learn(word: String) {}
}

private final class StubPredictiveTextProvider: PredictiveTextProvider {
    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
}

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}
}
