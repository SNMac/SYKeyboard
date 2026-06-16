# Issue 67 Predictive Suggestion Findings Context

Last Updated: 2026-06-16

## Relevant Files

- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: 텍스트 대치, 대치 복구 이력, lexicon/n-gram 엔진 준비와 기록 경로가 있다.
- `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`: n-gram 비동기 로딩, 저장, reset, 로딩 전 기록 무시 동작이 있다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 스페이스/삭제 입력 시 텍스트 대치와 복구를 호출하고, `viewDidAppear(_:)` 이후 deferred suggestion preparation을 시작한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`: 대치 복구 시 삭제할 길이를 판단한다.
- `Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift`: 후보 표시 쪽은 이미 현재 단어와 단축어의 정확한 일치를 사용한다.
- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`: `SuggestionController` 엔진 준비와 n-gram load callback 관련 테스트와 stub factory가 있다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: Issue #67의 source finding 상태 문서다.
- `dev/active/snm-40-predictive-loading/`: lexicon 지연 로딩과 n-gram 로딩 전 입력 누락이 미해결 질문으로 남아 있다.

## Facts Checked

- `gh issue view 67 --repo SNMac/SYKeyboard --comments`는 GitHub classic Projects GraphQL 필드 오류로 실패했다.
- `gh api repos/SNMac/SYKeyboard/issues/67`로 이슈 본문을 확인했다. 댓글 수는 `0`이다.
- Issue #67은 `enhancement`, `open`, assignee `SNMac`, parent issue `#57`이다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 4에는 Issue #67과 같은 Open findings 5건이 기록되어 있다.
- `SuggestionController.attemptTextReplacement(baseText:)`는 `baseText.lowercased().hasSuffix(entry.userInput.lowercased())`만 확인한다.
- `LexiconPredictiveTextEngine.suggestions(for:)`는 `currentWord(from:)`를 추출해 `entry.userInput`과 정확히 일치할 때만 후보를 반환한다. 즉 후보 표시와 스페이스 자동 대치의 경계 규칙이 현재 다르다.
- `SuggestionController.attemptRestoreReplacement(...)`는 `replacementHistory` 전체를 역순으로 탐색하고, `inputBuffer` 또는 `documentContextBeforeInput` suffix가 과거 `documentText`와 같으면 복구한다.
- `BaseKeyboardViewController.textWillChange(_:)`는 `resetInputBuffer()`를 호출한다. `selectionWillChange(_:)`/`selectionDidChange(_:)`는 현재 로그만 남긴다.
- 사용자 보고: 현재 글자를 입력한 뒤 커서를 이동하면 자동완성 제안이 초기 상태로 돌아간다.
- 사용자 기대: 커서 이동이 끝난 뒤 커서 앞 글자/단어에 맞게 자동완성 제안을 다시 표시한다.
- 사용자 추가 기대: 커서를 이동하는 동안에는 텍스트필드에 아무것도 없는 상황의 초기 후보로 바뀌지 않고, 직전 자동완성 후보가 그대로 남아 있어야 한다.
- `NGramPredictiveTextEngine.init(language:)`는 background load 완료 후 main queue에서 store와 `isLoaded`를 반영한다.
- `NGramPredictiveTextEngine.addWord(_:)`와 `endSentence()`는 `isLoaded == false`이면 요청을 버린다.
- `NGramPredictiveTextEngine.resetAllData()`는 메모리를 비우고 파일/legacy UserDefaults를 삭제하지만, 이미 진행 중인 background load 또는 save의 후속 반영을 막는 generation 검사가 없다.
- 현재 작업 시작 시 `git status --short`에는 변경 파일이 표시되지 않았다.

## Decisions

