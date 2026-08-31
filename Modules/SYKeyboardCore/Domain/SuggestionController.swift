//
//  SuggestionController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit
import OSLog

/// n-gram 예측 엔진에 필요한 기록/저장 기능 계약
protocol NGramPredictiveTextProviding: PredictiveTextProvider {
    /// 디스크 로딩이 완료되었을 때 호출할 콜백
    var onLoadCompleted: (() -> Void)? { get set }
    /// 현재 문장 버퍼의 단어 수
    var currentSentenceWordsCount: Int { get }

    /// 단어를 현재 문장 버퍼에 추가하고 n-gram을 기록합니다.
    func addWord(_ word: String)
    /// 문장 버퍼를 초기화하고 디스크에 저장합니다.
    func endSentence()
    /// 마지막으로 기록된 단어를 문장 버퍼에서 제거합니다.
    func removeLastWord()
    /// 문장 버퍼를 초기화합니다.
    func resetSentenceBuffer()
    /// n-gram 데이터를 디스크에 저장합니다.
    func saveToDisk()
}

extension NGramPredictiveTextEngine: NGramPredictiveTextProviding {}

/// `SuggestionController`가 사용하는 예측 엔진 생성 팩토리
struct SuggestionControllerEngineFactory {
    let makeLexiconEngine: () -> LexiconSuggestionProviding
    let makeTextCheckerEngine: (String) -> PredictiveTextProvider
    let makeNGramEngine: (String) -> NGramPredictiveTextProviding

    static let live = SuggestionControllerEngineFactory(
        makeLexiconEngine: { LexiconPredictiveTextEngine() },
        makeTextCheckerEngine: { TextCheckerPredictiveTextEngine(language: $0) },
        makeNGramEngine: { NGramPredictiveTextEngine(language: $0) }
    )
}

/// `SuggestionController`의 이벤트를 수신하는 델리게이트 프로토콜
protocol SuggestionControllerDelegate: AnyObject {
    /// 자동완성 후보가 업데이트되었을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - controller: 이벤트를 발생시킨 `SuggestionController`
    ///   - currentWord: 현재 입력 중인 단어 (없으면 nil)
    ///   - suggestions: 업데이트된 후보 단어 배열 (최대 2개, 텍스트 대치 우선)
    func suggestionController(_ controller: SuggestionController, didUpdateCurrentWord currentWord: String?, suggestions: [String])
}

/// 현재 SuggestionBar의 표시 모드
enum SuggestionMode {
    /// 입력 중: button1에 "현재단어", button2~3에 자동완성 후보
    case typing
    /// n-gram: button1~3에 다음 단어 예측
    case nGram
    /// 수식 결과: button1에 원문, button2에 원문+결과, button3에 결과 대치 후보
    case mathExpression
}

private enum MathSuggestionOrigin: Equatable {
    case unselected
    case selection(String)

    init(selectedText: String?) {
        if let selectedText, !selectedText.isEmpty {
            self = .selection(selectedText)
        } else {
            self = .unselected
        }
    }
}

