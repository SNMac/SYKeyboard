# NGram 지수 감쇠 점수 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NGram 학습의 기록·정리·추천을 빈도 대신 입력 단어 수 기준 지수 감쇠 점수(반감기 500단어)로 바꾸고, 10,000단어 동안 다시 쓰지 않은 항목은 저장소에 자리가 있어도 지운다.

**Architecture:** `NGramPredictiveTextEngine` 하나만 바뀐다. 메모리 값은 기준 시점으로 환산한 선형 점수(`Σ 2^(사용 시점 / H)`)와 클록이고, 파일은 `version: 2` + `clock` + `Double` 값이다. 옛 `Int` 빈도 데이터(파일·`UserDefaults`)는 로딩 때 한 변환 함수로 옮기고, 기준 시점 되돌리기와 잊기는 백그라운드 로딩 중에만 한다. `SuggestionController`·VC·프로토콜은 바뀌지 않는다.

**Tech Stack:** Swift 5, Foundation(`PropertyListEncoder`/`Decoder` binary, `exp2`, `M_LN2`), Swift Testing, Xcode 26 이상

**Spec:** `docs/superpowers/specs/2026-09-27-ngram-decay-score-design.md`

## Global Constraints

- 작업 브랜치는 `feat/#159-ngram-decay-score`다(`develop` `5806926a` 위, spec 커밋 `160581bd`).
- 커밋 메시지는 `type: #159 - subject` 형식, 한국어, 마침표 없음. 끝에 아래 줄을 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.

  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  ```

- CLAUDE.md 「Superpowers 계획 실행」을 따른다. step은 작업과 검증이 모두 끝난 직후에만 체크한다. **Task마다 마지막 커밋 step에서** 그 Task의 코드·테스트와 이 문서(체크박스, 실제 결과: 테스트 개수, 빌드 결과, 확인하지 못한 항목, 로그 경로)를 한 커밋으로 남긴다. 다음 Task는 직전 Task 커밋 뒤에 시작한다.
- 수치는 spec 그대로다: 반감기 `H = 500`단어, 잊는 기간 `F = 10,000`단어, 로딩 때 되돌리기 경계 `clock / H > 300`, 입력 중 넘침 방어 경계 `clock / H > 900`, 저장 형식 `version` 2, 옛 데이터 배율 `min(1, H / (ln2 × N))`(`N` = unigram 빈도 합, 0이면 1). `maxKeys`(5000/10000)·`maxEntriesPerKey`(24)·`writePeriod`(10)는 바꾸지 않는다.
- 파일 이름·위치(`Library/Application Support/ngram_{식별자}.plist`), 컨테이너 루트 옛 파일 이동, `UserDefaults` 레거시 키 이름·정리 흐름은 그대로 둔다.
- `SuggestionController`, `NGramPredictiveTextProviding`, `BaseKeyboardViewController`, 설정 화면은 고치지 않는다. 공개 API(`suggestions`, `completions`, `addWord`, `endSentence`, `removeWord`, `resetAllData`, `saveToDisk`)의 시그니처는 그대로다.
- 이번 변경은 `Modules/`에 새 파일을 만들지 않는다(엔진 파일 안에서 끝낸다). `SYKeyboardTests/`의 새 테스트 파일은 pbxproj를 고치지 않는다.
- 테스트 기준 기기는 `iPhone 13 mini / iOS 18.6`이다. 테스트 명령에는 아래 두 옵션을 붙인다. 빼면 테스트 호스트가 AdMob 초기화에서 크래시한다.

  ```sh
  xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    -parallel-testing-enabled NO \
    GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
    -only-testing:SYKeyboardTests/<SuiteType>
  ```

  `<SuiteType>`은 `@Suite` 표시 이름이 아니라 **타입 이름**이다. 로그는 scratchpad의 `sdd-logs/`에 파일로 남기고 `tail`/`grep`으로 결과만 본다. scratchpad는 `/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/a17970c2-b783-47ce-8ae4-26568a0f7dba/scratchpad`다(아래 `$SCRATCH`).
- `xcodebuild`는 수 분 걸린다. 실행 전에 사용자에게 오래 걸린다고 알린다. 서브에이전트에 맡길 때는 foreground로 `timeout: 600000`을 주고, 몇 분씩 진행이 없으면 기다리지 말고 보고하게 한다(CLAUDE.md 「호스트 앱이 뜨지도 않고 테스트가 매달리는 경우」, 「붙여넣기 권한 알림으로 테스트가 끝나지 않는 경우」). 이 두 경우는 코드 실패로 기록하지 않는다.
- extension scheme을 빌드할 때는 `-only-testing`과 code coverage 옵션을 비운다. 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌리고 커밋하지 않는다. 다른 항목이 바뀌었으면 되돌리지 말고 사용자에게 알린다.
- `SYKeyboard/Resources/Configs/Secrets.xcconfig`, Firebase, AdMob, entitlements, bundle 설정은 건드리지 않는다.
- `git add`는 항상 파일을 명시한다. push·PR 생성·이슈 수정은 사용자가 명시할 때만 한다.
- 테스트는 Swift Testing이고 production 진입점(`NGramPredictiveTextEngine`)을 호출한다. production 클래스에 `ForTesting` 메서드를 넣지 않는다. 테스트용 주입은 기존 internal init 인자(`maxKeys`처럼)로만 한다.
- 측정 코드(`ZZNGramDecayPerfTests.swift`)는 **커밋하지 않는다.** 측정이 끝나면 지운다.

### spec과 다르게 가는 곳

1. **잊기의 메모리 처리.** spec 「로딩 순서」 3단계는 "디코딩한 사전에서 바로 지운다"고 썼다. 구현은 `filter`/`compactMapValues`로 새 사전을 만들되, 지울 항목이 없는 문맥은 원래 사전을 그대로 돌려줘 새로 만들지 않는다. 백그라운드 로딩 중이라 메인 스레드 비용이 없다는 spec의 요점은 같고, 로딩 peak 메모리는 Task 4 측정으로 확인한다.

## Review Focus

- 파일이 새 형식도 옛 형식도 아니게 깨져 있으면 지금처럼 빈 학습으로 시작하고 멈추지 않아야 한다 → Task 2 `test깨진파일은_빈학습으로시작`.
- 옛 파일의 unigram이 비어 있고 bigram만 있으면(`N = 0`) 0으로 나누지 않고 배율 1로 옮겨야 한다 → Task 2 `test옛형식unigram이비어있으면_배율1로옮김`.
- 로딩이 끝나기 전에 친 단어(`pendingEvents`)도 클록을 올려야 한다. 안 올리면 그 단어가 가장 오래된 것으로 취급된다 → Task 2 `test로딩전에친단어도_클록을올림`.
- 1.6.3 사용자는 문맥 키당 50개까지 저장했다. 변환 뒤 그 문맥에 다시 기록하면 24개로 줄고, 가장 낮은 점수부터 지워져야 한다. 기록이 많은 사용자(배율 < 1)는 옛 점수가 작아져 방금 쓴 단어가 남고 오래된 항목이 지워지며, 기록이 적은 사용자(배율 1)는 방금 쓴 단어도 지워질 수 있다(develop과 같은 규칙) → Task 2 `test문맥당24개를넘는옛데이터는_다시기록할때_낮은점수부터24개로줄임`, `test기록이많은사용자의문맥당24개를넘는옛데이터는_새단어를남기고_오래된항목부터지움`.
- 잊기로 문맥 안 일부 항목만 지워지면 문맥 키와 남은 항목은 그대로여야 한다 → Task 3 `test문맥안일부만잊으면_문맥과남은항목은유지`.

---

### Task 1: 변경 전 기준 측정

**Files:**
- Create (커밋하지 않음): `SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift`
- Create (커밋하지 않음): `$SCRATCH/bench/` 측정 데이터
- Modify: `docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md` (결과 기록)

**Interfaces:**
- Consumes: 현재 `NGramPredictiveTextEngine(language:fileURL:legacyStorage:maxKeys:)`, `onLoadCompleted`, `addWord`, `endSentence`, `suggestions(for:preferredScript:)`
- Produces: Task 4가 같은 파일을 `label = "after"`로 다시 돌린다. 결과 파일 `$SCRATCH/perf-159.txt`

- [x] **Step 1: 측정 데이터 준비**

#157 측정 파일(옛 `Int` 형식)을 이번 scratchpad로 복사한다. 원본 scratchpad가 지워질 수 있어 생성 코드도 함께 복사한다.

```sh
OLD=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/3526bae6-16dc-4bec-b303-db0928873699/scratchpad/bench
SCRATCH=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/a17970c2-b783-47ce-8ae4-26568a0f7dba/scratchpad
mkdir -p "$SCRATCH/bench/typical" "$SCRATCH/sdd-logs"
cp "$OLD/ngram_ko-en.plist" "$OLD/ngram_ko-KR.plist" "$OLD/main.swift" "$OLD/typical.swift" "$SCRATCH/bench/"
cp "$OLD/typical/merged.plist" "$SCRATCH/bench/typical/"
ls -la "$SCRATCH/bench" "$SCRATCH/bench/typical"
```

Expected: `ngram_ko-en.plist` 약 2.4MB(통합 최악), `ngram_ko-KR.plist` 약 1.2MB(언어별 최악), `typical/merged.plist` 약 1.0MB(통합 1년 × 하루 1,000단어). 원본이 없으면 `main.swift`(최악)·`typical.swift`(많은 사용)를 `swiftc -O`로 돌려 다시 만들고 그 사실을 기록한다.

- [x] **Step 2: 측정 코드 작성 (커밋하지 않음)**

`SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift`:

```swift
// 버리는 성능 측정 코드. 커밋하지 않는다 (#159 변경 전후 비교)
import Foundation
import Testing
import Darwin

