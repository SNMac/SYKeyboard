# Issue 67 Predictive Suggestion Findings Plan

Last Updated: 2026-06-16

## Goal

- GitHub Issue #67의 Track 4 `Predictive Text And Suggestion Bar` Open findings 5건을 검증 가능한 작은 변경으로 처리한다.

## Current State

- GitHub Issue: `https://github.com/SNMac/SYKeyboard/issues/67`
- Parent issue: `#57`
- Findings source: `dev/active/code-review-scope/code-review-scope-findings.md`
- 2026-06-16 선택 범위에서 처리한 findings:
  - `[P1]` 텍스트 대치 복구 이력이 다른 위치의 동일 문구를 단축어로 되돌릴 수 있음
  - `[P1]` 텍스트 대치 단축어가 긴 단어의 suffix와도 일치함
  - `[P2]` 비동기 lexicon 로딩 전 첫 텍스트 대치가 조용히 누락될 수 있음
  - `[P2]` n-gram 초기화가 background load/save와 경쟁해 삭제한 학습 데이터를 되살릴 수 있음
  - `[P3]` n-gram 로딩 전 확정된 단어가 학습에서 누락될 수 있음
- 남은 추가 사용자 보고:
  - 현재 글자를 입력한 뒤 커서를 이동하면 자동완성 제안이 초기 상태로 돌아간다.
  - 기대 동작은 커서 이동이 끝난 뒤 커서 앞 글자/단어에 맞게 자동완성 제안을 다시 계산하는 것이다.
  - 키보드 커서 드래그가 끝난 뒤 제안 재계산은 구현했다.
  - 커서를 이동하는 동안에는 텍스트필드에 아무것도 없는 상황의 초기 후보로 바뀌지 않고, 드래그 시작 직전 후보가 그대로 남아 있도록 구현했다.
