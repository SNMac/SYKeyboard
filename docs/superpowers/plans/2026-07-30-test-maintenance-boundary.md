# 테스트 유지보수 경계 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 시각 구현에 결합된 unit test와 production 경로를 복제하는 test helper를 정리하면서 키 입력·한글 조합·자동완성 상호작용 회귀 계약은 유지한다.

**Architecture:** 자동완성 highlight 우선순위를 UIKit view 내부 상태에서 순수 `SuggestionHighlightPolicy`로 분리한다. 한글 삭제 시나리오는 test helper가 committed/composing 전이를 복제하지 않고 production `HangeulCompositionState`를 소유한 공통 harness를 사용한다. 정확한 색상·effect·SF Symbol·private view 계층 검증은 unit test 범위에서 제거한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+, iOS 16+
## Global Constraints

- 키보드 입력, 한글 조합, 자동완성 결과, 삭제·복구·커서 이동·제스처 타이밍을 변경하지 않는다.
- 자동완성 후보의 스크롤 없음·두 줄·자동 축소·`minimumScaleFactor = 0.7`·중간 생략 계약을 유지한다.
- `SuggestionBarView`의 endpoint 기반 후보 선택, 햅틱·소리, divider 동작을 유지한다.
- production 클래스에 새 `ForTesting` API를 추가하지 않는다.
- Firebase, AdMob, entitlements, bundle identifier, provisioning 설정을 변경하지 않는다.
- 각 Task는 코드·테스트·계획 문서의 실제 검증 결과를 함께 커밋한다.
- 기본 검증 destination은 `iPhone 13 mini / iOS 16.0`이며, 없으면 사용 가능한 가장 가까운 iOS 16+ Simulator를 사용하고 실제 destination을 기록한다.

---

## File Structure

- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift`
  - preview/touch/action highlight 우선순위를 UI 타입 없이 계산한다.
- Create: `SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift`
  - highlight 의미 상태와 유효 index 경계를 검증한다.
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
  - 정책 결과를 실제 suggestion/action 버튼에 반영하고 DEBUG test API를 제거한다.
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift`
  - exact color, `Mirror`, private 타입명 검색을 제거하고 명시된 label/endpoint 계약만 유지한다.
- Delete: `SYKeyboardTests/Utils/CursorDragOverlayTests.swift`
  - UIKit effect, SF Symbol, vibrancy hierarchy 고정 테스트를 제거한다.
- Delete: `SYKeyboardTests/Utils/ReturnButtonTests.swift`
  - template rendering과 exact tint 고정 테스트를 제거한다.
- Move: `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift` → `SYKeyboardTests/Utils/HangeulCompositionTestHarness.swift`
  - production `HangeulCompositionState` 기반 상태 시나리오 harness로 책임과 이름을 맞춘다.
- Modify: `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`
  - 공통 harness 이름과 검증 범위를 반영한다.
- Modify: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`
- Modify: `SYKeyboardTests/Processor/DubeolsikProcessorTests.swift`
- Modify: `SYKeyboardTests/Processor/NaratgeulProcessorTests.swift`
  - controller 수준 삭제 시나리오와 전체 글자 삭제 검증을 production state harness로 이동한다.
- Modify: `SYKeyboardTests/Utils/HangeulProcessorTestable.swift`
  - controller 상태 전이를 복제하는 `applyDelete`를 제거하고 processor 입력 helper 책임만 남긴다.
- Modify: `AGENTS.md`
  - 테스트 허용·금지 경계, production 진입점 요구, 예시 체크리스트를 추가한다.
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`
  - 각 Task의 실제 명령, destination, 테스트 수, 성공·실패 결과를 완료 직후 기록한다.

---

### Task 1: 시각 구현 고정 테스트 제거