@testable import SYKeyboardCore

private let label = "before"
private let scratch = "/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/a17970c2-b783-47ce-8ae4-26568a0f7dba/scratchpad"
private let benchDir = scratch + "/bench"
private let outFile = scratch + "/perf-159.txt"

private struct MirrorData: Codable {
    var unigram: [String: Int]
    var bigram: [String: [String: Int]]
    var trigram: [String: [String: Int]]
}

private func footprint() -> (now: Double, peak: Double) {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    return (Double(info.phys_footprint) / 1_048_576, Double(info.ledger_phys_footprint_peak) / 1_048_576)
}

private func log(_ s: String) {
    let line = "[\(label)] " + s
    print("PERF159 " + line)
    let data = (line + "\n").data(using: .utf8)!
    if let h = FileHandle(forWritingAtPath: outFile) {
        h.seekToEndOfFile(); h.write(data); try? h.close()
    } else {
        FileManager.default.createFile(atPath: outFile, contents: data)
    }
}

private func ms(_ d: Duration) -> Double {
    Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
}

private func stats(_ xs: [Double]) -> String {
    let s = xs.sorted()
    func p(_ q: Double) -> Double { s[min(s.count - 1, Int(Double(s.count) * q))] }
    return String(format: "중앙값 %.2fms, p95 %.2fms, 최대 %.2fms (n=%d)", p(0.5), p(0.95), s.last!, s.count)
}

private func kb(_ url: URL) -> Int {
    ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0) / 1024
}

/// 원본 파일을 임시 경로로 복사해 엔진을 만들고 로딩 완료까지 기다린다
@MainActor
private func loadEngine(file: String, language: String, maxKeys: Int) async -> (NGramPredictiveTextEngine, Double, URL) {
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".plist")
    try! FileManager.default.copyItem(at: URL(fileURLWithPath: "\(benchDir)/\(file)"), to: tmp)
    let clock = ContinuousClock()
    let start = clock.now
    var engine: NGramPredictiveTextEngine!
    await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
        engine = NGramPredictiveTextEngine(
            language: language,
            fileURL: tmp,
            legacyStorage: UserDefaults(suiteName: "perf159-\(UUID().uuidString)")!,
            maxKeys: maxKeys
        )
        engine.onLoadCompleted = { c.resume() }
    }
    return (engine, ms(clock.now - start), tmp)
}

@MainActor
private func run(name: String, file: String, language: String, maxKeys: Int, preferred: PredictiveTextScript?) async {
    try? await Task.sleep(for: .seconds(2))
    let base = footprint()
    let source = URL(fileURLWithPath: "\(benchDir)/\(file)")

    let (engine, firstLoad, url) = await loadEngine(file: file, language: language, maxKeys: maxKeys)
    try? await Task.sleep(for: .milliseconds(500))
    let loaded = footprint()
    log("[\(name)] 첫 로딩 \(String(format: "%.0f", firstLoad))ms, 로딩 뒤 유지 +\(String(format: "%.1f", loaded.now - base.now))MB, 로딩 중 peak +\(String(format: "%.1f", loaded.peak - base.peak))MB")

    // 스페이스 1회 = 단어 기록 + 문맥 후보 조회 + 문맥 없는 후보 조회
    let data = try! PropertyListDecoder().decode(MirrorData.self, from: Data(contentsOf: source))
    let known = Array(data.unigram.keys)
    let clock = ContinuousClock()
    var spaceTimes: [Double] = []
    var addTimes: [Double] = []
    for i in 0..<150 {
        try? await Task.sleep(for: .milliseconds(200))
        let word = i % 3 == 0 ? "새단어\(i)" : known.randomElement()!
        let t0 = clock.now
        engine.addWord(word)
        let t1 = clock.now
        _ = engine.suggestions(for: "\(word) ", preferredScript: preferred)
        _ = engine.suggestions(for: "", preferredScript: preferred)
        let t2 = clock.now
        addTimes.append(ms(t1 - t0))
        spaceTimes.append(ms(t2 - t0))
        if i % 12 == 11 { engine.endSentence() }
    }
    engine.endSentence()
    try? await Task.sleep(for: .seconds(2))
    let after = footprint()
    log("[\(name)] 스페이스 1회: \(stats(spaceTimes)), 16ms 초과 \(spaceTimes.filter { $0 > 16 }.count)회")
    log("[\(name)]   addWord: \(stats(addTimes))")
    log("[\(name)] 입력·저장 중 peak +\(String(format: "%.1f", after.peak - base.peak))MB")
    log("[\(name)] 파일 크기: 입력 \(kb(source))KB → 150단어 뒤 저장 \(kb(url))KB")

    var loads: [Double] = []
    for _ in 0..<5 {
        let (reloaded, t, _) = await loadEngine(file: file, language: language, maxKeys: maxKeys)
        loads.append(t)
        withExtendedLifetime(reloaded) {}
    }
    log("[\(name)] 로딩 반복: \(stats(loads))")
    withExtendedLifetime(engine) {}
}

@Suite(.serialized)
struct ZZNGramDecayPerfTests {
    @Test @MainActor func a통합최악() async {
        await run(name: "통합 최악", file: "ngram_ko-en.plist", language: "ko-en", maxKeys: 10000, preferred: .hangeul)
    }
    @Test @MainActor func b통합많은사용() async {
        await run(name: "통합 많은 사용", file: "typical/merged.plist", language: "ko-en", maxKeys: 10000, preferred: .hangeul)
    }
    @Test @MainActor func c언어별최악() async {
        await run(name: "언어별 최악", file: "ngram_ko-KR.plist", language: "ko-KR", maxKeys: 5000, preferred: nil)
    }
}
```

- [x] **Step 3: 최적화 빌드로 시나리오마다 새 프로세스에서 실행**

사용자에게 빌드가 수 분 걸린다고 먼저 알린다.

```sh
cd /Users/macmillan/Projects/XcodeProjects/SNMac/SYKeyboard/SYKeyboard
xcodebuild build-for-testing -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  SWIFT_OPTIMIZATION_LEVEL=-O > "$SCRATCH/sdd-logs/task1-build.log" 2>&1; tail -3 "$SCRATCH/sdd-logs/task1-build.log"
for t in 'a통합최악()' 'b통합많은사용()' 'c언어별최악()'; do
  xcodebuild test-without-building -project SYKeyboard.xcodeproj -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    -parallel-testing-enabled NO \
    -only-testing:"SYKeyboardTests/ZZNGramDecayPerfTests/$t" > "$SCRATCH/sdd-logs/task1-$t.log" 2>&1
  grep -E "PERF159|Executed|passed|failed" "$SCRATCH/sdd-logs/task1-$t.log" | tail -12
done
cat "$SCRATCH/perf-159.txt"
```

Expected: `** TEST BUILD SUCCEEDED **`, 시나리오마다 테스트 1개 통과, `perf-159.txt`에 `[before]` 줄이 시나리오별 6줄. 테스트가 0개 실행되면 `-only-testing` 식별자에서 `()`를 빼고 다시 실행하고 그 사실을 기록한다.

- [x] **Step 4: 측정 코드를 작업 트리에서 치우고 결과 기록**

```sh
mv SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift "$SCRATCH/bench/"
git status --short
```

Expected: `git status --short`에 이 계획 문서 외 변경 없음(`.xcscheme` 변경이 보이면 Global Constraints대로 처리).
아래 「Task 1 결과」에 `perf-159.txt`의 `[before]` 값을 옮긴다(시나리오별 첫 로딩, 로딩 반복 중앙값, 유지·peak 메모리, 스페이스 1회 중앙값/p95/최대·16ms 초과 횟수, 파일 크기).

**Task 1 결과:** (2026-09-27, 변경 전 코드 = `5806926a`와 같음, iPhone 13 mini / iOS 18.6 시뮬레이터, `SWIFT_OPTIMIZATION_LEVEL=-O`, `build-for-testing` 1회 뒤 시나리오마다 `test-without-building` 새 프로세스. `-only-testing` 식별자는 `()`를 붙인 형태로 각 1개 테스트 실행 확인)

| 시나리오 | 첫 로딩 | 로딩 반복 중앙값 | 로딩 뒤 유지 | 로딩 중 peak | 입력·저장 중 peak | 스페이스 1회 중앙값 / p95 / 최대 | 16ms 초과 | 파일 크기(입력 → 150단어 뒤) |
|---|---|---|---|---|---|---|---|---|
| 통합 최악 | 657ms | 621ms | +19.8MB | +23.0MB | +40.3MB | 1.93 / 10.72 / 14.84ms | 0회 | 2385KB → 2385KB |
| 통합 많은 사용 | 181ms | 166ms | +9.6MB | +19.9MB | +19.9MB | 3.26 / 6.63 / 7.39ms | 0회 | 1035KB → 1037KB |
| 언어별 최악 | 354ms | 333ms | +10.6MB | +13.2MB | +20.0MB | 2.16 / 5.98 / 7.30ms | 0회 | 1195KB → 1195KB |

- 원본: `$SCRATCH/perf-159.txt`의 `[before]` 줄, 로그 `$SCRATCH/sdd-logs/task1-*.log`. 측정 코드는 `$SCRATCH/bench/ZZNGramDecayPerfTests.swift`로 옮겼다(커밋 안 함).
- 데이터는 #157 scratchpad에서 복사했다(재생성 없음).

- [x] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
docs: #159 - 변경 전 NGram 입력 지연·메모리·파일 크기 기준 측정 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: 감쇠 점수·새 저장 형식·옛 형식 변환

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
- Modify: `SYKeyboardTests/Domain/NGramEngineTestSupport.swift`
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests.swift`
- Modify: `SYKeyboardTests/Domain/NGramPredictiveTextEngineFileMigrationTests.swift`
- Modify: `SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift:28-46`
- Modify: `SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift:38-45, 96-100`
- Modify: `SYKeyboardTests/Domain/NGramPredictiveTextEngineLoadingTests.swift:36`, `NGramPredictiveTextEngineCompletionTests.swift:144` (헬퍼 이름만)

