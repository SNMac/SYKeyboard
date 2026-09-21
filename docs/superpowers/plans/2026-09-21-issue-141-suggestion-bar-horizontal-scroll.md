# 자동완성 후보 바 가로 스크롤 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자동완성 후보 영역을 `UIScrollView`로 바꿔 후보를 최대 10개까지 가로로 넘겨 보게 하고, 선택은 탭으로만 하게 한다.

**Architecture:** `SuggestionBarView`의 고정 3버튼 + 2divider를 스크롤 뷰 하나로 대체하고, 그 안에 후보 버튼을 필요한 개수만큼 꺼내 쓰는 풀을 둔다. 스크롤·탭·길게 누르기의 분리는 `UIScrollView` 기본 동작(`delaysContentTouches = false`, `canCancelContentTouches`)이 담당하고 저장소 코드는 터치 중재 상태를 하나도 추가하지 않는다. 후보 상한은 UI가 다 갖춰진 뒤 마지막에 3에서 10으로 올려, 되돌릴 때도 상수 하나만 되돌리면 되게 한다.

**Tech Stack:** Swift 5, UIKit(`UIScrollView`, `CAGradientLayer`), Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`), Xcode 26 이상

**Spec:** `docs/superpowers/specs/2026-09-21-suggestion-bar-horizontal-scroll-design.md`

## Global Constraints

- 작업 브랜치는 `feat/#141-suggestion-bar-scroll`이고 `develop`(`6c9ae589`) 위로 rebase된 상태다. 커밋 메시지는 `type: #141 - subject` 형식을 쓰고 마침표를 붙이지 않는다.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`를 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.
- **`Modules/` 아래에 새 파일을 만들지 않는다.** 만들면 `SYKeyboard.xcodeproj/project.pbxproj`의 타깃별 `membershipExceptions`를 함께 고쳐야 한다. 이 계획의 모든 production 변경은 기존 파일 수정이다. `SuggestionScrollFadePolicy`도 기존 `SuggestionHighlightPolicy.swift` 안에 둔다.
- `SYKeyboardTests/` 아래 **테스트 파일도 새로 만들지 않는다.** 모든 새 테스트는 기존 suite 파일에 붙인다.
- 테스트 기준 기기는 `iPhone 13 mini / iOS 18.6`이다. 테스트 명령에는 반드시 아래 두 옵션을 붙인다. 빼면 테스트 호스트가 AdMob 초기화에서 크래시한다.

  ```sh
  xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    -parallel-testing-enabled NO \
    GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'
  ```

- `SYKeyboard/Resources/Configs/Secrets.xcconfig`는 **절대 만들거나 고치지 않는다.**
- extension scheme을 빌드할 때는 `-only-testing`과 code coverage 옵션을 비운다. 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌리고 커밋하지 않는다.
- `SYKeyboard/Presentation/Content/ContentView.swift`에 사용자의 미커밋 변경이 있다. **건드리지 않고 커밋에도 포함하지 않는다.** `git add`는 항상 파일을 명시한다.
- 확정된 제품 결정(spec 「확정된 결정」)은 구현 중 바꾸지 않는다. 후보 최대 10개, `"현재단어"` 버튼도 함께 스크롤, 끌어서 고르는 동작 제거, 후보 버튼 등폭 유지, 가장자리 페이드로 알림.
- `SuggestionButtonView`의 표시 계약(2줄, `minimumScaleFactor` 0.7, `byTruncatingMiddle`, 좌우 4pt)은 건드리지 않는다.
- Firebase, AdMob, entitlements, bundle identifier, provisioning 관련 파일은 건드리지 않는다.

### spec과 다르게 가는 한 곳

spec 2절은 버튼 폭을 "스크롤 뷰 뷰포트의 1/3"이라고 썼다. 그대로 하면 후보 3개일 때
`contentSize.width = viewport + 2pt`가 되어 수식 3칸에서도 스크롤과 페이드가 생긴다.
spec 6절·7절과 완료 기준이 요구하는 "3개면 스크롤 없음"을 지키려면 divider 2개를 뺀
값이어야 한다. 이 계획은 전부 아래 식을 쓴다.

```
buttonWidth = (viewportWidth - dividerWidth * 2) / 3
```

이 식이 스크롤 도입 전 등폭 제약이 만들던 폭과 정확히 같다.

## 파일 구조

| 파일 | 책임 | 변경 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift` | 스크롤 컨테이너, 후보 버튼 풀, 터치 전달, divider, 가장자리 페이드 | 수정 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift` | 표시 텍스트 접근자 추가, 쓰이지 않는 divider 참조 제거 | 수정 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift` | 가장자리 페이드 판정 정책 추가 | 수정 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift` | 드래그 선택 제거에 맞춰 주석 갱신 | 수정 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` | `maxPredictions` 3 → 10 | 수정 |
| `Modules/SYKeyboardCore/Domain/SuggestionController.swift` | `maxSuggestions` 3 → 10 | 수정 |
| `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift` | 스크롤 취소 경로, 가변 후보 개수 표시 검증 | 수정 |
| `SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift` | 확장된 후보 개수, 페이드 판정 검증 | 수정 |
| `SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift` | 상위 N개 순위 검증 | 수정 |
| `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift` | 9슬롯 limit·중복 제거 검증 | 수정 |
| `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` | 10칸에서 `barIndex - 1` 매핑 검증 | 수정 |
| `CLAUDE.md` | 후보 스크롤 금지 조항 갱신 | 수정 |
| `docs/architecture/자동완성 로직.md` | 후보 개수·버튼 배치 설명 갱신 | 수정 |
| `docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md` | 진행 상태와 검증 결과 기록 | 수정 |

## 작업 순서를 이렇게 잡은 이유

상한(`maxSuggestions`)을 마지막에 올린다. Task 1~3이 끝날 때까지 화면에 보이는 후보는
계속 3개라 각 Task의 중간 상태가 오늘과 똑같이 동작한다. 스크롤·풀·페이드가 모두
자리를 잡은 뒤 상수 하나를 올려 기능을 켜므로, 문제가 생기면 그 커밋 하나만 되돌리면
된다(spec 7절).

---

### Task 1: 후보 영역을 스크롤 컨테이너로 바꾸고 터치를 바로 전달

지금은 후보 버튼 3개와 그 사이 divider 2개가 `buttonContainerHStackView`의 arranged
subview다. 이 5개를 `UIScrollView` 하나로 바꾸고, 스크롤 뷰 안 content view가 받은
터치를 `SuggestionBarView`의 기존 터치 메서드로 그대로 넘긴다. 이 Task가 끝나도
후보는 3개 고정이고 사용자가 보는 화면은 같아야 한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- Test: `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`

**Interfaces:**
- Consumes: `SuggestionButtonView`, `KeyboardLayoutFigure.suggestionButtonDividerHeight`, `SuggestionHighlightPolicy.resolve(...)` (모두 기존)
- Produces:
  - `SuggestionBarView.isSuggestionAreaScrollable: Bool` — 후보 영역이 가로로 넘칠 수 있는 상태인지. Task 3·4가 이 프로퍼티로 검증한다.
  - `SuggestionBarView.pooledButtons: [SuggestionButtonView]`, `pooledDividers: [UIView]`, `visibleSuggestionCount: Int` (private). Task 2가 가변 개수로 확장한다.
  - `SuggestionBarView.layoutSuggestionContent()` (private) — 스크롤 content 프레임과 `contentSize` 계산 지점.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`의 `struct` 안,
