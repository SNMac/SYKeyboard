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
/// `isEnabled`를 통해 연산 자체를 비활성화할 수 있습니다.
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
    
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled { clearSuggestions() }
        }
    }
    
    /// 현재 표시 모드
    private(set) var currentMode: SuggestionMode = .nGram
    
    /// 자동완성 후보와 출처 정보를 함께 저장하는 모델
    struct SuggestionItem {
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
    private let lexiconEngine = LexiconPredictiveTextEngine()
    /// `UITextChecker` 기반 엔진 (시스템 사전)
    private let textCheckerEngine: TextCheckerPredictiveTextEngine
    /// n-gram 기반 엔진 (다음 단어 예측)
    private let nGramEngine = NGramPredictiveTextEngine()
    
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
    
    /// 지정한 엔진들로 컨트롤러를 초기화합니다.
    ///
    /// - Parameters:
    ///   - textCheckerLanguages: `UITextChecker`에서 사용할 언어 코드 배열 (기본값: 한국어+영어)
    init(textCheckerLanguages: [String] = ["ko_KR", "en-US"]) {
        self.textCheckerEngine = TextCheckerPredictiveTextEngine(languages: textCheckerLanguages)
    }
    
    // MARK: - Lexicon Loading
    
    func loadLexicon(from inputViewController: UIInputViewController) {
        Task { @MainActor in
            let lexicon = await inputViewController.requestSupplementaryLexicon()
            lexiconEngine.setLexicon(lexicon)
        }
    }
    
    // MARK: - Suggestion Methods
    
    func updateSuggestions(contextBeforeInput: String?) {
        guard isEnabled else { return }
        performUpdateSuggestions(contextBeforeInput: contextBeforeInput)
    }
    
    /// n-gram 추천 탭 후 강제로 n-gram 갱신을 시도하고,
    /// 결과가 없으면 입력 중 모드로 폴백합니다.
    ///
    /// 뒤 공백 없이 단어를 삽입한 후 호출되므로,
    /// context가 글자로 끝나는 상태에서 n-gram 모드를 시도합니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    func updateSuggestionsAfterNGramSelection(contextBeforeInput: String?) {
        guard isEnabled else { return }
        
        let context = contextBeforeInput ?? ""
        
        let nGramResults = nGramSuggestions(for: context)
        
        if !nGramResults.isEmpty {
            currentMode = .nGram
            currentSuggestions = nGramResults
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
        } else {
            // 폴백 시 performUpdateSuggestions가 currentMode = .typing으로 설정
            performUpdateSuggestions(contextBeforeInput: contextBeforeInput)
        }
    }
    
    func clearSuggestions() {
        currentSuggestions = []
        currentMode = .nGram
        delegate?.suggestionController(self, didUpdateCurrentWord: nil, suggestions: [])
    }
    
    func selectSuggestion(at index: Int, contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)? {
        guard index >= 0, index < currentSuggestions.count else { return nil }
        
        let context = contextBeforeInput ?? ""
        if let last = context.last, last.isWhitespace { return nil }
        
        let item = currentSuggestions[index]
        let currentWord = extractLastWord(from: context)
        
        // textChecker 후보만 학습, 텍스트 대치(lexicon)와 nGram은 제외
        if item.source == .textChecker {
            textCheckerEngine.learn(word: item.text)
        }
        
        // 텍스트 대치일 때만 대치 이력 기록
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
        textCheckerEngine.learn(word: word)
    }
    
    // MARK: - N-Gram Recording
    
    func recordWord(_ word: String) {
        nGramEngine.addWord(word)
    }
    
    func endSentence() {
        nGramEngine.endSentence()
    }
    
    func saveNGramData() {
        nGramEngine.saveToDisk()
    }
    
    // MARK: - Text Replacement Methods
    
    func attemptTextReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)? {
        guard let context = contextBeforeInput,
              let lexicon = lexiconEngine.lexicon else { return nil }
        
        // 가장 긴 매칭을 우선 적용
        let matchingEntries = lexicon.entries.filter { entry in
            let isMatch = context.lowercased().hasSuffix(entry.userInput.lowercased())
            
            // iOS 버그 대응: 'm' → 'M' 매핑 제외
            if entry.userInput.lowercased() == "m" && entry.documentText == "M" {
                return false
            }
            
            return isMatch
        }
        
        guard let match = matchingEntries.max(by: {
            $0.userInput.count < $1.userInput.count
        }) else { return nil }
        
        // 방금 복구된 단축어와 동일하면 대치 건너뛰기
        if let ignored = ignoredShortcut, ignored == match.userInput {
            ignoredShortcut = nil
            return nil
        }
        
        // 대치 이력 기록
        let record = ReplacementRecord(
            userInput: match.userInput,
            documentText: match.documentText
        )
        replacementHistory.append(record)
        
        return (deleteCount: match.userInput.count, insertText: match.documentText)
    }
    
    func attemptRestoreReplacement(contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)? {
        guard let context = contextBeforeInput,
              !replacementHistory.isEmpty else { return nil }
        
        for (index, record) in replacementHistory.enumerated().reversed() {
            if context.hasSuffix(record.documentText) {
                replacementHistory.remove(at: index)
                
                // 복구된 단축어를 기록하여 재대치 방지
                ignoredShortcut = record.userInput
                
                return (
                    deleteCount: record.documentText.count,
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
    /// 실제 후보 갱신 로직
    ///
    /// 문맥에 따라 두 가지 모드로 분기합니다:
    /// - 입력 없음(`nil`/빈 문자열) 또는 마지막 문자가 공백 → n-gram 모드
    /// - 단어 타이핑 중 → 입력 중 모드 (lexicon + textChecker)
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트 (`nil` 가능)
    func performUpdateSuggestions(contextBeforeInput: String?) {
        guard isEnabled else { return }
        
        let context = contextBeforeInput ?? ""
        
        if context.isEmpty || context.last?.isWhitespace == true {
            currentMode = .nGram
            currentSuggestions = nGramSuggestions(for: context)
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
            return
        }
        
        currentMode = .typing
        let currentWord = extractLastWord(from: context)
        currentSuggestions = mergeSuggestions(for: context, currentWord: currentWord)
        delegate?.suggestionController(
            self,
            didUpdateCurrentWord: currentWord.isEmpty ? nil : currentWord,
            suggestions: currentSuggestions.map { $0.text }
        )
    }
    
    /// n-gram 기반 다음 단어 예측 후보를 생성합니다.
    ///
    /// 입력이 없거나 마지막 문자가 공백일 때 사용됩니다.
    /// context가 비어있으면 unigram(자주 사용한 단어)을,
    /// 공백으로 끝나면 trigram → bigram → unigram 순으로 조회합니다.
    ///
    /// - Parameter context: 커서 앞의 텍스트 (빈 문자열 가능)
    /// - Returns: n-gram 예측 후보 배열 (최대 3개)
    func nGramSuggestions(for context: String) -> [SuggestionItem] {
        let results = nGramEngine.suggestions(for: context)
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
    ///   - context: 커서 앞의 텍스트
    ///   - currentWord: 현재 입력 중인 단어
    /// - Returns: 중복 제거된 후보 배열 (최대 2개)
    func mergeSuggestions(for context: String, currentWord: String) -> [SuggestionItem] {
        let lexiconResults = lexiconEngine.suggestions(for: context)
        let checkerResults = textCheckerEngine.suggestions(for: context)
        
        var seen = Set<String>()
        // 현재 입력 단어는 button1에 표시되므로 후보에서 제외
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []
        
        let maxSuggestionSlots = maxSuggestions - 1  // button1은 현재 입력용
        
        // 1순위: UILexicon (텍스트 대치)
        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestionSlots { return merged }
        }
        
        // 2순위: UITextChecker (시스템 사전)
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
