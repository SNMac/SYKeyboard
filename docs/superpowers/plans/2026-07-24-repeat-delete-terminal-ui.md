# 반복 삭제 종료 UI 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 줄바꿈 경계 반복 삭제는 유지하면서, 삭제 요청이 수행되지 않으면 한글·영문 삭제 버튼을 눌리지 않은 UI로 되돌리고 `touchDown` 이후 추가 피드백을 재생하지 않는다.

**Architecture:** 문맥 미제공 경계에서 한 번 요청한 삭제는 기존처럼 `textDidChange(_:)`의 삭제 형태 문맥 변화로 성공을 확인한다. 다음 반복 timer tick까지 pending 요청이 남아 있으면 삭제 불가로 판정해 shared controller가 버튼의 `isGesturing`을 해제하고 반복 상태를 종료한다.

**Tech Stack:** Swift 5, UIKit, Combine timer, Swift Testing, XcodeBuildMCP

## Global Constraints

- iOS 16+와 Swift 5 프로젝트 구조를 유지한다.
- 삭제 버튼 최초 `touchDown`의 사운드·햅틱 피드백은 변경하지 않는다.
- 실제 삭제가 확인된 반복 tick의 사운드·햅틱 피드백은 유지한다.
- 삭제 불가로 UI를 해제할 때는 사운드·햅틱을 추가로 재생하지 않는다.
- 줄바꿈 경계의 speculative delete와 `textDidChange(_:)` 완료 판정은 유지한다.
- 한글·영문 키보드가 공유하는 `BaseKeyboardViewController`에서 동일하게 동작한다.
- 각 코드 변경은 RED를 확인한 뒤 최소 구현으로 GREEN을 만들고 커밋한다.

---

