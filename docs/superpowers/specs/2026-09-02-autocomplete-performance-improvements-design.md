# 자동완성 키 입력 경로 성능 개선 설계

## 목적

GitHub Issue #123에 따라 자동완성 키 입력 경로에서 확인된 성능 후보를 개선한다.
배포 전 예방 점검에서 발견한 항목이며, 사용자에게 보고된 지연은 아직 없다.

개선은 두 부류로 나눈다.

- **기능 보존형**(항목 2, 3, 4, 1-a): 입력과 상태가 같으면 반환값과 디스크 내용이
  현재와 동일함을 보장한다. 동작 변경 없이 비용만 줄인다.
- **실험 적용**(항목 1-b): 후보 표시를 키 입력 프레임에서 분리하는 입력 흐름 변경이다.
  마지막 커밋으로 격리해 `git revert` 한 번으로 되돌릴 수 있게 하고, 실기기 측정으로
  유지/되돌림을 결정한다.

## 확인한 기준

- 작업 브랜치: `chore/#123-autocomplete-perf-signposts`. 계측 커밋 `a978c070`
  (`chore: #123 - 자동완성 성능 계측용 OSSignposter 구간 추가`) 위에 이어서 작업한다.
- 계측 구간: `TextCheckerCompletions`, `TextCheckerGuesses`, `LexiconSuggestions`,
  `TextCheckerSuggestions`, `TextReplacementMatch`, `RankedUnigramCandidates`,
  `NGramRecord`, `NGramSaveSnapshot`, `NGramSaveEncode`.
- 키 입력 1회에서 자동완성이 실행되는 경로:
  `BaseKeyboardViewController.updateSuggestionsForCurrentContext()` →
  `SuggestionController.updateSuggestions(for:selectedText:mathExpressionText:)` →
  `performUpdateSuggestions` → 단어 입력 중이면 `mergeSuggestions`, 단어 경계면
  `nGramSuggestions`. 전부 메인 스레드에서 동기로 실행된다.
- `SuggestionController.maxSuggestions = 3`, `mergeSuggestions`의
  `maxSuggestionSlots = maxSuggestions - 1 = 2`.
- `textCheckerEngine`의 선언 타입은 `PredictiveTextProvider`, `lexiconEngine`은
  `LexiconSuggestionProviding`, `nGramEngine`은 `NGramPredictiveTextProviding`이다.
  엔진은 `SuggestionControllerEngineFactory`로 주입되므로 테스트에서 stub으로 교체할 수 있다.
- `unigramStore`를 대입·변이하는 경로는 디스크 로드 반영, `resetAllData()`,
  `recordNGrams()`, `pruneUnigram()` 4곳이다.
- `saveToDisk()` 호출 지점: `NGramPredictiveTextEngine.endSentence()`,
  `scheduleSave()`(10회 기록마다), `SuggestionController.updateLanguage(to:)`,
  `SuggestionController.saveNGramData()`(`BaseKeyboardViewController` 408행, 키보드 종료 시).

## 예상 효과와 사용자 체감

실측 전 추정이다. 실제 값은 계측 구간으로 확인한다.

| 구간 | 현재 | 항목 2·3·4·1-a 반영 후 | 항목 1-b 반영 후 |
| --- | --- | --- | --- |
| 프록시 IPC | 약 1~3 ms | 동일 | 동일 |
| lexicon 조회 | lexicon 크기에 비례 | ~0 | ~0 |
| UITextChecker `completions` | 약 0.5~3 ms | 동일 | 0 (백그라운드) |
| UITextChecker `guesses` | 약 2~15 ms, 구형 기기 + 긴 단어 20~50 ms | `completions`로 2슬롯이 차면 0 | 0 (백그라운드) |
| unigram 정렬 (단어 경계) | 최대 5,000개 정렬 | 캐시 적중 시 0, 미적중 시 O(n) | 동일 |
| 메인 스레드 합계 (단어 입력 중) | 약 3~20 ms, 최악 30~50 ms | 약 3~20 ms, `guesses` 생략 시 3~8 ms | 약 2~4 ms |

