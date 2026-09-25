# 한영 통합 키보드 통합 NGram Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한영 통합 키보드가 언어 모드와 무관한 NGram 하나(`ngram_ko-en.plist`)로 학습·예측하고, 언어 전환 경계를 넘는 문맥과 'SY키보드'처럼 섞인 단어를 학습한다.

**Architecture:** `SuggestionController`에서 NGram 식별자를 TextChecker 언어와 분리해 한영 키보드만 `"ko-en"` 엔진 하나를 쓴다. NGram 기록·조회·문장 버퍼 동기화는 `BaseKeyboardViewController`가 `inputBuffer` 전체로 하고, 단어 완성·자동 대치는 지금처럼 언어 구간을 본다. 무엇을 넘길지는 새 순수 policy(`KeyboardNGramContextPolicy`)가 정하고, unigram 후보의 언어 우선 정렬은 엔진이 `PredictiveTextScriptPolicy`로 한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26 이상, binary plist(`PropertyListEncoder`/`Decoder`)

**Spec:** `docs/superpowers/specs/2026-09-25-hangeul-english-unified-ngram-design.md`

## Global Constraints

- 작업 브랜치는 `feat/#157-unified-ngram`이다(`develop` 위, spec 커밋 `d68a9d02`).
- 커밋 메시지는 `type: #157 - subject` 형식, 한국어, 마침표 없음. 끝에 아래 줄을 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.

  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  ```

- CLAUDE.md 「Superpowers 계획 실행」을 따른다. step은 작업과 검증이 모두 끝난 직후에만 체크한다. **Task마다 마지막 커밋 step에서** 그 Task의 코드·테스트와 이 문서(체크박스, 실제 결과: 테스트 개수, 빌드 결과, 확인하지 못한 항목)를 한 커밋으로 남긴다. 다음 Task는 직전 Task 커밋 뒤에 시작한다.
- 식별자·수치는 spec 그대로다. 통합 NGram 식별자 `"ko-en"`, 파일 `ngram_ko-en.plist`, 통합 `maxKeys` 10000, 언어별 `maxKeys` 5000, `maxEntriesPerKey` 24(변경 없음).
- 기존 ko/en 학습을 통합 파일로 **합치지 않는다.** 설정 화면 안내 문구도 넣지 않는다.
- 단독 한글·영어 키보드의 동작은 바꾸지 않는다. 단독 키보드는 언어 구간(`currentLanguageInputBuffer`)과 `inputBuffer`가 같으므로, 모든 새 규칙은 두 값이 같을 때 기존 결과를 그대로 내야 한다.
- 공백이 든 NGram 단어는 입력 중 후보 선택 경로(`handleInputBufferSuggestion`)에서만 지금처럼 생긴다. 다른 경로와 새 코드는 공백 든 단어를 만들지 않는다. 이 경로에 공백 필터를 넣지 않는다.
- NGram 후보 앞 공백 삽입(`shouldInsertLeadingSpaceBeforeNGramSuggestion`)은 언어 구간 기준을 유지한다(`"오늘meeting"` 붙임 동작 불변).
- `PropertyListSerialization`으로 바꾸지 않는다(spec 6-1).
- **`Modules/`에 새 파일을 만들면 `SYKeyboard.xcodeproj/project.pbxproj`를 함께 고친다.** `Exceptions for "Modules" folder in "SYKeyboard" target`과 `... in "SYKeyboardCore" target` 두 `membershipExceptions` 목록에 알파벳 순서로 경로를 넣는다. 안 넣으면 `cannot find ... in scope`로 컴파일이 실패한다. `SYKeyboardTests/`의 새 테스트 파일은 pbxproj를 고치지 않는다.
- 테스트 기준 기기는 `iPhone 13 mini / iOS 18.6`이다. 테스트 명령에는 반드시 아래 두 옵션을 붙인다. 빼면 테스트 호스트가 AdMob 초기화에서 크래시한다.

  ```sh
  xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    -parallel-testing-enabled NO \
    GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
    -only-testing:SYKeyboardTests/<SuiteType>
  ```

  `<SuiteType>`은 `@Suite` 표시 이름이 아니라 **타입 이름**이다. 로그는 scratchpad 파일로 남기고 `tail`로 결과만 본다.
- `xcodebuild`는 수 분 걸린다. 실행 전에 사용자에게 오래 걸린다고 알린다. 서브에이전트에 맡길 때는 foreground로 `timeout: 600000`을 주고, 몇 분씩 진행이 없으면 기다리지 말고 보고하게 한다(CLAUDE.md 「호스트 앱이 뜨지도 않고 테스트가 매달리는 경우」, 「붙여넣기 권한 알림으로 테스트가 끝나지 않는 경우」). 이 두 경우는 코드 실패로 기록하지 않는다.
- extension scheme을 빌드할 때는 `-only-testing`과 code coverage 옵션을 비운다. 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌리고 커밋하지 않는다. 다른 항목이 바뀌었으면 되돌리지 말고 사용자에게 알린다.
- `SYKeyboard/Resources/Configs/Secrets.xcconfig`, Firebase, AdMob, entitlements, bundle 설정은 건드리지 않는다.
- `git add`는 항상 파일을 명시한다. push·PR 생성은 사용자가 명시할 때만 한다.
- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)이고 production 진입점을 호출한다. production 클래스에 `ForTesting` 메서드를 넣지 않는다.

### spec과 다르게 가는 곳

1. **통합 `maxKeys` 전달 방식.** spec 2절은 "convenience `init(language:)`에 `maxKeys`를 넘길 수 있게"라고 썼다. 엔진 팩토리(`makeNGramEngine: (String) -> ...`)와 설정 화면 초기화가 모두 `init(language:)`로 엔진을 만들므로, 인자를 늘리는 대신 엔진이 식별자로 정한다(`NGramPredictiveTextEngine.maxKeys(forLanguage:)`). 호출부가 수치를 알 필요가 없어 두 곳이 어긋날 일이 없다.
2. **`handleNGramSuggestion(at:)` 이후 갱신 문맥.** spec 3절 표는 "policy로 계산"이라고 썼다. 그런데 NGram 후보를 넣은 직후 버퍼는 공백으로 끝나지 않아 policy가 언어 구간을 돌려주고, 한영 전환 뒤 "오늘 " → "meeting"을 고르면 trigram 문맥 `"오늘 meeting"`을 잃는다. 넣은 것은 완성된 단어이므로 `inputBuffer` 전체를 그대로 넘긴다. 단독 키보드는 두 값이 같아 결과가 같다.
3. **`BaseKeyboardViewController` 시나리오 테스트.** spec 테스트 절은 VC 경로 시나리오('SY'→전환→'키보드'→스페이스 등)를 VC 테스트로 적었다. VC의 `suggestionController`는 `private let`이고 `textDocumentProxy`를 주입할 수 없으며, CLAUDE.md는 `ForTesting` 메서드를 금지한다. 그래서 VC가 NGram에 무엇을 넘길지를 전부 `KeyboardNGramContextPolicy`에 두고 그 policy를 시나리오별로 테스트한다(Task 5). VC는 policy 결과를 그대로 넘기는 배선만 하고, 배선은 빌드와 실제 입력 앱 확인(Task 8)으로 검증한다.
4. **"통합 엔진이 ko/en 파일이 있어도 빈 상태로 시작" 테스트.** 합치기를 뺀 뒤로 엔진은 자기 파일만 읽으므로 이 테스트는 파일 경로가 다르다는 것만 확인하게 된다. 대신 한영 설정의 컨트롤러가 `"ko-en"` 엔진 하나만 만들고 ko/en 엔진을 만들지 않는지(Task 3), 통합 식별자의 `maxKeys`가 10000인지(Task 2)를 테스트한다.

## Review Focus

- 통합 엔진이 디스크를 읽는 도중 한영 전환을 하면, 로딩이 끝났을 때 후보가 갱신되어야 한다. 지금은 언어 전환이 `engineGeneration`을 올려 로딩 완료 콜백을 버리므로 통합 엔진에서는 후보가 빈 채로 남을 수 있다 → Task 3 테스트 `test통합NGram로딩중언어를바꿔도_로딩완료뒤후보를갱신`.
- '오늘 ' → 한영 전환 → 백스페이스: 공백 하나만 지웠으므로 NGram 문장 버퍼에서 "오늘"만 빠지고 문맥 전체가 초기화되면 안 된다. 지금은 언어 구간이 비어 있어 초기화된다 → Task 5 테스트 `test한영전환직후_경계를넘어공백을지우면_마지막단어만뺌`.
- 텍스트를 선택한 상태에서는 NGram 문맥도 지금처럼 선택 텍스트여야 한다(수식 selection 계약) → Task 5 테스트 `test선택영역이있으면_선택텍스트를문맥으로씀`.
- NGram 후보를 길게 눌러 지운 뒤 다시 조회할 때도 전체 버퍼 문맥을 써야 한다. 언어 구간으로 새면 후보가 unigram으로 바뀐다 → Task 4 테스트 `test후보삭제뒤재조회는_마지막NGram문맥을씀`.
- 현재 모드 문자 종류 단어가 10개보다 적으면 나머지 칸은 다른 문자 종류가 빈도순으로 채워야 하고, 10개 이상이면 다른 문자 종류는 밀려나야 한다 → Task 2 테스트 `test선호문자종류단어가부족하면_나머지를빈도순으로채움`, `test선호문자종류단어가10개이상이면_상위10개만`.

---

### Task 1: 문자 종류 판별 policy

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (`membershipExceptions` 두 곳)
- Test: `SYKeyboardTests/Utils/PredictiveTextScriptPolicyTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `enum PredictiveTextScript: Hashable { case hangeul, latin, other }`
  - `PredictiveTextScriptPolicy.script(of word: String) -> PredictiveTextScript`
  - `PredictiveTextScriptPolicy.preferredScript(forLanguage language: String) -> PredictiveTextScript?`

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/PredictiveTextScriptPolicyTests.swift`:

```swift
//
//  PredictiveTextScriptPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("NGram 후보 문자 종류 판별 검증")
struct PredictiveTextScriptPolicyTests {

    @Test("한글이 하나라도 있으면 한글", arguments: ["오늘", "ㅋㅋ", "SY키보드", "iOS용", "ᄀ"])
    func test한글이하나라도있으면_한글(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .hangeul)
    }

    @Test("한글 없이 라틴 문자가 있으면 라틴", arguments: ["meeting", "café", "iOS18", "Straße", "don't"])
    func test한글없이라틴문자가있으면_라틴(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .latin)
    }

    @Test("한글도 라틴 문자도 없으면 기타", arguments: ["123", "😀", "×÷", "...", ""])
    func test한글도라틴문자도없으면_기타(word: String) {
        #expect(PredictiveTextScriptPolicy.script(of: word) == .other)
    }

    @Test("언어 모드 식별자에서 선호 문자 종류를 정함")
    func test언어모드식별자에서_선호문자종류를정함() {
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "ko-KR") == .hangeul)
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "en-US") == .latin)
        #expect(PredictiveTextScriptPolicy.preferredScript(forLanguage: "ko-en") == nil)
    }
}
```

- [x] **Step 2: 테스트가 실패하는 것을 확인한다**

Run: Global Constraints의 테스트 명령, `-only-testing:SYKeyboardTests/PredictiveTextScriptPolicyTests`

Expected: 컴파일 실패. `cannot find 'PredictiveTextScriptPolicy' in scope`

Result: Confirmed compilation error as expected

- [x] **Step 3: policy를 만든다**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift`:

```swift
//
//  PredictiveTextScriptPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/25/26.
//

import Foundation

/// NGram 후보 단어의 문자 종류
enum PredictiveTextScript: Hashable {
    case hangeul
    case latin
    case other
}

/// 한영 통합 NGram에서 unigram 후보를 현재 언어 모드 순으로 세우기 위한 문자 종류 판별
enum PredictiveTextScriptPolicy {

    /// 한글이 하나라도 있으면 한글, 아니고 라틴 문자가 있으면 라틴, 둘 다 없으면 기타로 본다.
    /// 'SY키보드'처럼 섞인 단어는 한글이다
    static func script(of word: String) -> PredictiveTextScript {
        var hasLatin = false
        for scalar in word.unicodeScalars {
            if isHangeul(scalar) { return .hangeul }
            if isLatinLetter(scalar) { hasLatin = true }
        }
        return hasLatin ? .latin : .other
    }

    /// 언어 모드 식별자에서 먼저 보여줄 문자 종류를 정한다. 모르는 식별자는 `nil`이다
    static func preferredScript(forLanguage language: String) -> PredictiveTextScript? {
        switch language {
        case "ko-KR":
            return .hangeul
        case "en-US":
            return .latin
        default:
            return nil
        }
    }

    private static func isHangeul(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xAC00...0xD7A3, // 음절
             0x1100...0x11FF, // 자모
             0x3130...0x318F, // 호환 자모
             0xA960...0xA97F, // 자모 확장 A
             0xD7B0...0xD7FF: // 자모 확장 B
            return true
        default:
            return false
        }
    }

    private static func isLatinLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x41...0x5A, 0x61...0x7A:
            return true
        case 0xC0...0x24F:
            // Latin-1 보충·확장 A/B의 문자만. `×`, `÷`는 기호라 빠진다
            return scalar.properties.isAlphabetic
        default:
            return false
        }
    }
}
```

