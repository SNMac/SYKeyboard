# Keyboard Lifecycle·Auto Layout Crash Prevention Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 키보드 표시·크기 전환 중 document proxy reset 및 숨김 arranged subview 제약 충돌로 발생할 수 있는 크래시 경로를 제거한다.

**Architecture:** `BaseKeyboardViewController`는 host 입력 trait를 `textWillChange(_:)`/`textDidChange(_:)`에서만 동기화하고, 표시 정책과 높이 계산은 캐시된 값을 사용한다. 숨김 가능한 arranged subview의 기존 nonzero 크기 제약은 priority `999`로 내려 UIKit의 required 숨김 제약과 충돌하지 않게 한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+

## Global Constraints

- iOS 16+ 지원과 현재 Swift/UIKit 구조를 유지한다.
- 한글·영문 입력, 버튼 이벤트 타이밍, 자동완성 표시 조건을 변경하지 않는다.
- 키보드 높이와 영문 특수 키의 현재 너비 비율을 유지한다.
- `DeleteButton`, 한글 processor/automata, suggestion 엔진은 변경하지 않는다.
- UI private 구조나 exact visual 값을 고정하는 테스트를 추가하지 않는다.
- 각 step은 코드·검증·계획 결과 기록을 함께 하나의 커밋으로 남긴다.

---

### Step 1: document proxy trait 접근을 callback 경계로 제한

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-08-10-keyboard-lifecycle-autolayout-crash.md`

**Interfaces:**
- `KeyboardPresentationStatePolicy.shouldHideSuggestionBar(isPredictiveTextEnabled:autocorrectionType:currentKeyboard:)`는 optional `UITextAutocorrectionType?`을 받고 `nil`을 `.default`와 동일하게 처리한다.
- `BaseKeyboardViewController`는 마지막으로 callback에서 관찰한 optional autocorrection type을 보관한다.
- `setKeyboardHeight()`와 `updateSuggestionBarHidden()`은 `textDocumentProxy` 대신 캐시를 사용한다.

- [x] 테스트에 `autocorrectionType: nil`일 때 predictive text가 켜진 일반 키보드는 suggestion bar를 표시한다는 기대를 추가하고, production signature 변경 전 컴파일 실패를 확인한다.
- [x] policy가 optional trait의 `nil`을 `.default`로 처리하도록 최소 변경한다.
- [x] `textWillChange(_:)`/`textDidChange(_:)`에서 캐시를 갱신하고, `viewDidLoad`/`viewWillAppear` 경로의 직접 `autocorrectionType` 접근을 제거한다.
- [x] 관련 policy 테스트를 실행해 통과를 확인한다.
- [x] 이 step의 체크박스와 실제 명령·결과를 아래 결과란에 기록한다.
- [x] `fix: 키보드 표시 전 document proxy 접근 제거`로 이 step 변경만 커밋한다.

**Verification command:**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

**Result:**

- RED: production 변경 전 test build가
  `'nil' is not compatible with expected argument type 'UITextAutocorrectionType'`로
  실패했다(`xcodebuild` exit 65).
- GREEN: iPhone 13 mini / iOS 16.0에서
  `KeyboardPresentationStatePolicyTests` 고유 테스트 6개가 통과했다
  (`xcodebuild` exit 0).
- xcresult:
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.10_20-45-13-+0900.xcresult`

### Step 2: 숨김 arranged subview 크기 제약 충돌 제거

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
- Modify: `docs/superpowers/plans/2026-08-10-keyboard-lifecycle-autolayout-crash.md`

**Interfaces:**
- `suggestionBarView`의 nonzero 높이 제약은 visible 상태의 크기를 유지하면서 priority `999`를 사용한다.
- `atButton`, `periodButton`, `slashButton`, `dotComButton`의 너비 제약은 생성·재생성 시 모두 priority `999`를 사용한다.
- stack distribution, arranged subview 순서, `isHidden` 전환 API는 변경하지 않는다.

- [ ] 숨김 가능한 다섯 뷰의 크기 제약 생성 위치를 재확인한다.
- [ ] 대상 높이·너비 제약만 priority `999`로 설정한다.
- [ ] `KeyboardHeightPolicyTests`와 `KeyboardPresentationStatePolicyTests`를 실행해 기존 표시·높이 계약을 확인한다.
- [ ] `EnglishKeyboard`와 `HangeulKeyboard`를 빌드해 양쪽 layout 코드를 확인한다.
- [ ] 이 step의 체크박스와 실제 명령·결과를 아래 결과란에 기록한다.
- [ ] `fix: 숨김 키보드 뷰의 크기 제약 충돌 방지`로 이 step 변경만 커밋한다.

**Verification commands:**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

**Result:** 실행 전

### Step 3: 전체 회귀 검증 및 결과 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-08-10-keyboard-lifecycle-autolayout-crash.md`

- [ ] `SYKeyboard` 전체 테스트를 실행하고 테스트 개수·통과 여부를 기록한다.
- [ ] `HangeulKeyboard`, `EnglishKeyboard`, `SYKeyboard` scheme을 빌드하고 결과를 기록한다.
- [ ] 가능한 Simulator에서 키보드 표시·필드 전환·회전과 Auto Layout 경고를 확인하고, 관찰하지 못한 항목은 차단 경로를 기록한다.
- [ ] `git diff --check`와 `git status --short`로 변경 범위를 확인한다.
- [ ] 이 step의 체크박스와 실제 명령·산출물 경로를 아래 결과란에 기록한다.
- [ ] `docs: 키보드 크래시 수정 검증 결과 기록`으로 검증 문서만 커밋한다.

**Verification commands:**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

**Result:** 실행 전
