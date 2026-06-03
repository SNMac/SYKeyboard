# Hangeul Controller Domain Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한글 controller/simulator의 중복 버퍼 전이를 순수 도메인 상태 타입으로 옮기고 suggestion/undo 도메인 테스트를 보강한다.

**Architecture:** `HangeulCompositionState`가 상태 전이를 계산하고, controller는 proxy 반영과 UI side effect를 수행한다. Base/action registration과 gesture dispatch는 이번 작업에서 변경하지 않는다.

**Tech Stack:** Swift 5, Swift Testing, Xcode project synchronized root, iOS Simulator `iPhone 13 mini / iOS 16.0`.

---

### Task 1: Active Task Docs

**Files:**
- Create: `dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-plan.md`
- Create: `dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-context.md`
- Create: `dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-tasks.md`

- [ ] **Step 1: Write docs**

Record the approved scope, relevant files, risks, and verification commands.

- [ ] **Step 2: Verify docs**

Run:

```sh
git diff --check -- docs/superpowers dev/active/hangeul-controller-domain-stabilization
git status --short --untracked-files=all
```

Expected: no whitespace errors and only intended docs are dirty.

- [ ] **Step 3: Commit**

```sh
git add docs/superpowers/specs/2026-06-03-hangeul-controller-domain-stabilization-design.md \
  docs/superpowers/plans/2026-06-03-hangeul-controller-domain-stabilization.md \
  dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-plan.md \
  dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-context.md \
  dev/active/hangeul-controller-domain-stabilization/hangeul-controller-domain-stabilization-tasks.md
git commit -m "docs: #31 - 한글 controller 도메인 안정화 계획 추가"
```

### Task 2: HangeulCompositionState RED/GREEN

**Files:**
- Create: `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
- Create: `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` if synchronized root membership exceptions require the new source path.

- [ ] **Step 1: Write failing tests**

Create tests for:
- input applies `CompositionResult` into committed/composing.
- space commit protects committed text.
- delete from composing consumes committed tail.
- repeat delete pulls committed Hangeul into composing after finish.
- delete touchDown plus pan delete restores the original character only once.

- [ ] **Step 2: Verify RED**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

Expected: compile failure because `HangeulCompositionState` is not defined.

- [ ] **Step 3: Implement minimal state type**

Implement `HangeulCompositionState` with value-state properties and methods mirroring current simulator/controller behavior. Keep proxy side effects out of this type.

- [ ] **Step 4: Verify GREEN**

Run the same targeted test. Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```sh
git add Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift \
  SYKeyboardTests/Domain/HangeulCompositionStateTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj
git commit -m "refactor: #31 - 한글 조합 상태 전이 타입 추가"
```

### Task 3: Simulator Uses HangeulCompositionState

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
- Test: `SYKeyboardTests/Controller/*ControllerTests.swift`
- Test: `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`

- [ ] **Step 1: Replace duplicate state**

Move simulator state reads/writes through `HangeulCompositionState`. Keep simulator public API unchanged.

- [ ] **Step 2: Verify controller simulator tests**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DubeolsikControllerTests \
  -only-testing:SYKeyboardTests/NaratgeulControllerTests \
  -only-testing:SYKeyboardTests/CheonjiinControllerTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

Expected: `TEST SUCCEEDED`.

- [ ] **Step 3: Commit**

```sh
git add SYKeyboardTests/Utils/KeyboardControllerSimulator.swift
git commit -m "refactor: #31 - controller simulator 상태 전이 공유"
```

### Task 4: Hangeul Controller Uses HangeulCompositionState

**Files:**
- Modify: `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- Test: controller tests and full `SYKeyboard` tests.

- [ ] **Step 1: Refactor controller state**

Replace duplicated buffer fields with `HangeulCompositionState`. Preserve all Base hook overrides and call order.

- [ ] **Step 2: Preserve proxy side effects**

Map state transition mutations to the existing `insertText`, `replaceText`, and `deleteText` calls with the same delete counts.

- [ ] **Step 3: Verify focused tests**

Run the controller simulator test bundle from Task 3. Expected: `TEST SUCCEEDED`.

- [ ] **Step 4: Commit**

```sh
git add Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift
git commit -m "refactor: #31 - 한글 controller 상태 전이 공유"
```

### Task 5: Suggestion/Undo Domain Test Stabilization

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
- Modify production policy/manager only if a RED test exposes an actual gap.

- [ ] **Step 1: Add RED tests for domain gaps**

Add tests for:
- selected text containing newline clears suggestions.
- undo/redo target context survives pending group commit.
- redo is cleared when new replacement is recorded after undo.

- [ ] **Step 2: Verify RED**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

Expected: at least one new test fails before production adjustment, or document that the added tests are coverage-only because behavior already exists.

- [ ] **Step 3: Implement minimal fixes if needed**

Only change production code if RED exposes a missing behavior. Do not introduce suggestion coordinator or Base changes.

- [ ] **Step 4: Verify GREEN**

Run the same targeted test. Expected: `TEST SUCCEEDED`.

- [ ] **Step 5: Commit**

```sh
git add SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift \
  SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift
git commit -m "test: #31 - suggestion undo 도메인 경계 보강"
```

### Task 6: Final Verification

**Files:**
- Modify: `dev/active/hangeul-controller-domain-stabilization/*`

- [ ] **Step 1: Run full tests**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `TEST SUCCEEDED`.

- [ ] **Step 2: Update active docs**

Record test results, commits, and remaining risks.

- [ ] **Step 3: Commit docs**

```sh
git add dev/active/hangeul-controller-domain-stabilization
git commit -m "docs: #31 - 한글 controller 안정화 결과 기록"
```
