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
/// 문맥에 따른 다음 단어를 최근 사용이 반영된 점수순으로 예측합니다.
/// 점수는 쓸 때마다 +1, 입력 단어 `halfLife`개마다 절반이 되는 지수 감쇠입니다(#159).
/// 문맥이 없는 경우(키보드 처음 열림 등)에는 unigram으로 자주·최근에 사용한 단어를 추천합니다.
///
/// 식별자별로 데이터가 분리되어 저장됩니다. 생성 시 전달한 `language` 식별자에 따라
/// 한글 키보드는 한글 n-gram만, 영어 키보드는 영어 n-gram만 조회·기록합니다.
/// 한영 통합 키보드는 `hangeulEnglishLanguage`(`"ko-en"`) 식별자 하나로 두 언어를
/// 함께 기록·조회합니다(언어 전환 경계를 넘는 문맥 사용).
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
/// - App Group 컨테이너의 `Library/Application Support/`에 식별자별 바이너리 plist 파일로 영구 저장
/// - 파일명: `ngram_{language}.plist` (예: `ngram_ko.plist`, 한영 통합은 `ngram_ko-en.plist`)
/// - 항목 수 제한으로 메모리 과다 사용 방지. 오래 쓰지 않은 항목은 로딩 때 지운다
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
/// - 컨테이너 루트에 있던 옛 파일은 생성 시 새 위치로 한 번 옮깁니다. 옮기지 못하면 옛 파일을 계속 읽고 저장은 새 위치로 합니다.
/// - 기존 `UserDefaults`에 저장된 n-gram 데이터가 있는 경우,
///   초기 로딩 시 자동으로 파일로 마이그레이션한 뒤 UserDefaults에서 제거합니다.
final public class NGramPredictiveTextEngine: PredictiveTextProvider {
    
    // MARK: - Storage Model
    
    /// n-gram 데이터를 하나의 파일로 묶는 Codable 구조체 (저장 형식 2, #159)
    ///
    /// 값은 기준 시점(클록 0)으로 환산한 점수 `Σ 2^(사용 시점 / halfLife)`다.
    /// 현재 점수는 `값 × 2^(-clock / halfLife)`이고, 모든 항목이 같은 비율로 줄어드는 셈이라 값끼리 바로 비교·합산한다
    fileprivate struct NGramData: Codable {
        static let currentVersion = 2

        var version = NGramData.currentVersion
        /// 기준 시점 이후 기록한 단어 수
        var clock: Double
        var unigram: [String: Double]
        var bigram: [String: [String: Double]]
        var trigram: [String: [String: Double]]
    }

    /// 빈도를 저장하던 옛 형식. 1.6.3 파일, 1.6.0~1.6.2 `UserDefaults`, #159 이전 develop 파일이 이 구조다
    fileprivate struct LegacyNGramData: Codable {
        var unigram: [String: Int]
        var bigram: [String: [String: Int]]
        var trigram: [String: [String: Int]]
    }
    
    // MARK: - Properties

    /// 한영 통합 키보드가 쓰는 통합 NGram 식별자. 파일은 `ngram_ko-en.plist`다
    public static let hangeulEnglishLanguage = "ko-en"

    /// 식별자별 전체 키 최대 개수.
    ///
    /// 통합 NGram은 두 언어가 한 파일을 나눠 쓰므로, 한영 키보드가 언어별 엔진 2개로
    /// 쓰던 용량(5000 + 5000)과 메모리 최대치에 맞춘다
    static func maxKeys(forLanguage language: String) -> Int {
        language == hangeulEnglishLanguage ? 10000 : 5000
    }

    /// 기본 반감기(입력 단어 수). 이만큼 입력하면 점수가 절반이 된다.
    /// 같은 빈도로 습관을 바꾸면 새 표현이 이만큼 뒤에 예전 표현을 추월한다(#159 설계 문서의 시뮬레이션)
    static let defaultHalfLife: Double = 500
    /// 기본 잊는 기간(입력 단어 수). 한 번 쓴 항목이 이만큼 다시 쓰이지 않으면 저장소에 자리가 있어도 지운다
    static let defaultForgetAfter: Double = 10_000
    /// 로딩할 때 기준 시점을 되돌리는 클록 경계(반감기 배수). 기본 반감기면 약 15만 단어에 한 번이다
    private static let loadRebaseLimit: Double = 300
    /// 입력 중 값이 넘치지 않도록 기준 시점을 되돌리는 경계(반감기 배수). `Double`은 약 2^1023까지다
    private static let recordRebaseLimit: Double = 900

    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// 언어 식별자 (예: "ko", "en")
    private let language: String
    
    /// 디스크 로딩 완료 여부 (로딩 전에는 조회·기록을 건너뜀)
    private var isLoaded = false
    /// 디스크 로딩 완료 시 호출할 콜백
    var onLoadCompleted: (() -> Void)?
    /// 마이그레이션 파일 쓰기가 보류 중인지 여부
    private var needsLegacyCleanup = false
    /// reset과 비동기 load/save 결과를 구분하기 위한 세대 값
    private var storageGeneration = 0
    /// 백그라운드 load/save에서 storage generation을 확인하기 위한 lock
    private let storageGenerationLock = NSLock()
    /// 로딩 완료 전에 들어온 기록 이벤트
    private var pendingEvents: [PendingEvent] = []
    
