# SNM-40 Predictive Loading Context

Last Updated: 2026-06-04

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 키보드 extension lifecycle, 설정 반영, lexicon 로딩, 최초 `updateSuggestions()` 호출 경로.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: 자동완성/텍스트 대치 설정과 `LexiconPredictiveTextEngine`, `TextCheckerPredictiveTextEngine`, `NGramPredictiveTextEngine` 생성 책임.
- `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`: `BaseKeyboardViewController`가 의존하는 자동완성 서비스 계약.
- `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`: App Group 파일/UserDefaults 기반 n-gram 로딩, 마이그레이션, fallback 동작.
- `Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift`: `UILexicon` 후보와 텍스트 대치 후보 제공.
- `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift`: `UITextChecker` 기반 후보 제공.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`: suggestion bar 초기 표시 상태와 keyboard view 구성.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`: `updateSuggestions()` 실행/clear/no-op 결정.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`: suggestion bar 숨김과 undo/redo 표시 결정.
- `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`: 자동완성 후보 갱신 정책 테스트.
- `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`: suggestion bar 표시 정책 테스트.
- `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`: 한글 삭제/복구 후 suggestion UI 동기화 회귀 테스트.
- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`: `SuggestionController` 설정 저장과 엔진 생성 시점 분리 테스트.

## Facts Checked

- Linear `SNM-40` 원문을 확인했다. 요구사항은 측정, `SuggestionController` 엔진 생성 타이밍 분석, `requestSupplementaryLexicon()` 비용 확인, `NGramPredictiveTextEngine` 비용 확인, 지연 초기화/fallback 구현, 한글/영문 회귀 검증이다.
- 2026-06-03 변경 전 확인: `BaseKeyboardViewController.viewDidLoad()`는 `setupUI()`, `setNextKeyboardButton()` 등을 실행한 뒤 `suggestionController.isTextReplacementEnabled`와 `suggestionController.isPredictiveTextEnabled`를 설정했다.
- 2026-06-03 변경 전 확인: `BaseKeyboardViewController.viewDidLoad()`는 자동완성 또는 텍스트 대치가 켜져 있으면 `suggestionController.loadLexicon(from: self)`를 호출했다.
- 2026-06-03 변경 전 확인: `SuggestionController.isPredictiveTextEnabled`의 `didSet`은 ON 전환 시 `TextCheckerPredictiveTextEngine(language:)`와 `NGramPredictiveTextEngine(language:)`를 즉시 생성했다.
- 2026-06-03 변경 전 확인: `SuggestionController.updateLexiconEngine()`은 자동완성 또는 텍스트 대치 중 하나라도 켜져 있으면 `LexiconPredictiveTextEngine()`을 즉시 생성했다.
- 2026-06-03 변경 전 확인: `SuggestionController.loadLexicon(from:)`은 `lexiconEngine != nil`일 때 `Task { @MainActor in await inputViewController.requestSupplementaryLexicon() }`를 시작했다.
- `NGramPredictiveTextEngine.init(language:)`은 App Group container URL과 App Group `UserDefaults`를 init 중 준비한다.
- `NGramPredictiveTextEngine`의 파일 로딩과 UserDefaults 마이그레이션은 global queue에서 실행되고, 완료 후 main queue에서 store와 `isLoaded`를 반영한다.
- `NGramPredictiveTextEngine.suggestions(for:)`는 로딩 전 빈 배열을 반환한다.
- `NGramPredictiveTextEngine.addWord(_:)`와 `endSentence()`는 로딩 전 요청을 무시한다.
- `BaseKeyboardViewController.textDidChange(_:)`와 입력 후 hook은 `updateSuggestions()`를 호출한다.
- `KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(...)`이 자동완성 OFF, selected text, input buffer 상태에 따라 update/clear/no-op를 결정한다.
- 2026-06-04: `SuggestionController.isPredictiveTextEnabled = true`는 더 이상 `TextCheckerPredictiveTextEngine`, `NGramPredictiveTextEngine`을 즉시 생성하지 않는다.
- 2026-06-04: `SuggestionController.preparePredictiveEnginesIfNeeded()`는 자동완성 ON 상태에서 예측 엔진을 한 번만 생성한다.
- 2026-06-04: `SuggestionController.prepareLexiconEngineIfNeeded()`는 자동완성 또는 텍스트 대치 ON 상태에서 lexicon 엔진을 한 번만 생성한다.
- 2026-06-04: `BaseKeyboardViewController.viewDidLoad()`는 lexicon 요청을 시작하지 않고, `viewDidAppear(_:)` 이후 `startDeferredSuggestionPreparationIfNeeded()`에서 예측 엔진 준비와 lexicon 요청을 시작한다.
- 2026-06-04: `SuggestionController.loadLexicon(from:)`는 `requestSupplementaryLexicon()` 중복 요청과 이미 로드된 lexicon 재요청을 방지한다.
- 2026-06-04: 추가된 signpost 지점은 `KeyboardLoadView`, `KeyboardViewDidLoad`, `KeyboardViewWillAppear`, `KeyboardViewDidAppear`, `DeferredSuggestionPreparation`, `FirstTextInteraction`, `FirstUpdateSuggestions`, `PrepareLexiconEngine`, `PrepareTextCheckerEngine`, `PrepareNGramEngine`, `RequestSupplementaryLexicon`, `NGramInit`, `NGramBackgroundLoad`다.
- 2026-06-04: `RequestSupplementaryLexiconBegin/End` event는 Instruments Interval summary에서 duration 확인이 어렵기 때문에 `RequestSupplementaryLexicon` interval로 변경했다.

