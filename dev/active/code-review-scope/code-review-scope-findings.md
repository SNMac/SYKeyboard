# Code Review Scope Findings

Last Updated: 2026-06-13

## Purpose

- SYKeyboard 전체 코드리뷰를 트랙별로 진행하면서 나온 findings를 이 문서에 누적한다.
- 각 채팅의 final answer만 믿지 않고, 우선순위/상태/검증 결과를 한 곳에서 추적한다.
- 다음 트랙을 시작할 때는 이 문서를 읽고 이미 발견된 이슈와 handoff 항목을 확인한다.

## Priority Criteria

- `P1`: 즉시 수정해야 하는 문제. 빌드/테스트 실패, 사용자 입력 손상, 데이터 손실, 크래시, 보안/권한 위험, 명백한 기능 회귀처럼 다음 단계 진행을 막는 항목이다.
- `P2`: 다음 트랙이나 병합 전 수정해야 하는 문제. 회귀 가능성이 높은 설계 결함, 검증 누락, 모듈 계약 불일치, 문서와 실제 절차의 불일치처럼 방치하면 리뷰 결론을 흐릴 수 있는 항목이다.
- `P3`: 추적하면 좋은 개선 사항. PR 템플릿 보강, 문서 표현 정리, 유지보수 편의 개선처럼 즉시 기능 위험은 낮지만 후속 작업 품질을 높이는 항목이다.

## Status Values

- `Open`: 아직 처리하지 않은 finding.
- `In Progress`: 수정 또는 확인이 진행 중인 finding.
- `Resolved`: 수정/문서 반영/검증이 완료된 finding.
- `Deferred`: 지금 고치지 않기로 결정했고, 이유와 후속 위치가 기록된 finding.
- `Invalid`: 추가 확인 결과 finding이 아니라고 판단한 항목.

## Findings

### Track 0. Baseline Inventory And Review Rules

#### [P2][Resolved] Baseline inventory가 현재 브랜치/작업트리 상태를 반영하지 않음

- 위치: `dev/active/code-review-scope/code-review-scope-context.md`
- 영향: 이후 리뷰 findings나 baseline 문서가 #49 기능 작업과 같은 브랜치에 섞여 커밋/PR 범위가 흐려질 수 있다.
- 근거: 0번 리뷰 시점의 현재 브랜치는 `feat/#49-cursor-drag-acceleration`이고, `git status --short --branch`는 `?? dev/active/code-review-scope/`를 표시했다.
- 처리: `code-review-scope-context.md`에 현재 브랜치, HEAD, 직전 커밋, untracked 문서 상태, #49 변경 범위, 리뷰 findings 분리 원칙을 기록했다.
- 검증: `git status --short --branch`, `git branch -vv`, `git log --oneline --decorate -8`, `git diff 8494534d31699afbdc4d0f981573c19a74850149..HEAD --stat`

#### [P2][Resolved] Findings 우선순위 기준이 정의되어 있지 않음

- 위치: `dev/active/code-review-scope/code-review-scope-context.md`
- 영향: 여러 채팅에서 나뉘어 진행되는 리뷰의 P1/P2/P3 판단이 달라질 수 있다.
- 근거: 기존 문서에는 `[P1] 파일:라인` 형식만 있고 P1/P2/P3 의미가 없었다.
- 처리: `code-review-scope-context.md`와 이 문서에 `Priority Criteria`를 추가했다.
- 검증: `git diff --check`

#### [P3][Resolved] PR 템플릿에 검증 섹션이 없음

- 위치: `.github/pull_request_template.md`
- 영향: AGENTS와 dev 문서가 요구하는 빌드/테스트 결과, 샌드박스 실패, 권한 있는 재실행 결과가 PR 본문에서 누락될 수 있다.
- 근거: 기존 템플릿은 이슈, 작업 내용, 스크린샷만 요구했다.
- 처리: `.github/pull_request_template.md`에 `## ✅ 검증` 섹션과 Codex 샌드박스 재실행 기록 안내를 추가했다.
- 검증: `git diff --check`, `rg -n "[ \t]+$" .github/pull_request_template.md dev/active/code-review-scope`

### Track 1. Hangeul Input Domain Logic

#### [P2][Invalid] 나랏글 이중모음 결합이 입력 모음을 구분하지 않음

