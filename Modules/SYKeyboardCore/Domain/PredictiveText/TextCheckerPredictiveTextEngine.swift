//
//  TextCheckerPredictiveTextEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit

/// `UITextChecker` 기반의 자동완성 엔진
///
/// 한국어와 영어를 동시에 지원하며, 커서 앞 텍스트에서 마지막 단어를 추출해
/// `UITextChecker.completions(forPartialWordRange:in:language:)`를 통해
/// 자동완성 후보를 조회합니다.
///
/// ```swift
/// let engine = TextCheckerPredictiveTextEngine()
/// let suggestions = engine.suggestions(for: "hel")
/// // ["hello", "help", "helmet", ...]
/// ```
final class TextCheckerPredictiveTextEngine: PredictiveTextProvider {
    
    // MARK: - Properties
    
    private let checker = UITextChecker()
    private let languages: [String]
    
    // MARK: - Initializer
    
    /// 지정한 언어 목록으로 엔진을 초기화합니다.
    ///
    /// - Parameter languages: 자동완성에 사용할 언어 코드 배열
    init(languages: [String]) {
        self.languages = languages
    }
    
    // MARK: - PredictiveTextService Methods
    
    func suggestions(for contextBeforeInput: String) -> [String] {
        let lastWord = currentWord(from: contextBeforeInput)
        guard !lastWord.isEmpty else { return [] }
        
        let range = NSRange(location: 0, length: lastWord.utf16.count)
        var seen = Set<String>()
        var merged: [String] = []
        
        // 1순위: completions (접두어 자동완성)
        for language in languages {
            let completions = checker.completions(
                forPartialWordRange: range,
                in: lastWord,
                language: language
            ) ?? []
            
            for word in completions {
                let lowered = word.lowercased()
                guard lowered != lastWord.lowercased(),
                      !seen.contains(lowered) else { continue }
                seen.insert(lowered)
                merged.append(word)
            }
        }
        
        // 2순위: guesses (오타 교정, 중복 제거하여 보충)
        for language in languages {
            let guesses = checker.guesses(
                forWordRange: range,
                in: lastWord,
                language: language
            ) ?? []
            
            for word in guesses {
                let lowered = word.lowercased()
                guard lowered != lastWord.lowercased(),
                      !seen.contains(lowered) else { continue }
                seen.insert(lowered)
                merged.append(word)
            }
        }
        
        return merged
    }
    
    func learn(word: String) {
        guard !word.isEmpty else { return }
        UITextChecker.learnWord(word)
    }
}

// MARK: - Private Methods

private extension TextCheckerPredictiveTextEngine {
    /// 텍스트에서 마지막 단어를 추출합니다.
    ///
    /// 공백 문자를 기준으로 분리한 뒤 마지막 요소를 반환합니다.
    /// 텍스트가 비어있거나 공백만 있으면 빈 문자열을 반환합니다.
    ///
    /// - Parameter text: 원본 텍스트
    /// - Returns: 마지막 단어, 없으면 빈 문자열
    func currentWord(from text: String) -> String {
        guard let last = text.split(whereSeparator: { $0.isWhitespace }).last else {
            return ""
        }
        return String(last)
    }
}
