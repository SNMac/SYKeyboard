# 입력 중 NGram 단어 완성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 단어를 입력하는 도중에도 NGram에 학습된 단어(섞인 단어 'SY키보드' 포함)를 완성 후보로 보여준다.

**Architecture:** 새 순수 타입 `PredictiveTextCompletionMatchPolicy`가 "입력 중인 단어를 이어 쓴 단어인가"를 대소문자 무시·마지막 글자 자모 단위로 판정한다. `NGramPredictiveTextEngine.completions(forTypedWord:previousWord:limit:)`가 이 규칙으로 bigram 후보를 먼저, unigram 빈도순을 뒤에 돌려주고, `SuggestionController`가 입력 중 모드에서 lexicon → NGram 완성(최대 3개) → TextChecker 순으로 병합한다. 후보 선택·삭제·학습은 기존 `.nGram` 출처 경로를 그대로 탄다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26 이상

**Spec:** `docs/superpowers/specs/2026-09-25-ngram-typing-completion-design.md`

## Global Constraints

- 작업 브랜치는 `feat/#158-ngram-typing-completion`이다(`develop` 위). Task 0에서 만든다.
- 커밋 메시지는 `type: #158 - subject` 형식, 한국어, 마침표 없음. 끝에 아래 줄을 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.

  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  ```

- CLAUDE.md 「Superpowers 계획 실행」을 따른다. step은 작업과 검증이 모두 끝난 직후에만 체크한다. **Task마다 마지막 커밋 step에서** 그 Task의 코드·테스트와 이 문서(체크박스, 실제 결과: 테스트 개수, 빌드 결과, 확인하지 못한 항목)를 한 커밋으로 남긴다. 다음 Task는 직전 Task 커밋 뒤에 시작한다.
- 수치는 spec 그대로다. NGram 완성은 입력 중 모드에서 **lexicon 뒤, TextChecker 앞, 최대 3개**, 입력 중 후보 전체는 기존대로 9칸(`maxSuggestions - 1`). bigram 문맥은 바로 앞 단어 하나. trigram은 보지 않는다.
- 세 키보드(단독 한글·단독 영어·한영 통합) 모두 같은 `SuggestionController` 경로로 적용한다. 키보드별 분기를 넣지 않는다.
- 완성 후보에는 `preferredScript`(문자 종류 우선 정렬)를 쓰지 않는다. 한/A 전환 때 입력 중 후보를 다시 계산하는 경로를 만들지 않는다(#157 「자판만 바뀐다」 원칙).
- 접두어 규칙은 spec 1절 그대로다. 모음 합성(ㅘ, ㅐ)과 쌍자음은 나누지 않는다. 나랏글·천지인 중간 상태 보정을 넣지 않는다.
- 완성 후보 출처는 기존 `SuggestionItem.Source.nGram`을 쓴다. 새 출처 case를 만들지 않는다.
- 후보 선택 경로(`BaseKeyboardViewController.handleInputBufferSuggestion`)와 스마트 공백 규칙은 바꾸지 않는다.
- 공백이 든 NGram 단어를 새로 만드는 경로를 두지 않는다(#157 설계 「유지하는 동작」).
- **`Modules/`에 새 파일을 만들면 `SYKeyboard.xcodeproj/project.pbxproj`를 함께 고친다.** `Exceptions for "Modules" folder in "SYKeyboard" target`과 `... in "SYKeyboardCore" target` 두 `membershipExceptions` 목록에 알파벳 순서로 경로를 넣는다. `SYKeyboardTests/`의 새 테스트 파일은 pbxproj를 고치지 않는다.
- 로그와 임시 파일은 세션 scratchpad에 둔다. 아래 명령의 `"$SCRATCH"`는 그 절대 경로다. 저장소 안에 로그나 `.xcresult`를 만들지 않는다.
- 테스트 기준 기기는 `iPhone 13 mini / iOS 18.6`이다. 테스트 명령에는 반드시 `-parallel-testing-enabled NO`와 `GADApplicationIdentifier`를 붙인다. 빼면 테스트 호스트가 AdMob 초기화에서 크래시한다.

  ```sh
  xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    -parallel-testing-enabled NO \
    GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
    -only-testing:SYKeyboardTests/<SuiteType> \
    > "$SCRATCH/<로그이름>.log" 2>&1; tail -30 "$SCRATCH/<로그이름>.log"
  ```

  `<SuiteType>`은 `@Suite` 표시 이름이 아니라 **타입 이름**이다. 여러 suite는 `-only-testing`을 여러 번 쓴다.
- `xcodebuild`는 수 분 걸린다. 실행 전에 사용자에게 오래 걸린다고 알린다. 서브에이전트에 맡길 때는 foreground로 `timeout: 600000`을 주고, 몇 분씩 진행이 없으면 기다리지 말고 보고하게 한다(CLAUDE.md 「호스트 앱이 뜨지도 않고 테스트가 매달리는 경우」, 「붙여넣기 권한 알림으로 테스트가 끝나지 않는 경우」). 이 두 경우는 코드 실패로 기록하지 않는다.
- extension scheme을 빌드할 때는 `-only-testing`과 code coverage 옵션을 비운다. 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌리고 커밋하지 않는다. 다른 항목이 바뀌었으면 되돌리지 말고 사용자에게 알린다.
- `SYKeyboard/Resources/Configs/Secrets.xcconfig`, Firebase, AdMob, entitlements, bundle 설정은 건드리지 않는다.
- `git add`는 항상 파일을 명시한다. push·PR 생성은 사용자가 명시할 때만 한다.
- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)이고 production 진입점을 호출한다. production 클래스에 `ForTesting` 메서드를 넣지 않는다.

## Review Focus

- 한영 통합 키보드에서 'SY키' 입력 중 한/A를 누르면 입력 중 후보(완성 후보 포함)가 다시 계산되거나 바뀌면 안 된다 → Task 4 테스트 `test한A전환은_입력중NGram완성후보를_다시조회하지않음`.
- 키보드를 막 열어 NGram이 디스크를 읽는 중에 입력하면 완성 후보가 없다가, 로딩이 끝나면 같은 입력에 대해 채워져야 한다 → Task 4 테스트 `testNGram로딩이끝나면_입력중후보에_완성후보를채움`.
- 천지인 `ᆢ`(U+11A2)는 앞의 완성형 글자와 한 `Character`로 묶인다(`"고ᆢ".count == 1`). 문자 단위로 떼면 놓친다 → Task 1 테스트 인자 `("고양이", "고\u{11A2}")`.
- 입력 단어와 대소문자만 다른 학습 단어("keyboard" 입력 중 "KEYBOARD")가 완성 칸 하나를 차지하면 안 된다 → Task 1 `test입력단어와같은단어는_대소문자가달라도_완성이아님`, Task 3 `test입력중인단어와같은단어는_빼고반환`.
- lexicon과 NGram 완성이 9칸을 다 채우면 TextChecker 조회를 건너뛰어야 한다(12~22ms 조회 낭비) → Task 4 테스트 `testLexicon과NGram완성이_9칸을채우면_TextChecker를조회하지않음`.

---

### Task 0: 작업 브랜치와 설계·계획 커밋

**Files:**
- Create: `docs/superpowers/specs/2026-09-25-ngram-typing-completion-design.md` (계획 작성 시 이미 만들어져 있음)
- Create: `docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md` (이 문서)

- [x] **Step 1: 작업 트리 상태를 확인한다**

Run: `git status --short && git branch --show-current`
Expected: `develop`이고, 추적되지 않은 파일은 위 두 문서뿐이다. 다른 변경이 있으면 멈추고 사용자에게 알린다.

- [x] **Step 2: 브랜치를 만든다**

Run: `git switch -c 'feat/#158-ngram-typing-completion'`
Expected: `Switched to a new branch 'feat/#158-ngram-typing-completion'`

- [x] **Step 3: 커밋**

이 step을 체크한 뒤 커밋한다.

```bash
git add docs/superpowers/specs/2026-09-25-ngram-typing-completion-design.md docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
docs: #158 - 입력 중 NGram 완성 설계 문서와 구현 계획 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 1: 접두어 판정 policy

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextCompletionMatchPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 `membershipExceptions` 목록)
- Test: `SYKeyboardTests/Utils/PredictiveTextCompletionMatchPolicyTests.swift`

**Interfaces:**
- Produces:
  - `struct PredictiveTextCompletionMatchPolicy`
  - `init?(typedWord: String)` — 비교할 글자가 없으면(빈 문자열, 천지인 조합 중 모음뿐) `nil`
  - `func isCompletion(_ candidate: String) -> Bool`

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/PredictiveTextCompletionMatchPolicyTests.swift`:

```swift
//
//  PredictiveTextCompletionMatchPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import SYKeyboardCore

