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

    @Test("대치 복구는 여러 이력 중 커서 앞 문맥과 맞는 대치 결과를 복구")
    func test대치복구는_문맥과맞는대치결과를복구() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier"),
                TextReplacementEntry(userInput: "addr", documentText: "Seoul")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(baseText: "hello id")
        _ = controller.attemptTextReplacement(baseText: "home addr")

        let earlierRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "hello identifier",
            selectedText: nil
        )
        #expect(earlierRestore?.deleteCount == 10)
        #expect(earlierRestore?.insertText == "id")

        let latestRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "home Seoul",
            selectedText: nil
        )
        #expect(latestRestore?.deleteCount == 5)
        #expect(latestRestore?.insertText == "addr")
    }

    @Test("대치 복구는 문서 컨텍스트가 입력 단어로 끝나지 않아도 문맥을 보존")
    func test대치복구는_문서컨텍스트가_입력단어로끝나지않아도_문맥을보존() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(
            baseText: "id",
            documentContextBeforeInput: "hello"
        )

        let restore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "helloidentifier",
            selectedText: nil
        )
        #expect(restore?.deleteCount == 10)
        #expect(restore?.insertText == "id")
    }

    @Test("대치 복구는 다른 위치의 같은 확장 문구를 단축어로 되돌리지 않음")
    func test대치복구는_다른위치의같은확장문구를복구하지않음() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(baseText: "source id")

        let restore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "other identifier",
            selectedText: nil
        )
        #expect(restore == nil)
    }

    @Test("대치 복구 이력은 최근 20개만 보관")
    func test대치복구이력은_최근20개만보관() {
        let entries = (0...20).map {
            TextReplacementEntry(userInput: "id\($0)", documentText: "identifier\($0)")
        }
        let controller = makeController(entries: entries)
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        for index in 0...20 {
            _ = controller.attemptTextReplacement(baseText: "word\(index) id\(index)")
        }

        let prunedRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "word0 identifier0",
            selectedText: nil
        )
        #expect(prunedRestore == nil)

        let retainedRestore = controller.attemptRestoreReplacement(
            inputBuffer: "",
            documentContextBeforeInput: "word1 identifier1",
            selectedText: nil
        )
        #expect(retainedRestore?.insertText == "id1")
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

    @Test("대치 복구 직후 같은 단축어는 한 번만 재대치를 건너뜀")
    func test대치복구직후_같은단축어_재대치한번건너뜀() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        _ = controller.attemptTextReplacement(baseText: "id")
        let restore = controller.attemptRestoreReplacement(
            inputBuffer: "identifier",
            documentContextBeforeInput: "identifier",
            selectedText: nil
        )

        #expect(restore?.insertText == "id")
        #expect(controller.attemptTextReplacement(baseText: "id") == nil)

        let replacement = controller.attemptTextReplacement(baseText: "id")
        #expect(replacement?.deleteCount == 2)
        #expect(replacement?.insertText == "identifier")
    }

    @Test("텍스트 대치 preview 인덱스는 SuggestionBar 후보 위치를 반환")
    func test텍스트대치Preview인덱스는_SuggestionBar후보위치를반환() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        controller.updateSuggestions(for: "id")

        #expect(controller.textReplacementPreviewSuggestionIndex(baseText: "id") == 1)
    }

    @Test("입력 버퍼가 비어 있으면 커서 앞 문맥의 단축어를 preview하거나 대치하지 않음")
    func test입력버퍼가비어있으면_커서앞문맥의단축어를Preview하거나대치하지않음() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        let baseText = ""
        controller.updateSuggestions(for: baseText)

        #expect(controller.textReplacementPreviewSuggestionIndex(baseText: baseText) == nil)

        let replacement = controller.attemptTextReplacement(
            baseText: baseText,
            documentContextBeforeInput: "hello id"
        )
        #expect(replacement == nil)
    }

    @Test("분리된 커서 문맥은 일반 추천과 텍스트 대치 입력으로 전달하지 않음")
    func test분리된커서문맥은_일반추천과텍스트대치입력으로전달하지않음() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "id", documentText: "identifier")
            ]
        )
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        controller.updateSuggestions(
            for: "",
            selectedText: nil,
            mathExpressionText: "hello id"
        )

        #expect(controller.currentMode == .nGram)
        #expect(controller.textReplacementPreviewSuggestionIndex(baseText: "") == nil)
        #expect(
            controller.attemptTextReplacement(
                baseText: "",
                documentContextBeforeInput: "hello id"
            ) == nil
        )
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
