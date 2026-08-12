# 자동완성 후보 스크롤 롤백 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자동완성 후보의 가로 스크롤과 edge effect를 제거하고 스크롤 도입 전의 2줄·자동 축소 표시와 endpoint 기반 후보 선택으로 복원한다.

**Architecture:** `SuggestionButtonView`는 `UIScrollView` 대신 `UILabel`을 직접 배치하고 기존 축소·생략 설정을 사용한다. `SuggestionBarView`는 현재의 테스트 가능한 터치 메서드는 유지하되 스크롤 상태와 분기를 제거하고, 이동·종료 위치에 따라 하이라이트와 선택을 처리한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+, iOS 16+

## Global Constraints

- 수식 계산 자동완성과 숫자 표기 확장 production 코드·테스트는 변경하지 않는다.
- 후보 텍스트용 `UIScrollView`, `UIScrollEdgeEffect`, offset 상태와 가로 스크롤 터치 중재를 모두 제거한다.
- 후보 라벨은 `numberOfLines = 2`, `adjustsFontSizeToFitWidth = true`, `minimumScaleFactor = 0.7`, `lineBreakMode = .byTruncatingMiddle`로 복원한다.
- preview·touch 하이라이트, divider, 둥근 후보 배경, 햅틱·소리 피드백을 유지한다.
- iOS 16 최소 runtime과 기존 외부 의존성을 변경하지 않는다.
- 현재 브랜치 `feat/#98-math-calculation-auto-complete`에서 작업한다.

---

## File Structure

- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift`
  - 스크롤 없는 라벨 표시와 endpoint 기반 드래그 선택 계약을 영구 회귀 테스트로 추가한다.
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift`
  - `UILabel` 직접 배치와 스크롤 도입 전 표시 설정을 담당한다.
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
  - 스크롤 상태 없이 터치 위치 기반 하이라이트·선택을 담당한다.
- Delete: `SYKeyboardTests/Utils/SuggestionButtonViewScrollingTests.swift`
  - 제거되는 스크롤·edge effect 계약만 검증한다.
- Delete: `SYKeyboardTests/Utils/SuggestionBarViewTouchInteractionTests.swift`
  - 필요한 endpoint 계약은 기존 preview 테스트로 이동하고 스크롤 전용 계약은 제거한다.
- Delete: 스크롤·edge effect 도입만 설명하는 기존 계획 4개와 설계 1개
- Modify: `docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md`
  - RED/GREEN, 회귀 테스트와 빌드 결과를 단계별로 기록한다.

---

### Task 1: 스크롤 없는 표시와 endpoint 선택 계약

**Files:**
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift:15-178`
- Modify: `docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md`

**Interfaces:**
- Consumes: `SuggestionBarView.beginTouchInteraction(at:)`, `moveTouchInteraction(to:)`, `endTouchInteraction(at:playsFeedback:)`
- Produces: 스크롤 제거 후에도 유지할 표시·터치 회귀 계약 2개

- [x] **Step 1: 기존 preview suite에 스크롤 롤백 테스트를 추가**

suite에 `@MainActor`를 추가하고 다음 테스트를 작성한다.

```swift
@Test("후보 라벨은 스크롤 없이 두 줄 자동 축소와 가운데 생략 사용")
func test후보라벨은_스크롤없이_두줄자동축소와_가운데생략사용() {
    let bar = SuggestionBarView(keyboardHStackView: UIStackView())
    bar.updateSuggestions(
        currentWord: nil,
        suggestions: ["123456789012345678901234567890", "b", "c"]
    )

    let labels = suggestionLabels(in: bar)

    #expect(scrollViews(in: bar).isEmpty)
    #expect(labels.count == 3)
    #expect(labels.allSatisfy { $0.numberOfLines == 2 })
    #expect(labels.allSatisfy { $0.adjustsFontSizeToFitWidth })
    #expect(labels.allSatisfy { abs($0.minimumScaleFactor - 0.7) < 0.001 })
    #expect(labels.allSatisfy { $0.lineBreakMode == .byTruncatingMiddle })
}