마지막 `@Test` 아래에 붙인다.

```swift
    @Test("후보 3개는 후보 영역이 스크롤되지 않음")
    func test후보3개는_후보영역이스크롤되지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }

    @Test("후보 버튼은 등폭을 유지")
    func test후보버튼은_등폭을유지() {
        let fixture = makeFixture(acceptsRemoval: false)
        let widths = fixture.buttons.map { $0.bounds.width }

        #expect(widths.count == 3)
        for width in widths {
            #expect(width > 0)
            #expect(abs(width - widths[0]) < 0.5)
        }
    }

    @Test("스크롤이 터치를 가져가면 하이라이트와 삭제 타이머가 함께 취소")
    func test스크롤이터치를가져가면_하이라이트와삭제타이머가_함께취소() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        #expect(fixture.buttons[1].isHighlighted)

        fixture.bar.cancelTouchInteraction()
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.buttons[1].isHighlighted == false)
        #expect(fixture.delegate.removalRequestIndexes == [])
        #expect(fixture.delegate.selectedIndexes == [])
        #expect(fixture.keyboardHStackView.isUserInteractionEnabled)
    }
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionBarViewRemovalLongPressTests
```

Expected: 컴파일 실패. `value of type 'SuggestionBarView' has no member 'isSuggestionAreaScrollable'`

- [ ] **Step 3: 스크롤 뷰와 content view를 추가한다**

`SuggestionBarView.swift`의 `// MARK: - Properties` 블록에서 `suggestionButtons`
**computed property를 지우고** 아래 저장 프로퍼티로 바꾼다.

```swift
    /// 후보 버튼 재사용 풀. 한 번 만든 버튼은 버리지 않고 `isHidden`으로만 감춘다
    private var pooledButtons: [SuggestionButtonView] = []
    /// 후보 사이 divider 재사용 풀. 버튼 N개에 divider N-1개를 쓴다
    private var pooledDividers: [UIView] = []
    /// 현재 표시 중인 후보 버튼 개수
    private var visibleSuggestionCount = 0
    /// 후보 영역 표시 여부. 숨겨져 있으면 후보 사이 divider를 모두 감춘다
    private var isSuggestionAreaVisible = true

    /// 하이라이트·히트테스트 대상 후보 버튼. 풀에서 지금 쓰는 앞쪽 N개만 본다
    private var suggestionButtons: [SuggestionButtonView] {
        return Array(pooledButtons.prefix(visibleSuggestionCount))
    }

    /// 후보 영역이 가로로 넘쳐 스크롤될 수 있는 상태인지.
    ///
    /// 스크롤과 가장자리 페이드의 유일한 발생 조건이다. 후보 개수로 분기하지 않는다.
    /// 0.5pt는 부동소수 오차로 1pt도 안 되는 차이에 스크롤이 생기는 것을 막는 허용 오차다
    var isSuggestionAreaScrollable: Bool {
        return suggestionScrollView.contentSize.width
            > suggestionScrollView.bounds.width + 0.5
    }
```

`suggestionAreaDividers` computed property는 지운다. 풀이 대신한다.

`// MARK: - UI Components`에서 `suggestionButton1`, `leftDivider`,
`suggestionButton2`, `rightDivider`, `suggestionButton3` **다섯 개 선언을 지우고**
같은 자리에 아래를 넣는다.

```swift
    private lazy var suggestionScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never
        // 키보드라 기본 150ms 지연을 쓸 수 없다. 손을 대는 즉시 하이라이트가 켜져야 한다
        scrollView.delaysContentTouches = false
        // 스택이 기능 버튼을 배치하고 남긴 공간을 이 뷰가 전부 가져간다
        scrollView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        scrollView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        scrollView.delegate = self

        return scrollView
    }()

    private lazy var suggestionContentView: SuggestionScrollContentView = {
        let view = SuggestionScrollContentView()
        view.forwardingTarget = self

        return view
    }()
```

- [ ] **Step 4: 계층과 제약을 바꾼다**

`private extension SuggestionBarView`의 `setHierarchy()`를 아래로 바꾼다.

```swift
    func setHierarchy() {
        self.addSubview(buttonContainerHStackView)

        [clipboardButton,
         clipboardDivider,
         suggestionScrollView,
         undoRedoLeadingDivider,
         undoButton,
         undoRedoMiddleDivider,
         redoButton].forEach {
            buttonContainerHStackView.addArrangedSubview($0)
        }

        suggestionScrollView.addSubview(suggestionContentView)
    }
```

`setConstraints()`에서 `clipboardDivider, leftDivider, rightDivider, ...` 배열의
`leftDivider, rightDivider`를 빼고, `suggestionButton1~3` 제약 블록 전체를 아래로
바꾼다. content view와 후보 버튼·divider는 제약 대신 `layoutSubviews()`에서 프레임으로
배치한다. 후보 개수가 매번 달라지므로 제약을 다시 만드는 것보다 프레임 계산이 짧고
결과가 분명하다.

```swift
        [clipboardDivider, undoRedoLeadingDivider, undoRedoMiddleDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: SuggestionBarView.dividerWidth).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }

        suggestionScrollView.translatesAutoresizingMaskIntoConstraints = false
        suggestionScrollView.heightAnchor.constraint(
            equalTo: buttonContainerHStackView.heightAnchor
        ).isActive = true
```

`// MARK: - Properties` 위쪽, `clipboardClosedSymbolName` 선언 옆에 상수를 둔다.

```swift
    /// 화면에 한 번에 보이는 후보 칸 수. 버튼 폭 계산 기준이다
    private static let visibleSuggestionColumnCount: CGFloat = 3
    /// divider 두께
    private static let dividerWidth: CGFloat = 1
```

- [ ] **Step 5: 프레임 레이아웃과 풀 생성을 구현한다**

`// MARK: - Lifecycle`의 `touchesBegan` 위에 넣는다.

```swift
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSuggestionContent()
    }
```

`private extension SuggestionBarView`(Private Methods 쪽)에 넣는다.