**Interfaces:**
- Produces (Task 3이 쓴다):
  - `static let defaultHalfLife: Double = 500`, `static let defaultForgetAfter: Double = 10_000` (internal)
  - internal init에 `halfLife: Double = NGramPredictiveTextEngine.defaultHalfLife`, `forgetAfter: Double = NGramPredictiveTextEngine.defaultForgetAfter` 인자 (`maxKeys` 뒤, `saveQueue` 앞)
  - `private let halfLife: Double`, `private let forgetAfter: Double`, `private var clock: Double`
  - `fileprivate struct NGramData { var version: Int; var clock: Double; var unigram: [String: Double]; var bigram/trigram: [String: [String: Double]] }`
  - `startBackgroundLoad()` 안의 `var loaded: NGramData`, `var needsSave: Bool` (Task 3이 두 값 사이에 준비 단계를 끼운다)
  - 테스트 헬퍼: `makeLoadedNGramFixture(name:maxKeys:halfLife:forgetAfter:url:)`, `writeLegacyNGramData(unigram:bigram:trigram:to:)`, `readSavedNGramFile(at:) -> SavedNGramFile`, `temporaryNGramFileURL(name:) -> URL`

- [x] **Step 1: 테스트 헬퍼 갱신**

`SYKeyboardTests/Domain/NGramEngineTestSupport.swift`에서 `makeLoadedNGramFixture`와 파일 헬퍼를 아래로 바꾼다(`NGramLoadGate`는 그대로).

```swift
/// 임시 파일을 쓰는 엔진을 만들고 초기 로딩이 끝날 때까지 기다린다.
/// `url`을 주면 그 파일을 읽는다(저장 뒤 다시 로딩하는 테스트용)
func makeLoadedNGramFixture(
    name: String,
    maxKeys: Int = 5000,
    halfLife: Double = NGramPredictiveTextEngine.defaultHalfLife,
    forgetAfter: Double = NGramPredictiveTextEngine.defaultForgetAfter,
    url: URL? = nil
) async -> NGramEngineFixture {
    let url = url ?? temporaryNGramFileURL(name: name)
    let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.save.\(name)")
    let gate = NGramLoadGate()
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyScheduler: gate.schedule,
        maxKeys: maxKeys,
        halfLife: halfLife,
        forgetAfter: forgetAfter,
        saveQueue: saveQueue
    )
    await gate.finishLoading()
    return NGramEngineFixture(engine: engine, url: url, saveQueue: saveQueue)
}

func temporaryNGramFileURL(name: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
}
```

파일 끝의 `TestNGramData`/`writeNGramData`를 아래로 바꾼다.

```swift
/// #159 이전의 빈도 형식(1.6.3 파일·develop 파일과 같은 구조)
struct LegacyTestNGramData: Codable {
    var unigram: [String: Int]
    var bigram: [String: [String: Int]]
    var trigram: [String: [String: Int]]
}

/// 옛 빈도 형식(binary plist)으로 학습 데이터를 쓴다. 상위 디렉터리가 없으면 만든다
func writeLegacyNGramData(
    unigram: [String: Int],
    bigram: [String: [String: Int]] = [:],
    trigram: [String: [String: Int]] = [:],
    to url: URL
) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(LegacyTestNGramData(unigram: unigram, bigram: bigram, trigram: trigram))
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

/// 엔진이 저장한 새 형식(version 2) 파일
struct SavedNGramFile: Decodable {
    var version: Int
    var clock: Double
    var unigram: [String: Double]
    var bigram: [String: [String: Double]]
    var trigram: [String: [String: Double]]
}

func readSavedNGramFile(at url: URL) throws -> SavedNGramFile {
    try PropertyListDecoder().decode(SavedNGramFile.self, from: Data(contentsOf: url))
}
```

호출부 이름을 바꾼다: `NGramPredictiveTextEngineCompletionTests.swift:144`, `NGramPredictiveTextEngineFileMigrationTests.swift:17, 31, 32, 61, 75`, `NGramPredictiveTextEngineLoadingTests.swift:36`의 `writeNGramData(` → `writeLegacyNGramData(`.

- [x] **Step 2: 새 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests.swift`:

```swift
//
//  NGramPredictiveTextEngineDecayTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 감쇠 점수 기록·정리·저장·변환 검증")
struct NGramPredictiveTextEngineDecayTests {

    // MARK: - 최근 사용 반영

    @Test("반감기가 지나면 최근에 쓴 단어가 예전에 더 많이 쓴 단어보다 unigram 앞에 옴")
    func test반감기가지나면_최근에쓴단어가_예전에더많이쓴단어보다앞() async throws {
        let engine = await makeLoadedNGramFixture(name: "decay-unigram", halfLife: 10).engine
        recordAlone(engine, "alpha", times: 4)
        recordAlone(engine, "filler", times: 30)
        recordAlone(engine, "bravo", times: 3)

        let results = engine.suggestions(for: "")
        let alphaIndex = try #require(results.firstIndex(of: "alpha"))
        let bravoIndex = try #require(results.firstIndex(of: "bravo"))
        #expect(bravoIndex < alphaIndex)
    }

    @Test("반감기가 지나면 문맥 후보도 최근에 쓴 단어가 앞에 옴")
    func test반감기가지나면_문맥후보도_최근에쓴단어가앞() async {
        let engine = await makeLoadedNGramFixture(name: "decay-bigram", halfLife: 10).engine
        recordSentence(engine, ["오늘", "날씨"], times: 4)
        recordAlone(engine, "filler", times: 30)
        recordSentence(engine, ["오늘", "회의"], times: 3)

        #expect(Array(engine.suggestions(for: "오늘 ").prefix(2)) == ["회의", "날씨"])
    }

    // MARK: - 같은 횟수면 먼저 쓴 것부터 정리

    @Test("unigram 상한을 넘으면 같은 횟수 중 먼저 쓴 단어부터 지움")
    func testUnigram상한을넘으면_같은횟수중_먼저쓴단어부터지움() async {
        let engine = await makeLoadedNGramFixture(name: "decay-tie-unigram", maxKeys: 3).engine
        for word in ["a", "b", "c", "d"] {
            recordAlone(engine, word, times: 1)
        }

        #expect(engine.suggestions(for: "") == ["d", "c", "b"])
    }