- 위치: `Modules/HangeulKeyboardCore/Domain/Processor/NaratgeulProcessor.swift:367`
- 영향: `ㅗ + ㅓ` 또는 `ㅜ + ㅏ` 같은 교차 입력도 각각 `ㅘ`, `ㅝ`로 조합될 수 있어 사용자가 의도하지 않은 글자가 만들어질 위험이 있다.
- 근거: `input()`은 입력이 `ㅏ` 또는 `ㅓ`이면 `combine이중모음(글자Input:composing:)`을 호출하지만, `combine이중모음`은 `글자Input` 값을 실제 분기 조건에 사용하지 않는다. 현재 `이중모음결합Table`은 마지막 모음이 `ㅗ`면 항상 `ㅘ`, `ㅜ`면 항상 `ㅝ`로 변환한다. 반면 테스트 입력 맵은 `ㅘ = ["ㅗ", "ㅏ"]`, `ㅝ = ["ㅜ", "ㅓ"]`만 기대 경로로 정의한다.
- 판단: 사용자 확인 결과 이 동작은 의도된 동작이다. 따라서 버그 finding이 아니며 수정 대상에서 제외한다.
- 검증: 사용자 확인. 추가 코드 검증 없음.

#### [P3][Open] 천지인 전체 문자 테스트가 삭제 경로를 검증하지 않음

- 위치: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift:277`
- 영향: 천지인은 비표준 모음과 `committedTail` 복원 삭제 로직이 별도로 있는데, 전체 11,172자 테스트는 생성만 검증해서 겹모음/겹받침 삭제 회귀가 넓게 노출되지 않는다.
- 근거: `CheonjiinProcessorTests.validateAllCharacters()`는 입력 후 `committed + composing`이 목표 글자인지만 확인한다. 두벌식 전체 테스트는 생성 후 삭제 루프까지 검증하고, 나랏글 전체 테스트도 예상 삭제 횟수만큼 삭제 후 잔여물을 확인한다.
- 제안: 천지인도 전체 문자 생성 뒤 삭제 루프를 추가하거나, 최소한 겹받침/복합모음/비표준 모음 중간상태를 포함한 삭제 매트릭스를 보강한다.
- 검증: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`

### Track 2. Common Keyboard Interaction Runtime

#### [P1][Open] 취소된 텍스트 팬 제스처가 정상 키 입력을 실행함

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift:89`
- 영향: 문자 또는 스페이스 버튼에서 짧은 드래그가 시스템이나 다른 제스처에 의해 취소되면, 사용자가 확정하지 않은 키가 입력될 수 있다.
- 근거: `.ended`, `.cancelled`, `.failed`가 같은 분기를 사용하고, 커서 이동이 활성화되지 않은 경우 `sendActions(for: .touchUpInside)`를 호출한다. 이 호출은 `BaseKeyboardButton.isProgrammaticCall`을 활성화하므로 `BaseKeyboardViewController.makeTextInputAction()`의 현재 눌린 버튼 검증을 우회하고 입력을 수행한다.
- 제안: `.ended`만 짧은 팬을 탭으로 확정하고, `.cancelled`/`.failed`는 입력 없이 상태만 정리한다. 제스처 상태별 입력 횟수를 검증하는 interaction test를 추가한다.
- 검증: 코드 경로 확인. 현재 테스트에는 `TextInteractionGestureController`의 `.cancelled`/`.failed` 상태 검증이 없다.

#### [P1][Open] `touchCancel`이 버튼 눌림 상태를 해제하지 않아 다음 터치에서 이전 키를 입력할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift:91`
- 영향: 터치가 중단되면 suggestion bar가 비활성 상태로 남거나 Shift가 계속 눌린 것으로 처리될 수 있다. 다음 버튼의 `touchDown`에서 취소된 이전 버튼의 `.touchUpInside`가 실행되어 의도하지 않은 키/리턴 입력도 발생할 수 있다.
- 근거: 버튼 해제 action은 `.touchUpInside`, `.touchUpOutside`에만 등록되어 있고 `.touchCancel`에는 등록되지 않는다. 이후 다른 버튼을 누르면 `currentPressedButton`에 남은 이전 버튼에 `sendActions(for: .touchUpInside)`를 호출하며, programmatic call은 입력 action의 현재 버튼 검증을 우회한다.
- 제안: `.touchCancel`에서도 일반 버튼의 `currentPressedButton`과 Shift의 `isShiftButtonPressed`를 정리한다. 취소 후 suggestion bar 활성 상태와 다음 버튼 입력 횟수를 검증하는 테스트를 추가한다.
- 검증: 코드 경로 확인. 현재 테스트에는 `ButtonStateController`의 UIControl event 상태 전이 검증이 없다.