```swift
    /// 풀에 버튼 `count`개와 divider `count - 1`개가 있도록 채웁니다.
    func ensurePooledViews(count: Int) {
        while pooledButtons.count < count {
            let button = SuggestionButtonView()
            suggestionContentView.addSubview(button)
            pooledButtons.append(button)
        }

        let dividerCount = max(count - 1, 0)
        while pooledDividers.count < dividerCount {
            let divider = UIView()
            divider.backgroundColor = .suggestionDividerColor
            suggestionContentView.addSubview(divider)
            pooledDividers.append(divider)
        }
    }

    /// 스크롤 content의 프레임과 `contentSize`를 갱신합니다.
    ///
    /// 버튼 폭은 뷰포트에 후보 3칸과 그 사이 divider 2개가 정확히 들어가는 값이다.
    /// 클립보드·undo/redo 버튼이 숨겨질 수 있어 뷰포트 폭이 변하므로 매 레이아웃마다 다시 계산한다
    func layoutSuggestionContent() {
        let viewportWidth = suggestionScrollView.bounds.width
        let viewportHeight = suggestionScrollView.bounds.height
        guard viewportWidth > 0, viewportHeight > 0 else { return }

        let dividerWidth = SuggestionBarView.dividerWidth
        let columnCount = SuggestionBarView.visibleSuggestionColumnCount
        let buttonWidth = (viewportWidth - dividerWidth * (columnCount - 1)) / columnCount
        let dividerHeight = KeyboardLayoutFigure.suggestionButtonDividerHeight

        var offsetX: CGFloat = 0
        for index in 0..<visibleSuggestionCount {
            pooledButtons[index].frame = CGRect(
                x: offsetX,
                y: 0,
                width: buttonWidth,
                height: viewportHeight
            )
            offsetX += buttonWidth

            guard index < visibleSuggestionCount - 1 else { continue }
            pooledDividers[index].frame = CGRect(
                x: offsetX,
                y: (viewportHeight - dividerHeight) / 2,
                width: dividerWidth,
                height: dividerHeight
            )
            offsetX += dividerWidth
        }

        let contentWidth = max(offsetX, viewportWidth)
        suggestionContentView.frame = CGRect(
            x: 0,
            y: 0,
            width: contentWidth,
            height: viewportHeight
        )
        suggestionScrollView.contentSize = suggestionContentView.bounds.size
    }
```

- [ ] **Step 6: `updateSuggestions`를 풀 기반으로 바꾼다**

`updateSuggestions(currentWord:suggestions:)` 본문을 아래로 바꾼다. 이 Task에서는
표시 개수를 3으로 고정해 오늘과 같은 화면을 유지한다. 가변 개수는 Task 2에서 푼다.

```swift
    func updateSuggestions(currentWord: String?, suggestions: [String]) {
        var titles: [String] = []
        if let word = currentWord, !word.isEmpty {
            // 입력 중: 0번 칸이 "현재단어", 그 뒤가 자동완성 후보
            titles.append("\"\(word)\"")
        }
        titles.append(contentsOf: suggestions)

        // Task 2에서 titles.count로 바뀐다. 지금은 오늘과 같은 3칸 고정이다
        let count = Int(SuggestionBarView.visibleSuggestionColumnCount)
        ensurePooledViews(count: count)
        for index in 0..<count {
            pooledButtons[index].update(to: index < titles.count ? titles[index] : "")
            pooledButtons[index].isHidden = false
        }
        visibleSuggestionCount = count

        applyDividerVisibility()
        suggestionScrollView.contentOffset = .zero
        setNeedsLayout()
        applyHighlights()
    }
```

`updateSuggestionArea(isVisible:)`를 아래로 바꾼다.

```swift
    func updateSuggestionArea(isVisible: Bool) {
        isSuggestionAreaVisible = isVisible
        applyDividerVisibility()
    }
```

Private Methods 확장에 넣는다.

```swift
    func applyDividerVisibility() {
        let visibleDividerCount = max(visibleSuggestionCount - 1, 0)
        for (index, divider) in pooledDividers.enumerated() {
            divider.isHidden = !isSuggestionAreaVisible || index >= visibleDividerCount
        }
    }
```

- [ ] **Step 7: `updateDividers()`를 가변 개수로 일반화한다**

Private Methods 확장의 `updateDividers()`를 아래로 바꾼다.

```swift
    func updateDividers() {
        let buttons = suggestionButtons
        let firstHighlighted = isVisibleAndHighlighted(buttons.first)
        let lastHighlighted = isVisibleAndHighlighted(buttons.last)

        clipboardDivider.backgroundColor = (clipboardButton.isHighlighted || firstHighlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoLeadingDivider.backgroundColor = (lastHighlighted || undoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoMiddleDivider.backgroundColor = (undoButton.isHighlighted || redoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor

        for index in pooledDividers.indices {
            let leadingHighlighted = buttons.indices.contains(index) && buttons[index].isHighlighted
            let trailingHighlighted = buttons.indices.contains(index + 1) && buttons[index + 1].isHighlighted
            pooledDividers[index].backgroundColor = (leadingHighlighted || trailingHighlighted)
            ? .clear
            : .suggestionDividerColor
        }
    }

    /// 경계 divider를 지울지 판단합니다.
    ///
    /// 스크롤로 뷰포트 밖에 완전히 나간 버튼 때문에 보이지도 않는 divider가 사라지는 것을 막는다
    func isVisibleAndHighlighted(_ button: SuggestionButtonView?) -> Bool {
        guard let button, button.isHighlighted else { return false }
        return button.frame.intersects(suggestionScrollView.bounds)
    }
```

- [ ] **Step 8: content view의 터치 전달과 스크롤 델리게이트를 추가한다**

파일 끝 `// MARK: - Supporting Views` 안, `SuggestionActionButtonView` 선언 위에
넣는다. 새 파일을 만들지 않으므로 `project.pbxproj`를 고칠 필요가 없다.

```swift
/// 스크롤 뷰 안에서 받은 터치를 `SuggestionBarView`의 터치 처리로 그대로 넘기는 content view
///
/// `UITouch.location(in:)`이 대상 뷰를 인자로 받으므로 어느 뷰가 터치를 받았든 바 좌표가 정확히 나온다.
/// 덕분에 `beginTouchInteraction(at:)` 계열의 본문은 스크롤 도입 전과 같다.
/// 손가락을 끌어 스크롤이 시작되면 `UIScrollView`가 여기로 `touchesCancelled`를 보낸다
private final class SuggestionScrollContentView: UIView {

    weak var forwardingTarget: SuggestionBarView?

    private weak var activeTouch: UITouch?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil,
              let touch = touches.first,
              let target = forwardingTarget else { return }
        activeTouch = touch
        target.beginTouchInteraction(at: touch.location(in: target))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch,
              touches.contains(touch),
              let target = forwardingTarget else { return }
        target.moveTouchInteraction(to: touch.location(in: target))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch,
              touches.contains(touch),
              let target = forwardingTarget else { return }
        target.endTouchInteraction(at: touch.location(in: target), playsFeedback: true)
        activeTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch,
              touches.contains(touch),
              let target = forwardingTarget else { return }
        target.cancelTouchInteraction()
        activeTouch = nil
    }
}
```