    @Test("문맥 뒤 단어가 24개를 넘으면 같은 횟수 중 먼저 쓴 단어부터 지움")
    func test문맥뒤단어가24개를넘으면_같은횟수중_먼저쓴단어부터지움() async throws {
        let fixture = await makeLoadedNGramFixture(name: "decay-tie-entries")
        let successors = (0...24).map { "s\($0)" }
        for successor in successors {
            recordSentence(fixture.engine, ["k", successor], times: 1)
        }
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: fixture.url)
        let entries = try #require(saved.bigram["k"])
        #expect(Set(entries.keys) == Set(successors.dropFirst()))
    }

    @Test("문맥 키가 상한을 넘으면 같은 총점 중 먼저 쓴 문맥부터 지움")
    func test문맥키가상한을넘으면_같은총점중_먼저쓴문맥부터지움() async throws {
        let fixture = await makeLoadedNGramFixture(name: "decay-tie-keys", maxKeys: 3)
        for context in ["a", "b", "c", "d"] {
            recordSentence(fixture.engine, [context, "x"], times: 1)
        }
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(Set(saved.bigram.keys) == ["b", "c", "d"])
    }

    // MARK: - 저장 형식과 클록

    @Test("저장한 뒤 다시 로딩하면 순서와 클록이 이어짐")
    func test저장한뒤다시로딩하면_순서와클록이이어짐() async throws {
        let fixture = await makeLoadedNGramFixture(name: "decay-roundtrip", halfLife: 10)
        recordAlone(fixture.engine, "alpha", times: 4)
        recordAlone(fixture.engine, "bravo", times: 3)
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}
        let before = fixture.engine.suggestions(for: "")

        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(saved.version == 2)
        #expect(saved.clock == 7)

        let reloaded = await makeLoadedNGramFixture(name: "decay-roundtrip-reload", halfLife: 10, url: fixture.url)
        #expect(reloaded.engine.suggestions(for: "") == before)

        reloaded.engine.addWord("charlie")
        reloaded.engine.endSentence()
        reloaded.saveQueue.sync {}
        let resaved = try readSavedNGramFile(at: fixture.url)
        #expect(resaved.clock == 8)
    }

    @Test("초기화하면 클록도 처음부터 셈")
    func test초기화하면_클록도처음부터셈() async throws {
        let fixture = await makeLoadedNGramFixture(name: "decay-reset-clock")
        recordAlone(fixture.engine, "alpha", times: 5)

        fixture.engine.resetAllData()
        fixture.engine.addWord("bravo")
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(saved.clock == 1)
    }

    @Test("로딩 전에 친 단어도 클록을 올림")
    func test로딩전에친단어도_클록을올림() async throws {
        let url = temporaryNGramFileURL(name: "decay-pending-clock")
        try writeLegacyNGramData(unigram: ["old": 2], to: url)
        let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.decay.pending")
        let gate = NGramLoadGate()
        let engine = NGramPredictiveTextEngine(
            language: "test-decay-pending-clock",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyScheduler: gate.schedule,
            saveQueue: saveQueue
        )

        engine.addWord("new")
        await gate.finishLoading()
        engine.endSentence()
        saveQueue.sync {}

        let saved = try readSavedNGramFile(at: url)
        #expect(saved.clock == 1)
        #expect(saved.unigram["old"] == 2)
        let newValue = try #require(saved.unigram["new"])
        #expect(newValue > 1)
    }

    @Test("깨진 파일은 빈 학습으로 시작")
    func test깨진파일은_빈학습으로시작() async throws {
        let url = temporaryNGramFileURL(name: "decay-corrupt")
        try Data("not a plist".utf8).write(to: url)

        let engine = await makeLoadedNGramFixture(name: "decay-corrupt", url: url).engine

        #expect(engine.suggestions(for: "") == [])
    }

    // MARK: - 옛 형식 변환

    @Test("기록한 단어가 많은 옛 형식 파일은 빈도 비율을 유지한 점수로 옮기고 새 형식으로 저장")
    func test기록한단어가많은옛형식파일은_빈도비율을유지한점수로옮기고_새형식으로저장() async throws {
        let url = temporaryNGramFileURL(name: "decay-legacy-scaled")
        try writeLegacyNGramData(unigram: ["a": 3000, "b": 1000], bigram: ["a": ["b": 400]], to: url)
        let fixture = await makeLoadedNGramFixture(name: "decay-legacy-scaled", url: url)
        #expect(fixture.engine.suggestions(for: "") == ["a", "b"])

        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: url)
        let scale = 500 / (M_LN2 * 4000)
        let a = try #require(saved.unigram["a"])
        let b = try #require(saved.unigram["b"])
        let ab = try #require(saved.bigram["a"]?["b"])
        #expect(saved.version == 2)
        #expect(saved.clock == 0)
        #expect(abs(a - 3000 * scale) < 1e-9)
        #expect(abs(b - 1000 * scale) < 1e-9)
        #expect(abs(ab - 400 * scale) < 1e-9)
    }

    @Test("기록한 단어가 적은 옛 형식 파일은 빈도를 그대로 점수로 옮김")
    func test기록한단어가적은옛형식파일은_빈도를그대로점수로옮김() async throws {
        let url = temporaryNGramFileURL(name: "decay-legacy-small")
        try writeLegacyNGramData(unigram: ["a": 3, "b": 1], to: url)
        let fixture = await makeLoadedNGramFixture(name: "decay-legacy-small", url: url)

        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: url)
        #expect(saved.unigram == ["a": 3, "b": 1])
    }

    @Test("옛 형식 unigram이 비어 있으면 배율 1로 옮김")
    func test옛형식unigram이비어있으면_배율1로옮김() async throws {
        let url = temporaryNGramFileURL(name: "decay-legacy-empty-unigram")
        try writeLegacyNGramData(unigram: [:], bigram: ["a": ["b": 5]], to: url)
        let fixture = await makeLoadedNGramFixture(name: "decay-legacy-empty-unigram", url: url)

        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: url)
        #expect(saved.bigram == ["a": ["b": 5]])
    }

    @Test("UserDefaults에 남은 옛 데이터는 변환해 새 형식 파일로 쓰고 키를 지움")
    func testUserDefaults옛데이터는_변환해새형식파일로쓰고_키를지움() async throws {
        let suiteName = "SYKeyboardTests-\(UUID().uuidString)"
        let storage = try #require(UserDefaults(suiteName: suiteName))
        defer { storage.removePersistentDomain(forName: suiteName) }
        let language = "test-decay-defaults"
        storage.set(["a": 3000, "b": 1000], forKey: "com.snmac.sykeyboard.ngram.\(language).unigram")
        storage.set(["a": ["b": 400]], forKey: "com.snmac.sykeyboard.ngram.\(language).bigram")
        let url = temporaryNGramFileURL(name: "decay-defaults")
        let gate = NGramLoadGate()
        let engine = NGramPredictiveTextEngine(
            language: language,
            fileURL: url,
            legacyStorage: storage,
            loadApplyScheduler: gate.schedule
        )
        await gate.finishLoading()

        #expect(engine.suggestions(for: "") == ["a", "b"])
        let saved = try readSavedNGramFile(at: url)
        let scale = 500 / (M_LN2 * 4000)
        let a = try #require(saved.unigram["a"])
        let ab = try #require(saved.bigram["a"]?["b"])
        #expect(saved.version == 2)
        #expect(abs(a - 3000 * scale) < 1e-9)
        #expect(abs(ab - 400 * scale) < 1e-9)
        #expect(storage.object(forKey: "com.snmac.sykeyboard.ngram.\(language).unigram") == nil)
        #expect(storage.object(forKey: "com.snmac.sykeyboard.ngram.\(language).bigram") == nil)
    }

    @Test("문맥당 24개를 넘는 옛 데이터는 다시 기록할 때 낮은 점수부터 24개로 줄임")
    func test문맥당24개를넘는옛데이터는_다시기록할때_낮은점수부터24개로줄임() async throws {
        let url = temporaryNGramFileURL(name: "decay-legacy-50")
        // 1.6.3은 문맥당 50개까지 저장했다. s0이 가장 낮고 s29가 가장 높다
        let successors = Dictionary(uniqueKeysWithValues: (0..<30).map { ("s\($0)", $0 + 1) })
        try writeLegacyNGramData(unigram: ["k": 30], bigram: ["k": successors], to: url)
        let fixture = await makeLoadedNGramFixture(name: "decay-legacy-50", url: url)

        recordSentence(fixture.engine, ["k", "new"], times: 1)
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        // 31개 중 값이 큰 24개(s6 = 7 ~ s29 = 30)가 남는다. 방금 쓴 new(≈1.003)는 오래 쌓인 항목보다 낮아
        // 함께 지워진다. 문맥당 정리 규칙(점수 낮은 것부터)은 바꾸지 않는다
        let saved = try readSavedNGramFile(at: url)
        let kept = try #require(saved.bigram["k"])
        #expect(kept.count == 24)
        #expect(Set(kept.keys) == Set((6..<30).map { "s\($0)" }))
    }

    @Test("기록이 많은 사용자의 문맥당 24개를 넘는 옛 데이터는 새 단어를 남기고 오래된 항목부터 지움")
    func test기록이많은사용자의문맥당24개를넘는옛데이터는_새단어를남기고_오래된항목부터지움() async throws {
        let url = temporaryNGramFileURL(name: "decay-legacy-50-heavy")
        // 전체 기록 10만 단어라 배율이 약 0.0072다. 옛 값 1~30은 0.0072~0.22가 된다
        let successors = Dictionary(uniqueKeysWithValues: (0..<30).map { ("s\($0)", $0 + 1) })
        try writeLegacyNGramData(unigram: ["k": 100_000], bigram: ["k": successors], to: url)
        let fixture = await makeLoadedNGramFixture(name: "decay-legacy-50-heavy", url: url)

        recordSentence(fixture.engine, ["k", "new"], times: 1)
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        // 방금 쓴 new(≈1.003)가 가장 높고, 옛 항목은 큰 순으로 s7~s29(23개)가 남는다
        let saved = try readSavedNGramFile(at: url)
        let kept = try #require(saved.bigram["k"])
        #expect(kept.count == 24)
        #expect(Set(kept.keys) == Set((7..<30).map { "s\($0)" } + ["new"]))
    }
}

// MARK: - Helpers

/// 문맥 없이 unigram만 남도록 문장 버퍼를 비우고 기록한다
private func recordAlone(_ engine: NGramPredictiveTextEngine, _ word: String, times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        engine.addWord(word)
    }
}