    /// unigram 저장소: "단어" → 점수 값
    ///
    /// 변이 경로(디스크 로드 반영, reset, 기록, prune)가 모두 이 프로퍼티를 거치므로
    /// `didSet` 한 곳에서 순위 캐시를 무효화한다. 시간이 지나도 순서는 바뀌지 않으므로 기록할 때만 무효화하면 된다
    private var unigramStore: [String: Double] = [:] {
        didSet { rankedUnigramCache.removeAll() }
    }
    /// 선호 문자 종류별 `rankedUnigramCandidates(preferredScript:)` 결과 캐시.
    /// unigram이 바뀌지 않은 연속 스페이스 입력에서 계산을 건너뛴다
    private var rankedUnigramCache: [PredictiveTextScript?: [String]] = [:]
    /// bigram 저장소: "직전 단어" → ["다음 단어": 점수 값]
    private var bigramStore: [String: [String: Double]] = [:]
    /// trigram 저장소: "직전 2단어" → ["다음 단어": 점수 값]
    private var trigramStore: [String: [String: Double]] = [:]
    /// 기준 시점 이후 기록한 단어 수. 기록할 때만 늘어나므로 키보드를 쓰지 않는 동안에는 점수가 줄지 않는다
    private var clock: Double = 0
    /// 반감기(입력 단어 수)
    private let halfLife: Double
    /// 잊는 기간(입력 단어 수). 현재 점수가 `2^(-forgetAfter / halfLife)`보다 작으면 로딩 때 지운다
    private let forgetAfter: Double
    
    /// 현재 문장의 단어 버퍼
    private(set) var currentSentenceWords: [String] = []
    
    /// 예측 최대 반환 개수
    ///
    /// 후보 바가 가로로 스크롤되므로 화면 밖 후보까지 만든다. `SuggestionController.maxSuggestions`와 같은 값이다
    private let maxPredictions = 10
    
    /// n-gram 키 최대 항목 수 (이 수를 초과하면 점수 낮은 항목부터 정리)
    ///
    /// 실제로 노출하는 후보는 `maxPredictions`개뿐이고 나머지는 순위 변동을 위한 점수 기록이다.
    /// 키보드 확장은 메모리에 민감하므로 여유를 남기는 선에서 상한을 둔다
    private let maxEntriesPerKey = 24
    /// 전체 키 최대 개수
    private let maxKeys: Int
    
    /// 바이너리 plist 파일 경로
    private let fileURL: URL
    /// 컨테이너 루트에 있던 옛 파일 경로. 옮기지 못했을 때 읽기와 초기화에만 쓴다
    private let legacyFileURL: URL?
    /// 디스크에서 읽은 데이터를 메모리에 반영할 시점을 정한다. nil이면 main queue에 넘긴다.
    /// 테스트가 로딩·reset 순서를 고정할 때만 넘기며, 받은 클로저는 main에서 실행해야 한다
    private let loadApplyScheduler: ((@escaping () -> Void) -> Void)?

    /// 성능 계측용 signposter. 인스턴스마다 만들 필요가 없어 타입 프로퍼티로 공유한다
    private static let signposter = OSSignposter(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "NGramPredictiveTextEngine"
    )
    
    /// 백그라운드 저장용 직렬 큐
    private let saveQueue: DispatchQueue
    /// 마지막 저장 스냅샷 이후 학습으로 저장소가 바뀌었는지 여부. 변경이 없으면 저장을 건너뛴다
    private var hasUnsavedChanges = false

    /// 디스크 저장 디바운스용 카운터
    private var writeCounter: Int = 0
    /// 디스크 저장 주기 (n번 기록마다 1회 저장)
    private let writePeriod = 10
    
    /// 현재 문장 버퍼의 단어 수 (외부에서 미기록 단어 수 계산용)
    var currentSentenceWordsCount: Int {
        currentSentenceWords.count
    }
    
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
    
    /// App Group `UserDefaults` (마이그레이션 읽기/삭제 전용)
    private let legacyStorage: UserDefaults

    /// 로딩 전 들어온 기록 이벤트
    private enum PendingEvent {
        case addWord(String)
        case endSentence
    }
    
    // MARK: - Initializer
    
    /// 언어별 n-gram 엔진을 생성합니다.
    ///
    /// 디스크 로딩은 백그라운드에서 수행되며, 완료 전까지
    /// `suggestions`는 빈 배열, `addWord`/`endSentence`는 무시됩니다.
    ///
    /// 기존 `UserDefaults`에 데이터가 남아있으면 자동으로 파일로 마이그레이션합니다.
    ///
    /// - Parameter language: 언어 식별자 (예: "ko-KR", "en-US")
    public convenience init(language: String) {
        let initState = Self.signposter.beginInterval("NGramInit")
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else {
            fatalError("App Group 컨테이너 URL을 가져오는 데 실패했습니다.")
        }
        let fileURL = containerURL.appendingPathComponent("Library/Application Support/ngram_\(language).plist")
        let legacyFileURL = containerURL.appendingPathComponent("ngram_\(language).plist")
        guard let legacyStorage = UserDefaults(suiteName: DefaultValues.groupBundleID) else {
            fatalError("UserDefaults를 suiteName으로 불러오는 데 실패했습니다.")
        }
        Self.signposter.endInterval("NGramInit", initState)

        self.init(
            language: language,
            fileURL: fileURL,
            legacyFileURL: legacyFileURL,
            legacyStorage: legacyStorage,
            loadApplyScheduler: nil,
            maxKeys: Self.maxKeys(forLanguage: language)
        )
    }