`// MARK: - Supporting Views` 바로 위에 델리게이트 확장을 넣는다. 스크롤될 때
경계 버튼의 노출 여부가 바뀌므로 divider도 함께 갱신한다.

```swift
// MARK: - UIScrollViewDelegate

extension SuggestionBarView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDividers()
    }
}
```

`updateDividers()`는 `private extension`에 있으므로, 이 확장에서 부르려면
`updateDividers()` 선언을 `private extension SuggestionBarView`에서 타입 본문의
`// MARK: - Internal Methods` 아래로 옮기거나, `scrollViewDidScroll`을 타입 본문에
둔다. **`updateDividers()`와 `isVisibleAndHighlighted(_:)`를 타입 본문의
Internal Methods 구역 끝으로 옮기는 쪽을 택한다.** 접근 수준은 기본(internal)으로 둔다.

- [ ] **Step 9: 문서 주석을 고친다**

같은 파일에서 아래 세 곳을 고친다.

- `SuggestionBarDelegate`의 `didSelectSuggestionAt`·`shouldBeginRemovalAt` 주석의
  `- index: 선택된 후보의 인덱스 (0~2)` → `- index: 선택된 후보의 인덱스`
- 타입 주석 `최대 3개의 후보 버튼과 1개의 맞춤법 검사 버튼으로 구성되며,` →
  `후보 버튼은 가로 스크롤 영역에 들어가고, 클립보드·undo/redo 버튼은 양옆에 고정되며,`
- `updateSuggestions(currentWord:suggestions:)`의 주석에서 `button1`, `button2~3`
  표기를 `0번 칸`, `그 뒤 칸`으로 바꾼다.

- [ ] **Step 10: 테스트가 통과하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionBarViewRemovalLongPressTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests
```

Expected: PASS. 기존 4개 테스트도 그대로 통과해야 한다. 기존 테스트가 깨지면
스크롤 도입이 기존 동작을 바꾼 것이므로 구현을 고친다.

- [ ] **Step 11: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
        SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
feat: #141 - 자동완성 후보 영역을 가로 스크롤 컨테이너로 교체

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: 후보 버튼을 가변 개수로 표시

후보 수에 맞춰 버튼과 divider를 꺼내 쓴다. 후보가 줄면 남는 버튼은 텍스트를 비우고
감춘다. 이 Task가 끝나면 `updateSuggestions`에 10개를 넘기면 10칸이 만들어지고
`isSuggestionAreaScrollable`이 `true`가 된다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift`
- Test: `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`
- Test: `SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift`

**Interfaces:**
- Consumes: Task 1의 `pooledButtons`, `pooledDividers`, `visibleSuggestionCount`, `ensurePooledViews(count:)`, `applyDividerVisibility()`, `isSuggestionAreaScrollable`
- Produces:
  - `SuggestionButtonView.text: String?` — 현재 표시 중인 문자열. 테스트가 표시 결과를 공개 동작으로 읽는 경로다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`SuggestionBarViewRemovalLongPressTests.swift`의 `struct` 안에 붙인다.

```swift
    @Test("후보 수가 10 → 3 → 10으로 바뀌어도 이전 후보가 남지 않음")
    func test후보수가10과3을오가도_이전후보가남지않음() {
        let fixture = makeFixture(acceptsRemoval: false)
        let tenWords = (1...10).map { "단어\($0)" }
        let threeWords = ["가", "나", "다"]

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: tenWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == tenWords)
        #expect(fixture.bar.isSuggestionAreaScrollable)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: threeWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == threeWords)
        #expect(fixture.bar.isSuggestionAreaScrollable == false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: tenWords)
        fixture.bar.layoutIfNeeded()
        #expect(visibleSuggestionTexts(in: fixture.bar) == tenWords)
    }

    @Test("입력 중에는 0번 칸이 현재 단어이고 나머지가 후보")
    func test입력중에는_0번칸이현재단어이고_나머지가후보() {
        let fixture = makeFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: "hel", suggestions: ["hello", "help"])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == ["\"hel\"", "hello", "help"])
    }

    @Test("후보가 없으면 후보 칸이 하나도 남지 않음")
    func test후보가없으면_후보칸이하나도남지않음() {
        let fixture = makeFixture(acceptsRemoval: false)

        fixture.bar.updateSuggestions(currentWord: nil, suggestions: [])
        fixture.bar.layoutIfNeeded()

        #expect(visibleSuggestionTexts(in: fixture.bar) == [])
        #expect(fixture.bar.isSuggestionAreaScrollable == false)
    }
```

같은 파일 아래쪽, `typedSuggestionButtonViews(in:)` 정의 뒤에 헬퍼를 더한다.

```swift
private func visibleSuggestionTexts(in bar: UIView) -> [String] {
    return typedSuggestionButtonViews(in: bar)
        .filter { !$0.isHidden && $0.hasText }
        .compactMap { $0.text }
}
```

`makeFixture`의 `buttons`는 `updateSuggestions` 호출 시점의 버튼을 담으므로,
위 테스트들은 `fixture.buttons`를 쓰지 않고 매번 `visibleSuggestionTexts`로 읽는다.

`SuggestionHighlightPolicyTests.swift`의 `struct` 안에는 확장된 개수 케이스를 더한다.

```swift
    @Test("후보가 10개면 9번 후보도 하이라이트 대상")
    func test후보가10개면_9번후보도_하이라이트대상() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: nil,
            touchedSuggestionIndex: 9,
            touchedActionIndex: nil,
            suggestionCount: 10,
            actionCount: 3
        )

        #expect(state == .init(highlightedSuggestionIndex: 9, highlightedActionIndex: nil))
    }

    @Test("후보 수가 줄면 범위를 벗어난 preview 하이라이트는 무시")
    func test후보수가줄면_범위를벗어난preview하이라이트는무시() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 9,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 3
        )

        #expect(state == .none)
    }
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionBarViewRemovalLongPressTests \
  -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests
```

Expected: 컴파일 실패. `value of type 'SuggestionButtonView' has no member 'text'`

- [ ] **Step 3: `SuggestionButtonView`에 표시 텍스트 접근자를 넣는다**

`SuggestionButtonView.swift`의 `hasText` 선언을 아래로 바꾸고, 바로 아래
`leadingDivider`/`trailingDivider` 두 줄은 지운다. Task 1에서 대입하는 곳이
사라져 어디서도 읽지 않는 죽은 프로퍼티가 됐다.

```swift
    /// 현재 표시 중인 후보 문자열
    var text: String? {
        return suggestionLabel.text
    }

    var hasText: Bool {
        return !(text?.isEmpty ?? true)
    }
```

- [ ] **Step 4: 표시 개수를 후보 수에 맞춘다**