@Suite("NGram 완성 후보 접두어 판정 검증")
struct PredictiveTextCompletionMatchPolicyTests {

    @Test("라틴 문자는 대소문자를 무시하고 접두어로 비교", arguments: [
        ("hello", "hel"), ("Hello", "hel"), ("SY키보드", "sy"), ("SY키보드", "sy키"), ("sy키보드", "SY키볻")
    ])
    func test라틴문자는_대소문자를무시하고_접두어로비교(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("마지막 받침은 다음 글자 초성으로도 봄", arguments: [
        ("키보드", "키볻"), ("가방", "갑"), ("값", "갑")
    ])
    func test마지막받침은_다음글자초성으로도봄(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("겹받침은 두 자음으로 나눠 봄", arguments: [
        ("달걀", "닭"), ("안주", "앉"), ("닭고기", "닭")
    ])
    func test겹받침은_두자음으로나눠봄(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    // "고\u{11A2}"는 한 Character다. 스칼라 단위로 떼야 한다
    @Test("끝에 붙은 천지인 조합 중 모음은 떼고 비교", arguments: [
        ("키보드", "킵\u{318D}"), ("키보드", "키ㅂ\u{318D}"), ("여기", "ㅇ\u{11A2}"), ("고양이", "고\u{11A2}")
    ])
    func test끝에붙은_천지인조합중모음은_떼고비교(candidate: String, typedWord: String) {
        #expect(isCompletion(candidate, of: typedWord))
    }

    @Test("이어 쓴 단어가 아니면 완성이 아님", arguments: [
        ("키보드", "킴"), ("과자", "고"), ("개발", "가"), ("help", "hex"), ("가", "각"), ("달", "닭")
    ])
    func test이어쓴단어가아니면_완성이아님(candidate: String, typedWord: String) {
        #expect(!isCompletion(candidate, of: typedWord))
    }

    @Test("입력 단어와 같은 단어는 대소문자가 달라도 완성이 아님", arguments: [
        ("키보드", "키보드"), ("KEYBOARD", "keyboard")
    ])
    func test입력단어와같은단어는_대소문자가달라도_완성이아님(candidate: String, typedWord: String) {
        #expect(!isCompletion(candidate, of: typedWord))
    }

    @Test("비교할 글자가 없으면 판정하지 않음", arguments: ["", "\u{318D}", "\u{318D}\u{11A2}"])
    func test비교할글자가없으면_판정하지않음(typedWord: String) {
        #expect(PredictiveTextCompletionMatchPolicy(typedWord: typedWord) == nil)
    }
}

private func isCompletion(_ candidate: String, of typedWord: String) -> Bool {
    PredictiveTextCompletionMatchPolicy(typedWord: typedWord)?.isCompletion(candidate) == true
}
```

- [x] **Step 2: 테스트가 실패하는 것을 확인한다**

Global Constraints의 테스트 명령을 `-only-testing:SYKeyboardTests/PredictiveTextCompletionMatchPolicyTests`, 로그 이름 `158-task1-red`로 실행한다.
Expected: 컴파일 실패 `cannot find 'PredictiveTextCompletionMatchPolicy' in scope`

- [x] **Step 3: policy를 만든다**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextCompletionMatchPolicy.swift`:

```swift
//
//  PredictiveTextCompletionMatchPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/25/26.
//

import Foundation

/// 입력 중인 단어를 이어 쓴 NGram 학습 단어인지 판정하는 접두어 규칙
///
/// 대소문자를 무시하고, 아직 조합 중일 수 있는 마지막 글자만 호환 자모 단위로 비교한다.
/// `"키볻"`의 받침 ㄷ은 `"키보드"`의 다음 초성으로, `"닭"`의 겹받침 ㄺ은 `"달걀"`의 ㄹ 받침과 ㄱ 초성으로 본다.
/// 모음 합성(ㅘ, ㅐ)과 쌍자음은 나누지 않는다. 합성 전 상태에서는 목표 단어가 아직 보이지 않았으므로
/// 나누면 두벌식에서 '가'에 '개발'이 뜨는 잡음만 생긴다
struct PredictiveTextCompletionMatchPolicy {

    // MARK: - Properties

    /// 무엇이 될지 아직 모르는 천지인 조합 중 모음(ㆍ, ᆢ). 입력 끝에 있으면 떼고 비교한다.
    /// ᆢ(U+11A2)는 앞 완성형 글자와 한 `Character`로 묶일 수 있어 스칼라 단위로 뗀다
    private static let cheonjiinPendingVowels: Set<Unicode.Scalar> = ["\u{318D}", "\u{11A2}"]
    private static let choseongTable = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ".unicodeScalars)
    private static let jungseongTable = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ".unicodeScalars)
    /// 받침 없음을 뺀 종성 27개
    private static let jongseongTable = Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ".unicodeScalars)
    /// 겹받침 → 두 자음
    private static let compoundConsonants: [Unicode.Scalar: [Unicode.Scalar]] = [
        "ㄳ": ["ㄱ", "ㅅ"], "ㄵ": ["ㄴ", "ㅈ"], "ㄶ": ["ㄴ", "ㅎ"], "ㄺ": ["ㄹ", "ㄱ"],
        "ㄻ": ["ㄹ", "ㅁ"], "ㄼ": ["ㄹ", "ㅂ"], "ㄽ": ["ㄹ", "ㅅ"], "ㄾ": ["ㄹ", "ㅌ"],
        "ㄿ": ["ㄹ", "ㅍ"], "ㅀ": ["ㄹ", "ㅎ"], "ㅄ": ["ㅂ", "ㅅ"]
    ]

    /// 소문자로 바꾼 입력 단어. 같은 단어는 0번 칸이 보여주므로 완성으로 보지 않는다
    private let loweredTypedWord: String
    /// 마지막 글자를 뺀 입력. 후보가 이 문자열로 시작해야 한다
    private let head: String
    /// 마지막 글자의 호환 자모
    private let lastJamo: [Unicode.Scalar]

    // MARK: - Initializer

    /// 비교할 글자가 없으면(빈 문자열, 천지인 조합 중 모음뿐) `nil`이다
    init?(typedWord: String) {
        let lowered = typedWord.lowercased()
        var scalars = lowered.unicodeScalars
        while let last = scalars.last, Self.cheonjiinPendingVowels.contains(last) {
            scalars.removeLast()
        }
        let typed = String(scalars)
        guard let last = typed.last else { return nil }

        loweredTypedWord = lowered
        head = String(typed.dropLast())
        lastJamo = Self.jamo(of: last)
    }

    // MARK: - Internal Methods

    /// `candidate`가 입력 단어를 이어 쓴 단어면 `true`다
    func isCompletion(_ candidate: String) -> Bool {
        let lowered = candidate.lowercased()
        guard lowered.hasPrefix(head) else { return false }
        let rest = lowered.dropFirst(head.count)
        // 대부분은 다음 글자의 첫 자모에서 갈리므로 자모 배열을 만들기 전에 거른다
        guard let next = rest.first,
              Self.firstJamo(of: next) == lastJamo.first,
              lowered != loweredTypedWord else { return false }

        var candidateJamo: [Unicode.Scalar] = []
        // 글자마다 자모가 하나 이상이므로 마지막 글자의 자모 수만큼만 보면 충분하다
        for character in rest.prefix(lastJamo.count) {
            candidateJamo += Self.jamo(of: character)
        }
        return candidateJamo.starts(with: lastJamo)
    }
}

// MARK: - Private Methods

private extension PredictiveTextCompletionMatchPolicy {
    static func firstJamo(of character: Character) -> Unicode.Scalar? {
        guard let scalar = character.unicodeScalars.first else { return nil }
        if let consonants = compoundConsonants[scalar] { return consonants.first }
        guard let index = syllableIndex(of: scalar) else { return scalar }
        return choseongTable[index / 588]
    }

    static func jamo(of character: Character) -> [Unicode.Scalar] {
        let scalars = character.unicodeScalars
        guard scalars.count == 1, let scalar = scalars.first else { return Array(scalars) }
        if let consonants = compoundConsonants[scalar] { return consonants }
        guard let index = syllableIndex(of: scalar) else { return [scalar] }

        let syllable = [choseongTable[index / 588], jungseongTable[(index % 588) / 28]]
        let jongseongIndex = index % 28
        guard jongseongIndex > 0 else { return syllable }
        let jongseong = jongseongTable[jongseongIndex - 1]
        return syllable + (compoundConsonants[jongseong] ?? [jongseong])
    }

    /// 완성형 음절이면 `0xAC00`부터의 순번을 돌려준다
    static func syllableIndex(of scalar: Unicode.Scalar) -> Int? {
        guard (0xAC00...0xD7A3).contains(scalar.value) else { return nil }
        return Int(scalar.value - 0xAC00)
    }
}
```

- [x] **Step 4: pbxproj 두 목록에 파일을 넣는다**

`SYKeyboard.xcodeproj/project.pbxproj`에서 아래 줄은 두 번(`SYKeyboard` 대상, `SYKeyboardCore` 대상) 나온다. Edit을 `replace_all: true`로 써서 두 곳 모두 바로 앞에 새 경로를 넣는다(알파벳 순서상 `PredictiveTextC…`가 `PredictiveTextS…`보다 앞).

old:
```
				SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift,
```
new:
```
				SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextCompletionMatchPolicy.swift,
				SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextScriptPolicy.swift,
```

Run: `grep -c "PredictiveTextCompletionMatchPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj`
Expected: `2`

- [x] **Step 5: 테스트가 통과하는 것을 확인한다**

Step 2와 같은 명령을 로그 이름 `158-task1-green`으로 실행한다.
Expected: `PredictiveTextCompletionMatchPolicyTests` 7개 테스트(인자 포함 케이스 26개) 모두 통과, `** TEST SUCCEEDED **`

- [x] **Step 6: 커밋**

이 문서의 Task 1 체크박스와 실제 결과(통과 테스트 수)를 적은 뒤 커밋한다.

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/PredictiveTextCompletionMatchPolicy.swift SYKeyboard.xcodeproj/project.pbxproj SYKeyboardTests/Utils/PredictiveTextCompletionMatchPolicyTests.swift docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
feat: #158 - NGram 완성 후보 자모 접두어 판정 정책 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

**결과:** RED는 `cannot find 'PredictiveTextCompletionMatchPolicy' in scope` 컴파일 실패로 확인. GREEN은 `PredictiveTextCompletionMatchPolicyTests` 7개 테스트 통과(iPhone 13 mini / iOS 18.6 시뮬레이터). pbxproj 등록 2곳 확인.

---

### Task 2: 자판별 조합 중 판정 시나리오

실제 두벌식·나랏글·천지인 처리기에 키를 하나씩 넣어 화면 텍스트마다 policy 판정을 고정한다. 기대값은 spec 1절 표이며, 계획 작성 때 세 처리기 소스를 scratchpad에서 컴파일해 그대로 뽑은 값이다. 나랏글·천지인의 `false` 중간 상태는 spec의 **알려진 한계**다.

**Files:**
- Test: `SYKeyboardTests/Domain/HangeulCompletionMatchScenarioTests.swift`

**Interfaces:**
- Consumes: Task 1의 `PredictiveTextCompletionMatchPolicy(typedWord:)`, `isCompletion(_:)`. 기존 `HangeulCompositionTestHarness(processor:)`, `input(_:)`, `text`(`SYKeyboardTests/Utils/HangeulCompositionTestHarness.swift`).

- [x] **Step 1: 테스트를 쓴다**

`SYKeyboardTests/Domain/HangeulCompletionMatchScenarioTests.swift`:

```swift
//
//  HangeulCompletionMatchScenarioTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Testing

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

/// 조합 중 화면 텍스트에 NGram 완성 접두어 규칙을 적용한 결과를 자판별로 고정한다.
/// 마지막 상태는 입력이 목표와 같아 완성이 아니다(0번 칸이 보여준다)
@Suite("자판별 조합 중 NGram 완성 접두어 판정 시나리오")
struct HangeulCompletionMatchScenarioTests {

    // MARK: - Properties

    private let automata: HangeulAutomataProtocol = HangeulAutomata()

    // MARK: - Tests

    @Test("두벌식은 받침·겹받침이 다음 글자 초성이 되는 동안에도 목표를 완성 후보로 봄")
    func test두벌식은_받침과겹받침이_다음글자초성이되는동안에도_목표를완성후보로봄() {
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㅋ", "ㅣ", "ㅂ", "ㅗ", "ㄷ", "ㅡ"], target: "키보드") == [
            Step("ㅋ", true), Step("키", true), Step("킵", true), Step("키보", true), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㄷ", "ㅏ", "ㄹ", "ㄱ", "ㅑ", "ㄹ"], target: "달걀") == [
            Step("ㄷ", true), Step("다", true), Step("달", true), Step("닭", true), Step("달갸", true), Step("달걀", false)
        ])
        #expect(steps(DubeolsikProcessor(automata: automata), keys: ["ㅇ", "ㅏ", "ㄴ", "ㅈ", "ㅜ"], target: "안주") == [
            Step("ㅇ", true), Step("아", true), Step("안", true), Step("앉", true), Step("안주", false)
        ])
    }

    @Test("나랏글은 받침·겹받침은 유지하고 획추가 전 상태에서만 한 타 빠짐")
    func test나랏글은_받침과겹받침은유지하고_획추가전상태에서만_한타빠짐() {
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㄱ", "획", "ㅣ", "ㅁ", "획", "ㅗ", "ㄴ", "획", "ㅡ"], target: "키보드") == [
            Step("ㄱ", false), Step("ㅋ", true), Step("키", true), Step("킴", false), Step("킵", true),
            Step("키보", true), Step("키본", false), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㄴ", "획", "ㅏ", "ㄹ", "ㄱ", "ㅏ", "획", "ㄹ"], target: "달걀") == [
            Step("ㄴ", false), Step("ㄷ", true), Step("다", true), Step("달", true), Step("닭", true),
            Step("달가", false), Step("달갸", true), Step("달걀", false)
        ])
        #expect(steps(NaratgeulProcessor(automata: automata), keys: ["ㅇ", "ㅏ", "ㄴ", "ㅅ", "획", "ㅜ"], target: "안주") == [
            Step("ㅇ", true), Step("아", true), Step("안", true), Step("안ㅅ", false), Step("앉", true), Step("안주", false)
        ])
    }

    @Test("천지인은 받침·겹받침·조합 중 ㆍ는 유지하고 모음 조합과 자음 순환 전 상태에서만 한 타 빠짐")
    func test천지인은_받침과겹받침과조합중ㆍ는유지하고_모음조합과자음순환전상태에서만_한타빠짐() {
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㄱ", "ㄱ", "ㅣ", "ㅂ", "ㆍ", "ㅡ", "ㄷ", "ㅡ"], target: "키보드") == [
            Step("ㄱ", false), Step("ㅋ", true), Step("키", true), Step("킵", true), Step("킵ㆍ", true),
            Step("키보", true), Step("키볻", true), Step("키보드", false)
        ])
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㄷ", "ㅣ", "ㆍ", "ㄴ", "ㄴ", "ㄱ", "ㅣ", "ㆍ", "ㆍ", "ㄴ", "ㄴ"], target: "달걀") == [
            Step("ㄷ", true), Step("디", false), Step("다", true), Step("단", false), Step("달", true), Step("닭", true),
            Step("달기", false), Step("달가", false), Step("달갸", true), Step("달갼", false), Step("달걀", false)
        ])
        #expect(steps(CheonjiinProcessor(automata: automata), keys: ["ㅇ", "ㅣ", "ㆍ", "ㄴ", "ㅈ", "ㅡ", "ㆍ"], target: "안주") == [
            Step("ㅇ", true), Step("이", false), Step("아", true), Step("안", true), Step("앉", true),
            Step("안즈", false), Step("안주", false)
        ])
    }

    // MARK: - Helpers

    private struct Step: Equatable, CustomStringConvertible {
        let text: String
        let isCompletion: Bool

        init(_ text: String, _ isCompletion: Bool) {
            self.text = text
            self.isCompletion = isCompletion
        }

        var description: String { "\(text):\(isCompletion ? "T" : "F")" }
    }

    /// 키를 하나씩 넣으며 화면 텍스트와 목표 단어 완성 판정을 모은다
    private func steps(_ processor: HangeulProcessable, keys: [String], target: String) -> [Step] {
        let harness = HangeulCompositionTestHarness(processor: processor)
        return keys.map { key in
            harness.input(key)
            let isCompletion = PredictiveTextCompletionMatchPolicy(typedWord: harness.text)?.isCompletion(target) == true
            return Step(harness.text, isCompletion)
        }
    }
}
```

- [x] **Step 2: 테스트가 통과하는 것을 확인한다**

production 코드는 Task 1에서 이미 있으므로 바로 통과해야 한다. Global Constraints의 테스트 명령을 `-only-testing:SYKeyboardTests/HangeulCompletionMatchScenarioTests`, 로그 이름 `158-task2`로 실행한다.
Expected: 3개 테스트 통과. 실패하면 로그의 `Step` 배열(예: `[ㄱ:F, ㅋ:T, …]`)을 spec 1절 표와 비교한다. 텍스트가 다르면 처리기 동작이 계획 작성 이후 바뀐 것이므로 기대값을 고치지 말고 멈추고 사용자에게 알린다.

- [x] **Step 3: 커밋**

```bash
git add SYKeyboardTests/Domain/HangeulCompletionMatchScenarioTests.swift docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
test: #158 - 자판별 조합 중 NGram 완성 접두어 판정 시나리오 테스트 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

**결과:** `HangeulCompletionMatchScenarioTests` 3개 테스트 통과(iPhone 13 mini / iOS 18.6). 처리기별 상태 배열이 spec 1절 표와 일치.

---

### Task 3: 엔진의 입력 중 단어 완성 조회

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (`suggestions(for:preferredScript:)` 바로 뒤)
- Test: `SYKeyboardTests/Domain/NGramPredictiveTextEngineCompletionTests.swift`

**Interfaces:**
- Consumes: Task 1의 `PredictiveTextCompletionMatchPolicy`. 엔진 private extension의 기존 `rankedCandidates(from:key:)`, `insertTopUnigram(_:into:)`.
- Produces: `NGramPredictiveTextEngine.completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String]` (internal). Task 4가 프로토콜 요구사항으로 올린다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineCompletionTests.swift`:

```swift
//
//  NGramPredictiveTextEngineCompletionTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 입력 중 단어 완성 조회 검증")
struct NGramPredictiveTextEngineCompletionTests {

    @Test("접두어가 맞는 unigram을 빈도순으로 limit개까지 반환")
    func test접두어가맞는unigram을_빈도순으로_limit개까지반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-unigram").engine
        recordAlone(engine, "키보드", times: 3)
        recordAlone(engine, "키보드로", times: 5)
        recordAlone(engine, "키위", times: 4)
        recordAlone(engine, "키보드를", times: 2)
        recordAlone(engine, "마우스", times: 9)

        #expect(engine.completions(forTypedWord: "키보", previousWord: nil, limit: 3) == ["키보드로", "키보드", "키보드를"])
        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == ["키보드로", "키위", "키보드"])
    }

    @Test("받침이 다음 글자 초성일 수 있는 조합 중 단어도 완성 후보를 찾음")
    func test받침이다음글자초성일수있는_조합중단어도_완성후보를찾음() async {
        let engine = await makeLoadedNGramFixture(name: "completion-jamo").engine
        recordAlone(engine, "키보드", times: 1)
        recordAlone(engine, "달걀", times: 1)

        #expect(engine.completions(forTypedWord: "키볻", previousWord: nil, limit: 3) == ["키보드"])
        #expect(engine.completions(forTypedWord: "닭", previousWord: nil, limit: 3) == ["달걀"])
    }

    @Test("대소문자를 무시하고 저장된 표기 그대로 반환")
    func test대소문자를무시하고_저장된표기그대로반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-case").engine
        recordAlone(engine, "SY키보드", times: 1)

        #expect(engine.completions(forTypedWord: "sy", previousWord: nil, limit: 3) == ["SY키보드"])
        #expect(engine.completions(forTypedWord: "sy키", previousWord: nil, limit: 3) == ["SY키보드"])
    }

    @Test("입력 중인 단어와 같은 단어는 빼고 반환")
    func test입력중인단어와같은단어는_빼고반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-exclude-typed").engine
        recordAlone(engine, "키보드", times: 5)
        recordAlone(engine, "키보드로", times: 1)
        recordAlone(engine, "KEYBOARD", times: 5)
        recordAlone(engine, "keyboards", times: 1)

        #expect(engine.completions(forTypedWord: "키보드", previousWord: nil, limit: 3) == ["키보드로"])
        #expect(engine.completions(forTypedWord: "keyboard", previousWord: nil, limit: 3) == ["keyboards"])
    }

    @Test("바로 앞 단어의 bigram 후보를 unigram 빈도보다 먼저 반환")
    func test바로앞단어의bigram후보를_unigram빈도보다먼저반환() async {
        let engine = await makeLoadedNGramFixture(name: "completion-bigram").engine
        recordPair(engine, "오늘", "날씨", times: 2)
        recordAlone(engine, "날개", times: 9)
        recordAlone(engine, "날짜", times: 5)

        #expect(engine.completions(forTypedWord: "날", previousWord: nil, limit: 3) == ["날개", "날짜", "날씨"])
        #expect(engine.completions(forTypedWord: "날", previousWord: "오늘", limit: 3) == ["날씨", "날개", "날짜"])
        #expect(engine.completions(forTypedWord: "날", previousWord: "오늘", limit: 1) == ["날씨"])
    }

    @Test("디스크 로딩 전에는 빈 배열을 반환하고 로딩 뒤에 찾음")
    func test디스크로딩전에는_빈배열을반환하고_로딩뒤에찾음() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-completion-loading.plist")
        try writeNGramData(unigram: ["키보드": 3], to: url)
        let gate = NGramLoadGate()
        let engine = NGramPredictiveTextEngine(
            language: "test-completion-loading",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyScheduler: gate.schedule
        )

        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == [])

        await gate.finishLoading()

        #expect(engine.completions(forTypedWord: "키", previousWord: nil, limit: 3) == ["키보드"])
    }
}

/// 문맥 없이 unigram만 남도록 문장 버퍼를 비우고 기록한다
private func recordAlone(_ engine: NGramPredictiveTextEngine, _ word: String, times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        engine.addWord(word)
    }
}

/// `first` → `second` bigram을 남긴다
private func recordPair(_ engine: NGramPredictiveTextEngine, _ first: String, _ second: String, times: Int) {
    for _ in 0..<times {
        engine.resetSentenceBuffer()
        engine.addWord(first)
        engine.addWord(second)
    }
}
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Global Constraints의 테스트 명령을 `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineCompletionTests`, 로그 이름 `158-task3-red`로 실행한다.
Expected: 컴파일 실패 `value of type 'NGramPredictiveTextEngine' has no member 'completions'`

- [ ] **Step 3: 조회를 만든다**

`NGramPredictiveTextEngine.swift`에서 `suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String]` 메서드가 끝나는 `}` 바로 뒤, 아래 주석 앞에 넣는다.

```swift
    /// n-gram에서는 단어 단위 학습을 사용하지 않습니다.
