# Issue 64 Cheonjiin Delete Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 천지인 Processor의 완성형 한글 삭제와 비표준 모음 복원 경로를 production 동작 변경 없이 회귀 테스트로 보호한다.

**Architecture:** 기존 `CheonjiinProcessorTests`와 `HangeulProcessorTestable` 헬퍼를 재사용한다. 완성형 전체 삭제는 글자 구조 기반 예상 삭제 횟수로 검증하고, 비표준 모음 및 committed 복원 계약은 Processor 직접 호출 매트릭스로 분리한다.

**Tech Stack:** Swift 5, Swift Testing, Xcode 16, iOS 16 Simulator

---

### Task 1: 천지인 고유 삭제 계약 검증

**Files:**
- Modify: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`

- [ ] **Step 1: 비표준 모음 composing 삭제 테스트를 추가한다**

`ㆍ`, `ᆢ`, `간ㆍ`, `간ᆢ`에서 삭제 후 기대 composing을 검증한다.

- [ ] **Step 2: committed 비표준 모음 복원 매트릭스를 추가한다**

`committedTail`, `remaining`, `isProtected`, 예상 `composing`, 예상 `consumedCommittedCount`를 매트릭스로 검증한다.

- [ ] **Step 3: targeted 테스트를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CheonjiinProcessorTests
```

Expected: `TEST SUCCEEDED`

### Task 2: 천지인 11,172자 전체 삭제 검증

**Files:**
- Modify: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`

- [ ] **Step 1: 구조 기반 예상 삭제 횟수 helper를 추가한다**

초성 1회, 중성 분해 단계, 종성 단일/겹받침 단계를 더해 삭제 횟수를 반환한다.

- [ ] **Step 2: heavy test 생성 성공 후 삭제 루프를 추가한다**

생성 실패 문자는 `continue`하고, 예상 삭제 횟수 후 잔여물이 없어야 한다.

- [ ] **Step 3: 임시 production mutation으로 테스트 실패를 확인한다**

천지인 삭제의 겹받침 또는 비표준 모음 경로를 임시 변경해 새 테스트가 실패하는지 확인하고 즉시 복구한다.

- [ ] **Step 4: targeted 테스트를 다시 실행한다**

Expected: `TEST SUCCEEDED`

### Task 3: 전체 검증과 findings 갱신

**Files:**
- Modify: `dev/active/code-review-scope/code-review-scope-findings.md`
- Modify: `dev/active/issue-64-cheonjiin-delete-tests/issue-64-cheonjiin-delete-tests-context.md`
- Modify: `dev/active/issue-64-cheonjiin-delete-tests/issue-64-cheonjiin-delete-tests-tasks.md`

- [ ] **Step 1: 전체 테스트를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `TEST SUCCEEDED`

- [ ] **Step 2: findings를 Resolved로 갱신한다**

추가한 테스트 범위와 실제 검증 결과를 기록한다.

- [ ] **Step 3: 변경 범위를 확인한다**

Run:

```sh
git status --short
git diff --check
```

Expected: production Swift 파일 변경 없음, whitespace 오류 없음