@Test("긴 후보에서 시작한 드래그도 종료 위치 후보를 선택")
func test긴후보에서시작한드래그도_종료위치후보를선택() {
    let keyboardHStackView = UIStackView()
    let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
    let delegate = SuggestionBarRollbackDelegateSpy()
    bar.suggestionDelegate = delegate
    bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
    bar.updateSuggestions(
        currentWord: nil,
        suggestions: [
            "123456789012345678901234567890",
            "두번째",
            "세번째"
        ]
    )
    bar.layoutIfNeeded()

    let buttons = typedSuggestionButtonViews(in: bar)
    let startPoint = center(of: buttons[0], in: bar)
    let endPoint = center(of: buttons[2], in: bar)

    bar.beginTouchInteraction(at: startPoint)
    bar.moveTouchInteraction(to: endPoint)

    #expect(buttons[2].isHighlighted)

    bar.endTouchInteraction(at: endPoint, playsFeedback: false)

    #expect(delegate.selectedIndexes == [2])
    #expect(keyboardHStackView.isUserInteractionEnabled)
}
```

같은 파일에 재귀 탐색·좌표 helper와 delegate spy를 추가한다.

```swift
private func scrollViews(in view: UIView) -> [UIScrollView] {
    var result: [UIScrollView] = []
    for subview in view.subviews {
        if let scrollView = subview as? UIScrollView {
            result.append(scrollView)
        }
        result.append(contentsOf: scrollViews(in: subview))
    }
    return result
}

private func typedSuggestionButtonViews(
    in view: UIView
) -> [SuggestionButtonView] {
    var result: [SuggestionButtonView] = []
    for subview in view.subviews {
        if let button = subview as? SuggestionButtonView {
            result.append(button)
        }
        result.append(contentsOf: typedSuggestionButtonViews(in: subview))
    }
    return result.sorted {
        $0.convert($0.bounds, to: view).minX
            < $1.convert($1.bounds, to: view).minX
    }
}

private func center(of button: UIView, in bar: UIView) -> CGPoint {
    let frame = button.convert(button.bounds, to: bar)
    return CGPoint(x: frame.midX, y: frame.midY)
}

@MainActor
private final class SuggestionBarRollbackDelegateSpy: SuggestionBarDelegate {
    private(set) var selectedIndexes: [Int] = []

    func suggestionBar(
        _ bar: SuggestionBarView,
        didSelectSuggestionAt index: Int
    ) {
        selectedIndexes.append(index)
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}
}
```

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests
```

Expected: 신규 표시 테스트는 후보 내부 `UIScrollView`와 한 줄 고정 글꼴 때문에
실패한다. 신규 드래그 테스트는 첫 긴 후보가 스크롤 모드로 전환되어 세 번째
후보를 하이라이트·선택하지 않으므로 실패한다. 기존 7개 테스트는 통과한다.

실행 결과(2026-07-28, iPhone 13 mini / iOS 16.0): 총 9개 중 passed 7,
failed 2, skipped 0으로 RED를 확인했다. `후보 라벨은 스크롤 없이 두 줄 자동
축소와 가운데 생략 사용`은 후보 내부 `UIScrollView` 3개가 남아 있어
`scrollViews(in: bar).isEmpty`가 실패했다. `긴 후보에서 시작한 드래그도 종료
위치 후보를 선택`은 긴 첫 후보의 스크롤 중재 때문에 세 번째 후보의
`isHighlighted`가 `false`여서 실패했다. 기존 7개는 통과했으며, 두 실패 모두
예상한 production gap과 일치한다.

- [x] **Step 3: RED 결과를 기록하고 테스트 커밋**

```sh
git add \
  SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
  docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md
git commit -m "test: #98 - 자동완성 후보 스크롤 롤백 계약 추가"
```

---

### Task 2: 후보 표시와 터치 흐름 롤백

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift:12-239`
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift:35-261`
- Delete: `SYKeyboardTests/Utils/SuggestionButtonViewScrollingTests.swift`
- Delete: `SYKeyboardTests/Utils/SuggestionBarViewTouchInteractionTests.swift`
- Modify: `docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md`

**Interfaces:**
- Consumes: Task 1의 표시·endpoint 터치 계약
- Produces: 스크롤 상태가 없는 `SuggestionButtonView`와 위치 기반 `SuggestionBarView` 터치 흐름

- [x] **Step 1: `SuggestionButtonView`를 UILabel 직접 배치로 복원**

스크롤 관련 static/property와 `layoutSubviews()`, `setScrollOffsetX(_:)`,
`updateHorizontalEdgeEffects()`를 제거한다. 라벨 설정은 다음과 같이 복원한다.

```swift
private let suggestionLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: FontSize.stringKeyMedium)
    label.textColor = .label
    label.textAlignment = .center
    label.numberOfLines = 2
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.7
    label.lineBreakMode = .byTruncatingMiddle
    label.isUserInteractionEnabled = false

    return label
}()
```

