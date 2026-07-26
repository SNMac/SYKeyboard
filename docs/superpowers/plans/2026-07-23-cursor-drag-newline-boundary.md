# 커서 드래그 줄바꿈 경계 이동 수정 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 줄바꿈 직전에서 오른쪽 커서 드래그가 다음 줄로 이동하게 하고, 실제 커서 이동이 확인된 경우에만 햅틱을 재생한다.

**Architecture:** `CursorDragAccelerationPolicy`가 오른쪽 문맥을 확인할 수 없는 경계에서 UIKit에 1칸 이동을 요청하도록 한다. `adjustTextPosition(byCharacterOffset:)`는 성공 여부를 반환하지 않으므로 즉시 햅틱을 제거하고, primary 커서 드래그 중 `textDidChange(_:)`가 발생했을 때만 `KeyboardGesturePolicy`를 통해 햅틱을 재생한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, XcodeBuildMCP

## Global Constraints

- iOS 16+와 Swift 5 프로젝트 구조를 유지한다.
- 좌우 일반 문자 구간의 step 제한과 최대 4칸 가속은 변경하지 않는다.
- 삭제 버튼 드래그 삭제/복구 동작은 변경하지 않는다.
- `selectionWillChange(_:)`와 `selectionDidChange(_:)` 호출에 의존하지 않는다.
- 각 작업은 RED 실패를 확인한 뒤 최소 구현으로 GREEN을 만들고 별도 커밋한다.

---

### Task 1: 오른쪽 문맥이 없는 경계에서 1칸 이동 요청

**Files:**
- Modify: `SYKeyboardTests/Utils/CursorDragAccelerationPolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift`

**Interfaces:**
- Consumes: `CursorDragAccelerationPolicy.applicableSteps(to:requestedSteps:documentContextBeforeInput:documentContextAfterInput:)`
- Produces: 오른쪽 문맥이 `nil` 또는 빈 문자열이고 요청 step이 양수이면 `1`

- [x] **Step 1: 오른쪽 빈 문맥과 nil 문맥의 실패 테스트 추가**

```swift
@Test("오른쪽 문맥이 빈 문자열이면 경계 이동을 위해 1칸 요청")
func test오른쪽커서이동_빈문맥_1Step() {
    let steps = CursorDragAccelerationPolicy.applicableSteps(
        to: .right,
        requestedSteps: 4,
        documentContextBeforeInput: "가",
        documentContextAfterInput: ""
    )

    #expect(steps == 1)
}

@Test("오른쪽 문맥이 nil이면 경계 이동을 위해 1칸 요청")
func test오른쪽커서이동_nil문맥_1Step() {
    let steps = CursorDragAccelerationPolicy.applicableSteps(
        to: .right,
        requestedSteps: 4,
        documentContextBeforeInput: "가",
        documentContextAfterInput: nil
    )

    #expect(steps == 1)
}
```

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CursorDragAccelerationPolicyTests
```

Expected: 두 신규 테스트가 기존 반환값 `0` 때문에 실패한다.

- [x] **Step 3: 오른쪽 문맥 미제공 경계의 최소 구현**

`CursorDragAccelerationPolicy.applicableSteps`의 `.right` 분기를 다음과 같이 변경한다.

```swift
case .right:
    guard let documentContextAfterInput,
          !documentContextAfterInput.isEmpty else { return 1 }
    return min(requestedSteps, documentContextAfterInput.prefix(requestedSteps).count)
```

- [x] **Step 4: 집중 테스트를 다시 실행해 GREEN 확인**

Run: Step 2와 동일한 명령

Expected: `CursorDragAccelerationPolicyTests` 전체 통과

- [x] **Step 5: 작업 커밋**

```sh
git add \
  SYKeyboardTests/Utils/CursorDragAccelerationPolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift
git commit -m "fix: #102 - 줄바꿈 경계 오른쪽 커서 이동 허용"
```

### Task 2: 실제 커서 이동 callback에서만 햅틱 재생

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`

**Interfaces:**
- Produces: `KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(isPrimaryCursorDragging:) -> Bool`
- Consumes: `BaseKeyboardViewController.isPrimaryCursorDragging`, `UIInputViewController.textDidChange(_:)`

- [x] **Step 1: 커서 드래그 상태별 햅틱 정책 실패 테스트 추가**