글자가 화면에 찍히는 지연은 어느 항목과도 무관하다. `insertText`는 자동완성 계산 전에
호스트 앱으로 전달되고 호스트 앱이 독립적으로 렌더링한다. 이 개선이 바꾸는 것은 키보드
자체의 반응성(키 하이라이트 애니메이션, 다음 터치 처리 시작 시점)과 후보 바 갱신 시점이다.
타이핑 간격(100~200 ms)이 점유 시간보다 훨씬 길어 대부분의 사용자는 차이를 느끼지 못하며,
체감 가능한 경우는 구형 기기에서 `guesses`가 한 프레임(16.7 ms)을 넘겨 애니메이션이 끊기는
상황으로 한정된다.

## 항목 2: lexicon 인덱스

### 현재

- `LexiconPredictiveTextEngine.suggestions(for:)`는 키 입력마다 `lexicon.entries` 전체를
  순회하며 엔트리마다 `userInput.lowercased()`, `documentText.lowercased()`를 호출한다.
- `SuggestionController.textReplacementMatch(baseText:)`는 호출마다
  `textReplacementEntries` computed property로 전체 엔트리를 새 배열로 재매핑하고,
  filter 클로저 안에서 `currentWord.lowercased()`를 엔트리 수만큼 재계산하며
  `entry.userInput.lowercased()`를 엔트리당 2회 호출한다.

### 변경

- `LexiconPredictiveTextEngine.setLexicon(_:)`에서 `lexicon.entries`를 한 번 순회해
  `[String: [TextReplacementEntry]]` 인덱스를 만든다. 키는 `userInput.lowercased()`,
  값은 엔트리 원래 순서를 보존한 배열이다.
- `suggestions(for:)`는 `index[lastWord.lowercased()]`를 조회한 뒤, 현재와 같은
  `documentText.lowercased() != lowered` 필터를 그 배열에만 적용한다. 이 필터는 검색어에
  의존하므로 인덱스에 미리 넣지 않는다.
- `LexiconSuggestionProviding`의 `var textReplacementEntries: [TextReplacementEntry]`를
  `func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry]`로
  교체한다. 사용처는 `textReplacementMatch` 한 곳이다.
- `textReplacementMatch`는 `currentWord.lowercased()`를 1회 계산해 인덱스를 조회하고,
  기존의 `userInput.lowercased() == "m" && documentText == "M"` 제외를 적용한 뒤 현재와 같은
  `max(by: userInput.count)`로 고른다.

### 보존 계약

- 입력과 lexicon이 같으면 `suggestions(for:)`와 `textReplacementMatch`의 반환값(내용과 순서)이
  현재와 완전히 일치한다.
- `max(by:)`는 동률에서 첫 요소를 유지한다. 인덱스가 엔트리 순서를 보존하므로 같은
  `userInput`(대소문자만 다른 경우 포함)이 여러 개일 때의 선택도 동일하다.
- `UILexicon.entries`는 로드 후 불변이므로 인덱스가 낡을 수 없다.

### 테스트

- 기존 `SuggestionControllerTextReplacementTests`를 회귀 방지로 사용한다.
  `StubLexiconSuggestionProvider`는 자기 배열을 소문자 키로 필터해 새 메서드를 구현한다.
- 추가: 같은 `userInput`이 대소문자만 다르게 여러 개일 때 첫 엔트리가 선택되는지,
  `"m" → "M"` 제외가 유지되는지를 `SuggestionController` 진입점으로 검증한다.

## 항목 3: unigram 부분 선택, 캐시, `pruneUnigram`

### 현재

- `rankedUnigramCandidates()`는 상위 `maxPredictions`(3)개를 얻기 위해 `unigramStore` 전체
  (최대 `maxKeys` = 5,000)를 정렬한다. 문맥이 빈 키 입력(스페이스·문장 시작)마다 실행된다.
- `pruneUnigram()`은 `unigramStore.count > maxKeys`일 때 전체를 정렬해 초과분을 제거한다.
  정상 경로에서는 기록마다 최대 1개 증가하므로 상한 도달 후에는 새 단어마다 1개를 지우기
  위해 전체 정렬이 실행된다.