/// 자동완성 후보 조회, 텍스트 대치, 대치 복구를 통합 관리하는 컨트롤러
///
/// `UILexicon`과 `UITextChecker`, n-gram 세 소스를 조합하여 후보를 생성하며,
/// 스페이스 입력 시 텍스트 대치, 삭제 시 대치 복구 기능을 제공합니다.
///
/// ## 활성화 제어
/// - `isPredictiveTextEnabled`: 사용자 설정. `false`이면 `textCheckerEngine`과 `nGramEngine`을 해제합니다.
/// - `isTextReplacementEnabled`: 사용자 설정. `false`이면 텍스트 대치 기능을 비활성화합니다.
/// - `isSuspended`: 텍스트 필드별 일시적 비활성화 (`autocorrectionType == .no` 등).
///   엔진을 해제하지 않고 조회·기록만 건너뜁니다.
///
/// `lexiconEngine`은 자동완성과 텍스트 대치 양쪽에서 사용되므로,
/// 둘 다 꺼졌을 때만 해제됩니다.
///
/// 모든 후보 조회는 `BaseKeyboardViewController`가 관리하는 `inputBuffer`를 기준으로
/// 수행되며, 현재 키보드 세션에서 직접 입력한 텍스트만 대상으로 합니다.
///
/// ## 동작 흐름
/// 1. **입력 중**: SuggestionBar에 `UILexicon` + `UITextChecker` 후보 표시
/// 2. **후보 탭**: 현재 단어를 선택한 후보로 교체 (텍스트 대치 후보는 대치 이력 기록)
/// 3. **스페이스**: `UILexicon`에 정확히 매칭되는 텍스트 대치 자동 수행, n-gram 기록
/// 4. **삭제**: 방금 대치된 단어를 원래 단축어로 복구
/// 5. **복구 후 스페이스**: 같은 단축어에 대해 재대치 방지
/// 6. **입력 없음 / 자동완성 후**: n-gram 기반 다음 단어 예측
final class SuggestionController: SuggestionService {

    // MARK: - Properties

    weak var delegate: SuggestionControllerDelegate?

    /// 엔진 재생성 시 사용할 언어 코드
    private var language: String
    /// 비동기 n-gram 로드 콜백을 식별하는 엔진 세대
    private var engineGeneration = 0
    /// 예측 엔진 생성 팩토리
    private let engineFactory: SuggestionControllerEngineFactory
    /// 성능 계측용 signposter
    private let signposter = OSSignposter(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "SuggestionController"
    )

    /// 자동완성 사용자 설정
    ///
    /// `false`로 설정하면 `textCheckerEngine`과 `nGramEngine`을 해제합니다.
    /// `true`로 복구해도 엔진은 즉시 생성하지 않고 준비 API에서 생성합니다.
    var isPredictiveTextEnabled: Bool = false {
        didSet {
            guard oldValue != isPredictiveTextEnabled else { return }
            if !isPredictiveTextEnabled {
                textCheckerEngines.removeAll()
                nGramEngines.removeAll()
                clearSuggestions()
            }
            releaseLexiconEngineIfUnused()
        }
    }

    /// 텍스트 대치 사용자 설정
    ///
    /// `false`로 설정하면 텍스트 대치 기능을 비활성화합니다.
    /// `lexiconEngine`은 자동완성에서도 사용되므로, 자동완성도 꺼져야 해제됩니다.
    var isTextReplacementEnabled: Bool = false {
        didSet {
            guard oldValue != isTextReplacementEnabled else { return }
            releaseLexiconEngineIfUnused()
        }
    }

    /// 수식 결과 후보 표시 사용자 설정
    var isShowMathResultsEnabled: Bool = true {
        didSet {
            guard oldValue != isShowMathResultsEnabled else { return }
            if !isShowMathResultsEnabled, currentMode == .mathExpression {
                clearSuggestions()
            }
        }
    }

    /// 텍스트 필드별 일시적 비활성화
    ///
    /// `autocorrectionType == .no`인 텍스트 필드 등에서 `true`로 설정합니다.
    /// 엔진을 해제하지 않고 조회·기록만 건너뜁니다.
    var isSuspended: Bool = false {
        didSet {
            if isSuspended { clearSuggestions() }
        }
    }

    /// 현재 표시 모드
    private(set) var currentMode: SuggestionMode = .nGram