- [x] **Step 4: pbxproj 두 목록에 파일을 넣는다**

`SYKeyboard.xcodeproj/project.pbxproj`에서 아래 줄은 두 번 나온다(SYKeyboard 타깃, SYKeyboardCore 타깃).

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift,
```

두 곳 모두 그 바로 아래에 다음 줄을 넣는다(탭 4개 들여쓰기).

```
				SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift,
```

확인:

```sh
grep -c "Policies/PredictiveTextScriptPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [x] **Step 5: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: `PredictiveTextScriptPolicyTests` 4개 테스트(인자 포함 16건) 통과

Result: All 4 test functions passed (16 test cases: 5+5+5+1). Suite passed in 0.023 seconds

- [x] **Step 6: 커밋**

이 문서의 Task 1 체크박스와 결과를 갱신한 뒤:

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/PredictiveTextScriptPolicyTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - NGram 후보 문자 종류 판별 정책 추가" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: 엔진의 통합 식별자와 unigram 문자 종류 우선 정렬

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
  - `unigramStore`·`rankedUnigramCache` 선언(약 86-92행)
  - convenience `init(language:)`(약 176-197행)
  - `suggestions(for:)`(약 286-333행)
  - `rankedUnigramCandidates()`(약 661-679행)
- Test: `SYKeyboardTests/Domain/NGramPredictiveTextEngineScriptPreferenceTests.swift`

**Interfaces:**
- Consumes: Task 1의 `PredictiveTextScript`, `PredictiveTextScriptPolicy.script(of:)`
- Produces:
  - `public static let NGramPredictiveTextEngine.hangeulEnglishLanguage: String` (`"ko-en"`)
  - `static func NGramPredictiveTextEngine.maxKeys(forLanguage: String) -> Int`
  - `func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String]`
  - 기존 `func suggestions(for baseText: String) -> [String]`는 `preferredScript: nil`과 같다

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineScriptPreferenceTests.swift`:

```swift
//
//  NGramPredictiveTextEngineScriptPreferenceTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram unigram 후보 문자 종류 우선 정렬 검증")
struct NGramPredictiveTextEngineScriptPreferenceTests {

    @Test("선호 문자 종류가 없으면 기존처럼 빈도순")
    func test선호문자종류가없으면_기존처럼빈도순() async {
        let engine = await makeMixedEngine(name: "script-none")

        #expect(engine.suggestions(for: "") == ["meeting", "오늘", "123", "SY키보드", "hello"])
        #expect(engine.suggestions(for: "", preferredScript: nil) == ["meeting", "오늘", "123", "SY키보드", "hello"])
    }

    @Test("선호 문자 종류를 앞에 두고 각 묶음 안은 빈도순")
    func test선호문자종류를앞에두고_각묶음안은빈도순() async {
        let engine = await makeMixedEngine(name: "script-prefer")

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == ["오늘", "SY키보드", "meeting", "123", "hello"])
        #expect(engine.suggestions(for: "", preferredScript: .latin) == ["meeting", "hello", "오늘", "123", "SY키보드"])
    }

    @Test("학습으로 순위가 바뀌면 선호 정렬 후보도 갱신")
    func test학습으로순위가바뀌면_선호정렬후보도갱신() async {
        let engine = await makeMixedEngine(name: "script-invalidate")
        #expect(engine.suggestions(for: "", preferredScript: .latin).first == "meeting")

        record(engine, word: "hello", times: 10)

        #expect(engine.suggestions(for: "", preferredScript: .latin) == ["hello", "meeting", "오늘", "123", "SY키보드"])
    }

    @Test("선호 문자 종류 단어가 부족하면 나머지를 빈도순으로 채움")
    func test선호문자종류단어가부족하면_나머지를빈도순으로채움() async {
        let engine = await makeLoadedNGramFixture(name: "script-fill").engine
        record(engine, word: "alpha", times: 9)
        record(engine, word: "bravo", times: 8)
        record(engine, word: "가나", times: 1)

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == ["가나", "alpha", "bravo"])
    }

    @Test("선호 문자 종류 단어가 10개 이상이면 상위 10개만")
    func test선호문자종류단어가10개이상이면_상위10개만() async {
        let engine = await makeLoadedNGramFixture(name: "script-overflow").engine
        let hangeulWords = ["가", "나", "다", "라", "마", "바", "사", "아", "자", "차", "카", "타"]
        for (index, word) in hangeulWords.enumerated() {
            record(engine, word: word, times: 20 - index)
        }
        record(engine, word: "meeting", times: 50)

        #expect(engine.suggestions(for: "", preferredScript: .hangeul) == Array(hangeulWords.prefix(10)))
    }

    @Test("문맥 후보는 선호 문자 종류와 무관하게 빈도순")
    func test문맥후보는_선호문자종류와무관하게빈도순() async {
        let engine = await makeLoadedNGramFixture(name: "script-context").engine
        recordSentence(engine, words: ["오늘", "meeting"])
        recordSentence(engine, words: ["오늘", "날씨"])
        recordSentence(engine, words: ["오늘", "날씨"])

        #expect(Array(engine.suggestions(for: "오늘 ", preferredScript: .latin).prefix(2)) == ["날씨", "meeting"])
        #expect(Array(engine.suggestions(for: "오늘 ", preferredScript: .hangeul).prefix(2)) == ["날씨", "meeting"])
    }

    @Test("통합 식별자만 키 상한이 10000")
    func test통합식별자만_키상한이10000() {
        #expect(NGramPredictiveTextEngine.hangeulEnglishLanguage == "ko-en")
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "ko-en") == 10000)
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "ko-KR") == 5000)
        #expect(NGramPredictiveTextEngine.maxKeys(forLanguage: "en-US") == 5000)
    }
}

// MARK: - Helpers

/// 빈도: meeting 5, 오늘 4, 123 3, SY키보드 2, hello 1
private func makeMixedEngine(name: String) async -> NGramPredictiveTextEngine {
    let engine = await makeLoadedNGramFixture(name: name).engine
    record(engine, word: "meeting", times: 5)
    record(engine, word: "오늘", times: 4)
    record(engine, word: "123", times: 3)
    record(engine, word: "SY키보드", times: 2)
    record(engine, word: "hello", times: 1)
    return engine
}

private func record(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
    for _ in 0..<times {
        engine.addWord(word)
    }
}

private func recordSentence(_ engine: NGramPredictiveTextEngine, words: [String]) {
    for word in words {
        engine.addWord(word)
    }
    engine.endSentence()
}
```

- [x] **Step 2: 테스트가 실패하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineScriptPreferenceTests`

Expected: 컴파일 실패. `extra argument 'preferredScript' in call`, `type 'NGramPredictiveTextEngine' has no member 'hangeulEnglishLanguage'`

Result: 예상대로 컴파일 실패(xcodebuild exit 65). `extra argument 'preferredScript' in call`(6회), `type 'NGramPredictiveTextEngine' has no member 'hangeulEnglishLanguage'`, `'maxKeys' is inaccessible due to 'private' protection level`(3회) 확인. 로그: scratchpad `sdd-logs/task2-red.log`

- [x] **Step 3: 통합 식별자와 키 상한 규칙을 넣는다**

`// MARK: - Properties` 바로 아래(`private lazy var logger` 위)에 넣는다.

```swift
    /// 한영 통합 키보드가 쓰는 통합 NGram 식별자. 파일은 `ngram_ko-en.plist`다
    public static let hangeulEnglishLanguage = "ko-en"

    /// 식별자별 전체 키 최대 개수.
    ///
    /// 통합 NGram은 두 언어가 한 파일을 나눠 쓰므로, 한영 키보드가 언어별 엔진 2개로
    /// 쓰던 용량(5000 + 5000)과 메모리 최대치에 맞춘다
    static func maxKeys(forLanguage language: String) -> Int {
        language == hangeulEnglishLanguage ? 10000 : 5000
    }
```

convenience `init(language:)`의 `self.init(...)` 호출에 `maxKeys`를 넘긴다.

```swift
        self.init(
            language: language,
            fileURL: fileURL,
            legacyFileURL: legacyFileURL,
            legacyStorage: legacyStorage,
            loadApplyScheduler: nil,
            maxKeys: Self.maxKeys(forLanguage: language)
        )
```

- [x] **Step 4: unigram 순위 캐시를 선호 문자 종류별로 바꾼다**

기존:

```swift
    private var unigramStore: [String: Int] = [:] {
        didSet { rankedUnigramCache = nil }
    }
    /// `rankedUnigramCandidates()` 결과 캐시. unigram이 바뀌지 않은 연속 스페이스 입력에서 계산을 건너뛴다
    private var rankedUnigramCache: [String]?
```

변경:

```swift
    private var unigramStore: [String: Int] = [:] {
        didSet { rankedUnigramCache.removeAll() }
    }
    /// 선호 문자 종류별 `rankedUnigramCandidates(preferredScript:)` 결과 캐시.
    /// unigram이 바뀌지 않은 연속 스페이스 입력에서 계산을 건너뛴다
    private var rankedUnigramCache: [PredictiveTextScript?: [String]] = [:]
```

- [x] **Step 5: `suggestions(for:preferredScript:)`를 만든다**

기존 `func suggestions(for baseText: String) -> [String] {` 한 줄을 아래로 바꾼다. 기존 문서 주석은 짧은 `suggestions(for:)` 위에 그대로 남는다.

```swift
    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, preferredScript: nil)
    }

    /// `preferredScript`가 있으면 unigram 후보(문맥 없음, 남은 칸 보충)만 그 문자 종류를 앞에 둡니다.
    /// trigram·bigram 후보는 문자 종류와 무관하게 빈도순입니다.
    ///
    /// - Parameters:
    ///   - baseText: 자동완성을 제공할 텍스트 (`inputBuffer`)
    ///   - preferredScript: unigram 후보에서 먼저 보여줄 문자 종류. `nil`이면 빈도순만 따른다
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] {
```

그 아래 기존 본문(`guard isLoaded else { return [] }`부터 `return results`까지)은 그대로 두고 두 줄만 바꾼다.

```swift
        if words.isEmpty {
            return rankedUnigramCandidates(preferredScript: preferredScript)
        }
```

```swift
            for word in rankedUnigramCandidates(preferredScript: preferredScript) {
```

- [x] **Step 6: `rankedUnigramCandidates(preferredScript:)`를 만든다**

기존 `func rankedUnigramCandidates() -> [String] { ... }` 전체를 아래로 바꾼다.

```swift
    /// 빈도순으로 정렬된 unigram 후보를 반환합니다.
    ///
    /// 문맥이 없거나 trigram/bigram 결과가 부족할 때 사용됩니다.
    /// `preferredScript`가 있으면 그 문자 종류 상위 후보를 먼저, 나머지 상위 후보를 뒤에 둡니다.
    ///
    /// - Parameter preferredScript: 먼저 보여줄 문자 종류. `nil`이면 빈도순만 따른다
    /// - Returns: 단어 배열 (최대 `maxPredictions`개)
    func rankedUnigramCandidates(preferredScript: PredictiveTextScript? = nil) -> [String] {
        if let cached = rankedUnigramCache[preferredScript] { return cached }

        let state = Self.signposter.beginInterval("RankedUnigramCandidates")
        defer { Self.signposter.endInterval("RankedUnigramCandidates", state) }

        // 전체 정렬 대신 묶음마다 상위 maxPredictions개만 유지한다. 동률 순서는 정렬 시절과 마찬가지로 정의하지 않는다
        var preferred: [(key: String, value: Int)] = []
        var others: [(key: String, value: Int)] = []
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

    /// 빈도 내림차순을 유지하며 상위 `maxPredictions`개 안에 들면 넣는다
    func insertTopUnigram(_ entry: (key: String, value: Int), into top: inout [(key: String, value: Int)]) {
        guard top.count < maxPredictions || entry.value > top[top.count - 1].value else { return }
        let insertIndex = top.firstIndex { entry.value > $0.value } ?? top.count
        top.insert(entry, at: insertIndex)
        if top.count > maxPredictions {
            top.removeLast()
        }
    }
```

`preferredScript`가 `nil`이면 모든 항목이 `others`로 가므로 기존 결과와 같다.

