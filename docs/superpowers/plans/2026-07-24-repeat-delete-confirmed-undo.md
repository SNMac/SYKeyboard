# 반복 삭제 실제 변경 확인 Undo 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 메시지 앱에서 키보드 드래그 후 `가나\n다라\n마바\n`을 전부 반복 삭제해도 한 번의 SY키보드 undo가 원문을 정확히 복원하게 한다.

**Architecture:** 모든 반복 삭제 tick을 pending 요청으로 시작하고, 입력 로직이 만든 mutation을 요청 내부에 임시 보관한다. `textDidChange(_:)`가 실제 삭제를 확인한 뒤 일반 문자는 보관한 mutation을 확정하고, 메시지 앱의 줄 단위 문맥 패턴이면 proxy가 제시한 마지막 글자 대신 `\n`을 확정한다. 단일 삭제와 반복 삭제가 아닌 입력의 기존 즉시 기록 흐름은 유지한다.

**Tech Stack:** Swift 5, UIKit `UIInputViewController`/`UITextDocumentProxy`, Combine 기반 `KeyboardUndoRedoSession`, Swift Testing, XcodeBuildMCP

## Global Constraints

- iOS 16+를 지원한다.
- 한글·영문 키보드가 공유하는 `SYKeyboardCore`에서 같은 반복 삭제 정책을 사용한다.
- `selectionWillChange(_:)`와 `selectionDidChange(_:)` 호출에 의존하지 않는다.
- 단일 삭제, 삭제 버튼 드래그 삭제/복구, 커서 이동 속도와 햅틱 조건은 변경하지 않는다.
- 삭제할 내용이 없으면 버튼 UI를 해제하고 `touchDown` 피드백 1회만 유지한다.
- 실제 삭제가 확인된 반복 tick에만 삭제 사운드·햅틱을 재생한다.
- 각 Task는 테스트와 문서 기록을 함께 커밋한다.
- 각 Step은 작업과 검증 직후 체크박스와 실제 결과를 이 문서에 기록하고, 다음 Step을 시작하기 전에
  해당 Step에서 변경한 파일과 이 문서를 커밋한다. RED Step의 실패 테스트도 독립 커밋한다.

### Step별 커밋 메시지

| Step | 커밋 메시지 |
|---|---|
| Task 1 Step 1 | `test: #102 - 반복 삭제 실제 mutation 회귀 테스트` |
| Task 1 Step 2 | `docs: #102 - 반복 삭제 mutation RED 검증` |
| Task 1 Step 3 | `fix: #102 - 반복 삭제 mutation 확인 상태 추가` |
| Task 1 Step 4 | `test: #102 - 반복 삭제 lifecycle 회귀 테스트 이전` |
| Task 1 Step 5 | `docs: #102 - 반복 삭제 mutation GREEN 검증` |
| Task 1 Step 6 | `docs: #102 - 반복 삭제 mutation Task 1 검토` |
| Task 2 Step 1 | `test: #102 - 반복 삭제 전체 복원 회귀 테스트` |
| Task 2 Step 2 | `docs: #102 - 반복 삭제 controller RED 검증` |
| Task 2 Step 3 | `fix: #102 - 반복 삭제 요청 흐름 통합` |
| Task 2 Step 4 | `fix: #102 - 반복 삭제 mutation 임시 보관` |
| Task 2 Step 5 | `fix: #102 - 반복 삭제 callback undo 확정` |
| Task 2 Step 6 | `docs: #102 - 반복 삭제 controller 빌드 검증` |
| Task 2 Step 7 | `docs: #102 - 반복 삭제 controller Task 2 검토` |
| Task 2 Review Fix Step 1 | `test: #102 - 반복 삭제 callback 순서 회귀 테스트` |
| Task 2 Review Fix Step 2 | `docs: #102 - 반복 삭제 callback 순서 RED 검증` |
| Task 2 Review Fix Step 3 | `fix: #102 - 반복 삭제 callback 순서와 문맥 검증` |
| Task 2 Review Fix Step 4 | `docs: #102 - 반복 삭제 callback 수정 검증` |
| Task 2 Review Fix Step 5 | `docs: #102 - 반복 삭제 Task 2 리뷰 수정 검토` |
| Task 3 Step 1 | `docs: #102 - 반복 삭제 전체 테스트 검증` |
| Task 3 Step 2 | `docs: #102 - 반복 삭제 extension 최종 빌드` |
| Task 3 Step 3 | `docs: #102 - 메시지 앱 반복 삭제 수동 검증 기록` |
| Task 3 Step 4 | `docs: #102 - 반복 삭제 최종 변경 범위 검증` |
| Task 3 Step 5 | `docs: #102 - 반복 삭제 실제 mutation 최종 검증` |

---

### Task 1: 반복 삭제 mutation 확인 상태 모델

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`

**Interfaces:**
- Consumes: `KeyboardTextContextSnapshot`
- Produces: `RepeatDeleteMutationDraft`, `RepeatDeleteMutationReliability`, `RepeatDeleteCompletion`, `RepeatDeleteRequest`
- Produces: `RepeatDeleteRequest.begin(context:)`, `capture(deletedText:insertedText:reliability:)`, `completeAfterTextChange(isRepeatingInput:currentContext:)`, `completeWithoutDeletion()`, `cancel()`
- Preserves: Task 2 전까지 controller가 사용하는 `RepeatDeleteBoundaryRequest`

- [x] **Step 1: 메시지 앱 문맥과 일반 문자 확인 실패 테스트 작성**

`KeyboardTextInteractionPolicyTests`의 반복 삭제 테스트를 다음 상태 모델 기준으로 교체한다.

```swift
@Test("일반 문자 반복 삭제는 callback에서 후보 문자를 확정")
func test반복삭제_일반문자Callback_후보확정() {
    var request = RepeatDeleteRequest()
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: "마바", afterInput: "")
    )
    #expect(
        request.capture(
            deletedText: "바",
            insertedText: "",
            reliability: .proxyContext
        )
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(beforeInput: "마", afterInput: "")
        ) == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "바",
                insertedText: "",
                reliability: .proxyContext
            )
        ])
    )
}

@Test("메시지 앱 줄 단위 문맥이 그대로면 proxy 후보 대신 줄바꿈 확정")
func test반복삭제_메시지동일앞문맥_줄바꿈확정() {
    var request = RepeatDeleteRequest()
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: "다라", afterInput: "마바\n")
    )
    #expect(
        request.capture(
            deletedText: "라",
            insertedText: "",
            reliability: .proxyContext
        )
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "다라",
                afterInput: "마바\n"
            )
        ) == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ])
    )
}

