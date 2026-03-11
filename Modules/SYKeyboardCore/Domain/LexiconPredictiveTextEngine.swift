//
//  LexiconPredictiveTextEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

/// `UILexicon` 기반의 자동완성 엔진
///
/// 사용자의 연락처, 텍스트 대치 항목 등 개인화된 데이터를 기반으로
/// 자동완성 후보를 제공합니다.
///
/// - Note: `UILexicon`은 키보드 익스텐션에서만 사용 가능하며,
///   `UIInputViewController.requestSupplementaryLexicon`을 통해 로드해야 합니다.
final class LexiconPredictiveTextEngine: PredictiveTextService {
    
    // MARK: - Properties
    
    private(set) var lexicon: UILexicon?
    
    // MARK: - Internal Methods
    
    /// `UILexicon`을 설정합니다.
    ///
    /// `UIInputViewController.requestSupplementaryLexicon`의 결과를 전달받아 저장합니다.
    ///
    /// - Parameter lexicon: 로드된 `UILexicon` 객체
    func setLexicon(_ lexicon: UILexicon) {
        self.lexicon = lexicon
    }
    
    // MARK: - PredictiveTextService Methods
    
    /// 현재 입력된 단어와 정확히 일치하는 텍스트 대치 후보만 반환합니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트
    /// - Returns: 정확히 매칭된 대치 결과 배열
    func suggestions(for contextBeforeInput: String) -> [String] {
        guard let lexicon = lexicon else { return [] }
        
        let lastWord = currentWord(from: contextBeforeInput)
        guard !lastWord.isEmpty else { return [] }
        
        let lowered = lastWord.lowercased()
        
        return lexicon.entries.compactMap { entry in
            let entryInput = entry.userInput.lowercased()
            let entryDoc = entry.documentText.lowercased()
            
            guard entryInput == lowered,
                  entryDoc != lowered else { return nil }
            
            return entry.documentText
        }
    }
    
    // UILexicon은 시스템이 관리하므로 학습 불필요
    func learn(word: String) {}
}

// MARK: - Private Methods

private extension LexiconPredictiveTextEngine {
    func currentWord(from text: String) -> String {
        guard let last = text.split(whereSeparator: { $0.isWhitespace }).last else {
            return ""
        }
        return String(last)
    }
}