- 관련 파일:
  - `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
  - `Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift`
  - `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`
  - `dev/active/code-review-scope/code-review-scope-findings.md`
  - `dev/active/snm-40-predictive-loading/`

## Approach

1. 텍스트 대치 P1 2건을 먼저 테스트로 고정한다.
   - `attemptTextReplacement(baseText:)`가 현재 입력 단어와 단축어의 정확한 일치만 허용하도록 한다.
   - 대치 복구는 직전 대치 또는 동일 입력 흐름의 대치에만 반응하도록 한다.
   - 커서/focus/context 변경 경로에서 복구 이력을 무효화하는 보수적 정책을 우선 검토한다.
2. lexicon 로딩 전 첫 텍스트 대치 누락 정책을 확정하고 구현한다.
   - 텍스트 대치가 켜진 경우 `attemptTextReplacement(baseText:)` 호출 시점에 lexicon 준비가 아직 끝나지 않았는지 명시적으로 구분한다.
   - 재평가가 가능한 구조인지 확인하고, 불가능하면 첫 대치 누락을 의도된 trade-off가 아닌 기능 실패로 보고 보완한다.
   - 테스트에서는 `UILexicon` 자체 지연을 직접 만들기 어려우므로 `SuggestionController`에 주입 가능한 상태 또는 작은 정책 함수를 추가하는 방향을 우선 검토한다.
3. n-gram reset/load/save 경쟁 조건을 저장소 상태 단위로 직렬화한다.
   - 큰 저장소 추상화보다 먼저 generation token 또는 단일 serial state queue로 현재 구조를 보강할 수 있는지 확인한다.
   - `resetAllData()` 이후 오래된 background load/save 결과가 메모리나 파일에 반영되지 않도록 한다.
4. n-gram 로딩 전 `addWord(_:)`/`endSentence()` 보존 정책을 구현한다.
   - 로딩 전 입력을 작은 in-memory queue로 보관하고, load 완료 후 순서대로 적용한다.
   - `endSentence()`도 queue에 포함해 문장 경계가 유지되게 한다.
   - reset 이후의 보류 queue는 폐기한다.
5. 커서 이동 후 자동완성 제안 재계산을 추가한다.
   - 키보드 primary 버튼 커서 드래그가 끝난 시점에 `textDocumentProxy.documentContextBeforeInput`을 기준으로 제안을 다시 계산한다.
   - 커서 드래그 중에는 후보를 재계산하거나 clear하지 않고, 드래그 시작 직전 후보를 유지한다.
   - 넓은 `textDidChange(_:)` fallback은 focus 전환, undo/redo, 외부 텍스트 변경에 끼는 부작용을 줄이기 위해 사용하지 않는다.
   - 현재 키보드 세션에서 직접 입력한 `inputBuffer`와 외부 문서 컨텍스트 기반 제안을 구분해, n-gram 문장 학습에는 외부 컨텍스트를 잘못 기록하지 않도록 한다.
   - selected text가 있거나 자동완성이 비활성/일시 중단된 필드에서는 기존 정책대로 clear/no-op을 유지한다.
6. findings 문서를 처리 결과와 검증 결과로 갱신한다.

## Risks

- 텍스트 대치 복구를 너무 강하게 제한하면 “대치 직후 삭제하면 단축어로 복구”하는 기존 편의 기능이 깨질 수 있다.
- `UIInputViewController.requestSupplementaryLexicon()`은 시스템 비동기 API라 자동 테스트에서 실제 지연/완료 순서를 완전히 재현하기 어렵다.
- n-gram 변경은 저장 파일, legacy UserDefaults migration, background queue, main queue 반영이 얽혀 있어 race 테스트를 먼저 만들지 않으면 회귀를 놓치기 쉽다.
- 키보드 extension의 입력 이벤트 내부에서 lexicon을 기다리도록 만들면 입력 지연이 생길 수 있으므로, blocking wait는 피한다.
- 커서 이동 후 문서 컨텍스트 기반 제안을 추가할 때, 사용자가 직접 입력하지 않은 텍스트를 n-gram 학습 입력으로 기록하면 학습 데이터가 오염될 수 있다.
- 커서 드래그 중 후보 유지를 구현할 때 일반 입력/삭제/selection 변경에서 필요한 후보 clear까지 막으면 오래된 후보가 남을 수 있으므로, “키보드 primary 커서 드래그 중” 상태로 범위를 좁혀야 한다.

## Verification

- 2026-06-16 선택 범위 focused 테스트 통과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

- 결과: `** TEST SUCCEEDED **`
- 일반 샌드박스의 `xcodebuild`는 Xcode/Simulator 캐시와 CoreSimulator 권한 문제로 실패할 수 있어 권한 있는 실행으로 검증했다.

- 집중 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

- 필요 시 새 테스트 파일을 추가한 뒤 해당 테스트만 먼저 실행한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- extension 빌드:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 수동 확인:
  - 텍스트 대치 단축어 입력 후 스페이스로 대치된다.
  - 대치 직후 삭제하면 원래 단축어로 복구된다.
  - 다른 위치의 동일 확장 문구 뒤에서 삭제해도 과거 단축어로 바뀌지 않는다.
  - 단축어 `id`가 있을 때 `id `는 대치되고 `paid `는 대치되지 않는다.
  - 키보드 표시 직후 단축어와 스페이스를 빠르게 입력해도 대치 누락 정책이 계획대로 동작한다.
  - 자동완성 학습 데이터 초기화 후 이전 후보가 되살아나지 않는다.
  - 글자를 입력한 뒤 같은 필드의 다른 위치로 커서를 옮기면 커서 앞 단어에 맞는 자동완성 제안이 표시된다.
  - 커서를 이동하는 동안에는 드래그 시작 직전 자동완성 후보가 유지되고, 손을 떼면 커서 앞 단어 기준 후보로 갱신된다.
  - 커서 이동 후 selected text가 있는 경우에는 관련 없는 이전 후보가 남지 않는다.

## Done Criteria

- Issue #67 체크리스트 5개 항목이 `Resolved`, `Invalid`, 또는 명시적 이유가 있는 `Deferred` 중 하나로 정리된다.
- 각 수정에는 실패를 재현하는 테스트 또는 최소한 해당 코드 경로를 검증하는 focused 테스트가 있다.
- `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 결과와 검증 결과가 반영된다.
- 관련 테스트와 한글/영문 extension 빌드 결과가 기록된다.
- `git status --short`로 변경 범위가 의도한 파일에 한정됨을 확인한다.
