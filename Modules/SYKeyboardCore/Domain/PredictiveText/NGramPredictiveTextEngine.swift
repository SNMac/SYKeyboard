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
/// 언어별로 데이터가 분리되어 저장됩니다. 생성 시 전달한 `language` 식별자에 따라
/// 한글 키보드는 한글 n-gram만, 영어 키보드는 영어 n-gram만 조회·기록합니다.
///
/// ```swift
/// let koEngine = NGramPredictiveTextEngine(language: "ko")
/// let enEngine = NGramPredictiveTextEngine(language: "en")
///
/// koEngine.addWord("오늘")
/// koEngine.addWord("날씨")
/// koEngine.suggestions(for: "오늘") // → ["날씨"] (한글 데이터만 조회)
///
/// enEngine.addWord("good")
/// enEngine.addWord("morning")
/// enEngine.suggestions(for: "good") // → ["morning"] (영어 데이터만 조회)
/// ```
///
/// ## 저장 구조
/// - App Group 컨테이너에 언어별 바이너리 plist 파일로 영구 저장
/// - 파일명: `ngram_{language}.plist` (예: `ngram_ko.plist`)
/// - 항목 수 제한으로 메모리 과다 사용 방지
///
/// ## 동작 흐름
/// 1. 스페이스 입력 시 `addWord(_:)`로 단어 축적 및 n-gram 기록
/// 2. 리턴 입력 시 `endSentence()`로 문장 버퍼 초기화
/// 3. 입력 없음 / 자동완성 후 `suggestions(for:)`로 다음 단어 예측
///
/// ## 비동기 로딩
/// 디스크 로딩은 백그라운드 스레드에서 수행되며, 완료 전까지 조회·기록 요청은
/// 빈 결과 반환 / 무시됩니다. 키보드 표시 속도에 영향을 주지 않습니다.
///
/// ## 마이그레이션
/// 기존 UserDefaults에 저장된 n-gram 데이터가 있는 경우,
/// 초기 로딩 시 자동으로 파일로 마이그레이션한 뒤 UserDefaults에서 제거합니다.
final public class NGramPredictiveTextEngine: PredictiveTextProvider {
    
    // MARK: - Storage Model
    
    /// n-gram 데이터를 하나의 파일로 묶는 Codable 구조체
    fileprivate struct NGramData: Codable {
        var unigram: [String: Int]
        var bigram: [String: [String: Int]]
        var trigram: [String: [String: Int]]
    }
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// 언어 식별자 (예: "ko", "en")
    private let language: String
    
    /// 디스크 로딩 완료 여부 (로딩 전에는 조회·기록을 건너뜀)
    private var isLoaded = false
    
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
    
    /// 바이너리 plist 파일 경로
    private let fileURL: URL
    
    /// 백그라운드 저장용 직렬 큐
    private let saveQueue = DispatchQueue(label: "com.snmac.sykeyboard.ngram.save", qos: .utility)
    
    /// 디스크 저장 디바운스용 카운터
    private var writeCounter: Int = 0
    /// 디스크 저장 주기 (n번 기록마다 1회 저장)
    private let writePeriod = 10
    
    // MARK: - Legacy UserDefaults (마이그레이션용)
    
    /// 기존 UserDefaults 저장 키 — 마이그레이션 후 제거
    private var legacyUnigramKey: String {
        "com.snmac.sykeyboard.ngram.\(language).unigram"
    }
    private var legacyBigramKey: String {
        "com.snmac.sykeyboard.ngram.\(language).bigram"
    }
    private var legacyTrigramKey: String {
        "com.snmac.sykeyboard.ngram.\(language).trigram"
    }
    