    init(
        language: String,
        fileURL: URL,
        legacyFileURL: URL? = nil,
        legacyStorage: UserDefaults,
        loadApplyScheduler: ((@escaping () -> Void) -> Void)? = nil,
        maxKeys: Int = 5000,
        halfLife: Double = NGramPredictiveTextEngine.defaultHalfLife,
        forgetAfter: Double = NGramPredictiveTextEngine.defaultForgetAfter,
        saveQueue: DispatchQueue = DispatchQueue(label: "com.snmac.sykeyboard.ngram.save", qos: .utility)
    ) {
        self.language = language
        self.fileURL = fileURL
        self.legacyFileURL = legacyFileURL
        self.legacyStorage = legacyStorage
        self.loadApplyScheduler = loadApplyScheduler
        self.maxKeys = maxKeys
        self.halfLife = halfLife
        self.forgetAfter = forgetAfter
        self.saveQueue = saveQueue
        // 로딩·초기화와 경쟁하지 않도록 백그라운드 로딩 전에 옮긴다. 같은 볼륨 안 rename이라 비용이 작다
        if let legacyFileURL {
            Self.moveLegacyFileIfNeeded(from: legacyFileURL, to: fileURL)
        }
        startBackgroundLoad()
    }

    private func startBackgroundLoad() {
        let signposter = Self.signposter
        let generation = currentStorageGeneration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let loadState = signposter.beginInterval("NGramBackgroundLoad")
            
            var needsCleanup = false
            // 메모리와 파일이 달라(옛 형식 변환 등) 다음 저장 기회에 써야 하는지 여부
            var needsSave = false
            var loaded: NGramData

            if let fileResult = self.loadFromFile() {
                loaded = fileResult.data
                needsSave = fileResult.isConverted
            } else if let migrationResult = self.migrateFromUserDefaults() {
                loaded = migrationResult.data
                needsCleanup = migrationResult.needsCleanup
            } else {
                loaded = NGramData(clock: 0, unigram: [:], bigram: [:], trigram: [:])
            }
            // 기준 시점 되돌리기와 잊기는 백그라운드에서 끝내고 메인에는 결과만 넘긴다
            if self.prepareLoadedData(&loaded) {
                needsSave = true
            }
            
            let applyLoadedData = { [weak self] in
                // 로딩 반영까지만 측정하고, 완료 알림은 구간 밖에서 보낸다.
                // 중간에 빠져나가도 defer가 interval을 닫는다
                do {
                    defer { signposter.endInterval("NGramBackgroundLoad", loadState) }

                    guard let self else { return }
                    guard self.currentStorageGeneration() == generation else { return }

                    self.unigramStore = loaded.unigram
                    self.bigramStore = loaded.bigram
                    self.trigramStore = loaded.trigram
                    self.clock = loaded.clock
                    self.needsLegacyCleanup = needsCleanup
                    // 변환한 데이터는 다음 저장 기회에 새 형식으로 쓴다. 이후 flushPendingEvents가 기록하면 다시 true가 된다
                    self.hasUnsavedChanges = needsSave
                    self.isLoaded = true
                    self.flushPendingEvents()
                    self.logger.debug("[NGram/\(self.language)] 디스크 로딩 완료")
                }

                self?.onLoadCompleted?()
            }

            if let loadApplyScheduler = self.loadApplyScheduler {
                loadApplyScheduler(applyLoadedData)
            } else {
                DispatchQueue.main.async(execute: applyLoadedData)
            }
        }
    }
    
    // MARK: - PredictiveTextProvider
    
    /// 커서 앞 문맥을 기반으로 다음 단어를 예측합니다.
    ///
    /// trigram(직전 2단어) → bigram(직전 1단어) → unigram(점수순) 순으로
    /// 조회하며, 각 단계에서 부족한 슬롯을 다음 단계로 보충합니다.
    /// 문맥이 비어있으면 unigram만 사용합니다.
    ///
    /// 디스크 로딩이 완료되지 않은 경우 빈 배열을 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트 (`inputBuffer`)
    /// - Returns: 점수순으로 정렬된 다음 단어 후보 배열 (최대 `maxPredictions`개)
    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, preferredScript: nil)
    }

    /// `preferredScript`가 있으면 unigram 후보(문맥 없음, 남은 칸 보충)만 그 문자 종류를 앞에 둡니다.
    /// trigram·bigram 후보는 문자 종류와 무관하게 점수순입니다.
    ///
    /// - Parameters:
    ///   - baseText: 자동완성을 제공할 텍스트 (`inputBuffer`)
    ///   - preferredScript: unigram 후보에서 먼저 보여줄 문자 종류. `nil`이면 점수순만 따른다
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] {
        guard isLoaded else { return [] }

        let words = baseText
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        // 문맥이 없으면 unigram (자주 사용한 단어)
        if words.isEmpty {
            return rankedUnigramCandidates(preferredScript: preferredScript)
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
            for word in rankedUnigramCandidates(preferredScript: preferredScript) {
                guard !seen.contains(word.lowercased()) else { continue }
                seen.insert(word.lowercased())
                results.append(word)
                if results.count >= maxPredictions { break }
            }
        }
        
        return results
    }
    
    /// 입력 중인 단어를 이어 쓴 학습 단어를 반환합니다.
    ///
    /// `previousWord` 뒤에 쓴 bigram 후보 중 맞는 것을 점수순으로 먼저, 남은 칸은 unigram 점수순으로 채웁니다.
    /// unigram은 대소문자만 다른 표기를 한 단어로 묶어 합친 점수로 순위를 매기고 대표 표기 하나만 돌려줍니다.
    /// 비교·표기 규칙은 `PredictiveTextCompletionMatchPolicy`를 따르고, 입력 중인 단어 자체는 뺍니다.
    /// 디스크 로딩이 완료되지 않은 경우 빈 배열을 반환합니다.
    ///
    /// - Parameters:
    ///   - typedWord: 입력 중인 단어 (`inputBuffer`의 마지막 단어)
    ///   - previousWord: 바로 앞 단어. 없으면 `nil`
    ///   - limit: 최대 반환 개수 (`maxPredictions` 이하)
    /// - Returns: 완성 후보 배열
    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String] {
        guard isLoaded, limit > 0,
              let policy = PredictiveTextCompletionMatchPolicy(typedWord: typedWord) else { return [] }

        let state = Self.signposter.beginInterval("NGramCompletions")
        defer { Self.signposter.endInterval("NGramCompletions", state) }

        var seen: Set<String> = [typedWord.lowercased()]
        var results: [String] = []

        if let previousWord {
            for word in rankedCandidates(from: bigramStore, key: previousWord) where policy.isCompletion(word) {
                guard seen.insert(word.lowercased()).inserted else { continue }
                results.append(policy.displayText(for: word))
                if results.count >= limit { return results }
            }
        }

        // ponytail: 키 입력마다 unigram 전체(최대 10000개)를 훑는다. 대부분은 판정 정책의 첫 스칼라 거르기에서 바로 빠지고,
        // 남은 비용은 실제로 맞는 단어 몫이라 첫 자모 색인으로는 줄지 않는다
        var spellingGroups: [String: CaseSpellingGroup] = [:]
        var top: [(key: String, value: Double)] = []
        for entry in unigramStore where policy.isCompletion(entry.key) {
            // 대소문자가 없는 단어는 묶일 다른 표기가 없어 바로 순위에 넣는다
            if PredictiveTextCompletionMatchPolicy.hasNoCaseVariants(entry.key) {
                guard results.isEmpty || !seen.contains(entry.key) else { continue }
                insertTopUnigram(entry, into: &top)
                continue
            }
            let lowered = entry.key.lowercased()
            // bigram 후보가 없으면 seen에는 입력 단어뿐이고, 입력 단어는 판정 정책이 이미 뺀다
            guard results.isEmpty || !seen.contains(lowered) else { continue }
            spellingGroups[lowered, default: CaseSpellingGroup(lowered: lowered)].add(entry.key, score: entry.value)
        }
        for group in spellingGroups.values {
            insertTopUnigram(group.representative, into: &top)
        }
        return results + top.prefix(limit - results.count).map { policy.displayText(for: $0.key) }
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
        guard !word.isEmpty else { return }
        guard isLoaded else {
            pendingEvents.append(.addWord(word))
            return
        }
        currentSentenceWords.append(word)
        // 직전 saveToDisk의 스냅샷이 살아있으면 이 기록에서 CoW 복사가 발생하므로 구간으로 관측한다
        let recordState = Self.signposter.beginInterval("NGramRecord")
        recordNGrams()
        Self.signposter.endInterval("NGramRecord", recordState)
        scheduleSave()
    }
    
    /// 문장 버퍼를 초기화하고 디스크에 저장합니다.
    ///
    /// 리턴 키 입력 시 호출합니다.
    /// 디스크 로딩이 완료되지 않은 경우 무시됩니다.
    func endSentence() {
        guard isLoaded else {
            pendingEvents.append(.endSentence)
            return
        }
        currentSentenceWords.removeAll()
        saveToDisk()
    }
    
    /// 마지막으로 기록된 단어를 문장 버퍼에서 제거합니다.
    ///
    /// 사용자가 삭제로 커밋된 단어 경계(스페이스)를 허물었을 때 호출하여
    /// `currentSentenceWords`와 실제 입력 상태를 동기화합니다.
    func removeLastWord() {
        guard !currentSentenceWords.isEmpty else { return }
        currentSentenceWords.removeLast()
        logger.debug("[NGram/\(self.language)] 문장 버퍼 마지막 기록 단어 제거")
    }
    
    /// 문장 버퍼를 초기화합니다.
    ///
    /// 커서 이동, 키보드 열림/닫힘 등 `inputBuffer`가 초기화되는 시점에
    /// 함께 호출하여 n-gram 문맥을 리셋합니다.
    func resetSentenceBuffer() {
        currentSentenceWords.removeAll()
    }

    /// 문장 버퍼를 주어진 단어들로 바꿉니다.
    ///
    /// 입력창이 비워지기 직전의 문장 버퍼를 되돌려, 보낸 마지막 단어를 앞 단어와 이어 기록할 때 호출합니다.
    /// 기록·저장은 하지 않습니다.
    func restoreSentenceBuffer(_ words: [String]) {
        currentSentenceWords = words
    }

    /// 단어를 모든 n-gram 저장소에서 지우고 바로 저장합니다.
    ///
    /// 자동완성 후보를 길게 눌러 삭제할 때 호출합니다. 다시 입력하면 다시 기록됩니다.
    /// `suggestions(for:)`가 소문자 기준으로 중복을 제거하므로 대소문자를 구분하지 않고 지웁니다.
    /// 문장 버퍼는 `inputBuffer`와 단어 수를 맞추는 데 쓰이므로 건드리지 않습니다.
    /// 디스크 로딩이 완료되지 않은 경우 무시됩니다.
    ///
    /// - Parameter word: 지울 단어
    func removeWord(_ word: String) {
        guard isLoaded, !word.isEmpty else { return }

        let target = word.lowercased()
        let matches: (String) -> Bool = { $0.lowercased() == target }
        let droppingWord: ([String: Double]) -> [String: Double]? = { entries in
            let kept = entries.filter { !matches($0.key) }
            return kept.isEmpty ? nil : kept
        }

        unigramStore = unigramStore.filter { !matches($0.key) }
        bigramStore = bigramStore
            .filter { !matches($0.key) }
            .compactMapValues(droppingWord)
        trigramStore = trigramStore
            .filter { entry in
                !entry.key.split(separator: " ").contains { matches(String($0)) }
            }
            .compactMapValues(droppingWord)

        hasUnsavedChanges = true
        saveToDisk()
        logger.debug("[NGram/\(self.language)] 단어 삭제: \"\(word)\"")
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
        // 보류된 레거시 정리는 이 경로에서만 수행되므로 dirty가 아니어도 통과시킨다
        guard isLoaded, hasUnsavedChanges || needsLegacyCleanup else { return }

        let generation = currentStorageGeneration()
        let snapshotState = Self.signposter.beginInterval("NGramSaveSnapshot")
        let snapshot = NGramData(
            clock: clock,
            unigram: unigramStore,
            bigram: bigramStore,
            trigram: trigramStore
        )
        Self.signposter.endInterval("NGramSaveSnapshot", snapshotState)
        hasUnsavedChanges = false
        let url = fileURL
        let shouldCleanupLegacy = needsLegacyCleanup

        saveQueue.async { [weak self] in
            guard let self else { return }
            guard self.currentStorageGeneration() == generation else { return }

            // 실패로 빠져나가도 defer가 interval을 닫는다
            let encodeState = Self.signposter.beginInterval("NGramSaveEncode")
            defer { Self.signposter.endInterval("NGramSaveEncode", encodeState) }

            do {
                try Self.write(snapshot, to: url)

                if shouldCleanupLegacy {
                    self.legacyStorage.removeObject(forKey: self.legacyUnigramKey)
                    self.legacyStorage.removeObject(forKey: self.legacyBigramKey)
                    self.legacyStorage.removeObject(forKey: self.legacyTrigramKey)
                    DispatchQueue.main.async {
                        self.needsLegacyCleanup = false
                    }
                    self.logger.debug("[NGram/\(self.language)] 보류된 레거시 데이터 정리 완료")
                }
            } catch {
                self.logger.error("[NGram] 디스크 저장 실패: \(error.localizedDescription)")
                // 다음 저장 기회에 재시도할 수 있도록 되돌린다. reset 이후라면 버려진 데이터이므로 되돌리지 않는다
                DispatchQueue.main.async {
                    guard self.currentStorageGeneration() == generation else { return }
                    self.hasUnsavedChanges = true
                }
            }
        }
    }
    
    /// 모든 학습 데이터를 초기화합니다.
    public func resetAllData() {
        advanceStorageGeneration()
        isLoaded = true
        unigramStore = [:]
        bigramStore = [:]
        trigramStore = [:]
        clock = 0
        currentSentenceWords = []
        pendingEvents = []
        writeCounter = 0
        // 파일을 지우고 저장소도 비우므로 메모리와 디스크가 일치한다
        hasUnsavedChanges = false

        // 파일 삭제. 옮기지 못한 옛 파일이 남으면 다음 실행에서 되살아나므로 함께 지운다
        try? FileManager.default.removeItem(at: fileURL)
        if let legacyFileURL {
            try? FileManager.default.removeItem(at: legacyFileURL)
        }

        // 레거시 UserDefaults도 정리 (마이그레이션 전 사용자 대비)
        legacyStorage.removeObject(forKey: legacyUnigramKey)
        legacyStorage.removeObject(forKey: legacyBigramKey)
        legacyStorage.removeObject(forKey: legacyTrigramKey)
        
        logger.debug("[NGram/\(self.language)] 학습 데이터 초기화")
    }
}