`SuggestionBarView.updateSuggestions(currentWord:suggestions:)`에서 Task 1의
고정 3칸 블록을 아래로 바꾼다.

```swift
        ensurePooledViews(count: titles.count)
        for (index, button) in pooledButtons.enumerated() {
            let title = index < titles.count ? titles[index] : ""
            button.update(to: title)
            button.isHidden = index >= titles.count
        }
        visibleSuggestionCount = titles.count
```

`let count = Int(SuggestionBarView.visibleSuggestionColumnCount)` 줄과 그 위 주석은
지운다. `visibleSuggestionColumnCount`는 버튼 폭 계산에만 남는다.

- [ ] **Step 5: preview 하이라이트 주석의 범위 표기를 고친다**

`updatePreviewHighlight(index:)`의 주석을 고친다. 구현은 이미
`suggestionButtons.indices`로 판정하므로 코드는 바꾸지 않는다.

```swift
    /// 스페이스로 자동 적용될 후보의 preview 하이라이트를 갱신합니다.
    ///
    /// 유효 범위는 지금 표시 중인 후보 버튼 개수를 따른다. 대상이 스크롤 밖에 있어도 자동으로 스크롤하지 않는다
    ///
    /// - Parameter index: 강조할 후보 인덱스, 없으면 `nil`
```

- [ ] **Step 6: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: PASS

- [ ] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
        Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift \
        SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift \
        SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
feat: #141 - 자동완성 후보 버튼을 후보 수에 맞춰 가변 배치

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: 가장자리 페이드

남은 내용이 있는 방향에만 스크롤 뷰 가장자리를 흐리게 한다. `UIScrollEdgeEffect`는
iOS 26 전용이고 #98에서 의도대로 표시되지 않았으므로 쓰지 않는다. `CAGradientLayer`
mask면 iOS 16부터 같은 결과를 얻는다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- Test: `SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift`

**Interfaces:**
- Produces:
  - `SuggestionScrollFadePolicy.edgeTolerance: CGFloat`
  - `SuggestionScrollFadePolicy.State(showsLeadingFade: Bool, showsTrailingFade: Bool)`
  - `SuggestionScrollFadePolicy.resolve(contentOffsetX:viewportWidth:contentWidth:) -> State`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`SuggestionHighlightPolicyTests.swift` 파일 끝에 새 suite를 더한다. 새 파일을
만들지 않으므로 `project.pbxproj`를 고칠 필요가 없다.

```swift
@Suite("후보 스크롤 가장자리 페이드 판정 검증")
struct SuggestionScrollFadePolicyTests {

    @Test("내용이 뷰포트를 넘지 않으면 양쪽 모두 페이드 없음")
    func test내용이뷰포트를넘지않으면_양쪽모두페이드없음() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0,
            viewportWidth: 300,
            contentWidth: 300
        )

        #expect(state == .none)
    }

    @Test("맨 왼쪽이면 오른쪽만 페이드")
    func test맨왼쪽이면_오른쪽만페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: false, showsTrailingFade: true))
    }

    @Test("가운데면 양쪽 페이드")
    func test가운데면_양쪽페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 300,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: true, showsTrailingFade: true))
    }

    @Test("맨 오른쪽이면 왼쪽만 페이드")
    func test맨오른쪽이면_왼쪽만페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 600,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: true, showsTrailingFade: false))
    }

    @Test("1pt 미만 차이는 페이드를 켜지 않음")
    func test1pt미만차이는_페이드를켜지않음() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0.2,
            viewportWidth: 300,
            contentWidth: 300.3
        )

        #expect(state == .none)
    }
}
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionScrollFadePolicyTests
```

Expected: 컴파일 실패. `cannot find 'SuggestionScrollFadePolicy' in scope`

- [ ] **Step 3: 정책을 추가한다**

`SuggestionHighlightPolicy.swift` 맨 위에 `import Foundation`이 없으면 더하고,
파일 끝에 아래를 붙인다. `Presentation/Utils/Policies/`에 새 파일을 만들면
세 모듈 타깃의 `membershipExceptions`를 함께 고쳐야 하므로, 같은 바의 표시 정책인
이 파일에 둔다.

```swift
// MARK: - SuggestionScrollFadePolicy

/// 후보 가로 스크롤의 가장자리 페이드 표시 여부를 정하는 정책
enum SuggestionScrollFadePolicy {

    /// 부동소수 오차로 1pt도 안 되는 차이에 페이드가 켜지는 것을 막는 허용 오차
    static let edgeTolerance: CGFloat = 0.5

    struct State: Equatable {
        let showsLeadingFade: Bool
        let showsTrailingFade: Bool

        static let none = State(showsLeadingFade: false, showsTrailingFade: false)
    }

    /// - Parameters:
    ///   - contentOffsetX: 스크롤 뷰의 가로 오프셋
    ///   - viewportWidth: 스크롤 뷰 `bounds`의 너비
    ///   - contentWidth: 스크롤 뷰 `contentSize`의 너비
    /// - Returns: 남은 내용이 있는 방향만 `true`인 상태
    static func resolve(
        contentOffsetX: CGFloat,
        viewportWidth: CGFloat,
        contentWidth: CGFloat
    ) -> State {
        guard viewportWidth > 0,
              contentWidth > viewportWidth + edgeTolerance else { return .none }

        return State(
            showsLeadingFade: contentOffsetX > edgeTolerance,
            showsTrailingFade: contentOffsetX + viewportWidth < contentWidth - edgeTolerance
        )
    }
}
```

`import Foundation`은 `CGFloat`를 위해 필요하다. 파일에 이미 다른 import가 없다면
맨 위에 넣는다.

- [ ] **Step 4: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: PASS

- [ ] **Step 5: 스크롤 뷰에 mask를 건다**

먼저 Task 1에서 리터럴로 둔 허용 오차를 정책 상수로 바꾼다.

```swift
    var isSuggestionAreaScrollable: Bool {
        return suggestionScrollView.contentSize.width
            > suggestionScrollView.bounds.width + SuggestionScrollFadePolicy.edgeTolerance
    }
```

`SuggestionBarView.swift`의 `// MARK: - UI Components`, `suggestionScrollView`
선언 아래에 넣는다.

```swift
    /// 스크롤 가장자리 페이드용 mask. 남은 방향에만 정지점을 넣어 흐리게 만든다
    private let edgeFadeLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]

        return layer
    }()
```

상수 구역(`dividerWidth` 옆)에 더한다.

```swift
    /// 가장자리 페이드 폭
    private static let edgeFadeWidth: CGFloat = 16
```

Private Methods 확장에 넣는다.

