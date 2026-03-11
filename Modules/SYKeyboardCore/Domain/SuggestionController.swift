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
    ///   - suggestions: 업데이트된 후보 단어 배열 (최대 3개)
    func suggestionController(_ controller: SuggestionController, didUpdateSuggestions suggestions: [String])
}

/// 자동완성 후보 조회, 텍스트 대치, 대치 복구를 통합 관리하는 컨트롤러
///
/// `UILexicon`과 `UITextChecker` 두 소스를 조합하여 후보를 생성하며,
/// 스페이스 입력 시 텍스트 대치, 삭제 시 대치 복구 기능을 제공합니다.
/// `isEnabled`를 통해 연산 자체를 비활성화할 수 있습니다.
///
/// ## 동작 흐름
/// 1. **입력 중**: SuggestionBar에 `UILexicon` + `UITextChecker` 후보 표시
/// 2. **후보 탭**: 현재 단어를 선택한 후보로 교체 (텍스트 대치 후보는 대치 이력 기록)
/// 3. **스페이스**: `UILexicon`에 정확히 매칭되는 텍스트 대치 자동 수행
/// 4. **삭제**: 방금 대치된 단어를 원래 단축어로 복구
/// 5. **복구 후 스페이스**: 같은 단축어에 대해 재대치 방지
final class SuggestionController {
    
    // MARK: - Properties
    
    weak var delegate: SuggestionControllerDelegate?
    
    /// 자동완성 활성화 여부 (false면 엔진 연산 자체를 건너뜀)
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled { clearSuggestions() }
        }
    }
    
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
        }
    }
    
    /// 현재 표시 중인 후보 배열 (출처 정보 포함)
    private var currentSuggestions: [SuggestionItem] = []
    
    /// `UILexicon` 기반 엔진 (연락처, 텍스트 대치 등)
    private let lexiconEngine: LexiconPredictiveTextEngine
    /// `UITextChecker` 기반 엔진 (시스템 사전)
    private let textCheckerEngine: TextCheckerPredictiveTextEngine
    
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
    ///   - lexiconEngine: `UILexicon` 기반 엔진 (기본값: 새 인스턴스)
    ///   - textCheckerEngine: `UITextChecker` 기반 엔진 (기본값: 한국어+영어)
    init(
        lexiconEngine: LexiconPredictiveTextEngine = LexiconPredictiveTextEngine(),
        textCheckerEngine: TextCheckerPredictiveTextEngine = TextCheckerPredictiveTextEngine()
    ) {
        self.lexiconEngine = lexiconEngine
        self.textCheckerEngine = textCheckerEngine
    }
    
    // MARK: - Lexicon Loading
    
    /// `UIInputViewController`로부터 `UILexicon`을 로드합니다.
    ///
    /// `viewDidLoad` 시점에 호출하여 Lexicon 데이터를 준비합니다.
    ///
    /// - Parameter inputViewController: 현재 키보드의 `UIInputViewController`
    func loadLexicon(from inputViewController: UIInputViewController) {
        Task {
            lexiconEngine.setLexicon(await inputViewController.requestSupplementaryLexicon())
        }
    }
    
    // MARK: - Suggestion Methods
    
    /// 현재 입력 컨텍스트를 기반으로 후보를 갱신합니다.
    ///
    /// `UILexicon` 결과를 우선 배치하고, `UITextChecker` 결과로 나머지를 채웁니다.
    /// 중복은 제거되며, 결과는 최대 3개로 제한됩니다.
    /// 마지막 문자가 공백이면 후보를 초기화합니다.
    /// `isEnabled`가 `false`이면 갱신을 건너뜁니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트 (`documentContextBeforeInput`)
    func updateSuggestions(contextBeforeInput: String?) {
        guard isEnabled else { return }
        performUpdateSuggestions(contextBeforeInput: contextBeforeInput)
    }
    
    /// 모든 후보를 초기화합니다.
    func clearSuggestions() {
        currentSuggestions = []
        delegate?.suggestionController(self, didUpdateSuggestions: [])
    }
    
    /// 사용자가 후보를 선택했을 때 호출합니다.
    ///
    /// 현재 입력 중인 단어를 선택한 후보로 교체하기 위한 정보를 반환합니다.
    /// `UITextChecker` 결과인 경우 선택된 단어를 학습하며,
    /// `UILexicon` 결과인 경우 삭제 시 복구를 위해 대치 이력을 기록합니다.
    ///
    /// - Parameters:
    ///   - index: 선택된 후보의 인덱스 (0~2)
    ///   - contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 삭제할 글자 수와 삽입할 텍스트의 튜플, 유효하지 않은 인덱스면 `nil`
    func selectSuggestion(at index: Int, contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)? {
        guard index >= 0, index < currentSuggestions.count else { return nil }
        
        let context = contextBeforeInput ?? ""
        if let last = context.last, last.isWhitespace { return nil }
        
        let item = currentSuggestions[index]
        let currentWord = extractLastWord(from: context)
        
        textCheckerEngine.learn(word: item.text)
        
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
    
    // MARK: - Text Replacement Methods
    
    /// 스페이스 입력 시 텍스트 대치를 시도합니다.
    ///
    /// 커서 앞 텍스트의 끝부분이 `UILexicon`의 `userInput`과 일치하면
    /// 해당 `documentText`로 교체합니다.
    /// 방금 복구된 단축어와 동일하면 대치를 건너뜁니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 대치 수행 정보. 대치가 불필요하면 `nil`
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
    
    /// 삭제 시 방금 수행된 텍스트 대치를 복구합니다.
    ///
    /// 커서 앞 텍스트의 끝부분이 이전에 대치된 `documentText`와 일치하면
    /// 원래 `userInput`으로 되돌립니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 복구 수행 정보. 복구할 대상이 없으면 `nil`
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
    
    /// 스페이스 버튼 이외의 키 입력 시 호출하여 재대치 방지 상태를 초기화합니다.
    func clearIgnoredShortcut() {
        ignoredShortcut = nil
    }
    
    /// 대치 이력을 모두 초기화합니다.
    func clearReplacementHistory() {
        replacementHistory = []
    }
}

