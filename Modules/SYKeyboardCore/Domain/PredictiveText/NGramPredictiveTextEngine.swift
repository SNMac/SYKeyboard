//
//  NGramPredictiveTextEngine.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/12/26.
//

import Foundation
import OSLog

/// 사용자 입력 이력 기반 n-gram 다음 단어 예측 엔진
///
/// 사용자가 입력한 단어를 unigram(1-gram), bigram(2-gram), trigram(3-gram)으로 기록하여
/// 문맥에 따른 다음 단어를 빈도순으로 예측합니다.
/// 문맥이 없는 경우(키보드 처음 열림 등)에는 unigram으로 자주 사용한 단어를 추천합니다.
///
/// ```swift
/// let engine = NGramPredictiveTextEngine()
/// engine.addWord("오늘")     // 버퍼: ["오늘"]
/// engine.addWord("날씨")     // 버퍼: ["오늘", "날씨"], bigram 기록: "오늘" → "날씨"
/// engine.addWord("좋다")     // bigram + trigram 기록
///
/// // 이후 "오늘 날씨" 입력 시
/// engine.suggestions(for: "오늘 날씨") // → ["좋다"]
/// ```
///
/// ## 저장 구조
/// - `UserDefaults(suiteName:)`을 통해 App Group에 영구 저장
/// - unigram: `[String: Int]` 형태
/// - bigram/trigram: 각각 `[String: [String: Int]]` 형태
/// - 항목 수 제한으로 메모리 과다 사용 방지
///
/// ## 동작 흐름
/// 1. 스페이스 입력 시 `addWord(_:)`로 단어 축적 및 n-gram 기록
/// 2. 리턴 입력 시 `endSentence()`로 문장 버퍼 초기화
/// 3. 입력 없음 / 자동완성 후 `suggestions(for:)`로 다음 단어 예측
final public class NGramPredictiveTextEngine: PredictiveTextProvider {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// unigram 저장소: "단어" → 빈도수
    private var unigramStore: [String: Int] = [:]
    /// bigram 저장소: "직전 단어" → ["다음 단어": 빈도수]
    private var bigramStore: [String: [String: Int]] = [:]
    /// trigram 저장소: "직전 2단어" → ["다음 단어": 빈도수]
    private var trigramStore: [String: [String: Int]] = [:]
    
    /// 현재 문장의 단어 버퍼
    private var currentSentenceWords: [String] = []
    
    /// 예측 최대 반환 개수
    private let maxPredictions = 3
    
    /// n-gram 키 최대 항목 수 (이 수를 초과하면 빈도 낮은 항목부터 정리)
    private let maxEntriesPerKey = 50
    /// 전체 키 최대 개수
    private let maxKeys = 5000
    
    // UserDefaults 저장 키
    private static let unigramStoreKey = "com.snmac.sykeyboard.ngram.unigram"
    private static let bigramStoreKey = "com.snmac.sykeyboard.ngram.bigram"
    private static let trigramStoreKey = "com.snmac.sykeyboard.ngram.trigram"
    
    /// App Group UserDefaults
    private let storage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
    
    /// 디스크 저장 디바운스용 카운터
    private var writeCounter: Int = 0
    /// 디스크 저장 주기 (n번 기록마다 1회 저장)
    private let writePeriod = 10
    
    // MARK: - Initializer
    
    public init() {
        loadFromDisk()
    }
    
    // MARK: - PredictiveTextProvider
    