- [x] **Step 7: 테스트가 통과하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineScriptPreferenceTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests -only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRemovalTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests`

Expected: 새 suite의 테스트 7개와 기존 NGram 엔진 suite 전부 통과

Result: `** TEST SUCCEEDED **`. 6개 suite, 27개 테스트 전부 통과(새 suite "n-gram unigram 후보 문자 종류 우선 정렬 검증" 7개 포함). 기기 iPhone 13 mini / iOS 18.6. 로그: scratchpad `sdd-logs/task2-green.log`. 빌드 후 `.xcscheme` 변경 없음(`git status --short` 확인)

- [x] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineScriptPreferenceTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - NGram 통합 식별자와 unigram 후보 문자 종류 우선 정렬 추가" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `SuggestionController`의 NGram 식별자 분리

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `NGramPredictiveTextProviding` 프로토콜(약 13-31행)
  - 프로퍼티 `language`·`nGramEngines`·`nGramEngine`(약 114, 240-255행)
  - `init`(약 300-312행), `updateLanguage(to:)`(약 315-331행)
  - `preparePredictiveEnginesIfNeeded()`(약 333-359행), `releaseInactiveLanguageEngines()`(약 365-369행)
  - `nGramSuggestions(for:)`(약 973-979행)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift` (stub 조회 기록, 카운팅 팩토리 이동)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift` (파일 끝 `CountingSuggestionEngineFactory` 삭제)
- Test: `SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift`

**Interfaces:**
- Consumes: Task 1의 `PredictiveTextScriptPolicy.preferredScript(forLanguage:)`, Task 2의 `suggestions(for:preferredScript:)`
- Produces:
  - `SuggestionController.init(language: String = "ko-KR", nGramLanguage: String? = nil, engineFactory:, textCheckerQueue:)`
  - `NGramPredictiveTextProviding.suggestions(for:preferredScript:) -> [String]` 요구사항
  - 테스트 지원: `StubNGramPredictiveTextProvider.queriedBaseTexts: [String]`, `.queriedPreferredScripts: [PredictiveTextScript?]`, `final class CountingSuggestionEngineFactory`(internal)

- [x] **Step 1: 테스트 지원 코드를 옮기고 stub에 조회 기록을 넣는다**

`SuggestionControllerPreparationTests.swift` 끝의 `private final class CountingSuggestionEngineFactory { ... }` 전체(약 318-353행)를 잘라 `SuggestionControllerTestSupport.swift`의 `extension SuggestionControllerEngineFactory { ... }` 바로 아래로 옮기고 `private`을 뺀다.

```swift
/// 엔진 생성 횟수와 언어를 기록하는 factory
final class CountingSuggestionEngineFactory {

    // MARK: - Properties

    private(set) var lexiconCreationCount = 0
    private(set) var textCheckerCreationCount = 0
    private(set) var nGramCreationCount = 0
    private(set) var textCheckerLanguages: [String] = []
    private(set) var nGramLanguages: [String] = []
    private(set) var nGramProviders: [StubNGramPredictiveTextProvider] = []
    private(set) var lastNGramProvider: StubNGramPredictiveTextProvider?

    // MARK: - Internal Methods

    func makeFactory() -> SuggestionControllerEngineFactory {
        SuggestionControllerEngineFactory(
            makeLexiconEngine: { [weak self] in
                self?.lexiconCreationCount += 1
                return LexiconPredictiveTextEngine()
            },
            makeTextCheckerEngine: { [weak self] language in
                self?.textCheckerCreationCount += 1
                self?.textCheckerLanguages.append(language)
                return StubPredictiveTextProvider()
            },
            makeNGramEngine: { [weak self] language in
                self?.nGramCreationCount += 1
                self?.nGramLanguages.append(language)
                let provider = StubNGramPredictiveTextProvider()
                self?.nGramProviders.append(provider)
                self?.lastNGramProvider = provider
                return provider
            }
        )
    }
}
```

`StubNGramPredictiveTextProvider`에 조회 기록을 넣는다. `private(set) var saveCount = 0` 아래에:

```swift
    private(set) var queriedBaseTexts: [String] = []
    private(set) var queriedPreferredScripts: [PredictiveTextScript?] = []
```

`func suggestions(for baseText: String) -> [String] { loadedSuggestions }` 아래에:

```swift
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] {
        queriedBaseTexts.append(baseText)
        queriedPreferredScripts.append(preferredScript)
        return loadedSuggestions
    }
```

- [x] **Step 2: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift`:

```swift
//
//  SuggestionControllerUnifiedNGramTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 통합 NGram 식별자 검증")
struct SuggestionControllerUnifiedNGramTests {

    @Test("통합 NGram은 언어를 바꿔도 같은 엔진과 문장 버퍼를 씀")
    func test통합NGram은_언어를바꿔도_같은엔진과문장버퍼를씀() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.recordWord("오늘")
        controller.updateLanguage(to: "en-US")
        controller.recordWord("meeting")

        #expect(factory.nGramLanguages == ["ko-en"])
        #expect(factory.textCheckerLanguages == ["ko-KR", "en-US"])
        #expect(factory.lastNGramProvider?.saveCount == 0)
        #expect(factory.lastNGramProvider?.currentSentenceWordsCount == 2)
    }

    @Test("통합 NGram 조회는 현재 언어 모드의 문자 종류를 넘김")
    func test통합NGram조회는_현재언어모드의문자종류를넘김() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestions(for: "")
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")

        #expect(factory.lastNGramProvider?.queriedPreferredScripts == [.hangeul, .latin])
    }

    @Test("언어별 NGram은 선호 문자 종류 없이 조회하고 전환 때 저장")
    func test언어별NGram은_선호문자종류없이조회하고_전환때저장() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "")
        let koreanEngine = factory.lastNGramProvider
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")

        #expect(koreanEngine?.queriedPreferredScripts == [nil])
        #expect(koreanEngine?.saveCount == 1)
        #expect(factory.nGramLanguages == ["ko-KR", "en-US"])
    }

    @Test("통합 NGram 로딩 중 언어를 바꿔도 로딩 완료 뒤 후보를 갱신")
    func test통합NGram로딩중언어를바꿔도_로딩완료뒤후보를갱신() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate

        controller.updateSuggestions(for: "")
        controller.updateLanguage(to: "en-US")
        controller.updateSuggestions(for: "")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()

        #expect(delegate.updates.last?.suggestions == ["meeting"])
    }

    @Test("비활성 언어 엔진 해제는 통합 NGram 엔진을 남김")
    func test비활성언어엔진해제는_통합NGram엔진을남김() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateLanguage(to: "en-US")
        controller.releaseInactiveLanguageEngines()
        controller.preparePredictiveEnginesIfNeeded()

        #expect(factory.nGramCreationCount == 1)
    }
}

// MARK: - Helpers

/// 한영 통합 키보드 설정의 컨트롤러. 자동완성을 켜고 엔진을 준비한다
private func makeUnifiedController(factory: CountingSuggestionEngineFactory) -> SuggestionController {
    let controller = SuggestionController(
        language: "ko-KR",
        nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage,
        engineFactory: factory.makeFactory()
    )
    controller.isPredictiveTextEnabled = true
    controller.preparePredictiveEnginesIfNeeded()
    return controller
}
```

- [x] **Step 3: 테스트가 실패하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests`

Expected: 컴파일 실패. `extra argument 'nGramLanguage' in call`

- [x] **Step 4: 프로토콜에 선호 문자 종류 조회를 넣는다**

`NGramPredictiveTextProviding`의 `var currentSentenceWordsCount: Int { get }` 아래에:

```swift

    /// 문맥으로 다음 단어를 예측합니다. `preferredScript`가 있으면 unigram 후보만 그 문자 종류를 앞에 둡니다.
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String]
```

- [x] **Step 5: 식별자를 분리한다**

`private var language: String` 아래에:

```swift
    /// NGram 엔진 식별자. `nil`이면 `language`를 따른다.
    /// 한영 통합 키보드는 언어 모드와 무관하게 통합 엔진 하나를 쓴다
    private let nGramLanguage: String?
    /// 지금 쓰는 NGram 엔진 식별자
    private var activeNGramLanguage: String { nGramLanguage ?? language }
    /// 통합 NGram일 때만 현재 언어 모드의 문자 종류를 unigram 후보 앞에 둔다
    private var nGramPreferredScript: PredictiveTextScript? {
        guard nGramLanguage != nil else { return nil }
        return PredictiveTextScriptPolicy.preferredScript(forLanguage: language)
    }
```

`nGramEngines` 문서 주석과 `nGramEngine` 접근자를 바꾼다.

```swift
    /// 식별자별 n-gram 엔진 캐시.
    ///
    /// 언어별 NGram을 쓰는 키보드가 언어를 바꿀 때마다 엔진을 버리면 그때마다 디스크 로드를
    /// 다시 한다. 사용한 식별자의 엔진만 들고 있는다. 통합 NGram은 항목이 하나뿐이다
    private var nGramEngines: [String: NGramPredictiveTextProviding] = [:]
```

```swift
    private var nGramEngine: NGramPredictiveTextProviding? {
        get { nGramEngines[activeNGramLanguage] }
        set { nGramEngines[activeNGramLanguage] = newValue }
    }
```

`init`:

```swift
    /// - Parameters:
    ///   - language: `UITextChecker`에서 사용할 언어 코드 (기본값: "ko-KR")
    ///   - nGramLanguage: NGram 엔진 식별자. `nil`이면 `language`를 따른다
    init(
        language: String = "ko-KR",
        nGramLanguage: String? = nil,
        engineFactory: SuggestionControllerEngineFactory = .live,
        textCheckerQueue: DispatchQueue = DispatchQueue(
            label: "com.snmac.sykeyboard.suggestion.textchecker",
            qos: .userInitiated
        )
    ) {
        self.language = language
        self.nGramLanguage = nGramLanguage
        self.engineFactory = engineFactory
        self.textCheckerQueue = textCheckerQueue
    }
```

기존 `- Parameter language: ...` 한 줄 주석은 위 `- Parameters:` 블록으로 바꾼다.

- [x] **Step 6: 언어 전환·엔진 준비·해제를 식별자 기준으로 바꾼다**

`updateLanguage(to:)` 전체:

```swift
    func updateLanguage(to language: String) {
        guard self.language != language else { return }

        if nGramLanguage == nil {
            // 전환 전 언어의 학습 결과는 즉시 보존하되, 엔진 자체는 캐시에 남겨
            // 같은 언어로 돌아왔을 때 디스크 로드를 반복하지 않는다.
            // 통합 NGram은 엔진이 바뀌지 않으므로 저장하지 않고 로딩 완료 콜백도 살려 둔다
            nGramEngine?.saveToDisk()
            engineGeneration += 1
        }
        self.language = language
        lastSuggestionBaseText = nil
        lastMathExpressionText = nil
        lastSuggestionOrigin = nil
        currentMathCompletion = nil
        currentMathSuggestionOrigin = nil
        clearSuggestions()
    }
```

`preparePredictiveEnginesIfNeeded()`의 NGram 블록에서 두 곳을 바꾼다.

```swift
            let engineLanguage = activeNGramLanguage
```

```swift
                    guard let self,
                          self.engineGeneration == generation,
                          self.activeNGramLanguage == engineLanguage else { return }
```

`releaseInactiveLanguageEngines()`:

```swift
    func releaseInactiveLanguageEngines() {
        let activeLanguage = language
        let activeNGram = activeNGramLanguage
        nGramEngines = nGramEngines.filter { $0.key == activeNGram }
        textCheckerEngines = textCheckerEngines.filter { $0.key == activeLanguage }
    }
```

- [x] **Step 7: 조회에 선호 문자 종류를 넘긴다**

`nGramSuggestions(for:)`:

```swift
        let results = nGramEngine.suggestions(for: inputBuffer, preferredScript: nGramPreferredScript)
```

- [x] **Step 8: 테스트가 통과하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests -only-testing:SYKeyboardTests/SuggestionControllerSuspensionTests`

Expected: 새 suite의 테스트 5개와 기존 suite 전부 통과. 특히 `SuggestionControllerPreparationTests`의 언어 전환 stale callback 테스트가 그대로 통과해야 한다(언어별 NGram 동작 불변).

- [x] **Step 9: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift \
  SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 자동완성 컨트롤러에서 NGram 식별자를 언어와 분리" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

**실제 결과**: RED에서 `SuggestionControllerUnifiedNGramTests.swift`가 예상대로 `extra argument
'nGramLanguage' in call` 컴파일 오류로 실패하는 것을 확인했다. 구현 후 컴파일 오류가 하나 더
났다: brief에 없는 `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift`의
`private final class RemovableNGramStub`도 `NGramPredictiveTextProviding`을 채택하고 있어
새 프로토콜 요구사항 때문에 컴파일이 깨졌다. 기존 stub과 같은 패턴으로
`func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] { results }`
한 줄을 추가해 해결했다(brief 파일 목록 밖이지만 프로토콜 변경의 필연적 결과).
`iPhone 13 mini / iOS 18.6`에서
`-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests
-only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
-only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests
-only-testing:SYKeyboardTests/SuggestionControllerSuspensionTests`로 4개 suite 28개 테스트
전부 통과(`Test run with 28 tests in 4 suites passed`). 확인하지 못한 항목: 실제 입력 앱에서의
수동 확인(이 Task 범위 밖, Task 8에서 다룸), extension scheme 빌드(이 Task는 Core 도메인
로직만 변경해 스킴 빌드는 다른 Task 검증 범위로 남김).

---

