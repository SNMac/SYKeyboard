# 커서 앞 문맥 기준 자동완성 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 커서를 옮긴 뒤에도 커서 앞 단어 기준 후보를 보여 주고, 후보를 누르면 커서 앞 조각만 바꾸며, 앞 글자에 붙어 시작한 조각은 학습하지 않는다.

**Architecture:** 버퍼가 빌 때는 그 순간의 커서 앞 문맥, 버퍼가 있을 때는 버퍼가 시작될 때 떠 둔 `앞 문맥 + inputBuffer`를 일반 후보의 기준 텍스트로 쓴다. 계산 규칙은 `KeyboardSuggestionSelectionPolicy`의 순수 함수에 둔다. 텍스트 대치는 계속 `inputBuffer`만 쓰도록 `SuggestionService`에 대치용 텍스트를 따로 넘긴다. 학습은 앞 조각을 뺀 버퍼(`learnableInputBuffer`)로 한다.

**Tech Stack:** Swift 5, UIKit keyboard extension, Swift Testing, Xcode 26+

**Spec:** `docs/superpowers/specs/2026-09-28-cursor-context-suggestions-design.md`

## Global Constraints

- 브랜치: `feat/#164-ngram-sent-last-word`(#164에 포함). push·PR은 사용자가 요청할 때만 한다.
- 커밋 메시지: `type: #164 - subject`(한국어, 마침표 없음), 끝에 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
- 각 step은 실제 작업과 검증이 끝난 직후에만 체크하고, 결과를 이 문서에 적은 뒤 그 step의 변경과 함께 커밋한다.
- 검증 기준 시뮬레이터: iPhone 13 mini / iOS 18.6, UDID `82146144-24DE-4F91-B25D-23D147A91142`
- 텍스트 대치(스페이스 대치, 미리보기 강조, 복구)는 `inputBuffer`만 쓴다. 커서 문맥을 넘기지 않는다(#98 테스트 유지).
- 수식 후보 규칙(`mathExpressionDetectionText`)은 바꾸지 않는다.
- 커서 이동·리셋 시점, 삭제 경로, undo/redo 기록 방식은 바꾸지 않는다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. VC 연결은 수동으로 확인한다.
- 새 파일을 `Modules/`에 만들지 않는다(pbxproj 변경 없음). 테스트는 기존 파일에 추가한다.
- xcodebuild 출력은 scratchpad 파일로 남기고 테스트는 `-parallel-testing-enabled NO`로 돌린다. 실패가 예상되는 RED 실행은 `timeout 600`으로 감싼다.
- extension scheme 빌드 뒤 `.xcscheme`의 `RemotePath`만 바뀌었으면 되돌린다.

## Review Focus

1. 버퍼가 빈 상태에서 후보로 교체(`가|` + `가방`): 기준 텍스트가 `가가방`이 되지 않고 `가방`이어야 한다. → Task 1 `leadingContextAfterReplacement` 테스트, Task 5 수동 1
2. 앞 조각만 있는 버퍼(`방`)의 현재 단어 확정·스페이스·리턴·전송: 아무것도 학습하지 않고, 이어 친 단어의 문장 단어 수가 어긋나지 않아야 한다. → Task 1 `learnableInputBuffer` 테스트, Task 5 수동 3
3. 앞 글자에 붙여 친 단축어(`가omw`): 대치 후보가 나오고 `omw` 3자만 바뀌어야 한다. → Task 2 테스트, Task 5 수동 5
4. 커서를 단어 중간·공백 뒤·줄바꿈 뒤로 옮긴 경우: 줄바꿈과 공백은 조각 판정에서 경계로 봐야 한다. → Task 1 `isInputBufferAttachedToLeadingContext` 테스트
5. 키 입력 경로 성능: 기준 텍스트가 최대 256자로 길어져도 입력 중 후보 갱신 시간이 눈에 띄게 늘지 않아야 한다. → Task 4 측정

---

## 파일 구조

| 파일 | 변경 | 책임 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift` | 수정 | 기준 텍스트·조각 판정·학습용 버퍼·교체 뒤 앞 문맥(순수), 인자 이름 `baseText:` |
| `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` | 수정 | 대치용 텍스트 인자, 기존 시그니처 호환 extension |
| `Modules/SYKeyboardCore/Domain/SuggestionController.swift` | 수정 | lexicon 조회·교체 길이를 대치용 텍스트로, 마지막 대치용 텍스트 저장 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 수정 | 앞 문맥 상태, 기준 텍스트·학습용 버퍼 연결 |
| `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift` | 수정 | Policy 테스트 |
| `SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift` | 수정 | 대치용 텍스트·교체 길이 테스트 |
| `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` | 수정 | 인자 이름 변경 반영 |
| `docs/architecture/자동완성 로직.md` | 수정 | 기준 텍스트 원칙, 인자, 학습 표(#164 전송 경로 포함) |
| `docs/architecture/성능 고려 사항.md` | 수정 | 측정 기록 |

---

### Task 1: 기준 텍스트·학습용 버퍼 Policy

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (인자 이름 변경만)
- Test: `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `generalSuggestionBaseText(leadingContext: String?, inputBuffer: String, documentContextBeforeInput: String?) -> String`
  - `isInputBufferAttachedToLeadingContext(_ leadingContext: String?) -> Bool`
  - `learnableInputBuffer(_ inputBuffer: String, isAttachedToLeadingContext: Bool) -> String`
  - `leadingContextAfterReplacement(_ leadingContext: String?, inputBufferCount: Int, deleteCount: Int) -> String?`
  - 인자 이름 변경: `suggestionUpdateAction(isPredictiveTextEnabled:selectedText:baseText:)`, `shouldInsertLeadingSpaceBeforeNGramSuggestion(baseText:)`

- [x] **Step 1: 실패하는 테스트 작성**

`KeyboardSuggestionSelectionPolicyTests.swift`에서 기존 호출의 인자 이름을 바꾼다.

```sh
python3 - <<'EOF'
import re
p='SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift'
s=open(p).read()
pattern=re.compile(r'(suggestionUpdateAction|shouldInsertLeadingSpaceBeforeNGramSuggestion)\((.*?)\)', re.S)
s=pattern.sub(lambda m: m.group(1)+'('+m.group(2).replace('inputBuffer:', 'baseText:')+')', s)
open(p,'w').write(s)
EOF
grep -n "inputBuffer:" SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift
```

남는 `inputBuffer:`는 `currentWordForConfirmation(inputBuffer:)`와 `mathExpressionDetectionText(...)`뿐이어야 한다(이름을 바꾸지 않는 함수).
기존 테스트 이름 "n-gram 후보 앞 공백은 입력 버퍼가 비어 있지 않고…"는 "n-gram 후보 앞 공백은 기준 텍스트가 비어 있지 않고…"로 고친다.

같은 파일 struct 끝(마지막 `}` 앞)에 추가한다.

```swift
    @Test("일반 후보 기준 텍스트는 버퍼가 비면 커서 앞 문맥, 있으면 앞 문맥과 버퍼")
    func test일반후보기준텍스트() {
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: "가나 가"
            ) == "가나 가"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: "가나 가", inputBuffer: "방", documentContextBeforeInput: "무시됨"
            ) == "가나 가방"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "안녕", documentContextBeforeInput: nil
            ) == "안녕"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
                leadingContext: nil, inputBuffer: "", documentContextBeforeInput: nil
            ) == ""
        )
    }

    @Test("일반 후보 기준 텍스트는 앞 문맥과 버퍼를 합쳐 끝 256자로 제한")
    func test일반후보기준텍스트는_끝256자로제한() {
        let leading = String(repeating: "a", count: 300)
        let base = KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
            leadingContext: leading, inputBuffer: "b", documentContextBeforeInput: nil
        )

        #expect(base.count == 256)
        #expect(base.hasSuffix("ab"))
    }

    @Test("앞 문맥이 공백이 아닌 글자로 끝날 때만 버퍼 첫 단어를 조각으로 판정")
    func test조각판정() {
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가"))
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가나 ") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("가나\n") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext("") == false)
        #expect(KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext(nil) == false)
    }

    @Test("학습용 버퍼는 앞 글자에 붙은 첫 조각을 뺌")
    func test학습용버퍼는_앞조각을뺌() {
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방 가방 ", isAttachedToLeadingContext: true) == " 가방 ")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방", isAttachedToLeadingContext: true) == "")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer(" 가방", isAttachedToLeadingContext: true) == " 가방")
        #expect(KeyboardSuggestionSelectionPolicy.learnableInputBuffer("방 가방", isAttachedToLeadingContext: false) == "방 가방")
    }

    @Test("교체가 버퍼보다 길면 넘친 글자 수만큼 앞 문맥 끝을 자름")
    func test교체뒤앞문맥() {
        // 버퍼가 빈 상태의 교체: `가|`에서 `가방` 탭
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("가", inputBufferCount: 0, deleteCount: 1) == ""
        )
        // 일부 넘침: 앞 문맥 `가` + 버퍼 `방`에서 `가방끈` 탭
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("나 가", inputBufferCount: 1, deleteCount: 2) == "나 "
        )
        // 넘치지 않음: 한글 조합 교체
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement("나 가", inputBufferCount: 2, deleteCount: 1) == "나 가"
        )
        #expect(
            KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement(nil, inputBufferCount: 0, deleteCount: 3) == nil
        )
    }
```

- [x] **Step 2: RED 확인**

```sh
SCR=<scratchpad>
timeout 600 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests > $SCR/cc1-red.log 2>&1
grep -E "error:|TEST (SUCCEEDED|FAILED)" $SCR/cc1-red.log | sed -E 's/^.*error:/error:/' | sort -u | head
```

Expected: `extra argument 'baseText'`/`incorrect argument label`과 새 함수의 `has no member` 컴파일 오류

- [x] **Step 3: Policy 구현과 VC 인자 이름 변경**

`KeyboardSuggestionSelectionPolicy.swift`:

```swift
    static func shouldInsertLeadingSpaceBeforeNGramSuggestion(baseText: String) -> Bool {
        return !baseText.isEmpty && baseText.last?.isWhitespace != true
    }
```

`suggestionUpdateAction`의 마지막 인자를 `baseText: String`으로 바꾸고 마지막 줄을 `return .update(baseText)`로 바꾼다.

`limitedDocumentContextBeforeInput` 아래에 추가한다.

```swift
    /// 일반 후보(n-gram·TextChecker)의 기준 텍스트
    ///
    /// 버퍼가 비면 그 순간의 커서 앞 문맥을, 버퍼가 있으면 버퍼가 시작될 때 떠 둔 앞 문맥에 버퍼를 이어 쓴다.
    /// 입력 직후의 프록시 문맥은 늦게 갱신될 수 있어, 입력 중에는 키보드가 직접 관리하는 버퍼를 믿는다
    static func generalSuggestionBaseText(
        leadingContext: String?,
        inputBuffer: String,
        documentContextBeforeInput: String?
    ) -> String {
        guard !inputBuffer.isEmpty else {
            return limitedDocumentContextBeforeInput(documentContextBeforeInput)
        }
        return limitedDocumentContextBeforeInput((leadingContext ?? "") + inputBuffer)
    }

    /// 버퍼 첫 단어가 앞 글자에 붙어 시작했는지 판정한다
    static func isInputBufferAttachedToLeadingContext(_ leadingContext: String?) -> Bool {
        guard let last = leadingContext?.last else { return false }
        return !last.isWhitespace
    }

    /// 학습에 넘길 버퍼. 앞 글자에 붙어 시작한 첫 조각을 뺀다
    ///
    /// 매번 같은 규칙으로 빼므로 `recordUncommittedWords`의 문장 단어 수 비교가 어긋나지 않는다
    static func learnableInputBuffer(_ inputBuffer: String, isAttachedToLeadingContext: Bool) -> String {
        guard isAttachedToLeadingContext else { return inputBuffer }
        return String(inputBuffer.drop(while: { !$0.isWhitespace }))
    }

    /// 교체 뒤의 앞 문맥. 지운 글자가 버퍼보다 많으면 넘친 글자 수만큼 앞 문맥 끝을 자른다
    static func leadingContextAfterReplacement(
        _ leadingContext: String?,
        inputBufferCount: Int,
        deleteCount: Int
    ) -> String? {
        guard let leadingContext else { return nil }
        let overflow = deleteCount - inputBufferCount
        guard overflow > 0 else { return leadingContext }
        return String(leadingContext.dropLast(overflow))
    }
```

`BaseKeyboardViewController.swift`의 호출부 인자 이름만 바꾼다(값은 그대로 `inputBuffer`). Task 3에서 기준 텍스트로 바꾼다.

```sh
python3 - <<'EOF'
p='Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift'
s=open(p).read()
old1='''            selectedText: selectedText,
            inputBuffer: inputBuffer
        )
        let mathExpressionText'''
new1='''            selectedText: selectedText,
            baseText: inputBuffer
        )
        let mathExpressionText'''
old2='''shouldInsertLeadingSpaceBeforeNGramSuggestion(
            inputBuffer: inputBuffer'''
new2='''shouldInsertLeadingSpaceBeforeNGramSuggestion(
            baseText: inputBuffer'''
for o,n in [(old1,new1),(old2,new2)]:
    assert s.count(o)==1, o
    s=s.replace(o,n)
open(p,'w').write(s)
EOF
```

- [x] **Step 4: GREEN 확인**

Step 2와 같은 명령(로그 `cc1-green.log`). Expected: `** TEST SUCCEEDED **`, 기존 테스트 + 새 테스트 5개 통과

결과(2026-09-28, iPhone 13 mini / iOS 18.6): RED는 `incorrect argument label ... (have 'baseText:', expected 'inputBuffer:')`와 새 함수 4개의 `has no member`로 컴파일 실패, GREEN은 `Test run with 15 tests in 1 suite passed`(기존 10 + 새 5), `** TEST SUCCEEDED **`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift \
  docs/superpowers/plans/2026-09-28-cursor-context-suggestions.md
git commit -m "feat: #164 - 커서 앞 문맥 기준 텍스트와 학습용 버퍼 정책 추가"
```

---

### Task 2: SuggestionController 대치용 텍스트 분리

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` (인자 이름)
- Test: `SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `SuggestionService.updateSuggestions(for:selectedText:mathExpressionText:textReplacementBaseText:)`
  - `SuggestionService.selectSuggestion(at:baseText:textReplacementBaseText:) -> (deleteCount: Int, insertText: String)?`
  - `SuggestionService.updateSuggestionsAfterNGramSelection(baseText:textReplacementBaseText:)`
  - 호환 extension: `updateSuggestions(for:selectedText:mathExpressionText:)`, `selectSuggestion(at:baseText:)`, `updateSuggestionsAfterNGramSelection(baseText:)`는 대치용 텍스트에 기준 텍스트를 그대로 넘긴다

- [ ] **Step 1: 실패하는 테스트 작성**

`SuggestionControllerSuggestionRemovalTests.swift`의 `updateSuggestionsAfterNGramSelection(inputBuffer: "오늘 날씨")`를 `updateSuggestionsAfterNGramSelection(baseText: "오늘 날씨")`로 바꾼다.

`SuggestionControllerNGramCompletionTests.swift`의 `makeHarness` 위에 추가한다.

```swift
    @Test("앞 글자에 붙여 친 단축어는 대치용 텍스트로 찾고 단축어 길이만 교체")
    func test앞글자에붙여친단축어는_대치용텍스트로찾고_단축어길이만교체() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "omw", documentText: "On my way!")]
        )

        harness.controller.updateSuggestions(
            for: "가omw",
            selectedText: nil,
            mathExpressionText: "omw",
            textReplacementBaseText: "omw"
        )
        let result = harness.controller.selectSuggestion(
            at: 0,
            baseText: "가omw",
            textReplacementBaseText: "omw"
        )
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last?.currentWord == "가omw")
        #expect(harness.delegate.updates.last?.suggestions.first == "On my way!")
        #expect(result?.deleteCount == 3)
        #expect(result?.insertText == "On my way!")
    }

    @Test("완성 후보 교체 길이는 기준 텍스트의 마지막 단어 길이")
    func test완성후보교체길이는_기준텍스트의마지막단어길이() async {
        let harness = makeHarness()
        harness.nGram.completionResults = ["가방"]

        // 커서를 `가|나`로 옮긴 직후: 버퍼는 비고 기준 텍스트는 커서 앞 문맥
        harness.controller.updateSuggestions(
            for: "가",
            selectedText: nil,
            mathExpressionText: "",
            textReplacementBaseText: ""
        )
        let result = harness.controller.selectSuggestion(at: 0, baseText: "가", textReplacementBaseText: "")
        await harness.finishTextChecker()

        #expect(result?.deleteCount == 1)
        #expect(result?.insertText == "가방")
    }

    @Test("다음 단어 예측 뒤 입력 중 모드로 돌아가도 대치용 텍스트로 단축어를 찾음")
    func test다음단어예측뒤_입력중모드로돌아가도_대치용텍스트로단축어를찾음() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "omw", documentText: "On my way!")]
        )

        // NGram 결과가 없으면 입력 중 갱신으로 폴백한다
        harness.controller.updateSuggestionsAfterNGramSelection(baseText: "가omw", textReplacementBaseText: "omw")
        await harness.finishTextChecker()

        #expect(harness.delegate.updates.last?.suggestions.first == "On my way!")
    }
