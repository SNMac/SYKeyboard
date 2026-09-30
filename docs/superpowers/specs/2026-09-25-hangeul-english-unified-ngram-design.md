# 한영 통합 키보드 통합 NGram 설계

- 작성일: 2026-09-25
- 이슈: #157
- 브랜치: `feat/#157-unified-ngram`

## 목표

한영 통합 키보드가 한글·영어 NGram을 따로 두지 않고 통합 NGram 하나로 학습·예측한다.
"오늘 meeting 있어"처럼 섞어 쓰는 문맥과 'SY키보드'처럼 두 언어가 섞인 단어를 학습해,
언어를 바꾼 직후에도 이어지는 단어를 추천한다.

한영 키보드는 한글과 영어가 "따로 노는" 것이 아니라 하나로 통합된 느낌을 준다.
한/A 전환은 **자판 배열만 바꾸고**, 후보 바·입력 중인 단어·문맥 등 나머지는 그대로 둔다.

## 현재 구조

- NGram 파일은 언어별이다. `ngram_ko-KR.plist`, `ngram_en-US.plist`
  (App Group `Library/Application Support/`).
- 한글 키보드는 ko, 영어 키보드는 en을 쓰고, 한영 키보드는 모드 전환 때
  `updateSuggestionLanguage(to:)` → `SuggestionController.updateLanguage(to:)`로 두 엔진을 오간다.
  엔진별 문장 버퍼(`currentSentenceWords`)도 따로다.
