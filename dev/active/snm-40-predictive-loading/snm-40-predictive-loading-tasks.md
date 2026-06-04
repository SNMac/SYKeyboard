# SNM-40 Predictive Loading Tasks

Last Updated: 2026-06-04

## Checklist

- [x] Linear `SNM-40` 원문을 확인한다.
- [x] `dev/README.md`, `dev/templates/`, `dev/codex-skill-playbook.md`의 docs-and-infrastructure 규칙을 확인한다.
- [x] 자동완성 초기화 관련 주요 파일을 읽는다.
- [x] 구현 전 계획/context/tasks 문서를 만든다.
- [x] 기준 측정용 signpost 지점을 확정한다.
  - 완료 기준: launch, `loadView`, `viewDidLoad`, 설정 반영, lexicon request 시작/완료, `viewDidAppear`, 첫 `updateSuggestions()`, 첫 키 입력 처리 지점이 정리된다.
- [ ] 자동완성 ON/OFF, 텍스트 대치 ON/OFF 기준 측정을 수행한다.
  - 완료 기준: 한글/영문 키보드 각각의 첫 표시와 첫 입력 가능 시점이 기록된다.
- [x] `SuggestionController` 엔진 생성 타이밍을 측정한다.
  - 완료 기준: `LexiconPredictiveTextEngine`, `TextCheckerPredictiveTextEngine`, `NGramPredictiveTextEngine` 생성 비용이 분리된다.
- [ ] `requestSupplementaryLexicon()` 호출 시점과 완료 시점을 측정한다.
  - 완료 기준: 자동완성만 ON, 텍스트 대치만 ON, 둘 다 ON 조건별 비용과 동작 차이가 기록된다.
- [ ] `NGramPredictiveTextEngine` init과 background 로딩 비용을 측정한다.
  - 완료 기준: App Group container URL 접근, App Group UserDefaults 준비, plist load, UserDefaults migration 비용이 가능한 범위에서 분리된다.
- [x] 첫 표시 전 필수 초기화와 지연 가능한 초기화를 확정한다.
  - 완료 기준: 변경할 경로와 그대로 둘 경로가 plan/context에 기록된다.
- [x] `SuggestionController`에서 설정 저장과 엔진 생성 시점을 분리하는 테스트 또는 기존 테스트 영향 범위를 정한다.
  - 완료 기준: 자동완성 OFF, 텍스트 대치 ON/OFF 조합의 기대 상태가 테스트 케이스로 표현된다.
- [x] 필드별 자동완성 비허용/허용 전환 회귀 테스트를 추가한다.
  - 완료 기준: `isSuspended = true` 상태에서 엔진 준비가 발생하지 않고, `isSuspended = false` 해제 후 첫 후보 갱신에서 엔진이 준비되는 기대가 테스트로 고정된다.
- [x] 지연 초기화 구현을 적용한다.
  - 완료 기준: 키보드 첫 표시 경로에서 무거운 엔진 준비가 빠지고, 첫 표시 이후 또는 첫 후보 요청 시점에 중복 없이 준비된다.
- [x] `requestSupplementaryLexicon()` 측정 signpost를 Interval summary에서 볼 수 있게 정리한다.
  - 완료 기준: 기존 Begin/End event 대신 `RequestSupplementaryLexicon` interval로 lexicon 요청 duration을 측정할 수 있다.
- [x] n-gram 로딩 중 fallback을 명시적으로 유지하거나 보강한다.
  - 완료 기준: 로딩 전 후보 요청이 빈 후보 또는 현재 단어 표시로 안전하게 끝나고 crash/block이 없다.
- [x] 한글 키보드 후보 표시/선택/삭제 후 갱신을 확인한다.
  - 완료 기준: 한글 조합 중 현재 단어 표시, 후보 선택, 삭제 후 복구/갱신이 기존 기대와 맞는다.
- [x] 영어 키보드 후보 표시/선택/삭제 후 갱신을 확인한다.
  - 완료 기준: 영어 입력 중 후보 표시와 n-gram 후보 선택 후 갱신이 기존 기대와 맞는다.
- [x] 자동완성 OFF, 텍스트 대치 ON/OFF 조합을 확인한다.
  - 완료 기준: 자동완성 OFF에서는 suggestion bar가 숨겨지고, 텍스트 대치 ON이면 대치/복구 동작이 유지된다.
- [x] 관련 테스트를 실행하고 필요 시 갱신한다.
  - 완료 기준: `KeyboardSuggestionSelectionPolicyTests`, `KeyboardPresentationStatePolicyTests`, 한글 삭제/복구 관련 테스트가 통과하거나 변경 이유가 기록된다.
- [x] 전체 검증 명령을 실행한다.
  - 완료 기준: 아래 명령의 실제 결과가 context에 기록된다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

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

- [ ] 변경 후 측정을 기준 측정과 비교한다.
  - 완료 기준: 첫 표시 시간, 첫 입력 가능 시점, main thread 작업 감소 여부가 전/후로 정리된다.
- [ ] 영어 키보드 4조건 측정과 `RequestSupplementaryLexicon` interval 재측정을 기록한다.
  - 완료 기준: 한글 측정과 같은 조건으로 영어 측정값이 context에 기록되고, lexicon 요청 duration이 Interval summary에서 확인된다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [ ] 최종 응답에 변경 파일, 검증 결과, 남은 리스크를 요약한다.