```

- [ ] **Step 2: RED 확인**

```sh
timeout 600 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/SuggestionControllerNGramCompletionTests \
  -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests > $SCR/cc2-red.log 2>&1
grep -E "error:|TEST (SUCCEEDED|FAILED)" $SCR/cc2-red.log | sed -E 's/^.*error:/error:/' | sort -u | head
```

Expected: `extra argument 'textReplacementBaseText'`, `incorrect argument label ... (have 'baseText:', expected 'inputBuffer:')` 컴파일 오류

- [ ] **Step 3: 구현**

`SuggestionService.swift`의 요구사항을 바꾼다.

```swift
    ///   - mathExpressionText: 수식 탐지에만 사용하는 텍스트. 일반 예측 엔진과
    ///     텍스트 대치에는 전달하지 않습니다.
    ///   - textReplacementBaseText: 텍스트 대치(단축어) 조회에만 쓰는 텍스트. 현재 세션 `inputBuffer`이며
    ///     커서 앞 문맥을 넣지 않습니다.
    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String,
        textReplacementBaseText: String
    )

    /// n-gram 추천 탭 후 강제로 n-gram 갱신을 시도하고,
    /// 결과가 없으면 입력 중 모드로 폴백합니다.
    ///
    /// - Parameters:
    ///   - baseText: 일반 후보 기준 텍스트(커서 앞 문맥)
    ///   - textReplacementBaseText: 폴백 때 텍스트 대치 조회에 쓰는 `inputBuffer`
    func updateSuggestionsAfterNGramSelection(baseText: String, textReplacementBaseText: String)
