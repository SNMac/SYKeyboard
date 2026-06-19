# Code Review Scope Findings

Last Updated: 2026-06-19

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

#### [P3][Resolved] 천지인 전체 문자 테스트가 삭제 경로를 검증하지 않음

- 위치: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift:277`
- 영향: 천지인은 비표준 모음과 `committedTail` 복원 삭제 로직이 별도로 있는데, 전체 11,172자 테스트는 생성만 검증해서 겹모음/겹받침 삭제 회귀가 넓게 노출되지 않는다.
- 근거: `CheonjiinProcessorTests.validateAllCharacters()`는 입력 후 `committed + composing`이 목표 글자인지만 확인한다. 두벌식 전체 테스트는 생성 후 삭제 루프까지 검증하고, 나랏글 전체 테스트도 예상 삭제 횟수만큼 삭제 후 잔여물을 확인한다.
- 제안: 천지인도 전체 문자 생성 뒤 삭제 루프를 추가하거나, 최소한 겹받침/복합모음/비표준 모음 중간상태를 포함한 삭제 매트릭스를 보강한다.
- 처리: 완성형 글자의 중성/종성 구조 기반 예상 삭제 횟수를 계산해 11,172자 생성 후 전체 삭제를 검증하도록 보강했다. 완성형 전체 삭제로 검증할 수 없는 `ㆍ`/`ᆢ` composing 삭제와 `committedTail` 복원, `consumedCommittedCount`, `isProtected` 계약은 별도 매트릭스로 추가했다. production 코드는 변경하지 않았다.
- 검증:
  - 일반 샌드박스 targeted 테스트는 CoreSimulator/Xcode 캐시 권한 오류로 실패했다.
  - 권한 있는 환경의 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CheonjiinProcessorTests`는 정상 코드에서 `TEST SUCCEEDED`를 확인했다.
  - 비표준 모음 삭제가 진행되지 않도록 임시 mutation한 상태에서 새 `test비표준모음_Composing삭제()`가 실패함을 확인한 뒤 production 코드를 원복했다.
  - production 원복 후 같은 천지인 targeted 테스트를 fresh 재실행해 `TEST SUCCEEDED`를 확인했다.
  - 권한 있는 환경의 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` 전체 테스트도 `TEST SUCCEEDED`를 확인했다.

### Track 2. Common Keyboard Interaction Runtime

#### [P1][Resolved] 취소된 텍스트 팬 제스처가 정상 키 입력을 실행함

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift:89`
- 영향: 문자 또는 스페이스 버튼에서 짧은 드래그가 시스템이나 다른 제스처에 의해 취소되면, 사용자가 확정하지 않은 키가 입력될 수 있다.
- 근거: `.ended`, `.cancelled`, `.failed`가 같은 분기를 사용하고, 커서 이동이 활성화되지 않은 경우 `sendActions(for: .touchUpInside)`를 호출한다. 이 호출은 `BaseKeyboardButton.isProgrammaticCall`을 활성화하므로 `BaseKeyboardViewController.makeTextInputAction()`의 현재 눌린 버튼 검증을 우회하고 입력을 수행한다.
- 제안: `.ended`만 짧은 팬을 탭으로 확정하고, `.cancelled`/`.failed`는 입력 없이 상태만 정리한다. 제스처 상태별 입력 횟수를 검증하는 interaction test를 추가한다.
- 처리: `.ended`만 짧은 팬의 `.touchUpInside`를 전송하고, `.cancelled`/`.failed`는 해당 gesture button이 현재 눌린 버튼일 때만 해제하도록 변경했다. 삭제 pan의 stop callback과 UI 상호작용 복구는 terminal 상태와 무관하게 유지했다.
- 검증:
  - `TextInteractionGestureControllerTests`에서 정상 종료 입력, 취소/실패 입력 차단, 삭제 pan stop callback, 다른 현재 버튼 보존을 확인했다.
  - 권한 있는 환경의 집중 interaction 테스트와 전체 `SYKeyboard` 테스트에서 `TEST SUCCEEDED`를 확인했다.

#### [P1][Resolved] `touchCancel`이 버튼 눌림 상태를 해제하지 않아 다음 터치에서 이전 키를 입력할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift:91`
- 영향: 터치가 중단되면 suggestion bar가 비활성 상태로 남거나 Shift가 계속 눌린 것으로 처리될 수 있다. 다음 버튼의 `touchDown`에서 취소된 이전 버튼의 `.touchUpInside`가 실행되어 의도하지 않은 키/리턴 입력도 발생할 수 있다.
- 근거: 버튼 해제 action은 `.touchUpInside`, `.touchUpOutside`에만 등록되어 있고 `.touchCancel`에는 등록되지 않는다. 이후 다른 버튼을 누르면 `currentPressedButton`에 남은 이전 버튼에 `sendActions(for: .touchUpInside)`를 호출하며, programmatic call은 입력 action의 현재 버튼 검증을 우회한다.
- 제안: `.touchCancel`에서도 일반 버튼의 `currentPressedButton`과 Shift의 `isShiftButtonPressed`를 정리한다. 취소 후 suggestion bar 활성 상태와 다음 버튼 입력 횟수를 검증하는 테스트를 추가한다.
- 처리: 일반 버튼과 Shift 버튼에 `.touchCancel` 전용 action을 추가했다. 일반 터치 취소는 상태를 해제하되, 활성 recognizer가 터치 소유권을 얻으며 발생시킨 `.touchCancel`은 `isGesturing`으로 구분해 유지하고 terminal gesture handler가 정리하도록 했다.
- 검증:
  - `ButtonStateControllerTests`에서 일반 버튼 취소 후 눌림/suggestion bar 복구와 다음 버튼이 이전 입력을 실행하지 않는지 확인했다.
  - Shift 취소 후 `isShiftButtonPressed == false`를 확인했다.
  - 첫 구현 후 실기기에서 길게 누르기 반복 입력과 커서 드래그가 즉시 종료되는 회귀를 확인했다.
  - 활성 제스처 중 일반 버튼/Shift `.touchCancel`이 상태를 유지하는 테스트가 첫 구현에서 실패함을 확인하고 조건부 해제 로직을 추가했다.
  - 조건부 해제 수정 후 권한 있는 환경의 집중 interaction 테스트에서 `TEST SUCCEEDED`를 확인했다.
  - 사용자 실기기 확인에서 길게 누르기 반복 입력과 버튼 영역 밖 커서 드래그가 정상 동작함을 확인했다.