@Test("빈 앞 문맥에서 직전 줄 문맥이 나타나면 줄바꿈 확정")
func test반복삭제_빈앞문맥에서직전줄노출_줄바꿈확정() {
    var request = RepeatDeleteRequest()
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: nil, afterInput: "마바\n")
    )
    #expect(
        request.capture(
            deletedText: "",
            insertedText: "",
            reliability: .proxyContext
        )
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(
                beforeInput: "다라",
                afterInput: "마바\n"
            )
        ) == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ])
    )
}

@Test("조합 치환 mutation은 callback 확인 뒤 원형 유지")
func test반복삭제_권위있는조합치환_원형유지() {
    var request = RepeatDeleteRequest()
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: "")
    )
    #expect(
        request.capture(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )
    )

    #expect(
        request.completeAfterTextChange(
            isRepeatingInput: true,
            currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: "")
        ) == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "한",
                insertedText: "하",
                reliability: .authoritative
            )
        ])
    )
}
```

Result: 일반 문자, 동일 앞 문맥 줄바꿈, 빈 앞 문맥 직전 줄 노출, 권위 조합 치환의 4개 상태 모델 회귀 테스트를 추가했다. 컴파일 실패 확인은 Step 2에서 수행한다.

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: `RepeatDeleteRequest`, `RepeatDeleteMutationDraft`, `RepeatDeleteMutationReliability`, `.mutations`가 없어 컴파일 실패한다.

Result: iPhone 13 mini / iOS 16.0에서 XcodeBuildMCP `test_sim`으로 집중 테스트를 실행했다. `RepeatDeleteRequest`와 `RepeatDeleteMutationDraft`를 찾지 못하고 `.proxyContext`/`.authoritative` 문맥을 추론하지 못하는 16개 컴파일 오류로 의도한 RED를 확인했다.

- [x] **Step 3: 일반 문자·줄바꿈·권위 mutation을 구분하는 최소 상태 모델 구현**

`KeyboardTextInteractionPolicy.swift`에 다음 일반 요청 모델을 추가한다. 기존
`RepeatDeleteBoundaryRequest`는 Task 2에서 controller를 전환할 때 제거한다.

```swift
enum RepeatDeleteMutationReliability: Equatable {
    case proxyContext
    case authoritative
}

struct RepeatDeleteMutationDraft: Equatable {
    let deletedText: String
    let insertedText: String
    let reliability: RepeatDeleteMutationReliability
}

enum RepeatDeleteCompletion: Equatable {
    case mutations([RepeatDeleteMutationDraft])
    case noDeletion
}

struct RepeatDeleteRequest {
    private var requestContext: KeyboardTextContextSnapshot?
    private var drafts: [RepeatDeleteMutationDraft] = []

    var isPending: Bool { requestContext != nil }

    mutating func begin(context: KeyboardTextContextSnapshot) {
        requestContext = context
        drafts.removeAll()
    }

    @discardableResult
    mutating func capture(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability
    ) -> Bool {
        guard requestContext != nil else { return false }
        drafts.append(
            RepeatDeleteMutationDraft(
                deletedText: deletedText,
                insertedText: insertedText,
                reliability: reliability
            )
        )
        return true
    }

    mutating func completeAfterTextChange(
        isRepeatingInput: Bool,
        currentContext: KeyboardTextContextSnapshot
    ) -> RepeatDeleteCompletion? {
        guard isRepeatingInput, let requestContext else { return nil }
        guard normalized(requestContext.afterInput) == normalized(currentContext.afterInput)
        else { return nil }

        let completedDrafts = confirmedDrafts(
            requestContext: requestContext,
            currentContext: currentContext
        )
        guard !completedDrafts.isEmpty else { return nil }

        consume()
        return .mutations(completedDrafts)
    }

    mutating func completeWithoutDeletion() -> RepeatDeleteCompletion? {
        guard requestContext != nil else { return nil }
        consume()
        return .noDeletion
    }

    mutating func cancel() {
        consume()
    }

    private func confirmedDrafts(
        requestContext: KeyboardTextContextSnapshot,
        currentContext: KeyboardTextContextSnapshot
    ) -> [RepeatDeleteMutationDraft] {
        if drafts.contains(where: { $0.reliability == .authoritative }) {
            return drafts
        }

        let before = normalized(requestContext.beforeInput)
        let currentBefore = normalized(currentContext.beforeInput)
        guard let candidate = drafts.last else { return [] }

        if !candidate.deletedText.isEmpty,
           currentBefore == String(before.dropLast(candidate.deletedText.count)) {
            return drafts
        }

        let isSameLineContextBoundary = !candidate.deletedText.isEmpty
            && currentBefore == before
        let isEmptyToPreviousLineBoundary = before.isEmpty
            && !currentBefore.isEmpty
        guard isSameLineContextBoundary || isEmptyToPreviousLineBoundary else { return [] }

        return [
            RepeatDeleteMutationDraft(
                deletedText: "\n",
                insertedText: "",
                reliability: .authoritative
            )
        ]
    }

    private mutating func consume() {
        requestContext = nil
        drafts.removeAll()
    }

    private func normalized(_ context: String?) -> String {
        context ?? ""
    }
}
```

Result: `RepeatDeleteRequest`가 요청 문맥과 후보 mutation을 보관하고, callback의 앞·뒤 문맥으로 일반 문자 또는 줄바꿈을 확정하도록 구현했다. 권위 mutation은 그대로 확정하고, 기존 `RepeatDeleteBoundaryRequest`는 Task 2 전환 전까지 보존했다. GREEN 확인은 Step 5에서 수행한다.

- [x] **Step 4: lifecycle 상호 배타성 테스트를 이 모델로 이전**

기존 성공/무효 한 번 완료 테스트를 `RepeatDeleteRequest`로 바꾸고 다음 assertion을 유지한다.

```swift
#expect(request.completeAfterTextChange(
    isRepeatingInput: true,
    currentContext: deletedContext
) != nil)
#expect(request.completeAfterTextChange(
    isRepeatingInput: true,
    currentContext: deletedContext
) == nil)
    #expect(request.completeWithoutDeletion() == nil)