**Files:**
- Delete: `SYKeyboardTests/Utils/CursorDragOverlayTests.swift`
- Delete: `SYKeyboardTests/Utils/ReturnButtonTests.swift`
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift:95-143`
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Consumes: 기존 `KeyboardPresentationStatePolicyTests`의 return 활성 조건 검증
- Produces: exact effect, symbol, rendering mode, tint, label color에 결합되지 않은 test suite

- [x] **Step 1: 삭제 전 관련 테스트의 현재 상태를 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CursorDragOverlayTests \
  -only-testing:SYKeyboardTests/ReturnButtonTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests
```

Expected: 기존 세 suite가 통과한다. 실제 destination과 각 suite의 테스트 수를 이
계획 문서 Task 1 아래에 기록한다.

- [x] **Step 2: visual implementation test를 제거**

Delete:

```text
SYKeyboardTests/Utils/CursorDragOverlayTests.swift
SYKeyboardTests/Utils/ReturnButtonTests.swift
```

`SuggestionBarViewPreviewHighlightTests.swift`에서 다음 테스트와 helper를 제거한다.

```text
test기본자동완성후보라벨은_iOS버전에맞는색상으로표시
testPreview하이라이트후보라벨은_Label색상으로표시
test수식후보도_하이라이트여부만으로_라벨색상을결정
expectedDefaultSuggestionLabelColor()
```

이 Step에서는 production UI 코드를 변경하지 않는다.

- [x] **Step 3: 제거된 시각 단언이 남지 않았는지 확인**

Run:

```sh
rg -n \
  'CursorDragOverlayTests|ReturnButtonTests|expectedDefaultSuggestionLabelColor|UIGlassEffect|UIVibrancyEffect|returnButtonDisabledLabel' \
  SYKeyboardTests
```

Expected: 삭제 대상 visual test와 helper가 검색되지 않는다. 다른 의미의
`returnButtonDisabledLabel` 사용이 검색되면 test assertion인지 확인해 결과를
기록한다.

- [x] **Step 4: 남은 suggestion bar 계약 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests
```

Expected: label 롤백, endpoint 선택, highlight 상태, return 활성 조건 테스트가
통과한다.

- [x] **Step 5: Task 1 결과 기록 및 커밋**

계획 문서의 Task 1에 실제 destination, 실행 명령, 통과·실패·skip 개수를
기록하고 Step 1~5 체크박스를 완료 처리한다.

```sh
git add \
  SYKeyboardTests/Utils/CursorDragOverlayTests.swift \
  SYKeyboardTests/Utils/ReturnButtonTests.swift \
  SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
  docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "test: 시각 구현 고정 검증 제거"
```

#### Task 1 실행 결과 (2026-07-30)

- Destination: `platform=iOS Simulator,name=iPhone 13 mini,OS=16.0` (선택된 기기: `iPhone 13 mini`, iOS 16.0, arm64, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`).
- Step 1: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CursorDragOverlayTests -only-testing:SYKeyboardTests/ReturnButtonTests -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests`를 실행했다. 기본 샌드박스 실행은 CoreSimulator/SwiftPM 캐시 권한 오류로 테스트 시작 전 실패했고, 같은 명령을 권한 있는 환경에서 재실행했다. suite 정의 기준 `CursorDragOverlayTests` 5개, `ReturnButtonTests` 2개, `SuggestionBarViewPreviewHighlightTests` 9개가 통과했다(통과 16, 실패 0, skip 0).
- Step 2: `CursorDragOverlayTests.swift`, `ReturnButtonTests.swift`와 suggestion label 색상 단언 3개 및 `expectedDefaultSuggestionLabelColor()`를 제거했다. production UI 코드는 변경하지 않았다.
- Step 3: `rg -n 'CursorDragOverlayTests|ReturnButtonTests|expectedDefaultSuggestionLabelColor|UIGlassEffect|UIVibrancyEffect|returnButtonDisabledLabel' SYKeyboardTests` 결과는 비어 있었다. 따라서 다른 의미의 `returnButtonDisabledLabel` 사용도 남지 않았다.
- Step 4: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests`를 실행했다. 기본 샌드박스 실행은 CoreSimulator/SwiftPM 캐시 권한 오류로 테스트 시작 전 실패했고, 같은 명령을 권한 있는 환경에서 재실행했다. `SuggestionBarViewPreviewHighlightTests` 6개와 `KeyboardPresentationStatePolicyTests` 6개가 통과했다(통과 12, 실패 0, skip 0).