`update(to:)`는 텍스트와 appearance만 갱신한다.

```swift
func update(to title: String) {
    suggestionLabel.text = title
    updateAppearance()
}
```

hierarchy와 라벨 제약은 스크롤 도입 전 구조로 복원한다.

```swift
func setHierarchy() {
    self.insertSubview(backgroundView, at: 0)
    self.addSubview(suggestionLabel)
}

NSLayoutConstraint.activate([
    suggestionLabel.topAnchor.constraint(equalTo: self.topAnchor),
    suggestionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
    suggestionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
    suggestionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
])
```

- [x] **Step 2: `SuggestionBarView`의 스크롤 상태와 분기를 제거**

`scrollActivationDistance`, `scrollTouchButton`, `touchStartPoint`,
`scrollStartOffsetX`, `didScrollActiveTouch`를 제거한다. 테스트 가능한 터치
메서드는 다음 endpoint 기반 구현으로 단순화한다.

```swift
func beginTouchInteraction(at point: CGPoint) {
    updateHighlight(at: point)
    keyboardHStackView?.isUserInteractionEnabled = false
}

func moveTouchInteraction(to point: CGPoint) {
    updateHighlight(at: point)
}

func endTouchInteraction(at point: CGPoint, playsFeedback: Bool) {
    if let (index, _) = suggestionButton(at: point) {
        suggestionDelegate?.suggestionBar(
            self,
            didSelectSuggestionAt: index
        )
        playSelectionFeedbackIfNeeded(playsFeedback)
    } else if let action = undoRedoButton(at: point) {
        switch action {
        case undoButton:
            suggestionDelegate?.suggestionBarDidTapUndo(self)
        case redoButton:
            suggestionDelegate?.suggestionBarDidTapRedo(self)
        default:
            break
        }
        playSelectionFeedbackIfNeeded(playsFeedback)
    }

    resetTouchInteraction()
}

func resetTouchInteraction() {
    clearTouchHighlights()
    keyboardHStackView?.isUserInteractionEnabled = true
}
```

- [x] **Step 3: 제거된 스크롤 계약 테스트 파일 삭제**

다음 두 파일을 삭제한다.

```text
SYKeyboardTests/Utils/SuggestionButtonViewScrollingTests.swift
SYKeyboardTests/Utils/SuggestionBarViewTouchInteractionTests.swift
```

- [x] **Step 4: 집중 테스트를 실행해 GREEN 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/ButtonStateControllerTests
```

Expected: preview suite 9개와 button state suite 4개, 총 13개가 실패 없이
통과한다. 신규 테스트는 후보 내부 스크롤 부재, 2줄·자동 축소·가운데 생략,
긴 후보에서 시작한 드래그의 endpoint 하이라이트·선택을 확인한다.

- [x] **Step 5: production 검색으로 스크롤 잔여물 확인**

Run:

```sh
rg -n \
  "UIScrollView|UIScrollEdgeEffect|scrollOffsetX|maximumScrollOffsetX|isTextOverflowing|scrollActivationDistance|scrollTouchButton|didScrollActiveTouch" \
  Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift \
  Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift
```

Expected: 결과 없음.

- [x] **Step 6: GREEN 결과를 기록하고 구현 커밋**

```sh
git add \
  Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift \
  Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
  SYKeyboardTests/Utils/SuggestionButtonViewScrollingTests.swift \
  SYKeyboardTests/Utils/SuggestionBarViewTouchInteractionTests.swift \
  docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md