#expect(request.isPending == false)
```

Result: 기존 경계 요청의 성공·무효 단일 완료 테스트를 `RepeatDeleteRequest`로 이전해 callback 완료, 무효 완료, pending 해제의 상호 배타성을 유지했다.

- [x] **Step 5: 집중 테스트 GREEN 확인**

Step 2와 같은 명령을 실행한다.

Expected: `KeyboardTextInteractionPolicyTests` 전체 통과.

Result: iPhone 13 mini / iOS 16.0에서 XcodeBuildMCP `test_sim`으로 집중 테스트를 실행해 15개 통과, 실패 0건을 확인했다. Swift Testing의 `#expect`는 mutating `capture` 호출을 immutable로 평가하므로, 동일한 반환값을 지역 변수에 저장한 뒤 assertion하는 형태로 lifecycle 테스트 commit을 보정했다.

- [x] **Step 6: Task 1 변경 범위와 기록 자체 검토**

Run:

```sh
git diff HEAD~5..HEAD --check
git log --oneline -5
```

Expected: Task 1의 테스트·구현·검증 문서만 포함되고 공백 오류가 없다. 실제 검토 결과를 이 문서에
기록한다.

Result: `git diff HEAD~5..HEAD --check`는 출력 없이 통과했다. `git log --oneline -5`와 변경 파일 목록을 검토해 `KeyboardTextInteractionPolicy.swift`, `KeyboardTextInteractionPolicyTests.swift`, 본 계획 문서만 Task 1 범위에 포함됨을 확인했다. `RepeatDeleteBoundaryRequest`가 계속 정의되어 있어 Task 2 controller 전환 전 보존 조건도 충족한다.

### Task 2: Base controller의 반복 삭제 Undo 확정 지연

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
- Modify: `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`

**Interfaces:**
- Consumes: Task 1의 `RepeatDeleteRequest`와 `RepeatDeleteMutationDraft`
- Produces: 모든 반복 삭제 tick의 `begin → capture → textDidChange complete` 흐름
- Preserves: 단일 삭제와 반복 삭제 외 mutation의 즉시 `KeyboardUndoRedoSession.record`

- [x] **Step 1: 전체 문자열 복원과 한글 mutation 회귀 테스트 작성**

`KeyboardTextInteractionPolicyTests`에서 일반 문맥도 callback 대기 action을 반환해야 한다는 회귀
테스트를 먼저 추가한다.

```swift
@Test("확인 가능한 일반 문자 반복 삭제도 callback 대기")
func test반복삭제_일반문자_Callback대기() {
    #expect(
        KeyboardTextInteractionPolicy.repeatDeleteAction(
            documentContextBeforeInput: "마바",
            selectedText: nil,
            hasPendingBoundaryRequest: false
        ) == .deleteAwaitingTextChange
    )
}
```

`KeyboardUndoRedoManagerTests`에는 메시지 앱에서 확인된 삭제 순서를 재현한다.

```swift
@Test("커서 드래그 후 전체 반복 삭제 undo는 마지막 줄바꿈까지 원문 복원")
func test반복삭제_커서드래그후전체삭제_원문복원() {
    var manager = KeyboardUndoRedoManager()
    let confirmedDeletedTexts = [
        "\n", "바", "마", "\n", "라", "다", "\n", "나", "가"
    ]

    for deletedText in confirmedDeletedTexts {
        manager.record(deletedText: deletedText, insertedText: "", targetContext: nil)
    }

    #expect(
        manager.undo()
        == KeyboardUndoRedoEdit(deleteCount: 0, insertText: "가나\n다라\n마바\n")
    )
    #expect(
        manager.redo()
        == KeyboardUndoRedoEdit(deleteCount: 9, insertText: "")
    )
}
```

`HangeulCompositionStateTests`에는 권위 있는 조합 치환이 callback 뒤 한 번만 전달되는지 추가한다.

```swift
@Test("한글 반복 삭제 치환 mutation은 callback 확인 뒤 한 번만 유지")
func test한글반복삭제_치환Mutation_Callback확인() {
    var request = RepeatDeleteRequest()
    request.begin(
        context: KeyboardTextContextSnapshot(beforeInput: "한", afterInput: "")
    )
    #expect(
        request.capture(
            deletedText: "한",
            insertedText: "하",
            reliability: .authoritative
        )
    )

    let completion = request.completeAfterTextChange(
        isRepeatingInput: true,
        currentContext: KeyboardTextContextSnapshot(beforeInput: "하", afterInput: "")
    )

    #expect(
        completion == .mutations([
            RepeatDeleteMutationDraft(
                deletedText: "한",
                insertedText: "하",
                reliability: .authoritative
            )
        ])
    )
#expect(request.completeWithoutDeletion() == nil)
}
```

Result: 일반 문자 반복 삭제도 callback을 기다려야 한다는 정책 회귀, 메시지 앱에서 확인된 삭제 순서의 전체 문자열 undo/redo 복원, 한글 권위 치환 mutation의 callback 후 단일 소비를 각각 추가했다. `capture`의 mutating 호출은 기존 Swift Testing 제약에 맞춰 지역 변수에 결과를 저장한 뒤 assertion했다. RED 실행은 Step 2에서 수행한다.

- [x] **Step 2: controller 통합 전 RED 확인**

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

Expected: 일반 문자는 기존 `.deleteWithImmediateFeedback`를 반환하므로
`test반복삭제_일반문자_Callback대기`가 실패한다.