## Hypotheses

- 추정: `NGramPredictiveTextEngine`의 실제 파일 로딩은 background지만, init 안의 App Group container URL 접근과 App Group `UserDefaults` 생성이 첫 표시 전 main thread 비용에 포함될 수 있다.
- 추정: `requestSupplementaryLexicon()` 자체는 async API지만, `viewDidLoad()`에서 MainActor task를 즉시 시작하는 비용이나 시스템 lexicon 준비가 첫 표시 전후 scheduling에 영향을 줄 수 있다.
- 추정: `UITextChecker` 엔진 생성 비용은 작을 수 있으나, 자동완성 ON에서 매번 첫 launch 전에 생성되므로 계측 전에는 제외하면 안 된다.
- 추정: 자동완성만 ON인 경우 lexicon 로딩은 첫 후보 요청 전까지 지연해도 사용자 체감 리스크가 작고, 텍스트 대치 ON인 경우 첫 스페이스 대치 정확도 때문에 더 보수적으로 처리해야 한다.

## Decisions

- 구현 전 반드시 baseline 측정을 먼저 남긴다.
- 첫 구현 방향은 키보드 UI 표시와 입력 가능 경로를 우선하고, 자동완성 엔진 준비는 lazy/background bootstrap으로 분리하는 것이다.
- n-gram 로딩 중 fallback은 오류로 보지 않고 빈 후보 또는 현재 단어 표시를 정상 상태로 취급한다.
- 텍스트 대치 ON 동작은 자동완성 후보보다 우선순위가 높으므로, lexicon 지연 시 첫 대치가 누락되는지 별도 검증한다.
- 측정용 로그는 가능하면 `OSLog`/`os_signpost`를 사용하고, 릴리스 잔존 비용이 낮은 방식으로 둔다.
- 2026-06-04: 첫 구현은 `viewDidLoad()`에서 무거운 엔진 생성과 lexicon request를 제거하고, `viewDidAppear(_:)` 이후와 첫 후보 요청 시점의 lazy preparation으로 분리했다.
- 2026-06-04: `NGramPredictiveTextEngine`의 App Group container URL 준비 자체는 아직 init 안에 남겨두고, `NGramInit` signpost로 실제 비용을 먼저 측정하기로 했다.

## Open Questions

- 자동완성 ON + 텍스트 대치 ON에서 첫 스페이스 입력 전에 `UILexicon` 로딩이 끝나지 않으면 대치를 건너뛰어도 되는가, 아니면 첫 스페이스만큼은 lexicon 준비를 기다려야 하는가?
- n-gram 로딩 전 입력된 단어를 현재처럼 무시해도 되는가, 아니면 memory queue에 보관했다가 로딩 완료 후 기록해야 하는가?
- 목표 성능 기준을 어떤 값으로 둘 것인가? 예: 첫 표시 시간 n ms 이상 개선, main thread block n ms 이하, 체감 지연 제거.
- 실제 기준 측정 대상 기기와 OS는 무엇인가? 기본 문서 기준은 `iPhone 13 mini / iOS 16.0` simulator지만, extension launch 성능은 실기기 확인 가치가 높다.