### Task 4: NGram 조회 문맥을 따로 받기

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` (`updateSuggestions`, `updateSuggestionsAfterNGramSelection` 요구사항과 extension)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `lastSuggestionBaseText` 선언 아래(약 257행), `updateLanguage`(약 323행), `clearSuggestions`(약 457행)
  - `updateSuggestions`(약 405-422행), `updateSuggestionsAfterNGramSelection`(약 424-452행)
  - `removeSuggestionWord`(약 521-532행), `performUpdateSuggestions`(약 837행, n-gram 분기 약 878행)
  - `performRefreshSuggestionsAfterNGramLoadIfNeeded`(약 954-964행)
- Test: `SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift` (suite 추가)

**Interfaces:**
- Consumes: Task 3의 stub `queriedBaseTexts`, `CountingSuggestionEngineFactory`
- Produces:
  - `SuggestionService.updateSuggestions(for: String, nGramContext: String, selectedText: String?, mathExpressionText: String)` 요구사항
  - `SuggestionService.updateSuggestionsAfterNGramSelection(inputBuffer: String, nGramContext: String)` 요구사항
  - 기존 `updateSuggestions(for:selectedText:mathExpressionText:)`, `updateSuggestionsAfterNGramSelection(inputBuffer:)`는 extension으로 남고 `nGramContext`에 각각 `baseText`, `inputBuffer`를 넘긴다

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SuggestionControllerUnifiedNGramTests.swift`의 `// MARK: - Helpers` 위에 suite를 하나 더 둔다.

```swift
@Suite("자동완성 컨트롤러 NGram 조회 문맥 검증")
struct SuggestionControllerNGramContextTests {

    @Test("NGram 모드 조회는 넘겨받은 문맥을 씀")
    func testNGram모드조회는_넘겨받은문맥을씀() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestions(for: "", nGramContext: "오늘 ", selectedText: nil, mathExpressionText: "")

        #expect(controller.currentMode == .nGram)
        #expect(factory.lastNGramProvider?.queriedBaseTexts == ["오늘 "])
    }

    @Test("입력 중 모드 판단은 언어 구간으로 함")
    func test입력중모드판단은_언어구간으로함() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestions(for: "ㅎ", nGramContext: "오늘 ", selectedText: nil, mathExpressionText: "ㅎ")

        #expect(controller.currentMode == .typing)
        #expect(factory.lastNGramProvider?.queriedBaseTexts == [])
    }

    @Test("로딩 완료 뒤 갱신도 마지막 NGram 문맥을 씀")
    func test로딩완료뒤갱신도_마지막NGram문맥을씀() async {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestions(for: "", nGramContext: "오늘 ", selectedText: nil, mathExpressionText: "")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()

        #expect(factory.lastNGramProvider?.queriedBaseTexts == ["오늘 ", "오늘 "])
    }

    @Test("NGram 후보 선택 뒤 갱신은 넘겨받은 문맥을 씀")
    func testNGram후보선택뒤갱신은_넘겨받은문맥을씀() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)

        controller.updateSuggestionsAfterNGramSelection(inputBuffer: "meeting", nGramContext: "오늘 meeting")

        #expect(factory.lastNGramProvider?.queriedBaseTexts == ["오늘 meeting"])
    }

    @Test("후보 삭제 뒤 재조회는 마지막 NGram 문맥을 씀")
    func test후보삭제뒤재조회는_마지막NGram문맥을씀() async {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeUnifiedController(factory: factory)
        controller.updateSuggestions(for: "", nGramContext: "오늘 ", selectedText: nil, mathExpressionText: "")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()

        controller.removeSuggestionWord("meeting")

        #expect(factory.lastNGramProvider?.queriedBaseTexts.last == "오늘 ")
    }

    @Test("문맥을 따로 넘기지 않으면 baseText로 조회")
    func test문맥을따로넘기지않으면_baseText로조회() {
        let factory = CountingSuggestionEngineFactory()
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
        controller.isPredictiveTextEnabled = true

        controller.updateSuggestions(for: "오늘 ", selectedText: nil, mathExpressionText: "오늘 ")
        controller.updateSuggestionsAfterNGramSelection(inputBuffer: "오늘 날씨")

        #expect(factory.lastNGramProvider?.queriedBaseTexts == ["오늘 ", "오늘 날씨"])
    }
}
```

- [x] **Step 2: 테스트가 실패하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests`

Expected: 컴파일 실패. `extra argument 'nGramContext' in call`

- [x] **Step 3: 프로토콜 요구사항과 extension을 바꾼다**

`SuggestionService.swift`에서 요구사항 `func updateSuggestions(for:selectedText:mathExpressionText:)`를 아래로 바꾼다. 위에 붙은 기존 문서 주석은 그대로 두고 `nGramContext` 줄을 더한다.

```swift
    ///   - nGramContext: NGram 다음 단어 예측에 쓸 문맥. 모드 판단은 `baseText`로 한다.
    ///     한영 통합 키보드는 언어 전환 경계를 넘는 `inputBuffer` 전체를 넘긴다
    func updateSuggestions(
        for baseText: String,
        nGramContext: String,
        selectedText: String?,
        mathExpressionText: String
    )
```

요구사항 `func updateSuggestionsAfterNGramSelection(inputBuffer: String)`를 아래로 바꾼다.

```swift
    ///   - nGramContext: NGram 다음 단어 예측에 쓸 문맥
    func updateSuggestionsAfterNGramSelection(inputBuffer: String, nGramContext: String)
```

`extension SuggestionService`의 맨 앞에 두 함수를 더한다.

```swift
    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String
    ) {
        updateSuggestions(
            for: baseText,
            nGramContext: baseText,
            selectedText: selectedText,
            mathExpressionText: mathExpressionText
        )
    }

    func updateSuggestionsAfterNGramSelection(inputBuffer: String) {
        updateSuggestionsAfterNGramSelection(inputBuffer: inputBuffer, nGramContext: inputBuffer)
    }
```

- [x] **Step 4: 컨트롤러에 마지막 NGram 문맥을 둔다**

`private var lastSuggestionBaseText: String?` 아래에:

```swift
    /// 마지막으로 NGram 조회를 요청한 문맥. 로딩 완료·후보 삭제 뒤 재조회에 쓴다
    private var lastNGramContext: String?
```

`updateLanguage(to:)`와 `clearSuggestions()`에서 `lastSuggestionBaseText = nil` 바로 아래에 각각:

```swift
        lastNGramContext = nil
```

- [x] **Step 5: 갱신 경로에 문맥을 흘린다**

`updateSuggestions`:

```swift
    func updateSuggestions(
        for baseText: String,
        nGramContext: String,
        selectedText: String?,
        mathExpressionText: String
    ) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin(selectedText: selectedText)
        lastSuggestionBaseText = baseText
        lastNGramContext = nGramContext
        lastMathExpressionText = mathExpressionText
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()
        performUpdateSuggestions(
            for: baseText,
            nGramContext: nGramContext,
            mathExpressionText: mathExpressionText,
            origin: origin
        )
    }
```

`updateSuggestionsAfterNGramSelection`:

```swift
    func updateSuggestionsAfterNGramSelection(inputBuffer: String, nGramContext: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin.unselected
        lastSuggestionBaseText = inputBuffer
        lastNGramContext = nGramContext
        lastMathExpressionText = inputBuffer
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()

        let nGramResults = nGramSuggestions(for: nGramContext)

        if !nGramResults.isEmpty {
            currentMathCompletion = nil
            currentMathSuggestionOrigin = nil
            currentMode = .nGram
            currentSuggestions = nGramResults
            delegate?.suggestionController(
                self,
                didUpdateCurrentWord: nil,
                suggestions: currentSuggestions.map { $0.text }
            )
        } else {
            performUpdateSuggestions(
                for: inputBuffer,
                nGramContext: nGramContext,
                mathExpressionText: inputBuffer,
                origin: origin
            )
        }
    }