#### [P2][Resolved] 취소된 키보드 전환 제스처가 전환 결과를 확정할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift:112`, `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift:193`
- 영향: 키보드 선택 또는 한 손 모드 드래그/길게 누르기가 중단되어도 키보드 종류나 한 손 모드가 바뀔 수 있다.
- 근거: 팬의 `.cancelled`/`.failed`가 `.ended`와 같은 완료 경로를 실행해 `.touchUpInside`와 `on...GestureEnded`를 호출한다. 완료 helper는 현재 위치에 따라 `changeKeyboard` 또는 `changeOneHandedMode` delegate를 호출한다. 취소된 long press도 동일하게 종료 helper를 호출한다.
- 제안: 취소/실패 시 overlay와 버튼 상태만 정리하고 delegate 변경은 `.ended`에서만 확정한다. overlay가 표시된 상태에서 각 제스처를 취소하는 테스트를 추가한다.
- 처리: 키보드 선택 pan, 한 손 모드 pan, initial/continuation long press에서 `.ended`만 `.touchUpInside`와 delegate 변경을 확정하도록 분리했다. 취소/실패 시 overlay, 강조, gesture 상태, 버튼 상호작용은 정리하며 다른 현재 눌린 버튼은 보존한다.
- 검증:
  - `SwitchGestureControllerTests`에서 정상 종료 전환, 취소/실패 결과 차단, keyboard/one-handed overlay 정리, initial/continuation long press 취소, 다른 현재 버튼 보존을 확인했다.
  - 권한 있는 환경의 집중 interaction 테스트와 전체 `SYKeyboard` 테스트에서 `TEST SUCCEEDED`를 확인했다.
  - 권한 있는 환경에서 `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드 모두 `BUILD SUCCEEDED`를 확인했다.

### Track 3. Keyboard Layout, Views, And Assets

#### [P2][Invalid] 한 손 키보드가 설정한 너비보다 확장될 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift:178`
- 영향: 한 손 키보드 너비 슬라이더 값은 정확한 고정 폭이 아니라 키보드가 확보해야 할 최소 폭으로 적용된다.
- 근거: `keyboardLayoutView` 너비는 `greaterThanOrEqualToConstant`로만 제한된다. 한 손 모드에서도 수평 `UIStackView`가 남는 공간을 `keyboardLayoutView`에 배분할 수 있고, `updateOneHandedWidth(_:)`도 같은 하한값만 변경한다.
- 판단: 사용자 결정에 따라 설정값은 정확한 폭이 아니라 최소 폭이다. `equalToConstant` 고정 폭은 hidden arranged subview를 사용하는 기존 스택 레이아웃과 충돌해 세로·가로 한 손 모드 전환에서 제약 경고를 발생시켰다. 기준 커밋 `84a48326c9d492654074c863227b7330f3b2a97a`처럼 `greaterThanOrEqualToConstant` 제약을 항상 활성화하고 Chevron은 `isHidden`으로 표시한다.
- 처리: 고정 폭 계산·활성화 정책과 Chevron 폭 0 축소 처리를 제거했다. `KeyboardView`는 최소 폭 상수와 Chevron hidden 상태를 갱신하며, VC는 현재 모드 저장과 Chevron 탭 action만 관리한다.
- 검증:
  - 기준 커밋에서 같은 최소 폭 레이아웃으로 세로·가로 한 손 모드 전환 시 제약 경고가 없음을 사용자 확인했다.
  - 최소 폭 계약 복원 후 iPhone 13 mini / iOS 16.0에서 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드가 exit code 0으로 완료됐다.
  - 새 DerivedData 경로를 사용한 XcodeBuildMCP 앱 빌드·실행과 테스트 입력 필드의 키보드 표시가 성공했다.
  - UI 자동화로 커스텀 키보드의 한 손 모드 선택 제스처를 실행할 수 없어, 현재 변경 후 실제 extension의 세로·가로 한 손 모드 전환 경고는 사용자 재확인이 필요하다.

#### [P3][Resolved] 비활성화된 기본 리턴 키 아이콘이 활성 색상으로 남음