- 구현 순서는 P1 텍스트 대치 입력 손상 가능성, P2 lexicon 첫 대치 누락, P2/P3 n-gram 비동기 상태 순으로 둔다.
- 텍스트 대치 suffix finding은 유효한 것으로 본다. 같은 파일 안의 후보 표시 경로가 이미 정확한 current-word 일치를 사용하므로, 자동 대치도 같은 계약으로 맞추는 것이 자연스럽다.
- 대치 복구 이력 finding은 유효한 것으로 본다. 현재 기록에는 원래 위치 anchor가 없어 동일 문구가 다른 위치에 있을 때 구분할 근거가 없다.
- n-gram reset race finding은 유효한 것으로 본다. `resetAllData()`와 background load/save 사이에 세대 검사가 없다.
- n-gram 로딩 전 기록 누락 finding은 유효한 것으로 본다. 기존 SNM-40 문서에도 명시된 open question이고 코드가 요청을 버린다.
- 커서 이동 후 제안 재계산은 후속 작업으로 유지한다. 단, 커서 앞 문맥을 자동완성 조회에는 사용할 수 있지만 n-gram 학습 기록에는 사용하지 않는 방향을 우선한다.
- 2026-06-16 선택 범위 구현에서는 커서 이동 후 제안 재계산을 제외하고, 사용자가 선택한 텍스트 대치/lexicon 로딩/n-gram 로딩·reset 항목을 먼저 처리했다.
- 텍스트 대치 복구는 마지막 대치 이력만 복구 대상으로 삼고, `textWillChange(_:)`에서 복구 이력을 비워 커서/focus/context 변경 뒤 과거 대치 이력이 쓰이지 않도록 했다.
- lexicon 첫 대치 누락은 입력을 block하지 않고, 텍스트 대치가 켜진 경우 `viewDidLoad()`에서 lexicon load를 앞당겨 시작하는 정책으로 처리했다.
- n-gram 로딩 전 입력은 in-memory queue에 보관하고, reset은 generation token으로 오래된 load/save 반영을 차단한다.
- 2026-06-16 커서 이동 후 제안 재계산은 키보드 primary 버튼 커서 드래그가 끝난 시점에 `updateSuggestionsForCursorContext()`를 호출하는 방식으로 처리한다. 넓은 `textDidChange(_:)` fallback은 undo/redo와 focus 전환 부작용을 줄이기 위해 사용하지 않는다.
- 2026-06-16 커서 드래그 중 후보 유지 요구는 아직 구현 전이다. 현재 구현은 드래그 종료 후 재계산을 다루며, 드래그 중 빈 `inputBuffer` 기준 초기 후보 노출을 막는 상태 게이트는 후속 작업으로 남긴다.
- selected text가 있으면 기존처럼 selected text 정책이 우선한다. 문서 컨텍스트 기반 후보를 탭했을 때 실제 문서의 커서 앞 단어를 교체하는 동작은 delete count 안전성 검증이 더 필요해 후속 항목으로 남긴다.

## Hypotheses

- 추정: 대치 복구 이력은 `textWillChange(_:)`에서 `resetInputBuffer()`와 함께 비우면 focus/커서 변경으로 인한 오복구 위험을 크게 줄일 수 있다. 단, 실제 대치 직후 삭제 경로에서 `textWillChange(_:)`가 호출되는지 확인이 필요하다.
- 추정: 대치 복구를 “마지막 기록 1건”으로 제한해도 사용자 기대 동작에는 충분할 가능성이 높다. 과거 여러 대치 이력을 오래 유지하는 기능 요구는 아직 확인되지 않았다.
- 추정: `NGramPredictiveTextEngine` race 테스트를 안정적으로 작성하려면 파일 I/O와 queue를 주입 가능하게 만드는 작은 테스트 seam이 필요할 수 있다.
- 추정: lexicon 준비 전 첫 대치 누락은 실제 `UILexicon` 지연 완료를 테스트하기 어렵기 때문에 `SuggestionController`의 준비 상태/정책 단위 테스트와 수동 확인을 병행해야 할 수 있다.
- 추정: 키보드 자체 커서 드래그 종료 시점에는 `textDocumentProxy.documentContextBeforeInput`이 이동 후 커서 앞 문맥을 반영하므로, 커서 컨텍스트 전용 후보 갱신으로 커서 앞 글자에 맞는 후보를 다시 표시할 수 있다.