```

넣을 코드:

```swift
    /// 입력 중인 단어를 이어 쓴 학습 단어를 반환합니다.
    ///
    /// `previousWord` 뒤에 쓴 bigram 후보 중 맞는 것을 빈도순으로 먼저, 남은 칸은 unigram 빈도순으로 채웁니다.
    /// 비교 규칙은 `PredictiveTextCompletionMatchPolicy`를 따르고, 입력 중인 단어 자체는 뺍니다.
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
                results.append(word)
                if results.count >= limit { return results }
            }
        }

        // ponytail: 키 입력마다 unigram 전체(최대 10000개)를 훑는다. 실기기에서 느리면 소문자 키 캐시나 접두어 색인을 둔다
        var top: [(key: String, value: Int)] = []
        for entry in unigramStore where policy.isCompletion(entry.key) && !seen.contains(entry.key.lowercased()) {
            insertTopUnigram(entry, into: &top)
        }
        return results + top.prefix(limit - results.count).map(\.key)
    }

```

`insertTopUnigram(_:into:)`는 상위 `maxPredictions`(10)개를 유지하므로 `limit`이 10 이하면 그대로 쓸 수 있다. 호출자는 Task 4의 `SuggestionController`뿐이고 3을 넘긴다.

- [ ] **Step 4: 테스트가 통과하는 것을 확인한다**

Step 2와 같은 명령을 로그 이름 `158-task3-green`으로 실행한다.
Expected: 6개 테스트 통과, `** TEST SUCCEEDED **`

- [ ] **Step 5: 기존 엔진 테스트가 그대로인지 확인한다**

Global Constraints의 테스트 명령에 아래 `-only-testing`을 모두 붙여 로그 이름 `158-task3-engine`으로 실행한다.

```
-only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests
-only-testing:SYKeyboardTests/NGramPredictiveTextEngineScriptPreferenceTests
-only-testing:SYKeyboardTests/NGramPredictiveTextEngineRemovalTests
-only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests
-only-testing:SYKeyboardTests/NGramPredictiveTextEnginePruneTests
```

Expected: 모두 통과

- [ ] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift SYKeyboardTests/Domain/NGramPredictiveTextEngineCompletionTests.swift docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
feat: #158 - NGram 엔진에 입력 중 단어 완성 조회 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: 입력 중 후보에 NGram 완성 병합

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift` (`StubNGramPredictiveTextProvider`)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` (`RemovableNGramStub`)
- Test: `SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift`

**Interfaces:**
- Consumes: Task 3의 `completions(forTypedWord:previousWord:limit:)`.
- Produces: `NGramPredictiveTextProviding.completions(forTypedWord:previousWord:limit:)` 프로토콜 요구사항. `StubNGramPredictiveTextProvider.completionResults: [String]`, `completionQueries: [StubNGramPredictiveTextProvider.CompletionQuery]`.

- [ ] **Step 1: stub에 완성 조회를 넣는다**

`SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift`의 `StubNGramPredictiveTextProvider`에서 아래 줄 바로 뒤에 넣는다.

old:
```swift
    /// 선호 문자 종류별 결과. 없으면 `loadedSuggestions`를 돌려준다
    var resultsByPreferredScript: [PredictiveTextScript: [String]] = [:]
