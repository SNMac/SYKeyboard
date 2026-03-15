//
//  TextCheckerPredictiveTextEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

import UIKit
import OSLog

/// `UITextChecker` 기반의 자동완성 엔진
///
/// 한국어와 영어를 동시에 지원하며, 커서 앞 텍스트에서 마지막 단어를 추출해
/// `UITextChecker.completions(forPartialWordRange:in:language:)`와
/// `UITextChecker.guesses(forWordRange:in:language:)`를 통해
/// 자동완성 및 오타 교정 후보를 조회합니다.
///
/// 학습한 단어 목록을 App Group `UserDefaults`에 저장하여
/// 메인 앱에서 일괄 초기화할 수 있습니다.
///
/// ```swift
/// let engine = TextCheckerPredictiveTextEngine(languages: ["ko_KR", "en_US"])
/// let suggestions = engine.suggestions(for: "hel")
/// // ["hello", "help", "helmet", ...]
/// ```
final public class TextCheckerPredictiveTextEngine: PredictiveTextProvider {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    private let checker = UITextChecker()
    private let language: String
    
    private static let learnedWordsKey = "com.snmac.sykeyboard.textchecker.learnedWords"
    
    private let storage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
    
    /// 학습한 단어 목록
    ///
    /// App Group `UserDefaults`에 `[String]`으로 저장되며,
    /// getter에서 `Set`으로 변환하여 중복을 방지합니다.
    private var learnedWords: Set<String> {
        get {
            let array = storage.stringArray(forKey: Self.learnedWordsKey) ?? []
            return Set(array)
        }
        set {
            storage.set(Array(newValue), forKey: Self.learnedWordsKey)
        }
    }
    
    // MARK: - Initializer
    
    /// 지정한 언어 목록으로 엔진을 초기화합니다.
    ///
    /// - Parameter language: 자동완성에 사용할 언어 코드
    public init(language: String) {
        self.language = language
    }
    
    // MARK: - PredictiveTextProvider Methods
    
    func suggestions(for baseText: String) -> [String] {
        let lastWord = currentWord(from: baseText)
        guard !lastWord.isEmpty else { return [] }
        
        let range = NSRange(location: 0, length: lastWord.utf16.count)
        var seen = Set<String>()
        var merged: [String] = []
        
        // 1순위: completions (접두어 자동완성)
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
        
        // 2순위: guesses (오타 교정, 중복 제거하여 보충)
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
        
        return merged
    }
    
    func learn(word: String) {
        guard !word.isEmpty, !UITextChecker.hasLearnedWord(word) else { return }
        UITextChecker.learnWord(word)
        learnedWords.insert(word)
        
        logger.debug("[TextChecker] 시스템 사전 학습: \(word)")
    }
    
    // MARK: - Reset Methods
    
    /// 학습한 모든 단어를 시스템 사전에서 제거하고 저장소를 초기화합니다.
    public func unlearnAllWords() {
        for word in learnedWords {
            UITextChecker.unlearnWord(word)
        }
        learnedWords = []
        
        logger.debug("[TextChecker] 시스템 사전 초기화")
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
