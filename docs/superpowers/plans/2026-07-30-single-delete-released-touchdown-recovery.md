# 단일 삭제 released touchDown 복구 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 단일 삭제 callback이 누락되어도 다음 단일 탭을 소비하지 않고 삭제를 계속한다.

**Architecture:** `DeleteMutationLifecycle`이 `releasedTouchDown`만 현재 문맥으로 checkpoint하는 제한된 API를 제공한다. `BaseKeyboardViewController`는 새 단일 삭제 요청을 coordinator에 넣기 전에 이 API를 호출하고, 확인된 mutation은 기존 resolution 처리 경로로 완료한 뒤 같은 탭을 새 요청으로 실행한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+

## Global Constraints

- 현재 `feat/#98-math-calculation-auto-complete` 브랜치에서 작업하고 새 worktree나 브랜치를 만들지 않는다.
- 정상 `textDidChange`, selection 삭제, 반복 삭제, 삭제 드래그의 기존 동작을 유지한다.
- 복구를 유발한 다음 단일 탭은 소비하거나 중복 실행하지 않는다.
- `UITextDocumentProxy` mock과 DEBUG 전용 production API를 추가하지 않는다.
- 수식 평가, 일반 자동완성, 텍스트 대치, 한글 조합, `inputBuffer`를 변경하지 않는다.
- push하지 않는다.

---

### Task 1: callback 누락 단일 삭제 회귀 계약

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Create: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/progress.md`
- Create: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/task-1-review.md`
- Modify: `docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md`

**Interfaces:**
- Consumes: `DeleteMutationLifecycle.beginTouchDown`, `capture`, `finishTouchDown`
- Produces: 다음 단일 탭에서 호출할 `completeReleasedTouchDownAtCheckpoint(currentContext:currentSelectedText:)` 계약

- [x] **Step 1: 실패 테스트 작성**

`DeleteInteractionCoordinatorTests`에 다음 흐름을 추가한다.

```swift
@Test("released touchDown callback 누락 뒤 다음 단일 탭은 이전 요청을 확정하고 한 번 실행")
func testReleasedTouchDownMissingCallbackRecoversOnNextTap() throws {
    // "1 1 " → "1 1": release checkpoint는 stale 문맥이라 pending
    // 다음 tap 시 안정된 "1 1" 문맥으로 이전 요청을 확정
    // coordinator를 resolve한 뒤 같은 button이 새 touchDown으로 performNow
}
```

또한 확인되지 않은 문맥에서는 기존처럼 `.enqueued`를 유지하고, 이미 완료한
요청에 늦은 callback이 와도 `.noResolution`인 것을 검증한다.

Result: `DeleteInteractionCoordinatorTests`에 production `DeleteMutationLifecycle`와
`DeleteInteractionCoordinator`를 함께 구동하는 테스트 2개를 추가했다. 첫 테스트는
stale release 문맥, callback 없는 안정 문맥, 이전 draft 단 한 번의 resolution, 같은
button의 새 `.performNow`, 늦은 callback의 `.noResolution`을 확인한다. 둘째 테스트는
불확실한 checkpoint에서 기존 `.enqueued` 대기와 pending 유지를 확인한다. proxy mock과
DEBUG 전용 API는 추가하지 않았다.

- [x] **Step 2: 집중 테스트로 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: `completeReleasedTouchDownAtCheckpoint`가 없어 compile failure 또는
다음 단일 탭이 `.enqueued`로 남아 신규 테스트가 실패한다.

Result: 먼저 기본 sandbox에서 동일 명령은 CoreSimulatorService/SwiftPM ModuleCache
권한 오류(exit 74)로 컴파일 전 중단됐다. 권한 있는 재실행은 iPhone 13 mini / iOS
16.0(arm64)에서 exit 65로 의도한 RED를 확인했다. 대표 오류는
`Value of type 'DeleteMutationLifecycle' has no member
'completeReleasedTouchDownAtCheckpoint'`이며, 뒤따른 `nil` contextual type 오류는
누락 API에서 파생된 컴파일 오류다.

- [x] **Step 3: Task 1 구현 리뷰와 재리뷰**

테스트가 아래 계약을 직접 검증하는지 확인한다.