    /// App Group UserDefaults (마이그레이션 읽기/삭제 전용)
    private let legacyStorage: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        return userDefaults
    }()
    
    // MARK: - Initializer
    
    /// 언어별 n-gram 엔진을 생성합니다.
    ///
    /// 디스크 로딩은 백그라운드에서 수행되며, 완료 전까지
    /// `suggestions`는 빈 배열, `addWord`/`endSentence`는 무시됩니다.
    ///
    /// 기존 UserDefaults에 데이터가 남아있으면 자동으로 파일로 마이그레이션합니다.
    ///
    /// - Parameter language: 언어 식별자 (예: "ko-KR", "en-US")
    public init(language: String) {
        self.language = language
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else {
            fatalError("App Group 컨테이너 URL을 가져오는 데 실패했습니다.")
        }
        self.fileURL = containerURL.appendingPathComponent("ngram_\(language).plist")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            let loaded = self.loadFromFile()
                ?? self.migrateFromUserDefaults()
                ?? NGramData(unigram: [:], bigram: [:], trigram: [:])
            
            DispatchQueue.main.async {
                self.unigramStore = loaded.unigram
                self.bigramStore = loaded.bigram
                self.trigramStore = loaded.trigram
                self.isLoaded = true
                self.logger.debug("[NGram/\(self.language)] 디스크 로딩 완료")
            }
        }
    }
    
    // MARK: - PredictiveTextProvider
    
    /// 커서 앞 문맥을 기반으로 다음 단어를 예측합니다.
    ///
    /// trigram(직전 2단어) → bigram(직전 1단어) → unigram(빈도순) 순으로
    /// 조회하며, 각 단계에서 부족한 슬롯을 다음 단계로 보충합니다.
    /// 문맥이 비어있으면 unigram만 사용합니다.
    ///
    /// 디스크 로딩이 완료되지 않은 경우 빈 배열을 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트 (`inputBuffer`)
    /// - Returns: 빈도순으로 정렬된 다음 단어 후보 배열 (최대 3개)
    func suggestions(for baseText: String) -> [String] {
        guard isLoaded else { return [] }
        
        let words = baseText
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
    /// 디스크 로딩이 완료되지 않은 경우 무시됩니다.
    ///
    /// - Parameter word: 추가할 단어
    func addWord(_ word: String) {
        guard isLoaded, !word.isEmpty else { return }
        currentSentenceWords.append(word)
        recordNGrams()
        scheduleSave()
        
        logger.debug("[NGram/\(self.language)] n-gram 기록: \(word)")
    }
    
    /// 마지막 단어를 기록한 뒤 문장 버퍼를 초기화합니다.
    ///
    /// 리턴 키 입력 시 호출합니다.
    /// 스페이스 없이 바로 리턴을 누른 경우, 마지막 단어가 아직 기록되지 않았을 수 있으므로
    /// `lastWord`를 전달하면 중복 없이 기록 후 버퍼를 초기화합니다.
    ///
    /// 디스크 로딩이 완료되지 않은 경우 무시됩니다.
    ///
    /// - Parameter lastWord: 리턴 직전에 아직 커밋되지 않은 단어 (없으면 `nil`)
    func endSentence(lastWord: String? = nil) {
        guard isLoaded else { return }
        if let word = lastWord, !word.isEmpty {
            addWord(word)
        }
        currentSentenceWords.removeAll()
    }
    
    // MARK: - Persistence
    
    /// n-gram 데이터를 백그라운드에서 디스크에 저장합니다.
    ///
    /// 메인 스레드에서 스냅샷을 캡처한 뒤 직렬 큐에서 인코딩·쓰기를 수행하여
    /// 입력 처리를 블로킹하지 않습니다.
    ///
    /// 디스크 로딩이 완료되지 않은 경우 빈 데이터로 덮어쓰는 것을 방지하기 위해
    /// 저장을 건너뜁니다.
    func saveToDisk() {
        guard isLoaded else { return }
        
        let snapshot = NGramData(
            unigram: unigramStore,
            bigram: bigramStore,
            trigram: trigramStore
        )
        let url = fileURL
        
        saveQueue.async { [weak self] in
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                self?.logger.error("[NGram] 디스크 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 모든 학습 데이터를 초기화합니다.
    public func resetAllData() {
        unigramStore = [:]
        bigramStore = [:]
        trigramStore = [:]
        currentSentenceWords = []
        
        // 파일 삭제
        try? FileManager.default.removeItem(at: fileURL)
        
        // 레거시 UserDefaults도 정리 (마이그레이션 전 사용자 대비)
        legacyStorage.removeObject(forKey: legacyUnigramKey)
        legacyStorage.removeObject(forKey: legacyBigramKey)
        legacyStorage.removeObject(forKey: legacyTrigramKey)
        
        logger.debug("[NGram/\(self.language)] 학습 데이터 초기화")
    }
}

// MARK: - Private Methods

private extension NGramPredictiveTextEngine {
    
    // MARK: File I/O
    
    /// 바이너리 plist 파일에서 n-gram 데이터를 로드합니다.
    ///
    /// - Returns: 로드된 데이터, 파일이 없거나 파싱 실패 시 `nil`
    func loadFromFile() -> NGramData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? PropertyListDecoder().decode(NGramData.self, from: data)
    }
    
    // MARK: Migration
    
    /// 기존 UserDefaults에서 n-gram 데이터를 읽어 파일로 마이그레이션합니다.
    ///
    /// UserDefaults에 데이터가 없으면 `nil`을 반환합니다.
    /// 마이그레이션 성공 시 UserDefaults에서 기존 키를 제거합니다.
    ///
    /// - Returns: 마이그레이션된 데이터, 기존 데이터가 없으면 `nil`
    func migrateFromUserDefaults() -> NGramData? {
        let unigram = legacyStorage.dictionary(forKey: legacyUnigramKey)
            as? [String: Int]
        let bigram = legacyStorage.dictionary(forKey: legacyBigramKey)
            as? [String: [String: Int]]
        let trigram = legacyStorage.dictionary(forKey: legacyTrigramKey)
            as? [String: [String: Int]]
        
        // 세 저장소 모두 비어있으면 마이그레이션 대상 없음
        guard unigram != nil || bigram != nil || trigram != nil else { return nil }
        
        let migrated = NGramData(
            unigram: unigram ?? [:],
            bigram: bigram ?? [:],
            trigram: trigram ?? [:]
        )
        
        // 파일로 저장
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let data = try encoder.encode(migrated)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("[NGram/\(self.language)] 마이그레이션 저장 실패: \(error.localizedDescription)")
            return migrated  // 메모리에는 올려서 사용, 다음 saveToDisk에서 재시도
        }
        
        // UserDefaults에서 기존 키 제거
        legacyStorage.removeObject(forKey: legacyUnigramKey)
        legacyStorage.removeObject(forKey: legacyBigramKey)
        legacyStorage.removeObject(forKey: legacyTrigramKey)
        
        logger.debug("[NGram/\(self.language)] UserDefaults → 파일 마이그레이션 완료")
        
        return migrated
    }
    
    // MARK: N-Gram Recording
    
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
            logger.debug("[NGram/\(self.language)] bigram: \"\(key)\" → \"\(value)\" (count: \(self.bigramStore[key]?[value] ?? 0))")
        }
        
        // trigram: 직전 2단어 → 현재 단어
        if count >= 3 {
            let key = "\(words[count - 3]) \(words[count - 2])"
            let value = words[count - 1]
            trigramStore[key, default: [:]][value, default: 0] += 1
            pruneEntries(in: &trigramStore, forKey: key)
            logger.debug("[NGram/\(self.language)] trigram: \"\(key)\" → \"\(value)\" (count: \(self.trigramStore[key]?[value] ?? 0))")
        }
        
        pruneUnigram()
        pruneKeys(in: &bigramStore)
        pruneKeys(in: &trigramStore)
    }
    
    // MARK: Ranking
    
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
    
    // MARK: Pruning
    
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
    
    // MARK: Save Scheduling
    
    /// 일정 주기마다 디스크에 저장합니다.
    func scheduleSave() {
        writeCounter += 1
        if writeCounter >= writePeriod {
            writeCounter = 0
            saveToDisk()
        }
    }
}