## Open Questions

- 텍스트 대치 lexicon이 아직 로딩 중일 때 스페이스 입력을 어떻게 처리할지 최종 UX 정책이 필요하다. 입력을 지연시키지는 않고, 로딩 완료 후 다음 스페이스나 입력 이벤트에서 재평가하는 방향이 입력 지연 위험이 낮다.
- 대치 복구 이력을 커서/focus 변경 시 무효화하는 것만으로 충분한지, 아니면 record 자체에 context anchor를 추가해야 하는지 구현 중 테스트로 결정한다.
- n-gram reset race를 generation token으로 막을지, load/save/reset을 모두 하나의 serial state queue로 모을지 구현 난이도와 테스트 가능성을 비교해야 한다.
- 커서 이동 후 외부 문서 컨텍스트 기반 후보를 보여줄 때 `SuggestionController.lastSuggestionBaseText`와 `inputBuffer`를 어떻게 구분할지 확인이 필요하다.
- 커서 앞 단어 기준 제안을 선택했을 때 replace/delete count가 실제 문서 컨텍스트를 안전하게 수정하는지 별도 확인이 필요하다.
- 커서 드래그 중 후보 유지 구현 시 `textWillChange(_:)`/`textDidChange(_:)`에서 발생하는 후보 초기화만 막고, 일반 focus 전환이나 selected text 변경에서 필요한 clear 동작은 유지해야 한다.

## Verification Notes

- 2026-06-16 실행한 확인 명령:

```sh
git status --short
sed -n '1,220p' dev/README.md
rg --files dev/templates dev
gh issue view 67 --repo SNMac/SYKeyboard --comments
gh api repos/SNMac/SYKeyboard/issues/67
sed -n '1,260p' dev/active/code-review-scope/code-review-scope-findings.md
sed -n '1,240p' dev/active/snm-40-predictive-loading/snm-40-predictive-loading-context.md
sed -n '1,260p' dev/active/snm-40-predictive-loading/snm-40-predictive-loading-plan.md
sed -n '1,260p' dev/codex-skill-playbook.md
sed -n '1,540p' Modules/SYKeyboardCore/Domain/SuggestionController.swift
sed -n '1,430p' Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift
rg -n "SuggestionController|TextReplacement|replacement|NGramPredictiveTextEngine|Mock.*NGram|Lexicon" SYKeyboardTests Modules/SYKeyboardCore -g '*.swift'
sed -n '1,260p' dev/coding-conventions.md
```

- `gh issue view` 실패는 GitHub CLI GraphQL query의 classic Projects 필드 오류이며, `gh api` 직접 조회로 우회했다.
- 아직 테스트/빌드는 실행하지 않았다. 이 문서는 구현 전 수정 계획 산출물이다.
- 2026-06-16 사용자 추가 요청으로 커서 이동 후 커서 앞 글자 기준 자동완성 제안 재계산 계획을 추가했다.
- 2026-06-16 선택 범위 구현 후 focused 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

- 결과: 권한 있는 환경에서 `** TEST SUCCEEDED **`.
- 테스트 대상은 iPhone 13 mini / iOS 16.0 시뮬레이터다. Xcode가 연결된 물리 기기의 passcode 관련 경고를 출력했지만, focused 테스트 결과는 성공으로 종료됐다.
- 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`/`EnglishKeyboard` 개별 scheme 빌드는 아직 별도 실행하지 않았다.
- 2026-06-16 커서 이동 후 제안 재계산 focused 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests

xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

- 결과: 구현 전 `TextInteractionGestureControllerTests.test취소된Pan_다른현재버튼보존()`에서 RED 실패를 확인했고, 구현 후 권한 있는 환경에서 두 focused suite 모두 `** TEST SUCCEEDED **`를 확인했다.
- Xcode가 연결된 물리 기기의 passcode 관련 경고를 출력했지만, 테스트 대상은 iPhone 13 mini / iOS 16.0 시뮬레이터였고 테스트 결과는 성공으로 종료됐다.
