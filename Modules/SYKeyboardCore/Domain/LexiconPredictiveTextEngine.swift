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
    
    func suggestions(for contextBeforeInput: String) -> [String] {
        guard let lexicon = lexicon else { return [] }
        
        let lastWord = currentWord(from: contextBeforeInput)
        guard !lastWord.isEmpty else { return [] }
        
        let lowered = lastWord.lowercased()
        
        return lexicon.entries.compactMap { entry in
            let entryInput = entry.userInput.lowercased()
            let entryDoc = entry.documentText.lowercased()
            
            // 입력 중인 단어와 동일하면 제외
            guard entryDoc != lowered else { return nil }
            
            // userInput이 현재 입력의 접두사와 일치하거나,
            // documentText가 현재 입력의 접두사와 일치하면 후보로 반환
            if entryInput.hasPrefix(lowered) || entryDoc.hasPrefix(lowered) {
                return entry.documentText
            }
            
            // 정확히 일치하는 경우 (텍스트 대치용)
            if entryInput == lowered {
                return entry.documentText
            }
            
            return nil
        }
    }
    
    func learn(word: String) {
        // UILexicon은 시스템이 관리하므로 학습 불필요
    }
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
