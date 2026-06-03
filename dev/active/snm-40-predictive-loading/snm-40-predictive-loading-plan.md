# SNM-40 Predictive Loading Plan

Last Updated: 2026-06-03

## Goal

- 자동완성 텍스트 ON 상태에서 한글/영문 키보드 extension의 첫 표시와 첫 입력 가능 시점이 늦어지는 초기화 경로를 측정하고, 자동완성 엔진의 무거운 작업을 첫 표시 이후로 미루거나 안전하게 background 처리한다.

## Issue

- Linear: `SNM-40` 자동완성 텍스트 활성화 시 키보드 초기 로딩 최적화
- GitHub attachment: `#47 자동완성 텍스트 활성화 시 키보드 초기 로딩 최적화`
- 상태: `Backlog`
- 라벨: `enhancement`

## Current State

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `viewDidLoad()`에서 UI 설정 직후 `suggestionController.isTextReplacementEnabled`, `suggestionController.isPredictiveTextEnabled`를 설정한다.
  - 자동완성 또는 텍스트 대치가 켜져 있으면 같은 `viewDidLoad()`에서 `suggestionController.loadLexicon(from:)`을 호출한다.
  - `textDidChange(_:)`, 버튼 입력 후, 후보 선택 후에 `updateSuggestions()`가 호출된다.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `isPredictiveTextEnabled = true`가 되면 `TextCheckerPredictiveTextEngine`, `NGramPredictiveTextEngine`을 즉시 생성한다.
  - `updateLexiconEngine()`은 자동완성 또는 텍스트 대치 중 하나라도 켜져 있으면 `LexiconPredictiveTextEngine`을 즉시 생성한다.
  - `loadLexicon(from:)`은 `Task { @MainActor in await inputViewController.requestSupplementaryLexicon() }`로 lexicon을 요청한다.