### 변경

- `rankedUnigramCandidates()`를 한 번 순회하며 상위 `maxPredictions`개만 유지하는 부분
  선택으로 바꾼다.
- 결과를 `rankedUnigramCache: [String]?`에 저장하고 `unigramStore`에
  `didSet { rankedUnigramCache = nil }`을 붙인다. 4개 변이 경로가 모두 `unigramStore`
  대입·변이를 거치므로 호출 지점마다 무효화 코드를 두지 않는다.
- `pruneUnigram()`은 초과분이 정확히 1개일 때 `min(by:)`로 최소 빈도 항목 하나를 찾아
  제거한다. 초과분이 2개 이상이면(상한을 넘긴 마이그레이션 데이터 등) 현재의 정렬 방식을
  그대로 둔다.
- `maxKeys`를 지정 init 파라미터(기본값 5,000)로 주입할 수 있게 한다. 기존
  `loadApplyDelay`와 같은 테스트 전용 init 파라미터 방식이며 production 타입에 테스트
  전용 메서드를 추가하지 않는다.

### 보존 계약

- 후보 집합은 "빈도 상위 3개"로 동일하다. 빈도 동률 경계에서 어느 단어가 뽑히는지는 현재도
  딕셔너리 순회 순서에 따라 비결정적이며, 이번 변경도 이를 정의하지 않는다.
- prune 결과는 "최소 빈도 1개 제거"로 동일하다. 동률 선택은 마찬가지로 미정의다.

### 테스트

- 빈도가 서로 다른 단어 5개 이상을 `addWord`로 학습한 뒤 `suggestions(for: "")`가 상위
  3개를 빈도순으로 반환한다.
- 캐시 무효화: 상위 3개를 확인한 뒤 새 단어를 4회 학습해 1위로 만들면 결과가 갱신된다.
  `resetAllData()` 후에는 빈 결과다.
- prune: `maxKeys`를 작은 값(예: 3)으로 주입하고 상한을 넘겨 학습하면 최소 빈도 단어가
  후보에서 사라진다.

## 항목 4: 저장 dirty flag

### 현재

- `saveToDisk()`는 호출될 때마다 세 저장소의 스냅샷을 만들어 백그라운드 직렬 큐에서
  인코딩·쓰기한다. 스냅샷은 CoW라 즉시 비용은 없지만, 큐가 참조를 잡고 있는 동안 메인
  스레드의 다음 `recordNGrams()`가 딕셔너리 실제 복사를 유발한다.
- 리턴 키마다 `endSentence()`가 저장하고, 언어 전환·키보드 종료에서도 저장한다.
  변경이 없어도 매번 수행된다.

### 변경

- `private var hasUnsavedChanges = false`를 추가한다.
  - `true`: `recordNGrams()` 끝. 학습이 저장소를 바꾸는 유일한 경로다.
  - `false`: 디스크 로드 반영 직후(`flushPendingEvents()` 전 — 보류 이벤트가 `addWord`를
    재생하면 그때 다시 `true`가 된다), `resetAllData()`(파일 삭제 + 빈 저장소),
    `saveToDisk()`가 스냅샷을 뜬 직후.
- `saveToDisk()` 진입 가드를 `guard isLoaded, hasUnsavedChanges || needsLegacyCleanup`로
  확장한다. 보류된 레거시 정리는 저장 경로에 얹혀 있으므로 dirty가 아니어도 통과시킨다.
- 백그라운드 쓰기가 실패하면 main으로 돌아와 `hasUnsavedChanges = true`로 되돌려 다음 저장
  기회에 재시도한다. 세대 불일치로 건너뛴 경우(`resetAllData()` 이후)는 되돌리지 않는다.
- `scheduleSave`, `endSentence`, `updateLanguage(to:)`, `saveNGramData()`의 호출은 그대로
  두고 가드에서 걸러지게 한다.

### 보존 계약

- 어떤 호출 순서에서도 "저장이 실제로 수행된 뒤의 디스크 내용"은 현재와 동일하다. 달라지는
  것은 내용이 같은 재저장을 건너뛰는 것뿐이다.