- 위치: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ReturnButton.swift:78`, `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ReturnButton.swift:181`
- 영향: `enablesReturnKeyAutomatically`로 기본 리턴 키가 비활성화되어도 아이콘은 활성 상태 색상으로 보여 비활성 상태가 불명확하다. 배경과 입력 차단은 정상이다.
- 근거: 기본 리턴 이미지는 `.alwaysOriginal`과 `.label` 색상으로 생성된다. 비활성화 시 `primaryKeyListImageView.tintColor`만 변경하므로 이미지 색상에는 적용되지 않는다.
- 처리: 기본 리턴 이미지를 template rendering으로 변경하고, 현재 return key type을 보관해 활성/강조/비활성 상태에서 라벨과 이미지 tint를 함께 갱신한다. 비활성화 후 활성화 시 정상 foreground/background 색상을 즉시 복원한다.
- 검증:
  - `ReturnButtonTests`에서 기본 이미지의 template rendering과 비활성화 후 활성 tint 복원을 확인했다.
  - 권한 있는 환경의 iPhone 13 mini / iOS 16.0에서 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드가 exit code 0으로 완료됐다.
  - 실제 extension의 빈 필드 비활성 상태와 텍스트 입력 후 활성 복원은 수동 확인하지 못했다.

### Track 4. Predictive Text And Suggestion Bar

#### [P1][Invalid] selection 변경 후 이전 후보가 새 위치의 텍스트를 변경할 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:283`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1487`
- 영향: 후보가 표시된 뒤 커서를 이동하거나 다른 단어를 선택하면, 이전 텍스트용 후보를 탭해 새 커서 위치의 문자를 삭제하거나 현재 선택 텍스트를 관련 없는 후보로 교체할 수 있다.
- 근거: `selectionDidChange(_:)`는 로그만 남기며 `inputBuffer`나 후보를 초기화/갱신하지 않는다. 이후 후보 선택은 현재 선택 텍스트 또는 기존 `inputBuffer`를 사용하지만, `SuggestionController.currentSuggestions`가 해당 텍스트로 생성됐는지 확인하지 않는다.
- 판단: 사용자 확인 결과 `selectionWillChange(_:)`와 `selectionDidChange(_:)`는 관찰되지 않지만, focus 중인 텍스트 필드 변경, 사용자의 텍스트 필드 탭, 커서 이동 시 `textWillChange(_:)`와 `textDidChange(_:)`가 호출된다. 현재 구현은 `textWillChange(_:)`에서 `resetInputBuffer()`를 호출하고 `textDidChange(_:)`에서 `updateSuggestions()`를 호출하므로 커서/필드 변경 후 이전 후보가 그대로 남는다는 finding의 전제가 성립하지 않는다.
- 검증: 사용자 수동 확인 및 `BaseKeyboardViewController.textWillChange(_:)`, `textDidChange(_:)` 코드 경로 확인.

#### [P1][Resolved] 텍스트 대치 복구 이력이 다른 위치의 동일 문구를 단축어로 되돌릴 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:432`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:283`
- 영향: 텍스트 대치를 수행한 뒤 커서를 다른 위치의 동일한 확장 문구 뒤로 이동하고 삭제하면, 해당 문구가 과거 단축어로 예기치 않게 변경될 수 있다.
- 근거: `attemptRestoreReplacement(...)`는 모든 과거 `replacementHistory`를 역순으로 탐색하고 현재 `inputBuffer` 또는 커서 앞 컨텍스트 suffix가 `documentText`와 같으면 복구한다. 이력에는 원래 대치 위치나 컨텍스트 anchor가 없고 selection/cursor 변경 시 이력을 비우지 않는다.
- 제안: 직전 대치의 위치/컨텍스트와 일치할 때만 복구하거나, 커서·selection·focus 변경 시 복구 이력을 무효화한다.
- 처리: `attemptRestoreReplacement(...)`가 마지막 대치 이력만 복구 대상으로 삼도록 제한했다. `textWillChange(_:)`에서는 입력 버퍼와 함께 텍스트 대치 복구 이력을 비워 커서/focus/context 변경 뒤 과거 대치 이력이 쓰이지 않게 했다.
- 검증: `SuggestionControllerTextReplacementTests`에 마지막 대치 복구와 이력 삭제 후 미복구 테스트를 추가했다. 권한 있는 환경의 iPhone 13 mini / iOS 16.0 focused 테스트에서 `TEST SUCCEEDED`를 확인했다.

#### [P1][Resolved] 텍스트 대치 단축어가 긴 단어의 suffix와도 일치함

- 위치: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:396`
- 영향: 단축어가 일반 단어의 끝부분과 같으면 스페이스 입력 시 일반 단어 일부가 의도하지 않은 대치 문구로 변경될 수 있다.
- 근거: `attemptTextReplacement(baseText:)`는 `baseText.lowercased().hasSuffix(entry.userInput.lowercased())`만 확인하며 단축어 앞 단어 경계를 검사하지 않는다. 예를 들어 단축어 `id`는 `paid`의 suffix와도 일치한다.
- 제안: 전체 `baseText` suffix가 아니라 현재 입력 단어와 단축어가 정확히 일치하는지 검사하거나 단축어 앞의 단어 경계를 확인한다.
- 처리: `attemptTextReplacement(baseText:)`가 커서 앞 마지막 단어와 단축어의 exact match만 허용하도록 변경했다.
- 검증: `SuggestionControllerTextReplacementTests`에서 `paid`는 대치하지 않고 `id`만 대치하는 경로를 확인했다. 권한 있는 환경의 iPhone 13 mini / iOS 16.0 focused 테스트에서 `TEST SUCCEEDED`를 확인했다.

#### [P2][Resolved] 비동기 lexicon 로딩 전 첫 텍스트 대치가 조용히 누락될 수 있음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1002`, `Modules/SYKeyboardCore/Domain/SuggestionController.swift:391`
- 영향: 키보드가 표시된 직후 사용자가 단축어와 스페이스를 빠르게 입력하면 동일한 입력이어도 첫 텍스트 대치가 적용되지 않을 수 있다.
- 근거: lexicon 요청은 `viewDidAppear(_:)` 이후 비동기로 시작되고, `attemptTextReplacement(baseText:)`는 `lexiconEngine?.lexicon`이 아직 없으면 재시도나 보류 없이 `nil`을 반환한다. `snm-40-predictive-loading` 문서에도 첫 대치 누락 여부가 미해결 질문으로 남아 있다.
- 제안: 텍스트 대치가 켜진 경우 lexicon 준비 시점을 앞당기거나, 로딩 중 첫 대치 요청을 안전하게 재평가하는 정책을 명시한다.
- 처리: 텍스트 대치가 켜진 경우 `BaseKeyboardViewController.viewDidLoad()`에서 lexicon 로딩을 먼저 시작하도록 했다. 입력 이벤트를 기다리는 blocking 방식은 사용하지 않는다.
- 검증: `KeyboardSuggestionSelectionPolicyTests`에 텍스트 대치용 lexicon 선로딩 정책 테스트를 추가했다. 권한 있는 환경의 iPhone 13 mini / iOS 16.0 focused 테스트에서 `TEST SUCCEEDED`를 확인했다. 실제 시스템 `UILexicon` 지연 완료 타이밍의 첫 스페이스 입력은 수동 확인이 필요하다.