    /// 자동완성 후보와 출처 정보를 함께 저장하는 모델
    fileprivate struct SuggestionItem {
        /// 후보 텍스트
        let text: String
        /// 후보의 출처
        let source: Source
        /// 후보 선택 시 삽입할 텍스트
        let insertText: String?
        /// 후보 선택 시 삭제할 텍스트 수
        let replacementDeleteCount: Int?

        init(
            text: String,
            source: Source,
            insertText: String? = nil,
            replacementDeleteCount: Int? = nil
        ) {
            self.text = text
            self.source = source
            self.insertText = insertText
            self.replacementDeleteCount = replacementDeleteCount
        }

        /// 후보 출처 구분
        enum Source {
            /// `UILexicon` 기반 (텍스트 대치)
            case lexicon
            /// `UITextChecker` 기반 (시스템 사전)
            case textChecker
            /// n-gram 기반 (다음 단어 예측)
            case nGram
            /// 수식 원문 확인 후보
            case mathExpressionOriginal
            /// 수식 결과 삽입 후보
            case mathExpressionInsertion
            /// 수식 전체 대치 후보
            case mathExpressionReplacement
        }
    }

    /// 현재 표시 중인 후보 배열 (출처 정보 포함)
    private var currentSuggestions: [SuggestionItem] = []

    /// `UILexicon` 기반 엔진 (연락처, 텍스트 대치 등)
    ///
    /// 자동완성과 텍스트 대치 양쪽에서 사용되므로, 둘 다 꺼졌을 때만 `nil`이 됩니다.
    private var lexiconEngine: LexiconSuggestionProviding?
    /// 언어별 `UITextChecker` 기반 엔진 캐시
    private var textCheckerEngines: [String: PredictiveTextProvider] = [:]
    /// 언어별 n-gram 엔진 캐시.
    ///
    /// 한영 통합 키보드는 한 세션에서 두 언어를 오가므로, 언어를 바꿀 때마다
    /// 엔진을 버리면 그때마다 디스크 로드를 다시 한다. 사용한 언어의 엔진만 들고 있는다
    private var nGramEngines: [String: NGramPredictiveTextProviding] = [:]

    /// `UITextChecker` 기반 엔진 (시스템 사전)
    ///
    /// `isPredictiveTextEnabled`가 `false`이면 `nil`이 됩니다.
    private var textCheckerEngine: PredictiveTextProvider? {
        get { textCheckerEngines[language] }
        set { textCheckerEngines[language] = newValue }
    }
    /// n-gram 기반 엔진 (다음 단어 예측)
    ///
    /// `isPredictiveTextEnabled`가 `false`이면 `nil`이 됩니다.
    private var nGramEngine: NGramPredictiveTextProviding? {
        get { nGramEngines[language] }
        set { nGramEngines[language] = newValue }
    }
    /// 마지막으로 자동완성 갱신을 요청한 텍스트
    private var lastSuggestionBaseText: String?
    /// 마지막으로 수식 탐지를 요청한 텍스트
    private var lastMathExpressionText: String?
    /// 마지막으로 자동완성 갱신을 요청한 selection origin
    private var lastSuggestionOrigin: MathSuggestionOrigin?
    /// 현재 표시 중인 수식 후보를 만든 계산 결과
    private var currentMathCompletion: MathExpressionCompletion?
    /// 현재 표시 중인 수식 후보를 만든 selection origin
    private var currentMathSuggestionOrigin: MathSuggestionOrigin?
    /// `requestSupplementaryLexicon()` 중복 요청 방지 플래그
    private var isLoadingLexicon = false

    /// 후보 최대 표시 개수
    private let maxSuggestions = 3
    /// 복구 가능한 텍스트 대치 이력 최대 개수
    private let maxReplacementHistoryCount = 20

    /// 텍스트 대치 이력을 저장하는 모델
    private struct ReplacementRecord: Equatable {
        /// 사용자가 입력한 단축어 (예: "ㅈㄱㅈ")
        let userInput: String
        /// 대치된 결과물 (예: "지금 가는 중!")
        let documentText: String
        /// 대치 결과 앞쪽의 제한된 문맥
        let contextBeforeDocumentText: String
    }
    /// 텍스트 대치 이력
    private var replacementHistory: [ReplacementRecord] = []
    /// 방금 복구된 단축어 (재대치 방지용)
    private var ignoredShortcut: String?