---

### Task 2: 자동완성 highlight 의미 정책 분리

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift`
- Create: `SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift:42-45,270-311,410-439`
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift:69-93,145-223`
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Produces: `SuggestionHighlightPolicy.State`
- Produces: `SuggestionHighlightPolicy.resolve(previewSuggestionIndex:touchedSuggestionIndex:touchedActionIndex:suggestionCount:actionCount:) -> State`
- Consumes: `SuggestionBarView`의 preview/touch index와 suggestion/action button 개수

- [x] **Step 1: pure policy 실패 테스트 작성**

Create `SuggestionHighlightPolicyTests.swift`:

```swift
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 highlight 정책 검증")
struct SuggestionHighlightPolicyTests {

    @Test("preview는 해당 후보만 강조")
    func testPreviewSuggestion() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == 1)
        #expect(state.highlightedActionIndex == nil)
    }

    @Test("후보 touch는 preview를 일시 대체하고 touch 종료 시 preview가 복원")
    func testSuggestionTouchOverridesPreview() {
        let touched = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: 2,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let restored = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(touched.highlightedSuggestionIndex == 2)
        #expect(restored.highlightedSuggestionIndex == 1)
    }

    @Test("action touch는 preview를 가리고 action만 강조")
    func testActionTouchOverridesPreview() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: 0,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == nil)
        #expect(state.highlightedActionIndex == 0)
    }

    @Test("nil과 범위 밖 index는 강조하지 않음")
    func testNilAndOutOfRangeIndexes() {
        let nilState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: nil,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let invalidState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 3,
            touchedSuggestionIndex: -1,
            touchedActionIndex: 2,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(nilState == .none)
        #expect(invalidState == .none)
    }
}
```

- [x] **Step 2: 새 policy 테스트가 RED인지 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests
```

Expected: `SuggestionHighlightPolicy`가 없어서 compile failure가 발생한다. 실패
원인이 새 production 타입 부재인지 기록한다.

- [x] **Step 3: 최소 highlight policy 구현**

Create `SuggestionHighlightPolicy.swift`:

```swift
enum SuggestionHighlightPolicy {

    struct State: Equatable {
        let highlightedSuggestionIndex: Int?
        let highlightedActionIndex: Int?

        static let none = State(
            highlightedSuggestionIndex: nil,
            highlightedActionIndex: nil
        )
    }