#### [P2][Resolved] n-gram 초기화가 background load/save와 경쟁해 삭제한 학습 데이터를 되살릴 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:159`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:319`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:343`
- 영향: 사용자가 자동완성 학습 데이터를 초기화해도 진행 중이던 load 또는 save가 이후 완료되면 메모리나 파일에 이전 데이터가 다시 나타날 수 있다.
- 근거: init의 background load, `saveQueue`의 파일 쓰기, `resetAllData()`의 메모리 초기화/파일 삭제가 하나의 직렬화된 상태나 generation 검증 없이 독립적으로 실행된다.
- 제안: load/save/reset을 하나의 저장소 직렬 큐 또는 generation token으로 조정하고, 초기화를 위해 로딩 엔진을 새로 만드는 대신 저장소 수준 reset API를 제공한다.
- 처리: `NGramPredictiveTextEngine`에 storage generation을 추가해 reset 이후 완료된 오래된 background load/save가 메모리나 파일에 반영되지 않게 했다. reset 시 pending event와 write counter도 함께 비운다.
- 검증: `NGramPredictiveTextEngineLoadingTests`에 reset 이후 지연 load 결과가 되살아나지 않는 테스트를 추가했다. 권한 있는 환경의 iPhone 13 mini / iOS 16.0 focused 테스트에서 `TEST SUCCEEDED`를 확인했다.

#### [P3][Resolved] n-gram 로딩 전 확정된 단어가 학습에서 누락될 수 있음

- 위치: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:263`, `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:274`
- 영향: 키보드 표시 직후 로딩이 끝나기 전에 스페이스나 리턴으로 확정된 초기 단어가 n-gram 학습에 포함되지 않을 수 있다.
- 근거: `addWord(_:)`와 `endSentence()`는 `isLoaded == false`이면 요청을 버린다. `snm-40-predictive-loading` 문서도 로딩 전 기록 queue 필요 여부를 미해결 질문으로 남겼다.
- 제안: 로딩 전 기록을 메모리 queue에 보관해 로딩 완료 후 순서대로 적용하거나, 누락을 의도된 trade-off로 명시하고 검증한다.
- 처리: 로딩 전 `addWord(_:)`와 `endSentence()` 호출을 pending event queue에 보관하고, load 완료 후 순서대로 반영하도록 했다. reset 시 queue는 폐기한다.
- 검증: `NGramPredictiveTextEngineLoadingTests`에 로딩 전 기록한 단어가 로딩 완료 후 후보에 반영되는 테스트를 추가했다. 권한 있는 환경의 iPhone 13 mini / iOS 16.0 focused 테스트에서 `TEST SUCCEEDED`를 확인했다.

### Track 5. Settings And UserDefaults Contract

#### [P1][Resolved] 최초 설치에서 자동 대문자 기본값이 설정 화면과 키보드 런타임에서 다르게 해석됨

- 위치: `Modules/EnglishKeyboardCore/Storage/UserDefaultsManager+Extension.swift:15`, `Modules/EnglishKeyboardCore/Storage/DefaultValues+Extension.swift:12`, `SYKeyboard/Presentation/KeyboardSettings/InputSettingsView.swift:22`
- 영향: 사용자가 자동 대문자 설정을 변경한 적 없는 최초 설치 상태에서 설정 화면은 활성화로 표시하지만, 영어 키보드는 자동 대문자를 비활성화하고 앱 초기 Analytics도 비활성화로 기록한다.
- 근거: 선언된 기본값과 `@AppStorage` 기본값은 `true`지만, 영어 키보드 런타임 getter는 키가 없으면 `false`를 반환하는 `storage.bool(forKey:)`를 사용한다. `EnglishKeyboardCoreViewController.updateShiftButton()`은 이 getter를 직접 읽는다.
- 제안: `UserDefaultsWrapper`를 사용하거나 `storage.object(forKey:) as? Bool ?? DefaultValues.isAutoCapitalizationEnabled`로 absent-key fallback을 일치시킨다.
- 처리: 영어 키보드의 `isAutoCapitalizationEnabled` getter를 `storage.object(forKey:) as? Bool ?? DefaultValues.isAutoCapitalizationEnabled`로 변경해 absent key에서 선언된 기본값을 반환하도록 했다. `UserDefaultsContractTests`에 빈 저장소 fallback 계약 테스트를 추가했다.
- 검증:
  - 일반 샌드박스의 targeted 테스트는 CoreSimulator/Xcode 캐시 권한 오류로 실패했다.
  - 권한 있는 환경에서 구현 전 targeted 테스트가 `AppUserDefaults*` 타입 미정의 compile error로 실패하는 것을 확인했다.
  - 구현 후 권한 있는 환경의 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/UserDefaultsContractTests`는 `TEST SUCCEEDED`를 확인했다.
  - 권한 있는 환경의 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드도 성공했다.

#### [P2][Invalid] 키보드 컨트롤러가 재사용되면 변경된 설정 일부가 다시 반영되지 않음

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:207`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:226`
- 영향: 기존 키보드 컨트롤러가 사라졌다 다시 표시되는 동안 앱에서 설정을 바꾸면, 마침표 단축키, 커서 드래그, 길게 누르기, 숫자 키패드/한 손 모드 전환 제스처, 자동완성/텍스트 대치 상태가 이전 값으로 남을 수 있다.
- 근거: 설정 화면은 App Group `@AppStorage`에 즉시 값을 쓰지만, 런타임은 조건부 action/gesture와 suggestion 상태를 `viewDidLoad()`에서만 구성한다. `viewWillAppear()`는 키보드 높이와 햅틱 준비만 갱신하며 설정을 다시 적용하지 않는다.
- 제안: 재진입 시 호출할 idempotent 설정 갱신 경로를 정의하고, 조건부 action/gesture 추가·제거 및 suggestion 상태를 현재 저장값과 동기화한다.
- 처리: 실제 lifecycle 로그 확인 결과 키보드가 다시 표시될 때 기존 controller 인스턴스를 재사용하지 않고 새 인스턴스를 생성하며 `viewDidLoad()`를 다시 거친다. 따라서 현재 관찰된 환경에서는 stale 설정 전제가 성립하지 않는다.
- 검증: `loadView`, `viewDidLoad`, `viewWillAppear`, `viewDidAppear`, `deinit` lifecycle 로그로 새 인스턴스 생성과 `viewDidLoad()` 재호출을 확인했다.