```swift
@Test("textDidChange 커서 햅틱은 primary 커서 드래그 중에만 재생")
func testTextDidChange커서햅틱조건() {
    #expect(
        KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
            isPrimaryCursorDragging: true
        )
    )
    #expect(
        KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
            isPrimaryCursorDragging: false
        ) == false
    )
}
```

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests
```

Expected: `shouldPlayCursorDragHapticOnTextDidChange`가 없어 컴파일 실패

- [x] **Step 3: 햅틱 정책 최소 구현**

`KeyboardGesturePolicy`에 다음 메서드를 추가한다.

```swift
static func shouldPlayCursorDragHapticOnTextDidChange(
    isPrimaryCursorDragging: Bool
) -> Bool {
    return isPrimaryCursorDragging
}
```

- [x] **Step 4: controller의 햅틱 재생 시점 변경**

`BaseKeyboardViewController.textDidChange(_:)`에서 다음 조건으로 강제 햅틱을 재생한다.

```swift
if KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
    isPrimaryCursorDragging: isPrimaryCursorDragging
) {
    FeedbackManager.shared.playHaptic(isForcing: true)
}
```

`moveCursorIfPossible(to:steps:)`의 `adjustTextPosition` 직후에 있던 다음 코드를 제거한다.

```swift
FeedbackManager.shared.playHaptic(isForcing: true)
```

- [x] **Step 5: 집중 테스트를 다시 실행해 GREEN 확인**

Run: Step 2와 동일한 명령

Expected: `KeyboardGesturePolicyTests` 전체 통과

- [x] **Step 6: 작업 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
git commit -m "fix: #102 - 실제 커서 이동 시 햅틱 재생"
```

### Task 3: 전체 회귀 검증

**Files:**
- Modify: 없음
- Test: `SYKeyboardTests`

**Interfaces:**
- Consumes: Task 1과 Task 2의 커밋
- Produces: 전체 테스트 및 양쪽 키보드 extension 빌드 결과

- [x] **Step 1: `SYKeyboard` 전체 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 실패 0건

Result: iPhone 13 mini / iOS 16.0에서 258개 통과, 실패 0건

- [x] **Step 2: 한글 키보드 extension 빌드**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 빌드 성공

Result: iPhone 13 mini / iOS 16.0에서 빌드 성공

- [x] **Step 3: 영문 키보드 extension 빌드**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 빌드 성공

Result: iPhone 13 mini / iOS 16.0에서 빌드 성공

- [x] **Step 4: 변경 범위와 공백 오류 확인**

```sh
git diff --check
git status --short
git log --oneline -3
```

Expected: #102 관련 파일만 변경되고 공백 오류가 없다.

Result: #102 관련 코드·테스트·설계·계획 문서만 변경되었고 공백 오류가 없음

### Task 4: 리뷰 반영 — 실제 문맥 변경 확인

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md`

**Interfaces:**
- Consumes: 이동 요청 직전과 `textDidChange(_:)` 시점의 `KeyboardTextContextSnapshot`
- Produces: primary 커서 드래그 중 pending 요청이 있고 정규화된 문맥이 달라졌을 때만 `true`

- [x] **Step 1: 문맥 변경 여부에 따른 햅틱 실패 테스트 추가**

`KeyboardGesturePolicyTests`에서 다음 조건을 검증한다.

```swift
let requestContext = KeyboardTextContextSnapshot(
    beforeInput: "가",
    afterInput: ""
)
let movedContext = KeyboardTextContextSnapshot(
    beforeInput: "가\n",
    afterInput: ""
)

#expect(
    KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
        isPrimaryCursorDragging: true,
        pendingRequestContext: requestContext,
        currentContext: movedContext
    )
)
#expect(
    KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
        isPrimaryCursorDragging: true,
        pendingRequestContext: requestContext,
        currentContext: requestContext
    ) == false
)
#expect(
    KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
        isPrimaryCursorDragging: true,
        pendingRequestContext: nil,
        currentContext: movedContext
    ) == false
)
#expect(
    KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
        isPrimaryCursorDragging: false,
        pendingRequestContext: requestContext,
        currentContext: movedContext
    ) == false
)
```

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardGesturePolicyTests
```

Expected: 기존 햅틱 정책 메서드가 문맥 인자를 받지 않아 컴파일 실패

- [x] **Step 3: 문맥 비교 정책과 pending 요청 상태 구현**

- `KeyboardGesturePolicy`는 primary 커서 드래그 중이고 pending 요청 문맥이 있으며, `nil`과 빈 문자열을 동일하게 정규화한 전후 문맥이 달라졌을 때만 햅틱을 허용한다.
- `BaseKeyboardViewController`는 실제 이동 요청 직전에 현재 문맥을 저장하고, `textDidChange(_:)`에서 현재 문맥과 비교한 뒤 pending 상태를 소비한다.

- [x] **Step 4: 설계 문서에 실제 문맥 비교 조건 반영**

햅틱 성공 조건을 “primary 커서 드래그 중 callback 발생”에서 “pending 이동 요청이 있고 callback 시점 문맥이 이동 전 문맥과 다름”으로 강화한다.

- [x] **Step 5: 집중 테스트를 다시 실행해 GREEN 확인**

Run: Step 2와 동일한 명령