#### [P2][Open] 취소된 키보드 전환 제스처가 전환 결과를 확정할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift:112`, `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift:193`
- 영향: 키보드 선택 또는 한 손 모드 드래그/길게 누르기가 중단되어도 키보드 종류나 한 손 모드가 바뀔 수 있다.
- 근거: 팬의 `.cancelled`/`.failed`가 `.ended`와 같은 완료 경로를 실행해 `.touchUpInside`와 `on...GestureEnded`를 호출한다. 완료 helper는 현재 위치에 따라 `changeKeyboard` 또는 `changeOneHandedMode` delegate를 호출한다. 취소된 long press도 동일하게 종료 helper를 호출한다.
- 제안: 취소/실패 시 overlay와 버튼 상태만 정리하고 delegate 변경은 `.ended`에서만 확정한다. overlay가 표시된 상태에서 각 제스처를 취소하는 테스트를 추가한다.
- 검증: 코드 경로 확인. 현재 테스트에는 `SwitchGestureController` 취소 상태 검증이 없다.

### Track 4. Predictive Text And Suggestion Bar

#### [P1][Invalid] selection 변경 후 이전 후보가 새 위치의 텍스트를 변경할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:283`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1487`
- 영향: 후보가 표시된 뒤 커서를 이동하거나 다른 단어를 선택하면, 이전 텍스트용 후보를 탭해 새 커서 위치의 문자를 삭제하거나 현재 선택 텍스트를 관련 없는 후보로 교체할 수 있다.
- 근거: `selectionDidChange(_:)`는 로그만 남기며 `inputBuffer`나 후보를 초기화/갱신하지 않는다. 이후 후보 선택은 현재 선택 텍스트 또는 기존 `inputBuffer`를 사용하지만, `SuggestionController.currentSuggestions`가 해당 텍스트로 생성됐는지 확인하지 않는다.
- 판단: 사용자 확인 결과 `selectionWillChange(_:)`와 `selectionDidChange(_:)`는 관찰되지 않지만, focus 중인 텍스트 필드 변경, 사용자의 텍스트 필드 탭, 커서 이동 시 `textWillChange(_:)`와 `textDidChange(_:)`가 호출된다. 현재 구현은 `textWillChange(_:)`에서 `resetInputBuffer()`를 호출하고 `textDidChange(_:)`에서 `updateSuggestions()`를 호출하므로 커서/필드 변경 후 이전 후보가 그대로 남는다는 finding의 전제가 성립하지 않는다.
- 검증: 사용자 수동 확인 및 `BaseKeyboardViewController.textWillChange(_:)`, `textDidChange(_:)` 코드 경로 확인.

#### [P1][Open] 텍스트 대치 복구 이력이 다른 위치의 동일 문구를 단축어로 되돌릴 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:432`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:283`
- 영향: 텍스트 대치를 수행한 뒤 커서를 다른 위치의 동일한 확장 문구 뒤로 이동하고 삭제하면, 해당 문구가 과거 단축어로 예기치 않게 변경될 수 있다.
- 근거: `attemptRestoreReplacement(...)`는 모든 과거 `replacementHistory`를 역순으로 탐색하고 현재 `inputBuffer` 또는 커서 앞 컨텍스트 suffix가 `documentText`와 같으면 복구한다. 이력에는 원래 대치 위치나 컨텍스트 anchor가 없고 selection/cursor 변경 시 이력을 비우지 않는다.
- 제안: 직전 대치의 위치/컨텍스트와 일치할 때만 복구하거나, 커서·selection·focus 변경 시 복구 이력을 무효화한다.
- 검증: 코드 경로 확인. 대치 직후 삭제 복구와 다른 위치의 동일 문구 삭제를 구분하는 테스트가 없다.

#### [P1][Open] 텍스트 대치 단축어가 긴 단어의 suffix와도 일치함