// MARK: - Private Methods

private extension NGramPredictiveTextEngine {

    func currentStorageGeneration() -> Int {
        storageGenerationLock.lock()
        defer { storageGenerationLock.unlock() }
        return storageGeneration
    }

    func advanceStorageGeneration() {
        storageGenerationLock.lock()
        storageGeneration += 1
        storageGenerationLock.unlock()
    }
    
    // MARK: Decay

    /// 로딩한 데이터의 기준 시점을 필요하면 되돌리고, 잊는 기간 동안 다시 쓰이지 않은 항목을 지웁니다.
    ///
    /// ponytail: 잊기는 로딩 때만 한다. 엔진은 키보드 VC가 만들 때마다 새로 로딩하므로(VC가 deinit되면 함께 사라진다)
    /// 같은 VC가 계속 쓰이는 동안 기준 아래로 내려간 항목은 다음 VC 생성까지 남는다.
    /// 그 항목은 점수가 가장 낮아 상한 정리에서 먼저 지워지고 후보에는 맞는 다른 단어가 없을 때만 보인다.
    /// 키보드 VC가 deinit되지 않고 오래 재사용되는 것이 확인되면 저장 주기에 맞춰 메모리에서도 지운다
    ///
    /// - Returns: 데이터가 바뀌어 다음 저장 기회에 써야 하는지 여부
    func prepareLoadedData(_ data: inout NGramData) -> Bool {
        var changed = false
        if data.clock / halfLife > Self.loadRebaseLimit {
            Self.rebase(&data.unigram, &data.bigram, &data.trigram, clock: &data.clock, halfLife: halfLife)
            changed = true
        }

        // 현재 점수 = 값 × 2^(-clock / halfLife) 가 2^(-forgetAfter / halfLife) 보다 작으면 지운다
        let floor = exp2((data.clock - forgetAfter) / halfLife)
        let unigramCount = data.unigram.count
        data.unigram = data.unigram.filter { $0.value >= floor }
        changed = changed || data.unigram.count != unigramCount

        var removedContextEntry = false
        data.bigram = Self.removingForgotten(data.bigram, below: floor, removed: &removedContextEntry)
        data.trigram = Self.removingForgotten(data.trigram, below: floor, removed: &removedContextEntry)
        return changed || removedContextEntry
    }