- NGram 기록·조회는 `inputBuffer` 전체가 아니라 `currentLanguageInputBuffer`를 쓴다.
  `KeyboardLanguageSegmentTracker`가 마지막 언어 전환 이후 구간만 잘라 준다(#46).
  단독 키보드는 경계를 표시하지 않으므로 이 값이 `inputBuffer`와 같다.
- 그래서 지금 'SY' → 한글 전환 → '키보드' → 스페이스를 입력하면 NGram에는 `"키보드"`만 한글 쪽에
  기록되고, '오늘 ' → 영어 전환 직후에는 문맥이 비어 unigram만 뜬다.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 적용 범위 | 한영 키보드만 전용 통합 파일을 쓴다. 단독 키보드와 ko/en 파일은 그대로 둔다 |
| 기존 데이터 | 합치지 않는다. 한영 키보드는 빈 통합 파일로 시작한다 |
| 언어 전환 경계 | 없앤다. 한/A 전환은 자판만 바꾸고, NGram·단어 완성·자동 대치와 되돌리기·수식·후보 앞 공백 규칙이 모두 `inputBuffer` 전체를 본다. 전환 때 후보 바와 대치 이력을 비우지 않는다 |
| 한글 조합 | 한/A 전환 때 조합을 확정하는 지금 동작을 유지한다(iOS 기본 키보드와 같음) |
| 후보 순서 | 문맥(trigram/bigram) 후보는 빈도순 그대로(전환 직후 포함). unigram만 현재 모드 문자 종류 우선 |
| 삭제·초기화 | 길게 눌러 삭제는 통합 파일에서만. 설정의 NGram 초기화는 통합 파일도 지운다 |

단독 키보드를 계속 공유하도록 ko/en에도 동시 기록하는 안은 채택하지 않았다. 메모리 부담보다
단어 언어 분류 규칙, 세 파일의 삭제·초기화 동기화, 프로세스 간 덮어쓰기 증가가 비용이다.
필요해지면 이 설계 위에 동시 기록을 얹을 수 있다.

기존 ko/en 학습을 통합 파일로 옮기는 합치기(최초 1회, 또는 ko/en이 바뀔 때마다)는 하지 않는다.
최초 1회만 합치면 단독 키보드의 학습이 한 번은 반영되고 이후로는 반영되지 않아, 사용자가 "단독 키보드 학습이
한영 키보드에 반영된다"고 오해할 수 있다. 합치지 않으면 한영 키보드 추천이 처음부터 따로 쌓이므로 별도 안내
없이도 둘이 별개로 동작한다는 것이 드러난다. ko/en이 바뀔 때마다 합치는 안은 누적 빈도를 다시 더해 중복으로
쌓이므로 증분 파일이 필요하고 단독 키보드 저장 경로까지 바뀐다.

그 대가로 기존 한영 키보드 사용자는 업데이트 후 한영 키보드의 NGram 추천이 빈 상태에서 다시 쌓인다.
ko/en 파일은 그대로 남아 단독 키보드는 영향이 없다. 단어 완성(`UITextChecker` 학습 단어, `UILexicon`)은
NGram과 별개라 그대로 유지된다.

## 설계

### 1. NGram 식별자 분리 (`SuggestionController`)

- `init`에 `nGramLanguage: String? = nil`을 추가한다. `nil`이면 `language`를 쓴다.
- `nGramEngines` 캐시 키, `preparePredictiveEnginesIfNeeded()`의 엔진 생성과 로딩 완료 콜백의 guard,
  `releaseInactiveLanguageEngines()`의 NGram 필터는 `nGramLanguage` 기준으로 바꾼다.
  TextChecker 캐시는 지금처럼 `language` 기준이다.
- `updateLanguage(to:)`는 NGram 식별자가 고정이면(통합) **TextChecker 언어만 바꾼다.** NGram 엔진을
  저장·교체하지 않고, 후보·마지막 요청·수식 상태도 비우지 않는다. 문장 버퍼도 유지된다.
  언어별 NGram(`nGramLanguage == nil`)은 지금처럼 저장·세대 증가·상태 초기화를 한다.
- `BaseKeyboardViewController.init(language:)`에 `nGramLanguage:` 인자를 추가하고,
  `HangeulEnglishKeyboardViewController`만 `"ko-en"`을 넘긴다. 파일은 `ngram_ko-en.plist`다.

### 2. 통합 엔진 (`NGramPredictiveTextEngine`)

- 엔진 코드는 바꾸지 않고 식별자 `"ko-en"`으로 만든다. 파일은 `Library/Application Support/ngram_ko-en.plist`다.
  옛 위치 파일·레거시 `UserDefaults` 키도 식별자로 만들어지지만 존재한 적이 없으므로 읽을 것이 없다.
- convenience `init(language:)`에 `maxKeys`를 넘길 수 있게 하고, 통합 엔진은 10000을 쓴다. 두 언어가 한 파일을
  나눠 쓰므로 현재 한영 키보드가 엔진 2개(5000 + 5000)로 드는 용량·메모리 최대치와 같게 맞춘다.

### 3. 언어 전환 경계 제거 (`BaseKeyboardViewController`, `HangeulEnglishKeyboardViewController`)

#46은 한영 키보드에 언어 구간(`KeyboardLanguageSegmentTracker`)을 두어 자동완성이 마지막 전환 이후 글자만
보게 했다. 그래서 전환하면 현재 단어가 끊기고, 바에 남은 입력 중 후보를 누르면 잘못 대치되므로
(`'SY'` → 전환 → `SYSTEM` 선택 시 `"SYSYSTEM"`) 전환 때 후보를 비워야 했다. 이 경계를 없앤다.

- `HangeulEnglishKeyboardViewController.applyLanguageMode`에서 `clearSuggestionsForLanguageChange()`와
  `markCurrentInputBufferAsLanguageBoundary()` 호출을 뺀다. 조합 확정(`finishForLanguageChange`),
  입력 상호작용 중단, 버튼·자판 갱신, `updateSuggestionLanguage(to:)`는 그대로 둔다.
- `BaseKeyboardViewController`에서 `languageSegmentTracker`, `currentLanguageInputBuffer`,
  `clearSuggestionsForLanguageChange()`, `markCurrentInputBufferAsLanguageBoundary()`를 없애고,
  구간을 쓰던 모든 곳이 `inputBuffer`를 쓴다. 단독 키보드는 원래 두 값이 같았으므로 동작이 바뀌지 않는다.
- 경계가 없으므로 NGram 기록·조회·삭제 동기화, 0번 칸 확정, 단어 완성 선택은 develop의 원래 호출 형태
  (`recordUncommittedWords(from: inputBuffer)`, `recordWord(result.insertText)` 등)로 충분하다.
  구간과 전체 버퍼를 오가던 `KeyboardNGramContextPolicy`와 `SuggestionController`의 `nGramContext`
  인자·`lastNGramContext`는 필요 없어져 없앤다. `KeyboardLanguageSegmentTracker`도 없앤다.
- 결과
  - 전환 직후 후보 바가 그대로 남는다. '오늘 ' 뒤 `ok` 후보, 'SY' 입력 중 `SYSTEM` 후보가 전환 뒤에도 유효하다.
  - 'SY' → 전환 → '키보드'에서 현재 단어는 `SY키보드` 전체다. 스페이스·0번 칸 확정 모두 `SY키보드`로 기록한다.
  - 단어 완성 후보를 고르면 현재 단어 전체(`SY키보`)를 대치하므로 스마트 공백으로 단어가 쪼개지지 않는다.
  - NGram 후보 앞 공백 규칙이 전체 버퍼를 보므로 단어 중간에서 NGram 후보를 눌러도 붙지 않는다.
  - 자동 대치 직후 전환해도 백스페이스로 되돌릴 수 있다. 수식도 '3+' → 전환 → '4'를 `3+4`로 인식한다.
- 감수하는 것: 섞인 단어('SY키보')는 `UITextChecker`가 통째로 받아 단어 완성 후보가 거의 없다.
  #158(NGram 입력 중 완성)이 학습된 `SY키보드`로 보완한다. 전환 직후 남은 후보는 이전 언어 기준 순서로
  남았다가 다음 입력 때 새 언어 기준으로 바뀐다.

### 4. 후보 순서

- `NGramPredictiveTextEngine.suggestions(for:preferredScript:)`로 바꾸고 기존 호출은 `nil`을 넘긴다.
- `preferredScript`가 있으면 unigram 후보(문맥 없음, 남은 칸 보충 모두)만 안정 정렬한다.
  선호 문자 종류 → 나머지 순이며 각 그룹 안에서는 빈도순을 유지한다. trigram/bigram 후보는 건드리지 않는다.
- 문자 종류 판별은 새 policy `PredictiveTextScriptPolicy.script(of:)`가 한다.
  - 한글 음절·자모가 하나라도 있으면 `.hangeul` ('SY키보드'는 한글)
  - 아니고 라틴 문자가 있으면 `.latin`
  - 둘 다 없으면 `.other` (어느 쪽을 선호해도 뒤로 간다)
- `SuggestionController`는 `nGramLanguage != nil`(통합 NGram)일 때만 `language`에서 선호 문자 종류를 정해 넘긴다
  (`"ko-KR"` → `.hangeul`, `"en-US"` → `.latin`). 단독 키보드는 `nil`이다.
- 한/A 전환 때 후보 바가 NGram 후보를 보이는 중이면 `updateLanguage(to:)`가 마지막 요청값으로 다시 조회해
  새 언어 순서로 바꾼다(순서가 같으면 전달하지 않음). 입력 중 후보는 다시 계산하지 않는다.

### 5. 삭제·초기화

- 길게 눌러 삭제는 현재 NGram 엔진의 `removeWord(_:)`를 그대로 쓰므로 통합 파일에서만 지워진다.
- `PredictiveTextSettingsView.resetNGramData()`는 TextChecker용 `supportedLanguages`와 별도로
  NGram 목록 `["ko-KR", "en-US", "ko-en"]`을 돌며 초기화한다.

### 6. 메모리

통합 엔진 하나의 최악치는 현재 한영 키보드가 두 엔진을 캐시에 들고 있을 때와 같다.
ko/en 엔진은 한영 키보드에서 더 만들지 않는다.

### 6-1. 성능·메모리 측정 (설계 참고값)

scratchpad에서 돌린 버리는 측정이며 저장소에 코드는 남기지 않았다. Apple M3 Pro, macOS, `swiftc -O`,
엔진과 같은 `PropertyListDecoder`/`Encoder`(binary)와 `.atomic` 쓰기. 최악 크기 통합 파일(unigram·bigram·trigram
각 10000키, bigram·trigram 키당 24개, 약 2.4MB) 기준이다.

- 로드 약 585ms, 인코딩·쓰기 약 550ms. 언어별 파일(최악 약 1.2MB)은 로드 약 335ms, 쓰기 약 275ms다.
  지금 한영 키보드도 모드를 바꾸면 두 파일을 로드하므로 로드 총량은 같고, **저장 1회 비용은 약 두 배**가 된다
  (10단어마다·키보드가 사라질 때, 백그라운드).
- 로드 시 메모리 최대치 증가 약 25MB(`ru_maxrss`). 현재 한영 키보드가 두 엔진을 들고 있을 때와 같은 수준이다.
- 입력량 시뮬레이션(한글 80%/영어 20%, Zipf)에서 6개월 × 하루 300단어 사용자는 저장된 쌍이 최악의 약 9%,
  1년 × 하루 1,000단어는 약 21%였다. 실제 파일은 최악보다 5~10배 작다.
- iPhone은 1.5~3배로 추정한다(측정 아님).

`PropertyListSerialization`으로 바꾸는 안은 채택하지 않는다. Swift 딕셔너리에서 출발한 공정 비교에서
쓰기 약 195ms(현재 550ms), 읽기 약 293ms(현재 585ms)로 빠르고 파일도 양방향 호환됐지만, 최대 메모리 증가가
쓰기 +74MB(현재 +18MB), 읽기 +39MB(현재 +25MB)였다. Swift 문자열 약 24만 개를 `NSString`으로 새로 만들기
때문이며, 메모리 한도가 낮은 키보드 extension에서 10단어마다 저장할 때 종료될 위험이 속도 이득보다 크다.

### 6-2. 구현 뒤 production 엔진 측정 (2026-09-25)

실기기 체크리스트 16~18(로딩·메모리·스페이스 지연)을 시뮬레이터로 대신 잰 값이다. 버리는 측정이며 저장소에
코드를 남기지 않았다(scratchpad `bench/ZZNGramPerfMeasureTests.swift`).

- 대상: 실제 `NGramPredictiveTextEngine`(임시 파일 경로·`maxKeys` 지정 init). 새 한영은 `"ko-en"` 10000키 엔진 하나,
  이전 한영은 `"ko-KR"`·`"en-US"` 5000키 엔진 두 개를 모두 로딩한 상태.
- 환경: iPhone 13 mini / iOS 18.6 시뮬레이터(Apple M3 Pro), `SWIFT_OPTIMIZATION_LEVEL=-O` 빌드, 시나리오마다 새 테스트
  프로세스. 메모리는 `task_info(TASK_VM_INFO)`의 `phys_footprint`와 `ledger_phys_footprint_peak` 증가량이다.
- 데이터: 최악(6-1의 파일, 키마다 24개) / 많은 사용(6-1 시뮬레이션의 1년 × 하루 1,000단어 파일).
- 입력: 0.2초에 한 단어씩 150단어. 1/3은 새 단어이고 12단어마다 `endSentence()`. 스페이스 1회는 `addWord` +
  문맥 후보 조회 + 빈 입력 후보 조회다. 400단어를 쉬지 않고 넣으면 저장 스냅샷이 쌓여 peak가 부풀어
  (+111MB) 실제 사용과 달라지므로 속도를 맞췄다.

| 항목 | 새 한영 최악 | 이전 한영 최악 | 새 한영 많은 사용 | 이전 한영 많은 사용 |
| --- | --- | --- | --- | --- |
| 로딩(백그라운드) | 620~690ms | 한글 330~380ms + 영어 첫 전환 때 약 290ms | 170~185ms | 한글 110~125ms + 영어 약 70ms |
| 로딩 뒤 유지 메모리 | +21.3MB | +19.8MB | +8.4MB | +9.7MB |
| 로딩 중 peak | +33.9MB | +19.3MB | +17.3MB | +19.8MB |
| 입력·저장 중 peak | +41.8MB | +28.9MB | +17.3MB | +19.8MB |
| 스페이스 1회 중앙값 / p95 / 최대 | 4.5 / 16.1 / 17.6ms | 3.2 / 7.5 / 8.9ms | 5.5 / 10.6 / 11.3ms | 2.6 / 5.3 / 5.8ms |
| 16ms 초과 | 150회 중 9회 | 0회 | 0회 | 0회 |

- 스페이스 시간은 대부분 `addWord`다. 빈 입력 후보의 문자 종류 우선 정렬은 0.2~0.5ms(이전 0.03~0.1ms)로 작다.
  `addWord`가 느려진 원인은 가득 찬 저장소에 새 키가 들어올 때 키 전체를 합산·정렬하는 기존 `pruneKeys`의 대상이
  5000 → 10000개로 늘어난 것이다. 엔진에 임시 구간 계측을 넣어(커밋하지 않음, 같은 조건 300단어) 나눠 잰 결과
  `addWord` 시간의 약 98%가 `pruneKeys`(trigram 59~74%, bigram 24~40%)였다. trigram 키는 "직전 두 단어"라 새 키가
  거의 매번 생겨 대부분의 스페이스에서 돈다. 새 한영 최악에서 bigram·trigram 정리가 함께 돌 때 약 16~19ms가 된다.
  저장 스냅샷 뒤 첫 기록의 복사(copy-on-write)는 0.1~0.35ms로 원인이 아니다. 하루 1,000단어 × 1년 파일도 키가
  이미 10000개라 같은 비용이 든다(중앙값 4.7ms, p95 10.4ms).
- 이전 한영에서 한 언어만 쓰던 사용자는 엔진이 하나(최악 약 +10MB)였으므로 그 사용자 기준 증가 폭은 더 크다.
- 키보드 extension 프로세스의 절대 메모리는 재지 않았다(테스트 호스트 앱 안의 증가량이다).
- 결정: 구간 측정에서 1년 사용 수준도 같은 비용이 든다는 것이 드러나 이 브랜치에서 `pruneKeys`를 고쳤다.
  동작은 유지하고 `pruneUnigram`(#123)과 같이 1개만 넘는 정상 경로는 정렬 없이 총 빈도 최솟값 1개만 찾는다.
  같은 측정(최적화 빌드, 0.2초 간격 150단어)에서 스페이스 1회는 다음처럼 바뀌었다(중앙값 / p95 / 최대, 16ms 초과).

  | 시나리오 | 수정 전 | 수정 후 |
  | --- | --- | --- |
  | 새 한영 최악 | 4.5 / 16.1 / 17.6ms, 9회 | 1.9 / 12.3 / 15.3ms, 0회 |
  | 새 한영 많은 사용 | 5.5 / 10.6 / 11.3ms | 3.3 / 6.4 / 7.0ms |
  | 언어별 최악(이전 한영·단독 키보드) | 3.2 / 7.5 / 8.9ms | 2.2 / 6.0 / 6.8ms |
  | 언어별 많은 사용 | 2.6 / 5.3 / 5.8ms | 1.4 / 3.4 / 3.9ms |

  남은 p95는 새 문맥이 생길 때마다 키 전체의 빈도 합을 한 번씩 훑는 비용이다(bigram·trigram이 함께 돌 때).
  더 줄이려면 상한 초과분을 모았다가 한 번에 정리하는 방식이 필요한데, 상한을 잠시 넘게 되어 기존 동작이
  바뀌므로 실기기에서 체감될 때 따로 다룬다. 실기기는 1.5~3배로 추정한다(측정 아님).

## 테스트

모두 Swift Testing이며 production 진입점을 호출한다.

- `NGramPredictiveTextEngine`
  - `"ko-en"` 식별자와 `maxKeys: 10000`으로 만든 엔진이 ko/en 파일이 있어도 빈 상태로 시작하고,
    ko/en 파일 내용을 바꾸지 않는다
  - `preferredScript`별 unigram 순서, bigram 결과는 `preferredScript`와 무관하게 같다
- `PredictiveTextScriptPolicy`: 한글, 라틴, 섞인 단어('SY키보드'), 숫자·기호, 자모
- `SuggestionController` (엔진 팩토리 주입)
  - `nGramLanguage: "ko-en"`에서 `updateLanguage` 전후로 같은 NGram 엔진이 쓰이고 문장 버퍼 단어 수가 유지된다
  - "오늘" 기록 → 전환 → "meeting" 기록 뒤 `"오늘 "` 문맥에서 `"meeting"` 후보가 나온다
  - `nGramLanguage`가 없으면 지금처럼 언어별 엔진을 쓴다
  - `nGramLanguage: "ko-en"`에서 `updateLanguage`가 후보를 비우지 않는다(delegate 갱신 없음, 현재 후보 유지)
- `BaseKeyboardViewController`·`HangeulEnglishKeyboardViewController`는 주입할 수 없어 unit test 대신
  시뮬레이터에서 확인한다: 'SY' → 전환 → `SYSTEM` 선택, '오늘 ' → 전환 뒤 후보 유지,
  'SY' → 전환 → '키보드' 스페이스 뒤 `SY키보드` 학습, 전환 직후 백스페이스, 단독 키보드 변화 없음
- 기존 `NGramPredictiveTextEngine*`, `SuggestionController*`, `BaseKeyboardViewController` 테스트 전체 통과
- 4개 scheme 빌드, 전체 테스트(iPhone 13 mini / iOS 18.6)
- 실기기 입력 앱에서 한영 전환 직후 후보, 'SY키보드' 학습, 단독 키보드 후보 변화 없음 확인
- 실기기에서 `NGramBackgroundLoad` signpost 구간과 메모리로 통합 파일 로드 확인

## 범위 밖

- 단독 한글·영어 키보드의 동작
- 원본 `ngram_ko-KR`/`ngram_en-US` 파일 정리
- 기존 ko/en 학습을 통합 파일로 옮기기(합치기)
- 한영 키보드 학습 분리 안내 문구
- NGram 후보 앞 공백 삽입 규칙 개선(`"오늘meeting"` 붙임)
- 여러 키보드 프로세스가 같은 파일에 쓰는 기존 덮어쓰기 위험
- 단독 키보드 학습을 한영 키보드에 계속 반영하는 한 방향 공유(증분 파일)
- 입력 중 후보에 NGram 학습 단어 완성 추가(#158). 이번 변경의 NGram은 다음 단어 예측에만 쓰인다

## 유지하는 동작: 공백이 든 NGram 단어

**입력 중 후보 선택 경로(`handleInputBufferSuggestion`) 한 곳에 한정한다.** 이 경로는
`recordWord(result.insertText)`로 후보 문자열을 통째로 기록하고, `NGramPredictiveTextEngine.addWord(_:)`는
공백을 거르지 않는다. 그래서 여러 단어로 된 텍스트 대치(`UILexicon`, 예: "omw" → "On my way!"), 연락처,
`UITextChecker` guess(예: "alot" → "a lot")를 고르면 그 문자열이 한 단위로 학습되어 NGram 후보에 뜬다.
사용자에게 유용한 동작으로 보고 이 경로에서는 유지한다.

- 이 경로 밖에서는 공백이 든 단어를 만들지 않는다. 스페이스·리턴(`recordUncommittedWords`, `endSentence`),
  0번 칸 확정은 지금처럼 공백으로 나눈 단어를 기록하고, 이번에 추가하거나 바꾸는 코드도 공백 든 단어를
  새로 만드는 경로를 두지 않는다.
- 한영 키보드도 언어 구간이 없으므로 같은 경로가 단독 키보드와 똑같이 `insertText`를 기록한다.
- 이런 후보를 고른 뒤에는 문장 버퍼 단어 수가 `inputBuffer`의 공백 기준 단어 수와 달라, 다음 스페이스에서
  뒤 단어가 한 번 더 기록될 수 있다(코드 추정, 재현 안 함). 기존 동작이며 이번 범위에서 바꾸지 않는다.

## 설계 변경 이력

- 2026-09-25 (구현 뒤 사용자 결정): 처음 설계는 NGram만 언어 전환 경계를 넘고 단어 완성 등은 #46의 언어 구간을
  유지했다(`KeyboardNGramContextPolicy`, `nGramContext`). 시뮬레이터 확인에서 전환 직후 후보 바가 비고,
  단어 중간 전환 뒤 완성 선택 시 스마트 공백으로 단어가 쪼개져 기록이 어긋나는 문제가 드러났다.
  사용자는 "한/A 전환은 자판만 바뀌고 나머지는 그대로"를 원해 경계 자체를 없애기로 했다(3절).
  한글 조합 확정은 수정 범위와 회귀 위험이 커 지금처럼 유지한다.
- 2026-09-25 (실기기 확인 뒤): 전환 직후 문자 종류 순서가 "바로 바뀔 때와 안 바뀔 때가 있다"는 보고를 로그로
  확인했다. 전환 절차는 후보를 다시 계산하지 않고, iOS가 전환 뒤 `textWillChange`/`textDidChange`를 필드 포커스·탭
  직후에만 보내고 키보드로 입력한 뒤에는 보내지 않아 그 콜백을 탈 때만 순서가 바뀌었다. NGram 후보를 보이는
  중에만 전환 시 직접 다시 정렬하도록 했다(4절).
