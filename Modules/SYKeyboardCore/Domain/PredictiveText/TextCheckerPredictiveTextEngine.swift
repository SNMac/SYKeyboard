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
    
    /// `SuggestionController`의 TextChecker 큐에서만 접근한다.
    /// `UITextChecker`는 스레드 안전성이 문서화되지 않았으므로 다른 스레드에서 사용하지 않는다.
    /// `learn(word:)`가 쓰는 `UITextChecker.learnWord` 같은 클래스 메서드는 인스턴스와 무관하게 main에서 호출한다
    private let checker = UITextChecker()
    private let language: String

    /// 성능 계측용 signposter. 인스턴스마다 만들 필요가 없어 타입 프로퍼티로 공유한다
    private static let signposter = OSSignposter(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "TextCheckerPredictiveTextEngine"
    )
    
    static let learnedWordsKey = "com.snmac.sykeyboard.textchecker.learnedWords"
    
    private let storage: UserDefaults
    
    /// 학습한 단어 목록
    ///
    /// App Group `UserDefaults`에 `[String]`으로 저장되며,
    /// getter에서 `Set`으로 변환하여 중복을 방지합니다.
    /// 다른 프로세스가 쓴 값을 덮어쓰지 않도록 수정할 때마다 저장소에서 다시 읽는다
    private var learnedWords: Set<String> {
        get {
            let array = storage.stringArray(forKey: Self.learnedWordsKey) ?? []
            return Set(array)
        }
        set {
            storage.set(Array(newValue), forKey: Self.learnedWordsKey)
            cachedLearnedWords = newValue
        }
    }
    
    /// `canUnlearn(word:)`용 학습 단어 목록 캐시. `nil`이면 다음 조회 때 저장소에서 읽는다.
    ///
    /// 후보 바를 갱신할 때마다 `UITextChecker.hasLearnedWord`나 `UserDefaults`를 읽지 않으려고 둔다(#156, #161).
    /// main에서만 접근한다
    private var cachedLearnedWords: Set<String>?
    
    // MARK: - Initializer
    
    /// 지정한 언어 목록으로 엔진을 초기화합니다.
    ///
    /// - Parameters:
    ///   - language: 자동완성에 사용할 언어 코드
    ///   - storage: 학습 단어 목록 저장소. 기본값은 App Group `UserDefaults`
    public init(language: String, storage: UserDefaults? = nil) {
        self.language = language
        if let storage {
            self.storage = storage
        } else {
            guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
                fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
            }
            self.storage = userDefaults
        }
    }
    
    // MARK: - PredictiveTextProvider Methods
    
    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        let lastWord = currentWord(from: baseText)
        guard !lastWord.isEmpty, limit > 0 else { return [] }

        let range = NSRange(location: 0, length: lastWord.utf16.count)
        let loweredLastWord = lastWord.lowercased()
        var seen = Set<String>()
        var merged: [String] = []

        func append(_ words: [String]) {
            for word in words {
                let lowered = word.lowercased()
                guard lowered != loweredLastWord,
                      !seen.contains(lowered) else { continue }
                seen.insert(lowered)
                merged.append(word)
                if merged.count >= limit { return }
            }
        }

        // 1순위: completions (접두어 자동완성)
        let completionsState = Self.signposter.beginInterval("TextCheckerCompletions")
        let completions = checker.completions(
            forPartialWordRange: range,
            in: lastWord,
            language: language
        ) ?? []
        Self.signposter.endInterval("TextCheckerCompletions", completionsState)
        append(completions)

        // completions만으로 limit이 차면 guesses는 결과에 기여할 수 없으므로 호출하지 않는다
        guard merged.count < limit else { return merged }

        // 2순위: guesses (오타 교정, 중복 제거하여 보충)
        let guessesState = Self.signposter.beginInterval("TextCheckerGuesses")
        let guesses = checker.guesses(
            forWordRange: range,
            in: lastWord,
            language: language
        ) ?? []
        Self.signposter.endInterval("TextCheckerGuesses", guessesState)
        append(guesses)

        return merged
    }
    
    func learn(word: String) {
        guard !word.isEmpty, !UITextChecker.hasLearnedWord(word) else { return }
        UITextChecker.learnWord(word)
        learnedWords.insert(word)
        
        logger.debug("[TextChecker] 시스템 사전 학습: \(word)")
    }

    /// 앱이 저장한 학습 단어 목록에 있으면 `true`를 반환합니다.
    ///
    /// 시스템 사전(`UITextChecker.hasLearnedWord`)은 보지 않는다. 학습 단어 수에 비례해 느려 후보 바를
    /// 갱신할 때마다 부를 수 없고(#156), 앱이 학습시킨 단어만 지울 수 있게 하려는 것이다(#161).
    /// 그래서 iOS 키보드 사전 재설정으로 시스템 사전에서 빠진 단어도 목록에 남아 있으면 `true`다
    func canUnlearn(word: String) -> Bool {
        if cachedLearnedWords == nil {
            cachedLearnedWords = learnedWords
        }
        return cachedLearnedWords?.contains(word) == true
    }

    func invalidateLearnedWordsCache() {
        cachedLearnedWords = nil
    }

    func unlearn(word: String) {
        guard !word.isEmpty else { return }
        // 시스템 사전에서 이미 빠진 단어(키보드 사전 재설정)도 목록에서는 빼야 medium 표시가 사라진다
        if UITextChecker.hasLearnedWord(word) {
            UITextChecker.unlearnWord(word)
        }
        learnedWords.remove(word)

        logger.debug("[TextChecker] 시스템 사전 학습 해제: \(word)")
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