Result: iPhone 13 mini / iOS 16.0 (`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)을 XcodeBuildMCP session defaults로 설정하고 `test_sim`을 실행했다. 집중 테스트는 46개 통과, 1개 실패였으며, 유일한 실패는 `test반복삭제_일반문자_Callback대기`에서 실제 `.deleteWithImmediateFeedback`와 기대 `.deleteAwaitingTextChange`가 달랐던 의도한 RED였다. 빌드 오류나 다른 테스트 실패는 없었다.

- [x] **Step 3: 모든 반복 삭제 tick을 pending 요청으로 시작**

`BaseKeyboardViewController`의 `repeatDeleteBoundaryRequest`를 `repeatDeleteRequest`로 바꾸고 두 반복 삭제 진입점을 다음 패턴으로 통일한다.

```swift
private func beginRepeatDeleteRequest() {
    repeatDeleteRequest.begin(context: currentTextContextSnapshot())
}

final public func performRepeatTextInteraction(for button: TextInteractable) {
    guard self.view.window != nil else { return }

    textInteractionWillPerform(button: button)
    defer { textInteractionDidPerform(button: button) }

    switch button.type {
    case .keyButton:
        repeatInsertPrimaryKeyText(from: button)
        button.playFeedback()
    case .deleteButton:
        switch KeyboardTextInteractionPolicy.repeatDeleteAction(
            hasPendingRequest: repeatDeleteRequest.isPending
        ) {
        case .deleteAwaitingTextChange:
            beginRepeatDeleteRequest()
            repeatDeleteBackward()
        case .finishWithoutDeletion:
            finishRepeatDeleteWithoutDeletion(for: button)
        }
    case .spaceButton:
        insertSpaceText()
        button.playFeedback()
    case .returnButton:
        performRepeatReturnButtonTextInteraction(for: button)
    }
}
```

`performInitialRepeatDeleteTextInteraction(for:)`도 다음처럼 pending 확인, 요청 시작, 기존 단일 interaction
호출 순서를 사용하고 즉시 `button.playFeedback()`하지 않는다.

```swift
final public func performInitialRepeatDeleteTextInteraction(for button: TextInteractable) {
    guard self.view.window != nil else { return }

    switch KeyboardTextInteractionPolicy.repeatDeleteAction(
        hasPendingRequest: repeatDeleteRequest.isPending
    ) {
    case .deleteAwaitingTextChange:
        beginRepeatDeleteRequest()
        performTextInteraction(for: button)
    case .finishWithoutDeletion:
        finishRepeatDeleteWithoutDeletion(for: button)
    }
}
```

`RepeatDeleteAction.deleteWithImmediateFeedback`를 제거하고 정책 입력도 pending 여부 하나로 줄인다.

```swift
enum RepeatDeleteAction: Equatable {
    case deleteAwaitingTextChange
    case finishWithoutDeletion
}

static func repeatDeleteAction(
    hasPendingRequest: Bool
) -> RepeatDeleteAction {
    return hasPendingRequest
        ? .finishWithoutDeletion
        : .deleteAwaitingTextChange
}
```

관련 테스트 호출도 `hasPendingRequest:`로 바꾸고, controller 전환 후 사용하지 않는
`RepeatDeleteBoundaryRequest`는 제거한다.

Result: 반복 삭제 action을 pending 여부만 받는 `deleteAwaitingTextChange`/`finishWithoutDeletion` 두 상태로 축소하고, 최초·후속 반복 삭제 모두 `RepeatDeleteRequest.begin` 후 기존 삭제 흐름을 호출하도록 통합했다. controller·정책·한글·undo 테스트의 legacy 경계 요청 사용을 일반 요청 모델로 이전하고 `RepeatDeleteBoundaryRequest`, `RepeatDeleteBoundaryCompletion`, 전용 완료 helper를 제거했다. callback 결과의 Undo 반영은 Step 5까지 분리했다.

- [x] **Step 4: 반복 삭제 mutation만 임시 capture**

`recordUndoRedoChange`에 reliability 기본값을 추가하고, pending 요청이 있으면 session에 기록하지 않고 capture한다.

```swift
func recordUndoRedoChange(
    deletedText: String,
    insertedText: String,
    reliability: RepeatDeleteMutationReliability = .authoritative
) {
    if repeatDeleteRequest.capture(
        deletedText: deletedText,
        insertedText: insertedText,
        reliability: reliability
    ) {
        return
    }

    guard isUndoRedoFeatureAvailable,
          !undoRedoSession.isApplyingEdit else { return }
    undoRedoSession.record(
        deletedText: deletedText,
        insertedText: insertedText,
        targetContext: currentTextContextSnapshot(),
        shouldDeferCommit: { [weak self] in
            self?.shouldDeferUndoRedoCommit == true
        },
        debouncedCommitDidFinish: { [weak self] in
            self?.updateUndoRedoControls()
        }
    )
    updateUndoRedoControls()
}
```

`deleteText()`는 선택 텍스트가 있으면 `.authoritative`, proxy 앞 문맥에서 한 글자를 얻었으면 `.proxyContext`로 전달한다.

```swift
let selectedText = textDocumentProxy.selectedText
let reliability: RepeatDeleteMutationReliability =
    selectedText?.isEmpty == false ? .authoritative : .proxyContext
recordUndoRedoChange(
    deletedText: deletedText,
    insertedText: "",
    reliability: reliability
)
```

`replaceText(deleteCount:insert:)`가 만드는 한글 조합 치환은 기본 `.authoritative`를 유지한다.

Result: `recordUndoRedoChange`가 pending 반복 삭제 요청에 mutation을 먼저 capture하고 즉시 session 기록을 건너뛰도록 변경했다. `deleteText()`는 삭제 전 선택 텍스트를 보존해 선택 삭제를 `.authoritative`, proxy 앞 문맥 후보를 `.proxyContext`로 전달하며, `replaceText(deleteCount:insert:)`와 반복 삭제 외 호출은 기본 `.authoritative`로 기존 즉시 기록 경로를 유지한다.

- [x] **Step 5: callback에서 mutation 확정 후 피드백**

`textDidChange(_:)`에서 요청을 먼저 소비한 후 각 draft를 기존 기록 함수로 전달한다.

```swift
let repeatDeleteCompletion = repeatDeleteRequest.completeAfterTextChange(
    isRepeatingInput: isRepeatingInput,
    currentContext: currentTextContext
)
if case .mutations(let drafts) = repeatDeleteCompletion {
    for draft in drafts {
        recordUndoRedoChange(
            deletedText: draft.deletedText,
            insertedText: draft.insertedText
        )
    }
    FeedbackManager.shared.playHaptic()
    FeedbackManager.shared.playDeleteSound()
}
```

`stopRepeatInputTracking()`은 `repeatDeleteRequest.cancel()`을 호출한다. `finishRepeatDeleteWithoutDeletion(for:)`은 `.noDeletion`을 한 번 소비한 경우에만 버튼 UI와 반복 상태를 해제한다.

Result: `textDidChange(_:)`에서 `RepeatDeleteRequest`를 먼저 완료해 pending 상태를 소비한 뒤, 확정된 draft를 기존 `recordUndoRedoChange`로 한 번씩 기록하도록 연결했다. `.mutations`가 확인된 tick에만 삭제 햅틱과 사운드를 재생한다. 반복 추적 중단은 요청을 cancel하고, 삭제 없음 종료는 `.noDeletion`을 실제로 소비한 경우에만 버튼 gesture와 반복 상태를 해제한다.

- [x] **Step 6: 집중 테스트와 양쪽 extension 빌드 GREEN 확인**

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

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

Expected: 집중 테스트와 두 extension 빌드 성공.

Result: XcodeBuildMCP session defaults를 iPhone 13 mini / iOS 16.0 (`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)으로 유지하고 scheme을 각 명령 전에 맞췄다. `SYKeyboard` 집중 테스트는 43개 통과, 실패·건너뜀 0건이었다. `HangeulKeyboard`와 `EnglishKeyboard`의 simulator 빌드는 모두 성공했다. 테스트와 한글 extension 빌드 진단에 외부 Meta/FBAudienceNetwork `.pcm` 경로 경고가 있었지만 빌드 오류는 없었고, 영문 extension 빌드는 경고 없이 성공했다.