```swift
    /// 가장자리 페이드 mask의 프레임과 정지점을 갱신합니다.
    ///
    /// mask는 스크롤 뷰 `bounds` 좌표계라 `contentOffset`만큼 함께 움직인다. 매번 원점을 맞춘다
    func updateEdgeFade() {
        let bounds = suggestionScrollView.bounds
        guard bounds.width > 0 else { return }

        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: suggestionScrollView.contentOffset.x,
            viewportWidth: bounds.width,
            contentWidth: suggestionScrollView.contentSize.width
        )
        let fraction = min(SuggestionBarView.edgeFadeWidth / bounds.width, 0.5)
        let leading = NSNumber(value: state.showsLeadingFade ? Double(fraction) : 0)
        let trailing = NSNumber(value: state.showsTrailingFade ? Double(1 - fraction) : 1)

        // CALayer 암시적 애니메이션을 끄지 않으면 스크롤할 때마다 페이드가 늦게 따라온다
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeFadeLayer.frame = bounds
        edgeFadeLayer.locations = [NSNumber(value: 0.0), leading, trailing, NSNumber(value: 1.0)]
        CATransaction.commit()
    }
```

`setStyles()`에서 mask를 한 번만 건다.

```swift
    func setStyles() {
        self.backgroundColor = .clear
        suggestionScrollView.layer.mask = edgeFadeLayer
    }
```

`layoutSuggestionContent()` 마지막 줄(`suggestionScrollView.contentSize = ...`)
바로 뒤에 `updateEdgeFade()`를 부른다. `scrollViewDidScroll(_:)`에도 더한다.

```swift
extension SuggestionBarView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateEdgeFade()
        updateDividers()
    }
}
```

- [ ] **Step 6: 바 테스트가 여전히 통과하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionBarViewRemovalLongPressTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/SuggestionHighlightPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionScrollFadePolicyTests
```

Expected: PASS. mask가 걸려도 버튼 프레임과 하이라이트 판정은 바뀌지 않는다.

- [ ] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/SuggestionHighlightPolicy.swift \
        Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
        SYKeyboardTests/Utils/SuggestionHighlightPolicyTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
feat: #141 - 남은 방향에만 보이는 후보 스크롤 가장자리 페이드 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: n-gram 예측 상한을 10으로

`rankedUnigramCandidates()`는 전체 정렬 대신 상위 `maxPredictions`개만 유지하는 부분
삽입 정렬이다. N=3에 맞춰 검증된 코드이므로 **N을 늘리기 전에 항목 수가 N보다 적을
때·같을 때·많을 때를 모두 보는 테스트를 먼저 쓴다.**

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:103`
- Test: `SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift`

**Interfaces:**
- Consumes: 기존 `NGramPredictiveTextEngine(language:fileURL:legacyStorage:loadApplyDelay:maxKeys:)`, `addWord(_:)`, `suggestions(for:)`
- Produces: 없음(상수 변경)

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`NGramPredictiveTextEngineRankingTests.swift`에서 기존 두 테스트의 기대값을 10개
상한에 맞춰 고치고, 경계 케이스 세 개를 더한다.

기존 `test문맥이없으면_빈도상위3개를_빈도순으로반환`을 통째로 바꾼다.

```swift
    @Test("항목 수가 상한보다 적으면 있는 만큼 빈도순으로 반환")
    func test항목수가상한보다적으면_있는만큼빈도순으로반환() async {
        let engine = await makeLoadedEngine(name: "ranking-fewer")
        record(engine, word: "alpha", times: 5)
        record(engine, word: "bravo", times: 4)
        record(engine, word: "charlie", times: 3)
        record(engine, word: "delta", times: 2)
        record(engine, word: "echo", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie", "delta", "echo"])
    }

    @Test("항목 수가 상한과 같으면 전부 빈도순으로 반환")
    func test항목수가상한과같으면_전부빈도순으로반환() async {
        let engine = await makeLoadedEngine(name: "ranking-exact")
        let words = (1...10).map { "word\($0)" }
        for (index, word) in words.enumerated() {
            record(engine, word: word, times: 20 - index)
        }

        #expect(engine.suggestions(for: "") == words)
    }

    @Test("항목 수가 상한보다 많으면 상위 10개만 빈도순으로 반환")
    func test항목수가상한보다많으면_상위10개만_빈도순으로반환() async {
        let engine = await makeLoadedEngine(name: "ranking-more")
        let words = (1...14).map { "word\($0)" }
        for (index, word) in words.enumerated() {
            record(engine, word: word, times: 30 - index)
        }

        #expect(engine.suggestions(for: "") == Array(words.prefix(10)))
    }
```

기존 `test학습으로순위가바뀌면_후보가갱신`의 기대값을 고친다.

```swift
        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])

        record(engine, word: "delta", times: 4)

        #expect(engine.suggestions(for: "") == ["delta", "alpha", "bravo", "charlie"])
```

`testUnigram상한을넘으면_최소빈도단어가제거`는 `maxKeys: 3`이라 저장소 자체가 3개만
갖는다. 기대값을 바꾸지 않는다.

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests
```

Expected: FAIL. `test항목수가상한보다적으면...`이 `["alpha", "bravo", "charlie"]`만
돌려주고 5개를 기대한 단언이 깨진다.

- [ ] **Step 3: 상한을 올린다**

`NGramPredictiveTextEngine.swift:103` 근처를 고친다.

```swift
    /// 예측 최대 반환 개수
    ///
    /// 후보 바가 가로로 스크롤되므로 화면 밖 후보까지 만든다. `SuggestionController.maxSuggestions`와 같은 값이다
    private let maxPredictions = 10

    /// n-gram 키 최대 항목 수 (이 수를 초과하면 빈도 낮은 항목부터 정리)
    ///
    /// 실제로 노출하는 후보는 `maxPredictions`개뿐이고 나머지는 순위 변동을 위한 빈도 기록이다.
    /// 키보드 확장은 메모리에 민감하므로 여유를 남기는 선에서 상한을 둔다
    private let maxEntriesPerKey = 24
```

`maxEntriesPerKey = 24`는 그대로 둔다. `maxPredictions`가 10이어도 24는 여전히
"노출분 + 순위 변동 여유"라 주석 문구를 고칠 필요가 없다.

- [ ] **Step 4: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
        SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
feat: #141 - n-gram 예측 후보 상한을 10개로 확장

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 후보 상한을 10으로 올려 스크롤을 켠다

`SuggestionController.maxSuggestions`를 올리면 입력 중 모드의 엔진 몫이
`maxSuggestions - 1 = 9`, n-gram 모드가 10이 된다. 계산식은 이미 코드에 있으므로
수식은 건드리지 않는다. 이 커밋 하나가 기능의 on/off 스위치다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:269`
- Test: `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift`
- Test: `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift`

**Interfaces:**
- Consumes: 기존 `SuggestionController(language:engineFactory:textCheckerQueue:)`, `updateSuggestions(for:)`, `removableSuggestionText(atBarIndex:)`
- Produces: 없음(상수 변경)

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`SuggestionControllerTextCheckerLimitTests.swift`의 기존 두 테스트를 9슬롯에 맞춰
바꾸고 중복·현재 단어 제외 케이스를 더한다.