- release의 stale 문맥
- callback 없는 실제 문맥 갱신
- 이전 mutation 정확히 한 번 확정
- 같은 다음 탭이 새 요청으로 즉시 시작
- 불확실한 문맥에서 기존 대기 유지
- 늦은 callback 중복 무시

Critical/Important finding을 수정하고 재리뷰 결과를
`task-1-review.md`에 기록한다.

Result: `task-1-review.md`에 self-review와 재리뷰 결과를 기록했다. Critical/Important
finding은 없었고, production 파일은 변경하지 않았다.

- [x] **Step 4: RED 계약 커밋**

```sh
git add \
  SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift \
  docs/superpowers/specs/2026-07-30-single-delete-released-touchdown-recovery-design.md \
  docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md
git commit -m "test: #98 - 단일 삭제 callback 누락 회귀 계약 추가"
```

Result: `test: #98 - 단일 삭제 callback 누락 회귀 계약 추가` 커밋으로 RED 테스트와
설계·계획 문서를 기록했다. push는 수행하지 않았다.

### Task 2: released touchDown checkpoint 복구

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/progress.md`
- Create: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/task-2-review.md`
- Modify: `docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md`

**Interfaces:**
- Consumes: Task 1의 `completeReleasedTouchDownAtCheckpoint(currentContext:currentSelectedText:)` 계약
- Produces: `DeleteMutationResolution?`을 반환하는 released-touchDown 전용 checkpoint와 Base controller 사전 복구 호출

- [x] **Step 1: 최소 lifecycle 구현**

`DeleteMutationLifecycle`에 다음 제한된 API를 추가한다.

```swift
mutating func completeReleasedTouchDownAtCheckpoint(
    currentContext: KeyboardTextContextSnapshot,
    currentSelectedText: String?
) -> DeleteMutationResolution? {
    guard requestKind == .releasedTouchDown else { return nil }
    return resolve(
        request.completeAtCheckpoint(
            currentContext: currentContext,
            currentSelectedText: currentSelectedText
        )
    )
}
```

Result: `DeleteMutationLifecycle`에 `requestKind == .releasedTouchDown`일 때만
기존 checkpoint와 resolution을 재사용하는 제한 API를 추가했다.

- [x] **Step 2: Base controller 단일 탭 경로 연결**

새 단일 삭제의 `coordinator.beginTouchDown` 전에 이전 released 요청을 확인한다.

```swift
let previousResolution = deleteMutationLifecycle
    .completeReleasedTouchDownAtCheckpoint(
        currentContext: currentTextContextSnapshot(),
        currentSelectedText: textDocumentProxy.selectedText
    )
processDeleteMutationResolution(previousResolution)
```

resolution이 있으면 기존 처리 함수가 이전 generation을 resolve한다. 이어지는
`beginTouchDown`은 같은 사용자 탭을 새 generation으로 시작한다.

Result: 비반복 delete 경로에서 새 `beginTouchDown` 직전에 checkpoint를 수행하고
결과를 기존 `processDeleteMutationResolution`로 처리하도록 연결했다.

- [x] **Step 3: 집중 suite GREEN 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests \
  -only-testing:SYKeyboardTests/DeleteInteractionCoordinatorTests
```

Expected: 신규 복구 계약과 기존 lifecycle/coordinator 테스트가 모두 통과한다.

Result: 기본 sandbox는 CoreSimulator/SwiftPM cache 권한 오류로 exit 74였고,
권한 있는 RED는 누락 API로 exit 65였다. 최소 구현 뒤 Task 1의 mutating
`resolve` 직접 `#expect`가 Swift Testing immutable macro closure로 컴파일되지 않아,
계약 의미를 유지한 채 반환값을 지역 변수로 분리했다. 최종 권한 있는 실행은
iPhone 13 mini / iOS 16.0(arm64)에서 두 집중 suite 35개가 모두 통과했다
(실패 0, 건너뜀 0).

- [x] **Step 4: Task 2 구현 리뷰와 재리뷰**

production 변경이 `releasedTouchDown`에만 한정되고 기존 resolution 처리 경로를
재사용하는지 검토한다. selection, repeat, pan, input identifier 변경, late
callback과 중복 실행 위험을 확인한다. Critical/Important finding을 수정하고
재리뷰 결과를 `task-2-review.md`에 기록한다.