- [x] **Step 7: Task 2 변경 범위와 기록 자체 검토**

Run:

```sh
git diff HEAD~6..HEAD --check
git log --oneline -6
```

Expected: Task 2의 정책·controller·회귀 테스트·검증 문서만 포함되고 공백 오류가 없다. 실제 검토 결과를
이 문서에 기록한다.

Result: `git diff HEAD~6..HEAD --check`는 출력 없이 통과했고, `git log --oneline -6`에서 Task 2 Step 1~6의 지정 메시지와 순서를 확인했다. 기준 commit `3a27259f`부터의 변경 파일은 정책, base controller, 세 회귀 테스트 파일, 본 계획 문서의 6개로 Task 2 범위와 일치했다. 자체 검토에서 모든 반복 삭제 진입점이 pending 요청을 시작하고, mutation이 pending 중에는 session 기록 대신 capture되며, callback 소비 후에만 Undo와 피드백이 확정되는 흐름을 확인했다. 단일 삭제와 반복 삭제 외 mutation은 pending 요청이 없어 기존 즉시 기록 경로를 유지한다. legacy 경계 요청·action·helper 참조가 남지 않았고 추가 수정이 필요한 Task 2 결함은 발견하지 못했다. 메시지 앱 수동 검증과 전체 테스트는 계획의 Task 3 범위이므로 수행하지 않았다.

