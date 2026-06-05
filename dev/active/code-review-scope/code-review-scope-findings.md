# Code Review Scope Findings

Last Updated: 2026-06-06

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

## Handoff

- Track 2부터 각 리뷰 채팅의 findings는 이 문서의 `## Findings` 아래에 트랙별 섹션으로 추가한다.
- 각 finding은 우선순위, 상태, 위치, 영향, 근거, 제안 또는 처리, 검증을 포함한다.
- 다른 트랙으로 넘길 내용은 해당 트랙 섹션 끝에 `Handoff` 항목으로 남긴다.
- Track 1의 나랏글 이중모음 교차 입력 동작은 사용자 확인으로 의도된 동작으로 정리했다.