```
new:
```swift
    /// 선호 문자 종류별 결과. 없으면 `loadedSuggestions`를 돌려준다
    var resultsByPreferredScript: [PredictiveTextScript: [String]] = [:]
    /// 입력 중 단어 완성 조회에 돌려줄 결과. 앞에서부터 `limit`개만 돌려준다
    var completionResults: [String] = []
    /// 입력 중 단어 완성 조회에 받은 인자
    private(set) var completionQueries: [CompletionQuery] = []

    struct CompletionQuery: Equatable {
        let typedWord: String
        let previousWord: String?
        let limit: Int
    }
```

같은 클래스의 `func addWord(_ word: String) {` 바로 앞에 넣는다.

```swift
    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String] {
        completionQueries.append(CompletionQuery(typedWord: typedWord, previousWord: previousWord, limit: limit))
        return Array(completionResults.prefix(limit))
    }

```

`SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift`의 `RemovableNGramStub`에서:

old:
```swift
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] { results }
```
new:
```swift
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String] { results }
    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String] { [] }
```

- [ ] **Step 2: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift`:

```swift
//
//  SuggestionControllerNGramCompletionTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/25/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("입력 중 NGram 단어 완성 후보 병합 검증")
struct SuggestionControllerNGramCompletionTests {

    @Test("입력 중 후보는 lexicon, NGram 완성 최대 3개, TextChecker 순으로 중복 없이 병합")
    func test입력중후보는_lexicon_NGram완성최대3개_TextChecker순으로_중복없이병합() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "키보", documentText: "키보드 단축어")],
            checkerResults: ["키보드", "키보이"]
        )
        harness.nGram.completionResults = ["키보드", "키보드로", "키보드를", "키보드에서"]

        harness.controller.updateSuggestions(for: "키보")

        #expect(harness.delegate.updates.last == .init(
            currentWord: "키보",
            suggestions: ["키보드 단축어", "키보드", "키보드로", "키보드를"]
        ))

        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last == .init(
            currentWord: "키보",
            suggestions: ["키보드 단축어", "키보드", "키보드로", "키보드를", "키보이"]
        ))
        #expect(harness.nGram.completionQueries == [.init(typedWord: "키보", previousWord: nil, limit: 3)])
    }

    @Test("바로 앞 단어를 bigram 문맥으로 넘김")
    func test바로앞단어를_bigram문맥으로넘김() async {
        let harness = makeHarness()

        harness.controller.updateSuggestions(for: "날")
        harness.controller.updateSuggestions(for: "오늘 날")
        await harness.finishTextChecker()

        #expect(harness.nGram.completionQueries == [
            .init(typedWord: "날", previousWord: nil, limit: 3),
            .init(typedWord: "날", previousWord: "오늘", limit: 3)
        ])
    }

    @Test("한영 전환을 사이에 둔 섞인 단어는 단어 전체를 완성 후보로 대치")
    func test한영전환을사이에둔_섞인단어는_단어전체를_완성후보로대치() async {
        let harness = makeHarness()
        harness.nGram.completionResults = ["SY키보드"]

        harness.controller.updateSuggestions(for: "오늘 SY키")
        let result = harness.controller.selectSuggestion(at: 0, baseText: "오늘 SY키")
        await harness.finishTextChecker()

        #expect(harness.nGram.completionQueries == [.init(typedWord: "SY키", previousWord: "오늘", limit: 3)])
        #expect(result?.deleteCount == 3)
        #expect(result?.insertText == "SY키보드")
    }

    @Test("입력 중 NGram 완성 후보는 길게 눌러 삭제할 수 있음")
    func test입력중NGram완성후보는_길게눌러삭제할수있음() async {
        let harness = makeHarness()
        harness.nGram.completionResults = ["키보드"]

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()

        // 0번 버튼은 현재 단어라 완성 후보는 1번 버튼이다
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "키보드")
    }

    @Test("NGram 로딩이 끝나면 입력 중 후보에 완성 후보를 채움")
    func testNGram로딩이끝나면_입력중후보에_완성후보를채움() async {
        let harness = makeHarness()

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()
        #expect(harness.delegate.updates.last == .init(currentWord: "키보", suggestions: []))

        harness.nGram.completionResults = ["키보드"]
        harness.nGram.completeLoad(suggestions: [])
        await waitForMainQueue()
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last == .init(currentWord: "키보", suggestions: ["키보드"]))
    }

    @Test("lexicon과 NGram 완성이 9칸을 채우면 TextChecker를 조회하지 않음")
    func testLexicon과NGram완성이_9칸을채우면_TextChecker를조회하지않음() async {
        let harness = makeHarness(
            lexiconEntries: (1...6).map { TextReplacementEntry(userInput: "키보", documentText: "단축어\($0)") },
            checkerResults: ["키보이"]
        )
        harness.nGram.completionResults = ["키보드", "키보드로", "키보드를"]

        harness.controller.updateSuggestions(for: "키보")
        await harness.finishTextChecker()

        #expect(harness.checker.calledBaseTexts == [])
        #expect(harness.delegate.updates.last?.suggestions.count == 9)
    }

    @Test("한/A 전환은 입력 중 NGram 완성 후보를 다시 조회하지 않음")
    func test한A전환은_입력중NGram완성후보를_다시조회하지않음() async {
        let harness = makeHarness(nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage)
        harness.nGram.completionResults = ["SY키보드"]
        harness.controller.updateSuggestions(for: "SY키")
        await harness.finishTextChecker()
        let updateCount = harness.delegate.updates.count

        harness.controller.updateLanguage(to: "en-US")
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.count == updateCount)
        #expect(harness.nGram.completionQueries.count == 1)
        #expect(harness.controller.currentMode == .typing)
    }

    // MARK: - Harness

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let nGram: StubNGramPredictiveTextProvider
        let checker: RecordingTextCheckerProvider
        let queue: DispatchQueue

        /// 대기 중인 TextChecker 조회와 그 결과 반영까지 끝낸다
        func finishTextChecker() async {
            queue.sync {}
            await waitForMainQueue()
        }
    }

    private func makeHarness(
        lexiconEntries: [TextReplacementEntry] = [],
        checkerResults: [String] = [],
        nGramLanguage: String? = nil
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let checker = RecordingTextCheckerProvider(results: checkerResults)
        let nGram = StubNGramPredictiveTextProvider()
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in nGram }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.ngramcompletion")
        let controller = SuggestionController(
            language: "ko-KR",
            nGramLanguage: nGramLanguage,
            engineFactory: factory,
            textCheckerQueue: queue
        )
        let delegate = RecordingSuggestionControllerDelegate()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, delegate: delegate, nGram: nGram, checker: checker, queue: queue)
    }
}

/// 주입한 후보를 돌려주고 조회한 텍스트를 기록하는 TextChecker stub
private final class RecordingTextCheckerProvider: PredictiveTextProvider, @unchecked Sendable {
    private let results: [String]
    private(set) var calledBaseTexts: [String] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        calledBaseTexts.append(baseText)
        return Array(results.prefix(limit))
    }

    func learn(word: String) {}
}
```