    /// 모든 값을 현재 점수로 환산하고 클록을 0으로 되돌립니다. 항목 사이 순서와 비율은 그대로입니다
    static func rebase(
        _ unigram: inout [String: Double],
        _ bigram: inout [String: [String: Double]],
        _ trigram: inout [String: [String: Double]],
        clock: inout Double,
        halfLife: Double
    ) {
        let factor = exp2(-clock / halfLife)
        unigram = unigram.mapValues { $0 * factor }
        bigram = bigram.mapValues { $0.mapValues { $0 * factor } }
        trigram = trigram.mapValues { $0.mapValues { $0 * factor } }
        clock = 0
    }

    /// 문맥 저장소에서 `floor`보다 작은 항목을 지우고, 비게 된 문맥 키도 지웁니다.
    /// 지울 항목이 없는 문맥은 새로 만들지 않고 그대로 둡니다
    static func removingForgotten(
        _ store: [String: [String: Double]],
        below floor: Double,
        removed: inout Bool
    ) -> [String: [String: Double]] {
        store.compactMapValues { entries in
            guard entries.values.contains(where: { $0 < floor }) else { return entries }
            removed = true
            let kept = entries.filter { $0.value >= floor }
            return kept.isEmpty ? nil : kept
        }
    }

    // MARK: File I/O
    