- 키보드 확장이 강제 종료돼도 유실 범위는 현재와 같다(마지막 실제 저장 이후 변경분).

### 테스트

임시 `fileURL`을 주입하는 기존 `NGramPredictiveTextEngineLoadingTests` 방식을 따른다.
백그라운드 쓰기 완료를 기다릴 수 있도록 `saveQueue`도 init 파라미터(기본값: 기존 전용
직렬 큐)로 주입하고 테스트에서 `sync {}`로 비운다. 파일 부재 단언이 "아직 쓰지 않았을 뿐"으로
거짓 통과하지 않게 하기 위해서다.

- 파일이 없는 상태로 로드 완료 후 `saveToDisk()`를 호출하면 파일이 생성되지 않는다.
  현재는 빈 plist가 써지므로 이 변경의 결정적이고 관찰 가능한 차이다.
- `addWord` → `endSentence()` 후 파일이 존재한다.
- `resetAllData()` 후 `saveToDisk()`를 호출해도 파일이 없다.
- 쓰기 실패 재시도는 파일 시스템 오류를 신뢰성 있게 재현하기 어려워 자동 테스트에서
  제외한다. 미검증 항목으로 기록한다.

## 항목 1-a: `guesses` 조건부 생략

### 현재

`TextCheckerPredictiveTextEngine.suggestions(for:)`는 `completions`와 `guesses`를 항상 둘 다
호출하고 `completions` 결과 뒤에 `guesses` 결과를 이어 붙여 반환한다. `guesses`(오타 교정
탐색)가 둘 중 무거운 쪽이다.

### 변경

- `PredictiveTextProvider`에 `func suggestions(for baseText: String, limit: Int) -> [String]`을
  추가하고 protocol extension 기본 구현은 `suggestions(for:)`를 그대로 호출한다. 다른 엔진은
  영향받지 않는다.
- `TextCheckerPredictiveTextEngine`은 `limit` 버전을 구현한다. `completions`를 현재처럼 중복
  제거하며 모으다 `merged.count >= limit`이면 `guesses`를 호출하지 않고 반환한다. 부족할
  때만 `guesses`를 호출하고 `limit`에 도달하면 중단한다. 기존 `suggestions(for:)`는
  `limit: Int.max`로 위임한다.
- `SuggestionController.mergeSuggestions`는 lexicon 결과로 슬롯이 다 차면 반환한 뒤에야
  `textCheckerEngine`을 `suggestions(for:limit: maxSuggestionSlots)`로 호출한다. 현재는
  lexicon 결과와 무관하게 먼저 호출하고 버리므로, 이 순서 변경도 출력에 영향이 없다.

### 보존 증명

`mergeSuggestions`는 lexicon 결과를 먼저 넣고 TextChecker 목록을 순서대로 읽으며 각 항목을
슬롯에 넣거나(최대 `maxSuggestionSlots − lexicon 수`) `seen`에 있어 건너뛴다. `seen`은
현재 단어와 lexicon 결과뿐이고 엔진이 현재 단어를 이미 제외하므로, 건너뜀은 lexicon 중복
(최대 `lexicon 수`)뿐이다. 따라서 읽는 항목 수는 `maxSuggestionSlots` 이하이고, TextChecker
목록의 앞 `maxSuggestionSlots`개만 같으면 결과가 동일하다. `completions`가 목록 앞에 오므로
`completions`만으로 `limit`이 차면 `guesses`는 결과에 기여할 수 없다.

### 효과의 한계

`completions`가 2개 미만인 입력(짧은 접두어, 오타, 한글)에서는 여전히 `guesses`가 호출된다.
생략 비율은 `TextCheckerGuesses` 구간의 발생 횟수 감소로 확인한다.

### 테스트

- `SuggestionControllerEngineFactory`로 호출 횟수와 전달된 `limit`을 기록하는 stub 엔진을
  주입해, lexicon이 2슬롯을 채우면 TextChecker가 호출되지 않는 기존 조기 반환과 `limit`이
  `maxSuggestionSlots`로 전달되는지를 검증한다.