- [ ] **Step 3: 테스트가 실패하는 것을 확인한다**

Global Constraints의 테스트 명령을 `-only-testing:SYKeyboardTests/SuggestionControllerNGramCompletionTests`, 로그 이름 `158-task4-red`로 실행한다.
Expected: 컴파일은 되고(`NGramPredictiveTextEngine`과 두 stub에 메서드가 이미 있으므로) 다음이 실패한다: `test입력중후보는_…병합`(NGram 완성 없음), `test바로앞단어를_bigram문맥으로넘김`·`test한영전환을…대치`(조회 기록 없음), `test입력중NGram완성후보는_길게눌러삭제할수있음`, `testNGram로딩이끝나면_…채움`, `testLexicon과NGram완성이_9칸을채우면_…`. `test한A전환은_…다시조회하지않음`은 조회 횟수 기대(1)가 0이라 실패한다.

- [ ] **Step 4: 프로토콜에 완성 조회를 넣는다**

`SuggestionController.swift`의 `NGramPredictiveTextProviding`에서:

old:
```swift
    /// 문맥으로 다음 단어를 예측합니다. `preferredScript`가 있으면 unigram 후보만 그 문자 종류를 앞에 둡니다.
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String]
}
```
new:
```swift
    /// 문맥으로 다음 단어를 예측합니다. `preferredScript`가 있으면 unigram 후보만 그 문자 종류를 앞에 둡니다.
    func suggestions(for baseText: String, preferredScript: PredictiveTextScript?) -> [String]
    /// 입력 중인 단어를 이어 쓴 학습 단어를 반환합니다. `previousWord` 뒤에 쓴 bigram 후보가 먼저입니다.
    func completions(forTypedWord typedWord: String, previousWord: String?, limit: Int) -> [String]
}
```