- 위치: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:396`
- 영향: 단축어가 일반 단어의 끝부분과 같으면 스페이스 입력 시 일반 단어 일부가 의도하지 않은 대치 문구로 변경될 수 있다.
- 근거: `attemptTextReplacement(baseText:)`는 `baseText.lowercased().hasSuffix(entry.userInput.lowercased())`만 확인하며 단축어 앞 단어 경계를 검사하지 않는다. 예를 들어 단축어 `id`는 `paid`의 suffix와도 일치한다.
- 제안: 전체 `baseText` suffix가 아니라 현재 입력 단어와 단축어가 정확히 일치하는지 검사하거나 단축어 앞의 단어 경계를 확인한다.
- 검증: 코드 경로 확인. 독립 단축어와 긴 단어 내부 suffix를 구분하는 텍스트 대치 테스트가 없다.

#### [P2][Open] 비동기 lexicon 로딩 전 첫 텍스트 대치가 조용히 누락될 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1002`, `Modules/SYKeyboardCore/Domain/SuggestionController.swift:391`
- 영향: 키보드가 표시된 직후 사용자가 단축어와 스페이스를 빠르게 입력하면 동일한 입력이어도 첫 텍스트 대치가 적용되지 않을 수 있다.
- 근거: lexicon 요청은 `viewDidAppear(_:)` 이후 비동기로 시작되고, `attemptTextReplacement(baseText:)`는 `lexiconEngine?.lexicon`이 아직 없으면 재시도나 보류 없이 `nil`을 반환한다. `snm-40-predictive-loading` 문서에도 첫 대치 누락 여부가 미해결 질문으로 남아 있다.
- 제안: 텍스트 대치가 켜진 경우 lexicon 준비 시점을 앞당기거나, 로딩 중 첫 대치 요청을 안전하게 재평가하는 정책을 명시한다.
- 검증: 코드 경로와 `dev/active/snm-40-predictive-loading/` 확인. lexicon 응답을 지연시킨 상태의 첫 스페이스 대치 테스트가 없다.

#### [P2][Open] n-gram 초기화가 background load/save와 경쟁해 삭제한 학습 데이터를 되살릴 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:159`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:319`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:343`
- 영향: 사용자가 자동완성 학습 데이터를 초기화해도 진행 중이던 load 또는 save가 이후 완료되면 메모리나 파일에 이전 데이터가 다시 나타날 수 있다.
- 근거: init의 background load, `saveQueue`의 파일 쓰기, `resetAllData()`의 메모리 초기화/파일 삭제가 하나의 직렬화된 상태나 generation 검증 없이 독립적으로 실행된다.
- 제안: load/save/reset을 하나의 저장소 직렬 큐 또는 generation token으로 조정하고, 초기화를 위해 로딩 엔진을 새로 만드는 대신 저장소 수준 reset API를 제공한다.
- 검증: 코드 경로 확인. load/save를 보류한 상태에서 reset 후 보류 작업을 완료하는 경쟁 조건 테스트가 없다.

#### [P3][Open] n-gram 로딩 전 확정된 단어가 학습에서 누락될 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:263`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:274`
- 영향: 키보드 표시 직후 로딩이 끝나기 전에 스페이스나 리턴으로 확정된 초기 단어가 n-gram 학습에 포함되지 않을 수 있다.
- 근거: `addWord(_:)`와 `endSentence()`는 `isLoaded == false`이면 요청을 버린다. `snm-40-predictive-loading` 문서도 로딩 전 기록 queue 필요 여부를 미해결 질문으로 남겼다.
- 제안: 로딩 전 기록을 메모리 queue에 보관해 로딩 완료 후 순서대로 적용하거나, 누락을 의도된 trade-off로 명시하고 검증한다.
- 검증: 코드 경로와 `dev/active/snm-40-predictive-loading/` 확인. 로딩 전 `addWord`/`endSentence` 호출 보존 여부 테스트가 없다.

### Track 5. Settings And UserDefaults Contract

#### [P1][Open] 최초 설치에서 자동 대문자 기본값이 설정 화면과 키보드 런타임에서 다르게 해석됨

- 위치: `Modules/EnglishKeyboardCore/Storage/UserDefaultsManager+Extension.swift:15`, `Modules/EnglishKeyboardCore/Storage/DefaultValues+Extension.swift:12`, `SYKeyboard/Presentation/KeyboardSettings/InputSettingsView.swift:22`
- 영향: 사용자가 자동 대문자 설정을 변경한 적 없는 최초 설치 상태에서 설정 화면은 활성화로 표시하지만, 영어 키보드는 자동 대문자를 비활성화하고 앱 초기 Analytics도 비활성화로 기록한다.
- 근거: 선언된 기본값과 `@AppStorage` 기본값은 `true`지만, 영어 키보드 런타임 getter는 키가 없으면 `false`를 반환하는 `storage.bool(forKey:)`를 사용한다. `EnglishKeyboardCoreViewController.updateShiftButton()`은 이 getter를 직접 읽는다.
- 제안: `UserDefaultsWrapper`를 사용하거나 `storage.object(forKey:) as? Bool ?? DefaultValues.isAutoCapitalizationEnabled`로 absent-key fallback을 일치시킨다.
- 검증: 코드 경로 확인. 빈 App Group 저장소에서 설정 화면과 manager getter가 모두 `true`를 반환하는 계약 테스트가 없다.