### Task 2 Review Fix: callback 순서와 authoritative 문맥 검증

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`

**Interfaces:**
- Consumes: Task 2의 `RepeatDeleteRequest`
- Produces: callback-before-capture 문맥 보관, timer/release 현재 문맥 재확인, authoritative mutation 예상 문맥 검증
- Preserves: 실제 삭제가 없는 문서 시작의 UI 해제와 추가 피드백 없음

- [x] **Step 1: callback 순서와 문맥 불일치 실패 테스트 작성**

다음 조건을 독립 테스트로 추가한다.

```text
1. capture 전에 callback이 오면 문맥을 보관하고 capture 뒤 mutation을 확정한다.
2. callback이 다음 timer tick보다 늦어도 tick 시점 현재 문맥으로 mutation을 확정한다.
3. 버튼 release 전에 callback이 없어도 release 시점 현재 문맥으로 mutation을 확정한다.
4. authoritative "한" → "하" mutation은 현재 beforeInput이 "하"일 때만 성공한다.
5. authoritative mutation에서 현재 beforeInput이 "한" 그대로이거나 다른 값이면 성공하지 않는다.
6. 변경된 afterInput, isRepeatingInput == false, pending 없음, nil/empty 문맥 차이만 있는 callback은 성공하지 않는다.
```

Result: `KeyboardTextInteractionPolicyTests`에 capture 전 callback 보관, timer/release checkpoint 확정,
authoritative 예상 앞 문맥의 성공·무변경·불일치, 변경된 `afterInput`, 종료된 반복 입력, 요청 없음,
nil/empty 차이만 있는 문맥의 부정 경로를 각각 독립 테스트로 추가했다. callback 뒤 `capture`가 completion을
전달하는 결과와 checkpoint API는 아직 구현하지 않아 Step 2 RED에서 확인한다.

- [x] **Step 2: 집중 테스트 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: callback-before-capture 완료 API, checkpoint 재확인 API, authoritative 결과 문맥 검증이 없어 새 테스트가
실패한다.

Result: XcodeBuildMCP session defaults를 `SYKeyboard`, iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)으로 설정하고 `test_sim`에
`-only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests`를 전달했다. 9.430초 뒤 예상대로
compile RED가 발생했고 테스트는 실행되지 않았다. 진단 8건은 `Bool` capture 결과에 없는 `.completion`과
`.awaitingTextChange`, 아직 없는 `completeAtCheckpoint` API를 가리켰으며 기존 테스트 실패나 다른 빌드 오류는
없었다. build log는
`~/Library/Developer/XcodeBuildMCP/workspaces/SYKeyboard-5f24c9a85604/logs/test_sim_2026-07-23T18-22-42-964Z_pid19368_b0ce9fe0.log`다.

- [x] **Step 3: callback 순서 독립 상태와 authoritative 결과 검증 구현**

`RepeatDeleteRequest`가 draft 없이 callback을 받으면 현재 문맥을 보관한다. 이후 `capture`가 호출되면 보관한
문맥으로 완료 가능 여부를 다시 계산해 controller가 처리할 completion을 반환한다. 다음 timer tick과 버튼
release에서는 pending을 즉시 취소하기 전에 `currentTextContextSnapshot()`으로 같은 완료 계산을 한 번
수행한다.

authoritative draft는 요청 전 `beforeInput`의 suffix에 draft의 삭제·삽입을 순서대로 적용한 예상 문맥과 현재
`beforeInput`이 일치할 때만 확정한다. `afterInput` 유지 조건과 성공·무효 요청의 일회성 소비 조건은 유지한다.

Result: `RepeatDeleteRequest`가 draft 전 callback 문맥을 별도로 보관하고, 이후 `capture`가
`.completion` 또는 `.awaitingTextChange`를 반환하도록 변경했다. timer/release 공용
`completeAtCheckpoint(currentContext:)`를 추가하고 controller가 다음 tick의 삭제 없음 처리 및 버튼 release
취소 전에 현재 proxy 문맥을 한 번 재확인하도록 연결했다. authoritative draft는 모두 authoritative인 경우에만
요청 전 `beforeInput` suffix에 삭제·삽입을 순서대로 적용하며, 예상 결과가 실제 현재 `beforeInput`과 일치하고
원문과 달라진 경우에만 확정한다. 기존 세 집중 테스트 파일의 capture assertion은 새 결과 타입으로 이전했고,
`git diff --check`는 출력 없이 통과했다. GREEN 실행은 Step 4에서 수행한다.

- [x] **Step 4: 집중 테스트와 양쪽 extension 빌드 재검증**

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

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

Expected: 새 callback 순서·문맥 불일치 테스트를 포함한 집중 테스트와 두 extension 빌드 성공.

Result: XcodeBuildMCP session defaults와 simulator 목록을 다시 확인해 iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)을 사용했다. `SYKeyboard` scheme에서 세 `-only-testing`
대상을 실행해 53개 통과, 실패·건너뜀 0건(57.223초)을 확인했다. test build log는
`~/Library/Developer/XcodeBuildMCP/workspaces/SYKeyboard-5f24c9a85604/logs/test_sim_2026-07-23T18-26-14-040Z_pid19368_741fb3e1.log`,
xcresult는
`~/Library/Developer/XcodeBuildMCP/workspaces/SYKeyboard-5f24c9a85604/result-bundles/test_sim_2026-07-23T18-26-14-040Z_pid19368_e811fa57.xcresult`다.
`HangeulKeyboard` simulator 빌드는 10.594초에 성공했고 build log는
`~/Library/Developer/XcodeBuildMCP/workspaces/SYKeyboard-5f24c9a85604/logs/build_sim_2026-07-23T18-27-23-379Z_pid19368_04309f93.log`다.
`EnglishKeyboard` simulator 빌드는 경고 없이 6.538초에 성공했고 build log는
`~/Library/Developer/XcodeBuildMCP/workspaces/SYKeyboard-5f24c9a85604/logs/build_sim_2026-07-23T18-27-39-972Z_pid19368_da7b49da.log`다.
집중 테스트와 한글 extension 빌드에는 기존 외부 Meta/FBAudienceNetwork `.pcm` 경로 경고가 있었지만 오류는
없었다.

- [x] **Step 5: 리뷰 수정 범위 자체 검토**

Run:

```sh
git diff 97745c46..HEAD --check
git log --oneline 97745c46..HEAD
```

Expected: Task 2 리뷰 지적을 해결하는 정책·controller·테스트·계획 문서만 포함되고 공백 오류가 없다.

Result: `git diff 97745c46..HEAD --check`는 출력 없이 통과했다. `git log --oneline
97745c46..HEAD`에서 리뷰 수정 계획 `a67fdb30` 뒤 Step 1~4가
`f70a982b` → `998a5330` → `699f7d12` → `95469fd9` 순서와 지정 메시지로 분리됐음을 확인했다.
변경 파일은 반복 삭제 정책, base controller, 세 집중 테스트 파일, 본 계획 문서뿐이었다. 자체 검토에서
callback-before-capture는 저장 문맥을 capture 시점에 한 번 소비하고, timer/release checkpoint는
`noDeletion`/cancel 전에만 현재 문맥을 확인하며, authoritative mutation은 요청 전 suffix에 순서대로 적용한
예상 앞 문맥이 실제 값과 일치할 때만 Undo와 피드백으로 전달됨을 확인했다. 변경된 `afterInput`, 종료된 반복
입력, 요청 없음, nil/empty 차이만 있는 문맥은 확정하지 않으며, 성공과 무효 요청은 기존처럼 한 번만 소비된다.
Context7의 Apple UIKit 문서에서 custom keyboard가 `textDocumentProxy`의 삽입점 앞·뒤 문맥을 사용하고
`UIInputViewController`가 문서 내용·삽입점 변경에 응답하는 구조도 다시 확인했다.

### Task 3: 전체 검증과 메시지 앱 수동 검증 문서화

**Files:**
- Modify: `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`

**Interfaces:**
- Consumes: Task 1~2의 최종 구현
- Produces: 전체 테스트, extension 빌드, 수동 검증 체크리스트와 실제 결과

- [x] **Step 1: 전체 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

Expected: 전체 테스트 실패 0개.

Result: XcodeBuildMCP의 `session_show_defaults`와 `list_sims`로 대상을 확인한 뒤,
`SYKeyboard` scheme과 iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)을 session defaults로 지정하고 `test_sim`을 실행했다.
전체 281개 테스트가 통과했고 실패·건너뜀은 각각 0개였다. 실행 시간은 51.345초였다. 외부
Meta/FBAudienceNetwork 및 Apple SDK module의 `.pcm` 경로를 찾지 못한다는 진단 경고가 있었지만
XcodeBuildMCP 결과의 오류와 test failure는 0개였다.

- [x] **Step 2: 양쪽 extension 최종 빌드**

Task 2 Step 6의 `HangeulKeyboard`, `EnglishKeyboard` build 명령을 다시 실행한다.

Expected: 두 scheme 모두 `BUILD SUCCEEDED`.

Result: iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)을 유지하고 XcodeBuildMCP session defaults의 scheme을
각각 `HangeulKeyboard`, `EnglishKeyboard`로 전환해 `build_sim`을 실행했다. 한글 extension은
9.400초, 영문 extension은 5.601초에 각각 `SUCCEEDED`로 완료됐고 오류는 없었다. 한글 extension에는
Step 1과 같은 외부 Meta/FBAudienceNetwork 및 Apple SDK module `.pcm` 경로 진단 경고가 있었고,
영문 extension에는 경고가 없었다.

- [x] **Step 3: 메시지 앱 수동 검증 항목 기록**

실제 기기에서 다음 순서로 검증하고 결과를 이 문서에 기록한다.

```text
1. 메시지 앱에 "가나\n다라\n마바\n" 입력
2. 키보드 드래그로 줄 사이를 여러 번 왕복
3. 키보드 드래그로 마지막 줄바꿈 뒤에 커서 배치
4. 삭제 버튼을 길게 눌러 전부 삭제
5. SY키보드 undo 버튼을 한 번 누름
6. 결과가 "가나\n다라\n마바\n"과 정확히 같은지 확인
7. 문서 시작에서 버튼 UI가 해제되고 touchDown 외 추가 피드백이 없는지 확인
8. 한글·영문 키보드에서 같은 순서를 반복
```

자동화 환경에서 실행하지 못한 물리 UI·사운드·햅틱 항목은 `미검증`으로 명시한다.

Result: **BLOCKED / 수동 handoff 필요.** `build-ios-apps:ios-debugger-agent` 지침과
XcodeBuildMCP만 사용했다. 당시 booted 상태였던 iPhone Air / iOS 26.5
(`22449D97-7BEB-486D-BE47-B0AA91738DF8`)에 `SYKeyboard`를 `build_run_sim`으로 설치·실행한 뒤,
설정 앱의 `일반 > 키보드 > 키보드` 목록에서 `영어 — SY키보드`와 `한글 — SY키보드`가 모두
등록된 것을 UI snapshot으로 확인했다. 각 상세 화면의 screenshot에서 `전체 접근 허용` 스위치가
녹색 ON인 것도 확인했다.

Messages의 `+1 (888) 555-1212` 대화에서 입력 필드를 열었으나 표시된 것은 SY키보드가 아닌 시스템
한글 키보드였다. XcodeBuildMCP runtime snapshot은 지구본을 `다음 키보드` element로 노출했지만,
해당 element에 `long_press` 또는 touch-down을 보내면 키보드 선택 목록이 아니라 `숫자` 키가 눌려
숫자 레이아웃으로 전환됐다. `type_text`는 한글을 AXe가 지원하지 않는 문자로 거부했다. 따라서 실제
SY키보드로 전환됐음을 식별하지 못했고, 시스템 키보드에서 발생한 입력 결과는 검증 결과로 사용하지 않았다.

수동 handoff는 현재 Messages 입력 화면에서 지구본을 길게 눌러 목록을 띄우고
`한글 — SY키보드`를 명시적으로 선택하는 것부터 시작해야 한다. 그 후 위 1~7 순서를 수행하고, 원문을
다시 만든 뒤 지구본 목록에서 `영어 — SY키보드`를 명시적으로 선택해 같은 순서를 반복해야 한다.
두 flow의 정확한 원문 복원, 문서 시작에서 버튼 UI 해제, touchDown 외 추가 sound/haptic 부재는 모두
`미검증`이다. Simulator에서는 물리 햅틱을 검증할 수 없다.

- [x] **Step 4: 변경 범위와 문서 자체 검증**

Run:

```sh
git diff --check
git status --short
git log --oneline -8
```

Expected: 공백 오류가 없고 Task 3 문서 변경만 미커밋 상태다.

Result: Step 3 커밋 직후 `git diff --check`와 `git status --short`는 모두 출력이 없어 공백 오류와
미커밋 변경이 없었다. `git log --oneline -8`에서 Task 3 Step 1~3이 `8a98f684` →
`c73344fa` → `7f05c628` 순서와 지정 메시지로 분리됐고, 기준 `e16e559f` 이후 Task 3 변경은 본 계획
문서뿐임을 확인했다. 이 결과를 기록한 현재 미커밋 변경도 본 계획 문서뿐이다.

- [x] **Step 5: 최종 검증 기록 자체 검토**

이 문서의 모든 Step이 실제 결과와 함께 체크되어 있는지, 실패·미검증 항목이 성공으로 표현되지 않았는지
확인하고 검토 결과를 기록한다.

Result: Task 3 Step 1~5가 모두 실제 결과와 함께 체크됐음을 다시 읽어 확인했다. 전체 테스트
281개 통과와 양쪽 extension build 성공은 XcodeBuildMCP 결과 그대로 기록했다. Step 3은 Settings의
extension 등록과 전체 접근 ON까지만 확인 완료로 분리했고, Messages의 시스템 키보드 상태는 폐기했다.
실제 SY키보드 전환 이후의 한글·영문 flow, 버튼 해제, 추가 sound/haptic 부재는 `BLOCKED`와
`미검증`으로 유지했으며 물리 햅틱을 Simulator 검증 성공으로 표현하지 않았다. 기준 `e16e559f` 이후
production 코드 변경은 없고 Step 1~4 계획 문서 커밋은 4개로 분리됐다. 이 Step 기록은 지정 메시지의
다섯 번째 문서 커밋으로 분리한다.

---

## 2026-07-25 History Compaction 정정

이 문서의 `97745c46..HEAD`, `239a1657..HEAD`, `e16e559f` 및 개별 Step SHA는 사용자 요청에 따른
history compaction 전 실행 기록이다. 해당 SHA object가 로컬에 남아 있더라도 현재 branch 이력에서는
unreachable이므로 현재 범위나 재현 가능한 Step commit으로 해석하지 않는다. compaction 직전 최종
commit `46990093`과 compaction 후 `afb74ad4`의 tree는
`406ac51d160781c2ba9bad3b9429ba8881693b6d`로 동일하다.

현재 branch에서 도달 가능한 task-level commit은 다음 8개다.

| 순서 | Commit | 내용 |
|---|---|---|
| 1 | `a046505b` | 반복 삭제 mutation 계획과 실행 기준 정리 |
| 2 | `0f747742` | 반복 삭제 mutation 확인 상태 추가 |
| 3 | `d676e881` | 반복 삭제 요청과 callback undo 검증 |
| 4 | `8e3a4aab` | 반복 삭제 실제 mutation 최종 검증 |
| 5 | `d05cad5e` | 반복 삭제 tick 처리 설계 및 계획 |
| 6 | `dbf5d89f` | 반복 삭제 callback과 선택 상태 검증 |
| 7 | `b73f0e7e` | 반복 삭제 tick당 단일 호출 속도 유지 |
| 8 | `afb74ad4` | 반복 삭제 tick 최종 검증 |

`.superpowers/sdd/task-1-confirmed-undo-report.md`는 scratch ignore 규칙이 기존 tracked 파일을 자동으로
제외하지 못해 남아 있던 파일이며, 2026-07-25 최종 리뷰 수정에서 index와 tree에서 제거했다.

최종 리뷰에서 발견된 초기 delete `.touchDown` 순서 결함은 controller가 사용하는
`DeleteMutationLifecycle` 회귀 테스트로 보완한다. 테스트 controller/proxy harness가 없어 실제
`UIInputViewController` instance를 직접 구동하지는 못하며, production lifecycle 정책으로
touchDown-before-capture, callback-before/after-capture, tap release, English timer 전환, Hangeul 즉시
첫 repeat, 첫 proxy 후보와 실제 줄바꿈 불일치 및 grouped Undo/Redo를 검증한다.

Messages의 실제 한글·영문 8개 수동 항목은 여전히 `사용자 검증 대기`다. 이 자동 검증은 실제 앱의
체감 cadence, 버튼 해제, Undo/Redo UI, 사운드·햅틱을 통과한 것으로 대체하지 않는다.

2026-07-25 최종 리뷰 수정 자동 검증은 iPhone 13 mini / iOS 16.0에서 신규 lifecycle 집중 테스트
RED(신규 production 타입 부재 컴파일 실패) 후 release-before-callback 리뷰 회귀 RED를 추가로 확인했고,
최종 GREEN에서 7개가 통과했다. release된 touchDown 요청은 다음 callback과 조정할 때까지 보존하고,
확인 전 long press 전환은 다음 mutation을 만들지 않으며, 한글 즉시 전환 후 반복 상태가 끝났다면
timer를 다시 만들지 않도록 보완했다. 최종 전체 suite는 293개 통과, 실패·skip 0개였고, sandbox 권한
오류를 분리한 권한 있는 재실행에서 `HangeulKeyboard`와 `EnglishKeyboard` build가 모두 성공했다.

### 2026-07-25 최종 재리뷰 Cycle 4 수정

재리뷰의 Critical finding에 따라 확인되지 않은 repeat tick을 gesture release에서 취소하지 않고
`releasedRepeatTick`으로 보존한다. unchanged newline checkpoint 뒤 release가 먼저 발생해도 지연된
`textDidChange(_:)`가 mutation을 한 번 확정하고 grouped Undo/Redo에 줄바꿈을 포함하며 repeat
feedback을 한 번만 요청한다. 관련 없는 callback이 확인에 실패하면 released 요청을 즉시 폐기해 이후
callback이나 입력에 남기지 않는다.

Important finding에 따라 lifecycle의 새 요청 시작이 기존 pending 요청을 덮어쓰지 않도록
`DeleteMutationStartResult`로 gate한다. 확인되지 않은 released touchDown 뒤 두 번째 delete touchDown은
새 삭제를 실행하지 않는다. non-delete 일반 입력과 long press repeat는 실제 edit 전에
`prepareForNonDeleteEdit()`로 released 요청을 정리하고, capture에도 같은 방어를 적용해 새 삽입 mutation이
이전 삭제 요청에 흡수되지 않게 한다. initial touchDown feedback, 확인된 repeat feedback 한 번,
English timer와 Hangeul 즉시 repeat 의미, `max(0.01, 0.10 - repeatRate)` 간격과 tick당 최대 한 번의 새
삭제는 유지한다.

정확한 lifecycle 집중 명령은 production 수정 전 exit 65와 `** TEST FAILED **`를 반환했다.
`beginTouchDown`의 `.started`/`.awaitingPreviousMutation` 계약 부재로 3개 build command가 실패한
예상 RED였다. self-review에서 callback-before-capture 순서를 추가한 뒤에는
`prepareForNonDeleteEdit` 부재로 같은 명령이 다시 예상 RED를 보였다. 최소 구현 뒤 최종 focused
GREEN은 lifecycle 테스트 11개 통과였다.

최종 전체 `SYKeyboard` suite는 iPhone 13 mini / iOS 16.0에서 297개 통과, 실패·skip·expected failure
0개였다. 같은 대상의 `HangeulKeyboard`와 `EnglishKeyboard` build는 모두
`** BUILD SUCCEEDED **`였다. Messages 한글·영문 8개 수동 항목과 실제 사운드·햅틱은 여전히
`사용자 검증 대기`이며 자동 검증 성공으로 표현하지 않는다.

### 2026-07-25 최종 재리뷰 Cycle 5 수정

callback이 오지 않는 문서 시작의 최초 삭제는 선택 영역이 없고, 요청 전·후 문맥이 모두 비어 있으며,
현재 문맥이 변하지 않고, draft가 없거나 빈 draft뿐일 때만 `.noDeletion`으로 확정한다. 문맥이 비어
있어도 요청 전 문맥이 비어 있지 않은 줄 경계와 nonempty proxy 후보는 계속 pending으로 남긴다.
proxy suffix 확인에는 `before.hasSuffix(candidate.deletedText)`를 추가해 빈 `before`에서 nonempty
후보를 성공으로 잘못 확정하지 않는다. ordinary release는 기존처럼 요청을 정리하며, Hangeul 즉시
long press와 English timer는 확정된 `.noDeletion`을 `.finishWithoutDeletion`으로 소비해 timer와
버튼 상태를 종료한다.

확인되지 않은 released 요청이 남은 상태에서 두 번째 delete touchDown이 오면 요청을 덮어쓰거나 새
삭제를 실행하지 않고 deferred intent를 기록한다. 앞 요청이 callback 또는 checkpoint에서
확정·취소된 뒤 현재 문맥으로 deferred touchDown을 한 번만 실행하며, 기존 touchDown 피드백을
중복하지 않는다. delete pan도 같은 명시적 boundary를 통과한다. 앞 요청이 모호하면 방향을 queue하고,
late callback으로 앞 요청을 조정한 뒤 pan 방향을 한 번 적용해 최초 줄바꿈과 pan 삭제가 grouped
Undo/Redo에 함께 남도록 했다.

production 수정 전 정확한 focused 명령은 다음 계약이 없어 exit 65와 `** TEST FAILED **`를
반환했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DeleteMutationLifecycleTests
```

