//
//  SuggestionController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

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
    private let language: String
    
    /// 자동완성 사용자 설정
    ///
    /// `false`로 설정하면 `textCheckerEngine`과 `nGramEngine`을 해제합니다.
    /// `true`로 복구하면 엔진을 재생성합니다.
    var isPredictiveTextEnabled: Bool = false {
        didSet {
            guard oldValue != isPredictiveTextEnabled else { return }
            if isPredictiveTextEnabled {
                if textCheckerEngine == nil {
                    textCheckerEngine = TextCheckerPredictiveTextEngine(language: language)
                }
                if nGramEngine == nil {
                    nGramEngine = NGramPredictiveTextEngine(language: language)
                }
            } else {
                textCheckerEngine = nil
                nGramEngine = nil
                clearSuggestions()
            }
            updateLexiconEngine()
        }
    }
    
    /// 텍스트 대치 사용자 설정
    ///
    /// `false`로 설정하면 텍스트 대치 기능을 비활성화합니다.
    /// `lexiconEngine`은 자동완성에서도 사용되므로, 자동완성도 꺼져야 해제됩니다.
    var isTextReplacementEnabled: Bool = false {
        didSet {
            guard oldValue != isTextReplacementEnabled else { return }
            updateLexiconEngine()
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
        
        /// 후보 출처 구분
        enum Source {
            /// `UILexicon` 기반 (텍스트 대치)
            case lexicon
            /// `UITextChecker` 기반 (시스템 사전)
            case textChecker
            /// n-gram 기반 (다음 단어 예측)
            case nGram
        }
    }
    
    /// 현재 표시 중인 후보 배열 (출처 정보 포함)
    private var currentSuggestions: [SuggestionItem] = []
    
    /// `UILexicon` 기반 엔진 (연락처, 텍스트 대치 등)
    ///
    /// 자동완성과 텍스트 대치 양쪽에서 사용되므로, 둘 다 꺼졌을 때만 `nil`이 됩니다.
    private var lexiconEngine: LexiconPredictiveTextEngine?
    /// `UITextChecker` 기반 엔진 (시스템 사전)
    ///
    /// `isPredictiveTextEnabled`가 `false`이면 `nil`이 됩니다.
    private var textCheckerEngine: TextCheckerPredictiveTextEngine?
    /// n-gram 기반 엔진 (다음 단어 예측)
    ///
    /// `isPredictiveTextEnabled`가 `false`이면 `nil`이 됩니다.
    private var nGramEngine: NGramPredictiveTextEngine?
    
    /// 후보 최대 표시 개수
    private let maxSuggestions = 3
    
    /// 텍스트 대치 이력을 저장하는 모델
    private struct ReplacementRecord: Equatable {
        /// 사용자가 입력한 단축어 (예: "ㅈㄱㅈ")
        let userInput: String
        /// 대치된 결과물 (예: "지금 가는 중!")
        let documentText: String
    }
    /// 텍스트 대치 이력
    private var replacementHistory: [ReplacementRecord] = []
    /// 방금 복구된 단축어 (재대치 방지용)
    private var ignoredShortcut: String?
    
    // MARK: - Initializer
    
    /// 지정한 언어로 컨트롤러를 초기화합니다.
    ///
    /// 초기화 시점에는 엔진을 생성하지 않습니다.
    /// `isPredictiveTextEnabled`와 `isTextReplacementEnabled`를 설정하면
    /// 해당 엔진이 자동으로 생성됩니다.
    ///
    /// - Parameter language: `UITextChecker`, NGram엔진에서 사용할 언어 코드 (기본값: "ko-KR")
    init(language: String = "ko-KR") {
        self.language = language
    }
    
    // MARK: - Lexicon Loading
    
    func loadLexicon(from inputViewController: UIInputViewController) {
        guard lexiconEngine != nil else { return }
        Task { @MainActor in
            let lexicon = await inputViewController.requestSupplementaryLexicon()
            lexiconEngine?.setLexicon(lexicon)
        }
    }
    
    // MARK: - Suggestion Methods
    
    func updateSuggestions(for baseText: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        performUpdateSuggestions(for: baseText)
    }
    
    func updateSuggestionsAfterNGramSelection(inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        
        let nGramResults = nGramSuggestions(for: inputBuffer)
        
        if !nGramResults.isEmpty {
            currentMode = .nGram
            currentSuggestions = nGramResults
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
        } else {
            performUpdateSuggestions(for: inputBuffer)
        }
    }
    
    func clearSuggestions() {
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
            let record = ReplacementRecord(
                userInput: currentWord,
                documentText: item.text
            )
            replacementHistory.append(record)
        }
        
        return (deleteCount: currentWord.count, insertText: item.text)
    }
    
    func nGramSuggestionText(at index: Int) -> String? {
        guard index >= 0, index < currentSuggestions.count,
              currentSuggestions[index].source == .nGram else { return nil }
        return currentSuggestions[index].text
    }
    
    // MARK: - Learning
    
    func learnWord(_ word: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        textCheckerEngine?.learn(word: word)
    }
    
    // MARK: - N-Gram Recording
    
    func recordWord(_ word: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        nGramEngine?.addWord(word)
    }
    
    func endSentence(inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        recordUncommittedWords(from: inputBuffer)
        nGramEngine?.endSentence()
    }
    
    func saveNGramData() {
        nGramEngine?.saveToDisk()
    }
    
    func recordUncommittedWords(from inputBuffer: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
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
        guard isTextReplacementEnabled,
              !baseText.isEmpty,
              let lexicon = lexiconEngine?.lexicon else { return nil }
        
        let matchingEntries = lexicon.entries.filter { entry in
            let isMatch = baseText.lowercased().hasSuffix(entry.userInput.lowercased())
            
            if entry.userInput.lowercased() == "m" && entry.documentText == "M" {
                return false
            }
            
            return isMatch
        }
        
        guard let match = matchingEntries.max(by: {
            $0.userInput.count < $1.userInput.count
        }) else { return nil }
        
        if let ignored = ignoredShortcut, ignored == match.userInput {
            ignoredShortcut = nil
            return nil
        }
        
        let record = ReplacementRecord(
            userInput: match.userInput,
            documentText: match.documentText
        )
        replacementHistory.append(record)
        
        return (deleteCount: match.userInput.count, insertText: match.documentText)
    }
    
    func attemptRestoreReplacement(
        inputBuffer: String,
        documentContextBeforeInput: String?,
        selectedText: String?
    ) -> (deleteCount: Int, insertText: String)? {
        guard isTextReplacementEnabled,
              !replacementHistory.isEmpty else { return nil }
        
        for (index, record) in replacementHistory.enumerated().reversed() {
            if let deleteCount = KeyboardSuggestionSelectionPolicy.textReplacementRestoreDeleteCount(
                documentText: record.documentText,
                inputBuffer: inputBuffer,
                documentContextBeforeInput: documentContextBeforeInput,
                selectedText: selectedText
            ) {
                replacementHistory.remove(at: index)
                
                ignoredShortcut = record.userInput
                
                return (
                    deleteCount: deleteCount,
                    insertText: record.userInput
                )
            }
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
    /// `isPredictiveTextEnabled` 또는 `isTextReplacementEnabled` 변경 시
    /// `lexiconEngine`의 생성/해제를 결정합니다.
    ///
    /// 둘 중 하나라도 켜져 있으면 유지, 둘 다 꺼지면 해제합니다.
    func updateLexiconEngine() {
        if isPredictiveTextEnabled || isTextReplacementEnabled {
            if lexiconEngine == nil {
                lexiconEngine = LexiconPredictiveTextEngine()
            }
        } else {
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
    func performUpdateSuggestions(for baseText: String) {
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
        let lexiconResults = lexiconEngine?.suggestions(for: text) ?? []
        let checkerResults = textCheckerEngine?.suggestions(for: text) ?? []
        
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