git commit -m "remove: #98 - 자동완성 후보 가로 스크롤 제거"
```

실행 결과(2026-07-28, iPhone 13 mini / iOS 16.0): 권한 있는 Xcode 환경에서
지정한 집중 테스트를 실행해 preview suite 9개와 button state suite 4개, 총 13개가
실패 없이 통과했다. 기본 Codex 샌드박스에서는 CoreSimulator 및 Xcode 캐시 접근이
제한되어 같은 명령이 실패했으나, 이는 코드 실패가 아닌 환경 권한 문제였다.
`rg`로 두 production 파일에서 `UIScrollView`, `UIScrollEdgeEffect`, scroll offset,
overflow 및 터치 스크롤 상태 심볼의 잔여 결과가 없음을 확인했다.

---

### Task 3: 스크롤 문서 정리와 전체 회귀 검증

**Files:**
- Delete: `docs/superpowers/plans/2026-07-27-suggestion-overflow-scrolling.md`
- Delete: `docs/superpowers/plans/2026-07-28-suggestion-horizontal-edge-effect.md`
- Delete: `docs/superpowers/plans/2026-07-28-suggestion-scroll-edge-effect.md`
- Delete: `docs/superpowers/plans/2026-07-28-suggestion-soft-edge-effect.md`
- Delete: `docs/superpowers/specs/2026-07-28-suggestion-scroll-edge-effect-design.md`
- Modify: `docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md`

**Interfaces:**
- Consumes: Task 2의 스크롤 없는 후보 UI와 터치 흐름
- Produces: 현재 동작과 일치하는 문서 집합 및 전체 회귀 증거

- [x] **Step 1: 폐기된 스크롤·edge effect 문서 삭제**

File Structure에 열거한 계획 4개와 설계 1개를 삭제한다. 롤백 설계와 이 구현
계획은 삭제하지 않는다.

- [x] **Step 2: 전체 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 스크롤 전용 suite 2개가 제거된 상태로 전체 테스트가 실패 없이 끝난다.
실제 passed, failed, skipped 수를 이 Step 아래에 기록한다.

실행 결과(2026-07-28, iPhone 13 mini / iOS 16.0): `xcodebuild test`가
`** TEST SUCCEEDED **`로 종료했다. `xcresulttool` summary에서 총 352개 중 passed
352, failed 0, skipped 0, expected failures 0을 확인했다.

- [x] **Step 3: 한글·영문 키보드 확장 빌드**

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

Expected: 두 빌드 모두 성공한다. 외부 의존성 warning과 오류 수를 기록한다.

실행 결과(2026-07-28, iPhone 13 mini / iOS 16.0): 권한 있는 Xcode 환경에서
`HangeulKeyboard`, `EnglishKeyboard` 모두 `** BUILD SUCCEEDED **`로 종료했다.
각 조용한 빌드 로그의 외부 의존성 warning은 0건, 오류는 0건이었다. 각 빌드에는
동일한 대상이 둘 발견됐다는 `xcodebuild` 대상 선택 안내 warning 1건이 있었으나,
외부 의존성 warning은 아니다. 기본 Codex 샌드박스에서의 두 빌드는
CoreSimulator·SwiftPM/clang cache 접근 제한으로 exit 74가 발생했으며, 권한 있는
재실행에서 코드 오류가 아님을 분리했다.

- [x] **Step 4: 수식 자동완성 보존과 diff 범위 확인**

Run:

```sh
git diff --name-status f7b898e..HEAD
git diff --check
rg -n "UIScrollEdgeEffect|scrollActivationDistance|didScrollActiveTouch" \
  Modules/SYKeyboardCore SYKeyboardTests
```

Expected: 변경은 계획에 명시한 production·test·문서에 한정된다. 스크롤 심볼
검색 결과가 없고, 수식 자동완성 production·test 파일은 diff 목록에 없다.

실행 결과(2026-07-28): `git diff --name-status f7b898e..HEAD`는 후보 표시·터치
production/test 파일, 스크롤 롤백 계획과 설계만 보였고 수식 계산 자동완성 및 숫자
표기 확장 production·test 파일은 포함하지 않았다. `git diff --check`와
`UIScrollEdgeEffect|scrollActivationDistance|didScrollActiveTouch` 검색은 모두
결과가 없었다.

- [x] **Step 5: 검증 결과를 기록하고 문서 커밋**

```sh
git add \
  docs/superpowers/plans/2026-07-27-suggestion-overflow-scrolling.md \
  docs/superpowers/plans/2026-07-28-suggestion-horizontal-edge-effect.md \
  docs/superpowers/plans/2026-07-28-suggestion-scroll-edge-effect.md \
  docs/superpowers/plans/2026-07-28-suggestion-soft-edge-effect.md \
  docs/superpowers/specs/2026-07-28-suggestion-scroll-edge-effect-design.md \
  docs/superpowers/plans/2026-07-28-suggestion-scroll-rollback.md
git commit -m "docs: #98 - 자동완성 후보 스크롤 문서 정리"
```

---

## Completion Criteria

- 후보 내부에 `UIScrollView`와 `UIScrollEdgeEffect`가 없다.
- 후보 라벨이 2줄·자동 축소·가운데 생략 설정을 사용한다.
- 긴 후보에서 시작한 드래그도 종료 위치 후보를 하이라이트하고 선택한다.
- 스크롤 전용 테스트·설계·계획 문서가 제거된다.
- 수식 계산 자동완성과 숫자 표기 확장 파일은 변경되지 않는다.
- 집중 테스트, 전체 테스트와 두 키보드 확장 빌드가 통과한다.
