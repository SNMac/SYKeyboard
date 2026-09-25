# 입력 중 NGram 단어 완성 설계

이슈: #158 ([Feat] 입력 중 자동완성 후보에 NGram 학습 단어 완성 추가). #157(한영 통합 NGram) 이후 작업이다.

## 목표

단어를 입력하는 도중에도 NGram에 학습된 단어를 완성 후보로 보여준다. #157로 학습되는 'SY키보드' 같은 섞인
단어도 'SY', 'SY키'를 입력하는 도중에 후보에 뜨게 한다.

## 현재 구조

- `SuggestionController.performUpdateSuggestions`는 `inputBuffer`가 비었거나 공백으로 끝나면 NGram 모드
  (다음 단어 예측), 아니면 입력 중 모드다.
- 입력 중 모드는 0번 칸이 현재 단어이고, 1번 칸부터 `UILexicon`(동기) → `UITextChecker`(비동기, 직렬 큐) 순으로
  최대 9칸(`maxSuggestions - 1`)을 채운다(`mergeSuggestions`). NGram은 입력 중 모드에서 조회하지 않는다.
- 섞인 단어(`"sy키보"`)는 `UITextChecker`가 통째로 받아 완성 후보가 없다(#157의 알려진 한계).
- 후보 선택(`handleInputBufferSuggestion`)은 `selectSuggestion`이 돌려준 `deleteCount`(공백 기준 마지막 단어 전체
  길이)만큼 지우고 후보를 넣는다. 스마트 공백은 지운 뒤 앞 글자가 비었거나 공백이면 붙지 않는다.

## 결정 사항

사용자 확인(2026-09-25)을 거쳤다.

1. **배치**: lexicon → **NGram 완성 최대 3개** → TextChecker. 전체 9칸 상한은 그대로다. lexicon이 없으면 보이는
   1·2번 칸이 NGram 완성이 되고, 자주 쓰는 접두어에서도 TextChecker 몫(오타 교정 포함)이 최소 6칸 남는다.
2. **bigram 우선**: 바로 앞 단어의 bigram 후보 중 접두어가 맞는 것을 빈도순으로 먼저, 남은 칸은 unigram 빈도순.
3. **적용 범위**: 단독 한글·영어 키보드와 한영 통합 키보드 모두. `SuggestionController` 공통 경로라 키보드별
   분기를 두지 않는다. 단독 키보드도 입력 중 후보 순서가 바뀌는 기존 동작 변경이다.
4. **문자 종류 우선 정렬(`preferredScript`)은 완성 후보에 적용하지 않는다.** 접두어가 이미 문자 종류를 정하고,
   한/A 전환 때 입력 중 후보는 다시 계산하지 않는다는 #157 원칙("자판만 바뀐다")을 그대로 지킨다.

## 설계

### 1. 접두어 규칙 (`PredictiveTextCompletionMatchPolicy`)

`Modules/SYKeyboardCore/Presentation/Utils/Policies/`의 순수 타입이다. `HangeulKeyboardCore`의 오토마타 분해 함수는
의존 방향이 반대(`HangeulKeyboardCore` → `SYKeyboardCore`)라 쓸 수 없어 호환 자모 분해를 따로 둔다.

**원칙: 보이던 목표 후보는 사용자가 그 단어를 계속 입력하는 동안 사라지지 않는다.** 세 자판 공통으로 이 원칙을
깨는 것은 "마지막 글자의 받침이 사실 다음 글자의 초성"인 경우다('키보' → 'ㄷ' → `"키볻"`, '달' → 'ㄱ' → `"닭"`).

- 대소문자를 무시한다(`"sy"` → `"SY키보드"`). 후보는 저장된 표기 그대로 보여주되, 입력이 대문자로 시작했고
  후보가 소문자로만 저장돼 있으면 첫 글자만 대문자로 올린다(문장 첫머리 `"Hel"` → `"Hello"`). 대문자가 섞인
  표기(`"SY키보드"`, `"iPhone"`)는 바꾸지 않는다.
- 입력 단어의 **마지막 글자만** 자모 단위로 비교한다. 앞 글자들은 확정됐으므로 문자열 접두어로 비교한다.
- 완성형 글자는 호환 자모 초성·중성·종성으로 나누고, **겹받침은 두 자음으로** 나눈다(`"닭"` → ㄷ ㅏ ㄹ ㄱ,
  `"앉"` → ㅇ ㅏ ㄴ ㅈ). 입력 끝의 호환 겹자음 낱자(ㄺ 등)도 같이 나눈다.
- **모음 합성(ㅘ = ㅗ+ㅏ, ㅐ = ㅏ+ㅣ)과 쌍자음은 나누지 않는다.** 합성 전 상태('고')에서는 목표('과자')가 아직
  보이지 않았으므로 원칙을 깨지 않고, 나누면 두벌식에서 '가'에 '개발'이 뜨는 잡음이 생긴다.
- 끝에 붙은 천지인 조합 중 모음(`ㆍ` U+318D, `ᆢ` U+11A2)은 무엇이 될지 모르므로 떼고 비교한다
  (`"킵ㆍ"` → `"킵"`).
- 입력 단어와 같은 단어(대소문자 무시)는 완성이 아니다. 0번 칸이 이미 보여준다.
- 성능: 후보마다 자모 배열을 만들면 한 글자 입력('다')에서 1만 개 전부를 분해한다. 다음 글자의 첫 자모만 먼저
  비교해 대부분을 배열 없이 거른다.

실제 처리기(`DubeolsikProcessor`·`NaratgeulProcessor`·`CheonjiinProcessor`)를 scratchpad에서 컴파일해 키 입력마다
판정한 결과다(T = 목표를 완성 후보로 봄, 마지막 칸은 입력이 목표와 같아 F).

| 자판 | 목표 | 키 입력별 상태 |
| --- | --- | --- |
| 두벌식 | 키보드 | ㅋ:T 키:T 킵:T 키보:T 키볻:T 키보드:F |
| 두벌식 | 달걀 | ㄷ:T 다:T 달:T 닭:T 달갸:T 달걀:F |
| 두벌식 | 안주 | ㅇ:T 아:T 안:T 앉:T 안주:F |
| 나랏글 | 키보드 | ㄱ:F ㅋ:T 키:T **킴:F** 킵:T 키보:T **키본:F** 키볻:T 키보드:F |
| 나랏글 | 달걀 | ㄴ:F ㄷ:T 다:T 달:T 닭:T **달가:F** 달갸:T 달걀:F |
| 나랏글 | 안주 | ㅇ:T 아:T 안:T **안ㅅ:F** 앉:T 안주:F |
| 천지인 | 키보드 | ㄱ:F ㅋ:T 키:T 킵:T 킵ㆍ:T 키보:T 키볻:T 키보드:F |
| 천지인 | 달걀 | ㄷ:T **디:F** 다:T **단:F** 달:T 닭:T **달기:F 달가:F** 달갸:T **달갼:F** 달걀:F |
| 천지인 | 안주 | ㅇ:T **이:F** 아:T 안:T 앉:T **안즈:F** 안주:F |

**알려진 한계**(굵은 F): 나랏글 획추가·쌍자음 전 상태('킴' → '킵'), 천지인 모음 조합 전 상태('디' → '다')와
자음 순환 전 상태('단' → '달')에서는 목표가 한 타 동안 빠진다. 자판 규칙을 모르는 `SuggestionController`에서는
풀지 않는다. 이 구간에서는 지금 `UITextChecker` 후보도 같은 방식으로 바뀐다.

### 2. 엔진 조회 (`NGramPredictiveTextEngine.completions(forTypedWord:previousWord:limit:)`)

- 로딩 전이거나 입력 단어가 비었거나 `limit <= 0`이면 빈 배열이다.
- `previousWord`가 있으면 `bigramStore[previousWord]`를 빈도순으로 훑어 맞는 것을 먼저 넣는다(키당 최대 24개).
- 남은 칸은 `unigramStore` 전체를 훑어 맞는 것 중 빈도 상위를 채운다. 순위는 기존 `insertTopUnigram`
  (상위 `maxPredictions`개 유지)을 재사용하고 `limit - 앞 결과 수`만큼 자른다. 동률 순서는 정의하지 않는다
  (`rankedUnigramCandidates`와 같다).
- 중복은 소문자 기준으로 거른다. 입력 단어 자체도 처음부터 제외한다.
- trigram은 보지 않는다.
- signpost 구간 `"NGramCompletions"`로 계측한다.
- `NGramPredictiveTextProviding` 프로토콜에 같은 시그니처를 추가한다.

### 3. 후보 병합 (`SuggestionController`)

- 입력 중 모드 1단계(동기)에서 lexicon 다음에 NGram 완성을 조회한다. NGram 저장소는 main에서만 바뀌므로
  TextChecker처럼 큐로 넘기지 않는다. 바로 앞 단어(공백 기준 끝에서 두 번째)를 `previousWord`로, 최대 3개
  (`maxNGramCompletions`)를 요청한다.
- `mergeSuggestions`는 lexicon → NGram 완성 → TextChecker 순으로 소문자 기준 중복을 거르며 9칸까지 채운다.
  2단계(TextChecker 도착) 재병합에도 1단계의 NGram 완성 결과를 그대로 쓴다.
- 직전 TextChecker 후보 이어받기 규칙은 그대로다. NGram 완성은 매 입력 동기로 다시 조회하므로 이어받지 않는다.
- TextChecker 조회를 건너뛰는 조건은 "lexicon과 NGram 완성이 9칸을 다 채웠을 때"로 넓힌다.
- 완성 후보의 출처는 기존 `.nGram`을 쓴다. 입력 중 모드에서 고르면 `selectSuggestion`이 현재 단어 전체를
  대치하고, 길게 눌러 삭제(`removableSuggestionText`)는 기존 `.nGram` 경로를 그대로 탄다. 선택 뒤
  `recordWord(result.insertText)` 기록도 기존 경로 그대로다.
- NGram 로딩 전에는 완성 후보가 없고, 로딩이 끝나면 기존 `performRefreshSuggestionsAfterNGramLoadIfNeeded`가
  마지막 요청으로 다시 계산해 채운다.
- 한/A 전환은 입력 중 후보를 다시 계산하지 않는다(#157 동작 유지).

### 4. 섞인 단어의 대치 범위

코드 변경 없이 현재 경로가 맞는지 테스트와 실제 입력 앱으로 확인한다.

- 'SY' → 한영 전환 → '키'에서 `inputBuffer`는 `"SY키"`다(#157에서 언어 구간 제거). `selectSuggestion`의 현재 단어는
  공백 기준 마지막 단어라 `"SY키"` 전체이고, `deleteCount` 3, 삽입 `"SY키보드"`다.
- 스마트 공백은 `inputBuffer.dropLast(3)`이 비었거나 공백으로 끝나므로 붙지 않는다. `"오늘 SY키"`도 같다.

### 5. 성능

scratchpad 측정(Apple M3 Pro, `swiftc -O`, 무작위 한글·영문 unigram 10000개, 한 글자·두 글자·섞인 단어 입력):
첫 자모 사전 거르기 적용 전 약 2.5ms/조회, 적용 후 약 0.9ms/조회. 남은 비용은 후보마다 `lowercased()` 할당이다.

- 구현 뒤 시뮬레이터(iPhone 13 mini / iOS 18.6, 최적화 빌드)에서 production 엔진으로 다시 재고, 실기기에서
  Instruments `os_signpost`의 `NGramCompletions` 구간과 입력 체감을 확인한다.
- 시뮬레이터 p95가 2ms를 넘거나 실기기에서 입력 지연이 체감되면 이번 범위에서 고치지 않고 사용자에게 알린다.
  후보 해법: 입력에 대소문자 구분 글자가 없으면(한글만) 후보 `lowercased()`를 건너뛴다. 한글 머리 글자와
  한글 첫 자모 비교는 대소문자 변환과 무관하기 때문이다.
- 구현 뒤 시뮬레이터 측정(2026-09-25, iPhone 13 mini / iOS 18.6, `SWIFT_OPTIMIZATION_LEVEL=-O`, 무작위 unigram
  10000개, 입력 "다"·"닭"·"가나"·"키볻"·"sy"·"sy키" 각 50회): 중앙값 0.84ms, p95 1.72ms, 최대 2.53ms.
  p95가 기준(2ms) 안이라 후보 해법은 적용하지 않았다. 실기기 값은 재지 않았다.

## 테스트

- `PredictiveTextCompletionMatchPolicyTests`: 대소문자, 받침→초성, 겹받침, 천지인 조합 중 모음, 완성이 아닌 경우.
- `HangeulCompletionMatchScenarioTests`: 세 처리기로 위 표의 키 입력을 실제로 넣어 상태별 판정을 고정한다.
- `NGramPredictiveTextEngineCompletionTests`: 실제 엔진으로 빈도순·limit, 조합 중 단어, 대소문자, 입력 단어 제외,
  bigram 우선, 로딩 전 빈 결과.
- `SuggestionControllerNGramCompletionTests`: 배치와 중복 제거, bigram 문맥 전달, 섞인 단어 대치 범위, 길게 눌러
  삭제 대상, 로딩 뒤 갱신, TextChecker 생략 조건, 한/A 전환 시 입력 중 후보 유지.
- 실제 입력 앱: 세 키보드에서 입력 중 완성 후보 표시·선택, 한영 전환을 사이에 둔 섞인 단어 대치, 입력 지연.

## 범위 밖

- 나랏글·천지인 중간 상태 보정(1절 알려진 한계), 모음 합성·쌍자음 분해.
- trigram 문맥 완성, 완성 후보의 문자 종류 우선 정렬.
- 접두어 색인 등 저장 구조 변경(5절 측정 결과로 필요해지면 별도 작업).
- NGram 모드(다음 단어 예측)와 수식 후보 동작.
- 공백이 든 NGram 단어 규칙(#157 설계 「유지하는 동작」)은 그대로다. 입력 중 완성으로 뜬 공백 든 단어를 고르면
  기존 후보 선택 경로가 그대로 기록한다. 새 코드는 공백 든 단어를 만드는 경로를 두지 않는다.

## 설계 변경 이력

- 2026-09-25 최종 리뷰 반영: 소문자로 학습한 단어가 문장 첫머리 대문자 입력(`"Hel"`)에 소문자 그대로(`"hello"`) 뜨고,
  같은 단어의 TextChecker 후보(`"Hello"`)는 중복으로 빠져 고르면 대문자가 사라졌다. 사용자 확인을 거쳐 1절의
  첫 글자 대문자 규칙(`PredictiveTextCompletionMatchPolicy.displayText(for:)`)을 추가했다.