Expected: `KeyboardGesturePolicyTests` 전체 통과

Result: 기존 시그니처에서 컴파일 실패를 확인한 뒤 9개 통과, 실패 0건

- [x] **Step 6: 리뷰 반영 작업 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md \
  docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md
git commit -m "fix: #102 - 커서 이동 문맥 변경 시 햅틱 재생"
```

### Task 5: 리뷰 반영 후 최종 회귀 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md`
- Test: `SYKeyboardTests`

- [x] **Step 1: `SYKeyboard` 전체 테스트 재실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 실패 0건

Result: iPhone 13 mini / iOS 16.0에서 259개 통과, 실패 0건

- [x] **Step 2: 한글·영문 키보드 extension 재빌드**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 scheme 모두 빌드 성공

Result: iPhone 13 mini / iOS 16.0에서 두 scheme 모두 빌드 성공

- [x] **Step 3: 최종 변경 범위와 작업 트리 확인**

```sh
git diff --check origin/develop...HEAD
git status --short
git log --oneline -8
```

Expected: #102 관련 변경만 존재하고 공백 오류가 없다.

Result: #102 관련 7개 파일만 변경되었고 공백 오류가 없음

- [x] **Step 4: 최종 검증 기록 커밋**

```sh
git add docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md
git commit -m "docs: #102 - 리뷰 반영 후 최종 검증 기록"
```

### Task 6: 줄바꿈 경계 반복 삭제와 실제 삭제 피드백

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md`

**Interfaces:**
- Produces: `KeyboardTextInteractionPolicy.repeatDeleteAction(documentContextBeforeInput:selectedText:hasPendingBoundaryRequest:)`
- Produces: `KeyboardTextInteractionPolicy.didCompletePendingRepeatDelete(isRepeatingInput:pendingRequestContext:currentContext:)`
- Consumes: 반복 삭제 요청 직전과 `textDidChange(_:)` 시점의 `KeyboardTextContextSnapshot`

- [x] **Step 1: 반복 삭제 경계 동작의 실패 테스트 추가**

다음 동작을 `KeyboardTextInteractionPolicyTests`에서 검증한다.

- 커서 앞 문맥이나 선택 텍스트가 있으면 즉시 삭제와 피드백을 수행한다.
- 앞 문맥이 `nil` 또는 빈 문자열이고 pending 요청이 없으면 피드백 없는 경계 삭제를 한 번 요청한다.
- 경계 삭제 확인을 기다리는 동안 추가 삭제를 요청하지 않는다.
- pending 요청 전후 문맥이 실제로 달라진 callback에서만 삭제 피드백을 허용한다.
- 문맥 변화 없음, 반복 입력 종료, pending 요청 없음에서는 피드백을 허용하지 않는다.
- 문맥의 `nil`과 빈 문자열 차이만으로는 삭제 성공으로 판단하지 않는다.
- 삭제 버튼 최초 `touchDown`의 누름 피드백은 기존 동작을 유지하고 반복 tick의 피드백만 실제 삭제 여부로 제한한다.

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: 신규 반복 삭제 action과 완료 판정 API가 없어 컴파일 실패

Result: 신규 API가 없어 `KeyboardTextInteractionPolicyTests` 컴파일 실패 확인

- [x] **Step 3: 반복 삭제 action과 완료 판정 정책 구현**

```swift
enum RepeatDeleteAction: Equatable {
    case deleteWithImmediateFeedback
    case deleteAwaitingTextChange
    case waitForTextChange
}
```

- 선택 텍스트나 비어 있지 않은 앞 문맥이 있으면 `.deleteWithImmediateFeedback`
- 문맥을 확인할 수 없고 pending 요청이 없으면 `.deleteAwaitingTextChange`
- pending 요청이 있으면 `.waitForTextChange`
- 완료 판정은 반복 입력 중 pending 요청 문맥과 현재 문맥이 실제로 달라진 경우에만 `true`

- [x] **Step 4: controller에서 경계 삭제 요청과 지연 피드백 연결**

- `.deleteWithImmediateFeedback`: 기존처럼 반복 삭제 후 `button.playFeedback()`
- `.deleteAwaitingTextChange`: 요청 직전 문맥을 저장하고 반복 삭제하되 즉시 피드백하지 않음
- `.waitForTextChange`: 추가 삭제와 피드백 없이 callback을 기다림
- `textDidChange(_:)`: 실제 문맥 변경을 확인하면 삭제 햅틱·사운드를 재생하고 pending 상태를 소비
- 반복 입력 종료 시 pending 상태를 초기화
- 단일 삭제와 최초 `touchDown` 피드백 경로는 변경하지 않음

- [x] **Step 5: 설계 문서에 반복 삭제 경계와 피드백 조건 반영**

반복 삭제도 커서 이동과 동일하게 문맥 미제공 경계에서 한 번 요청하고, 실제 문맥 변경이 확인된 경우에만 피드백을 재생한다고 기록한다.

- [x] **Step 6: 집중 테스트를 다시 실행해 GREEN 확인**

Run: Step 2와 동일한 명령

Expected: `KeyboardTextInteractionPolicyTests` 전체 통과

Result: iPhone 13 mini / iOS 16.0에서 9개 통과, 실패 0건

- [x] **Step 7: 작업 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md \
  docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md
git commit -m "fix: #102 - 줄바꿈 경계 반복 삭제 유지"
```