    // MARK: - Initializer

    /// 지정한 언어로 컨트롤러를 초기화합니다.
    ///
    /// 초기화 시점에는 엔진을 생성하지 않습니다.
    /// 설정값은 저장만 하고, 해당 엔진은 준비 API에서 생성합니다.
    ///
    /// - Parameter language: `UITextChecker`, NGram엔진에서 사용할 언어 코드 (기본값: "ko-KR")
    init(
        language: String = "ko-KR",
        engineFactory: SuggestionControllerEngineFactory = .live
    ) {
        self.language = language
        self.engineFactory = engineFactory
    }

    // MARK: - Lexicon Loading

    func updateLanguage(to language: String) {
        guard self.language != language else { return }

        // 전환 전 언어의 학습 결과는 즉시 보존하되, 엔진 자체는 캐시에 남겨
        // 같은 언어로 돌아왔을 때 디스크 로드를 반복하지 않는다
        nGramEngine?.saveToDisk()
        engineGeneration += 1
        self.language = language
        lastSuggestionBaseText = nil
        lastMathExpressionText = nil
        lastSuggestionOrigin = nil
        currentMathCompletion = nil
        currentMathSuggestionOrigin = nil
        clearSuggestions()
    }

    func preparePredictiveEnginesIfNeeded() {
        guard isPredictiveTextEnabled else { return }

        if textCheckerEngine == nil {
            let state = signposter.beginInterval("PrepareTextCheckerEngine")
            textCheckerEngine = engineFactory.makeTextCheckerEngine(language)
            signposter.endInterval("PrepareTextCheckerEngine", state)
        }

        if nGramEngine == nil {
            let state = signposter.beginInterval("PrepareNGramEngine")
            let generation = engineGeneration
            let engineLanguage = language
            let engine = engineFactory.makeNGramEngine(engineLanguage)
            // 이 콜백은 엔진이 이미 main으로 넘겨 호출하므로 동기로 갱신할 수도 있지만,
            // 그러면 엔진의 로딩 완료 클로저 안에서 후보 갱신이 엔진으로 재진입한다.
            // 한 프레임을 아끼는 대신 재진입 위험을 지는 거래라 비동기를 유지한다
            engine.onLoadCompleted = { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.engineGeneration == generation,
                          self.language == engineLanguage else { return }
                    self.performRefreshSuggestionsAfterNGramLoadIfNeeded()
                }
            }
            nGramEngine = engine
            signposter.endInterval("PrepareNGramEngine", state)
        }
    }

    /// 현재 언어가 아닌 예측 엔진 캐시를 해제합니다.
    ///
    /// 비활성 언어 엔진은 전환 시점에 이미 `saveToDisk()`로 저장했고
    /// 그 뒤로는 학습을 받지 않으므로, 저장 없이 버려도 유실되는 기록이 없습니다.
    func releaseInactiveLanguageEngines() {
        let activeLanguage = language
        nGramEngines = nGramEngines.filter { $0.key == activeLanguage }
        textCheckerEngines = textCheckerEngines.filter { $0.key == activeLanguage }
    }

    func prepareLexiconEngineIfNeeded() {
        guard isPredictiveTextEnabled || isTextReplacementEnabled else { return }
        guard lexiconEngine == nil else { return }

        let state = signposter.beginInterval("PrepareLexiconEngine")
        lexiconEngine = engineFactory.makeLexiconEngine()
        signposter.endInterval("PrepareLexiconEngine", state)
    }

    func loadLexicon(from inputViewController: UIInputViewController) {
        prepareLexiconEngineIfNeeded()
        guard lexiconEngine != nil else { return }
        guard !isLoadingLexicon else { return }
        guard lexiconEngine?.hasLoadedLexicon == false else { return }

        isLoadingLexicon = true
        Task { @MainActor [weak self, weak inputViewController] in
            guard let self else { return }
            guard let inputViewController else {
                self.isLoadingLexicon = false
                return
            }
            let state = self.signposter.beginInterval("RequestSupplementaryLexicon")
            defer {
                self.signposter.endInterval("RequestSupplementaryLexicon", state)
                self.isLoadingLexicon = false
            }
            let lexicon = await inputViewController.requestSupplementaryLexicon()
            (lexiconEngine as? LexiconLoadableSuggestionProviding)?.setLexicon(lexicon)
        }
    }

    // MARK: - Suggestion Methods

    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String
    ) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin(selectedText: selectedText)
        lastSuggestionBaseText = baseText
        lastMathExpressionText = mathExpressionText
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()
        performUpdateSuggestions(
            for: baseText,
            mathExpressionText: mathExpressionText,
            origin: origin
        )
    }

    func updateSuggestionsAfterNGramSelection(inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin.unselected
        lastSuggestionBaseText = inputBuffer
        lastMathExpressionText = inputBuffer
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()

        let nGramResults = nGramSuggestions(for: inputBuffer)

        if !nGramResults.isEmpty {
            currentMathCompletion = nil
            currentMathSuggestionOrigin = nil
            currentMode = .nGram
            currentSuggestions = nGramResults
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
        } else {
            performUpdateSuggestions(
                for: inputBuffer,
                mathExpressionText: inputBuffer,
                origin: origin
            )
        }
    }

    func clearSuggestions() {
        lastSuggestionBaseText = nil
        lastMathExpressionText = nil
        lastSuggestionOrigin = nil
        currentMathCompletion = nil
        currentMathSuggestionOrigin = nil
        currentSuggestions = []
        currentMode = .nGram
        delegate?.suggestionController(self, didUpdateCurrentWord: nil, suggestions: [])
    }

    func selectSuggestion(at index: Int, baseText: String) -> (deleteCount: Int, insertText: String)? {
        guard index >= 0, index < currentSuggestions.count else { return nil }

        if let last = baseText.last, last.isWhitespace { return nil }

        let item = currentSuggestions[index]
        let currentWord = extractLastWord(from: baseText)

        if item.source == .textChecker {
            textCheckerEngine?.learn(word: item.text)
        }

        if item.source == .lexicon {
            appendReplacementRecord(
                userInput: currentWord,
                documentText: item.text,
                baseText: baseText,
                currentWord: currentWord
            )
        }

        return (deleteCount: currentWord.count, insertText: item.text)
    }

    func nGramSuggestionText(at index: Int) -> String? {
        guard index >= 0, index < currentSuggestions.count,
              currentSuggestions[index].source == .nGram else { return nil }
        return currentSuggestions[index].text
    }

    func mathResultAction(
        at index: Int,
        selectedText: String?
    ) -> MathResultSuggestionAction? {
        guard currentMode == .mathExpression,
              index >= 0,
              index < currentSuggestions.count else { return nil }

        guard let currentMathCompletion,
              let currentMathSuggestionOrigin else { return nil }

        let selectedPrefix: String?
        switch currentMathSuggestionOrigin {
        case .unselected:
            guard selectedText?.isEmpty != false else { return nil }
            selectedPrefix = nil
        case .selection(let originalSelection):
            guard selectedText == originalSelection,
                  originalSelection == lastSuggestionBaseText,
                  originalSelection.hasSuffix(currentMathCompletion.expressionText) else {
                return nil
            }
            selectedPrefix = String(
                originalSelection.dropLast(currentMathCompletion.expressionText.count)
            )
        }

        let item = currentSuggestions[index]

        switch item.source {
        case .mathExpressionOriginal:
            return .confirmOriginal
        case .mathExpressionInsertion:
            guard let insertText = item.insertText else { return nil }
            if let selectedPrefix {
                return .replaceSelection(selectedPrefix + item.text)
            }
            return .insertResult(insertText)
        case .mathExpressionReplacement:
            guard let insertText = item.insertText,
                  let deleteCount = item.replacementDeleteCount else { return nil }
            if let selectedPrefix {
                return .replaceSelection(selectedPrefix + insertText)
            }
            return .replaceExpression(
                deleteCount: deleteCount,
                insertText: insertText
            )
        default:
            return nil
        }
    }

    func textReplacementPreviewSuggestionIndex(baseText: String) -> Int? {
        guard currentMode == .typing,
              let match = textReplacementMatch(baseText: baseText) else { return nil }

        if let ignored = ignoredShortcut, ignored == match.entry.userInput {
            return nil
        }

        guard let suggestionIndex = currentSuggestions.firstIndex(where: {
            $0.source == .lexicon && $0.text == match.entry.documentText
        }) else { return nil }

        return suggestionIndex + 1
    }

    // MARK: - Learning

    func learnWord(_ word: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        preparePredictiveEnginesIfNeeded()
        textCheckerEngine?.learn(word: word)
    }

    // MARK: - N-Gram Recording

    func recordWord(_ word: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        preparePredictiveEnginesIfNeeded()
        nGramEngine?.addWord(word)
    }

    func endSentence(inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        preparePredictiveEnginesIfNeeded()
        recordUncommittedWords(from: inputBuffer)
        nGramEngine?.endSentence()
    }

    func saveNGramData() {
        nGramEngine?.saveToDisk()
    }

    func recordUncommittedWords(from inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        preparePredictiveEnginesIfNeeded()
        guard let nGramEngine else { return }

        let words = inputBuffer
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        guard !words.isEmpty else { return }

        let committedCount = nGramEngine.currentSentenceWordsCount
        let uncommitted = Array(words.dropFirst(committedCount))

        for word in uncommitted {
            nGramEngine.addWord(word)
        }
    }

    func removeLastRecordedWord() {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        nGramEngine?.removeLastWord()
    }

    func resetSentenceBuffer() {
        nGramEngine?.resetSentenceBuffer()
    }

    // MARK: - Text Replacement Methods

    func attemptTextReplacement(baseText: String) -> (deleteCount: Int, insertText: String)? {
        return attemptTextReplacement(baseText: baseText, documentContextBeforeInput: nil)
    }

    func attemptTextReplacement(
        baseText: String,
        documentContextBeforeInput: String?
    ) -> (deleteCount: Int, insertText: String)? {
        guard let match = textReplacementMatch(baseText: baseText) else { return nil }

        if let ignored = ignoredShortcut, ignored == match.entry.userInput {
            ignoredShortcut = nil
            return nil
        }

        appendReplacementRecord(
            userInput: match.entry.userInput,
            documentText: match.entry.documentText,
            baseText: documentContextBeforeInput ?? baseText,
            currentWord: match.currentWord
        )

        return (deleteCount: match.entry.userInput.count, insertText: match.entry.documentText)
    }

    func attemptRestoreReplacement(
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> (deleteCount: Int, insertText: String)? {
        guard isTextReplacementEnabled,
              !replacementHistory.isEmpty else { return nil }

        for (index, record) in replacementHistory.enumerated().reversed() {
            guard let deleteCount = textReplacementRestoreDeleteCount(
                for: record,
                inputBuffer: inputBuffer,
                documentContextBeforeInput: documentContextBeforeInput,
                selectedText: selectedText
            ) else { continue }

            replacementHistory.remove(at: index)
            ignoredShortcut = record.userInput

            return (
                deleteCount: deleteCount,
                insertText: record.userInput
            )
        }

        return nil
    }

    // MARK: - State Management

    func clearIgnoredShortcut() {
        ignoredShortcut = nil
    }

    func clearReplacementHistory() {
        replacementHistory = []
    }
}