    /// 바이너리 plist 파일에서 n-gram 데이터를 로드합니다.
    ///
    /// 새 위치를 먼저 읽고, 없으면 옮기지 못한 옛 위치를 읽습니다.
    /// 새 형식으로 읽지 못하면 옛 빈도 형식으로 읽어 점수로 변환합니다.
    ///
    /// - Returns: 로드된 데이터와 옛 형식에서 변환했는지 여부, 파일이 없거나 파싱 실패 시 `nil`
    func loadFromFile() -> (data: NGramData, isConverted: Bool)? {
        for url in [fileURL, legacyFileURL].compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: url) else { continue }
            let decoder = PropertyListDecoder()
            if let current = try? decoder.decode(NGramData.self, from: data) {
                return (current, false)
            }
            guard let legacy = try? decoder.decode(LegacyNGramData.self, from: data) else { return nil }
            return (converted(legacy), true)
        }
        return nil
    }

    /// 옛 빈도를, 그 비율대로 지금 반감기로 계속 써 왔다면 가졌을 점수로 옮깁니다.
    ///
    /// 일정한 비율 r로 오래 쓴 항목의 점수는 `r × halfLife / ln2`에서 안정되므로 빈도에
    /// `halfLife / (ln2 × 전체 기록 단어 수)`를 곱합니다. 항목 사이 순서는 그대로입니다.
    /// 기록한 단어가 적으면(배율이 1을 넘으면) 빈도를 그대로 점수로 씁니다.
    func converted(_ legacy: LegacyNGramData) -> NGramData {
        let total = legacy.unigram.values.reduce(0, +)
        let scale = total > 0 ? min(1, halfLife / (M_LN2 * Double(total))) : 1
        let scaled: ([String: Int]) -> [String: Double] = { $0.mapValues { Double($0) * scale } }
        return NGramData(
            clock: 0,
            unigram: scaled(legacy.unigram),
            bigram: legacy.bigram.mapValues(scaled),
            trigram: legacy.trigram.mapValues(scaled)
        )
    }

    /// 새 위치에 파일이 없고 옛 위치에 있을 때만 옮긴다.
    /// 다른 프로세스가 먼저 옮겼거나 옮기지 못해도 로딩이 새 위치 → 옛 위치 순으로 읽으므로 실패는 기록만 한다
    static func moveLegacyFileIfNeeded(from legacyURL: URL, to fileURL: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: fileURL.path),
              fileManager.fileExists(atPath: legacyURL.path) else { return }
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.moveItem(at: legacyURL, to: fileURL)
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "NGramPredictiveTextEngine")
                .error("[NGram] 옛 위치 파일 이동 실패: \(error.localizedDescription)")
        }
    }

    /// App Group 컨테이너에는 `Library/Application Support`가 기본으로 없어 쓰기 전에 만든다
    static func write(_ ngramData: NGramData, to url: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(ngramData)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    // MARK: Migration
    
    /// 기존 `UserDefaults`에서 n-gram 데이터를 읽어 파일로 마이그레이션합니다.
    ///
    /// `UserDefaults`에 데이터가 없으면 `nil`을 반환합니다.
    /// 마이그레이션 성공 시 `UserDefaults`에서 기존 키를 제거합니다.
    ///
    /// - Returns: 마이그레이션된 데이터와 레거시 정리 보류 여부, 기존 데이터가 없으면 `nil`
    func migrateFromUserDefaults() -> (data: NGramData, needsCleanup: Bool)? {
        let unigram = legacyStorage.dictionary(forKey: legacyUnigramKey) as? [String: Int]
        let bigram = legacyStorage.dictionary(forKey: legacyBigramKey) as? [String: [String: Int]]
        let trigram = legacyStorage.dictionary(forKey: legacyTrigramKey) as? [String: [String: Int]]
        
        guard unigram != nil || bigram != nil || trigram != nil else { return nil }
        
        let migrated = converted(LegacyNGramData(
            unigram: unigram ?? [:],
            bigram: bigram ?? [:],
            trigram: trigram ?? [:]
        ))
        
        do {
            try Self.write(migrated, to: fileURL)
        } catch {
            logger.error("[NGram/\(self.language)] 마이그레이션 저장 실패: \(error.localizedDescription)")
            return (migrated, true)  // 데이터는 올리되, cleanup 보류
        }
        
        legacyStorage.removeObject(forKey: legacyUnigramKey)
        legacyStorage.removeObject(forKey: legacyBigramKey)
        legacyStorage.removeObject(forKey: legacyTrigramKey)
        
        logger.debug("[NGram/\(self.language)] UserDefaults → 파일 마이그레이션 완료")
        
        return (migrated, false)
    }
    
    // MARK: N-Gram Recording

    /// 로딩 전에 들어온 기록 이벤트를 로딩된 저장소 위에 순서대로 반영합니다.
    func flushPendingEvents() {
        let events = pendingEvents
        pendingEvents = []

        for event in events {
            switch event {
            case .addWord(let word):
                addWord(word)
            case .endSentence:
                endSentence()
            }
        }
    }
    
    /// 현재 버퍼의 마지막 단어들로 n-gram을 기록합니다.
    func recordNGrams() {
        let words = currentSentenceWords
        let count = words.count
        clock += 1
        if clock / halfLife > Self.recordRebaseLimit {
            Self.rebase(&unigramStore, &bigramStore, &trigramStore, clock: &clock, halfLife: halfLife)
        }
        // 사용 시점을 기준 시점으로 환산한 가중치. 모든 항목이 같은 비율로 줄어드는 셈이라 순서가 시간으로 바뀌지 않는다
        let weight = exp2(clock / halfLife)

        // unigram: 현재 단어
        let currentWord = words[count - 1]
        unigramStore[currentWord, default: 0] += weight
        pruneUnigram()
        logger.debug("[NGram/\(self.language)] unigram: \"\(currentWord)\" (value: \(self.unigramStore[currentWord] ?? 0))")
        
        // bigram: 직전 단어 → 현재 단어
        if count >= 2 {
            let key = words[count - 2]
            let value = words[count - 1]
            bigramStore[key, default: [:]][value, default: 0] += weight
            pruneEntries(in: &bigramStore, forKey: key)
            logger.debug("[NGram/\(self.language)] bigram: \"\(key)\" → \"\(value)\" (value: \(self.bigramStore[key]?[value] ?? 0))")
        }
        
        // trigram: 직전 2단어 → 현재 단어
        if count >= 3 {
            let key = "\(words[count - 3]) \(words[count - 2])"
            let value = words[count - 1]
            trigramStore[key, default: [:]][value, default: 0] += weight
            pruneEntries(in: &trigramStore, forKey: key)
            logger.debug("[NGram/\(self.language)] trigram: \"\(key)\" → \"\(value)\" (value: \(self.trigramStore[key]?[value] ?? 0))")
        }
        
        pruneKeys(in: &bigramStore)
        pruneKeys(in: &trigramStore)
        hasUnsavedChanges = true
    }
    
    // MARK: Ranking
    
    /// 점수순으로 정렬된 unigram 후보를 반환합니다.
    ///
    /// 문맥이 없거나 trigram/bigram 결과가 부족할 때 사용됩니다.
    /// `preferredScript`가 있으면 그 문자 종류 상위 후보를 먼저, 나머지 상위 후보를 뒤에 둡니다.
    ///
    /// - Parameter preferredScript: 먼저 보여줄 문자 종류. `nil`이면 점수순만 따른다
    /// - Returns: 단어 배열 (최대 `maxPredictions`개)
    func rankedUnigramCandidates(preferredScript: PredictiveTextScript? = nil) -> [String] {
        if let cached = rankedUnigramCache[preferredScript] { return cached }

        let state = Self.signposter.beginInterval("RankedUnigramCandidates")
        defer { Self.signposter.endInterval("RankedUnigramCandidates", state) }

        // 전체 정렬 대신 묶음마다 상위 maxPredictions개만 유지한다. 동률 순서는 정렬 시절과 마찬가지로 정의하지 않는다
        var preferred: [(key: String, value: Double)] = []
        var others: [(key: String, value: Double)] = []
        for entry in unigramStore {
            if let preferredScript, PredictiveTextScriptPolicy.script(of: entry.key) == preferredScript {
                insertTopUnigram(entry, into: &preferred)
            } else {
                insertTopUnigram(entry, into: &others)
            }
        }

        let ranked = Array((preferred + others).prefix(maxPredictions).map(\.key))
        rankedUnigramCache[preferredScript] = ranked
        return ranked
    }

    /// 점수 내림차순을 유지하며 상위 `maxPredictions`개 안에 들면 넣는다
    func insertTopUnigram(_ entry: (key: String, value: Double), into top: inout [(key: String, value: Double)]) {
        guard top.count < maxPredictions || entry.value > top[top.count - 1].value else { return }
        let insertIndex = top.firstIndex { entry.value > $0.value } ?? top.count
        top.insert(entry, at: insertIndex)
        if top.count > maxPredictions {
            top.removeLast()
        }
    }
    
    /// 점수순으로 정렬된 후보를 반환합니다.
    ///
    /// - Parameters:
    ///   - store: n-gram 저장소
    ///   - key: 문맥 키
    /// - Returns: 점수순으로 정렬된 단어 배열
    func rankedCandidates(from store: [String: [String: Double]], key: String) -> [String] {
        guard let scores = store[key] else { return [] }
        return scores
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    // MARK: Pruning
    
    /// unigram 항목 수가 제한을 초과하면 점수 낮은 항목을 제거합니다.
    ///
    /// `maxKeys`를 초과할 때 점수가 낮은 순서대로 제거합니다. 같은 횟수면 먼저 쓴 항목이 점수가 낮다.
    func pruneUnigram() {
        let removeCount = unigramStore.count - maxKeys
        guard removeCount > 0 else { return }

        // 정상 경로는 기록마다 최대 1개 초과라 최소 점수 1개만 찾는다. 2개 이상 초과(상한을 넘긴
        // 마이그레이션 데이터 등)는 드물어 기존 정렬 방식을 유지한다
        if removeCount == 1 {
            if let lowest = unigramStore.min(by: { $0.value < $1.value }) {
                unigramStore.removeValue(forKey: lowest.key)
            }
            return
        }

        let sorted = unigramStore.sorted { $0.value < $1.value }
        for i in 0..<removeCount {
            unigramStore.removeValue(forKey: sorted[i].key)
        }
    }
    
    /// 특정 키의 항목 수가 제한을 초과하면 점수 낮은 항목을 제거합니다.
    ///
    /// - Parameters:
    ///   - store: n-gram 저장소
    ///   - key: 정리할 키
    func pruneEntries(in store: inout [String: [String: Double]], forKey key: String) {
        guard let entries = store[key], entries.count > maxEntriesPerKey else { return }
        
        let sorted = entries.sorted { $0.value > $1.value }
        let topEntries = Array(sorted.prefix(maxEntriesPerKey))
        let pruned = Dictionary(uniqueKeysWithValues: topEntries)
        store[key] = pruned
    }
    
    /// 전체 키 수가 제한을 초과하면 총점이 낮은 키를 제거합니다.
    ///
    /// - Parameter store: n-gram 저장소
    func pruneKeys(in store: inout [String: [String: Double]]) {
        let removeCount = store.count - maxKeys
        guard removeCount > 0 else { return }

        // pruneUnigram과 같이 정상 경로는 기록마다 최대 1개 초과라 총점이 가장 낮은 키 1개만 찾는다.
        // 가득 찬 저장소에서는 trigram 새 문맥이 거의 매 스페이스마다 생겨 전체 정렬이 입력 지연이 된다
        if removeCount == 1 {
            var lowestKey: String?
            var lowestTotal = Double.infinity
            for (key, entries) in store {
                let total = entries.values.reduce(0, +)
                if total < lowestTotal {
                    lowestTotal = total
                    lowestKey = key
                }
            }
            if let lowestKey {
                store.removeValue(forKey: lowestKey)
            }
            return
        }

        // 각 키의 총점을 계산하여 낮은 순으로 제거
        let keysWithTotalFreq = store.map { (key: $0.key, total: $0.value.values.reduce(0, +)) }
        let sorted = keysWithTotalFreq.sorted { $0.total < $1.total }

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

// MARK: - CaseSpellingGroup

/// 대소문자만 다른 표기 묶음에서 보여줄 표기와 합친 점수를 고른다.
///
/// 소문자 표기가 있으면 첫 글자만 대문자인 표기(문장 첫머리에서 학습된 `"Hello"`)를 그 점수에 더한다.
/// 문장 첫머리 대문자는 `PredictiveTextCompletionMatchPolicy.displayText(for:)`가 입력에 맞춰 다시 붙인다.
/// 나머지는 점수가 높은(자주·최근에 쓴) 표기를 고른다(`"SY키보드"`를 `"sy키보드"`보다 많이 썼으면 `"SY키보드"`). 소문자 표기가 없는 `"Seoul"`은 그대로다.
/// 키 입력마다 맞는 단어 수만큼 만들고 대부분은 표기가 하나라, 표기가 둘 이상일 때만 표기별 사전을 만든다
private struct CaseSpellingGroup {
    private let lowered: String
    private var first: (key: String, value: Double)?
    private var others: [(key: String, value: Double)] = []

    init(lowered: String) {
        self.lowered = lowered
    }

    mutating func add(_ spelling: String, score: Double) {
        if first == nil {
            first = (spelling, score)
        } else {
            others.append((spelling, score))
        }
    }

    /// 대표 표기와 묶음 전체 점수
    var representative: (key: String, value: Double) {
        guard let first else { return (key: lowered, value: 0) }
        // 표기가 하나면 규칙과 관계없이 그 표기가 대표다
        guard !others.isEmpty else { return first }

        var spellings = Dictionary([first] + others, uniquingKeysWith: { _, latest in latest })
        if spellings[lowered] != nil, let firstCharacter = lowered.first {
            let sentenceStartSpelling = firstCharacter.uppercased() + lowered.dropFirst()
            if sentenceStartSpelling != lowered, let score = spellings.removeValue(forKey: sentenceStartSpelling) {
                spellings[lowered, default: 0] += score
            }
        }
        // 동률이면 코드 포인트 순으로 앞선 표기를 골라 결과가 매번 같게 한다
        let representative = spellings.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key ?? lowered
        return (key: representative, value: spellings.values.reduce(0, +))
    }
}