- 엔진 단위: `limit: 1`로 호출하면 결과가 최대 1개다. `UITextChecker` 사전 내용에 의존하는
  기대값은 고정하지 않는다.

## 항목 1-b: TextChecker 비동기화 (실험 커밋)

### 위치와 격리

- 구현 순서의 마지막 커밋으로 둔다. `git revert` 한 번으로 빠지도록:
  - 건드리는 코드는 `SuggestionController`의 비동기 경로(큐, 세대 카운터, 완료 핸들러)와
    `TextCheckerPredictiveTextEngine`의 큐 한정 접근뿐이다. 항목 2·3·4·1-a가 만든
    인터페이스는 수정하지 않고 사용만 한다.
  - 1-b 전용 테스트를 같은 커밋에 넣는다.
  - 공유 라인 재포맷, 주석 정리 같은 부수 변경을 섞지 않는다.

### 설계

- `SuggestionController`에 전용 직렬 큐(`qos: .userInitiated`)와 요청 세대 카운터를 둔다.
  `performUpdateSuggestions`의 `.typing` 분기 진입마다 세대를 올린다. 세대는 큐 스레드도
  읽으므로 `OSAllocatedUnfairLock`으로 한정한다.
- 큐 블록은 조회 전에 세대를 확인해 이미 낡은 요청이면 조회 자체를 건너뛴다. 빠른 연속
  입력으로 요청이 쌓여도 마지막 요청 하나만 `completions`/`guesses`를 수행한다.
- `mergeSuggestions` 경로에서 lexicon 조회는 동기로 두고 TextChecker 조회만 큐로 보낸다.
- 완료 시 main으로 돌아와 세대가 최신이고 `lastSuggestionBaseText`가 그대로일 때만 병합하고
  delegate를 호출한다. 낡은 결과는 버린다. 세대 검사는 delegate 호출 전에 있어야 한다.
  후보 선택과 수식 action은 현재 `selectedText`·origin 계약을 그대로 쓴다.
- `UITextChecker` 인스턴스는 스레드 안전성이 문서화되지 않았으므로 그 큐에서만 접근한다.
  `UITextChecker.learnWord` 같은 클래스 메서드는 현재처럼 main에서 호출하고 이 분리를
  주석으로 남긴다.
- 결과 대기 중에는 새 lexicon 결과와 직전 `.typing` 모드의 `.textChecker` 후보를 병합한
  후보와 `currentWord`를 즉시 delegate에 전달하고, TextChecker 결과가 도착하면 그 결과로
  다시 병합해 전달한다. 기준선 측정에서 TextChecker 조회가 12~22 ms라 60 Hz 한 프레임
  (16.7 ms)을 넘으므로, 이어받지 않으면 빈 후보 중간 상태가 입력마다 렌더링된다.
- 이어받는 대상을 직전 `.typing` 모드의 `.textChecker` 후보로 한정하고 lexicon·n-gram·수식
  후보는 유지하지 않는다. n-gram 후보는 다음 단어 예측이라 입력 중 모드에서 탭되면 현재
  단어를 잘못 교체하고, lexicon 후보는 이번 입력의 조회 결과로 대치되어야
  `textReplacementPreviewSuggestionIndex`가 어긋나지 않는다.
- 조회 생략 판정(`lexicon`이 슬롯을 다 채웠는가)은 이어받은 후보를 제외한 `.lexicon` 출처
  후보 수로 한다. 이어받은 후보까지 세면 새 조회가 영영 실행되지 않는다.
- `clearSuggestions()`는 요청 세대를 올려 진행 중인 조회 결과를 무효화한다. 일시 중단,
  자동완성 해제, 언어 전환이 이 경로를 지난다.
- 테스트가 큐를 비울 수 있도록 `SuggestionController.init`에 `textCheckerQueue`를
  주입 가능한 파라미터(기본값: 전용 직렬 큐)로 둔다. 항목 4의 `saveQueue` 주입과 같은
  방식이다.

### 바뀌는 동작