```

`removeSuggestionWord`의 NGram 모드 분기:

```swift
        if currentMode == .nGram, let lastSuggestionBaseText {
            updateSuggestionsAfterNGramSelection(
                inputBuffer: lastSuggestionBaseText,
                nGramContext: lastNGramContext ?? lastSuggestionBaseText
            )
        } else {
```

`performUpdateSuggestions` 시그니처와 n-gram 분기:

```swift
    /// - Parameters:
    ///   - baseText: 자동완성을 제공할 텍스트. 모드 판단에 쓴다
    ///   - nGramContext: NGram 모드에서 다음 단어 예측에 쓸 문맥
    func performUpdateSuggestions(
        for baseText: String,
        nGramContext: String,
        mathExpressionText: String,
        origin: MathSuggestionOrigin
    ) {
```

```swift
        if baseText.isEmpty || baseText.last?.isWhitespace == true {
            currentMode = .nGram
            currentSuggestions = nGramSuggestions(for: nGramContext)
```

기존 `- Parameter baseText: 자동완성을 제공할 텍스트` 한 줄은 위 `- Parameters:` 블록으로 바꾼다.

`performRefreshSuggestionsAfterNGramLoadIfNeeded`:

```swift
        performUpdateSuggestions(
            for: lastSuggestionBaseText,
            nGramContext: lastNGramContext ?? lastSuggestionBaseText,
            mathExpressionText: lastMathExpressionText,
            origin: lastSuggestionOrigin
        )
```

- [x] **Step 6: 테스트가 통과하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests -only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests -only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests -only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests -only-testing:SYKeyboardTests/SuggestionControllerSuspensionTests`

Expected: 새 suite의 테스트 6개와 기존 `SuggestionController*` suite 전부 통과. 이 시점에 `BaseKeyboardViewController`는 3인자 extension을 거쳐 기존과 같게 동작한다.

- [x] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 자동완성 컨트롤러가 NGram 조회 문맥을 따로 받도록 변경" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

**결과**: Step 2 RED에서 `extra argument 'nGramContext' in call` 컴파일 실패를 확인한 뒤 Step 3~5를 브리프 그대로 구현했다.
Step 6 GREEN 실행(`-only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests` 외 8개 suite)은
**74 tests in 9 suites passed**(9.4초). `HangeulEnglishKeyboard` scheme을 `-only-testing` 없이 빌드해
`BaseKeyboardViewController`가 3인자 extension 경로로 그대로 컴파일되는 것도 확인했다(`** BUILD SUCCEEDED **`).
빌드 후 `git status --short`에 `.xcscheme` 변경 없음. 확인하지 못한 항목 없음.

---

### Task 5: NGram 문맥 policy

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (`membershipExceptions` 두 곳)
- Test: `SYKeyboardTests/Utils/KeyboardNGramContextPolicyTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `KeyboardNGramContextPolicy.queryContext(inputBuffer: String, currentSegment: String, selectedText: String?) -> String`
  - `KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: String, currentSegment: String) -> String`
  - `KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(bufferBeforeDelete: String, bufferAfterDelete: String) -> KeyboardNGramContextPolicy.SentenceBufferAction`
  - `enum SentenceBufferAction: Equatable { case none, reset, removeLastWord }`

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/KeyboardNGramContextPolicyTests.swift`:

```swift
//
//  KeyboardNGramContextPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("NGram 문맥 정책 검증")
struct KeyboardNGramContextPolicyTests {

    // MARK: - queryContext

    @Test("경계가 없으면 입력 버퍼를 그대로 문맥으로 씀", arguments: ["", "오늘 ", "오늘 날"])
    func test경계가없으면_입력버퍼를그대로문맥으로씀(buffer: String) {
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: buffer, currentSegment: buffer, selectedText: nil
        ) == buffer)
    }

    @Test("공백 뒤에 전환하면 경계를 넘는 전체 버퍼를 문맥으로 씀")
    func test공백뒤에전환하면_경계를넘는전체버퍼를문맥으로씀() {
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: "오늘 ", currentSegment: "", selectedText: nil
        ) == "오늘 ")
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: "오늘 meeting ", currentSegment: "meeting ", selectedText: nil
        ) == "오늘 meeting ")
    }

    @Test("단어 중간에 전환하면 언어 구간을 문맥으로 씀")
    func test단어중간에전환하면_언어구간을문맥으로씀() {
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: "SY", currentSegment: "", selectedText: nil
        ) == "")
    }

    @Test("선택 영역이 있으면 선택 텍스트를 문맥으로 씀")
    func test선택영역이있으면_선택텍스트를문맥으로씀() {
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: "오늘 ", currentSegment: "", selectedText: "1+2"
        ) == "1+2")
        #expect(KeyboardNGramContextPolicy.queryContext(
            inputBuffer: "오늘 ", currentSegment: "", selectedText: ""
        ) == "오늘 ")
    }

    // MARK: - attachedPrefix

    @Test("단어 중간에 전환했으면 경계 앞에 붙은 부분을 돌려줌")
    func test단어중간에전환했으면_경계앞에붙은부분을돌려줌() {
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "SY키보", currentSegment: "키보") == "SY")
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "오늘 SY키보", currentSegment: "키보") == "SY")
    }

    @Test("경계 앞이 공백이거나 경계가 없으면 빈 문자열")
    func test경계앞이공백이거나경계가없으면_빈문자열() {
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "오늘 키보", currentSegment: "키보") == "")
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "키보", currentSegment: "키보") == "")
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "오늘 날", currentSegment: "오늘 날") == "")
    }

    @Test("구간 안에 공백이 있으면 현재 단어는 경계에 붙어 있지 않음")
    func test구간안에공백이있으면_현재단어는경계에붙어있지않음() {
        #expect(KeyboardNGramContextPolicy.attachedPrefix(inputBuffer: "SYabc 키보", currentSegment: "abc 키보") == "")
    }

    // MARK: - sentenceBufferActionAfterDelete

    @Test("공백을 지워 단어 경계를 허물면 마지막 단어만 뺌")
    func test공백을지워단어경계를허물면_마지막단어만뺌() {
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "오늘 날씨 ", bufferAfterDelete: "오늘 날씨"
        ) == .removeLastWord)
    }

    @Test("한영 전환 직후 경계를 넘어 공백을 지우면 마지막 단어만 뺌")
    func test한영전환직후_경계를넘어공백을지우면_마지막단어만뺌() {
        // 언어 구간은 비어 있지만 전체 버퍼 기준으로 판단한다
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "오늘 ", bufferAfterDelete: "오늘"
        ) == .removeLastWord)
    }

    @Test("모두 지우면 문장 버퍼를 초기화")
    func test모두지우면_문장버퍼를초기화() {
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "a", bufferAfterDelete: ""
        ) == .reset)
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "", bufferAfterDelete: ""
        ) == .reset)
    }

    @Test("단어 안의 글자나 연속 공백 하나를 지우면 그대로 둠")
    func test단어안의글자나연속공백하나를지우면_그대로둠() {
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "오늘 날씨", bufferAfterDelete: "오늘 날"
        ) == .none)
        #expect(KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: "오늘  ", bufferAfterDelete: "오늘 "
        ) == .none)
    }
}
```

- [x] **Step 2: 테스트가 실패하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/KeyboardNGramContextPolicyTests`

Expected: 컴파일 실패. `cannot find 'KeyboardNGramContextPolicy' in scope`

Result: Confirmed compilation error as expected

- [x] **Step 3: policy를 만든다**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift`:

```swift
//
//  KeyboardNGramContextPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/25/26.
//

import Foundation

/// NGram에 넘길 문맥과 문장 버퍼 동기화를 정한다.
///
/// NGram은 언어 전환 경계를 넘어 `inputBuffer` 전체를 보고, 단어 완성·자동 대치는
/// 마지막 전환 이후 구간(`currentSegment`)만 본다. 경계가 없는 단독 키보드는 두 값이
/// 같으므로 모든 결과가 기존과 같다
enum KeyboardNGramContextPolicy {

    /// 삭제 뒤 NGram 문장 버퍼를 맞추는 방법
    enum SentenceBufferAction: Equatable {
        case none
        /// 모든 입력을 지웠다
        case reset
        /// 스페이스를 지워 기록된 단어 경계를 허물었다
        case removeLastWord
    }

    /// NGram 조회 문맥.
    ///
    /// 선택 영역이 있으면 지금처럼 선택 텍스트를 쓴다. 전체 버퍼가 비었거나 공백으로 끝나면
    /// 경계를 넘는 전체 버퍼를, 단어 중간에서 전환했다면 지금처럼 언어 구간을 쓴다
    static func queryContext(inputBuffer: String, currentSegment: String, selectedText: String?) -> String {
        if let selectedText, !selectedText.isEmpty { return selectedText }
        if inputBuffer.isEmpty || inputBuffer.last?.isWhitespace == true { return inputBuffer }
        return currentSegment
    }

    /// 언어 구간 앞에 공백 없이 붙어 있던 부분.
    ///
    /// 단어 완성 후보를 고를 때 이 부분을 후보 앞에 붙여 NGram에 한 단어로 기록한다('SY' + '키보드').
    /// 구간 안에 공백이 있거나 경계가 없으면 빈 문자열이다
    static func attachedPrefix(inputBuffer: String, currentSegment: String) -> String {
        guard !currentSegment.contains(where: { $0.isWhitespace }) else { return "" }
        let outside = inputBuffer.dropLast(currentSegment.count)
        return String(outside.reversed().prefix { !$0.isWhitespace }.reversed())
    }

    /// 한 글자 삭제 뒤 NGram 문장 버퍼를 맞추는 방법. 전체 버퍼 기준으로 판단한다
    static func sentenceBufferActionAfterDelete(
        bufferBeforeDelete: String,
        bufferAfterDelete: String
    ) -> SentenceBufferAction {
        if bufferAfterDelete.isEmpty { return .reset }
        if bufferBeforeDelete.last?.isWhitespace == true,
           bufferAfterDelete.last?.isWhitespace != true {
            return .removeLastWord
        }
        return .none
    }
}
```

- [x] **Step 4: pbxproj 두 목록에 파일을 넣는다**

`SYKeyboard.xcodeproj/project.pbxproj`에서 아래 줄은 두 번 나온다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageSegmentTracker.swift,
```

두 곳 모두 그 바로 아래에 넣는다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift,
```

확인:

```sh
grep -c "Policies/KeyboardNGramContextPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

Result: Confirmed 2 occurrences in pbxproj file

- [x] **Step 5: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: `KeyboardNGramContextPolicyTests` 11개 테스트(인자 포함 13건) 통과

Result: All 11 test functions passed (13 test cases total: 3 parametrized + 10 regular tests). Suite passed in 0.050 seconds. Device: iPhone 13 mini / iOS 18.6

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/KeyboardNGramContextPolicyTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 언어 전환 경계를 넘는 NGram 문맥 정책 추가" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: 키보드 컨트롤러 배선

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `init(language:)`(약 272-275행)
  - `insertSpaceText()`(약 638-645행), `insertReturnText()`(약 649-659행)
  - `deleteText()`(약 804-832행)
  - `updateSuggestionsForCurrentContext()`(약 1975-1999행)
  - `handleNGramSuggestion(at:)`(약 2752-2770행)
  - `handleCurrentWordConfirmationIfNeeded(at:)`(약 2772-2784행)
  - `handleInputBufferSuggestion(at:)`(약 2786-2802행)
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift` (`init()`, 약 87행)

**Interfaces:**
- Consumes: Task 2 `NGramPredictiveTextEngine.hangeulEnglishLanguage`, Task 3 `SuggestionController.init(language:nGramLanguage:...)`, Task 4 `updateSuggestions(for:nGramContext:selectedText:mathExpressionText:)`·`updateSuggestionsAfterNGramSelection(inputBuffer:nGramContext:)`, Task 5 `KeyboardNGramContextPolicy`
- Produces: `BaseKeyboardViewController.init(language: String, nGramLanguage: String? = nil)` (public)

이 Task는 VC 배선이라 새 unit test가 없다(「spec과 다르게 가는 곳」 3). 규칙은 Task 5 policy 테스트가 고정하고, 여기서는 빌드·기존 테스트·Task 8 수동 확인으로 검증한다.

- [x] **Step 1: 초기화에 NGram 식별자를 받는다**

```swift
    /// - Parameters:
    ///   - language: 키보드 언어. `UITextChecker` 언어로도 쓴다
    ///   - nGramLanguage: NGram 엔진 식별자. `nil`이면 `language`를 따른다
    public init(language: String, nGramLanguage: String? = nil) {
        self.suggestionController = SuggestionController(language: language, nGramLanguage: nGramLanguage)
        super.init(nibName: nil, bundle: nil)
    }
```

`HangeulEnglishKeyboardViewController.init()`의 `super.init(language: mode.languageIdentifier)`를 바꾼다.

```swift
        super.init(
            language: mode.languageIdentifier,
            nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage
        )
```

- [x] **Step 2: 스페이스·리턴 기록을 전체 버퍼로 바꾼다**

`insertSpaceText()`:

```swift
        // NGram은 언어 전환 경계를 넘어 전체 버퍼로 기록한다
        suggestionController.recordUncommittedWords(from: inputBuffer)
```

`insertReturnText()`:

```swift
        suggestionController.endSentence(inputBuffer: inputBuffer)
```

- [x] **Step 3: 삭제 뒤 문장 버퍼 동기화를 policy로 바꾼다**

`deleteText()`의 첫 줄 `let wasSpaceAtEnd = currentLanguageInputBuffer.last?.isWhitespace == true`를 지우고 그 자리에:

```swift
        let bufferBeforeDelete = inputBuffer
```

함수 끝의 `if currentLanguageInputBuffer.isEmpty { ... } else if wasSpaceAtEnd && ... { ... }` 블록 전체를 아래로 바꾼다.

```swift
        // NGram 문장 버퍼는 언어 전환 경계와 무관하게 전체 버퍼 기준으로 맞춘다
        switch KeyboardNGramContextPolicy.sentenceBufferActionAfterDelete(
            bufferBeforeDelete: bufferBeforeDelete,
            bufferAfterDelete: inputBuffer
        ) {
        case .reset:
            // 모든 입력을 지운 경우 → 문장 버퍼 전체 초기화
            suggestionController.resetSentenceBuffer()
        case .removeLastWord:
            // 스페이스를 지워서 커밋된 단어 경계를 허문 경우 → n-gram 버퍼에서 pop
            suggestionController.removeLastRecordedWord()
        case .none:
            break
        }
```

- [x] **Step 4: 후보 갱신에 NGram 문맥을 넘긴다**

`updateSuggestionsForCurrentContext()`의 `case .update(let text):`:

```swift
        case .update(let text):
            suggestionController.updateSuggestions(
                for: text,
                nGramContext: KeyboardNGramContextPolicy.queryContext(
                    inputBuffer: inputBuffer,
                    currentSegment: currentLanguageInputBuffer,
                    selectedText: selectedText
                ),
                selectedText: selectedText,
                mathExpressionText: mathExpressionText
            )
```

`handleNGramSuggestion(at:)`의 끝(앞 공백 삽입 판단은 `currentLanguageInputBuffer` 그대로 둔다):

```swift
        // 방금 넣은 것은 완성된 단어라 언어 전환 경계를 넘는 전체 버퍼를 문맥으로 쓴다
        suggestionController.updateSuggestionsAfterNGramSelection(
            inputBuffer: currentLanguageInputBuffer,
            nGramContext: inputBuffer
        )
```

- [x] **Step 5: 후보 확정·선택 기록을 전환 경계 앞부분까지 넓힌다**

`handleCurrentWordConfirmationIfNeeded(at:)`:

```swift
        let currentWord = KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
            inputBuffer: currentLanguageInputBuffer
        )
        if !currentWord.isEmpty {
            suggestionController.learnWord(currentWord)
            // NGram은 언어 전환 경계 앞에 붙은 부분까지 한 단어로 기록한다('SY' + '키보드')
            suggestionController.recordWord(
                KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(inputBuffer: inputBuffer)
            )
        }
```

`handleInputBufferSuggestion(at:)`:

```swift
    func handleInputBufferSuggestion(at index: Int) {
        let suggestionIndex = index - 1
        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            baseText: currentLanguageInputBuffer
        ) else { return }

        // 대치 전에 구한다. 언어 전환 경계 앞에 붙어 있던 부분을 후보 앞에 붙여 한 단어로 기록한다.
        // 후보 문자열은 그대로 기록하므로 여러 단어로 된 후보의 공백은 지금처럼 남는다
        let attachedPrefix = KeyboardNGramContextPolicy.attachedPrefix(
            inputBuffer: inputBuffer,
            currentSegment: currentLanguageInputBuffer
        )

        replaceTextWithSmartInsertDeleteSpacing(
            deleteCount: result.deleteCount,
            insert: result.insertText
        )

        suggestionController.recordWord(attachedPrefix + result.insertText)

        suggestionDidApply()
        updateSuggestions()
    }
```

- [x] **Step 6: 남은 NGram 경로가 없는지 확인한다**

```sh
grep -n "recordUncommittedWords\|endSentence(inputBuffer\|recordWord(\|updateSuggestionsAfterNGramSelection(\|resetSentenceBuffer()\|removeLastRecordedWord()" \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: 나오는 줄은 이 Task에서 바꾼 호출(`deleteText()`의 `switch` 안 두 호출 포함)과 `resetInputBuffer()` 안의 `resetSentenceBuffer()`뿐이다. `recordUncommittedWords`·`endSentence`·`recordWord`에 `currentLanguageInputBuffer`나 그 단어를 넘기는 줄이 남아 있으면 안 된다.

- [x] **Step 7: 빌드와 기존 테스트를 확인한다**

사용자에게 빌드·테스트가 수 분 걸린다고 알린 뒤 실행한다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: `** BUILD SUCCEEDED **`. 이어서 `git status --short`로 `.xcscheme` `RemotePath` 변경을 확인하고 있으면 되돌린다.

Run: `-only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests -only-testing:SYKeyboardTests/KeyboardNGramContextPolicyTests -only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests`

Expected: 전부 통과

**실제 결과**: `HangeulEnglishKeyboard` scheme 빌드 `** BUILD SUCCEEDED **`(iPhone 13 mini / iOS 18.6). 빌드 후 `git status --short`에 `.xcscheme` 변경 없음. 테스트 3개 suite 총 20개 전부 통과(`Test run with 20 tests in 3 suites passed`). Step 6 grep 결과는 이 Task에서 바꾼 8줄(645, 656, 836, 839, 869-`resetInputBuffer`, 2783, 2799, 2826)만 남았고 `currentLanguageInputBuffer`를 넘기는 줄은 없음. Task 8 수동 확인(실기기 입력 앱)은 이 Task 범위 밖이라 미실행.

- [x] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 한영 통합 키보드가 통합 NGram과 전체 버퍼 문맥을 쓰도록 연결" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: 설정의 학습 데이터 초기화에 통합 파일 포함

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift` (`supportedLanguages` 약 31행, `resetNGramData()` 약 114-123행)

**Interfaces:**
- Consumes: Task 2 `NGramPredictiveTextEngine.hangeulEnglishLanguage`
- Produces: 없음

SwiftUI 설정 화면의 버튼 동작이라 unit test를 두지 않는다. 초기화가 파일을 지우는 동작은 기존 `resetAllData()` 테스트가 고정하고, 여기서는 목록에 식별자가 들어가는지만 바뀐다. Task 8에서 시뮬레이터로 파일 삭제를 확인한다.

- [x] **Step 1: NGram 초기화 목록을 분리한다**

`private let supportedLanguages = ["ko-KR", "en-US"]` 아래에:

```swift
    /// NGram은 한영 통합 키보드의 통합 파일까지 지운다
    private let nGramLanguages = ["ko-KR", "en-US", NGramPredictiveTextEngine.hangeulEnglishLanguage]
```

`resetNGramData()`:

```swift
    func resetNGramData() {
        for lang in nGramLanguages {
            let engine = NGramPredictiveTextEngine(language: lang)
            engine.resetAllData()
        }
```

(`Analytics.logEvent` 이하는 그대로)

- [x] **Step 2: 앱 빌드를 확인한다**

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: `** BUILD SUCCEEDED **`

Result: `** BUILD SUCCEEDED **` (iPhone 13 mini / iOS 18.6). 빌드 후 `git status --short` 결과 `.xcscheme` 변경 없음.

- [x] **Step 3: 커밋**

```bash
git add SYKeyboard/Presentation/KeyboardSettings/PredictiveTextSettingsView.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 학습 데이터 초기화에 한영 통합 NGram 파일 포함" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: 전체 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md` (결과 기록)

- [x] **Step 1: 4개 scheme 빌드**

사용자에게 오래 걸린다고 알린 뒤, `-only-testing`·coverage 옵션 없이 CLAUDE.md 「빌드와 테스트」의 `SYKeyboard`(build), `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` 빌드 명령을 실행한다. 로그는 scratchpad에 남긴다.

Expected: 4개 모두 `** BUILD SUCCEEDED **`. 빌드 뒤 `.xcscheme` `RemotePath` 변경은 되돌린다.

**결과 (iPhone 13 mini / iOS 18.6, 2026-09-25):**

| scheme | 결과 | 로그 |
| --- | --- | --- |
| `SYKeyboard` (build) | `** BUILD SUCCEEDED **` | `sdd-logs/task8-build-sykeyboard.log` |
| `HangeulKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task8-build-hangeul.log` |
| `EnglishKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task8-build-english.log` |
| `HangeulEnglishKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task8-build-hangeulenglish.log` |

4개 빌드 모두 각각 foreground로 순서대로 실행. 빌드 뒤 `git status --short`는 매번 비어 있어 `.xcscheme` `RemotePath` 변경이 발생하지 않았다(되돌릴 것 없음).

- [x] **Step 2: 전체 테스트**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  -resultBundlePath <scratchpad>/sdd-logs/task8-full.xcresult \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'
```

Expected: 전부 통과. 이 문서에 통과 개수, `.xcresult` 경로, 결과 추출 명령(`xcrun xcresulttool get test-results summary --path <xcresult>`)을 적는다.

**결과 (iPhone 13 mini / iOS 18.6, 2026-09-25):** `** TEST SUCCEEDED **`, Swift Testing 요약 `Test run with 779 tests in 87 suites passed after 7.043 seconds.`

`.xcresult` 경로:
`/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/3526bae6-16dc-4bec-b303-db0928873699/scratchpad/sdd-logs/task8-full.xcresult`

추출 명령: `xcrun xcresulttool get test-results summary --path <위 xcresult 경로>`

추출 결과 요약: `result: "Passed"`, `totalTestCount: 779`, `passedTests: 779`(디바이스별 `passedTests: 826`은 dynamic-parameter 확장 포함), `failedTests: 0`, `skippedTests: 0`, `expectedFailures: 0`. 빌드 로그: `sdd-logs/task8-full-test.log`. 테스트 뒤 `git status --short`도 비어 있어 되돌릴 `.xcscheme` 변경 없음.

- [x] **Step 3: 시뮬레이터에서 한영 키보드 동작 확인 (iPhone 13 mini / iOS 18.6)**

한영 키보드를 켠 메모 앱 등 입력 앱에서 확인하고, 항목마다 결과를 적는다. 키보드 미활성화·붙여넣기 알림 등으로 확인하지 못한 항목은 미확인과 막힌 이유를 적는다(완료로 표시하지 않는다).

1. '오늘' 스페이스 → 영어 전환 → 'meeting' 스페이스 → 리턴을 3번 반복한 뒤, '오늘' 스페이스 → 영어 전환 직후 후보에 `meeting`이 뜬다.
2. 영어 'SY' → 한글 전환(스페이스 없이) → '키보드' 스페이스 → 리턴을 2번 반복한 뒤, 문맥 없는 첫 화면 후보에 `SY키보드`가 뜬다.
3. 한글 모드에서 문맥 없는 후보는 한글 단어가 앞에, 영어 모드에서는 영어 단어가 앞에 온다.
4. '오늘' 스페이스 → 영어 전환 → 백스페이스 한 번 → 스페이스를 입력했을 때, 후보가 "오늘" 뒤 문맥 후보로 다시 뜬다(문맥 초기화 안 됨).
5. 단독 한글 키보드와 단독 영어 키보드의 후보는 기존 학습(ko/en 파일) 그대로이고, 1~2에서 한영 키보드로 학습한 `meeting`·`SY키보드`가 단독 키보드 후보에 새로 생기지 않는다.
6. 앱 설정의 '학습 데이터 초기화' 뒤 App Group `Library/Application Support/`에 `ngram_ko-en.plist`가 없다.

   ```sh
   ls "$(xcrun simctl get_app_container 82146144-24DE-4F91-B25D-23D147A91142 github.com-SNMac.SYKeyboard groups | awk '{print $2}' | head -1)/Library/Application Support/"
   ```

   출력 형식이 다르면 `xcrun simctl get_app_container <UDID> github.com-SNMac.SYKeyboard groups` 결과에서 App Group 경로를 직접 골라 쓴다.

**Step 3 결과 (2026-09-25, 컨트롤러가 `idb ui tap`·`simctl io screenshot`으로 실행)**

환경: iPhone 13 mini / iOS 18.6 (`82146144-24DE-4F91-B25D-23D147A91142`), Task 8 Step 2 테스트가 설치한 빌드, 앱의 '터치하여 키보드 테스트' 입력창.
붙여넣기 알림을 피하려고 확인 동안 App Group `isClipboardHistoryEnabled`를 `false`로 두었다가 끝난 뒤 `true`로 되돌렸다.
입력 순서: '오늘' 스페이스 → 한/A → 'ok' 스페이스 → 한/A → '오늘' 스페이스 → 한/A → 백스페이스 → 스페이스 → 'sy' → 한/A(스페이스 없이) → '키보드' 스페이스 → 한/A → 백스페이스 → 스페이스 → 리턴.

1. **기대와 다름(기존 동작, 이번 변경의 회귀 아님).** 두 번째 '오늘 ' 뒤 한글 모드 후보가 `ok, 오늘`로, 언어를 넘는 bigram이 학습·조회되는 것은 확인했다.
   하지만 **한/A로 전환한 직후에는 후보 바가 비어 있다.** `applyLanguageMode`가 `clearSuggestionsForLanguageChange()`로 후보를 비우기만 하고 다시 계산하지 않는다.
   develop의 `HangeulEnglishKeyboardViewController`도 같다(#46 `ce2a755a`부터). 전환 뒤 백스페이스·스페이스처럼 다음 갱신이 오면 전체 버퍼 문맥 후보(`ok, 오늘`)가 뜬다.
   전환 직후 다시 계산할지는 기존 동작 변경이라 사용자 확인 사항으로 남긴다.
2. **확인.** 'sy' → 스페이스 없이 한글 전환 → '키보드' 스페이스 뒤 후보에 `sy키보드`가 한 단어로 떴다. 대문자 대신 소문자로 입력했다(같은 경로).
3. **확인.** 문맥이 없는 unigram 후보가 한글 모드에서 `오늘, sy키보드, ok`, 영어 모드에서 `ok, 오늘, sy키보드`였다.
4. **확인.** 영어 모드에서 경계를 넘어 백스페이스(공백 삭제) → 스페이스를 쳐도 '오늘' 뒤 문맥 후보 `ok`가 그대로 떴다.
5. **일부 확인.** 리턴으로 저장한 뒤 App Group `Library/Application Support/`에는 `ngram_ko-en.plist`만 생기고 `ngram_ko-KR`·`ngram_en-US`는 생기지 않았다.
   파일 내용: unigram `{sy키보드: 2, 오늘: 3, ok: 1}`, bigram `{오늘: {sy키보드: 2, ok: 1}, ok: {오늘: 2}}`, trigram `{ok 오늘: {sy키보드: 2}, 오늘 ok: {오늘: 2}}`.
   단독 한글·영어 키보드 화면은 미확인이다. 지구본 키 `idb ui tap`이 iOS 18.6에서 반응하지 않아 키보드를 바꾸지 못했다.
6. **확인.** '학습 데이터 초기화' → 'Confirm' 뒤 `ngram_ko-en.plist`가 사라졌다.

- [x] **Step 4: 실기기 확인 항목을 사용자에게 넘긴다**

아래는 이 세션에서 할 수 없으므로 사용자 확인 항목으로 적는다.

- 실기기에서 Step 3의 1~5
- Instruments에서 `NGramBackgroundLoad` signpost 구간과 메모리로 통합 파일 로드 시간·최대치 확인(spec 6-1 참고값: M3 Pro 최악 로드 약 585ms, `ru_maxrss` +25MB)

**Step 4 결과**: 위 목록과 Step 3의 1번(전환 직후 후보)·5번(단독 키보드 화면)을 사용자 확인 항목으로 최종 보고에 넘겼다.

- [x] **Step 5: 결과를 기록하고 커밋**

```bash
git add docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "docs: #157 - 통합 NGram 전체 빌드·테스트·시뮬레이터 확인 결과 기록" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## 설계 변경 뒤 추가 Task (2026-09-25)

spec 「3. 언어 전환 경계 제거」와 「설계 변경 이력」을 구현한다. 한/A 전환은 자판만 바꾸고 후보 바·현재 단어·문맥은
그대로 둔다. #46의 언어 구간(`KeyboardLanguageSegmentTracker`)과 Task 4~6·수정 단계에서 구간과 전체 버퍼를
오가려고 만든 코드(`KeyboardNGramContextPolicy`, `nGramContext`)를 없앤다. 한글 조합 확정은 유지한다.
Global Constraints는 그대로 적용한다. 단, "NGram 후보 앞 공백 삽입은 언어 구간 기준 유지" 항목은 구간이
없어지므로 전체 `inputBuffer` 기준이 된다(단독 키보드와 같은 코드).

기준 커밋: develop merge base `773401e5`. Task 9 시작 HEAD는 spec 커밋 뒤의 이 계획 커밋이다.

### Task 9: 언어 전환 경계 제거

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift` (`applyLanguageMode`)
- Delete: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageSegmentTracker.swift`
- Delete: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift`
- Delete: `SYKeyboardTests/Utils/KeyboardLanguageSegmentTrackerTests.swift`
- Delete: `SYKeyboardTests/Utils/KeyboardNGramContextPolicyTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (`membershipExceptions` 두 목록에서 위 두 production 파일 줄 삭제)

**Interfaces:**
- Consumes: Task 3의 `SuggestionController.init(language:nGramLanguage:...)`, Task 2의 `NGramPredictiveTextEngine.hangeulEnglishLanguage`. `SuggestionService`의 3인자 `updateSuggestions(for:selectedText:mathExpressionText:)`와 1인자 `updateSuggestionsAfterNGramSelection(inputBuffer:)`는 지금 extension forwarder로 남아 있어 develop 형태의 호출이 그대로 컴파일된다.
- Produces: `BaseKeyboardViewController.init(language: String, nGramLanguage: String? = nil)`(유지). `clearSuggestionsForLanguageChange()`, `markCurrentInputBufferAsLanguageBoundary()`, `currentLanguageInputBuffer`, `languageSegmentTracker`는 사라진다.

VC는 주입할 수 없어 새 unit test가 없다. 동작 확인은 Task 12의 시뮬레이터 확인이다.

- [x] **Step 1: Base VC를 develop 버전으로 되돌린다**

이 브랜치가 Base VC에 한 변경은 `init`의 `nGramLanguage` 인자를 빼면 모두 언어 구간 배선이다(b2188026, 3d18886b, b7287fc6). develop 버전에서 시작한다.

```bash
git checkout 773401e5 -- Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

- [x] **Step 2: `init`에 NGram 식별자를 다시 받는다**

`public init(language: String) {` 블록을 아래로 바꾼다.

```swift
    /// - Parameters:
    ///   - language: 키보드 언어. `UITextChecker` 언어로도 쓴다
    ///   - nGramLanguage: NGram 엔진 식별자. `nil`이면 `language`를 따른다
    public init(language: String, nGramLanguage: String? = nil) {
        self.suggestionController = SuggestionController(language: language, nGramLanguage: nGramLanguage)
        super.init(nibName: nil, bundle: nil)
    }
```

- [x] **Step 3: 언어 구간을 없앤다**

1. 아래 선언 4줄을 지운다.

   ```swift
       private var languageSegmentTracker = KeyboardLanguageSegmentTracker()
       private var currentLanguageInputBuffer: String {
           return languageSegmentTracker.currentSegment(in: inputBuffer)
       }
   ```

2. `languageSegmentTracker.`로 시작하는 줄을 모두 지운다(`insert`, `delete(count:)`, `replace(deleteCount:insertText:)`, `resetForExternalContext()`, `markLanguageBoundary()`).
3. 아래 두 함수를 문서 주석과 함께 지운다.

   ```swift
       /// 언어 전환 전 후보와 대치 이력을 비웁니다.
       public final func clearSuggestionsForLanguageChange() {
           suggestionController.clearSuggestions()
           suggestionController.clearReplacementHistory()
       }

       /// 현재 입력 버퍼 위치를 새 언어 segment의 시작점으로 표시합니다.
       public final func markCurrentInputBufferAsLanguageBoundary() {
           languageSegmentTracker.markLanguageBoundary()
       }
   ```

4. 남은 `currentLanguageInputBuffer`를 모두 `inputBuffer`로 바꾼다.

   ```bash
   sed -i '' 's/currentLanguageInputBuffer/inputBuffer/g' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
   ```

5. `inputBuffer` 문서 주석(`/// 현재 키보드 세션에서 직접 입력한 텍스트를 추적하는 버퍼`)은 그대로 둔다.

- [x] **Step 4: 한영 VC의 전환 절차에서 후보 비우기와 경계 표시를 뺀다**

`HangeulEnglishKeyboardViewController.applyLanguageMode`에서 아래 두 줄만 지운다. 조합 확정, `updateSuggestionLanguage(to:)`, 버튼·자판 갱신은 그대로 둔다.

```swift
        clearSuggestionsForLanguageChange()
        markCurrentInputBufferAsLanguageBoundary()
```

- [x] **Step 5: 쓰지 않게 된 파일을 지운다**

```bash
git rm Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageSegmentTracker.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift \
  SYKeyboardTests/Utils/KeyboardLanguageSegmentTrackerTests.swift \
  SYKeyboardTests/Utils/KeyboardNGramContextPolicyTests.swift
```

`SYKeyboard.xcodeproj/project.pbxproj`에서 아래 두 줄은 각각 두 번 나온다. 네 줄 모두 지운다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageSegmentTracker.swift,
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardNGramContextPolicy.swift,
```

- [x] **Step 6: 남은 참조가 없는지 확인한다**

```bash
grep -rn "KeyboardLanguageSegmentTracker\|KeyboardNGramContextPolicy\|currentLanguageInputBuffer\|languageSegmentTracker\|LanguageBoundary\|clearSuggestionsForLanguageChange" \
  --include='*.swift' --include='*.pbxproj' Modules Keyboards SYKeyboard SYKeyboardTests SYKeyboard.xcodeproj
git diff 773401e5 -- Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: grep 결과 없음. develop 대비 Base VC diff는 `init` 변경, 구간 관련 선언·호출·두 함수 삭제, `currentLanguageInputBuffer` → `inputBuffer` 치환뿐이다.

- [x] **Step 7: 빌드와 테스트를 확인한다**

사용자에게 오래 걸린다고 알린 뒤 실행한다.

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: `** BUILD SUCCEEDED **`. `.xcscheme` `RemotePath` 변경은 되돌린다.

Run: Global Constraints 테스트 명령, `-only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests -only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests -only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests`

Expected: 전부 통과(테스트 타깃 전체가 컴파일되므로 지운 테스트 파일의 잔여 참조도 여기서 드러난다)

- [x] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "refactor: #157 - 한/A 전환 시 자판만 바뀌도록 언어 전환 경계 제거" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

(`git rm`한 네 파일은 이미 스테이징되어 함께 커밋된다.)

**결과:** Step 6 grep(`KeyboardLanguageSegmentTracker|KeyboardNGramContextPolicy|currentLanguageInputBuffer|languageSegmentTracker|LanguageBoundary|clearSuggestionsForLanguageChange`)은 결과 없음. `git diff 773401e5 -- BaseKeyboardViewController.swift`는 `init` 변경, 구간 선언·호출·두 함수 삭제, `currentLanguageInputBuffer` → `inputBuffer` 치환만 남음(+19 -36). `xcodebuild build -scheme HangeulEnglishKeyboard`는 `** BUILD SUCCEEDED **`(로그: `sdd-logs/task9-build.log`), `.xcscheme` 변경 없음. `xcodebuild test -scheme SYKeyboard -only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests -only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests -only-testing:SYKeyboardTests/SuggestionControllerNGramContextTests`는 3 suites 14 tests 전부 통과(로그: `sdd-logs/task9-test.log`). 단독 한글/영어 VC는 여전히 `super.init(language:)` 1인자 호출만 써서 `nGramLanguage`가 `nil`로 develop과 동일하게 동작함을 확인.

### Task 10: 통합 NGram 전환에서 후보를 비우지 않기와 `nGramContext` 제거

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift`

**Interfaces:**
- Consumes: Task 9 이후 Base VC는 3인자·1인자 호출만 쓴다.
- Produces: `SuggestionService`가 develop과 같은 시그니처(`updateSuggestions(for:selectedText:mathExpressionText:)`, `updateSuggestionsAfterNGramSelection(inputBuffer:)`)로 돌아간다. 통합 NGram에서 `updateLanguage(to:)`는 TextChecker 언어만 바꾼다.

- [x] **Step 1: Task 4의 `nGramContext` 변경을 되돌린다**

Task 4 커밋(`403c5417`) 뒤로 세 파일을 고친 커밋은 없으므로 역패치가 그대로 적용된다(적용 가능 확인됨).

```bash
git show 403c5417 -- Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift | git apply -R
git diff --stat
```

Expected: 세 파일만 바뀐다. `SuggestionControllerNGramContextTests` suite가 사라지고, `SuggestionService.swift`는 develop과 같아진다(`git diff 773401e5 -- Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` 결과 없음).

- [x] **Step 2: 실패하는 테스트를 쓴다**

`SuggestionControllerUnifiedNGramTests` suite의 마지막 테스트 뒤에 넣는다.

```swift
    @Test("통합 NGram은 언어를 바꿔도 후보를 비우지 않음")
    func test통합NGram은_언어를바꿔도_후보를비우지않음() async {
        let factory = CountingSuggestionEngineFactory()
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeUnifiedController(factory: factory)
        controller.delegate = delegate
        controller.updateSuggestions(for: "오늘 ")
        factory.lastNGramProvider?.completeLoad(suggestions: ["meeting"])
        await waitForMainQueue()
        let updateCount = delegate.updates.count

        controller.updateLanguage(to: "en-US")

        #expect(delegate.updates.count == updateCount)
        #expect(controller.currentMode == .nGram)
        #expect(controller.nGramSuggestionText(at: 0) == "meeting")
    }
```

- [x] **Step 3: 테스트가 실패하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests`

Expected: 새 테스트 실패(`updateLanguage`가 `clearSuggestions()`로 delegate를 한 번 더 부르고 후보를 비움)

- [x] **Step 4: 통합 NGram의 `updateLanguage`를 바꾼다**

```swift
    func updateLanguage(to language: String) {
        guard self.language != language else { return }

        // 통합 NGram(한영 키보드)은 한/A 전환에서 자판만 바뀌어야 하므로 TextChecker 언어만 바꾸고
        // NGram 엔진·문장 버퍼·후보·마지막 요청 상태는 그대로 둔다
        guard nGramLanguage == nil else {
            self.language = language
            return
        }

        // 전환 전 언어의 학습 결과는 즉시 보존하되, 엔진 자체는 캐시에 남겨
        // 같은 언어로 돌아왔을 때 디스크 로드를 반복하지 않는다
        nGramEngine?.saveToDisk()
        engineGeneration += 1
        self.language = language
        lastSuggestionBaseText = nil
        lastMathExpressionText = nil
        lastSuggestionOrigin = nil
        currentMathCompletion = nil
        currentMathSuggestionOrigin = nil
        clearSuggestions()
    }
```

- [x] **Step 5: 테스트가 통과하는 것을 확인한다**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests -only-testing:SYKeyboardTests/SuggestionControllerSuspensionTests -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests -only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests -only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests`

Expected: 전부 통과. `SuggestionControllerPreparationTests`의 언어별 전환 테스트(저장·세대 증가·stale 콜백 무시)가 그대로 통과해야 한다.

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "feat: #157 - 한/A 전환 시 통합 NGram 후보를 유지하고 NGram 조회 문맥 분리 제거" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

**결과**: Step 1 역패치로 3개 파일만 바뀌었고 `SuggestionService.swift`는 develop(773401e5)과 동일함을
`git diff` 빈 결과로 확인. RED: `SuggestionControllerUnifiedNGramTests` 6개 중 새 테스트 1개만 예상대로
실패(`delegate.updates.count == updateCount` 3≠2, `nGramSuggestionText(at: 0)` nil≠"meeting"), 나머지
5개 통과. GREEN: 8개 suite 69개 테스트 전부 통과(iPhone 13 mini / iOS 18.6). HangeulEnglishKeyboard
scheme 빌드 성공(BUILD SUCCEEDED), `.xcscheme` 변경 없음. 자기 리뷰: `nGramLanguage == nil` 분기 본문이
develop의 `updateLanguage` 본문과 라인 단위로 동일함을 `git show develop:...` 비교로 확인.

### Task 11: 아키텍처 문서를 경계 없는 구조로 갱신

**Files:**
- Modify: `docs/architecture/한영 통합 키보드.md`, `docs/architecture/자동완성 로직.md`, `docs/architecture/전체 아키텍처.md`

- [x] **Step 1: 문서를 고친다**

CLAUDE.md 「문서 작성 규칙」을 따르고, 각 문서의 기존 구조를 유지한 채 해당 부분만 고친다. 코드(Task 9·10 이후)를 직접 읽고 쓴다.

- `한영 통합 키보드.md`
  - 전환 절차 목록(~:119-120)에서 `clearSuggestionsForLanguageChange()`, `markCurrentInputBufferAsLanguageBoundary()` 단계를 지우고, 전환은 자판·조합 확정·TextChecker 언어만 바꾸며 후보 바와 대치 이력은 유지한다고 적는다.
  - §4 "inputBuffer 공유와 언어 경계 — KeyboardLanguageSegmentTracker"(~:129-155)를 "inputBuffer 공유 — 언어 경계 없음"으로 다시 쓴다. 두 언어가 하나의 `inputBuffer`를 그대로 공유하고 모든 입력 보조(NGram, 단어 완성, 자동 대치와 되돌리기, 수식, NGram 후보 앞 공백)가 전체 버퍼를 본다. 섞인 단어(`SY키보`)는 TextChecker 완성이 약하고 #158이 보완한다는 한계도 적는다.
  - §5 통합 NGram 설명에서 `updateLanguage`가 통합 NGram일 때 TextChecker 언어만 바꾼다는 점을 반영한다.
  - 테스트 표·명령(~:237, :249)에서 `KeyboardLanguageSegmentTrackerTests`를 지운다.
- `자동완성 로직.md`: `currentLanguageInputBuffer`, `KeyboardNGramContextPolicy`, `nGramContext`, `attachedPrefix`, `wordsToRecordAfterCompletion`, `sentenceBufferActionAfterDelete`를 언급하는 곳(~:36-37, :53, :166-170, :182, :236-237, :470-491, :629, :659)을 경계 없는 현재 코드에 맞게 고친다. 후보 선택은 `recordWord(result.insertText)`로 통째 기록(여러 단어 후보 포함, 의도된 동작), 0번 칸 확정은 현재 단어, 스페이스·리턴·삭제는 `inputBuffer` 기준이다.
- `전체 아키텍처.md`: ~:50의 구간 설명, ~:186 `KeyboardLanguageSegmentTracker` 행을 지우거나 고친다.

- [x] **Step 2: 남은 언급이 없는지 확인한다**

```bash
grep -rn "KeyboardLanguageSegmentTracker\|currentLanguageInputBuffer\|KeyboardNGramContextPolicy\|nGramContext\|attachedPrefix\|wordsToRecordAfterCompletion\|clearSuggestionsForLanguageChange\|markCurrentInputBufferAsLanguageBoundary" docs/architecture
```

Expected: 결과 없음

실행 결과: 종료 코드 1(매치 없음). `grep -rn "언어 구간\|언어 경계" docs/architecture`로 남은
"언어 경계" 언급도 모두 확인했고, 전부 "경계가 없다"는 새 설명이거나 §8-2의 `SY키보` 한계 설명이다.
`docs/architecture/README.md`의 한영 통합 키보드 요약 행("언어 경계 추적")과
`자동완성 로직.md` §6 흐름표의 `wordsToRecordAfterCompletion` 잔여 언급도 같은 확인 중 발견해 함께 고쳤다.

- [x] **Step 3: 커밋**

```bash
git add "docs/architecture/한영 통합 키보드.md" "docs/architecture/자동완성 로직.md" "docs/architecture/전체 아키텍처.md" \
  docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "docs: #157 - 아키텍처 문서를 언어 전환 경계 없는 구조로 갱신" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

**결과**: 코드(Task 9·10)를 직접 읽어 `applyLanguageMode`(9·10단계 삭제 확인),
`SuggestionController.updateLanguage`(통합 NGram 경로 early return 확인), `BaseKeyboardViewController`의
`updateSuggestions`/`deleteText`/`handleInputBufferSuggestion` 등을 근거로 세 문서를 갱신했다.
`docs/architecture/README.md`도 한 줄 함께 고쳤다(Task 11 파일 목록 밖이지만 같은 확인 과정에서 발견한
사실 오류라 별도 변경으로 미루지 않고 반영). 빌드/테스트는 문서 전용 작업이라 실행하지 않았다.

### Task 12: 전체 검증

- [x] **Step 1: 4개 scheme 빌드와 전체 테스트**

Task 8 Step 1·2와 같은 명령으로 실행하고, `.xcresult` 경로와 추출 명령·결과 개수를 적는다.

**결과 (iPhone 13 mini / iOS 18.6, 2026-09-25):**

| scheme | 결과 | 로그 |
| --- | --- | --- |
| `SYKeyboard` (build) | `** BUILD SUCCEEDED **` | `sdd-logs/task12-build-sykeyboard.log` |
| `HangeulKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task12-build-hangeul.log` |
| `EnglishKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task12-build-english.log` |
| `HangeulEnglishKeyboard` | `** BUILD SUCCEEDED **` | `sdd-logs/task12-build-hangeulenglish.log` |

4개 빌드 모두 foreground로 순서대로 실행. 각 빌드 뒤 `git status --short`는 비어 있어 `.xcscheme` `RemotePath` 변경이 발생하지 않았다(되돌릴 것 없음).

전체 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  -resultBundlePath <scratchpad>/sdd-logs/task12-full.xcresult \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'
```

`** TEST SUCCEEDED **`, Swift Testing 요약 `Test run with 760 tests in 84 suites passed after 5.900 seconds.` (Task 8 시점 779 tests/87 suites 대비 감소는 Task 9~11에서 `KeyboardNGramContextPolicy`·언어 구간 관련 테스트를 제거했기 때문이다.)

`.xcresult` 경로:
`/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/3526bae6-16dc-4bec-b303-db0928873699/scratchpad/sdd-logs/task12-full.xcresult`

추출 명령: `xcrun xcresulttool get test-results summary --path <위 xcresult 경로>`

추출 결과 요약: `result: "Passed"`, `totalTestCount: 760`, `passedTests: 760`(디바이스별 `passedTests: 805`는 dynamic-parameter 확장 포함), `failedTests: 0`, `skippedTests: 0`, `expectedFailures: 0`. 로그: `sdd-logs/task12-full-test.log`. 테스트 뒤 `git status --short`도 비어 있어 되돌릴 `.xcscheme` 변경 없음.

- [x] **Step 2: 시뮬레이터 확인 (컨트롤러가 idb로 수행)**

한영 키보드, iPhone 13 mini / iOS 18.6, 앱 '터치하여 키보드 테스트' 입력창. 확인 동안만 `isClipboardHistoryEnabled`를 끄고 끝나면 되돌린다.

1. 영어 'sy' → 한/A → 후보 바가 그대로 남고, 남은 영어 완성 후보를 누르면 `sy`가 그 후보로 대치된다(`"sysystem"` 같은 결과가 없다).
2. '오늘' 스페이스 → 한/A → 후보 바가 비지 않고 '오늘' 뒤 문맥 후보가 그대로 보인다.
3. 영어 'sy' → 한/A(스페이스 없이) → '키보드' 스페이스 → 리턴 뒤 NGram 파일에 `sy키보드`가 한 번 기록되고 `키보드`·`sy`가 따로 기록되지 않는다.
4. 영어 'sy' → 한/A → '키보' → 완성 후보 선택 → 리턴 뒤 입력창과 NGram 기록이 일치한다(스마트 공백으로 쪼개지지 않음).
5. '오늘' 스페이스 → 한/A → 백스페이스 → 스페이스에서 문맥 후보가 유지된다.
6. 한글 '키' → 한/A → 한/A → 'ㅂ'을 치면 새 글자가 시작된다(조합 확정 유지).

**Step 2 결과 (2026-09-25, 컨트롤러가 idb로 실행, iPhone 13 mini / iOS 18.6, 한영 키보드 확장 빌드 13:43:56 = cd57c5dc 코드)**
확인 동안 App Group `isClipboardHistoryEnabled`를 `false`로 두었다가 끝난 뒤 `true`로 되돌렸다.

1. 확인. 영어 'sy' → 후보 `"sy", sync, symptoms` → 한/A 뒤 후보 바가 그대로 남고 자판만 바뀌었다. 남은 `sync`를 누르니 입력창이 `sync`가 되었다(`sysync` 없음).
2. 확인. '오늘' 스페이스 → 후보 `ok, 아, 키보드` → 한/A 뒤에도 같은 후보가 그대로 보인다.
3. 확인. '아' 스페이스 → 한/A → 'sy' → 한/A(스페이스 없이) → '키보드' 스페이스 → 리턴 뒤 NGram: `sy키보드` 2→3, bigram `아 → sy키보드` 2→3, `키보드` 3 그대로, `sy` 기록 없음. 입력창 `아 sy키보드 `.
4. 해당 없음(알려진 한계). '아' 스페이스 → 한/A → 'sy' → 한/A → '키보' 뒤 후보 바에는 0번 칸 `"sy키보"`만 있고 완성 후보가 없다(`UITextChecker`가 섞인 단어를 통째로 받음, #158에서 보완). 고를 후보가 없으므로 스마트 공백으로 단어가 쪼개지는 경로가 생기지 않는다.
5. 확인. '오늘' 스페이스 → 한/A → 백스페이스 → 스페이스 뒤 후보 `ok, 아, 오늘`로 '오늘' 뒤 문맥이 유지된다.
6. 확인. '키' → 한/A → 한/A → 'ㅂ' 뒤 입력창 `키ㅂ`(조합 확정 유지).

- [x] **Step 3: 결과를 기록하고 커밋**

```bash
git add docs/superpowers/plans/2026-09-25-issue-157-hangeul-english-unified-ngram.md
git commit -m "docs: #157 - 언어 전환 경계 제거 뒤 전체 검증 결과 기록" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

### Task 13: 한/A 전환 시 NGram 후보를 새 언어 순서로 다시 정렬

실기기 확인에서 "전환 직후 문자 종류 순서가 바로 바뀔 때와 안 바뀔 때가 있다"는 보고가 있었다. 임시 로그
(커밋하지 않음)로 확인한 결과, `applyLanguageMode`는 후보를 다시 계산하지 않고 iOS가 전환 뒤
`textWillChange`/`textDidChange`를 보낼 때만 `updateSuggestions()`가 돌았다. 시뮬레이터(iPhone 13 mini / iOS 18.6)에서
필드 포커스·탭 직후에는 전환마다 약 15~20ms 뒤 콜백이 왔고, 키보드로 글자·스페이스·삭제를 입력한 뒤에는
다음 필드 탭 전까지 오지 않았다. 사용자 확인 뒤 NGram 후보를 보이는 중에만 전환 시 직접 다시 정렬하기로 했다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`updateLanguage(to:)`, `refreshNGramSuggestionsForLanguageModeChange()`)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift` (stub `resultsByPreferredScript`)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerUnifiedNGramTests.swift`
- Modify: `docs/architecture/한영 통합 키보드.md`, `docs/architecture/자동완성 로직.md`, 설계 문서 4절·변경 이력

- [x] **Step 1: 실패하는 테스트**

`test통합NGram후보를보이는중_언어를바꾸면_새언어순서로다시보냄`(한글 모드 `["아","ok"]` → 영어 전환 뒤 `["ok","아"]`)와
`test입력중후보를보이는중에는_언어를바꿔도_다시계산하지않음`(typing 모드에서 전환 뒤 delegate 전달·NGram 조회 횟수 불변)을 추가했다.
`-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests` 결과 앞 테스트만 실패(`delegate.updates.last?.suggestions → ["아", "ok"]`).
실패 뒤 xcodebuild가 `simctl diagnose`로 진단을 모으느라 끝나지 않아 프로세스를 종료했다(테스트 자체는 0.03초에 끝남).

- [x] **Step 2: 구현**

통합 NGram(`nGramLanguage != nil`)의 `updateLanguage(to:)`가 `language`를 바꾼 뒤
`refreshNGramSuggestionsForLanguageModeChange()`를 부른다. 자동완성이 켜져 있고 일시 중단이 아니며
`currentMode == .nGram`이고 `lastSuggestionBaseText`가 있을 때만 `nGramSuggestions(for:)`로 다시 조회하고,
후보 텍스트 순서가 달라졌을 때만 `currentSuggestions`를 바꾸고 delegate로 보낸다.

기존 `test통합NGram조회는_현재언어모드의문자종류를넘김`의 기대값은 전환 자체의 재조회가 더해져
`[.hangeul, .latin, .latin]`이 되었다. typing 테스트는 비동기 TextChecker 결과가 늦게 도착해 횟수가 흔들렸으므로
직렬 `textCheckerQueue`를 넣고 `queue.sync {}` 뒤 기준 횟수를 잡는다.

- [x] **Step 3: 검증**

- 같은 suite 3회 연속: `Test run with 8 tests in 1 suite passed` ×3
- 전체: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -parallel-testing-enabled NO GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'`
  → `** TEST SUCCEEDED **`, `Test run with 762 tests in 84 suites passed after 6.155 seconds.` 로그: `<scratchpad>/t13-full.log`
- 시뮬레이터(idb, 확인 동안만 `isClipboardHistoryEnabled` false): 영어 'a' 스페이스 → 후보 `ok, sync, A` → 한/A 뒤 `아, 오늘, sy키보드`
  → 한/A 뒤 `ok, sync, A`로 매번 바로 바뀜(수정 전에는 입력 뒤 전환에서 바뀌지 않음). 영어 'a' 입력 중 한/A 뒤에는 `"a", and, are` 그대로.

### Task 14: `pruneKeys` 정상 경로를 정렬 없이 최솟값 1개 제거로 변경

성능 측정(설계 문서 6-2)에서 `addWord` 시간의 약 98%가 `pruneKeys`였고, 하루 1,000단어 × 1년 파일도 키가 이미
상한이라 같은 비용이 들었다. 사용자 확인 뒤 동작을 유지하는 방식으로 이 브랜치에서 고쳤다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (`pruneKeys(in:)`)
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEnginePruneTests.swift`
- Modify: `docs/architecture/자동완성 로직.md`, 설계 문서 6-2

- [x] **Step 1: 현재 동작을 고정하는 테스트**

bigram·trigram 문맥 키 상한 정리 테스트가 없어 `maxKeys: 3`에서 총 빈도가 가장 낮은 문맥이 지워지는지 확인하는
테스트 2개를 추가했다. 수정 전 코드에서 `-only-testing:SYKeyboardTests/NGramPredictiveTextEnginePruneTests`
→ `Test run with 2 tests in 1 suite passed`(동작 고정용이라 처음부터 통과).

- [x] **Step 2: 구현**

`removeCount == 1`이면 키를 한 번 훑어 총 빈도 최솟값 1개만 지운다(동률은 기존과 같이 딕셔너리 순서상 첫 최솟값).
2개 이상 초과는 기존 정렬 방식을 유지한다.

- [x] **Step 3: 검증**

- 전체: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -parallel-testing-enabled NO GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'`
  → `** TEST SUCCEEDED **`, `Test run with 764 tests in 85 suites passed after 5.951 seconds.` 로그: `<scratchpad>/prune-full.log`
- 성능: 버리는 측정 테스트(`<scratchpad>/bench/ZZNGramPerfMeasureTests.swift`, 커밋하지 않음)를 `SWIFT_OPTIMIZATION_LEVEL=-O`
  `build-for-testing` 뒤 시나리오마다 `test-without-building -only-testing:SYKeyboardTests/ZZNGramPerfMeasureTests/<시나리오>()`로 실행.
  결과는 `<scratchpad>/perf-results-run3-prunefix.txt`, 수정 전은 `<scratchpad>/perf-results-run2.txt`. 요약은 설계 문서 6-2.