### Task 1: pending 반복 삭제를 추가 피드백 없이 종료

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md`

**Interfaces:**
- Consumes: `KeyboardTextInteractionPolicy.repeatDeleteAction(documentContextBeforeInput:selectedText:hasPendingBoundaryRequest:)`
- Produces: `RepeatDeleteAction.finishWithoutDeletion`
- Consumes: `BaseKeyboardViewController.stopRepeatInputTracking()`
- Produces: pending 요청이 다음 반복 tick에도 남아 있을 때 `button.isGesturing == false`, timer 취소, `isRepeatingInput == false`

- [x] **Step 1: pending 요청의 삭제 불가 종료 action 실패 테스트 작성**

`KeyboardTextInteractionPolicyTests`의 기존 pending 테스트를 다음과 같이 변경한다.

```swift
@Test("반복 삭제 pending 요청이 다음 tick까지 남으면 삭제 불가로 종료")
func test반복삭제_pending요청_삭제불가종료() {
    #expect(
        KeyboardTextInteractionPolicy.repeatDeleteAction(
            documentContextBeforeInput: "가",
            selectedText: nil,
            hasPendingBoundaryRequest: true
        ) == .finishWithoutDeletion
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
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: `RepeatDeleteAction`에 `finishWithoutDeletion` case가 없어 컴파일 실패

- [x] **Step 3: 삭제 불가 종료 action 구현**

`KeyboardTextInteractionPolicy.swift`의 enum과 pending 분기를 다음과 같이 변경한다.

```swift
enum RepeatDeleteAction: Equatable {
    case deleteWithImmediateFeedback
    case deleteAwaitingTextChange
    case finishWithoutDeletion
}
```

```swift
guard !hasPendingBoundaryRequest else {
    return .finishWithoutDeletion
}
```

- [x] **Step 4: shared controller에서 UI와 반복 상태 종료**

`BaseKeyboardViewController`에 다음 helper를 추가한다.

```swift
func finishRepeatDeleteWithoutDeletion(for button: TextInteractable) {
    button.isGesturing = false
    stopRepeatInputTracking()
}
```

`performRepeatTextInteraction(for:)`와 `performInitialRepeatDeleteTextInteraction(for:)`의 switch에서 기존
`.waitForTextChange` 분기를 다음과 같이 교체한다.

```swift
case .finishWithoutDeletion:
    finishRepeatDeleteWithoutDeletion(for: button)
```

이 helper에서는 `button.playFeedback()` 또는 `FeedbackManager`를 호출하지 않는다.

- [x] **Step 5: 집중 테스트를 다시 실행해 GREEN 확인**

Run: Step 2와 동일한 명령

Expected: `KeyboardTextInteractionPolicyTests` 9개 통과, 실패 0건

- [x] **Step 6: 변경된 양쪽 extension 컴파일 확인**

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

- [x] **Step 7: 구현과 단계 문서 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md
git commit -m "fix: #102 - 삭제 불가 시 반복 버튼 UI 해제"
```

#### Task 1 결과 (2026-07-24)

- RED: `KeyboardTextInteractionPolicyTests` 집중 테스트가 `RepeatDeleteAction.finishWithoutDeletion` 미정의 컴파일 오류로 실패했다.
- GREEN: 같은 집중 테스트에서 정책 테스트 9개가 모두 통과했다.
- 빌드: `HangeulKeyboard`, `EnglishKeyboard` scheme이 `iPhone 13 mini (iOS 16.0)` 대상으로 모두 성공했다. 기본 샌드박스의 한글 빌드는 Xcode/SwiftPM 캐시·CoreSimulator 권한 오류로 실패해, 권한 있는 환경에서 재실행했다.

### Task 2: 전체 회귀 검증과 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md`

**Interfaces:**
- Consumes: Task 1의 `RepeatDeleteAction.finishWithoutDeletion`
- Produces: 전체 테스트·extension 빌드·수동 검증 상태 기록

- [x] **Step 1: `SYKeyboard` 전체 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 테스트 실패 0건

- [x] **Step 2: 한글·영문 extension 최종 빌드**

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

- [x] **Step 3: 실제 입력 앱 수동 검증 상태 기록**

확인 항목:

- 줄바꿈 경계에서 long press 반복 삭제가 계속된다.
- 삭제할 내용이 없으면 버튼 UI가 눌리지 않은 상태로 돌아온다.
- 한글·영문 모두 삭제할 내용이 없을 때 `touchDown` 피드백 1회만 발생한다.
- 실제 삭제가 발생하는 반복 tick에는 기존 사운드·햅틱이 유지된다.

자동화 환경에서 실제 키보드 extension과 햅틱을 확인하지 못하면 미검증으로 명시한다.

- [x] **Step 4: 변경 범위 확인**

Run:

```sh
git diff --check
git status --short
git log --oneline -6
```

Expected: 계획 문서 외 미커밋 변경이 없고 공백 오류가 없다.

- [x] **Step 5: 검증 기록 커밋**

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md
git commit -m "docs: #102 - 반복 삭제 종료 UI 검증 기록"
```

#### Task 2 결과 (2026-07-24)

- 검증 대상: `iPhone 13 mini (iOS 16.0, UDID CBD992D3-5364-4F69-AC5F-0077ADF1A292)`. XcodeBuildMCP `session_show_defaults`의 simulator ID와 `list_sims`의 iOS 16.0 runtime 항목을 대조해 대상 runtime을 확인했다.
- 전체 테스트: XcodeBuildMCP `test_sim`으로 위 대상에서 `SYKeyboard` scheme을 실행했다. 263개 통과, 실패 0개, skip 0개(58.2초)였다. Meta/Facebook 의존성의 누락된 `.pcm` 경로 경고 26개는 있었지만 테스트 결과는 성공이었다.
- extension 빌드: XcodeBuildMCP `build_sim`으로 위 대상에서 `HangeulKeyboard` scheme이 성공(11.2초, 위와 같은 `.pcm` 경고 26개), `EnglishKeyboard` scheme이 성공(8.0초, 경고 없음)했다.
- 수동 검증: 자동화 환경에서 실제 입력 앱의 키보드 extension을 활성화해 long press, 버튼 해제 상태, 사운드·햅틱을 관찰하지 않았다. 따라서 줄바꿈 경계의 반복 삭제 지속, 삭제 불가 시 버튼 UI 해제, 한글·영문 `touchDown` 피드백 1회, 실제 삭제 tick의 피드백 유지는 모두 **미검증**이다.
- 변경 범위: 커밋 전 `git diff --check`는 공백 오류 없이 성공했다. `git status --short`에는 이 계획 문서만 변경으로 표시됐고, `git log --oneline -6`에서 Task 1 커밋 `116d39ee fix: #102 - 삭제 불가 시 반복 버튼 UI 해제`를 확인했다.

### Task 3: final review 줄바꿈 undo와 lifecycle 상호 배타성 수정

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
- Modify: `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
- Modify: `docs/superpowers/specs/2026-07-23-cursor-drag-newline-boundary-design.md`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md`

- [x] **Step 1: undo 누락 root cause 확인**

`deleteText()`는 speculative 경계 요청 전에 `documentContextBeforeInput`이 `nil` 또는 빈 문자열이므로
삭제 문자를 `""`로 계산한다. `KeyboardUndoRedoManager.record`는 삭제·입력 문자열이 모두 비어 있으면
즉시 반환한다. 이후 `textDidChange(_:)`는 앞 문맥 변화와 뒤 문맥 유지로 삭제 성공을 확인하지만 기존
구현은 사운드·햅틱과 pending 정리만 수행해 줄바꿈을 undo history에 기록하지 않았다.

- [x] **Step 2: shared/한글/lifecycle 회귀 테스트 작성 후 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

XcodeBuildMCP `test_sim`으로 실행했고 `RepeatDeleteBoundaryRequest`가 아직 없어
`KeyboardTextInteractionPolicyTests.swift`의 두 위치에서 `cannot find ... in scope` 컴파일 오류가
발생했다. 이는 새 회귀 테스트가 구현 부재를 원인으로 실패한 RED였다.

- [x] **Step 3: 경계 요청 상태와 confirmed newline undo 최소 구현**

`RepeatDeleteBoundaryRequest`가 요청 문맥을 소유하고 성공 또는 무효 완료 시 문맥을 먼저 소비하도록 했다.
삭제 형태의 `textDidChange(_:)`가 성공을 확인하면 `.deleted("\n")`을 한 번 반환하고,
`BaseKeyboardViewController`는 이를 기존 `recordUndoRedoChange`로 기록한 뒤 피드백을 재생한다.
다음 timer tick까지 callback이 없으면 `.noDeletion`으로 한 번 완료한 뒤 기존처럼 버튼 UI와 반복 상태를
종료한다. 새 반복 시작, 정상 종료, view 소멸 등 기존 중단 경로는 `cancel()`로 요청 상태를 정리한다.

- [x] **Step 4: focused GREEN 확인**

Step 2와 같은 XcodeBuildMCP 집중 테스트에서 40개 통과, 실패 0개, skip 0개였다. 회귀 테스트는 다음을
자동 검증한다.

- 확인된 줄바꿈이 앞뒤 일반 삭제와 같은 그룹에서 `b\nc` 순서로 undo되고 redo에서 3글자를 다시 삭제한다.
- 성공한 요청은 다시 성공하거나 무효 완료될 수 없고, 무효 요청도 이후 성공 완료될 수 없다.
- 문서 시작의 무효 요청은 undo mutation을 만들지 않는다.
- 빈 한글 조합 상태의 경계 반복 삭제는 `.delete(count: 1)`을 유지하고 조합 buffer를 변경하지 않는다.

- [x] **Step 5: 전체 테스트와 extension 빌드 확인**

검증 대상은 `iPhone 13 mini (iOS 16.0, UDID CBD992D3-5364-4F69-AC5F-0077ADF1A292)`이다.

- `SYKeyboard` 전체 테스트: 268개 통과, 실패 0개, skip 0개(52.9초)
- `HangeulKeyboard` build: 성공(12.0초), 기존 Meta/Facebook `.pcm` 경로 경고 26개
- `EnglishKeyboard` build: 성공(6.2초), 경고 없음

- [x] **Step 6: 남은 실제 UI/피드백 검증 한계 기록**

자동 테스트는 pending 성공/무효 완료의 callback 순서와 상호 배타성, undo/redo 결과, 한글 조합 상태를
검증한다. 실제 입력 앱에서 키보드 extension을 활성화해 timer 취소 시점, `button.isGesturing`의 물리 UI,
사운드·햅틱 횟수를 직접 관찰하지는 않았다. 따라서 이 물리 UI/피드백 항목은 여전히 수동 검증이 필요하다.

### Task 4: controller 독립 최종 검증과 branch review

- [x] **Step 1: 최종 HEAD 전체 테스트 재실행**

XcodeBuildMCP `test_sim`을 `iPhone 13 mini (iOS 16.0, UDID
CBD992D3-5364-4F69-AC5F-0077ADF1A292)` 대상으로 실행했다.

Result: 268개 통과, 실패 0개, skip 0개

- [x] **Step 2: 최종 HEAD 양쪽 extension 재빌드**

같은 simulator에서 XcodeBuildMCP `build_sim`을 실행했다.

- `HangeulKeyboard`: 빌드 성공, 기존 Meta/Facebook `.pcm` 경로 경고 26개
- `EnglishKeyboard`: 빌드 성공, 경고 없음

- [x] **Step 3: 전체 branch 최종 재검토**

`origin/develop`과의 merge base `ac09db95`부터 `1a7890d1`까지 17개 커밋을 대상으로 재검토했다.

Result: Critical/Important/Minor 이슈 없음, merge-ready

- [x] **Step 4: 남은 수동 검증 명시**

실제 입력 앱에서 한글·영문 extension의 줄바꿈 반복 삭제, 문서 시작 버튼 UI 해제, 정확한
사운드·햅틱 횟수는 여전히 수동 검증이 필요하다.

- [x] **Step 5: 최종 검증 기록 커밋**

```sh
git add docs/superpowers/plans/2026-07-24-repeat-delete-terminal-ui.md
git commit -m "docs: #102 - 반복 삭제 종료 UI 최종 검증"
```