- 후보 표시가 키 입력 프레임에서 분리되어 수 ms 뒤에 반영된다.
- 빠른 연속 입력에서 중간 상태의 후보 갱신이 생략될 수 있다.

### 유지/되돌림 기준

항목 1-a까지 반영한 상태에서 지원 하한에 가까운 기기(iPhone SE 2세대급 / iOS 16)로
Instruments os_signpost를 실행해 단어 입력 중 `TextCheckerSuggestions` 분포를 본다.

- p50 ≥ 3 ms 또는 p95 ≥ 8 ms: 유지한다. 60 Hz 프레임 예산 16.7 ms 안에 프록시 IPC와
  레이아웃도 들어가야 하므로 자동완성 하나가 절반을 쓰면 체감 지연이 된다.
- 한 자릿수 ms 이하: 1-b 커밋을 revert한다.
- 어느 쪽이든 측정값을 #123에 남긴다. 임계값은 제안이며 측정 결과를 보고 조정한다.

### 테스트

- stub 엔진으로 세대 검사(낡은 결과 폐기), 낡은 요청의 조회 생략, 결과 도착 전 직전
  `.typing` 모드의 `.textChecker` 후보 유지를 production 경로로 검증한다. n-gram·수식 후보를
  이어받지 않는다는 것도 함께 확인한다.
- 실기기 체감(후보 바 깜빡임, 키 애니메이션)은 수동 관찰 항목으로 기록한다.

## 커밋 계획

브랜치 `chore/#123-autocomplete-perf-signposts`에 계측 커밋 뒤로 이어서 남긴다. 각 커밋은
한 항목과 그 테스트만 담는다.

| 순서 | 항목 | 커밋 메시지 |
| --- | --- | --- |
| 1 | 2 | `refactor: #123 - lexicon 텍스트 대치 조회를 인덱스 기반으로 변경` |
| 2 | 3 | `refactor: #123 - unigram 후보 선택과 prune을 부분 선택·캐시로 변경` |
| 3 | 4 | `refactor: #123 - NGram 저장을 변경이 있을 때만 수행하도록 변경` |
| 4 | 1-a | `refactor: #123 - completions로 슬롯이 차면 guesses 호출 생략` |
| 5 | 1-b | `feat: #123 - TextChecker 조회를 백그라운드 큐로 분리 (실험)` |

1~4는 동작 변경이 없어 `refactor`, 5는 입력 흐름이 바뀌므로 `feat`로 구분한다.

## 검증

커밋마다 아래를 실행한다. 기준 시뮬레이터는 iPhone 13 mini / iOS 16.0이다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests
```

신규 suite는 위 목록에 추가한다. 마지막 커밋 뒤에는 `-only-testing` 없이 전체 테스트와
`HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme 빌드를 실행한다.

빌드 후 확인:

- `git status --short`에서 `.xcscheme`의 `RemotePath` 변경은 되돌린다.
- `SYKeyboard/Resources/Info.plist`가 diff에 나타나면 내용을 비교한다. 이 브랜치의 계측
  작업 중 빌드 스크립트가 `NSUserTrackingUsageDescription` 키를 제거한 사례가 있다.
  사용자 변경이 아니면 `git checkout -- SYKeyboard/Resources/Info.plist`로 복원한다.

실기기 수동 관찰(자동 테스트가 대체하지 않는 항목):

- 항목 1-b 커밋 뒤 Instruments os_signpost로 `TextCheckerSuggestions`·`TextCheckerGuesses`
  분포를 기록하고 유지/되돌림을 결정한다.
- 후보 바 깜빡임, 키 애니메이션 끊김, 빠른 연속 입력 시 후보 갱신 여부를 관찰한다.

## 범위 밖

- 자동완성 후보의 표시 방식(`SuggestionButtonView`의 두 줄·축소·중간 생략)은 변경하지 않는다.
- NGram 저장 형식, `maxKeys`·`maxEntriesPerKey` 기본값, `writePeriod`는 변경하지 않는다.
- `TextCheckerPredictiveTextEngine.learnedWords`의 무제한 성장은 이번 범위가 아니다.
