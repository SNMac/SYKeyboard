# Landscape One-Handed Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 가로 화면에서 한 손 키보드 모드를 일시적으로 중앙 표시하고 세로 복귀 시 저장 모드를 자동 복원한다.

**Architecture:** 순수 표시 정책이 저장 모드와 화면 방향으로 실제 표시 모드를 결정한다. `BaseKeyboardViewController`는 방향 상태와 표시 갱신을 관리하며 저장 설정은 변경하지 않는다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode iOS Simulator

---

### Task 1: 표시 모드 정책

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
- Create: `SYKeyboardTests/Utils/OneHandedKeyboardPresentationPolicyTests.swift`

- [ ] **Step 1: Write the failing tests**

세로에서 저장 모드를 유지하고 가로에서 `.center`를 반환하며, 같은 저장 모드로 다시 세로를 계산하면 원래 모드가 복원되는 테스트를 작성한다.

- [ ] **Step 2: Run focused tests to verify RED**

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -enableCodeCoverage NO \
  -only-testing:SYKeyboardTests/OneHandedKeyboardPresentationPolicyTests
```

Expected: 표시 모드 정책이 없어 컴파일 실패한다.

- [ ] **Step 3: Implement the minimal policy**

`KeyboardPresentationStatePolicy.displayedOneHandedMode(storedMode:isPortrait:)`를 추가해 세로에서는 `storedMode`, 가로에서는 `.center`를 반환한다.

- [ ] **Step 4: Run focused tests to verify GREEN**

Task 1 Step 2 명령을 다시 실행하고 exit code 0을 확인한다.

### Task 2: 실제 표시와 회전 경로 연결

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`

- [ ] **Step 1: Add controller orientation state**

`isPortraitLayout`을 추가하고 최초 표시 및 `viewWillTransition(to:with:)`에서 갱신한다.

- [ ] **Step 2: Apply displayed mode**

`updateOneHandModekeyboard()`가 정책이 반환한 표시 모드로 chevron과 `KeyboardView`를 갱신하도록 한다. 저장 모드 getter/setter는 변경하지 않는다.

- [ ] **Step 3: Disable landscape selection interaction**

가로에서는 한 손 모드 pan/long press handler를 조기에 종료하고, 가로 전환 시 모든 키보드 레이아웃의 한 손 모드 선택 overlay를 숨긴다.

- [ ] **Step 4: Remove redundant orientation width behavior**

`KeyboardView`는 컨트롤러가 전달한 표시 모드만 기준으로 너비 제약을 활성화하며 화면 방향을 직접 판정하지 않도록 정리한다.

### Task 3: 문서와 회귀 검증

**Files:**
- Modify: `dev/active/issue-66-keyboard-layout-findings/issue-66-keyboard-layout-findings-context.md`
- Modify: `dev/active/issue-66-keyboard-layout-findings/issue-66-keyboard-layout-findings-plan.md`
- Modify: `dev/active/issue-66-keyboard-layout-findings/issue-66-keyboard-layout-findings-tasks.md`
- Modify: `dev/active/code-review-scope/code-review-scope-findings.md`

- [ ] **Step 1: Run full tests**

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -enableCodeCoverage NO
```

Expected: exit code 0.

- [ ] **Step 2: Build both extensions sequentially**

```sh
xcodebuild build -quiet -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -quiet -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: both commands exit code 0.

- [ ] **Step 3: Update active docs**

사용자 결정, 구현 결과, 자동 검증 결과, 남은 수동 검증을 기록한다.

- [ ] **Step 4: Check final diff**

```sh
git diff --check HEAD
git status --short
```

Expected: whitespace 오류가 없고 무관한 사용자 변경은 유지된다.