/// 문장 버퍼를 비우고 `words`를 차례로 기록한다
private func recordSentence(_ engine: NGramPredictiveTextEngine, _ words: [String], times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        for word in words {
            engine.addWord(word)
        }
    }
}
```

값 계산(`test문맥당24개를넘는...`): 옛 unigram 합 `N = 30`이라 배율 1, `s0`~`s29` 값 1~30. `k`(클록 1)·`new`(클록 2, 값 `2^(2/500)` ≈ 1.003)를 기록하면 31개가 되고 `pruneEntries`가 값이 큰 24개(`s6`~`s29`)만 남긴다. 기록이 많은 경우(`N = 100,000`)는 배율 `500 / (ln2 × 100,000)` ≈ 0.0072라 옛 값이 모두 `new`보다 작아 `new`와 `s7`~`s29`가 남는다. 두 테스트는 기록량에 따라 새 단어가 남는지가 갈리는 것을 함께 고정한다.

- [x] **Step 3: 기존 테스트를 새 형식·감쇠에 맞춤**

`NGramPredictiveTextEngineRemovalTests.swift`의 `test삭제하면_값과문맥키에서모두지우고_바로저장` 단언부(`let data = ...`부터 끝까지)를 바꾼다.

```swift
        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(Set(saved.unigram.keys) == ["오늘", "좋다"])
        #expect(saved.bigram.isEmpty)
        #expect(saved.trigram.isEmpty)
```

`NGramPredictiveTextEngineRankingTests.swift`에서 30번부터 차례로 줄여 기록하는 두 곳은, 앞 단어를 30번 쓴 직후 29번 쓴 단어가 감쇠로 약간 앞서 순서가 뒤집힌다(`29 × 2^(45/500) > 30 × 2^(15.5/500)`). 테스트 목적(상위 10개 선별·보충 순서)을 지키도록 **적게 쓴 단어부터** 기록한다.

`test항목수가상한보다많으면_상위10개만_빈도순으로반환`:

```swift
        let words = (1...14).map { "word\($0)" }
        // 적게 쓴 단어부터 기록해 최근 사용이 횟수 순서를 뒤집지 않게 한다
        for (index, word) in words.enumerated().reversed() {
            record(engine, word: word, times: 30 - index)
        }
```

`test문맥이있으면_trigram다음bigram다음unigram순으로_10칸을채우고중복을제거`의 unigram 보충 부분:

```swift
        // unigram 보충용. 위 단어들보다 많이 써서 상위에 온다. 적게 쓴 단어부터 기록한다
        for (index, word) in ["u1", "u2", "u3", "u4", "u5", "u6"].enumerated().reversed() {
            recordSentence(engine, words: [word], times: 30 - index)
        }
```

`NGramPredictiveTextEngineFileMigrationTests.swift`에 1.6.3 경로 테스트를 추가한다(`test초기화는_옛파일도삭제` 뒤).

```swift
    @Test("옛 위치의 옛 형식 파일은 옮긴 뒤 다음 저장에서 새 형식으로 씀")
    func test옛위치옛형식파일은_옮긴뒤_다음저장에서새형식으로씀() async throws {
        let paths = try makeContainer(name: "legacy-format")
        try writeLegacyNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.migration.legacy-format")

        let gate = NGramLoadGate()
        let engine = makeEngine(paths: paths, name: "legacy-format", gate: gate, saveQueue: saveQueue)
        await gate.finishLoading()
        engine.saveToDisk()
        saveQueue.sync {}

        let saved = try readSavedNGramFile(at: paths.fileURL)
        #expect(saved.version == 2)
        #expect(saved.unigram == ["legacy": 3])
        #expect(engine.suggestions(for: "") == ["legacy"])
    }
```

- [x] **Step 4: 실패 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineDecayTests \
  > "$SCRATCH/sdd-logs/task2-red.log" 2>&1; grep -E "error:|TEST (SUCCEEDED|FAILED)" "$SCRATCH/sdd-logs/task2-red.log" | head -20
```

Expected: 컴파일 실패. `extra arguments at positions ... in call`(`halfLife`/`forgetAfter`) 또는 `type 'NGramPredictiveTextEngine' has no member 'defaultHalfLife'`.

- [x] **Step 5: 엔진 구현 — 저장 모델과 프로퍼티**

`NGramPredictiveTextEngine.swift`의 `// MARK: - Storage Model` 절을 바꾼다.

```swift
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
```

`maxKeys(forLanguage:)` 아래에 상수를 추가한다.

```swift
    /// 기본 반감기(입력 단어 수). 이만큼 입력하면 점수가 절반이 된다.
    /// 같은 빈도로 습관을 바꾸면 새 표현이 이만큼 뒤에 예전 표현을 추월한다(#159 설계 문서의 시뮬레이션)
    static let defaultHalfLife: Double = 500
    /// 기본 잊는 기간(입력 단어 수). 한 번 쓴 항목이 이만큼 다시 쓰이지 않으면 저장소에 자리가 있어도 지운다
    static let defaultForgetAfter: Double = 10_000
```

저장소 프로퍼티를 `Double`로 바꾸고 클록·반감기를 추가한다.

```swift
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
```

`maxEntriesPerKey` 주석의 "빈도 낮은 항목부터 정리" → "점수 낮은 항목부터 정리", "순위 변동을 위한 빈도 기록" → "순위 변동을 위한 점수 기록"으로 바꾼다.

internal init에 인자를 추가한다.

```swift
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
        // (이하 기존 그대로)
```

- [x] **Step 6: 엔진 구현 — 로딩·저장·변환**

`startBackgroundLoad()`의 로드 분기와 반영부를 바꾼다.

```swift
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
```

`applyLoadedData` 안:

```swift
                    self.unigramStore = loaded.unigram
                    self.bigramStore = loaded.bigram
                    self.trigramStore = loaded.trigram
                    self.clock = loaded.clock
                    self.needsLegacyCleanup = needsCleanup
                    // 변환한 데이터는 다음 저장 기회에 새 형식으로 쓴다. 이후 flushPendingEvents가 기록하면 다시 true가 된다
                    self.hasUnsavedChanges = needsSave
```

`applyLoadedData` 클로저는 지금 `needsCleanup`(var)을 캡처하는 것과 같은 방식으로 `loaded`·`needsSave`를 캡처한다(Swift 5 언어 모드). Task 3이 클로저를 만들기 전에 `loaded`를 고치므로 `loaded`는 `var`다.

`saveToDisk()`의 스냅샷:

```swift
        let snapshot = NGramData(
            clock: clock,
            unigram: unigramStore,
            bigram: bigramStore,
            trigram: trigramStore
        )
```

`resetAllData()`에서 `trigramStore = [:]` 다음 줄에 `clock = 0`을 넣는다.

`removeWord(_:)`의 `droppingWord` 타입을 `([String: Double]) -> [String: Double]?`로 바꾼다.

`loadFromFile()`을 바꾼다.

```swift
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
```

`migrateFromUserDefaults()`에서 `let migrated = NGramData(...)` 부분을 바꾼다(키 읽기·쓰기·정리 흐름은 그대로).

```swift
        let migrated = converted(LegacyNGramData(
            unigram: unigram ?? [:],
            bigram: bigram ?? [:],
            trigram: trigram ?? [:]
        ))
```

- [x] **Step 7: 엔진 구현 — 기록·순위·정리의 점수화**

`recordNGrams()`:

```swift
    /// 현재 버퍼의 마지막 단어들로 n-gram을 기록합니다.
    func recordNGrams() {
        let words = currentSentenceWords
        let count = words.count
        clock += 1
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
```

타입만 `Int` → `Double`로 바꿀 곳(로직 그대로):

- `completions(forTypedWord:previousWord:limit:)`: `var top: [(key: String, value: Double)] = []`
- `rankedUnigramCandidates(preferredScript:)`: `var preferred: [(key: String, value: Double)] = []`, `var others: [(key: String, value: Double)] = []`
- `insertTopUnigram(_ entry: (key: String, value: Double), into top: inout [(key: String, value: Double)])`
- `rankedCandidates(from store: [String: [String: Double]], key: String) -> [String]`
- `pruneEntries(in store: inout [String: [String: Double]], forKey key: String)`
- `pruneKeys(in store: inout [String: [String: Double]])`: `var lowestTotal = Double.infinity`
- `CaseSpellingGroup`: `first: (key: String, value: Double)?`, `others: [(key: String, value: Double)]`, `mutating func add(_ spelling: String, score: Double)`, `var representative: (key: String, value: Double)`. `completions`의 호출부는 `.add(entry.key, score: entry.value)`.

주석의 "빈도"를 "점수"로 바꾼다: 클래스 설명 "문맥에 따른 다음 단어를 빈도순으로 예측" → "문맥에 따른 다음 단어를 최근 사용이 반영된 점수순으로 예측", `suggestions` 설명의 "unigram(빈도순)"·"빈도순으로 정렬된"·"trigram·bigram 후보는 ... 빈도순" → "점수순", `completions` 설명의 "빈도순"·"합친 빈도" → "점수순"·"합친 점수", `rankedUnigramCandidates`·`insertTopUnigram`·`rankedCandidates`·`pruneUnigram`·`pruneEntries`·`pruneKeys`·`CaseSpellingGroup`의 "빈도" → "점수"("총 빈도" → "총점"). `CaseSpellingGroup`의 `("SY키보드" 5 > "sy키보드" 1)` 예시는 "더 자주 쓴 표기(점수가 높은 표기)"로 바꾼다.

- [x] **Step 8: 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineDecayTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEnginePruneTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRemovalTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineCompletionTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineScriptPreferenceTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests \
  -only-testing:SYKeyboardTests/SuggestionControllerNGramCompletionTests \
  -only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests \
  > "$SCRATCH/sdd-logs/task2-green.log" 2>&1; grep -E "✘|Test run with|TEST (SUCCEEDED|FAILED)" "$SCRATCH/sdd-logs/task2-green.log" | tail -20