// MARK: - Private Methods

private extension SuggestionController {
    /// 실제 후보 갱신 로직
    func performUpdateSuggestions(contextBeforeInput: String?) {
        guard isEnabled else { return }
        
        guard let context = contextBeforeInput, !context.isEmpty else {
            clearSuggestions()
            return
        }
        
        if let last = context.last, last.isWhitespace {
            clearSuggestions()
            return
        }
        
        currentSuggestions = mergeSuggestions(for: context)
        delegate?.suggestionController(self, didUpdateSuggestions: currentSuggestions.map { $0.text })
    }
    
    /// `UILexicon`과 `UITextChecker`의 결과를 병합합니다.
    ///
    /// `UILexicon` 결과를 먼저 배치하여 사용자 개인화 데이터를 우선시하고,
    /// 남은 슬롯을 `UITextChecker` 결과로 채웁니다.
    ///
    /// - Parameter context: 커서 앞의 텍스트
    /// - Returns: 중복 제거된 후보 배열 (최대 3개)
    func mergeSuggestions(for context: String) -> [SuggestionItem] {
        let lexiconResults = lexiconEngine.suggestions(for: context)
        let checkerResults = textCheckerEngine.suggestions(for: context)
        
        var seen = Set<String>()
        var merged: [SuggestionItem] = []
        
        // 1순위: UILexicon (텍스트 대치)
        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestions { return merged }
        }
        
        // 2순위: UITextChecker (시스템 사전)
        for suggestion in checkerResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .textChecker))
            if merged.count >= maxSuggestions { return merged }
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