```

`selectSuggestion` 요구사항:

```swift
    ///   - textReplacementBaseText: 텍스트 대치 후보의 교체 길이를 계산할 `inputBuffer`
    func selectSuggestion(
        at index: Int,
        baseText: String,
        textReplacementBaseText: String
    ) -> (deleteCount: Int, insertText: String)?
```

`extension SuggestionService`에 호환 메서드를 추가한다(기존 `updateSuggestions(for:selectedText:)`는 3인자 호출을 그대로 쓴다).

```swift
    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String
    ) {
        updateSuggestions(
            for: baseText,
            selectedText: selectedText,
            mathExpressionText: mathExpressionText,
            textReplacementBaseText: baseText
        )
    }

    func selectSuggestion(at index: Int, baseText: String) -> (deleteCount: Int, insertText: String)? {
        selectSuggestion(at: index, baseText: baseText, textReplacementBaseText: baseText)
    }

    func updateSuggestionsAfterNGramSelection(baseText: String) {
        updateSuggestionsAfterNGramSelection(baseText: baseText, textReplacementBaseText: baseText)
    }
```

`SuggestionController.swift`:

1. `lastMathExpressionText` 선언 아래에 추가한다.

```swift
    /// 마지막으로 텍스트 대치 조회를 요청한 텍스트
    private var lastTextReplacementBaseText: String?