```

Expected: `** TEST SUCCEEDED **`, 실패(`✘`) 없음. 실패가 있으면 기대값을 고치기 전에 그 테스트가 감쇠로 순서가 바뀐 것인지(Step 3과 같은 경우), 동작이 틀린 것인지 먼저 가린다. 기대값을 바꿨다면 이유를 결과에 적는다.

- [x] **Step 9: Commit**

이 문서의 Task 2 체크박스와 결과(통과 suite·테스트 개수, 로그 경로, Step 8에서 기대값을 바꾼 테스트가 있으면 그 이유)를 기록한 뒤:

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  SYKeyboardTests/Domain/NGramEngineTestSupport.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineFileMigrationTests.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineLoadingTests.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineCompletionTests.swift \
  docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
feat: #159 - NGram 기록·정리·추천을 지수 감쇠 점수로 바꾸고 옛 빈도 데이터 변환

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

**Task 2 결과:** (2026-09-27)
- Step 4(RED): 예상대로 컴파일 실패 — `type 'NGramPredictiveTextEngine' has no member 'defaultHalfLife'`/`'defaultForgetAfter'`, `extra arguments at positions #6, #7 in call`. 로그 `$SCRATCH/sdd-logs/task2-red.log`
- Step 8(GREEN): NGram 관련 11 suites 73 tests 전부 통과(`$SCRATCH/ngram-suites.sh`, 로그 `$SCRATCH/sdd-logs/task2-green.log`). 새 테스트 `NGramPredictiveTextEngineDecayTests` 15개, `FileMigrationTests` 1개 추가. 엔진·테스트 파일의 새 경고 없음
- 기대값을 바꾼 기존 테스트는 계획 Step 3의 세 곳뿐이다(Removal 파일 단언을 새 형식으로, Ranking 두 곳 기록 순서). 그 밖의 기존 테스트는 고치지 않고 통과했다

---

### Task 3: 로딩 때 기준 시점 되돌리기·잊기와 입력 중 넘침 방어

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
- Modify: `SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests.swift`

**Interfaces:**
- Consumes (Task 2): `halfLife`, `forgetAfter`, `clock`, `NGramData`, `startBackgroundLoad()`의 `loaded`/`needsSave`, 테스트 헬퍼
- Produces: `private static let loadRebaseLimit: Double = 300`, `private static let recordRebaseLimit: Double = 900`, `func prepareLoadedData(_ data: inout NGramData) -> Bool`, `static func rebase(_:_:_:clock:halfLife:)`, `static func removingForgotten(_:below:removed:) -> [String: [String: Double]]`

- [x] **Step 1: 실패하는 테스트 추가**

`NGramPredictiveTextEngineDecayTests`의 `// MARK: - 옛 형식 변환` 앞에 넣는다.

```swift
    // MARK: - 잊기와 기준 시점 되돌리기

    @Test("잊는 기간 동안 다시 쓰지 않은 항목은 다시 로딩하면 사라짐")
    func test잊는기간동안다시쓰지않은항목은_다시로딩하면사라짐() async throws {
        let fixture = await makeLoadedNGramFixture(name: "forget", halfLife: 1, forgetAfter: 4)
        recordSentence(fixture.engine, ["옛문맥", "옛단어"], times: 1)
        for index in 0..<6 {
            recordAlone(fixture.engine, "새단어\(index)", times: 1)
        }
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        let reloaded = await makeLoadedNGramFixture(name: "forget-reload", halfLife: 1, forgetAfter: 4, url: fixture.url).engine

        // 클록 8, 기준값 2^(8-4): 값 2(옛문맥)·4(옛단어, 옛문맥→옛단어)·8(새단어0)은 지우고 16 이상은 남긴다
        #expect(reloaded.suggestions(for: "") == ["새단어5", "새단어4", "새단어3", "새단어2", "새단어1"])
        // 문맥 키도 지워져 unigram 보충만 남는다
        #expect(reloaded.suggestions(for: "옛문맥 ") == reloaded.suggestions(for: ""))
    }

    @Test("문맥 안 일부만 잊으면 문맥과 남은 항목은 유지")
    func test문맥안일부만잊으면_문맥과남은항목은유지() async throws {
        let fixture = await makeLoadedNGramFixture(name: "forget-partial", halfLife: 1, forgetAfter: 4)
        recordSentence(fixture.engine, ["문맥", "옛단어"], times: 1)
        for index in 0..<3 {
            recordAlone(fixture.engine, "채움\(index)", times: 1)
        }
        recordSentence(fixture.engine, ["문맥", "새단어"], times: 1)
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        // 다시 로딩한 엔진은 기록이 없어도 잊은 결과를 저장한다(로딩 때 바뀐 데이터는 dirty)
        let reloadedFixture = await makeLoadedNGramFixture(name: "forget-partial-reload", halfLife: 1, forgetAfter: 4, url: fixture.url)
        reloadedFixture.engine.saveToDisk()
        reloadedFixture.saveQueue.sync {}

        // 클록 7, 기준값 2^3 = 8: 문맥→옛단어(값 4)는 지우고 문맥→새단어(값 128)는 남긴다
        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(saved.bigram == ["문맥": ["새단어": 128]])
        #expect(reloadedFixture.engine.suggestions(for: "문맥 ").first == "새단어")
    }

    @Test("클록이 반감기의 300배를 넘으면 로딩할 때 되돌리고 순서는 유지")
    func test클록이반감기300배를넘으면_로딩할때되돌리고_순서는유지() async throws {
        let fixture = await makeLoadedNGramFixture(name: "rebase-load", halfLife: 1, forgetAfter: 1_000)
        for index in 0..<301 {
            recordAlone(fixture.engine, "w\(index % 7)", times: 1)
        }
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}
        let before = fixture.engine.suggestions(for: "")
        let firstSaved = try readSavedNGramFile(at: fixture.url)
        #expect(firstSaved.clock == 301)

        let reloaded = await makeLoadedNGramFixture(name: "rebase-load-reload", halfLife: 1, forgetAfter: 1_000, url: fixture.url)
        #expect(reloaded.engine.suggestions(for: "") == before)

        reloaded.engine.addWord("w0")
        reloaded.engine.endSentence()
        reloaded.saveQueue.sync {}
        let saved = try readSavedNGramFile(at: fixture.url)
        #expect(saved.clock == 1)
        // 되돌린 값은 현재 점수라 가장 최근 단어(w0, 방금 +1) 값이 2 안팎이다
        let w0 = try #require(saved.unigram["w0"])
        #expect(w0 < 4)
    }

    @Test("입력 중 클록이 반감기의 900배를 넘으면 되돌려 값이 넘치지 않음")
    func test입력중클록이반감기900배를넘으면_되돌려값이넘치지않음() async throws {
        let fixture = await makeLoadedNGramFixture(name: "rebase-record", halfLife: 1)
        for index in 0..<1_100 {
            recordAlone(fixture.engine, "w\(index % 7)", times: 1)
        }
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        let saved = try readSavedNGramFile(at: fixture.url)
        // 901번째 기록에서 0으로 되돌린 뒤 199번 더 기록했다
        #expect(saved.clock == 199)
        #expect(saved.unigram.values.allSatisfy { $0.isFinite })
        #expect(fixture.engine.suggestions(for: "").first == "w\(1_099 % 7)")
    }
```

값 계산(`test문맥안일부만잊으면...`): `문맥`(t1)→`옛단어`(t2) 값 `2^2 = 4`, 채움 t3~5, `문맥`(t6)→`새단어`(t7) 값 `2^7 = 128`, 클록 7, 기준값 `2^(7-4) = 8`. `exp2`에 정수를 넣으면 정확한 값이라 `128`과 바로 비교한다.

`test잊는기간...`의 값 계산: `옛문맥`(t1) 값 2, `옛단어`(t2) 값 4, `옛문맥→옛단어` 값 4, `새단어0`~`새단어5`(t3~8) 값 8~256, 클록 8, 기준값 `2^(8-4) = 16`. `새단어1`(값 16)은 경계값이라 남는다(현재 점수가 기준값과 같으면 지우지 않는다).

- [x] **Step 2: 실패 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineDecayTests \
  > "$SCRATCH/sdd-logs/task3-red.log" 2>&1; grep -E "✘|TEST (SUCCEEDED|FAILED)" "$SCRATCH/sdd-logs/task3-red.log" | head -20
```

Expected: 새 테스트 4개 실패(잊기 2개는 옛 항목이 남음, 되돌리기는 클록 302, 넘침은 값이 `inf`이거나 저장 실패로 파일 읽기 오류). Task 2 테스트는 통과.

- [x] **Step 3: 구현**

상수를 `defaultForgetAfter` 아래에 추가한다.

```swift
    /// 로딩할 때 기준 시점을 되돌리는 클록 경계(반감기 배수). 기본 반감기면 약 15만 단어에 한 번이다
    private static let loadRebaseLimit: Double = 300
    /// 입력 중 값이 넘치지 않도록 기준 시점을 되돌리는 경계(반감기 배수). `Double`은 약 2^1023까지다
    private static let recordRebaseLimit: Double = 900