`test입력중TextChecker는_후보슬롯수를limit으로받음` 본문의 단언을 바꾼다.

```swift
        #expect(checker.receivedLimits == [9])
        #expect(delegate.updates.last?.currentWord == "hel")
        #expect(delegate.updates.last?.suggestions == ["hello", "help", "helmet"])
```

`testLexicon이슬롯을다채우면_TextChecker를조회하지않음`은 슬롯이 9개가 되었으므로
lexicon 항목을 9개로 늘린다.

```swift
    @Test("lexicon이 슬롯을 다 채우면 TextChecker를 조회하지 않음")
    func testLexicon이슬롯을다채우면_TextChecker를조회하지않음() async {
        let checker = RecordingPredictiveTextProvider(results: ["hello"])
        let delegate = RecordingSuggestionControllerDelegate()
        let documentTexts = (1...9).map { "entry\($0)" }
        let harness = makeController(
            checker: checker,
            lexiconEntries: documentTexts.map {
                TextReplacementEntry(userInput: "hel", documentText: $0)
            }
        )
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.callCount == 0)
        #expect(delegate.updates.last?.suggestions == documentTexts)
    }
```

같은 suite에 더한다.

```swift
    @Test("입력 중 후보는 9칸까지 차되 현재 단어와 중복을 제외")
    func test입력중후보는_9칸까지차되_현재단어와중복을제외() async {
        // TextChecker 결과는 limit으로 잘리지만 lexicon 결과는 잘리지 않는다.
        // 현재 단어 "hel"과 "hello"의 대소문자 중복을 lexicon 쪽에 두어 제외를 확인한다
        let checker = RecordingPredictiveTextProvider(
            results: (1...9).map { "help\($0)" }
        )
        let delegate = RecordingSuggestionControllerDelegate()
        let harness = makeController(
            checker: checker,
            lexiconEntries: ["hel", "hello", "Hello", "world"].map {
                TextReplacementEntry(userInput: "hel", documentText: $0)
            }
        )
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        let suggestions = delegate.updates.last?.suggestions ?? []
        #expect(checker.receivedLimits == [9])
        #expect(suggestions.count == 9)
        #expect(suggestions.contains("hel") == false)
        #expect(suggestions.contains("Hello") == false)
        #expect(suggestions == ["hello", "world",
                                "help1", "help2", "help3", "help4",
                                "help5", "help6", "help7"])
    }
```

`SuggestionControllerSuggestionRemovalTests.swift`에는 10칸 매핑 케이스를 더한다.

```swift
    @Test("입력 중 10칸에서도 바 인덱스가 후보 배열의 앞 한 칸만큼 밀림")
    func test입력중10칸에서도_바인덱스가_앞한칸만큼밀림() async {
        let checkerResults = (1...9).map { "help\($0)" }
        let harness = makeHarness(
            checkerResults: checkerResults,
            learnedWords: Set(checkerResults)
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == checkerResults)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "help1")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 9) == "help9")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 10) == nil)
    }
```

- [ ] **Step 2: 테스트가 실패하는 것을 확인한다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests \
  -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests
```

Expected: FAIL. `receivedLimits`가 `[2]`라 `[9]` 기대가 깨진다.

- [ ] **Step 3: 상한을 올린다**

`SuggestionController.swift:269`를 고친다.

```swift
    /// 후보 최대 표시 개수
    ///
    /// 후보 바가 가로로 스크롤되므로 화면에 보이는 3칸보다 많이 만든다.
    /// 입력 중 모드는 0번 칸이 `"현재단어"`라 엔진 몫이 `maxSuggestions - 1`이다.
    /// 이 값을 3으로 되돌리면 스크롤과 가장자리 페이드가 함께 사라진다
    private let maxSuggestions = 10
```

- [ ] **Step 4: 테스트가 통과하는 것을 확인한다**

Run: Step 2와 같은 명령

Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/SuggestionController.swift \
        SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift \
        SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
feat: #141 - 자동완성 후보 상한을 10개로 확장

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: 문서 갱신과 전체 검증

`CLAUDE.md`의 후보 스크롤 금지 조항을 이번 결정에 맞게 갱신하고, 전체 테스트와 세
키보드 extension 빌드를 돌려 결과를 이 계획 문서에 적는다.

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/architecture/자동완성 로직.md`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`
- Modify: `docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md`

- [ ] **Step 1: 이름이 실제 동작과 어긋난 테스트를 고친다**

`SuggestionBarViewRemovalLongPressTests.swift`의
`test누른후보를벗어나면_삭제를요청하지않고_드래그선택유지`는 이름에 "드래그 선택 유지"가
들어 있다. 실기기에서 후보를 가로로 끌면 `UIScrollView`가 터치를 가져가므로 끌어서
고르는 동작은 더 이상 없다. 이 테스트가 검증하는 것은 "누른 후보를 벗어나면 삭제
타이머가 취소된다"이므로 이름과 단언을 그 범위로 좁힌다.

```swift
    @Test("누른 후보를 벗어나면 삭제를 요청하지 않음")
    func test누른후보를벗어나면_삭제를요청하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let startPoint = center(of: fixture.buttons[0], in: fixture.bar)
        let endPoint = center(of: fixture.buttons[2], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: startPoint)
        fixture.bar.moveTouchInteraction(to: endPoint)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.removalRequestIndexes == [])
    }
```

- [ ] **Step 2: 드래그 선택을 전제로 한 주석을 고친다**

`KeyboardSuggestionSelectionPolicy.swift`의 `removalLongPressDuration` 주석에서
마지막 문장을 바꾼다.

```swift
    /// 자동완성 후보 삭제 확인을 띄우는 길게 누르기 시간
    ///
    /// 사용자 설정 `longPressDuration`과 별개인 고정값이다. 실기기 확인 결과 0.7초는
    /// 길게 느껴져 0.5초로 조정했다. 후보를 가로로 끌면 `UIScrollView`가 터치를 가져가
    /// 타이머가 취소되므로 스크롤 중에는 삭제 확인이 뜨지 않는다
    static let removalLongPressDuration: TimeInterval = 0.5