    /// 커서 앞 문맥을 기반으로 다음 단어를 예측합니다.
    ///
    /// trigram(직전 2단어) → bigram(직전 1단어) → unigram(빈도순) 순으로
    /// 조회하며, 각 단계에서 부족한 슬롯을 다음 단계로 보충합니다.
    /// 문맥이 비어있으면 unigram만 사용합니다.
    ///
    /// - Parameter contextBeforeInput: 커서 앞의 텍스트 (빈 문자열 가능)
    /// - Returns: 빈도순으로 정렬된 다음 단어 후보 배열 (최대 3개)
    func suggestions(for contextBeforeInput: String) -> [String] {
        let words = contextBeforeInput
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        
        // 문맥이 없으면 unigram (자주 사용한 단어)
        if words.isEmpty {
            return rankedUnigramCandidates()
        }
        
        var seen = Set<String>()
        var results: [String] = []
        
        // 1순위: trigram (직전 2단어로 예측)
        if words.count >= 2 {
            let key = "\(words[words.count - 2]) \(words[words.count - 1])"
            let candidates = rankedCandidates(from: trigramStore, key: key)
            for word in candidates {
                guard !seen.contains(word.lowercased()) else { continue }
                seen.insert(word.lowercased())
                results.append(word)
                if results.count >= maxPredictions { return results }
            }
        }
        
        // 2순위: bigram (직전 1단어로 예측)
        let lastWord = words[words.count - 1]
        let candidates = rankedCandidates(from: bigramStore, key: lastWord)
        for word in candidates {
            guard !seen.contains(word.lowercased()) else { continue }
            seen.insert(word.lowercased())
            results.append(word)
            if results.count >= maxPredictions { return results }
        }
        
        // 3순위: unigram (슬롯이 남아있으면 보충)
        if results.count < maxPredictions {
            for word in rankedUnigramCandidates() {
                guard !seen.contains(word.lowercased()) else { continue }
                seen.insert(word.lowercased())
                results.append(word)
                if results.count >= maxPredictions { break }
            }
        }
        
        return results
    }
    
    /// n-gram에서는 단어 단위 학습을 사용하지 않습니다.
    ///
    /// 시퀀스 기록은 `addWord(_:)`를 통해 수행합니다.
    func learn(word: String) {}
    
    // MARK: - Sequence Recording
    
    /// 단어를 현재 문장 버퍼에 추가하고 n-gram을 기록합니다.
    ///
    /// 스페이스 입력 시 직전 단어를 전달하여 호출합니다.
    ///
    /// - Parameter word: 추가할 단어
    func addWord(_ word: String) {
        guard !word.isEmpty else { return }
        currentSentenceWords.append(word)
        recordNGrams()
        scheduleSave()
        
        logger.debug("[NGram] n-gram 기록: \(word)")
    }
    
    /// 문장이 끝났을 때 버퍼를 초기화합니다.
    ///
    /// 리턴 키 입력 시 호출합니다.
    func endSentence() {
        currentSentenceWords.removeAll()
    }
    
    // MARK: - Persistence
    
    /// n-gram 데이터를 디스크에 저장합니다.
    func saveToDisk() {
        storage.set(unigramStore, forKey: Self.unigramStoreKey)
        storage.set(bigramStore, forKey: Self.bigramStoreKey)
        storage.set(trigramStore, forKey: Self.trigramStoreKey)
    }
    
    /// 모든 학습 데이터를 초기화합니다.
    public func resetAllData() {
        unigramStore = [:]
        bigramStore = [:]
        trigramStore = [:]
        currentSentenceWords = []
        storage.removeObject(forKey: Self.unigramStoreKey)
        storage.removeObject(forKey: Self.bigramStoreKey)
        storage.removeObject(forKey: Self.trigramStoreKey)
        
        logger.debug("[NGram] 학습 데이터 초기화")
    }
}

// MARK: - Private Methods

private extension NGramPredictiveTextEngine {
    /// 디스크에서 n-gram 데이터를 로드합니다.
    func loadFromDisk() {
        unigramStore = (storage.dictionary(forKey: Self.unigramStoreKey)
                as? [String: Int]) ?? [:]
        bigramStore = (storage.dictionary(forKey: NGramPredictiveTextEngine.bigramStoreKey)
            as? [String: [String: Int]]) ?? [:]
        trigramStore = (storage.dictionary(forKey: NGramPredictiveTextEngine.trigramStoreKey)
            as? [String: [String: Int]]) ?? [:]
    }
    