#### [P3][Resolved] 앱 전용 UserDefaults 상태의 모듈 경계와 기본값 계약 정리

- 위치: `SYKeyboard/Storage/UserDefaultsManager+Extension.swift:13`, `SYKeyboard/Storage/DefaultValues+Extension.swift:12`
- 영향: 현재 `ContentView`는 올바른 `@AppStorage` 기본값을 사용하므로 즉시 사용자 영향은 낮지만, 앱 전용 온보딩/리뷰 상태가 `SYKeyboardCore.UserDefaultsManager/UserDefaultsKeys/DefaultValues` 확장에 섞여 모듈 경계가 흐려진다. 향후 manager getter를 직접 사용하는 코드는 최초 실행에서 온보딩 기본값을 `true`가 아닌 `false`로 해석할 수 있다.
- 근거: 선언된 기본값은 `true`지만 getter는 키가 없으면 `false`를 반환하는 `storage.bool(forKey:)`를 사용한다. 추가 확인 결과 `isOnboarding`, `reviewCounter`, `lastBuildPromptedForReview`는 앱 타깃에서만 사용되고 키보드 모듈 사용처는 확인되지 않았다.
- 제안: 단순 fallback 수정 대신 앱 전용 `AppUserDefaultsManager`, `AppUserDefaultsKeys`, `AppDefaultValues`로 분리한다. 기존 key 문자열과 App Group suiteName은 유지해 저장 데이터 위치를 바꾸지 않는다.
- 처리: 앱 타깃에 `AppUserDefaultsManager`, `AppUserDefaultsKeys`, `AppDefaultValues`를 추가하고 `ContentView`, `RequestReviewViewModifier`가 앱 전용 타입을 사용하도록 전환했다. 기존 key 문자열과 App Group suiteName은 유지했고, `SYKeyboardCore.UserDefaultsManager/UserDefaultsKeys/DefaultValues`에 붙어 있던 앱 전용 extension 파일은 제거했다.
- 검증:
  - `UserDefaultsContractTests`에서 빈 저장소의 온보딩 기본값 fallback과 앱 전용 key 문자열 보존을 확인했다.
  - 권한 있는 환경의 targeted 계약 테스트, 전체 `SYKeyboard` 테스트, `HangeulKeyboard` 빌드, `EnglishKeyboard` 빌드가 모두 성공했다.

### Track 6. Keyboard Extension Entry Points

#### [P2][Resolved] 전체 접근 미허용 상태에서 오버레이 닫힘 상태를 공유 컨테이너에 저장함

- 위치: `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift:70`, `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift:70`, `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:31`, `Modules/SYKeyboardCore/Storage/KeyboardExtensionLocalStateStore.swift`
- 영향: 전체 접근을 허용하지 않은 사용자가 안내를 닫아도 keyboard extension이 app-group 공유 컨테이너에 접근할 수 없어 닫힘 상태가 다음 세션에 유지되지 않을 수 있다. 그 결과 한글/영문 키보드를 다시 열 때 전체 화면 오버레이가 반복 표시될 수 있다.
- 근거: 오버레이는 `hasFullAccess == false`일 때 표시되지만 닫기 action은 app-group suite를 사용하는 `keyboardSettingsManager.isRequestFullAccessOverlayClosed`에 기록한다.
- 처리: `KeyboardExtensionLocalStateStore`를 추가해 기본 저장소를 `UserDefaults.standard`로 분리했다. `BaseKeyboardViewController.needToShowFullAccessGuide`와 한글/영문 overlay close action이 이 local store를 사용하도록 변경했다. app-group 저장소와 동기화하거나 전체 접근 허용 후 migration하지 않는다.
- 검증:
  - 구현 전 `UserDefaultsContractTests/testRequestFullAccessOverlayStateUsesLocalStorage()`는 local state store 타입 미정의로 실패하는 것을 확인했다.
  - rename 작업에서 테스트를 먼저 `KeyboardExtensionLocalStateStore`로 변경한 뒤, 권한 있는 환경에서 타입 미정의 compile error로 RED를 확인했다.
  - 구현 후 권한 있는 환경의 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/UserDefaultsContractTests`에서 `TEST SUCCEEDED`를 확인했다.
  - 권한 있는 환경의 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드가 모두 성공했다.
  - 2026-06-19 사용자 실기기 확인에서 전체 접근 미허용 상태의 한글/영문 오버레이 닫힘 유지 동작이 정상이라고 확인했다.

#### [P2][Resolved] EnglishKeyboard target에 app-extension-safe API 검사가 비활성화되어 있음

- 위치: `SYKeyboard.xcodeproj/project.pbxproj`
- 영향: 영어 keyboard extension 또는 의존 코드에 app extension에서 사용할 수 없는 API가 추가되어도 빌드 시 검출되지 않을 수 있다. 같은 역할의 한글 extension과 안전성 검증 수준도 달라진다.
- 근거: HangeulKeyboard Debug/Release에는 `APPLICATION_EXTENSION_API_ONLY = YES`가 있지만 EnglishKeyboard Debug/Release에는 해당 설정이 없다.
- 처리: EnglishKeyboard Debug/Release build settings에 `APPLICATION_EXTENSION_API_ONLY = YES`를 추가했다.
- 검증:
  - 권한 있는 환경의 `xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`에서 `BUILD SUCCEEDED`를 확인했다.
  - 권한 있는 환경의 `HangeulKeyboard` scheme 빌드와 전체 `SYKeyboard` 테스트도 성공했다.

#### [P3][Deferred] 설정 이동 버튼이 URL 열기 실패를 조용히 무시함

- 위치: `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift:104`, `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift:104`
- 영향: responder chain에서 `UIApplication`을 찾지 못하거나 URL 열기가 거부되면 사용자가 `시스템 설정 이동` 버튼을 눌러도 아무 반응이 없다.
- 근거: `openURL(_:)`은 `UIApplication`을 찾지 못하면 그대로 종료하고, `application.open(url)`의 성공/실패 completion도 처리하지 않는다.
- 판단: 설정 이동은 비핵심 편의 기능이며 오버레이에 수동 설정 경로가 이미 표시되어 있다. 사용자 실패 UI나 복잡한 fallback은 추가하지 않고 현재 best-effort 동작을 유지한다.
- 후속: 개발자가 실패 상황을 확인할 수 있도록 responder chain에서 `UIApplication`을 찾지 못한 경우와 URL 열기 completion 실패에 진단 로그를 남기는 수준으로 제한한다.
- 검증: 사용자 결정 및 코드 경로 확인. 진단 로그를 추가할 때 성공/실패 분기만 확인한다.

### Track 7. Main App Shell, Onboarding, Ads, And Resources

#### [P2][Open] 설정 이동 deep link가 최초 ATT 권한 요청과 충돌함

- 위치: `SYKeyboard/App/SYKeyboardApp.swift:121`, `SYKeyboard/App/SYKeyboardApp.swift:126`
- 영향: 전체 접근 안내에서 `sykeyboard://`로 앱을 열어 시스템 설정으로 이동하려는 최초 사용자가, 설정 앱 위에서 SYKeyboard의 추적 권한 팝업을 보게 되어 설정 흐름이 중단되고 권한 요청 맥락도 불명확해진다.
- 근거: `.onOpenURL`은 즉시 시스템 설정을 열고, 인접한 `didBecomeActive` 구독은 ATT 상태가 `.notDetermined`이면 독립적으로 권한을 요청한다. 독립 코드리뷰에서 iOS 26.5 시뮬레이터의 최초 권한 상태로 `sykeyboard://`를 열었을 때 Settings가 foreground인 상태에서 SYKeyboard ATT 팝업이 표시되는 것을 재현했다.
- 제안: ATT 요청을 온보딩 이후의 명시적인 앱 내부 시점으로 이동하거나, 설정 redirect를 처리하는 동안에는 ATT 요청을 보류한다.
- 검증: ATT 권한을 초기화한 뒤 `sykeyboard://` 진입 시 Settings가 팝업 없이 열리는지 확인하고, 일반 앱 실행에서는 정한 앱 내부 시점에 ATT 요청이 표시되는지 확인한다.