- `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
  - init 시 App Group 컨테이너 URL과 App Group `UserDefaults`를 준비한다.
  - 파일 로딩과 UserDefaults 마이그레이션은 `DispatchQueue.global(qos: .userInitiated)`에서 수행하고, 완료 후 main queue에서 store를 반영한다.
  - 로딩 전 `suggestions(for:)`는 빈 배열을 반환하고 `addWord(_:)`, `endSentence()`는 무시한다.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
  - `suggestionBarView`는 `UserDefaultsManager.shared.isPredictiveTextEnabled` 값을 기준으로 초기 hidden 상태를 정한다.

## Approach

1. 기준 측정을 먼저 만든다.
   - `os_signpost` 또는 Instruments로 keyboard extension launch, `loadView`, `viewDidLoad`, `viewWillAppear`, `viewDidAppear`, 첫 `updateSuggestions()`, 첫 버튼 입력 가능 시점을 나눈다.
   - 자동완성 ON/OFF, 텍스트 대치 ON/OFF, 한글/영문 키보드를 같은 기기와 같은 입력 앱에서 비교한다.
2. main thread 초기화 비용을 분해한다.
   - `BaseKeyboardViewController.viewDidLoad()`의 설정 적용, suggestion bar 표시 결정, lexicon 요청 시작 시점을 측정한다.
   - `SuggestionController.isPredictiveTextEnabled` 전환 시 `TextCheckerPredictiveTextEngine`, `NGramPredictiveTextEngine`, `LexiconPredictiveTextEngine` 생성 비용을 각각 측정한다.
   - `NGramPredictiveTextEngine.init(language:)` 안의 App Group 컨테이너 접근, App Group UserDefaults 생성, background 로딩 시작 전 동기 작업 비용을 측정한다.
3. 첫 표시 전 필수 작업과 지연 가능한 작업을 분리한다.
   - 필수: keyboard view 생성, 버튼 action/delegate 연결, suggestion bar 표시/숨김 상태, 입력 가능 상태.
   - 지연 후보: `requestSupplementaryLexicon()`, `UITextChecker` 엔진 준비, n-gram 파일/마이그레이션, 초기 n-gram 후보 계산.
4. 지연 초기화 설계를 적용한다.
   - 자동완성 ON이어도 `viewDidLoad()`에서는 suggestion bar와 입력 경로만 준비한다.
   - 첫 표시 이후 또는 첫 실제 후보 요청 시점에 엔진을 생성하는 lazy/bootstrap API를 `SuggestionController`에 둔다.
   - `requestSupplementaryLexicon()`은 텍스트 대치 ON일 때는 기능 요구가 더 높으므로 보수적으로 다루고, 자동완성만 ON인 경우에는 첫 표시 이후로 지연하는 방안을 우선 검토한다.
   - n-gram 로딩 중에는 빈 후보 또는 현재 단어 표시를 유지하고, 로딩 완료 후 다음 `updateSuggestions()`부터 후보를 제공한다.
5. 기존 동작을 보존한다.
   - 자동완성 OFF이면 suggestion bar 숨김과 자동완성 엔진 미생성 상태를 유지한다.
   - 텍스트 대치 ON/OFF와 자동완성 ON/OFF 조합에서 lexicon 사용 범위가 바뀌지 않게 한다.
   - 한글 조합 중 현재 단어 표시, 삭제 후 후보 갱신, 후보 선택 후 입력 버퍼 동기화는 기존 테스트를 기준으로 유지한다.

## Implementation Candidates

- `SuggestionController`
  - 설정값 저장과 엔진 생성 시점을 분리한다.
  - 예: `configure(isPredictiveTextEnabled:isTextReplacementEnabled:)`, `preparePredictiveEnginesIfNeeded()`, `prepareLexiconIfNeeded(from:)`.
  - 엔진 readiness 상태를 내부 enum이나 Bool로 관리해 중복 초기화를 막는다.
- `NGramPredictiveTextEngine`
  - init의 동기 작업 비용이 의미 있게 크면 파일 URL/UserDefaults 준비까지 background bootstrap으로 옮기는 별도 loader를 검토한다.
  - 로딩 완료 callback이나 상태 조회가 필요하면 `SuggestionController`가 UI를 직접 밀어내지 않고 다음 입력 이벤트에서 자연스럽게 반영하는 방향을 우선한다.
- `BaseKeyboardViewController`
  - `viewDidAppear(_:)` 또는 첫 run loop 이후 `Task { @MainActor }`에서 자동완성 엔진 준비를 시작하는 경로를 검토한다.
  - `updateSuggestions()`는 엔진 미준비 상태에서도 빠르게 no-op/fallback으로 끝나야 한다.

## Risks

- `requestSupplementaryLexicon()` 지연으로 텍스트 대치 첫 스페이스 입력이 기존보다 늦게 적용될 수 있다.
- n-gram 로딩 중 `addWord(_:)`가 무시되는 현재 동작을 유지하면 첫 입력 몇 개가 학습되지 않을 수 있다. 필요하면 로딩 전 기록 queue를 별도로 검토한다.
- `SuggestionController` 엔진 생성 시점을 바꾸면 자동완성 OFF, 텍스트 대치 ON 조합에서 `LexiconPredictiveTextEngine`이 누락될 수 있다.
- 한글 조합 중 `inputBuffer`와 suggestion bar 현재 단어 표시가 어긋나면 삭제/복구 회귀가 생길 수 있다.
- 키보드 extension은 메모리와 launch budget이 작으므로, 측정용 signpost/log가 릴리스 경로에 과도하게 남지 않게 해야 한다.

## Verification

- 기준/전후 측정:

```sh
# Instruments 또는 Console에서 OSLog signpost 확인
# 대상: HangeulKeyboard, EnglishKeyboard extension
# 조건: 자동완성 ON/OFF, 텍스트 대치 ON/OFF
```

- 자동 테스트:

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
  - 메시지 또는 메모 입력 필드에서 한글 키보드 최초 표시 지연과 첫 키 입력 가능 시점 확인
  - 영어 키보드 최초 표시 지연과 첫 키 입력 가능 시점 확인
  - 자동완성 후보 표시/선택/삭제 후 갱신 확인
  - 텍스트 대치 ON 상태에서 단축어 입력 후 스페이스 대치와 삭제 복구 확인
  - 자동완성 OFF 상태에서 suggestion bar 숨김과 입력 동작 확인

## Done Criteria

- 자동완성 ON 상태의 초기 로딩 기준 측정과 변경 후 측정이 문서화된다.
- 첫 표시 전 main thread에서 수행되는 자동완성 관련 작업이 확인된다.
- 첫 표시 이후로 미룬 작업이 기존 입력/후보/텍스트 대치 동작을 깨지 않는다.
- n-gram 로딩 중 fallback 동작이 명시적으로 동작하고 테스트 또는 수동 확인으로 검증된다.
- `KeyboardSuggestionSelectionPolicyTests` 등 영향 받는 테스트가 유지 또는 갱신된다.
- 한글/영문 키보드 extension build와 `SYKeyboard` scheme test 결과가 기록된다.