```

`startBackgroundLoad()`에서 로드 분기 바로 뒤(`let applyLoadedData` 앞)에 넣는다.

```swift
            // 기준 시점 되돌리기와 잊기는 백그라운드에서 끝내고 메인에는 결과만 넘긴다
            if self.prepareLoadedData(&loaded) {
                needsSave = true
            }
```

private extension의 `// MARK: File I/O` 앞에 새 절을 추가한다.

```swift
    // MARK: Decay

    /// 로딩한 데이터의 기준 시점을 필요하면 되돌리고, 잊는 기간 동안 다시 쓰이지 않은 항목을 지웁니다.
    ///
    /// ponytail: 잊기는 로딩 때만 한다. 한 프로세스가 오래 살면 그 사이 기준 아래로 내려간 항목이 다음 로딩까지 남는다.
    /// 그 항목은 점수가 가장 낮아 상한 정리에서 먼저 지워지고 후보에는 맞는 다른 단어가 없을 때만 보인다.
    /// 확장 프로세스가 오래 사는 것이 실기기에서 확인되면 저장 주기에 맞춰 메모리에서도 지운다
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
```

`recordNGrams()`의 `clock += 1` 바로 뒤에 넣는다.

```swift
        if clock / halfLife > Self.recordRebaseLimit {
            Self.rebase(&unigramStore, &bigramStore, &trigramStore, clock: &clock, halfLife: halfLife)
        }
```

- [x] **Step 4: 통과 확인**

Task 2 Step 8과 같은 명령을 `task3-green.log`로 실행한다.

Expected: `** TEST SUCCEEDED **`, 실패 없음.

- [x] **Step 5: Commit**

이 문서의 Task 3 체크박스와 결과를 기록한 뒤:

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests.swift \
  docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
feat: #159 - 오래 쓰지 않은 NGram 학습을 로딩 때 지우고 기준 시점 되돌리기 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

**Task 3 결과:** (2026-09-27)
- Step 2(RED): 새 테스트 4개만 실패, 8 issues. 잊기 2개는 옛 항목이 남음(`suggestions` 불일치, 파일 bigram 불일치), 되돌리기는 `saved.clock == 1`·`w0 < 4` 실패, 넘침은 `clock == 199`·`isFinite`·첫 후보 실패. Task 2 테스트는 통과. 로그 `$SCRATCH/sdd-logs/task3-red.log`
- Step 4(GREEN): NGram 관련 11 suites 77 tests 전부 통과, 엔진 새 경고 없음. 로그 `$SCRATCH/sdd-logs/task3-green.log`

---

### Task 4: 변경 후 측정

**Files:**
- Create (커밋하지 않음): `SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift` (Task 1 파일 재사용)
- Modify: `docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md`

- [ ] **Step 1: 측정 코드 되돌려 놓고 라벨 변경**

```sh
cp "$SCRATCH/bench/ZZNGramDecayPerfTests.swift" SYKeyboardTests/Domain/
sed -i '' 's/private let label = "before"/private let label = "after"/' SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift
grep -n 'private let label' SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift
```

Expected: `private let label = "after"`.

- [ ] **Step 2: Task 1 Step 3과 같은 명령으로 실행** (로그 이름만 `task4-*`)

Expected: `perf-159.txt`에 `[after]` 줄이 시나리오별 6줄. 입력 파일은 옛 형식이라 변경 후에는 변환 경로를 탄다.

- [ ] **Step 3: 측정 코드 치우고 비교 기록**

```sh
rm SYKeyboardTests/Domain/ZZNGramDecayPerfTests.swift
git status --short
```

아래 「Task 4 결과」에 before/after 비교표(시나리오 × 첫 로딩·로딩 반복 중앙값·유지·peak 메모리·스페이스 1회 중앙값/p95/최대·16ms 초과·파일 크기)를 적는다.
스페이스 p95가 12ms를 넘거나 before보다 20% 이상 늘면 사용자에게 알리고 실기기 측정 여부를 묻는다(spec 「측정」). 파일 크기가 늘어난 비율도 적는다.

**Task 4 결과:** (실행 뒤 기록)

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
docs: #159 - 감쇠 점수 적용 뒤 NGram 입력 지연·메모리·파일 크기 측정 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: 문서 갱신

**Files:**
- Modify: `docs/architecture/자동완성 로직.md` (§2-3 NGram 표, 테스트 표, 실행 명령)
- Modify: `docs/architecture/성능 고려 사항.md` (§2-2 표기 묶기 행, §2-3, §2-7 키당 24개 행·`ponytail` 표, §3-3 뒤 새 절 §3-5, §7 테스트 표)
- Modify: `docs/architecture/전체 아키텍처.md:206`
- Modify: `README.md:879`
- Modify: `docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md`

- [ ] **Step 1: `자동완성 로직.md` §2-3 NGram 표**

- 「조회」 행: "3순위 unigram(빈도순 보충)" → "3순위 unigram(점수순 보충)", "(trigram/bigram은 문자 종류와 무관하게 빈도순)" → "(trigram/bigram은 문자 종류와 무관하게 점수순)", "unigram이 바뀔 때 무효화" 뒤에 "(시간이 지나도 순서가 바뀌지 않아 기록할 때만 무효화)"를 붙인다. 완성 설명의 "빈도순으로 먼저, 남은 칸은 unigram 빈도순" → "점수순으로 먼저, 남은 칸은 unigram 점수순", "합친 빈도로" → "합친 점수로".
- 「기록」 행을 바꾼다:

  ```
  | 기록 | `addWord(_:)`가 문장 버퍼(`currentSentenceWords`)에 쌓으며 unigram/bigram/trigram 동시 기록. 점수는 쓸 때마다 +1, 입력 단어 `halfLife`(500)개마다 절반인 지수 감쇠다(#159). 메모리 값은 기준 시점으로 환산한 `Σ 2^(사용 시점 / halfLife)`이고 클록(`clock`, 기록한 단어 수)은 기록할 때만 늘어 키보드를 쓰지 않는 동안에는 줄지 않는다. 값끼리 바로 비교·합산한다 |
  ```

- 「상한」 행: "빈도 낮은 것부터 정리" → "점수 낮은 것부터 정리", "unigram은 빈도, bigram·trigram 키(`pruneKeys`)는 총 빈도가" → "unigram은 점수, bigram·trigram 키(`pruneKeys`)는 총점이". 행 끝에 "같은 횟수면 먼저 쓴 것이 점수가 낮아 먼저 지워진다"를 붙인다.
- 「상한」 행 다음에 새 행을 넣는다:

  ```
  | 잊기 | 현재 점수가 `2^(-forgetAfter / halfLife)`(`forgetAfter` 10,000단어) 아래인 항목은 상한과 관계없이 백그라운드 로딩 때 지우고, 비게 된 문맥 키도 지운다. 한 번 쓴 항목은 10,000단어, 자주 쓰던 항목은 `10,000 + 500 × log2(쉬기 직전 점수)`단어 동안 다시 쓰이지 않으면 지워진다. 입력 중에는 하지 않는다(`prepareLoadedData`, `ponytail:` 주석). 클록이 `halfLife`의 300배를 넘으면 로딩 때 값을 현재 점수로 환산해 클록을 0으로 되돌리고, 입력 중 900배를 넘으면 메모리에서 같은 일을 한다(`rebase`) |
  ```

- 「디스크 저장」 행 끝에 "파일은 저장 형식 2(`version`, `clock`, `Double` 값)"를 붙인다.
- 「마이그레이션」 행을 바꾼다:

  ```
  | 마이그레이션 | 레거시 `UserDefaults` 키(1.6.0~1.6.2) 발견 시 변환해 새 형식 파일로 쓰고 키 제거. 옛 빈도 형식 파일(1.6.3, #159 이전)은 로딩 때 변환하고 다음 저장에서 새 형식으로 쓴다. 변환은 `converted(_:)` 하나이고 빈도에 `min(1, halfLife / (ln2 × unigram 빈도 합))`을 곱해, 그 비율대로 계속 써 왔을 때의 점수로 옮긴다(항목 사이 순서 유지). 컨테이너 루트 → `Library/Application Support` 파일 이동은 저장소 행 참조. 옛 빌드는 새 형식을 읽지 못해 학습이 초기화된다(TestFlight 테스터만 해당) |
  ```

- [ ] **Step 2: `자동완성 로직.md` 테스트 표와 실행 명령**

「n-gram 단어 삭제」 행 아래에 넣는다:

```
| n-gram 감쇠 점수(최근 사용 반영, 같은 횟수 정리 순서, 저장 형식·클록, 옛 형식 변환, 잊기, 기준 시점 되돌리기) | `SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests` |
```