// MARK: - Private Methods

private extension SuggestionController {

    func textReplacementMatch(
        baseText: String
    ) -> (entry: TextReplacementEntry, currentWord: String)? {
        guard isTextReplacementEnabled,
              !baseText.isEmpty,
              let lexiconEngine,
              lexiconEngine.hasLoadedLexicon else { return nil }

        let currentWord = extractLastWord(from: baseText)
        guard !currentWord.isEmpty else { return nil }

        let matchState = signposter.beginInterval("TextReplacementMatch")
        defer { signposter.endInterval("TextReplacementMatch", matchState) }

        let matchingEntries = lexiconEngine.textReplacementEntries.filter { entry in
            let isMatch = currentWord.lowercased() == entry.userInput.lowercased()

            if entry.userInput.lowercased() == "m" && entry.documentText == "M" {
                return false
            }

            return isMatch
        }

        guard let entry = matchingEntries.max(by: {
            $0.userInput.count < $1.userInput.count
        }) else { return nil }

        return (entry: entry, currentWord: currentWord)
    }

    func appendReplacementRecord(
        userInput: String,
        documentText: String,
        baseText: String,
        currentWord: String
    ) {
        let contextBeforeDocumentText: String
        if baseText.hasSuffix(currentWord) {
            contextBeforeDocumentText = String(
                baseText
                    .dropLast(currentWord.count)
                    .suffix(KeyboardTextContextNavigator.maximumCursorRestoreDistance)
            )
        } else {
            contextBeforeDocumentText = String(
                baseText
                    .suffix(KeyboardTextContextNavigator.maximumCursorRestoreDistance)
            )
        }

        replacementHistory.append(
            ReplacementRecord(
                userInput: userInput,
                documentText: documentText,
                contextBeforeDocumentText: contextBeforeDocumentText
            )
        )

        if replacementHistory.count > maxReplacementHistoryCount {
            replacementHistory.removeFirst(replacementHistory.count - maxReplacementHistoryCount)
        }
    }