### Task 7: 반복 삭제 pending 수명과 삭제 형태 검증

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- Modify: `docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md`

- [x] **Step 1: 코드 검토에서 발견한 회귀 위험 기록**

- 비정상 반복 종료 후 pending 상태가 다음 반복 세션을 막지 않아야 한다.
- pending 중 외부 편집이나 커서 문맥 변경을 삭제 성공으로 오인하지 않아야 한다.
- 한글 키보드의 long press 인식 시 첫 반복 삭제도 실제 삭제가 확인된 경우에만 피드백해야 한다.

- [x] **Step 2: 삭제 형태가 아닌 문맥 변경의 실패 테스트 추가**

- 뒤 문맥만 바뀐 경우 피드백을 허용하지 않는다.
- 앞·뒤 문맥이 모두 바뀐 경우 피드백을 허용하지 않는다.
- 뒤 문맥은 유지되고 앞 문맥만 바뀐 경우에만 경계 삭제 완료로 판단한다.

- [x] **Step 3: 집중 테스트를 실행해 RED 확인**

Expected: 기존 완료 판정이 뒤 문맥 변경도 성공으로 판단해 실패

Result: 뒤 문맥만 변경된 경우와 앞·뒤 문맥이 모두 변경된 경우가 `true`여서 1개 테스트 실패 확인

- [x] **Step 4: pending 수명과 삭제 형태 판정 보완**

- 반복 시작 전 기존 pending 상태를 방어적으로 초기화한다.
- view 소멸 및 타이머의 비정상 종료 경로에서도 반복 상태와 pending을 함께 종료한다.
- 경계 삭제 완료는 정규화된 뒤 문맥이 같고 앞 문맥만 달라진 경우로 제한한다.
- 한글 키보드의 첫 반복 삭제도 동일한 즉시·지연 피드백 정책으로 처리한다.

- [x] **Step 5: 설계 문서 보완**

- 반복 세션 종료·중단 시 pending 초기화 조건과 삭제 형태 판정 조건을 기록한다.

- [x] **Step 6: 집중 테스트 GREEN 확인**

Expected: `KeyboardTextInteractionPolicyTests` 9개 통과

Result: iPhone 13 mini / iOS 16.0에서 9개 통과, 실패 0건. 변경된 한글 키보드 extension 빌드 성공

- [x] **Step 7: 검토 보완 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
  docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md \
  docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md
git commit -m "fix: #102 - 반복 삭제 pending 상태 정리"
```

### Task 8: 반복 삭제 수정 최종 검증

- [x] **Step 1: `SYKeyboard` 전체 테스트**

Result: iPhone 13 mini / iOS 16.0에서 263개 통과, 실패 0건

- [x] **Step 2: 한글·영문 키보드 extension 빌드**

Result: iPhone 13 mini / iOS 16.0에서 두 scheme 모두 빌드 성공

- [x] **Step 3: 코드 재검토**

Result: pending 수명, 삭제 형태 판정, 한글 첫 반복 삭제 피드백 보완 후 Critical/Important 이슈 없음

- [x] **Step 4: 변경 범위와 공백 오류 확인**

```sh
git diff --check
git status --short
git log --oneline -5
```

Expected: 검증 문서 외 변경이 없고 공백 오류가 없다.

- [x] **Step 5: 실제 입력 앱 수동 검증**

다음 항목은 실제 키보드 extension을 활성화한 입력 앱에서 확인한다.

- 줄 간 커서 이동을 반복한 뒤 삭제 버튼 long press가 줄바꿈을 넘어 계속 삭제한다.
- 최초 `touchDown`에는 항상 피드백이 있다.
- long press 인식 이후에는 실제 삭제가 발생한 경우에만 사운드·햅틱이 있다.
- 문서 시작에서는 long press 반복 피드백이 추가로 발생하지 않는다.

Result: 자동화 환경에서는 실제 키보드 extension의 입력 앱 동작과 햅틱을 확인하지 못해 수동 검증 필요

- [x] **Step 6: 최종 검증 기록 커밋**

```sh
git add docs/superpowers/plans/2026-07-23-cursor-drag-newline-boundary.md
git commit -m "docs: #102 - 반복 삭제 수정 검증 기록"
```