#### [P2][Open] 화면 폭 변경 후 adaptive banner가 최초 크기를 유지함

- 위치: `SYKeyboard/Presentation/Content/ContentView.swift:28`, `SYKeyboard/Presentation/Content/BannerAd/BannerAdView.swift:37`
- 영향: 회전 또는 iPad 창 크기 변경 후 SwiftUI가 확보한 광고 영역과 실제 로드된 banner 크기가 달라져 광고가 잘리거나 빈 공간이 생길 수 있다.
- 근거: `ContentView`는 현재 `geometry.size.width`로 `adSize`를 다시 계산하지만, `BannerAdView.updateUIView(_:,context:)`가 비어 있어 이미 생성된 `BannerView`의 `adSize`와 광고 요청은 갱신되지 않는다.
- 제안: `updateUIView`에서 새 크기와 현재 banner 크기를 비교해 `adSize`를 갱신하고 필요한 경우 광고를 다시 요청한다.
- 검증: 광고 로드 후 기기 회전과 iPad 창 크기 변경을 수행해 `BannerView.adSize`, 실제 frame, SwiftUI 광고 영역이 일치하는지 확인한다.

#### [P2][Open] 광고를 받지 못해도 빈 하단 safe area가 유지됨

- 위치: `SYKeyboard/Presentation/Content/ContentView.swift:36`
- 영향: 네트워크 오류, 광고 재고 부족, 초기 로딩 중에도 설정 목록 아래에 광고 높이만큼 빈 공간이 남아 사용 가능한 화면 영역이 줄어든다.
- 근거: `safeAreaInset` 내부의 `BannerAdView`는 항상 `adSize.size.height`까지 레이아웃에 참여한다. `isAdReceived == false`일 때 적용하는 `.opacity(0)`와 `.allowsHitTesting(false)`는 표시와 입력만 바꾸며 레이아웃 공간은 제거하지 않는다.
- 제안: 광고 수신 성공 시에만 safe-area 높이를 확보하거나, 수신 상태에 따라 광고 container 높이를 0과 실제 높이 사이에서 전환한다.
- 검증: 광고 요청을 실패시키거나 오프라인으로 실행해 하단 빈 공간이 없는지 확인하고, 광고 수신 후에만 설정 목록이 광고 높이만큼 안전하게 올라가는지 확인한다.

#### [P2][Open] 자동 인앱 리뷰 요청 modifier가 어떤 화면에도 연결되지 않음

- 위치: `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift:14`, `SYKeyboard/Presentation/Utils/Extensions/View+Extension.swift:15`
- 영향: 사용자가 앱 화면을 반복 방문해도 `reviewCounter`가 증가하지 않고 자동 인앱 리뷰 요청이 절대 표시되지 않는다. 수동 App Store 리뷰 버튼만 동작한다.
- 근거: `requestReviewViewModifier()` helper와 modifier 구현은 남아 있지만, 현재 Swift 파일에서 이를 적용하는 호출이 없다. Git 이력상 과거 설정 화면들에는 modifier가 적용되어 있었으므로 기능 연결이 제거된 상태다.
- 제안: 자동 리뷰 요청을 유지할 계획이면 반복 방문을 의미하는 안정적인 화면에 modifier를 적용하고, 유지하지 않을 계획이면 modifier와 관련 저장 키를 제거해 의도를 명확히 한다.
- 검증: 자동 요청을 유지할 경우 threshold 직전 counter로 대상 화면을 열고 닫아 counter 증가, build당 1회 제한, 요청 호출을 확인한다.

#### [P3][Resolved] 한 손 키보드 안내의 한국어 문구에 영문 `or`가 노출됨