    static func resolve(
        previewSuggestionIndex: Int?,
        touchedSuggestionIndex: Int?,
        touchedActionIndex: Int?,
        suggestionCount: Int,
        actionCount: Int
    ) -> State {
        if let touchedSuggestionIndex,
           (0..<suggestionCount).contains(touchedSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: touchedSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        if let touchedActionIndex,
           (0..<actionCount).contains(touchedActionIndex) {
            return State(
                highlightedSuggestionIndex: nil,
                highlightedActionIndex: touchedActionIndex
            )
        }

        if let previewSuggestionIndex,
           (0..<suggestionCount).contains(previewSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: previewSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        return .none
    }
}
```

후보 touch와 action touch가 동시에 존재할 수 없다는 기존
`SuggestionBarView.updateHighlight(at:)` 계약을 유지한다.

- [x] **Step 4: policy 테스트 GREEN 확인**

Run the Step 2 command again.

Expected: `SuggestionHighlightPolicyTests` 4개가 통과한다.

- [x] **Step 5: SuggestionBarView가 policy를 사용하도록 refactor**

`SuggestionBarView`의 touch view reference를 의미 index로 변경한다.

```swift
private var touchedSuggestionIndex: Int?
private var touchedActionIndex: Int?
private var previewHighlightIndex: Int?
```

`updateHighlight(at:)`는 hit test 결과에서 index를 저장하고,
`clearTouchHighlights()`는 두 touch index를 `nil`로 만든다.
`applyHighlights()`는 다음처럼 policy 결과만 view에 반영한다.

```swift
let state = SuggestionHighlightPolicy.resolve(
    previewSuggestionIndex: previewHighlightIndex,
    touchedSuggestionIndex: touchedSuggestionIndex,
    touchedActionIndex: touchedActionIndex,
    suggestionCount: suggestionButtons.count,
    actionCount: undoRedoButtons.count
)

for (index, button) in suggestionButtons.enumerated() {
    button.isHighlighted = state.highlightedSuggestionIndex == index
}
for (index, button) in undoRedoButtons.enumerated() {
    button.isHighlighted = state.highlightedActionIndex == index
}
```

다음을 삭제한다.

```text
#if DEBUG updateTouchHighlightForTesting(index:)
#if DEBUG updateUndoRedoTouchHighlightForTesting(index:)
touchHighlightedSuggestionButton
touchHighlightedActionButton
```

- [x] **Step 6: brittle view-state 테스트와 helper 제거**

`SuggestionBarViewPreviewHighlightTests.swift`에서 policy 테스트로 이동한 다음
테스트를 제거한다.

```text
testPreview하이라이트인덱스는_해당후보버튼만강조
testPreview하이라이트를Nil로갱신하면_모든후보강조를해제
test다른후보를누르는동안_Preview하이라이트는_터치후보로대체
testUndoRedo를누르는동안_Preview하이라이트는_액션버튼으로대체
```

다음 helper도 제거한다.

```text
suggestionButtonViews(in:)
isSuggestionButtonHighlighted(_:)
suggestionActionButtonViews(in:)
isSuggestionActionButtonHighlighted(_:)
```

label 롤백 테스트와 endpoint 선택 테스트에 필요한 typed view, label,
scroll view, coordinate helper는 유지한다.

- [x] **Step 7: production test seam과 reflection 제거 확인**

Run:

```sh
rg -n \
  'ForTesting|Mirror\\(|String\\(describing: type\\(of: subview\\)\\)' \
  Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
  SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
  SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift
```

Expected: 검색 결과가 없다.

- [x] **Step 8: highlight와 실제 touch 회귀 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests
```

Expected: policy 4개와 남은 label/endpoint view 테스트가 통과한다.

- [x] **Step 9: Task 2 결과 기록 및 커밋**

계획 문서의 Task 2에 RED/GREEN 결과, 실제 destination, 테스트 수를 기록하고
Step 1~9 체크박스를 완료 처리한다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift \
  Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
  SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift \
  SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
  docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "refactor: 자동완성 highlight 상태 정책 분리"
```

#### Task 2 실행 결과 (2026-07-30)

- Destination: `platform=iOS Simulator,name=iPhone 13 mini,OS=16.0` (선택된 기기: `iPhone 13 mini`, iOS 16.0, arm64, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`).
- Step 2 RED: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests`를 실행했고, 새 production 타입이 없는 상태에서 `cannot find 'SuggestionHighlightPolicy' in scope`로 compile failure가 발생했다(exit 65). 테스트 오타나 실행 환경이 아니라 의도한 타입 부재가 실패 원인이었다.
- Step 4 GREEN: 최소 policy 파일 생성 직후 같은 명령을 실행했으나 file-system-synchronized `Modules` group의 기존 인접 policy와 달리 새 파일의 target membership이 등록되지 않아 타입 부재가 계속됐다. 계획 작성자 승인 후 `SYKeyboard.xcodeproj/project.pbxproj`의 인접 policy와 동일한 두 `membershipExceptions` 목록에 새 경로만 최소 추가했다. 재실행 결과 `SuggestionHighlightPolicyTests` 4개가 통과했다(통과 4, 실패 0, skip 0).
- Step 5~6: `SuggestionBarView`의 touch view reference를 suggestion/action index로 교체하고 `SuggestionHighlightPolicy` 결과만 버튼에 반영했다. DEBUG test seam 2개, reflection 기반 view-state 테스트 4개와 전용 helper 4개를 제거했다. 후보 라벨의 스크롤 없음·두 줄·`minimumScaleFactor == 0.7`·가운데 생략 계약과 drag endpoint 선택 테스트, 기존 feedback·divider 적용 경로는 유지했다.
- Step 7: `rg -n 'ForTesting|Mirror\\(|String\\(describing: type\\(of: subview\\)\\)' Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift` 결과는 비어 있었다(exit 1, no matches).
- Step 8: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests`를 실행했다. policy 4개와 남은 label/endpoint view 테스트 2개가 통과했다(통과 6, 실패 0, skip 0).

---

### Task 3: production 한글 상태 harness 통합과 synthetic 자동완성 제거

**Files:**
- Move: `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift` → `SYKeyboardTests/Utils/HangeulCompositionTestHarness.swift`
- Modify: `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
- Modify: `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Produces: `HangeulCompositionTestHarness.init(processor:)`
- Produces: `HangeulCompositionTestHarness.text`, `committedBuffer`, `composingBuffer`
- Produces: production `HangeulCompositionState`를 호출하는 `input`, `space`, `delete`, `repeatInsert`, `repeatDelete`, `deleteButtonTouchDown`, `dragDeleteLeft`, `dragRestoreRight`, `finishRepeatDelete`, `repeatStart`
- Removes: `KeyboardControllerSimulator.suggestionCurrentWord`

- [ ] **Step 1: synthetic 자동완성 테스트가 실제 production gap을 잡지 못함을 기록**

Read-only confirmation:

```sh
rg -n \
  'suggestionCurrentWord|updateSuggestionCurrentWord|SuggestionController|inputBuffer' \
  SYKeyboardTests/Utils/KeyboardControllerSimulator.swift \
  SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift
```

Expected: simulator 내부 대입과 해당 assertion만 검색되고 production
`SuggestionController`/`inputBuffer` 호출은 검색되지 않는다. 결과를 Task 3에
기록한다.

- [ ] **Step 2: harness 이름과 initializer를 실제 책임에 맞게 변경**

파일과 타입을 다음처럼 변경한다.

```text
KeyboardControllerSimulator.swift → HangeulCompositionTestHarness.swift
KeyboardControllerSimulator → HangeulCompositionTestHarness
init(automata:processor:) → init(processor:)
```

기존 initializer의 사용하지 않는 `automata` parameter를 제거한다.
모든 controller suite call site를 새 타입과 initializer로 갱신한다.

- [ ] **Step 3: synthetic suggestion 상태와 테스트 제거**

Harness에서 다음을 제거한다.

```text
suggestionCurrentWord
updateSuggestionCurrentWord()
input/deleteButtonTouchDown/dragDeleteLeft/dragRestoreRight의 synthetic update 호출
```

`HangeulDeleteButtonDragControllerTests`에서
`test두벌식_삭제버튼드래그_전체복구후_자동완성현재단어동기화`를 제거한다.
삭제·복구 text와 composing buffer를 확인하는 기존 테스트는 유지한다.

- [ ] **Step 4: suite 설명을 검증 범위에 맞게 갱신**

`Controller` 폴더의 suite 이름과 harness 문서에서 “실제 ViewController 통합”
의미를 제거하고 `HangeulCompositionState 기반 입력 상태 시나리오`임을
명시한다. 파일 경로는 이번 Task에서 이동하지 않는다.

- [ ] **Step 5: synthetic 경로 제거 확인**

Run:

```sh
rg -n \
  'KeyboardControllerSimulator|suggestionCurrentWord|updateSuggestionCurrentWord|init\\(automata:' \
  SYKeyboardTests
```

Expected: 검색 결과가 없다.

- [ ] **Step 6: 한글 상태 시나리오 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests \
  -only-testing:SYKeyboardTests/CheonjiinControllerTests \
  -only-testing:SYKeyboardTests/DubeolsikControllerTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests \
  -only-testing:SYKeyboardTests/NaratgeulControllerTests
```

Expected: synthetic 자동완성 테스트를 제외한 production state 시나리오가 모두
통과한다.

- [ ] **Step 7: Task 3 결과 기록 및 커밋**

계획 문서의 Task 3에 검색 결과, 실제 destination, 테스트 수를 기록하고
Step 1~7 체크박스를 완료 처리한다.

```sh
git add \
  SYKeyboardTests/Utils/KeyboardControllerSimulator.swift \
  SYKeyboardTests/Utils/HangeulCompositionTestHarness.swift \
  SYKeyboardTests/Controller/CheonjiinControllerTests.swift \
  SYKeyboardTests/Controller/DubeolsikControllerTests.swift \
  SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift \
  SYKeyboardTests/Controller/NaratgeulControllerTests.swift \
  docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "test: 한글 상태 시나리오 harness 책임 정리"
```

---

### Task 4: processor 삭제 시나리오를 production state로 이동

**Files:**
- Modify: `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`
- Modify: `SYKeyboardTests/Processor/DubeolsikProcessorTests.swift`
- Modify: `SYKeyboardTests/Processor/NaratgeulProcessorTests.swift`
- Modify: `SYKeyboardTests/Utils/HangeulProcessorTestable.swift`
- Consume: `SYKeyboardTests/Utils/HangeulCompositionTestHarness.swift`
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Consumes: `HangeulCompositionTestHarness.init(processor:)`
- Removes: `HangeulProcessorTestable.applyDelete(committed:composing:)`
- Retains: `HangeulProcessorTestable.applyInput(_:committed:composing:)` for processor input-result scenarios only

- [ ] **Step 1: applyDelete 사용 위치를 고정**

Run:

```sh
rg -n 'applyDelete\\(' SYKeyboardTests/Processor SYKeyboardTests/Utils/HangeulProcessorTestable.swift
```

Expected: `HangeulProcessorTestable` 구현 1곳과 processor suite call site 13곳이
검색된다. 실제 개수가 다르면 계획 문서에 기록하고 검색된 모든 call site를
이번 Task 범위에 포함한다.

- [ ] **Step 2: 삭제 시나리오 테스트를 production state harness로 변경**

입력부터 삭제까지 이어지는 각 테스트는 다음 패턴으로 바꾼다.

```swift
let harness = HangeulCompositionTestHarness(processor: processor)
["ㄱ", "ㅏ", "ㄹ", "ㄱ", "ㅏ"].forEach(harness.input)

#expect(harness.text == "갈가")

harness.delete()

#expect(harness.text == "갉")
```

각 입력기 고유 키(`천`, `지`, `인`, `획`, `쌍`)는 기존 순서를 그대로 사용한다.
한 테스트 안에서 processor 반환값 자체를 검증하는 단언은 raw processor API를
유지하고, controller 수준의 pull-from-committed 기대만 harness로 옮긴다.

- [ ] **Step 3: 11,172자 삭제 검증을 production state harness로 변경**

각 글자 iteration마다 새 harness를 만들고 기존 변환 입력 sequence를
`harness.input`으로 재생한다. 삭제는 `expectedDeleteCount`만큼
`harness.delete()`를 호출한다.

```swift
let harness = HangeulCompositionTestHarness(processor: processor)
inputSequence.forEach(harness.input)

guard harness.text == targetString else {
    // 기존 logger/failureCount 처리 유지
    continue
}

for _ in 0..<expectedDeleteCount {
    harness.delete()
}
```

processor의 내부 상태가 iteration 사이에 남지 않도록 기존 reset 방식이 있으면
유지하고, 없다면 각 iteration 시작 시 `processor.reset한글조합()`을 호출한다.

- [ ] **Step 4: applyDelete helper 제거**

`HangeulProcessorTestable.swift`에서 `applyDelete` 전체를 제거한다.
`automata`가 `applyDelete`에서만 사용되고 각 conforming suite가 별도로
필요로 하지 않으면 protocol requirement에서도 제거한다. `applyInput` 문서는
processor 입력 결과 누적 helper이며 controller 보호·끌어오기 검증에 사용하지
않는다고 수정한다.

- [ ] **Step 5: helper 중복 제거 확인**

Run:

```sh
rg -n \
  'applyDelete\\(|composing이 비었으면 committed에서 끌어오기|ViewController의 `deleteBackward`를 시뮬레이션' \
  SYKeyboardTests
```

Expected: 검색 결과가 없다.

- [ ] **Step 6: processor와 composition state 집중 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinProcessorTests \
  -only-testing:SYKeyboardTests/DubeolsikProcessorTests \
  -only-testing:SYKeyboardTests/NaratgeulProcessorTests \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests \
  -only-testing:SYKeyboardTests/HangeulAutomataTests
```

Expected: 천지인·두벌식·나랏글 processor, production composition state,
automata 테스트가 모두 통과한다. 전체 글자 테스트의 실제 실행 수와 소요 결과를
기록한다.

- [ ] **Step 7: Task 4 결과 기록 및 커밋**

계획 문서의 Task 4에 migration call site 수, 실제 destination, 테스트 수를
기록하고 Step 1~7 체크박스를 완료 처리한다.

```sh
git add \
  SYKeyboardTests/Processor/CheonjiinProcessorTests.swift \
  SYKeyboardTests/Processor/DubeolsikProcessorTests.swift \
  SYKeyboardTests/Processor/NaratgeulProcessorTests.swift \
  SYKeyboardTests/Utils/HangeulProcessorTestable.swift \
  docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "test: processor 삭제 시나리오 production 상태 사용"
```

---

### Task 5: AGENTS 테스트 작성 계약 반영

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Consumes: Tasks 1~4에서 확정된 테스트 허용·금지 경계
- Produces: 새 테스트 작성 시 바로 적용할 규칙, 예시, 체크리스트

- [ ] **Step 1: 테스트 지침에 허용·금지 규칙 추가**

`AGENTS.md`의 `## 테스트 지침`에 다음 내용을 한국어로 추가한다.

```markdown
- 숫자가 포함되어 있다는 이유만으로 UI 구현 테스트로 판단하지 않는다. 입력
  임계값, 키보드 높이 계산식, 반복 타이머 하한처럼 사용자 동작과 안전성에
  영향을 주는 정책 수치는 검증한다.
- exact color, font, SF Symbol 이름, corner radius, effect subclass, private
  subview 계층, `Mirror` 기반 private 상태는 unit test에서 고정하지 않는다.
- production 동작을 검증한다고 설명하는 테스트는 해당 production 진입점을
  호출해야 한다. helper가 결과를 직접 계산하거나 production 로직을 복제한
  경우 통합 검증으로 인정하지 않는다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. 의미 있는 상태
  계산은 production policy로 분리하고 UI 결과는 공개된 동작으로 검증한다.
- processor 단위 테스트는 processor 반환값을 검증하고, controller 수준의
  committed/composing 상태 전이는 `HangeulCompositionState`를 사용한다.
```

- [ ] **Step 2: 즉시 사용할 예시와 체크리스트 추가**

같은 섹션에 다음 예시와 체크리스트를 추가한다.

```markdown
### 테스트 경계 예시

- 유지: 커서 속도별 이동 step, suggestion bar 표시 여부, 키보드 높이 계산,
  제스처 취소 후 입력 복구
- 제거하거나 실제 화면 검증으로 이동: 정확한 tint, blur/glass 구체 타입,
  SF Symbol 이름, private subview 구조
- 명시적 UI 회귀 계약: 자동완성 후보의 스크롤 없음·두 줄·자동 축소·중간 생략

새 테스트 추가 전 확인:

- 이 테스트가 실패할 production 동작을 한 문장으로 설명할 수 있는가?
- production 진입점을 실제로 호출하는가?
- helper가 기대 결과나 상태 전이를 다시 구현하고 있지 않은가?
- UI 구조가 바뀌어도 사용자 동작이 같으면 통과하는가?
- 시각 속성을 고정한다면 명시된 제품 계약 또는 접근성 요구가 있는가?
```

- [ ] **Step 3: 문서 일관성 확인**

Run:

```sh
rg -n \
  'ForTesting|Mirror|SF Symbol|HangeulCompositionState|테스트 경계 예시|새 테스트 추가 전 확인' \
  AGENTS.md
```

Expected: 모든 신규 규칙과 예시가 검색되며 기존 테스트 지침과 충돌하지 않는다.

- [ ] **Step 4: Task 5 결과 기록 및 커밋**

계획 문서의 Task 5에 추가한 규칙·예시·체크리스트 위치를 기록하고 Step 1~4
체크박스를 완료 처리한다.

```sh
git add \
  AGENTS.md \
  docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "docs: 테스트 코드 작성 경계 반영"
```

---

### Task 6: 전체 회귀 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md`

**Interfaces:**
- Consumes: Tasks 1~5의 test/production/documentation 변경
- Produces: 전체 test와 세 scheme build 결과, 재현 가능한 검증 기록

- [ ] **Step 1: 사용 가능한 Simulator와 scheme 확인**

Run:

```sh
xcodebuild -list -project SYKeyboard.xcodeproj
xcrun simctl list devices available
```

Expected: `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard` scheme과 실제 사용할
iOS 16+ Simulator를 확인한다.

- [ ] **Step 2: 전체 SYKeyboardTests 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 테스트가 실패 없이 통과한다. 총 passed/failed/skipped 개수를
기록한다.

- [ ] **Step 3: 세 production scheme build**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 세 scheme 모두 `BUILD SUCCEEDED`.

- [ ] **Step 4: 정적 범위와 formatting 확인**

Run:

```sh
rg -n \
  'CursorDragOverlayTests|ReturnButtonTests|suggestionCurrentWord|KeyboardControllerSimulator|applyDelete\\(|ForTesting|Mirror\\(' \
  SYKeyboardTests Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift
git diff --check HEAD~5..HEAD
git status --short
```

Expected: 제거 대상 검색 결과가 없고 `git diff --check`가 성공한다. 계획 문서
기록 외 예상하지 못한 변경이 없다.

- [ ] **Step 5: 검증 결과 판독과 계획 완료 기록**

Task 6 아래에 다음을 실제 값으로 기록한다.

- 사용한 Simulator 이름과 OS
- 전체 test passed/failed/skipped
- 각 scheme build 결과
- sandbox 실행 실패가 있었다면 실패 메시지
- 권한 있는 재실행 명령과 실제 결과
- 실행하지 못한 수동 화면 항목

모든 검증이 성공한 경우에만 Step 1~6과 계획 전체를 완료 처리한다.

- [ ] **Step 6: 최종 검증 문서 커밋**

```sh
git add docs/superpowers/plans/2026-07-30-test-maintenance-boundary.md
git commit -m "docs: 테스트 유지보수 경계 정리 검증 결과 반영"
```