## Verification Notes

- 2026-06-03: 아직 구현/측정은 수행하지 않았다. 이 문서는 SNM-40 구현 전 계획 문서다.
- 2026-06-03: 실행한 확인 명령:

```sh
git status --short
sed -n '1,240p' dev/README.md
rg --files dev/templates dev
sed -n '/docs-and-infrastructure/,+80p' dev/codex-skill-playbook.md
sed -n '1,260p' Modules/SYKeyboardCore/Domain/SuggestionController.swift
sed -n '1,280p' Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift
rg -n "updateSuggestions|suggestion|SuggestionController|isPredictiveTextEnabled|requestSupplementaryLexicon|NGramPredictive" Modules Keyboards SYKeyboardTests
```
- 2026-06-04: 일반 샌드박스에서 focused test 실행은 CoreSimulator/SwiftPM cache 권한 오류로 실패했다. 권한 있는 실행으로 재시도해 코드 실패와 환경 실패를 분리했다.
- 2026-06-04: RED 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

결과: 새 API가 없어 compile fail. 주요 오류는 `SuggestionControllerEngineFactory`, `NGramPredictiveTextProviding`, `engineFactory` initializer, `preparePredictiveEnginesIfNeeded()`, `prepareLexiconEngineIfNeeded()` 미정의.

- 2026-06-04: 구현 후 focused test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-04: 필드별 자동완성 비허용/허용 전환 회귀 테스트를 추가했다. `SuggestionController.isSuspended = true` 상태에서는 `updateSuggestions(for:)`가 예측/lexicon 엔진을 준비하지 않고, `isSuspended = false`로 풀린 뒤 첫 `updateSuggestions(for:)`에서 `TextChecker`, n-gram, lexicon 엔진을 준비하는 기대 동작을 고정한다.

- 2026-06-04: 필드 전환 회귀 테스트 추가 후 focused test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

결과: 일반 샌드박스에서는 CoreSimulator/SwiftPM cache 권한 오류로 실패했다. 권한 있는 실행에서 `TEST SUCCEEDED`.

- 2026-06-04: `RequestSupplementaryLexicon` interval 변경 후 focused test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-04: 최신 변경 후 전체 test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `TEST SUCCEEDED`.

- 2026-06-04: 최종 diff 검증:

```sh
git diff --check
git status --short
```

결과: `git diff --check` 통과. 현재 변경 파일은 자동완성 지연 준비 코드, `SuggestionControllerPreparationTests`, SNM-40 dev 문서다.

- 2026-06-04: 회귀 focused test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

결과: `TEST SUCCEEDED`.

- 2026-06-04: 전체 test 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `TEST SUCCEEDED`.

- 2026-06-04: extension build 결과:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `BUILD SUCCEEDED`.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `BUILD SUCCEEDED`.

- 2026-06-04: 남은 검증 gap: Instruments 또는 Console에서 signpost 기반 실제 기준/변경 후 시간 비교는 아직 수행하지 않았다.
- 2026-06-04: 사용자 제공 `os_signpost` 단일 샘플 확인:
  - `KeyboardLifecycle`: `KeyboardLoadView` 49.79 ms, `KeyboardViewDidLoad` 3.07 ms, `KeyboardViewWillAppear` 1.58 ms, `KeyboardViewDidAppear` 52.54 us, `DeferredSuggestionPreparation` 28.62 us.
  - `SuggestionController`: `PrepareTextCheckerEngine` 1.66 ms, `PrepareNGramEngine` 112.58 us, `PrepareLexiconEngine` 1.46 us.
  - `NGramPredictiveTextEngine`: `NGramInit` 69.54 us, `NGramBackgroundLoad` 69.42 ms.
  - `keyboardPerf.UI`: `keyboard.complete` 4회, 평균 450.58 ms, 최소 381.18 ms, 최대 519.97 ms.
  - 해석: 자동완성 엔진의 main thread 동기 준비 비용은 낮아졌고, n-gram의 큰 비용은 background interval로 분리되어 보인다. 다만 `DeferredSuggestionPreparation` 28.62 us가 개별 prepare interval 합보다 작으므로, 개별 prepare가 deferred block 내부에서 발생했는지는 Instruments 타임라인 순서로 추가 확인이 필요하다.
  - 조건, 키보드 종류, 반복 횟수가 아직 충분히 분리되지 않아 기준 측정 완료로 보지는 않는다.