- 위치: `SYKeyboard/Presentation/Content/InstructionsTabView.swift:49`, `SYKeyboard/Presentation/InstructionsTab/InstructionsPageView.swift:62`, `SYKeyboard/Resources/Localizable.xcstrings`
- 영향: 한국어 온보딩 화면에 영문 접속사가 섞여 문구 완성도가 떨어진다.
- 근거: 한국어 source 문자열이 `"'!#1', '한글' 또는 'ABC' 버튼을 위로 드래그 or 길게 누르기"`로 정의되어 있다.
- 처리: 실제 안내 문구와 SwiftUI preview 문구를 자연스러운 한국어인 `위로 드래그하거나 길게 누르기`로 변경하고 String Catalog key를 함께 갱신했다.
- 검증: `jq empty SYKeyboard/Resources/Localizable.xcstrings`, `xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`

### Track 8. Build, Packaging, And Repository Hygiene

#### [P2][Invalid] fresh clone에서 문서의 빌드 명령을 실행할 준비 절차가 없음

- 위치: `.gitignore:154`, `ci_scripts/ci_post_clone.sh:12`, `SYKeyboard.xcodeproj/project.pbxproj:949`, `AGENTS.md:79`
- 판단: 저장소의 clean-environment 빌드 계약은 Xcode Cloud의 `ci_post_clone.sh`가 환경변수를 검증하고 `Secrets.xcconfig`와 Firebase plist를 생성하는 흐름이다. 사용자가 이 흐름에서 CI/CD 빌드와 테스트가 정상 수행됨을 확인했으며, 로컬 fresh clone bootstrap은 지원 요구사항이 아니므로 finding에서 제외한다.

#### [P2][Open] 문서의 Xcode 16+ 지원 기준과 로컬 package 최소 tools version이 일치하지 않음

- 위치: `README.md:50`, `AGENTS.md:52`, `SYKeyboardAssets/Package.swift:1`
- 영향: Xcode 16 이상이면 개발 가능한 것으로 안내되지만, `SYKeyboardAssets` manifest는 Swift tools 6.2 이상을 요구해 낮은 버전 Xcode에서 package graph 해석 전에 막힐 수 있다.
- 근거: README와 AGENTS는 Xcode 16+를 기준으로 선언하고, package manifest는 최소 tools version을 `6.2`로 선언한다. 현재 검증 환경은 Xcode 26.5 / Swift 6.3.2뿐이다.
- 제안: 실제 최소 지원 Xcode를 문서에 명시하거나, package가 Swift tools 6.2 기능을 사용하지 않는다면 지원하려는 Xcode에 맞춰 tools version을 낮추고 검증한다.
- 검증: 문서에 선언할 최소 Xcode에서 `xcodebuild -list`와 `SYKeyboard` 빌드를 실행한다.

#### [P3][Resolved] 저장소 문서와 CI 스크립트가 메인 앱 번들에 포함됨

- 위치: `SYKeyboard.xcodeproj/project.pbxproj:650`, `SYKeyboard.xcodeproj/project.pbxproj:839`
- 영향: 런타임에 필요하지 않은 `README.md`와 `ci_post_clone.sh`가 app bundle에 포함되어 배포 산출물과 target membership에 불필요한 노이즈가 생긴다.
- 근거: `README.md`는 app resources build phase에 명시적으로 포함되어 있고, `ci_scripts/`는 app target의 filesystem-synchronized group이다. 별도 DerivedData 빌드 산출물에서 두 파일의 실제 포함을 확인했다.
- 처리: app resources build phase에서 `README.md`를 제거하고, filesystem-synchronized `ci_scripts/` group의 app target membership에서 `ci_post_clone.sh`를 제외했다.
- 검증: `SYKeyboard` scheme 빌드가 성공했고, 새 app bundle에 `README.md`와 `ci_post_clone.sh`가 포함되지 않은 것을 확인했다.

#### [P3][Resolved] Meta mediation 의존성이 mutable `main` branch를 따름

- 위치: `SYKeyboard.xcodeproj/project.pbxproj:492`, `SYKeyboard.xcodeproj/project.pbxproj:818`, `SYKeyboard.xcodeproj/project.pbxproj:1910`, `SYKeyboard.xcodeproj/project.pbxproj:1937`
- 영향: package update 시 검토되지 않은 adapter 변경이 들어와 빌드나 광고 동작이 달라질 수 있다.
- 근거: Meta adapter repository가 프로젝트의 `packageReferences`에 직접 선언되고 `MetaAdapterTarget`도 메인 앱 Frameworks에 직접 연결되어 있어 다른 라이브러리의 전이 의존성이 아니다. package requirement는 `kind = branch`, `branch = main`이며, 현재 일반 clone 재현성은 `Package.resolved`의 revision `52622d3` 고정으로 완화된다.
- 처리: Meta mediation package를 다시 추가하면서 requirement를 `upToNextMajorVersion`, 최소 버전 `6.21.101`로 변경하고 `Package.resolved`를 release version `6.21.101`로 갱신했다.
- 검증: 별도 DerivedData 경로에서 package graph가 Meta adapter `6.21.101`과 FBAudienceNetwork `6.21.1`로 resolve됐고, `SYKeyboard` scheme 빌드가 성공했다.

#### [P3][Resolved] 메인 앱 Info.plist에 `DeveloperEmail` key가 중복 선언됨

- 위치: `SYKeyboard/Resources/Info.plist:7`
- 영향: 중복 dictionary key는 도구별 해석이 모호하고 향후 두 값이 달라질 때 설정 drift를 숨길 수 있다.
- 근거: source plist에 동일 key가 두 번 존재한다. `plutil -lint`는 통과하며 현재 빌드 산출물에는 하나의 값만 남는다.
- 처리: 중복 선언 하나를 제거했다.
- 검증: source plist의 `DeveloperEmail` key가 하나인 것과 `plutil -lint` 통과, 새 app bundle의 processed plist에 key가 하나인 것을 확인했다.

#### [P3][Open] generated SwiftPM workspace metadata가 git에 추적됨