「n-gram 파일 위치 이동」 행은 "n-gram 파일 위치 이동, 옛 위치 옛 형식 파일 변환"으로 바꾼다. 실행 명령 블록의 `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests \` 다음 줄에 `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineDecayTests \`를 넣는다.

- [ ] **Step 3: `성능 고려 사항.md`**

- §2-2 「대소문자가 없는 단어…」 행: "빈도가 같은 후보의 순서를 빼면" → "점수가 같은 후보의 순서를 빼면".
- §2-3 표 맨 아래에 행을 추가한다:

  ```
  | 감쇠는 저장값을 바꾸지 않고 기준 시점 값으로 한다 | 쓸 때 `2^(clock/halfLife)`를 더하면 시간이 지나도 순서가 그대로라 비교·합·순위 캐시가 빈도 때와 같다. 저장할 때 현재 점수로 환산하면 10단어마다 전체 복사본이 생기므로 클록을 함께 저장하고, 되돌리기는 로딩 때(백그라운드)만 한다. 입력 경로 추가 비용은 `addWord`마다 `exp2` 한 번이다(§3-5) | `NGramPredictiveTextEngine.recordNGrams`, `prepareLoadedData` |
  ```

- §2-7 「NGram 키당 항목은 24개…」 행: "순위 변동용 빈도다" → "순위 변동용 점수다". 행 끝에 "오래 쓰지 않은 항목은 로딩 때 지워(#159) 보통 사용에서는 상한까지 차지 않는다(시뮬레이션에서 잊기 없음의 약 1/4)"를 붙인다.
- `ponytail:` 표 앞 문장 "현재 4곳이다" → "현재 5곳이다", 표 첫 행 아래에 넣는다:

  ```
  | `NGramPredictiveTextEngine.prepareLoadedData` | 잊기를 로딩 때만 해서 오래 사는 프로세스에서는 기준 아래 항목이 다음 로딩까지 남는다 | 확장 프로세스가 오래 사는 것이 실기기에서 확인되면 저장 주기에 맞춰 메모리에서도 지운다 |
  ```

- §3-3 끝의 "남은 p95는 새 문맥이 생길 때마다 키 전체의 빈도 합을 한 번 훑는 비용이다" → "…키 전체의 총점(#159 이전에는 빈도 합)을 한 번 훑는 비용이다".
- §3-4 뒤(§4 앞)에 새 절 `### 3-5. NGram 감쇠 점수 (#159)`를 넣고, Task 1·4 결과의 before/after 표와 측정 조건(시뮬레이터 iPhone 13 mini / iOS 18.6, `-O`, 0.2초 간격 150단어, 12단어마다 `endSentence()`, 옛 형식 입력을 변환해 로딩), 파일 크기 변화, 반감기·잊는 기간 결정 근거는 spec 「반감기·잊는 기간 결정 근거」를 가리키는 한 줄을 적는다. 실기기 측정은 하지 않았다는 사실과 그 기준(스페이스 p95 12ms)을 적는다.
- §7 테스트 표에 넣는다:

  ```
  | NGram 감쇠 점수·옛 형식 변환·잊기·기준 시점 되돌리기 | `SYKeyboardTests/Domain/NGramPredictiveTextEngineDecayTests` |
  ```

- [ ] **Step 4: `전체 아키텍처.md:206`, `README.md:879`**

`전체 아키텍처.md` 206행 설명 칸 끝에 "저장 형식 2(점수 값·클록)이고, 옛 빈도 형식과 레거시 `UserDefaults` 데이터는 로딩 때 변환한다(#159)"를 붙인다.

`README.md` 879행 문장 끝에 붙인다: " 자주 쓰고 최근에 쓴 표현일수록 먼저 추천하고, 오래 쓰지 않은 학습은 자동으로 지워집니다."

- [ ] **Step 5: 확인과 Commit**

```sh
grep -n "빈도" "docs/architecture/자동완성 로직.md" "docs/architecture/성능 고려 사항.md" | grep -iE "ngram|n-gram|unigram|bigram|trigram|키당|pruneKeys|표기"
```

Expected: NGram 순위·정리를 "빈도"로 설명하는 줄이 남지 않는다(§3-3의 "#159 이전에는 빈도 합", 마이그레이션 행의 "옛 빈도 형식"은 의도한 표현). 남은 줄이 있으면 고친다.

```bash
git add "docs/architecture/자동완성 로직.md" "docs/architecture/성능 고려 사항.md" "docs/architecture/전체 아키텍처.md" README.md docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
docs: #159 - README·아키텍처 문서에 NGram 감쇠 점수·잊기·저장 형식 변환과 측정 결과 반영

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

**Task 5 결과:** (실행 뒤 기록)

---

### Task 6: 전체 검증과 시뮬레이터 입력 앱 확인

**Files:**
- Modify: `docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md`

- [ ] **Step 1: 전체 테스트**

사용자에게 수 분 걸린다고 알린다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  > "$SCRATCH/sdd-logs/task6-full.log" 2>&1; grep -E "✘|Test run with|Executed|TEST (SUCCEEDED|FAILED)" "$SCRATCH/sdd-logs/task6-full.log" | tail -10
```

Expected: `** TEST SUCCEEDED **`, 실패 없음. 테스트·suite 개수를 기록한다.

- [ ] **Step 2: 4개 scheme 빌드**

```sh
for s in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$s" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$SCRATCH/sdd-logs/task6-build-$s.log" 2>&1; echo "$s: $(tail -1 "$SCRATCH/sdd-logs/task6-build-$s.log")"
done
git status --short
```

Expected: 4개 모두 `** BUILD SUCCEEDED **`. `.xcscheme` `RemotePath`만 바뀌었으면 되돌린다.

- [ ] **Step 3: 시뮬레이터 입력 앱 확인 준비 (1.6.3 업데이트 재현)**

`reference-idb-simulator-quirks` 메모리의 조작 방법을 따른다. 기준 시뮬레이터 UDID를 `xcrun simctl list devices booted`로 확인하고(`$UDID`), 방금 빌드한 앱을 설치한다.

```sh
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/SYKeyboard-*/Build/Products/Debug-iphonesimulator/SYKeyboard.app | head -1)
xcrun simctl install "$UDID" "$APP"
GROUP=$(xcrun simctl get_app_container "$UDID" github.com-SNMac.SYKeyboard group.github.com-SNMac.SYKeyboard)
mkdir -p "$SCRATCH/sim-backup"
cp "$GROUP/Library/Application Support/ngram_ko-KR.plist" "$SCRATCH/sim-backup/" 2>/dev/null || echo "원본 없음"
python3 - "$GROUP/Library/Application Support/ngram_ko-KR.plist" <<'EOF'
import plistlib, sys
# 1.6.3과 같은 옛 빈도 형식. 오늘 뒤에는 날씨(3)가 회의(2)보다 앞이다
data = {"unigram": {"오늘": 5, "날씨": 3, "회의": 2, "안녕": 9},
        "bigram": {"오늘": {"날씨": 3, "회의": 2}},
        "trigram": {}}
with open(sys.argv[1], "wb") as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)
EOF
plutil -p "$GROUP/Library/Application Support/ngram_ko-KR.plist"
```

떠 있는 한글 키보드 확장 프로세스가 있으면 호스트에서 끝낸다: `pgrep -fl HangeulKeyboard` → `kill -9 <pid>`.

- [ ] **Step 4: 입력 앱에서 확인**

`xcrun simctl openurl "$UDID" "sms:010"`로 메시지 작성 화면을 띄우고 한글 키보드(SY키보드 한글)로 바꾼다(메모리: `AppleKeyboards`를 두 개로 줄여 전환, 끝나면 원래 배열로 복원). 각 단계를 `xcrun simctl io "$UDID" screenshot "$SCRATCH/sim-<n>.png"`로 캡처해 확인한다.

1. 입력란이 빈 상태의 후보 바 첫 칸이 `안녕`이다(변환 뒤에도 unigram 순서 유지).
2. `오늘` + 스페이스 뒤 후보가 `날씨`, `회의` 순이다(문맥 순서 유지).
3. `회의`를 후보에서 골라 넣고 리턴, 다시 `오늘` + 스페이스 → `회의`를 한 번 더 고르고 리턴한 뒤, `오늘` + 스페이스 후보가 `회의`, `날씨` 순이다(새로 쓴 표현이 앞으로 옴).
4. 작성 취소로 키보드를 내린 뒤(저장) `plutil -p`로 파일을 보면 `version => 2`, `clock`이 있고 값이 실수다.

- [ ] **Step 5: 원래 상태로 복원**

```sh
pgrep -fl HangeulKeyboard   # 있으면 kill -9
cp "$SCRATCH/sim-backup/ngram_ko-KR.plist" "$GROUP/Library/Application Support/ngram_ko-KR.plist" 2>/dev/null \
  || rm "$GROUP/Library/Application Support/ngram_ko-KR.plist"
```

`AppleKeyboards`를 바꿨다면 원래 배열로 되돌린다. 복원한 파일은 옛 형식일 수 있으며, 다음 로딩 때 변환된다.

- [ ] **Step 6: 기록과 Commit**

「Task 6 결과」에 전체 테스트 개수, 4개 빌드 결과, 입력 앱 확인 1~4의 결과와 캡처 경로를 적는다. 입력 앱 확인은 시뮬레이터 확인으로 실기기 확인을 대신한다(사용자 결정). 조작이 막혀 확인하지 못한 항목은 차단 경로와 함께 "미확인"으로 적는다.

```bash
git add docs/superpowers/plans/2026-09-27-issue-159-ngram-decay-score.md
git commit -F - <<'EOF'
docs: #159 - 전체 테스트·4개 scheme 빌드·시뮬레이터 입력 앱 확인 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

**Task 6 결과:** (실행 뒤 기록)