- 2026-06-04: 사용자 제공 한글 키보드 4조건 `os_signpost` 측정 세트:
  - 자동완성 OFF / 텍스트 대치 OFF: `KeyboardLoadView` 50.69 ms, `KeyboardViewDidLoad` 7.85 ms, `KeyboardViewWillAppear` 1.54 ms, `KeyboardViewDidAppear` 24.29 us, `keyboard.complete` 평균 448.00 ms. `SuggestionController` prepare interval은 관측되지 않았다.
  - 자동완성 ON / 텍스트 대치 OFF: `KeyboardLoadView` 51.24 ms, `KeyboardViewDidLoad` 3.15 ms, `KeyboardViewWillAppear` 379.29 us, `KeyboardViewDidAppear` 66.38 us, `DeferredSuggestionPreparation` 52.33 us, `PrepareTextCheckerEngine` 1.45 ms, `PrepareNGramEngine` 126.21 us, `PrepareLexiconEngine` 1.83 us, `NGramInit` 81.75 us, `NGramBackgroundLoad` 64.05 ms, `keyboard.complete` 평균 651.96 ms.
  - 자동완성 OFF / 텍스트 대치 ON: `KeyboardLoadView` 41.38 ms, `KeyboardViewDidLoad` 2.16 ms, `KeyboardViewWillAppear` 558.83 us, `KeyboardViewDidAppear` 25.75 us, `DeferredSuggestionPreparation` 9.88 us, `PrepareLexiconEngine` 542 ns, `keyboard.complete` 평균 616.15 ms.
  - 자동완성 ON / 텍스트 대치 ON: `KeyboardLoadView` 50.02 ms, `KeyboardViewDidLoad` 2.77 ms, `KeyboardViewWillAppear` 345.88 us, `KeyboardViewDidAppear` 21.08 us, `DeferredSuggestionPreparation` 7.62 us, `PrepareTextCheckerEngine` 16.96 us, `PrepareNGramEngine` 109.04 us, `PrepareLexiconEngine` 292 ns, `NGramInit` 99.08 us, `NGramBackgroundLoad` 58.84 ms, `keyboard.complete` 평균 1.68 s.
  - 해석: 한글 키보드의 `KeyboardLoadView`는 41.38~51.24 ms, `KeyboardViewDidLoad`는 2.16~7.85 ms 범위로, 자동완성 ON 조건에서도 lifecycle 초기 구간에 큰 추가 비용은 보이지 않는다. `PrepareTextCheckerEngine`, `PrepareNGramEngine`, `PrepareLexiconEngine`은 모두 매우 작고, n-gram의 수십 ms 비용은 background interval로 잡힌다.
  - 주의: `keyboard.complete`는 조건별 count가 2/4/6/8로 다르고 system/host UI 비용이 섞이는 것으로 보이므로, 이 값만으로 자동완성 설정별 성능 차이를 단정하지 않는다. 측정 이후 `RequestSupplementaryLexiconBegin/End` event를 `RequestSupplementaryLexicon` interval로 변경했으므로 lexicon 요청 duration은 재측정이 필요하다.

## Linear Checklist Mapping

- main thread 작업 측정: `BaseKeyboardViewController.viewDidLoad()`, `BaseKeyboardViewController.viewDidAppear(_:)`, `SuggestionController` prepare API, `NGramPredictiveTextEngine.init`, `loadLexicon(from:)`
- `SuggestionController` 생성 타이밍 분석: `isPredictiveTextEnabled`, `isTextReplacementEnabled`, `preparePredictiveEnginesIfNeeded()`, `prepareLexiconEngineIfNeeded()`
- `requestSupplementaryLexicon()` 비용 확인: `SuggestionController.loadLexicon(from:)`
- n-gram 비용 확인: `NGramPredictiveTextEngine.init`, `loadFromFile()`, `migrateFromUserDefaults()`
- 첫 표시 이후로 미룰 후보: lexicon request, text checker/n-gram engine bootstrap, n-gram initial suggestions
- fallback 확인: n-gram loading 중 `suggestions(for:) == []`, 입력 중 현재 단어 표시 유지