- 위치: `SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata:1`, `.gitignore:128`
- 영향: 생성 가능한 workspace metadata가 불필요한 리뷰 변경을 만들고 저장소의 ignore 정책과 어긋난다.
- 근거: 해당 파일과 정확히 일치하는 ignore 규칙이 있지만 파일은 이미 git에 추적되어 있다.
- 제안: 파일을 git 추적에서 제거하고 현재 ignore 규칙을 유지한다.
- 검증: package를 Xcode에서 다시 연 뒤 `git status --short`가 깨끗한지 확인한다.

## Handoff

- Track 2부터 각 리뷰 채팅의 findings는 이 문서의 `## Findings` 아래에 트랙별 섹션으로 추가한다.
- 각 finding은 우선순위, 상태, 위치, 영향, 근거, 제안 또는 처리, 검증을 포함한다.
- 다른 트랙으로 넘길 내용은 해당 트랙 섹션 끝에 `Handoff` 항목으로 남긴다.
- Track 1의 나랏글 이중모음 교차 입력 동작은 사용자 확인으로 의도된 동작으로 정리했다.
- Track 2의 세 finding은 모두 제스처/UIControl 취소 상태 전이와 관련되어 있어 함께 수정하고 interaction test로 검증하는 편이 적절하다.
- Track 3의 한 손 키보드 폭 finding은 최소 폭 계약으로 최종 결정됐다. 실제 extension과 preview의 portrait/landscape에서 키보드가 설정값 이상을 확보하고 제약 경고가 없는지 확인한다.
- Track 3의 기본 리턴 키 아이콘 finding은 `ReturnButton`의 template/original rendering 정책을 정리할 때 함께 수정한다.
- `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/.DS_Store`는 `.gitignore` 대상이라 추적되지는 않지만 로컬 리소스 폴더에 존재한다. 실제 SPM 리소스 번들 포함 여부는 Track 8에서 확인한다.
- Track 4의 selection stale 후보 finding은 실제 `textWillChange(_:)`/`textDidChange(_:)` 호출 동작 확인으로 `Invalid` 처리했다. selection 콜백 대신 text change 콜백을 외부 문서 컨텍스트 동기화 기준으로 본다.
- Track 4의 텍스트 대치 복구 이력 문제는 `textWillChange(_:)`에서 `inputBuffer`와 n-gram 문맥은 초기화하지만 replacement history는 유지한다는 점을 고려해 후속 검증한다.
- Track 4의 lexicon/n-gram 로딩 findings는 `dev/active/snm-40-predictive-loading/`의 미해결 질문과 연결해 후속 처리한다.
- Track 5에서 메인 앱의 학습 데이터 초기화 화면이 모든 데이터 삭제를 약속하지만 임시 엔진을 생성해 `resetAllData()`를 호출한다는 점을 확인했다. 기존 Track 4의 n-gram reset 경쟁 조건을 해결할 때 설정 화면과 활성 extension 엔진 사이의 저장소 수준 reset 계약을 함께 정의해야 한다.
- Track 5의 키보드 재진입 설정 갱신 finding은 공통 런타임과 extension lifecycle에 걸쳐 있으므로 Track 2/6 후속 수정에서 함께 다룬다.
- Track 5 범위에는 UserDefaults 키/기본값/type parity, absent-key fallback, 재진입 설정 갱신을 직접 검증하는 테스트가 없다.
- Track 6의 전체 접근 오버레이 닫힘 상태는 각 extension의 `UserDefaults.standard`에만 저장한다. app-group 동기화나 마이그레이션은 하지 않으며 한글/영문 상태를 독립적으로 유지한다.
- Track 6의 EnglishKeyboard Debug/Release에 `APPLICATION_EXTENSION_API_ONLY = YES`를 적용하기로 결정했다. Track 8의 build/packaging 리뷰에서도 target별 설정 parity와 적용 후 빌드 결과를 다시 확인한다.
- Track 6의 설정 이동 실패는 비핵심 best-effort 기능으로 유지한다. 사용자 실패 UI 대신 개발자 진단 로그만 후속 개선 대상으로 둔다.
- Track 7 확인 결과 `sykeyboard://`는 현재 등록된 유일한 custom scheme이며 extension의 설정 이동 전용으로 사용되므로, URL 종류를 구분하지 않고 시스템 설정을 여는 현재 동작 자체는 finding으로 보지 않는다. 향후 다른 deep link를 추가할 때는 명시적인 URL routing을 먼저 정의한다.
- Track 7의 ATT/설정 이동 충돌은 extension overlay에서 시작되는 사용자 흐름이지만 수정 책임은 메인 앱 lifecycle에 둔다.
- Track 7의 banner 두 finding은 함께 수정하고, 광고 성공/실패 및 기기 회전/iPad resize 흐름을 수동 검증하는 편이 적절하다.
- Track 7에서 `SYKeyboard/Resources/Info.plist` source에 `DeveloperEmail` key가 두 번 선언된 것을 확인했다. 빌드 결과에는 하나의 값만 남지만 source hygiene와 Firebase/config packaging 전반은 Track 8로 넘긴다.
- Track 8에서 전체 review execution checklist가 완료됐다. 다음 단계는 Open findings의 수정 우선순위와 묶음을 결정하는 것이다.
- fresh clone bootstrap 문서화 finding은 Xcode Cloud의 secret 생성 흐름이 저장소의 clean-environment 빌드 계약이고 CI/CD가 정상 수행된다는 사용자 확인에 따라 `Invalid` 처리했다.
- Track 8의 앱 번들 문서/스크립트 포함과 중복 `DeveloperEmail` findings는 사용자 수정 후 빌드 산출물 검증을 거쳐 `Resolved` 처리했다.
- Meta mediation package는 전이 의존성이 아니라 프로젝트에 직접 추가된 의존성이다. release version 기반 requirement로 다시 추가하고 빌드를 검증해 mutable `main` branch finding을 `Resolved` 처리했다.
- `SYKeyboardAssets` resource bundle에는 ignored `.DS_Store`가 포함되지 않아 추가 finding으로 보지 않는다.
- Track 6의 EnglishKeyboard `APPLICATION_EXTENSION_API_ONLY` parity finding은 `Resolved` 처리했고, Track 8에서 중복 finding을 추가하지 않았다.