```

- [ ] **Step 3: `CLAUDE.md`의 금지 조항을 갱신한다**

「작업 원칙」 마지막 항목을 아래로 바꾼다.

```markdown
- 자동완성 후보 목록은 #141부터 `UIScrollView` 가로 스크롤이다. 선택은 탭으로만
  하고 끌면 스크롤한다. 터치 중재는 `UIScrollView` 기본 동작(`delaysContentTouches
  = false`, `canCancelContentTouches`)에 맡기고, `setScrollOffsetX` 같은 offset 직접
  조작이나 거리 임계값 기반 제스처 중재를 되살리지 않는다. 가장자리 페이드는
  `CAGradientLayer` mask이며 `UIScrollEdgeEffect`는 쓰지 않는다(#98에서 롤백됨).
  `SuggestionButtonView` **안의** 긴 텍스트는 여전히 스크롤하지 않는다. 두 줄·글자
  축소·중간 생략 동작을 유지한다.
```

「테스트 경계 예시」의 아래 줄도 바꾼다.

```markdown
- 명시적 UI 회귀 계약: 자동완성 후보 버튼 안 텍스트의 두 줄·자동 축소·중간 생략,
  후보 목록의 가로 스크롤 발생 조건(`contentSize.width > bounds.width`)
```

- [ ] **Step 4: 자동완성 문서를 갱신한다**

`docs/architecture/자동완성 로직.md`에서 두 곳을 고친다.

「3-1. 세 가지 모드」 표의 버튼 배치 열:

```markdown
| 1 | `isShowMathResultsEnabled`이고 `MathExpressionCompletionEvaluator.completion(for:)` 성공 | `.mathExpression` | 0번 `"원문"`, 1번 원문+결과, 2번 결과(대치). 3칸이라 스크롤되지 않는다 |
| 2 | baseText가 비었거나 공백으로 끝남 | `.nGram` | 0번부터 예측 후보, 최대 10개 |
| 3 | 단어 타이핑 중 | `.typing` | 0번 `"현재단어"`, 1번부터 자동완성 후보, 최대 9개 |
```

「3-4. n-gram 모드」 첫 문단:

```markdown
`nGramSuggestions(for:)`가 엔진 결과를 최대 10개로 잘라 반환한다. 후보 바는 3칸씩
보여 주고 나머지는 가로로 넘겨서 본다. 이력이 없으면 후보 칸이 하나도 만들어지지 않는다.
```

같은 문서 「3-3」 쪽의 `4. 최대 2개 반환 (button2~3용, maxSuggestions(3) - 1)`도
`4. 최대 9개 반환 (1번 칸부터, maxSuggestions(10) - 1)`로 고친다.

- [ ] **Step 5: 전체 테스트를 돌린다**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'
```

Expected: 전체 PASS. 통과한 테스트 개수와 실패 항목을 아래 「검증 결과」에 적는다.
`.xcresult`에서 결과를 읽었다면 산출물 경로와 추출 명령도 함께 적는다.

- [ ] **Step 6: 세 키보드 extension을 빌드한다**

`-only-testing`과 coverage 옵션이 남아 있지 않은 상태로 순서대로 돌린다.

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: 세 개 모두 `BUILD SUCCEEDED`

- [ ] **Step 7: 빌드 부수 효과를 되돌린다**

```bash
git status --short
```

`.xcscheme`이 보이면 `git diff`로 확인하고 `RemotePath`만 바뀐 경우 되돌린다.

```bash
git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/HangeulKeyboard.xcscheme
```

`RemotePath` 외의 항목이 바뀌었으면 되돌리지 말고 사용자에게 알린다.
`SYKeyboard/Presentation/Content/ContentView.swift`의 ` M`은 사용자 변경이므로
그대로 둔다.

- [ ] **Step 8: 검증 결과를 계획 문서에 적고 커밋**

아래 「검증 결과」 절에 실제 명령과 결과를 적는다.

```bash
git add CLAUDE.md \
        "docs/architecture/자동완성 로직.md" \
        Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift \
        SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift \
        docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
docs: #141 - 후보 가로 스크롤 결정에 맞춰 지침과 자동완성 문서 갱신

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: 실기기 수동 확인

자동 테스트와 빌드가 수동 관찰을 대체하지 않는다. iPhone 13 mini / iOS 18.6 실기기의
실제 입력 앱(메모, 메시지)에서 확인하고 결과를 아래 체크리스트에 적는다. 관찰하지
못한 항목은 미확인으로 남기고 완료로 표시하지 않는다.

**Files:**
- Modify: `docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md`

- [ ] **Step 1: 아래 「실기기 수동 확인」 항목을 하나씩 확인하고 결과를 적는다**

- [ ] **Step 2: 타이핑 지연을 실측한다**

Instruments의 os_signpost로 `LexiconSuggestions`,
`TextCheckerSuggestions`, `RankedUnigramCandidates` 구간을 본다. 상한을 올리기 전
(`Task 4` 이전 커밋)과 후의 값을 각각 기록한다. 메인 스레드에 실제로 늘어나는 비용은
버튼 레이아웃이므로 `SuggestionBarView.layoutSubviews` 구간도 함께 본다.

- [ ] **Step 3: 결과 기록을 커밋**

```bash
git add docs/superpowers/plans/2026-09-21-issue-141-suggestion-bar-horizontal-scroll.md
git commit -m "$(cat <<'EOF'
docs: #141 - 후보 가로 스크롤 실기기 수동 확인 결과 기록

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## 검증 결과

Task 6에서 채운다.

| 항목 | 명령 | 결과 |
|---|---|---|
| 전체 테스트 | (Task 6 Step 5) | 미실행 |
| HangeulKeyboard 빌드 | (Task 6 Step 6) | 미실행 |
| EnglishKeyboard 빌드 | (Task 6 Step 6) | 미실행 |
| HangeulEnglishKeyboard 빌드 | (Task 6 Step 6) | 미실행 |

## 실기기 수동 확인

iPhone 13 mini / iOS 18.6, 실제 입력 앱. Task 7에서 채운다.

- [ ] 짧은 탭으로 후보가 선택되고, 끌면 스크롤된다
- [ ] 후보에 손을 댄 즉시 하이라이트가 켜진다(`delaysContentTouches = false`)
- [ ] 스크롤 중에는 삭제 확인 오버레이가 뜨지 않는다
- [ ] 제자리에서 0.5초 누르면 삭제 확인 오버레이가 뜬다(#139 회귀 확인)
- [ ] 라이트/다크 모드에서 가장자리 페이드가 의도대로 보인다
- [ ] 반투명 키보드 배경에서도 페이드가 어색하지 않다
- [ ] 클립보드·undo/redo 버튼이 스크롤과 무관하게 동작한다
- [ ] 클립보드 패널을 열고 닫아 후보 영역 폭이 바뀌어도 버튼 폭이 다시 맞는다
- [ ] 수식 후보 3칸이 스크롤되지 않는다
- [ ] 가로 모드에서도 후보 폭과 스크롤이 정상이다
- [ ] 타이핑 지연이 체감되지 않는다(신호 구간 실측값 기록)
- [ ] 세 키보드(한글·영문·한영 통합) 모두에서 위 항목이 같다

## 되돌리는 법

`SuggestionController.maxSuggestions`를 `3`으로 되돌리면 후보가 3개를 넘지 않아
`contentSize.width`가 뷰포트를 넘지 않고, 스크롤과 가장자리 페이드가 함께 사라진다.
후보 개수로 분기하는 코드가 없으므로 다른 곳은 고치지 않아도 된다.