```

`lastMathExpressionText = nil`이 있는 두 곳(`updateLanguage`, `clearSuggestions`)에 `lastTextReplacementBaseText = nil`을 함께 넣는다.

2. `updateSuggestions(for:selectedText:mathExpressionText:)` 구현을 4인자로 바꾼다.

```swift
    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String,
        textReplacementBaseText: String
    ) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin(selectedText: selectedText)
        lastSuggestionBaseText = baseText
        lastMathExpressionText = mathExpressionText
        lastTextReplacementBaseText = textReplacementBaseText
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()
        performUpdateSuggestions(
            for: baseText,
            mathExpressionText: mathExpressionText,
            textReplacementBaseText: textReplacementBaseText,
            origin: origin
        )
    }
```

3. `updateSuggestionsAfterNGramSelection(inputBuffer:)`를 바꾼다.

```swift
    func updateSuggestionsAfterNGramSelection(baseText: String, textReplacementBaseText: String) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        let origin = MathSuggestionOrigin.unselected
        lastSuggestionBaseText = baseText
        lastMathExpressionText = baseText
        lastTextReplacementBaseText = textReplacementBaseText
        lastSuggestionOrigin = origin
        preparePredictiveEnginesIfNeeded()
        prepareLexiconEngineIfNeeded()
        let nGramResults = nGramSuggestions(for: baseText)
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
                for: baseText,
                mathExpressionText: baseText,
                textReplacementBaseText: textReplacementBaseText,
                origin: origin
            )
        }
    }