    /// 현재 버퍼의 마지막 단어들로 n-gram을 기록합니다.
    func recordNGrams() {
        let words = currentSentenceWords
        let count = words.count
        
        // unigram: 현재 단어
        let currentWord = words[count - 1]
        unigramStore[currentWord, default: 0] += 1
        
        // bigram: 직전 단어 → 현재 단어
        if count >= 2 {
            let key = words[count - 2]
            let value = words[count - 1]
            bigramStore[key, default: [:]][value, default: 0] += 1
            pruneEntries(in: &bigramStore, forKey: key)
            logger.debug("[NGram] bigram: \"\(key)\" → \"\(value)\" (count: \(self.bigramStore[key]?[value] ?? 0))")
        }
        
        // trigram: 직전 2단어 → 현재 단어
        if count >= 3 {
            let key = "\(words[count - 3]) \(words[count - 2])"
            let value = words[count - 1]
            trigramStore[key, default: [:]][value, default: 0] += 1
            pruneEntries(in: &trigramStore, forKey: key)
            logger.debug("[NGram] trigram: \"\(key)\" → \"\(value)\" (count: \(self.trigramStore[key]?[value] ?? 0))")
        }
        
        pruneUnigram()
        pruneKeys(in: &bigramStore)
        pruneKeys(in: &trigramStore)
    }
    
    /// 빈도순으로 정렬된 unigram 후보를 반환합니다.
    ///
    /// 문맥이 없거나 trigram/bigram 결과가 부족할 때 사용됩니다.
    ///
    /// - Returns: 빈도순으로 정렬된 단어 배열 (최대 `maxPredictions`개)
    func rankedUnigramCandidates() -> [String] {
        return unigramStore
            .sorted { $0.value > $1.value }
            .prefix(maxPredictions)
            .map { $0.key }
    }
    
    /// 빈도순으로 정렬된 후보를 반환합니다.
    ///
    /// - Parameters:
    ///   - store: n-gram 저장소
    ///   - key: 문맥 키
    /// - Returns: 빈도순으로 정렬된 단어 배열
    func rankedCandidates(from store: [String: [String: Int]], key: String) -> [String] {
        guard let frequencies = store[key] else { return [] }
        return frequencies
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    /// unigram 항목 수가 제한을 초과하면 빈도 낮은 항목을 제거합니다.
    ///
    /// `maxKeys`를 초과할 때 빈도가 낮은 순서대로 제거합니다.
    func pruneUnigram() {
        guard unigramStore.count > maxKeys else { return }
        let sorted = unigramStore.sorted { $0.value < $1.value }
        let removeCount = unigramStore.count - maxKeys
        for i in 0..<removeCount {
            unigramStore.removeValue(forKey: sorted[i].key)
        }
    }
    
    /// 특정 키의 항목 수가 제한을 초과하면 빈도 낮은 항목을 제거합니다.
    ///
    /// - Parameters:
    ///   - store: n-gram 저장소
    ///   - key: 정리할 키
    func pruneEntries(in store: inout [String: [String: Int]], forKey key: String) {
        guard let entries = store[key], entries.count > maxEntriesPerKey else { return }
        
        let sorted = entries.sorted { $0.value > $1.value }
        let topEntries = Array(sorted.prefix(maxEntriesPerKey))
        let pruned = Dictionary(uniqueKeysWithValues: topEntries)
        store[key] = pruned
    }
    
    /// 전체 키 수가 제한을 초과하면 총 빈도가 낮은 키를 제거합니다.
    ///
    /// - Parameter store: n-gram 저장소
    func pruneKeys(in store: inout [String: [String: Int]]) {
        guard store.count > maxKeys else { return }
        
        // 각 키의 총 빈도를 계산하여 낮은 순으로 제거
        let keysWithTotalFreq = store.map { (key: $0.key, total: $0.value.values.reduce(0, +)) }
        let sorted = keysWithTotalFreq.sorted { $0.total < $1.total }
        
        let removeCount = store.count - maxKeys
        for i in 0..<removeCount {
            store.removeValue(forKey: sorted[i].key)
        }
    }
    
    /// 일정 주기마다 디스크에 저장합니다.
    func scheduleSave() {
        writeCounter += 1
        if writeCounter >= writePeriod {
            writeCounter = 0
            saveToDisk()
        }
    }
}
