# SNM-40 Predictive Loading Context

Last Updated: 2026-06-03

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

## Facts Checked

- Linear `SNM-40` 원문을 확인했다. 요구사항은 측정, `SuggestionController` 엔진 생성 타이밍 분석, `requestSupplementaryLexicon()` 비용 확인, `NGramPredictiveTextEngine` 비용 확인, 지연 초기화/fallback 구현, 한글/영문 회귀 검증이다.
- `BaseKeyboardViewController.viewDidLoad()`는 `setupUI()`, `setNextKeyboardButton()` 등을 실행한 뒤 `suggestionController.isTextReplacementEnabled`와 `suggestionController.isPredictiveTextEnabled`를 설정한다.
- `BaseKeyboardViewController.viewDidLoad()`는 자동완성 또는 텍스트 대치가 켜져 있으면 `suggestionController.loadLexicon(from: self)`를 호출한다.
- `SuggestionController.isPredictiveTextEnabled`의 `didSet`은 ON 전환 시 `TextCheckerPredictiveTextEngine(language:)`와 `NGramPredictiveTextEngine(language:)`를 즉시 생성한다.
- `SuggestionController.updateLexiconEngine()`은 자동완성 또는 텍스트 대치 중 하나라도 켜져 있으면 `LexiconPredictiveTextEngine()`을 즉시 생성한다.
- `SuggestionController.loadLexicon(from:)`은 `lexiconEngine != nil`일 때 `Task { @MainActor in await inputViewController.requestSupplementaryLexicon() }`를 시작한다.
- `NGramPredictiveTextEngine.init(language:)`은 App Group container URL과 App Group `UserDefaults`를 init 중 준비한다.
- `NGramPredictiveTextEngine`의 파일 로딩과 UserDefaults 마이그레이션은 global queue에서 실행되고, 완료 후 main queue에서 store와 `isLoaded`를 반영한다.
- `NGramPredictiveTextEngine.suggestions(for:)`는 로딩 전 빈 배열을 반환한다.
- `NGramPredictiveTextEngine.addWord(_:)`와 `endSentence()`는 로딩 전 요청을 무시한다.
- `BaseKeyboardViewController.textDidChange(_:)`와 입력 후 hook은 `updateSuggestions()`를 호출한다.
- `KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(...)`이 자동완성 OFF, selected text, input buffer 상태에 따라 update/clear/no-op를 결정한다.

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

## Linear Checklist Mapping

- main thread 작업 측정: `BaseKeyboardViewController.viewDidLoad()`, `SuggestionController` 설정 didSet, `NGramPredictiveTextEngine.init`, `loadLexicon(from:)`
- `SuggestionController` 생성 타이밍 분석: `isPredictiveTextEnabled`, `isTextReplacementEnabled`, `updateLexiconEngine()`
- `requestSupplementaryLexicon()` 비용 확인: `SuggestionController.loadLexicon(from:)`
- n-gram 비용 확인: `NGramPredictiveTextEngine.init`, `loadFromFile()`, `migrateFromUserDefaults()`
- 첫 표시 이후로 미룰 후보: lexicon request, text checker/n-gram engine bootstrap, n-gram initial suggestions
- fallback 확인: n-gram loading 중 `suggestions(for:) == []`, 입력 중 현재 단어 표시 유지