예상한 컴파일 실패는 `.deferred`, `beginDeferredTouchDown`, `actionForDeletePan` 부재였다. 기존 11개
회귀를 유지하고 문서 시작 no-op, Hangeul/English long press 종료, nonempty proxy 대기, deferred
두 번째 tap, pan boundary와 grouped Undo/Redo를 다루는 5개를 추가했다. 기본 병렬 focused GREEN
시도는 cloned Simulator 결과 정리에서 `simctl diagnose --timeout=600` 상태로 멈춰 해당
`xcodebuild` process만 종료했다. 동일 코드와 대상을 `-parallel-testing-enabled NO`로 재실행한
최종 focused GREEN은 16개 모두 통과, exit 0, `** TEST SUCCEEDED **`였다.

최종 전체 suite도 같은 non-parallel 안정화 옵션으로 새로 실행해 35 suites의 302개 테스트가 모두
통과했고 exit 0, `** TEST SUCCEEDED **`였다. 같은 iPhone 13 mini / iOS 16.0 대상에서
`HangeulKeyboard`와 `EnglishKeyboard` build는 기본 sandbox의 CoreSimulator·SwiftPM/clang cache
권한 오류(exit 74)를 분리한 뒤 동일 명령을 권한 있는 환경에서 재실행해 각각 exit 0,
`** BUILD SUCCEEDED **`를 확인했다. Messages 한글·영문 8개 수동 항목과 실제 사운드·햅틱은 계속
`사용자 검증 대기`다.