- [ ] **Step 5: 완성 후보 칸 수와 주석을 고친다**

클래스 문서 주석:

old:
```swift
/// 1. **입력 중**: SuggestionBar에 `UILexicon` + `UITextChecker` 후보 표시
```
new:
```swift
/// 1. **입력 중**: SuggestionBar에 `UILexicon` + n-gram 단어 완성 + `UITextChecker` 후보 표시
```

출처 주석:

old:
```swift
            /// n-gram 기반 (다음 단어 예측)
            case nGram
```
new:
```swift
            /// n-gram 기반 (다음 단어 예측, 입력 중 단어 완성)
            case nGram
```

`maxSuggestions` 선언 바로 뒤:

old:
```swift
    private let maxSuggestions = 10
```
new:
```swift
    private let maxSuggestions = 10
    /// 입력 중 모드에서 n-gram 단어 완성에 주는 최대 칸 수
    ///
    /// lexicon 뒤, TextChecker 앞에 둔다. 자주 쓰는 접두어에서도 TextChecker 몫(오타 교정 포함)이 남도록 제한한다
    private let maxNGramCompletions = 3
```

- [ ] **Step 6: 입력 중 모드에서 완성을 조회하고 병합한다**

`performUpdateSuggestions`의 문서 주석:

old:
```swift
    /// - 단어 타이핑 중 → 입력 중 모드 (lexicon + textChecker)
```
new:
```swift
    /// - 단어 타이핑 중 → 입력 중 모드 (lexicon + n-gram 단어 완성 + textChecker)
```

이어받기 주석:

old:
```swift
        // lexicon·n-gram·수식 후보를 이어받지 않는 이유: n-gram 후보는 다음 단어 예측이라
        // 입력 중 모드에서 탭되면 현재 단어를 잘못 교체하고, lexicon 후보는 이번 입력의
        // 조회 결과로 대치되어야 `textReplacementPreviewSuggestionIndex`가 어긋나지 않는다
```
new:
```swift
        // lexicon·n-gram·수식 후보를 이어받지 않는 이유: n-gram 모드 후보는 다음 단어 예측이라
        // 입력 중 모드에서 탭되면 현재 단어를 잘못 교체하고, lexicon 후보는 이번 입력의
        // 조회 결과로 대치되어야 `textReplacementPreviewSuggestionIndex`가 어긋나지 않는다.
        // n-gram 단어 완성은 lexicon처럼 이번 입력으로 동기 조회하므로 이어받을 필요가 없다
```

lexicon 조회와 1단계 병합:

old:
```swift
        let lexiconState = signposter.beginInterval("LexiconSuggestions")
        let lexiconResults = lexiconEngine?.suggestions(for: baseText) ?? []
        signposter.endInterval("LexiconSuggestions", lexiconState)

        // 새 lexicon 결과를 앞에 두고 직전 TextChecker 후보로 남은 슬롯을 채워 먼저 갱신한다.
        // TextChecker 결과가 도착하면 그 결과로 다시 병합한다
        currentSuggestions = mergeSuggestions(
            lexiconResults: lexiconResults,
            checkerResults: previousCheckerTexts,
            currentWord: currentWord
        )
```
new:
```swift
        let lexiconState = signposter.beginInterval("LexiconSuggestions")
        let lexiconResults = lexiconEngine?.suggestions(for: baseText) ?? []
        signposter.endInterval("LexiconSuggestions", lexiconState)
        // n-gram 저장소는 main에서만 바뀌므로 TextChecker와 달리 큐로 넘기지 않고 동기로 조회한다
        let nGramCompletions = nGramCompletionSuggestions(for: baseText, currentWord: currentWord)

        // 새 lexicon·n-gram 완성 결과를 앞에 두고 직전 TextChecker 후보로 남은 슬롯을 채워 먼저 갱신한다.
        // TextChecker 결과가 도착하면 그 결과로 다시 병합한다
        currentSuggestions = mergeSuggestions(
            lexiconResults: lexiconResults,
            nGramCompletions: nGramCompletions,
            checkerResults: previousCheckerTexts,
            currentWord: currentWord
        )
```

TextChecker 생략 조건:

old:
```swift
        // lexicon이 슬롯을 다 채웠으면 TextChecker 조회가 결과에 기여할 수 없다.
        // 이어받은 후보는 이번 조회 결과로 대치될 값이라 세지 않는다
        guard currentSuggestions.filter({ $0.source == .lexicon }).count < maxSuggestionSlots,
```
new:
```swift
        // lexicon·n-gram 완성이 슬롯을 다 채웠으면 TextChecker 조회가 결과에 기여할 수 없다.
        // 이어받은 후보는 이번 조회 결과로 대치될 값이라 세지 않는다
        guard currentSuggestions.filter({ $0.source != .textChecker }).count < maxSuggestionSlots,
```

2단계 재병합:

old:
```swift
                self.currentSuggestions = self.mergeSuggestions(
                    lexiconResults: lexiconResults,
                    checkerResults: checkerResults,
                    currentWord: currentWord
                )
```
new:
```swift
                self.currentSuggestions = self.mergeSuggestions(
                    lexiconResults: lexiconResults,
                    nGramCompletions: nGramCompletions,
                    checkerResults: checkerResults,
                    currentWord: currentWord
                )
```

- [ ] **Step 7: 완성 조회 helper를 넣고 병합 함수를 바꾼다**

`nGramSuggestions(for:)` 메서드가 끝나는 `}` 바로 뒤, `/// lexicon 결과와 TextChecker 결과를 병합합니다.` 앞에 넣는다.

```swift
    /// 입력 중인 단어를 이어 쓴 n-gram 학습 단어를 조회합니다.
    ///
    /// 바로 앞 단어가 있으면 bigram 문맥으로 넘겨 그 뒤에 자주 쓴 단어를 먼저 받는다.
    ///
    /// - Parameters:
    ///   - baseText: 자동완성을 제공할 텍스트
    ///   - currentWord: `baseText`의 마지막 단어
    /// - Returns: 완성 후보 (최대 `maxNGramCompletions`개)
    func nGramCompletionSuggestions(for baseText: String, currentWord: String) -> [String] {
        guard let nGramEngine, !currentWord.isEmpty else { return [] }
        let words = baseText.split(whereSeparator: { $0.isWhitespace })
        let previousWord = words.count >= 2 ? String(words[words.count - 2]) : nil
        return nGramEngine.completions(
            forTypedWord: currentWord,
            previousWord: previousWord,
            limit: maxNGramCompletions
        )
    }

```

`mergeSuggestions` 전체(문서 주석 포함)를 바꾼다.

old:
```swift
    /// lexicon 결과와 TextChecker 결과를 병합합니다.
    ///
    /// 현재 입력 중인 단어와 동일한 후보는 제외하고,
    /// lexicon 결과를 먼저 배치하여 사용자 개인화 데이터를 우선시합니다.
    ///
    /// - Parameters:
    ///   - lexiconResults: `UILexicon` 후보
    ///   - checkerResults: `UITextChecker` 후보 (아직 도착하지 않았으면 빈 배열)
    ///   - currentWord: 현재 입력 중인 단어
    /// - Returns: 중복 제거된 후보 배열 (최대 `maxSuggestions - 1`개. 0번 칸은 `"현재단어"` 몫이다)
    func mergeSuggestions(
        lexiconResults: [String],
        checkerResults: [String],
        currentWord: String
    ) -> [SuggestionItem] {
        var seen = Set<String>()
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []

        let maxSuggestionSlots = maxSuggestions - 1

        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        for suggestion in checkerResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .textChecker))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        return merged
    }
```
new:
```swift
    /// lexicon, n-gram 단어 완성, TextChecker 결과를 병합합니다.
    ///
    /// 현재 입력 중인 단어와 동일한 후보는 제외하고,
    /// lexicon → n-gram 단어 완성 → TextChecker 순으로 배치하여 사용자 개인화 데이터를 우선시합니다.
    ///
    /// - Parameters:
    ///   - lexiconResults: `UILexicon` 후보
    ///   - nGramCompletions: n-gram 단어 완성 후보
    ///   - checkerResults: `UITextChecker` 후보 (아직 도착하지 않았으면 빈 배열)
    ///   - currentWord: 현재 입력 중인 단어
    /// - Returns: 중복 제거된 후보 배열 (최대 `maxSuggestions - 1`개. 0번 칸은 `"현재단어"` 몫이다)
    func mergeSuggestions(
        lexiconResults: [String],
        nGramCompletions: [String],
        checkerResults: [String],
        currentWord: String
    ) -> [SuggestionItem] {
        var seen = Set<String>()
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []

        let maxSuggestionSlots = maxSuggestions - 1
        let sources: [(results: [String], source: SuggestionItem.Source)] = [
            (lexiconResults, .lexicon),
            (nGramCompletions, .nGram),
            (checkerResults, .textChecker)
        ]

        for (results, source) in sources {
            for suggestion in results {
                let lowered = suggestion.lowercased()
                guard !seen.contains(lowered) else { continue }
                seen.insert(lowered)
                merged.append(SuggestionItem(text: suggestion, source: source))
                if merged.count >= maxSuggestionSlots { return merged }
            }
        }

        return merged
    }
```