```


4. `selectSuggestion`:

```swift
    func selectSuggestion(
        at index: Int,
        baseText: String,
        textReplacementBaseText: String
    ) -> (deleteCount: Int, insertText: String)? {
        guard index >= 0, index < currentSuggestions.count else { return nil }

        if let last = baseText.last, last.isWhitespace { return nil }

        let item = currentSuggestions[index]
        // 텍스트 대치는 이 키보드로 친 단어(`inputBuffer`)만 바꾼다. 나머지는 커서 앞 단어 전체를 바꾼다
        let currentWord = extractLastWord(from: item.source == .lexicon ? textReplacementBaseText : baseText)
```

이후 `appendReplacementRecord(... baseText: baseText ...)`는 `baseText: textReplacementBaseText`로 바꾼다. 나머지는 그대로다.

5. `removeSuggestionWord`의 `updateSuggestionsAfterNGramSelection(inputBuffer: lastSuggestionBaseText)`를 다음으로 바꾼다.

```swift
            updateSuggestionsAfterNGramSelection(
                baseText: lastSuggestionBaseText,
                textReplacementBaseText: lastTextReplacementBaseText ?? lastSuggestionBaseText
            )
```

6. `performUpdateSuggestions`에 `textReplacementBaseText: String` 인자를 `mathExpressionText` 다음에 추가하고, `lexiconEngine?.suggestions(for: baseText)`를 `lexiconEngine?.suggestions(for: textReplacementBaseText)`로 바꾼다. `performRefreshSuggestionsAfterNGramLoadIfNeeded()`는 다음처럼 넘긴다.

```swift
        performUpdateSuggestions(
            for: lastSuggestionBaseText,
            mathExpressionText: lastMathExpressionText,
            textReplacementBaseText: lastTextReplacementBaseText ?? lastSuggestionBaseText,
            origin: lastSuggestionOrigin
        )
```

나머지 `performUpdateSuggestions(` 호출도 컴파일 오류를 따라 같은 인자를 넣는다(`grep -n "performUpdateSuggestions(" Modules/SYKeyboardCore/Domain/SuggestionController.swift`).

- [ ] **Step 4: GREEN 확인**

Step 2와 같은 명령(로그 `cc2-green.log`). Expected: `** TEST SUCCEEDED **`. 이어서 텍스트 대치 테스트도 돌린다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests > $SCR/cc2-regress.log 2>&1
grep -E "TEST (SUCCEEDED|FAILED)|Test run with" $SCR/cc2-regress.log
```

Expected: `** TEST SUCCEEDED **`("분리된 커서 문맥은 일반 추천과 텍스트 대치 입력으로 전달하지 않음" 포함)

- [ ] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerNGramCompletionTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift \
  docs/superpowers/plans/2026-09-28-cursor-context-suggestions.md
git commit -m "feat: #164 - 자동완성 텍스트 대치 조회를 일반 후보 기준 텍스트와 분리"
```

---

### Task 3: VC 연결

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`

**Interfaces:**
- Consumes: Task 1의 Policy 함수 4개와 `baseText:` 인자, Task 2의 `updateSuggestions(...textReplacementBaseText:)`, `selectSuggestion(at:baseText:textReplacementBaseText:)`, `updateSuggestionsAfterNGramSelection(baseText:textReplacementBaseText:)`
- Produces: 없음(VC 내부)

VC 연결은 자동 테스트로 고정하지 않는다(spec "테스트" 절). 검증은 빌드와 Task 5 수동 확인이다.

- [ ] **Step 1: 앞 문맥 상태와 helper**

`private var pendingSentTextSnapshot: SentTextSnapshot?` 아래:

```swift
    /// 버퍼가 빈 상태에서 첫 글자를 넣기 직전의 커서 앞 문맥(최대 256자). 후보 기준 텍스트와 조각 판정에 쓴다
    private var inputBufferLeadingContext: String?
```

`// MARK: - Sent Text Recording` 바로 위:

```swift
// MARK: - Cursor Context Suggestions

private extension BaseKeyboardViewController {
    /// 버퍼가 비어 있으면 첫 글자를 넣기 직전의 커서 앞 문맥을 떠 둔다
    func captureInputBufferLeadingContextIfNeeded() {
        guard inputBuffer.isEmpty else { return }
        inputBufferLeadingContext = KeyboardSuggestionSelectionPolicy.limitedDocumentContextBeforeInput(
            textDocumentProxy.documentContextBeforeInput
        )
    }

    /// 일반 후보(n-gram·TextChecker)의 기준 텍스트
    var generalSuggestionBaseText: String {
        KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
            leadingContext: inputBufferLeadingContext,
            inputBuffer: inputBuffer,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
        )
    }

    /// 앞 글자에 붙어 시작한 조각을 뺀 버퍼. NGram 기록과 현재 단어 확정에 쓴다
    var learnableInputBuffer: String {
        KeyboardSuggestionSelectionPolicy.learnableInputBuffer(
            inputBuffer,
            isAttachedToLeadingContext: KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext(
                inputBufferLeadingContext
            )
        )
    }
}
```

- [ ] **Step 2: 버퍼를 바꾸는 5곳 연결**

`insertText(_:)` 첫 줄에 `captureInputBufferLeadingContextIfNeeded()`를 넣는다.

`deleteText()`의 `if inputBuffer.isEmpty {` 블록 안, `suggestionController.resetSentenceBuffer()` 아래에 `inputBufferLeadingContext = nil`을 넣는다.

`replaceText(deleteCount:insert:)`:

```swift
    public func replaceText(deleteCount: Int, insert text: String) {
        captureInputBufferLeadingContextIfNeeded()
        let inputBufferCountBeforeReplacement = inputBuffer.count
        let deletedText = textBeforeCursorSuffix(count: deleteCount)
        replaceTextInDocument(deleteCount: deleteCount, insert: text)
        replaceInputBufferSuffix(deleteCount: deleteCount, insert: text)
        inputBufferLeadingContext = KeyboardSuggestionSelectionPolicy.leadingContextAfterReplacement(
            inputBufferLeadingContext,
            inputBufferCount: inputBufferCountBeforeReplacement,
            deleteCount: deleteCount
        )
        recordUndoRedoChange(deletedText: deletedText, insertedText: text)
    }
```

`resetInputBuffer()`에 `inputBufferLeadingContext = nil`을 넣는다.

`replaceSelectedText(_:with:)` 첫 줄에 `captureInputBufferLeadingContextIfNeeded()`를 넣는다.

- [ ] **Step 3: 후보 갱신·적용·학습 경로 연결**

`updateSuggestionsForCurrentContext()`:

```swift
        let action = KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
            isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
            selectedText: selectedText,
            baseText: generalSuggestionBaseText
        )
```

`.update(let text)`:

```swift
        case .update(let text):
            suggestionController.updateSuggestions(
                for: text,
                selectedText: selectedText,
                mathExpressionText: mathExpressionText,
                // 선택 텍스트 후보는 선택한 단어 그대로 대치를 찾는다
                textReplacementBaseText: selectedText?.isEmpty == false ? text : inputBuffer
            )
```

`handleNGramSuggestion(at:)`:

```swift
        if KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
            baseText: generalSuggestionBaseText
        ) {
            insertText(" ")
        }

        insertText(word)

        suggestionDidApply()

        suggestionController.updateSuggestionsAfterNGramSelection(
            baseText: generalSuggestionBaseText,
            textReplacementBaseText: inputBuffer
        )
```

`handleCurrentWordConfirmationIfNeeded(at:)`의 `currentWordForConfirmation(inputBuffer: inputBuffer)`를 `currentWordForConfirmation(inputBuffer: learnableInputBuffer)`로 바꾼다.

`handleInputBufferSuggestion(at:)`:

```swift
        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            baseText: generalSuggestionBaseText,
            textReplacementBaseText: inputBuffer
        ) else { return }
```

`insertSpaceText()`: `recordUncommittedWords(from: inputBuffer)` → `recordUncommittedWords(from: learnableInputBuffer)`

`insertReturnText()`: `endSentence(inputBuffer: inputBuffer)` → `endSentence(inputBuffer: learnableInputBuffer)`

`makeSentTextSnapshot()`:

```swift
    func makeSentTextSnapshot() -> SentTextSnapshot? {
        let buffer = learnableInputBuffer
        guard buffer.contains(where: { !$0.isWhitespace }) else { return nil }
        return SentTextSnapshot(
            inputBuffer: buffer,
            sentenceWords: suggestionController.sentenceWordsSnapshot(),
            documentIdentifier: currentDocumentIdentifier()
        )
    }
```

- [ ] **Step 4: 4개 scheme 빌드**

```sh
for S in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme $S \
    -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' > $SCR/cc3-$S.log 2>&1
  echo "$S $(grep -E 'BUILD (SUCCEEDED|FAILED)' $SCR/cc3-$S.log)"
done
git status --short
```

Expected: 4개 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 `RemotePath`만 바뀌었으면 되돌린다.

- [ ] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-09-28-cursor-context-suggestions.md
git commit -m "feat: #164 - 커서 앞 문맥 기준 자동완성과 앞 조각 학습 제외 연결"
```

---

### Task 4: 전체 테스트, 성능 측정, 문서

**Files:**
- Modify: `docs/architecture/자동완성 로직.md`
- Modify: `docs/architecture/성능 고려 사항.md`
- Modify: `docs/superpowers/plans/2026-09-28-cursor-context-suggestions.md`

**Interfaces:**
- Consumes: Task 1–3 전체
- Produces: 검증 기록, 문서

- [ ] **Step 1: 전체 테스트**

```sh
timeout 900 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO > $SCR/cc4-all.log 2>&1
grep -E "TEST (SUCCEEDED|FAILED)|Test run with|✘ Test" $SCR/cc4-all.log | tail -5
```

Expected: `** TEST SUCCEEDED **`. 개수와 결과를 기록하고 커밋한다(`docs: #164 - 커서 앞 문맥 자동완성 전체 테스트 결과 기록`).

- [ ] **Step 2: 입력 중 후보 갱신 시간 비교(시뮬레이터)**

`성능 고려 사항.md` §6-4 방식으로 임시 테스트를 만들어 측정하고, 측정 뒤 삭제한다. 실제 `NGramPredictiveTextEngine`(학습 단어 1,000개)과 stub TextChecker로 같은 입력 단어를 두 기준 텍스트로 각각 1,000번 갱신해 1회 평균을 잰다.

임시 파일 `SYKeyboardTests/Domain/TemporaryCursorContextBenchmarkTests.swift`:

```swift
import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("임시: 커서 앞 문맥 기준 텍스트 후보 갱신 시간")
struct TemporaryCursorContextBenchmarkTests {
    @Test("짧은 기준과 256자 기준의 1회 평균")
    func measure() async {
        let engine = await makeLoadedNGramFixture(name: "cursor-context-bench").engine
        for index in 0..<1000 {
            engine.addWord("가방\(index)")
            engine.endSentence()
        }
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { StubLexiconSuggestionProvider() },
            makeTextCheckerEngine: { _ in StubPredictiveTextProvider() },
            makeNGramEngine: { _ in engine }
        )
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory)
        controller.isPredictiveTextEnabled = true
        let shortBase = "안녕 가방"
        let longBase = String(repeating: "문장 ", count: 83) + "가방"

        for (name, base) in [("short", shortBase), ("long", longBase)] {
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                for _ in 0..<1000 {
                    controller.updateSuggestions(
                        for: base,
                        selectedText: nil,
                        mathExpressionText: "가방",
                        textReplacementBaseText: "가방"
                    )
                }
            }
            print("[cursor-context-bench] \(name) count=\(base.count) per-call=\(elapsed / 1000)")
        }
    }
}
```

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO SWIFT_OPTIMIZATION_LEVEL=-O \
  -only-testing:SYKeyboardTests/TemporaryCursorContextBenchmarkTests > $SCR/cc4-bench.log 2>&1
grep "cursor-context-bench" $SCR/cc4-bench.log
rm SYKeyboardTests/Domain/TemporaryCursorContextBenchmarkTests.swift
git status --short
```
 차이가 1회 0.1ms 안이면 통과로 본다(120Hz 부가 기능 예산 4ms의 2.5%). 측정값을 `성능 고려 사항.md` §3에 새 절(`3-6. 커서 앞 문맥 기준 텍스트 (#164)`)로 날짜·기기·빌드와 함께 적는다. 실기기 Release Instruments(§6-2)는 사용자가 요청할 때 한다. 적지 않으면 "실기기 미측정(추정)"으로 표시한다. 임시 테스트 파일이 남지 않았는지 `git status --short`로 확인하고 문서만 커밋한다(`docs: #164 - 커서 앞 문맥 기준 텍스트 후보 갱신 시간 측정 기록`).

- [ ] **Step 3: `자동완성 로직.md` 갱신**

- 핵심 원칙의 "모든 후보 조회는 `inputBuffer` 기준" 문단을 바꾼다: 일반 후보는 커서 앞 문맥 기준(버퍼가 비면 그 순간의 문맥, 있으면 떠 둔 앞 문맥 + 버퍼), 텍스트 대치·학습은 `inputBuffer` 기준, 앞 글자에 붙은 첫 조각은 학습하지 않음.
- §3의 `updateSuggestions` 시그니처와 인자 설명에 `textReplacementBaseText`를 넣고, 정책 트리의 `.update(inputBuffer)`를 `.update(generalSuggestionBaseText)`로 바꾼다.
- §3-4의 `updateSuggestionsAfterNGramSelection(inputBuffer:)`를 `(baseText:textReplacementBaseText:)`로 바꾼다.
- §8-2 기록 표: 스페이스·리턴·현재 단어 확정은 `learnableInputBuffer`를 쓴다고 고치고, #164 전송 행을 추가한다. "전송(입력창이 전송으로 비워짐) | `textWillChange`에서 뜬 스냅샷으로 `KeyboardSentTextDetectionPolicy`가 판정하면 `endSentence(inputBuffer:restoringSentenceWords:)` — 리턴과 같은 기록·저장. 검색창(`.search`) 제외"

커밋: `docs: #164 - 자동완성 로직 문서에 커서 앞 문맥 기준과 전송 학습 경로 반영`

---

### Task 5: 수동 확인

**Files:**
- Modify: `docs/superpowers/plans/2026-09-28-cursor-context-suggestions.md` (결과 기록)

**Interfaces:**
- Consumes: Task 1–4 전체
- Produces: 검증 기록

- [ ] **Step 1: 시뮬레이터 수동 확인**

준비는 #164 계획 Task 5 Step 2와 같다(가장 최근 DerivedData 빌드 설치, 한글 키보드만 남기기, 클립보드 기록 끄기, 끝나면 복원). NGram 학습 여부는 App Group `Library/Application Support/ngram_ko-KR.plist`를 `plutil -p`로 본다. 커서 이동은 idb 스와이프가 먹지 않으므로 입력창 안을 클릭해 옮기도록 사용자에게 요청한다.

1. `가나` 입력 → 커서를 `가|나`로 옮김 → `가`로 시작하는 후보 → `가방`(미리 학습) 탭 → `가방|나`
2. 커서를 `가나 |`로 옮김 → `가나` 다음 단어 예측
3. `가|`에서 `방` 입력 → `가방` 기준 후보 → 스페이스 → 파일에 `방` unigram 없음
4. 기존 텍스트가 있는 대화 초안을 열면 그 텍스트 기준 예측
5. `가` 뒤에 `omw` → 대치 후보 탭 → `가On my way!`
6. 기존 텍스트 `안녕` 끝에서 `하세요` + 스페이스 → 파일에 `하세요` 없음
7. 회귀: 평소 입력 후보·단어 완성, 스페이스·리턴 학습, #164 전송 학습, 텍스트 대치(스페이스), 수식 후보(`3+1=`), #164 검색창 X 버튼(검색창에 입력 → X → 학습 안 됨)

각 항목 결과를 이 문서에 기록하고 커밋한다(`docs: #164 - 커서 앞 문맥 자동완성 시뮬레이터 수동 확인 결과 기록`).

- [ ] **Step 2: 실기기 확인**

사용자에게 이 브랜치를 SNMac's iPhone에 설치해 달라고 요청하고, Step 1의 1·2·3·5·7(카카오톡)을 확인한다. 기기에 이미 학습된 단어와 겹치지 않는 드문 조합을 쓴다. 결과를 기록하고 커밋한다(`docs: #164 - 커서 앞 문맥 자동완성 실기기 확인 결과 기록`).