Result: production 변경은 `releasedTouchDown` guard와 비반복 단일 delete 진입
checkpoint에만 한정했다. selection은 현재 `selectedText`를 그대로 비교하고,
repeat/pan/input identifier 경로는 변경하지 않았다. 성공 resolution은 기존
generation resolve/drain 경로를 재사용하고 late callback 중복을 만들지 않는다.
self-review와 재리뷰에서 Critical/Important 잔여 finding은 없었다.

- [x] **Step 5: GREEN 구현 커밋**

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md
git commit -m "fix: #98 - 다음 단일 삭제에서 미확정 요청 복구"
```

Result: production 2개 파일, Task 1 Swift Testing 문법 보정, 이 계획 문서를
지정한 Task 2 커밋 범위로 확정했다.

### Task 3: 전체 회귀 검증과 최종 리뷰

**Files:**
- Modify: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/progress.md`
- Create: `.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/final-review.md`
- Modify: `docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md`

**Interfaces:**
- Consumes: Task 2의 GREEN 구현
- Produces: 전체 테스트·두 extension 빌드·정적 검색·최종 리뷰 기록

- [x] **Step 1: 전체 검증**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'

git diff --check
rg -n "hasSelectedText" Modules SYKeyboardTests
rg -n "setMarkedText" Modules Keyboards SYKeyboard -g '*.swift'
```

Expected: 전체 테스트와 두 extension 빌드 성공, diff 오류 없음,
`hasSelectedText`와 production `setMarkedText` 검색 결과 없음.

Result: XcodeBuildMCP의 최초 `session_show_defaults`에서 기본값이 비어 있음을
확인한 뒤 project=`SYKeyboard.xcodeproj`, scheme=`SYKeyboard`, simulator=iPhone 13
mini / iOS 16.0 (`CBD992D3-5364-4F69-AC5F-0077ADF1A292`), configuration=Debug로
설정했다. 전체 `SYKeyboard` 테스트는 373개 통과, 실패 0, 건너뜀 0이었다.
`HangeulKeyboard`, `EnglishKeyboard` build는 각각 성공했다. 테스트와 Hangeul build에
Meta/Buck `.pcm` 누락 경로의 외부 경고 26건이 있었고 English build에는 경고가 없었다.
`git diff --check`와 `git diff --check 5b37780f..HEAD`는 출력 없이 통과했다.
`hasSelectedText`와 production `setMarkedText` 검색은 모두 일치 항목 없이 exit 1을
반환했다. 세부 로그·result bundle 경로와 리뷰 결과는
`.superpowers/sdd/2026-07-30-single-delete-released-touchdown-recovery/final-review.md`에
기록했다.

- [x] **Step 2: 별도 전체 리뷰와 재리뷰**

설계·계획·diff·검증 결과를 독립적으로 리뷰한다. Critical/Important finding을
수정하고 같은 검증을 다시 실행한다. 결과와 남은 실제 기기 위험을
`final-review.md`에 기록한다.

Result: 설계 문서, Task 1/2의 108-line production/test diff, lifecycle guard,
Base controller 호출 순서, 전체 검증과 정적 검색 결과를 독립적으로 대조했다.
`releasedTouchDown` 외 lifecycle 상태는 새 API에서 즉시 반환되고, resolution은 기존
`processDeleteMutationResolution`를 거친 뒤 같은 탭이 새 coordinator request로 시작한다.
Critical/Important finding은 없었으므로 코드를 수정하거나 검증을 재실행할 사유가
없었다. host 앱의 실제 keyboard extension에서 callback 누락을 재현하는 수동 확인은
수행하지 못했으며, 이를 남은 위험으로 기록했다.

- [x] **Step 3: 최종 검증 문서 커밋**

```sh
git add \
  docs/superpowers/plans/2026-07-30-single-delete-released-touchdown-recovery.md
git commit -m "docs: #98 - 단일 삭제 복구 최종 검증"
```

push는 수행하지 않는다.

Result: 이 계획 문서의 최종 검증 기록을 별도 docs 커밋으로 남겼다. push는 수행하지
않았다.
