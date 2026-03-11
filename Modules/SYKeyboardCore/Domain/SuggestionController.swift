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
    func suggestionController(_ controller: SuggestionController, didUpdateSuggestions suggestions: [String]
    )
}

/// 자동완성 후보의 조회, 선택, 학습을 관리하는 컨트롤러
///
/// `PredictiveTextService`로부터 후보를 받아 최대 3개로 제한하고,
/// 사용자가 후보를 선택하면 현재 단어를 교체할 정보를 반환합니다.
///
/// ```swift
/// let controller = SuggestionController()
/// controller.delegate = self
/// controller.updateSuggestions(contextBeforeInput: "hel")
/// ```
final class SuggestionController {
    
    // MARK: - Properties
    
    weak var delegate: SuggestionControllerDelegate?
    
    /// 현재 표시 중인 후보 단어 배열
    private(set) var currentSuggestions: [String] = []
    
    private let predictiveTextService: PredictiveTextService
    
    // MARK: - Initializer
    
    /// 지정한 `PredictiveTextService`로 컨트롤러를 초기화합니다.
    ///
    /// - Parameter predictiveTextService: 자동완성 후보를 제공하는 서비스 (기본값: `PredictiveTextEngine()`)
    init(predictiveTextService: PredictiveTextService = PredictiveTextEngine()) {
        self.predictiveTextService = predictiveTextService
    }
    
    // MARK: - Internal Methods
    
    /// 현재 입력 컨텍스트를 기반으로 후보를 갱신합니다.
    ///
    /// 커서 앞 텍스트가 비어있으면 후보를 초기화합니다.
    /// 결과는 최대 3개로 제한되며, 델리게이트를 통해 전달됩니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트 (`documentContextBeforeInput`)
    func updateSuggestions(contextBeforeInput: String?) {
        guard let context = contextBeforeInput, !context.isEmpty else {
            clearSuggestions()
            return
        }
        
        let suggestions = predictiveTextService.suggestions(for: context)
        currentSuggestions = Array(suggestions.prefix(3))
        delegate?.suggestionController(self, didUpdateSuggestions: currentSuggestions)
    }
    
    /// 모든 후보를 초기화합니다.
    ///
    /// 델리게이트에 빈 배열을 전달합니다.
    func clearSuggestions() {
        currentSuggestions = []
        delegate?.suggestionController(self, didUpdateSuggestions: [])
    }
    
    /// 사용자가 후보를 선택했을 때 호출합니다.
    ///
    /// 선택된 단어를 학습하고, 현재 입력 중인 단어를 교체하기 위한 정보를 반환합니다.
    ///
    /// - Parameters:
    ///   - index: 선택된 후보의 인덱스 (0~2)
    ///   - contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 삭제할 글자 수와 삽입할 텍스트의 튜플, 유효하지 않은 인덱스면 `nil`
    func selectSuggestion(at index: Int, contextBeforeInput: String?) -> (deleteCount: Int, insertText: String)? {
        guard index >= 0, index < currentSuggestions.count else { return nil }
        
        let selected = currentSuggestions[index]
        let currentWord = extractLastWord(from: contextBeforeInput ?? "")
        
        predictiveTextService.learn(word: selected)
        
        return (deleteCount: currentWord.count, insertText: selected + " ")
    }
}

// MARK: - Private Methods

private extension SuggestionController {
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