#### [P2][Open] 키보드 컨트롤러가 재사용되면 변경된 설정 일부가 다시 반영되지 않음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:207`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:226`
- 영향: 기존 키보드 컨트롤러가 사라졌다 다시 표시되는 동안 앱에서 설정을 바꾸면, 마침표 단축키, 커서 드래그, 길게 누르기, 숫자 키패드/한 손 모드 전환 제스처, 자동완성/텍스트 대치 상태가 이전 값으로 남을 수 있다.
- 근거: 설정 화면은 App Group `@AppStorage`에 즉시 값을 쓰지만, 런타임은 조건부 action/gesture와 suggestion 상태를 `viewDidLoad()`에서만 구성한다. `viewWillAppear()`는 키보드 높이와 햅틱 준비만 갱신하며 설정을 다시 적용하지 않는다.
- 제안: 재진입 시 호출할 idempotent 설정 갱신 경로를 정의하고, 조건부 action/gesture 추가·제거 및 suggestion 상태를 현재 저장값과 동기화한다.
- 검증: 동일 controller 인스턴스를 재사용하면서 disappear/appear 사이 설정값을 변경하는 lifecycle 테스트가 없다.

#### [P3][Open] 앱 전용 온보딩 manager getter가 선언된 기본값과 다름

- 위치: `SYKeyboard/Storage/UserDefaultsManager+Extension.swift:13`, `SYKeyboard/Storage/DefaultValues+Extension.swift:12`
- 영향: 현재 `ContentView`는 올바른 `@AppStorage` 기본값을 사용하므로 즉시 사용자 영향은 없지만, 향후 manager getter를 직접 사용하는 코드는 최초 실행에서 온보딩 기본값을 `true`가 아닌 `false`로 해석한다.
- 근거: 선언된 기본값은 `true`지만 getter는 키가 없으면 `false`를 반환하는 `storage.bool(forKey:)`를 사용한다.
- 제안: 공통 default-aware wrapper 또는 명시적인 absent-key fallback으로 getter 계약을 일치시킨다.
- 검증: 빈 저장소의 앱 전용 기본값을 검증하는 테스트가 없다.

## Handoff

- Track 2부터 각 리뷰 채팅의 findings는 이 문서의 `## Findings` 아래에 트랙별 섹션으로 추가한다.
- 각 finding은 우선순위, 상태, 위치, 영향, 근거, 제안 또는 처리, 검증을 포함한다.
- 다른 트랙으로 넘길 내용은 해당 트랙 섹션 끝에 `Handoff` 항목으로 남긴다.
- Track 1의 나랏글 이중모음 교차 입력 동작은 사용자 확인으로 의도된 동작으로 정리했다.
- Track 2의 세 finding은 모두 제스처/UIControl 취소 상태 전이와 관련되어 있어 함께 수정하고 interaction test로 검증하는 편이 적절하다.
- Track 4의 selection stale 후보 finding은 실제 `textWillChange(_:)`/`textDidChange(_:)` 호출 동작 확인으로 `Invalid` 처리했다. selection 콜백 대신 text change 콜백을 외부 문서 컨텍스트 동기화 기준으로 본다.
- Track 4의 텍스트 대치 복구 이력 문제는 `textWillChange(_:)`에서 `inputBuffer`와 n-gram 문맥은 초기화하지만 replacement history는 유지한다는 점을 고려해 후속 검증한다.
- Track 4의 lexicon/n-gram 로딩 findings는 `dev/active/snm-40-predictive-loading/`의 미해결 질문과 연결해 후속 처리한다.
- Track 5에서 메인 앱의 학습 데이터 초기화 화면이 모든 데이터 삭제를 약속하지만 임시 엔진을 생성해 `resetAllData()`를 호출한다는 점을 확인했다. 기존 Track 4의 n-gram reset 경쟁 조건을 해결할 때 설정 화면과 활성 extension 엔진 사이의 저장소 수준 reset 계약을 함께 정의해야 한다.
- Track 5의 키보드 재진입 설정 갱신 finding은 공통 런타임과 extension lifecycle에 걸쳐 있으므로 Track 2/6 후속 수정에서 함께 다룬다.
- Track 5 범위에는 UserDefaults 키/기본값/type parity, absent-key fallback, 재진입 설정 갱신을 직접 검증하는 테스트가 없다.