- [ ] **Step 8: 새 테스트가 통과하는 것을 확인한다**

Step 3과 같은 명령을 로그 이름 `158-task4-green`으로 실행한다.
Expected: 7개 테스트 통과

- [ ] **Step 9: 기존 컨트롤러 테스트가 그대로인지 확인한다**

Global Constraints의 테스트 명령에 아래 `-only-testing`을 모두 붙여 로그 이름 `158-task4-controller`로 실행한다.

```
-only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests
-only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests
-only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests
-only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests
-only-testing:SYKeyboardTests/SuggestionControllerUnifiedNGramTests
-only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
-only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
-only-testing:SYKeyboardTests/SuggestionControllerSuspensionTests
```

Expected: 모두 통과. 기존 stub의 `completionResults` 기본값이 빈 배열이라 입력 중 후보 기대값은 바뀌지 않는다. 실패하면 기대값을 고치기 전에 이번 변경의 회귀인지 확인하고 사용자에게 알린다.

- [ ] **Step 10: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/SuggestionController.swift SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
feat: #158 - 입력 중 후보에 NGram 완성 후보 병합

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 아키텍처 문서 갱신

**Files:**
- Modify: `docs/architecture/자동완성 로직.md` (§2-3 표 「조회」 행, §3-3, §6-1 표 `removableSuggestionText` 행)
- Modify: `docs/architecture/한영 통합 키보드.md` (「알려진 한계」 문단)

- [ ] **Step 1: `자동완성 로직.md` §2-3 표에 완성 조회를 넣는다**

old:
```
  unigram 순위는 `preferredScript`별로 `rankedUnigramCache`에 캐시하고 unigram이 바뀔 때 무효화 |
```
new:
```
  unigram 순위는 `preferredScript`별로 `rankedUnigramCache`에 캐시하고 unigram이 바뀔 때 무효화.
  입력 중 단어 완성은 `completions(forTypedWord:previousWord:limit:)`: 바로 앞 단어의 bigram 후보 중
  접두어가 맞는 것을 빈도순으로 먼저, 남은 칸은 unigram 빈도순(전체를 훑음, signpost `NGramCompletions`).
  접두어 판정은 `PredictiveTextCompletionMatchPolicy`(대소문자 무시, 마지막 글자 자모 단위, 겹받침 분해,
  끝의 천지인 ㆍ/ᆢ 제외, 입력 단어 자체 제외). 문자 종류 우선 정렬은 하지 않는다 |
```

- [ ] **Step 2: §3-3 두 단계 갱신과 병합 규칙을 고친다**

old:
```
1. lexicon 결과(동기) + 직전 typing 모드의 textChecker 후보(previousCheckerTexts)를 병합해 즉시 delegate 전달
   - 이어받는 것은 textChecker 후보뿐. n-gram·lexicon·수식 후보는 이어받지 않는다
     (n-gram 후보는 입력 중 모드에서 탭되면 현재 단어를 잘못 교체하고, lexicon 후보는 이번 조회 결과로 대치돼야
     textReplacementPreviewSuggestionIndex가 어긋나지 않는다)
2. lexicon이 후보 슬롯(maxSuggestions(10) - 1 = 9)을 다 채우지 않았을 때만 textCheckerQueue(직렬, .userInitiated)에서
   textCheckerEngine.suggestions(for:limit: 9) 조회
```
new:
```
1. lexicon 결과(동기) + n-gram 단어 완성(동기, 최대 3개) + 직전 typing 모드의 textChecker 후보(previousCheckerTexts)를
   병합해 즉시 delegate 전달
   - n-gram 단어 완성은 nGramCompletionSuggestions(for:currentWord:)가 마지막 단어와 바로 앞 단어(bigram 문맥)로
     엔진의 completions(forTypedWord:previousWord:limit: 3)을 부른다. n-gram 저장소는 main에서만 바뀌어 큐로 넘기지 않는다
   - 이어받는 것은 textChecker 후보뿐. n-gram·lexicon·수식 후보는 이어받지 않는다
     (n-gram 모드 후보는 입력 중 모드에서 탭되면 현재 단어를 잘못 교체하고, lexicon 후보는 이번 조회 결과로 대치돼야
     textReplacementPreviewSuggestionIndex가 어긋나지 않는다. n-gram 단어 완성은 매 입력 동기로 다시 조회한다)
2. lexicon과 n-gram 완성이 후보 슬롯(maxSuggestions(10) - 1 = 9)을 다 채우지 않았을 때만 textCheckerQueue(직렬, .userInitiated)에서
   textCheckerEngine.suggestions(for:limit: 9) 조회
```

old:
```
3. main으로 돌아와 세대가 여전히 같고 currentMode == .typing일 때만 다시 병합해 delegate 전달
```
new:
```
3. main으로 돌아와 세대가 여전히 같고 currentMode == .typing일 때만 1단계의 lexicon·n-gram 완성 결과와 다시 병합해 delegate 전달
```

old:
```
1. seen에 currentWord(lowercased)를 먼저 등록 → button1과의 중복 방지
2. lexicon 결과를 먼저 추가 (개인화 데이터 우선)
3. 남은 슬롯을 textChecker 결과로 채움
4. 최대 9개 반환 (1번 칸부터, maxSuggestions(10) - 1)
```
new:
```
1. seen에 currentWord(lowercased)를 먼저 등록 → button1과의 중복 방지
2. lexicon 결과를 먼저 추가 (개인화 데이터 우선)
3. n-gram 단어 완성 결과를 추가 (출처 .nGram, 엔진이 최대 3개만 돌려줌)
4. 남은 슬롯을 textChecker 결과로 채움
5. 최대 9개 반환 (1번 칸부터, maxSuggestions(10) - 1)
```

그 바로 뒤(§3-4 제목 앞)에 문단을 넣는다.

```
n-gram 단어 완성 후보를 고르면 다른 입력 중 후보와 같이 `selectSuggestion`이 현재 단어(공백 기준 마지막 단어)
전체를 대치하고 `recordWord(result.insertText)`로 기록한다. 한영 통합 키보드에서 'SY' → 전환 → '키'의 현재 단어는
`"SY키"`이므로 `"SY키보드"`를 고르면 `"SY키"` 전체가 대치된다. 조합 중 판정의 자판별 결과와 알려진 한계(나랏글
획추가 전, 천지인 모음 조합·자음 순환 전 상태에서 한 타 빠짐)는
[설계 문서](../superpowers/specs/2026-09-25-ngram-typing-completion-design.md) 1절에 있다.
```

- [ ] **Step 3: §6-1 표의 삭제 대상 설명을 고친다**

old:
```
| `removableSuggestionText(atBarIndex:)` | n-gram 후보, 그리고 `canUnlearn`이 true인 textChecker 후보만 단어를 반환.
```
new:
```
| `removableSuggestionText(atBarIndex:)` | n-gram 후보(입력 중 모드의 n-gram 단어 완성 포함), 그리고 `canUnlearn`이 true인 textChecker 후보만 단어를 반환.
```

- [ ] **Step 4: `한영 통합 키보드.md`의 알려진 한계를 고친다**

old:
```
**알려진 한계**: `SY키보`처럼 한글과 영문이 섞인 토큰은 언어 경계로 나누지 않고 `UITextChecker`에
통째로 넘어가므로 단어 완성이 약하다. 타이핑 중 NGram 완성(#158)이 이를 보완할 예정이다.
```
new:
```
**섞인 단어의 완성**: `SY키보`처럼 한글과 영문이 섞인 토큰은 언어 경계로 나누지 않고 `UITextChecker`에
통째로 넘어가므로 사전 완성은 거의 없다. 대신 입력 중 NGram 단어 완성(#158)이 통합 NGram에 학습된
`"SY키보드"`를 대소문자 무시 접두어로 찾아 보여주고, 고르면 현재 단어 `"SY키"` 전체를 대치한다
([자동완성 로직 §3-3](자동완성%20로직.md)).
```