    private func textReplacementRestoreDeleteCount(
        for record: ReplacementRecord,
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> Int? {
        guard selectedText?.isEmpty != false else { return nil }

        if replacementRecord(record, matches: inputBuffer) {
            return record.documentText.count
        }

        guard inputBuffer.isEmpty,
              let documentContextBeforeInput else { return nil }

        return replacementRecord(record, matches: documentContextBeforeInput)
            ? record.documentText.count
            : nil
    }

    private func replacementRecord(
        _ record: ReplacementRecord,
        matches text: String
    ) -> Bool {
        guard !record.documentText.isEmpty else { return false }

        let expectedSuffix = record.contextBeforeDocumentText + record.documentText
        guard text.count >= expectedSuffix.count else { return false }
        return text.hasSuffix(expectedSuffix)
    }

    /// `isPredictiveTextEnabled` 또는 `isTextReplacementEnabled` 변경 시
    /// 더 이상 필요 없는 `lexiconEngine`을 해제합니다.
    ///
    /// 생성은 첫 표시 이후 또는 첫 후보 요청 시점의 준비 API에서 수행합니다.
    func releaseLexiconEngineIfUnused() {
        if !isPredictiveTextEnabled && !isTextReplacementEnabled {
            lexiconEngine = nil
        }
    }

    /// 실제 후보 갱신 로직
    ///
    /// 입력 버퍼에 따라 두 가지 모드로 분기합니다:
    /// - 버퍼 비어있음 또는 마지막 문자가 공백 → n-gram 모드
    /// - 단어 타이핑 중 → 입력 중 모드 (lexicon + textChecker)
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트
    func performUpdateSuggestions(
        for baseText: String,
        mathExpressionText: String,
        origin: MathSuggestionOrigin
    ) {
        if isShowMathResultsEnabled,
           let completion = MathExpressionCompletionEvaluator.completion(
               for: mathExpressionText
           ) {
            currentMathCompletion = completion
            currentMathSuggestionOrigin = origin
            currentMode = .mathExpression
            currentSuggestions = [
                SuggestionItem(
                    text: "\"\(completion.expressionText)\"",
                    source: .mathExpressionOriginal
                ),
                SuggestionItem(
                    text: completion.displayText,
                    source: .mathExpressionInsertion,
                    insertText: completion.insertText
                ),
                SuggestionItem(
                    text: completion.insertText,
                    source: .mathExpressionReplacement,
                    insertText: completion.insertText,
                    replacementDeleteCount: completion.expressionText.count
                )
            ]
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
            return
        }

        currentMathCompletion = nil
        currentMathSuggestionOrigin = nil
        if baseText.isEmpty || baseText.last?.isWhitespace == true {
            currentMode = .nGram
            currentSuggestions = nGramSuggestions(for: baseText)
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
            return
        }

        currentMode = .typing
        let currentWord = extractLastWord(from: baseText)
        currentSuggestions = mergeSuggestions(for: baseText, currentWord: currentWord)
        delegate?.suggestionController(
            self,
            didUpdateCurrentWord: currentWord.isEmpty ? nil : currentWord,
            suggestions: currentSuggestions.map { $0.text }
        )
    }

    func performRefreshSuggestionsAfterNGramLoadIfNeeded() {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        guard let lastSuggestionBaseText,
              let lastMathExpressionText,
              let lastSuggestionOrigin else { return }
        performUpdateSuggestions(
            for: lastSuggestionBaseText,
            mathExpressionText: lastMathExpressionText,
            origin: lastSuggestionOrigin
        )
    }

    /// n-gram 기반 다음 단어 예측 후보를 생성합니다.
    ///
    /// 입력 버퍼가 비어있으면 unigram(자주 사용한 단어)을,
    /// 공백으로 끝나면 trigram → bigram → unigram 순으로 조회합니다.
    ///
    /// - Parameter inputBuffer: 현재 키보드 세션에서 직접 입력한 텍스트 버퍼
    /// - Returns: n-gram 예측 후보 배열 (최대 3개)
    func nGramSuggestions(for inputBuffer: String) -> [SuggestionItem] {
        guard let nGramEngine else { return [] }
        let results = nGramEngine.suggestions(for: inputBuffer)
        return results.prefix(maxSuggestions).map {
            SuggestionItem(text: $0, source: .nGram)
        }
    }

    /// `UILexicon`과 `UITextChecker`의 결과를 병합합니다.
    ///
    /// 현재 입력 중인 단어와 동일한 후보는 제외하고,
    /// `UILexicon` 결과를 먼저 배치하여 사용자 개인화 데이터를 우선시합니다.
    ///
    /// - Parameters:
    ///   - text: 자동완성을 제공할 텍스트
    ///   - currentWord: 현재 입력 중인 단어
    /// - Returns: 중복 제거된 후보 배열 (최대 2개)
    func mergeSuggestions(for text: String, currentWord: String) -> [SuggestionItem] {
        let lexiconState = signposter.beginInterval("LexiconSuggestions")
        let lexiconResults = lexiconEngine?.suggestions(for: text) ?? []
        signposter.endInterval("LexiconSuggestions", lexiconState)

        let checkerState = signposter.beginInterval("TextCheckerSuggestions")
        let checkerResults = textCheckerEngine?.suggestions(for: text) ?? []
        signposter.endInterval("TextCheckerSuggestions", checkerState)

        var seen = Set<String>()
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []

        let maxSuggestionSlots = maxSuggestions - 1

        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        for suggestion in checkerResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .textChecker))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        return merged
    }

    /// 텍스트에서 마지막 단어를 추출합니다.
    ///
    /// - Parameter text: 원본 텍스트
    /// - Returns: 마지막 단어, 없으면 빈 문자열
    func extractLastWord(from text: String) -> String {
        guard let last = text.split(whereSeparator: { $0.isWhitespace }).last else {
            return ""
        }
        return String(last)
    }
}
