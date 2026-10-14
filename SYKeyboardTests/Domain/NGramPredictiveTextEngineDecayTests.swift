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
        let a = try #require(saved.unigram["a"])
        let b = try #require(saved.unigram["b"])
        let ab = try #require(saved.bigram["a"]?["b"])
        #expect(saved.version == 2)
        #expect(saved.clock == 0)
        // 전체 4000회·반감기 500일 때 배율 약 0.18034 (3000:1000:400 비율 유지)
        #expect(abs(a - 541.0106403333614) < 1e-9)
        #expect(abs(b - 180.33688011112045) < 1e-9)
        #expect(abs(ab - 72.13475204444818) < 1e-9)
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
        let a = try #require(saved.unigram["a"])
        let ab = try #require(saved.bigram["a"]?["b"])
        #expect(saved.version == 2)
        // 전체 4000회·반감기 500일 때 배율 약 0.18034 (3000:400 비율 유지)
        #expect(abs(a - 541.0106403333614) < 1e-9)
        #expect(abs(ab - 72.13475204444818) < 1e-9)
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