- [ ] **Step 5: 문서 변경 범위를 확인한다**

Run: `git diff --stat`
Expected: `docs/architecture/자동완성 로직.md`, `docs/architecture/한영 통합 키보드.md`, 이 계획 문서만 바뀌었다.

- [ ] **Step 6: 커밋**

```bash
git add "docs/architecture/자동완성 로직.md" "docs/architecture/한영 통합 키보드.md" docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
docs: #158 - 아키텍처 문서에 입력 중 NGram 완성 반영

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: 전체 테스트·빌드와 시뮬레이터 성능 측정

**Files:**
- Modify: 이 계획 문서(결과 기록만)
- 임시: `"$SCRATCH/ZZNGramCompletionPerfTests.swift"` → 측정하는 동안만 `SYKeyboardTests/Domain/`에 복사하고 지운다. 커밋하지 않는다.

- [ ] **Step 1: 전체 테스트를 실행한다**

Global Constraints의 테스트 명령에서 `-only-testing`을 빼고 로그 이름 `158-task6-all`로 실행한다.
Expected: `** TEST SUCCEEDED **`. 실행한 테스트 수와 소요 시간을 이 문서에 적는다(`grep -E "Test run with|tests? passed|failed" "$SCRATCH/158-task6-all.log" | tail -5`).

- [ ] **Step 2: 4개 scheme을 빌드한다**

`-only-testing`·coverage 옵션 없이 각각 실행한다.

```sh
for scheme in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$SCRATCH/158-task6-build-$scheme.log" 2>&1
  echo "$scheme: $(tail -1 "$SCRATCH/158-task6-build-$scheme.log")"
done
git status --short
```

Expected: 네 줄 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 보이면 Global Constraints대로 처리한다.

- [ ] **Step 3: 시뮬레이터에서 production 엔진 조회 비용을 잰다**

`"$SCRATCH/ZZNGramCompletionPerfTests.swift"`를 만든다.

```swift
import Foundation
import Testing

@testable import SYKeyboardCore

/// 버리는 측정. 커밋하지 않는다
@Suite("ZZ 임시 측정: NGram 단어 완성 조회")
struct ZZNGramCompletionPerfTests {
    @Test func measure() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-completion-perf.plist")
        var unigram: [String: Int] = [:]
        while unigram.count < 10000 {
            var word = ""
            if Int.random(in: 0..<5) == 0 {
                for _ in 0..<Int.random(in: 2...8) {
                    word.append(Character(Unicode.Scalar(UInt8.random(in: 97...122))))
                }
            } else {
                for _ in 0..<Int.random(in: 1...4) {
                    word.append(Character(Unicode.Scalar(0xAC00 + UInt32.random(in: 0..<11172))!))
                }
            }
            unigram[word] = Int.random(in: 1...50)
        }
        try writeNGramData(unigram: unigram, to: url)
        let gate = NGramLoadGate()
        let engine = NGramPredictiveTextEngine(
            language: "test-completion-perf",
            fileURL: url,
            legacyStorage: .standard,
            loadApplyScheduler: gate.schedule,
            maxKeys: 10000
        )
        await gate.finishLoading()

        var durations: [Double] = []
        for typedWord in ["다", "닭", "가나", "키볻", "sy", "sy키"] {
            for _ in 0..<50 {
                let start = DispatchTime.now().uptimeNanoseconds
                _ = engine.completions(forTypedWord: typedWord, previousWord: nil, limit: 3)
                durations.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
            }
        }
        durations.sort()
        print("NGRAM_COMPLETION_PERF median=\(durations[durations.count / 2])ms p95=\(durations[durations.count * 95 / 100])ms max=\(durations[durations.count - 1])ms")
    }
}
```

복사해 최적화 빌드로 실행하고, **같은 명령 끝에서** 바로 지운다.

```sh
cp "$SCRATCH/ZZNGramCompletionPerfTests.swift" SYKeyboardTests/Domain/ZZNGramCompletionPerfTests.swift
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  SWIFT_OPTIMIZATION_LEVEL=-O \
  -only-testing:SYKeyboardTests/ZZNGramCompletionPerfTests \
  > "$SCRATCH/158-task6-perf.log" 2>&1
rm SYKeyboardTests/Domain/ZZNGramCompletionPerfTests.swift
grep NGRAM_COMPLETION_PERF "$SCRATCH/158-task6-perf.log"; git status --short
```

Expected: `NGRAM_COMPLETION_PERF median=… p95=… max=…` 한 줄, `git status`에 `ZZNGramCompletionPerfTests.swift`가 없다. 값을 이 문서와 spec 5절에 적는다. **p95가 2ms를 넘으면 여기서 멈추고 사용자에게 알린다**(spec 5절, 고치지 않음).

- [ ] **Step 4: spec에 측정 결과를 적는다**

`docs/superpowers/specs/2026-09-25-ngram-typing-completion-design.md` 5절 끝에 한 문단을 덧붙인다. 형식:

```
- 구현 뒤 시뮬레이터 측정(YYYY-MM-DD, iPhone 13 mini / iOS 18.6, `SWIFT_OPTIMIZATION_LEVEL=-O`, 무작위 unigram
  10000개, 입력 "다"·"닭"·"가나"·"키볻"·"sy"·"sy키" 각 50회): 중앙값 Nms, p95 Nms, 최대 Nms.
```

`YYYY-MM-DD`와 `N`은 Step 3의 실제 값으로 채운다.

- [ ] **Step 5: 커밋**

```bash
git add docs/superpowers/specs/2026-09-25-ngram-typing-completion-design.md docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
docs: #158 - 전체 테스트·빌드와 NGram 완성 조회 측정 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: 실제 입력 앱 확인

자동 테스트가 대신하지 못하는 항목이다(CLAUDE.md 테스트 지침). 사용자가 실기기에서 확인하고, 결과를 받아 기록한다. 확인하지 못한 항목은 미확인으로 남기고 완료로 표시하지 않는다.

**Files:**
- Modify: 이 계획 문서(결과 기록만)

- [ ] **Step 1: 사용자에게 확인 목록을 전달한다**

아래 목록을 그대로 보내고 결과를 받는다. 앱에서 자동완성을 켜고, 먼저 각 단어를 스페이스로 두세 번 입력해 학습시킨다.

1. 단독 한글 키보드(두벌식): '키보드' 학습 뒤 'ㅋ' → '키' → '킵' → '키보' → '키볻'에서 '키보드'가 1번 칸 근처에 계속 보인다.
2. 단독 한글 키보드(나랏글·천지인 각각): 같은 입력에서 '킴'(나랏글), '디'(천지인)처럼 알려진 중간 상태에서만 한 타 빠지고 다시 나타난다.
3. 겹받침: '달걀' 학습 뒤 '닭'까지 입력했을 때 '달걀'이 보인다.
4. 단독 영어 키보드: 'Keyboard' 학습 뒤 'key' 입력 중 'Keyboard'가 보이고, 고르면 'key'가 'Keyboard'로 바뀐다.
5. 한영 통합 키보드: 'SY키보드' 학습 뒤 'SY' → 한/A → '키' 입력 중 'SY키보드'가 보이고, 고르면 'SY키' 전체가 'SY키보드'로 바뀐다(앞에 공백이 생기지 않는다). '오늘 SY키'에서도 같다.
6. 한영 통합 키보드: 'SY키' 입력 중 한/A를 눌러도 후보가 바뀌지 않는다.
7. bigram: '오늘 날씨'를 여러 번 입력한 뒤 '오늘 날'에서 '날씨'가 다른 '날…' 단어보다 앞에 온다.
8. 입력 중 완성 후보를 길게 눌러 삭제하면 사라지고 다시 입력하기 전까지 뜨지 않는다.
9. 빠르게 타이핑할 때 입력 지연이 체감되지 않는다. 가능하면 Instruments `os_signpost`에서 subsystem = 키보드 extension bundle id, category = `NGramPredictiveTextEngine`, 구간 `NGramCompletions`의 최대값을 알려준다.

- [ ] **Step 2: 결과를 기록한다**

이 문서의 Task 7 아래에 항목 번호별로 확인 기기(모델·iOS 버전), 결과(통과/실패/미확인과 이유)를 적는다. 실패 항목이 있으면 고치지 말고 사용자와 범위를 정한다.

- [ ] **Step 3: 커밋**

```bash
git add docs/superpowers/plans/2026-09-25-issue-158-ngram-typing-completion.md
git commit -m "$(cat <<'EOF'
docs: #158 - 실제 입력 앱 확인 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```
