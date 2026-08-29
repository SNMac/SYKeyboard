# 이슈 #119 대응 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 가로 모드 버튼 라벨 렌더링 2건, 회전 중 Auto Layout 경고, Swift 동시성 경고, 리뷰 팝업 전 입력 지연, 그리고 #112 후속 테스트 품질 4건을 한 PR로 정리한다.

**Architecture:** 시각 규칙은 `SwitchButton` / `LanguageSwitchButton`의 기존 `static` 정책 함수 패턴을 그대로 확장한다(너비 기준 → 너비·높이 기준). 제약 경고는 우선순위 하향, 동시성 경고는 클로저 래핑으로 끝난다. 리뷰 팝업 지연은 **원인 확정 전에는 수정하지 않는다** — 계측과 결정적 실험을 먼저 하고 결과에 따라 분기한다. 테스트 후속은 production 진입점 경유와 절대값 단언으로 바꾼다.

**Tech Stack:** Swift 5, UIKit, SwiftUI, Swift Testing, Xcode 26, iOS 16+

**Spec:** https://github.com/SNMac/SYKeyboard/issues/119

## Global Constraints

- 대상 브랜치: `develop`에서 분기. 단일 PR로 통합한다(사용자 결정).
- 검증 시뮬레이터: `iPhone 13 mini / iOS 16.0`. 없으면 가장 가까운 iOS 16+ 시뮬레이터로 조정하고 PR 본문에 실제 기기명·OS를 적는다.
- **새 파일을 만들지 않는다.** 전부 기존 파일 수정이므로 `SYKeyboard.xcodeproj/project.pbxproj`의 `membershipExceptions`를 건드릴 일이 없다.
- 빌드 후 `git status --short`에 `SYKeyboard.xcodeproj/xcshareddata/xcschemes/*.xcscheme`이 보이면 내용을 확인하고 `RemotePath`만 바뀐 경우 `git checkout --`으로 되돌린다.
- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)만 쓴다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. private 상태를 `Mirror`로 읽지 않는다.
- 커밋 메시지는 `type: #119 - subject` 형식. 마침표 없음. step마다 한 커밋.
- Firebase / AdMob / entitlements / bundle id / provisioning / `Secrets.xcconfig`는 건드리지 않는다.
- 이슈의 **10번(범위 밖 저장 배율)은 코드 변경 없이 종료**한다(사용자 결정: "처리하지 않음"). Task 10에서 이슈에만 근거를 남긴다.

**세로 모드 회귀 금지 계약** — Task 3·4는 가로 모드만 고치는 변경이다. 세로 모드에서 아래 값이 그대로여야 한다.

| 대상 | 세로 기준값 | 근거 |
|---|---|---|
| `SwitchButton` 보조 라벨 크기 | `FontSize.stringKeySmall` = 8.0pt | 실제 세로 배경 높이는 4x4 56, 쿼티 52로 모두 상한(40)을 넘어 8.0에 걸린다 |
| `LanguageSwitchButton` 사선 각도 | 세로 실측값 그대로(45° 미만으로 내려가지 않게 하는 바닥일 뿐, 45°로 고정하지 않는다) | 실제 세로 modifier 배경은 globe 숨김 42.75×56에서 50.0°, globe 표시 26.5×56에서 62.5°다 |

> **정정 (최종 코드 리뷰):** 이 계획은 세로 모드 행 높이를 48pt, 가로 모드 행 높이를 35pt로 잘못 계산했고, "세로 각도가 이미 ~45°"라고 잘못 전제했다. `KeyboardHeightPolicy.height(...)`에 따르면 기본 `keyboardHeight`(240)에서 세로 행 높이는 **60pt**, `landscapeKeyboardHeight`(188) 기준 가로 행 높이는 **36pt**다. 이 오차 때문에 Task 4에서 세로 각도를 45°로 고정하는 구현(`f82d3602`)이 채택됐고, 이는 실제로는 45°가 아니었던 세로 각도(50.0°/62.5°)를 45°로 눕혀 라벨 위치까지 바꾸는 회귀였다. 최종 수정은 세로 값을 그대로 두고 **각도가 45° 아래로 내려가는 경우에만** 가로 반길이를 세로 반길이까지 줄이는 45°-바닥 규칙으로 교체했다. 자세한 내용은 Task 3·Task 4 본문의 정정 블록과 최종 구현(`LanguageSwitchButton.dividerHalfExtents(forKeySize:)`, `SwitchButton.subLabelFullSizeKeyHeight` 주석)을 참고한다.

---

## File Structure

**production 수정 (5개 파일)**

| 파일 | 책임 | 이슈 항목 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/PrimaryKeyButton.swift` | `@MainActor` 함수 참조를 클로저로 감싸 동시성 경고 제거 | 4 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift` | 한 손 최소 너비 제약 우선순위 999 | 3 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift` | 보조 라벨 크기 정책에 높이 기준 추가 | 1 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift` | 구분선 기울기 고정 + 키 박스 클램프 | 2 |
| `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift` | 슬라이더 퍼센트 ↔ 배율 변환을 정책으로 노출 | 9 |
| `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift` | 파생 바인딩이 위 정책을 쓰도록 교체 | 9 |
| `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift` | 지연 구간 계측 → 확정된 원인에 맞게 수정 | 5 |

**테스트 수정 (4개 파일)**

| 파일 | 책임 | 이슈 항목 |
|---|---|---|
| `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift` | 라벨 크기·구분선 정책 단위 테스트, modifier 폭 절대값 단언 | 1, 2, 7 |
| `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift` | 붕괴 회귀 테스트를 `updateNextKeyboardButton` 경유로, 절대 폭 단언 추가 | 6, 7 |
| `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`, `NumericBottomSpaceLayoutTests.swift` | modifier 폭 절대값 단언 | 7 |
| `SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift` | 루프 범위 축소, 항진명제 제거, 바인딩 왕복 테스트 | 8, 9 |

---

## Task 1: 동시성 경고 제거 (이슈 4)

가장 기계적이고 다른 작업과 겹치지 않아 먼저 한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/PrimaryKeyButton.swift:120,133`

**Interfaces:**
- Consumes: 없음
- Produces: 없음 (동작 변경 없음)

- [x] **Step 1: 현재 경고를 확인한다**

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  2>&1 | grep "main actor-isolated static method 'displayLabel"
```

Expected: `PrimaryKeyButton.swift:120` `:133` 두 줄이 나온다. 나오지 않으면 이미 고쳐졌거나 빌드 설정이 다른 것이므로 멈추고 확인한다.

- [x] **Step 2: 함수 참조를 클로저로 감싼다**

`updatePrimaryKeyListLabel()` 안 두 곳만 바꾼다. `displayLabel(for:)` 본체와 호출 결과는 그대로다.

```swift
    func updatePrimaryKeyListLabel() {
        if type.primaryKeyList.count == 1 {
            // 함수 참조는 비격리 클로저로 전달돼 @MainActor 경고가 난다. 클로저로 감싸 격리를 유지한다
            guard let primaryKey = type.primaryKeyList.first.map({ Self.displayLabel(for: $0) }) else { return }
            primaryKeyListLabel.text = primaryKey
```

```swift
        } else {
            primaryKeyListLabel.text = type.primaryKeyList.map { Self.displayLabel(for: $0) }.joined(separator: "")
            primaryKeyListLabel.font = .systemFont(ofSize: FontSize.charKeyMedium)
        }
```

- [x] **Step 3: 경고가 사라졌는지 확인한다**

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  2>&1 | grep "main actor-isolated static method 'displayLabel"
```

Expected: 출력 없음 (grep exit code 1).

- [x] **Step 4: 라벨 표기 회귀가 없는지 기존 테스트로 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/PrimaryKeyButtonLabelTests
```

Expected: PASS.

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/PrimaryKeyButton.swift
git commit -m "fix: #119 - PrimaryKeyButton 주 키 라벨 갱신의 MainActor 격리 경고 제거"
```

**실행 결과 (커밋 `e842237d`):** 경고 제거 확인, `PrimaryKeyButtonLabelTests` 5/5 PASS.

---

## Task 2: 회전 중 Auto Layout 경고 제거 (이슈 3)

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift:195-198`

**Interfaces:**
- Consumes: 없음
- Produces: 없음 (`keyboardLayoutWidthConstraint`는 계속 private)

**단위 테스트를 추가하지 않는 이유:** `keyboardLayoutWidthConstraint`와 `keyboardLayoutView`는 private이고, CLAUDE.md가 `ForTesting` 접근자 추가와 `Mirror` 기반 private 상태 검증을 금지한다. 관찰 가능한 차이는 콘솔 경고뿐이므로 Step 1·4의 회전 실행이 검증 근거다. 이 사실을 PR 본문 검증 항목에 그대로 적는다.

- [ ] **Step 1: 수정 전 경고를 재현하고 기록한다** (미수행 — 사용자 확인 필요)

시뮬레이터에서 키보드 확장을 띄운 뒤 회전한다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

시뮬레이터에서 메시지 앱 등 텍스트 필드를 열고 SY키보드로 전환한 뒤 `Cmd+←`로 회전한다. Console.app 또는 Xcode 콘솔에서 다음을 확인한다.

Expected: `[LayoutConstraints] Unable to simultaneously satisfy constraints.` 와 목록 안의 `UIView:...width >= 300` / `UIView-Encapsulated-Layout-Width ... == 225`

이 경고가 재현되지 않으면 수정의 근거가 없으므로 멈추고 사용자에게 알린다.

- [x] **Step 2: 최소 너비 제약 우선순위를 999로 낮춘다**

`setConstraints()` 안의 세 줄을 바꾼다. 활성화된 제약은 required ↔ 비required로 바꿀 수 없으므로 **활성화 전에** 우선순위를 정한다.

```swift
        keyboardLayoutView.translatesAutoresizingMaskIntoConstraints = false
        let minWidth = UserDefaultsManager.shared.oneHandedKeyboardWidth
        let widthConstraint = keyboardLayoutView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth)
        // 회전 도중 키보드 폭이 일시적으로 최소 너비보다 좁아진다.
        // 의도는 "가능하면 최소 너비 이상"이므로 required보다 낮춰 Auto Layout이 양보하게 한다
        widthConstraint.priority = .init(999)
        widthConstraint.isActive = true
        keyboardLayoutWidthConstraint = widthConstraint
```

`keyboardLayoutWidthConstraint?.constant = width`(같은 파일 139행)는 그대로 둔다. 우선순위만 바뀌고 상수 갱신 경로는 변하지 않는다.

- [x] **Step 3: 한 손 키보드 폭이 여전히 적용되는지 기존 테스트로 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests \
  -only-testing:SYKeyboardTests/FourColumnWidthLayoutTests
```

Expected: PASS.

- [ ] **Step 4: 회전으로 경고가 사라졌는지 확인한다** (미수행 — 사용자 확인 필요)

Step 1과 동일한 절차를 반복한다.

Expected: `Unable to simultaneously satisfy constraints` 가 나오지 않는다. 세로·가로 모두에서 한 손 모드를 켜고 키보드 폭이 설정값대로 유지되는지 눈으로 확인한다.

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift
git commit -m "fix: #119 - 회전 중 한 손 키보드 최소 너비 제약 충돌 경고 제거"
```

**실행 결과 (커밋 `da18af35`):** 우선순위 999 변경과 `KeyboardModifierLayoutTests`/`FourColumnWidthLayoutTests`(Step 3) 확인은 수행했다. Step 1·4의 회전 실행과 콘솔 경고 재현·소멸 확인은 시뮬레이터/실기기에서 사람이 직접 회전하며 봐야 하는 작업이라 이번 자동 검증에서는 수행하지 못했다(사람 몫으로 남김).

---

## Task 3: 가로 모드 힌트 라벨 크기 (이슈 1)

`SwitchButton`의 보조 라벨(`⌨︎△`, `123▷`)이 가로 모드에서 가운데 라벨과 겹친다. 기존 `subLabelFontSize(forKeyWidth:)`에 **높이 인자를 추가**해 좁은 쪽 기준으로 줄인다(사용자 결정).

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift:27-32,114,141-147`
- Test: `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift`

**Interfaces:**
- Consumes: `FontSize.stringKeySmall` = 8.0
- Produces: `SwitchButton.subLabelFontSize(forKeyWidth: CGFloat, keyHeight: CGFloat) -> CGFloat` (internal static). 기존 `subLabelFontSize(forKeyWidth:)`는 **남기지 않고 교체**한다. 호출부는 `layoutSubviews()` 한 곳뿐이다.

**상수 근거** — `subLabelFullSizeKeyHeight = 40.0`

> **정정 (최종 코드 리뷰):** 아래 표의 버튼 높이 48/35는 잘못된 값이다. `KeyboardHeightPolicy.height(...)`를 보면 세로는 `keyboardHStackViewHeight = keyboardSettingsHeight`(자동완성 바는 그 위에 얹힌다), 가로는 `keyboardHStackViewHeight = landscapeKeyboardHeight − visibleSuggestionBarHeight`다. 기본 `keyboardHeight`(240)에서 세로 행 높이는 4행으로 나눈 **60**, `landscapeKeyboardHeight`(188) − 자동완성 바(44) = 144를 4행으로 나눈 가로 행 높이는 **36**이다. 결과 크기 열은 실제로도 8.0으로 상한에 걸려 있었으므로(48이든 60이든 40 이상이면 결과가 같다) 값 자체는 우연히 맞았지만, 가로 6.2/5.4는 실제로는 6.4/5.6이다.

| 상황 | 버튼 높이(정정) | `insetDy` | `backgroundView` 높이(정정) | 결과 크기 |
|---|---|---|---|---|
| 세로 4x4 (나랏글·천지인·숫자) | 60 | 2 | 56 | `min(8, 8×56/40)` = **8.0** (현행 유지) |
| 세로 쿼티·두벌식·기호 | 60 | 4 | 52 | `min(8, 8×52/40)` = **8.0** (현행 유지) |
| 가로 4x4 | 36 | 2 | 32 | `8×32/40` = **6.4** |
| 가로 쿼티·두벌식·기호 | 36 | 4 | 28 | `8×28/40` = **5.6** |

가로 행 높이 36pt는 `landscapeKeyboardHeight` 188 − 자동완성 바 `suggestionBarHeightWithTopSpacing` 44 = 144를 4행으로 나눈 값이다(별도의 `keyboardFrameSpacing` 차감은 없다). 세로는 `DefaultValues.keyboardHeight` 240 기준으로 60이다.

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift` 파일 끝(마지막 `}` 앞이 아니라 파일 최하단, `KeyboardModifierLayoutTests` 구조체 **바깥**)에 새 suite를 추가한다.

```swift
@MainActor
@Suite("전환 버튼 보조 라벨 크기")
struct SwitchButtonSubLabelFontSizeTests {
    private static let fullSize: CGFloat = 8.0

    @Test("세로 모드 키 크기에서는 기본 크기를 유지한다")
    func testPortraitKeepsFullSize() {
        // 세로 4x4: 버튼 48 - insetDy 2 * 2 = 44, 세로 쿼티: 48 - 4 * 2 = 40
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 44) - Self.fullSize) < 0.01)
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 33.0, keyHeight: 40) - Self.fullSize) < 0.01)
    }

    @Test("가로 모드 낮은 키에서는 높이에 비례해 줄인다")
    func testLandscapeShrinksWithHeight() {
        // 가로 4x4: 35 - 2 * 2 = 31, 가로 쿼티: 35 - 4 * 2 = 27
        let fourByFour = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 31)
        let qwerty = SwitchButton.subLabelFontSize(forKeyWidth: 200, keyHeight: 27)

        #expect(abs(fourByFour - Self.fullSize * 31 / 40) < 0.01)
        #expect(abs(qwerty - Self.fullSize * 27 / 40) < 0.01)
        #expect(qwerty < fourByFour)
        #expect(fourByFour < Self.fullSize)
    }

    @Test("좁은 키에서는 너비 기준 축소가 그대로 유지된다")
    func testNarrowKeyStillShrinksByWidth() {
        // 한 손 키보드처럼 좁은 키는 높이가 넉넉해도 너비 때문에 줄어야 한다
        let narrow = SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 44)

        #expect(abs(narrow - Self.fullSize * 20 / 25) < 0.01)
        #expect(narrow < Self.fullSize)
    }

    @Test("너비와 높이 중 좁은 쪽이 결과를 결정한다")
    func testUsesSmallerOfWidthAndHeightRule() {
        // 너비 20 -> 6.4, 높이 27 -> 5.4. 더 작은 5.4가 나와야 한다
        #expect(abs(SwitchButton.subLabelFontSize(forKeyWidth: 20, keyHeight: 27) - Self.fullSize * 27 / 40) < 0.01)
    }

    @Test("크기가 0이면 기본 크기로 되돌린다")
    func testNonPositiveSizeFallsBackToFullSize() {
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 0, keyHeight: 44) == Self.fullSize)
        #expect(SwitchButton.subLabelFontSize(forKeyWidth: 39.7, keyHeight: 0) == Self.fullSize)
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SwitchButtonSubLabelFontSizeTests
```

Expected: 컴파일 실패. `extra argument 'keyHeight' in call` 또는 `incorrect argument label`.

- [x] **Step 3: 정책 함수에 높이 기준을 추가한다**

`SwitchButton.swift`의 상수 선언(27-29행 부근)에 높이 상수를 더한다.

```swift
    /// 보조 라벨이 기본 크기 그대로 들어가는 최소 키 폭.
    /// 한 손 키보드처럼 이보다 좁아지면 글자가 키 밖으로 나가므로 너비에 비례해 줄인다
    private static let subLabelFullSizeKeyWidth: CGFloat = 25.0

    /// 보조 라벨이 기본 크기 그대로 들어가는 최소 키 높이.
    /// 가로 모드는 행 높이가 낮아(약 35pt) 모서리 힌트가 가운데 라벨과 겹치므로 높이에도 비례해 줄인다.
    /// 세로 모드 최소 키 높이(쿼티 40pt)를 기준값으로 잡아 세로 크기는 그대로 둔다
    private static let subLabelFullSizeKeyHeight: CGFloat = 40.0
```

정책 함수(141-147행)를 교체한다.

```swift
    /// 키 크기에 맞는 보조 라벨 글자 크기.
    /// 기본 크기를 상한으로 두고, 키가 좁거나 낮아지면 좁은 쪽 기준으로 줄인다
    static func subLabelFontSize(forKeyWidth width: CGFloat, keyHeight height: CGFloat) -> CGFloat {
        guard width > 0, height > 0 else { return FontSize.stringKeySmall }

        return min(FontSize.stringKeySmall,
                   FontSize.stringKeySmall * width / subLabelFullSizeKeyWidth,
                   FontSize.stringKeySmall * height / subLabelFullSizeKeyHeight)
    }
```

`layoutSubviews()`(114행) 호출부를 바꾼다.

```swift
        let subLabelFontSize = Self.subLabelFontSize(forKeyWidth: backgroundView.bounds.width,
                                                    keyHeight: backgroundView.bounds.height)
```

- [x] **Step 4: 테스트가 통과하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SwitchButtonSubLabelFontSizeTests
```

Expected: 5개 PASS.

- [ ] **Step 5: 실기기·시뮬레이터에서 겹침이 사라졌는지 확인한다** (미수행 — 사용자 확인 필요)

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

세로·가로 각각에서 `!#1` 버튼을 본다.
- 세로: 힌트 크기가 이전과 같아 보여야 한다.
- 가로: 힌트가 가운데 `!#1` 글자와 겹치지 않아야 한다.
- 한 손 모드 세로: 힌트가 키 밖으로 나가지 않아야 한다.
- 나랏글/천지인/두벌식/쿼티/기호/숫자 각각에서 확인한다.

**가로에서 여전히 겹치면** `subLabelFullSizeKeyHeight`를 40보다 크게(예: 48) 올려 더 줄인다. 세로 4x4(44)·세로 쿼티(40)에서 8.0이 유지되는지 Step 1 테스트의 기대값도 함께 갱신해야 하므로, 상수를 바꾸면 Step 1·4를 다시 돈다. **관찰하지 못한 조합이 있으면 미확인으로 기록하고 완료로 표시하지 않는다.**

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift \
        SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift
git commit -m "fix: #119 - 가로 모드에서 전환 버튼 힌트 라벨이 가운데 라벨과 겹치는 현상 수정"
```

**실행 결과 (커밋 `ee9e5baf`):** `SwitchButtonSubLabelFontSizeTests` 5/5 PASS. Step 5의 실기기·시뮬레이터 육안 확인(나랏글/천지인/두벌식/쿼티/기호/숫자 각각의 겹침 여부)은 사람이 화면을 봐야 하는 항목이라 미수행이다.

---

## Task 4: `한/A` 사선 각도 고정 (이슈 2)

현재 `layoutSubviews()`가 `halfWidth = 너비 × 0.22`, `halfHeight = 높이 × 0.20`으로 사선을 그려 **버튼 종횡비가 그대로 각도가 된다.** 가로 모드에서 키가 낮아지면 사선이 눕는다.

사용자 결정(초안, 이후 정정됨): ~~세로 모드 기준 각도를 가로에서도 유지한다. 실측한 세로 각도는 4x4 45.2°(39.7 × 44), 쿼티 47.8°(33 × 40)이므로 45°로 고정하고, 반길이는 두 비율이 만드는 박스 안에 들어가도록 클램프한다.~~

> **정정 (최종 코드 리뷰):** 위 문단은 잘못된 세로 배경 크기(39.7×44, 33×40 — 48pt 행 높이 가정)로 세로 각도를 45.2°/47.8°라고 잘못 계산했고, 이를 근거로 세로 각도까지 45°로 **고정**하는 구현(`f82d3602`)을 채택했다. 실제 세로 modifier 배경은 globe 숨김 42.75×56, globe 표시 26.5×56이며 각도는 **50.0°/62.5°**로 이미 45° 이상이다. 즉 세로는 원래부터 45°가 아니었고, "45°로 고정"은 세로 각도를 45°까지 눕히는 회귀였다. 최종 결정은 **세로 값을 그대로 두고, 각도가 45° 아래로 내려가는 경우에만(가로 4x4 34.2°) 가로 반길이를 세로 반길이까지 줄이는 45°-바닥** 규칙이다. `dividerAngle` 상수와 삼각함수는 모두 삭제했다 — 도달 가능한 각도가 45° 하나뿐이라 별도 상수로 뺄 이유가 없었다.

| 상황 | 실제 (halfW, halfH) → 각도 | 45°-바닥 적용 후 (halfW, halfH) → 각도 |
|---|---|---|
| 세로 4x4, globe 숨김 (42.75 × 56) | (9.405, 11.20) → 50.0° | (9.405, 11.20) → **50.0°** (변화 없음) |
| 세로 4x4/쿼티, globe 표시 (26.5 × 56) | (5.83, 11.20) → 62.5° | (5.83, 11.20) → **62.5°** (변화 없음) |
| 가로 4x4, globe 숨김 (42.75 × 32) | (9.405, 6.40) → 34.2° | (6.40, 6.40) → **45.0°** |
| 가로 4x4/쿼티, globe 표시 (26.5 × 32) | (5.83, 6.40) → 47.7° | (5.83, 6.40) → **47.7°** (변화 없음, 이미 45° 이상) |

`layoutLabels(halfWidth:halfHeight:)`가 `hypot`으로 법선을 구하므로, 두 반길이가 같아지면 법선이 `(-1/√2, -1/√2)`로 고정되고 `한`·`A` 라벨도 함께 45° 축에 정렬된다. **라벨 배치 코드는 손대지 않는다.**

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift:31-34,90-98,112-128`
- Test: `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - ~~`LanguageSwitchButton.dividerAngle: CGFloat` (internal static, 라디안)~~ — 정정 후 삭제됨. 도달 가능한 각도가 45° 하나뿐이라 상수로 뺄 이유가 없었다
  - `LanguageSwitchButton.dividerHalfExtents(forKeySize: CGSize) -> CGSize` (internal static)
  - `dividerWidthRatio` / `dividerHeightRatio` 는 instance `private let` → `private static let` 으로 옮긴다. 값(0.22 / 0.20)은 그대로다.

- [x] **Step 1: 실패하는 테스트를 쓴다**

`SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift` 파일 최하단에 suite를 추가한다.

```swift
@MainActor
@Suite("한영 전환 버튼 구분선 기울기")
struct LanguageSwitchButtonDividerTests {
    /// `dividerHalfExtents`가 만드는 사선의 각도(도)
    private static func angleInDegrees(forKeySize size: CGSize) -> CGFloat {
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)
        return atan2(extents.height, extents.width) * 180 / .pi
    }

    @Test("세로 키에서 사선 각도는 45도다")
    func testPortraitAngleIsFixed() {
        #expect(abs(Self.angleInDegrees(forKeySize: CGSize(width: 39.7, height: 44)) - 45) < 0.01)
        #expect(abs(Self.angleInDegrees(forKeySize: CGSize(width: 33, height: 40)) - 45) < 0.01)
    }

    @Test("가로처럼 낮은 키에서도 각도가 눕지 않는다")
    func testLandscapeKeepsSameAngle() {
        #expect(abs(Self.angleInDegrees(forKeySize: CGSize(width: 200, height: 31)) - 45) < 0.01)
        #expect(abs(Self.angleInDegrees(forKeySize: CGSize(width: 200, height: 27)) - 45) < 0.01)
    }

    @Test("반길이는 너비·높이 비율 박스를 넘지 않는다")
    func testHalfExtentsStayInsideRatioBox() {
        for size in [CGSize(width: 39.7, height: 44),
                     CGSize(width: 33, height: 40),
                     CGSize(width: 200, height: 27),
                     CGSize(width: 20, height: 60)] {
            let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: size)

            #expect(extents.width <= size.width * 0.22 + 0.001)
            #expect(extents.height <= size.height * 0.20 + 0.001)
            #expect(extents.width > 0)
            #expect(extents.height > 0)
        }
    }

    @Test("낮은 키에서는 높이 비율이 반길이를 결정한다")
    func testShortKeyIsLimitedByHeight() {
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: CGSize(width: 200, height: 27))

        #expect(abs(extents.height - 27 * 0.20) < 0.01)
        #expect(abs(extents.width - 27 * 0.20) < 0.01)
    }

    @Test("좁은 키에서는 너비 비율이 반길이를 결정한다")
    func testNarrowKeyIsLimitedByWidth() {
        let extents = LanguageSwitchButton.dividerHalfExtents(forKeySize: CGSize(width: 20, height: 60))

        #expect(abs(extents.width - 20 * 0.22) < 0.01)
        #expect(abs(extents.height - 20 * 0.22) < 0.01)
    }

    @Test("크기가 0이면 반길이도 0이다")
    func testZeroSizeYieldsZeroExtents() {
        #expect(LanguageSwitchButton.dividerHalfExtents(forKeySize: .zero) == .zero)
    }

    @Test("낮은 키에서도 두 글자가 버튼 안에 남는다")
    func testLabelsStayInsideShortKey() throws {
        let button = LanguageSwitchButton(mode: .hangeul)
        // 가로 모드 쿼티 키에 가까운 크기
        button.frame = CGRect(x: 0, y: 0, width: 39, height: 35)
        button.layoutIfNeeded()

        let labels = button.subviews.compactMap { $0 as? UILabel }.filter { $0.text == "한" || $0.text == "A" }
        #expect(labels.count == 2)

        for label in labels {
            #expect(label.frame.minX >= -0.5)
            #expect(label.frame.minY >= -0.5)
            #expect(label.frame.maxX <= button.bounds.width + 0.5)
            #expect(label.frame.maxY <= button.bounds.height + 0.5)
        }
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonDividerTests
```

Expected: 컴파일 실패. `type 'LanguageSwitchButton' has no member 'dividerHalfExtents'`.

- [x] **Step 3: 반길이 계산을 정책으로 뽑고 각도를 고정한다**

`LanguageSwitchButton.swift`의 instance 비율 상수(31-34행) 두 개를 static으로 옮긴다.

```swift
    /// 구분선 가로 반길이의 버튼 너비 대비 상한
    private static let dividerWidthRatio: CGFloat = 0.22
    /// 구분선 세로 반길이의 버튼 높이 대비 상한
    private static let dividerHeightRatio: CGFloat = 0.20
```

`// MARK: - Internal Methods` extension(112행 이후)에 각도 상수와 계산 함수를 더한다.

```swift
    /// 구분선 기울기(라디안).
    ///
    /// 예전에는 버튼 종횡비가 그대로 각도가 돼 행 높이가 낮은 가로 모드에서 사선이 누웠다.
    /// 세로 모드에서 나오던 각도(4x4 45.2°, 쿼티 47.8°)를 45°로 고정해 방향을 통일한다
    static let dividerAngle: CGFloat = .pi / 4

    /// 고정 기울기를 유지하면서 키 안에 들어가는 구분선 반길이.
    ///
    /// 기울기가 고정이므로 가로·세로 반길이 비가 항상 같고, 길이만 두 비율 상한 중
    /// 좁은 쪽에 맞춰 잘린다. 낮은 키에서는 높이가, 좁은 키에서는 너비가 길이를 정한다
    static func dividerHalfExtents(forKeySize size: CGSize) -> CGSize {
        let cosine = cos(dividerAngle)
        let sine = sin(dividerAngle)
        guard size.width > 0, size.height > 0, cosine > 0, sine > 0 else { return .zero }

        let length = min(size.width * dividerWidthRatio / cosine,
                         size.height * dividerHeightRatio / sine)

        return CGSize(width: length * cosine, height: length * sine)
    }
```

`layoutSubviews()`(90-98행)에서 반길이 계산을 교체한다. 나머지 줄은 그대로다.

**계획 수정 (실행 중 발견):** `dividerHalfExtents(forKeySize:)`는 `CGSize`를 받는데 `keyBounds`는 `CGRect`다. 아래 스니펫은 `keyBounds.size`로 넘긴다. 실제 구현도 `keyBounds.size`를 쓴다.

```swift
        let halfExtents = Self.dividerHalfExtents(forKeySize: keyBounds.size)
        let halfWidth = halfExtents.width
        let halfHeight = halfExtents.height

        let path = UIBezierPath()
        path.move(to: CGPoint(x: keyBounds.midX - halfWidth, y: keyBounds.midY + halfHeight))
        path.addLine(to: CGPoint(x: keyBounds.midX + halfWidth, y: keyBounds.midY - halfHeight))
        dividerLayer.path = path.cgPath

        layoutLabels(halfWidth: halfWidth, halfHeight: halfHeight)
```

- [x] **Step 4: 테스트가 통과하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonDividerTests \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests
```

Expected: 전부 PASS. 특히 `KeyboardModifierLayoutTests`의 기존 `labelFontSize` / `dividerLineWidth` 테스트가 깨지지 않아야 한다(둘은 너비 기준이라 이번 변경과 무관하다).

- [ ] **Step 5: 실기기·시뮬레이터에서 확인한다** (미수행 — 사용자 확인 필요)

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 세로: `한/A` 사선 각도와 두 글자 위치가 이전과 같아 보여야 한다.
- 가로: 사선이 세로와 같은 기울기로 보이고 `한`·`A`가 버튼 안에 있어야 한다.
- 한 손 모드: 좁은 키에서 글자가 사선과 겹치거나 밖으로 나가지 않아야 한다.
- 통합 키보드의 나랏글/천지인/두벌식/쿼티/숫자 배치 각각에서 확인한다.

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift \
        SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift
git commit -m "fix: #119 - 한영 전환 버튼 사선이 가로 모드에서 눕지 않도록 기울기 고정"
```

**실행 결과 (커밋 `f82d3602`):** `LanguageSwitchButtonDividerTests` 7/7 PASS. Step 3에서 `dividerHalfExtents(forKeySize:)` 호출부는 계획의 `keyBounds`가 아니라 `keyBounds.size`로 구현했다(위 계획 수정 참고). Step 5의 실기기·시뮬레이터 육안 확인(세로/가로/한 손 모드 각 배치)은 사람이 화면을 봐야 하는 항목이라 미수행이다.

---

## Task 5: 붕괴 회귀 테스트를 production 진입점 경유로 (이슈 6)

`FourColumnWidthLayoutTests.swift`의 두 테스트가 `nextKeyboardButton.isHidden = true` 와 `nextKeyboardButtonVisibilityDidChange(...)`를 손으로 두 단계 재현한다. 실제 진입점은 `NormalKeyboardLayoutProvider.updateNextKeyboardButton(needsInputModeSwitchKey:nextKeyboardAction:)`이고 그 안에서 `isHidden` 설정과 콜백 호출을 모두 한다. 지금 형태로는 진입점이 콜백 호출을 빠뜨려도 두 테스트가 통과한다.

같은 저장소의 `KeyboardModifierLayoutTests`, `CheonjiinBottomSpaceLayoutTests` 등이 이미 쓰는 `NSSelectorFromString("unusedNextKeyboardAction:")` 패턴으로 바꾼다.

**Files:**
- Modify: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift:255-257,379-381`

**Interfaces:**
- Consumes: `NormalKeyboardLayoutProvider.updateNextKeyboardButton(needsInputModeSwitchKey:nextKeyboardAction:)`
- Produces: 없음

- [x] **Step 1: 진입점 경유로 바꾼다**

`testBottomSpaceLayoutSplitsModifierStackEqually()`(255-257행 부근)의 세 줄을 바꾼다.

```swift
        // 지구본을 숨기면 modifier 스택에 한/영과 전환 버튼 2개만 남는다.
        // production 진입점을 그대로 호출해 isHidden 설정과 재배치 콜백을 함께 검증한다
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
```

`testHigherMultiplierKeepsModifierStackFromCollapsing()`(379-381행 부근)에도 같은 교체를 적용한다.

```swift
        // 지구본을 숨기면 modifier 스택에 한/영과 전환 버튼 2개만 남는다.
        // production 진입점을 그대로 호출해 isHidden 설정과 재배치 콜백을 함께 검증한다
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
```

`Foundation`(`NSSelectorFromString`)이 필요하다. 파일 상단 import에 없으면 추가한다.

```swift
import Foundation
import Testing
import UIKit
```

- [x] **Step 2: 테스트가 통과하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinColumnWidthLayoutTests \
  -only-testing:SYKeyboardTests/NumericColumnWidthLayoutTests
```

Expected: PASS.

- [x] **Step 3: 테스트가 실제로 진입점을 검증하는지 확인한다**

`NormalKeyboardLayoutProvider.swift:37`의 `nextKeyboardButtonVisibilityDidChange(...)` 호출을 잠시 주석 처리하고 Step 2를 다시 돌린다.

Expected: 두 테스트가 **FAIL**. (수정 전에는 통과했었다.) 확인 후 주석을 원복하고 `git diff`가 `FourColumnWidthLayoutTests.swift`만 담고 있는지 본다.

```sh
git checkout -- Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift
git status --short
```

- [x] **Step 4: 커밋**

```bash
git add SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "test: #119 - modifier 붕괴 회귀 테스트를 updateNextKeyboardButton 진입점 경유로 변경"
```

**실행 결과 (커밋 `e3233e62`):** Step 3의 mutation check를 실제로 실행했다. `NormalKeyboardLayoutProvider.swift:37`의 `nextKeyboardButtonVisibilityDidChange(...)` 호출을 주석 처리한 뒤 재실행하면 `NumericColumnWidthLayoutTests/testHigherMultiplierKeepsModifierStackFromCollapsing`과 `CheonjiinColumnWidthLayoutTests/testBottomSpaceLayoutSplitsModifierStackEqually` 두 개만 FAIL했고, 나머지는 그대로 PASS했다. 확인 후 `NormalKeyboardLayoutProvider.swift`는 원복했다.

---

## Task 6: modifier 폭 단언에 절대값 추가 (이슈 7)

현재 기대값이 `modifierStack.frame.width / 보이는 버튼 수`뿐이라, modifier 열 자체가 잘못된 폭으로 무너져도 두 버튼이 반씩 나눠 갖기만 하면 통과한다. 배율 1.0 고정 테스트에는 `키보드 폭 / 4 / 보이는 버튼 수` 절대값을 함께 단언한다.

**단, 배율 1.15 테스트는 열 폭이 `keyboardWidth × 0.2875`이므로 절대값이 다르다.** `FourColumnWidthLayoutTests`의 두 테스트는 이미 `modifierStack.frame.width`의 절대값을 따로 단언하고 있으니(`0.2875` 비교), 아래 표대로 각각 맞는 값을 쓴다.

| 테스트 | 파일:행 | 배율 | modifier 열 폭 | 버튼 기대 폭 |
|---|---|---|---|---|
| `testUnifiedNumericHiddenGlobeSplitsModifierStackEqually` | `KeyboardModifierLayoutTests.swift:225` | 1.0 | 390 / 4 = 97.5 | 48.75 |
| `testFourByFourHiddenGlobeSplitsModifierStackEqually` | `KeyboardModifierLayoutTests.swift:331` | 1.0 | 390 / 4 = 97.5 | 48.75 |
| `testCheonjiin...`(하단 스페이스) | `CheonjiinBottomSpaceLayoutTests.swift:141` | 기본값 | 아래 Step 1에서 실측 후 고정 | — |
| `testNumeric...`(하단 스페이스) | `NumericBottomSpaceLayoutTests.swift:95` | 기본값 | 아래 Step 1에서 실측 후 고정 | — |
| `testBottomSpaceLayoutSplitsModifierStackEqually` | `FourColumnWidthLayoutTests.swift:250` | 1.15 | 이미 `0.2875` 절대 단언 있음 | 추가 불필요 |
| `testHigherMultiplierKeepsModifierStackFromCollapsing` | `FourColumnWidthLayoutTests.swift:374` | 1.15 | 절대 단언 없음 → 추가 | `390 × 0.2875 / 2` |

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift`
- Modify: `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`
- Modify: `SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift`
- Modify: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: 없음

- [x] **Step 1: 하단 스페이스 두 테스트의 실제 배율과 열 폭을 확인한다**

두 테스트는 `updateLetterColumnWidthMultiplier`를 호출하는지 여부가 파일마다 다를 수 있다. 확인한다.

```sh
grep -n "updateLetterColumnWidthMultiplier\|CGRect(x: 0, y: 0" \
  SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift \
  SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift
```

- 해당 테스트가 `updateLetterColumnWidthMultiplier(1.0)`을 호출하면 modifier 열 폭은 `키보드 폭 / 4`다.
- 호출하지 않으면 **먼저 `view.updateLetterColumnWidthMultiplier(1.0)`을 추가한다.** 기본 인자가 App Group `UserDefaults`를 읽어 시뮬레이터 상태에 따라 값이 달라지므로, 절대값 단언을 붙이기 전에 배율을 고정해야 한다. 같은 파일의 다른 테스트가 쓰는 주석 문구를 그대로 따른다.

```swift
        // 저장된 사용자 설정과 무관하게 기본 배율로 고정한다
        view.updateLetterColumnWidthMultiplier(1.0)
```

- [x] **Step 2: 절대값 단언을 추가한다**

`KeyboardModifierLayoutTests.swift:243` 부근(`testUnifiedNumericHiddenGlobeSplitsModifierStackEqually`)에 두 줄을 더한다.

```swift
        let modifierStack = try #require(languageButton.superview)
        // 지구본이 숨겨져 한/영과 전환 버튼 2개만 남는다
        let visibleButtonCount: CGFloat = 2
        // 열 자체가 무너져도 두 버튼이 반씩 나눠 가지면 상대 단언은 통과한다.
        // 배율 1.0에서 modifier 열은 키보드 폭의 1/4이므로 절대값을 함께 고정한다
        let expectedButtonWidth = width / CGFloat(4) / visibleButtonCount

        #expect(view.nextKeyboardButton.isHidden)
        #expect(abs(modifierStack.frame.width - width / 4) < 0.5)
        #expect(abs(languageButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(abs(view.switchButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(
            abs(languageButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
        #expect(
            abs(view.switchButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
```

`testFourByFourHiddenGlobeSplitsModifierStackEqually`(`:331` 부근)에도 같은 형태를 적용한다. 이 테스트는 폭이 리터럴 `390`이므로 지역 상수를 먼저 뽑는다.

```swift
        let width: CGFloat = 390
        view.frame = CGRect(x: 0, y: 0, width: width, height: 216)
```

그리고 단언 블록:

```swift
        let modifierStack = try #require(languageButton.superview)
        // globe가 빠지면 한/영과 전환 버튼 2개가 modifier 스택을 균등하게 나눈다
        let visibleButtonCount: CGFloat = 2
        // 배율 1.0에서 modifier 열은 키보드 폭의 1/4이다. 열 붕괴를 잡으려면 절대값이 필요하다
        let expectedButtonWidth = width / CGFloat(4) / visibleButtonCount

        #expect(primaryView.nextKeyboardButton.isHidden)
        #expect(abs(modifierStack.frame.width - width / 4) < 0.5)
        #expect(abs(languageButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(abs(primaryView.switchButton.frame.width - expectedButtonWidth) < 0.5)
        #expect(
            abs(languageButton.frame.width - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
        #expect(
            abs(primaryView.switchButton.frame.width
                - modifierStack.frame.width / visibleButtonCount) < 0.5
        )
```

`CheonjiinBottomSpaceLayoutTests.swift:141` / `NumericBottomSpaceLayoutTests.swift:95` 부근에도 같은 두 줄(`modifierStack.frame.width`, 각 버튼의 `expectedButtonWidth`)을 더한다. 폭 리터럴이 지역 상수가 아니면 먼저 상수로 뽑는다.

`FourColumnWidthLayoutTests.swift:374`의 `testHigherMultiplierKeepsModifierStackFromCollapsing`에는 배율 1.15 기준 절대값을 더한다.

```swift
        let modifierStack = try #require(languageSwitchButton.superview)
        let visibleButtonCount: CGFloat = 2
        let buttonWidth = languageSwitchButton.frame.width
        // 배율 1.15에서 기능 열은 키보드 폭의 0.1375, 글자 열은 0.2875다.
        // 기본 배치(하단 스페이스 아님)의 modifier 스택은 4행 4열(기능 열)에 놓인다
        let expectedStackWidth = Self.keyboardWidth * 0.1375

        #expect(abs(modifierStack.frame.width - expectedStackWidth) < Self.tolerance)
        #expect(abs(buttonWidth - expectedStackWidth / visibleButtonCount) < Self.tolerance)
```

**주의:** 위 `expectedStackWidth`가 실제 값과 다르면(하단 스페이스 배치가 아니므로 4행 1열이 기능 열일 수 있다) 단언이 실패한다. 실패하면 **테스트를 실제 측정값에 맞추지 말고**, 먼저 `#expect(modifierStack.frame.width == 0)` 같은 임시 단언으로 실측값을 출력해 어느 열인지 확인한 뒤 그 열의 정의값(`0.2875` 또는 `0.1375`)을 쓴다. 실측값을 그대로 상수로 박으면 이 단계의 목적(절대 계약 고정)이 사라진다.

**계획 수정 (실행 중 발견):** 위 스니펫의 초안은 `expectedStackWidth`를 글자 열 값 `0.2875`로 썼으나, `NumericKeyboardView.setHierarchy()`에서 `usesBottomSpaceLayout == false`일 때 modifier 스택은 4행의 마지막 슬롯인 **기능 열**(4번째 열)에 놓인다. 실제로 맞는 값은 **`0.1375`**(390 × 0.1375 = 53.625, 버튼당 26.8125)이며, 구현 코드와 이 문서 모두 `0.1375`를 쓴다.

- [x] **Step 3: 테스트가 통과하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests \
  -only-testing:SYKeyboardTests/NumericBottomSpaceLayoutTests \
  -only-testing:SYKeyboardTests/CheonjiinColumnWidthLayoutTests \
  -only-testing:SYKeyboardTests/NumericColumnWidthLayoutTests
```

Expected: 전부 PASS.

- [x] **Step 4: 커밋**

```bash
git add SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift \
        SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift \
        SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift \
        SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "test: #119 - modifier 스택 폭 단언에 열 절대 폭 검증 추가"
```

**실행 결과 (커밋 `720f0994`):** 위 계획 수정대로 `0.1375`를 적용해 관련 스위트 전부 PASS.

---

## Task 7: 정책 테스트 루프 범위 축소 (이슈 8)

`KeyboardColumnWidthPolicyTests`의 합=1 검증 루프가 `0...20`(배율 1.20)까지 돈다. 상한이 1.15로 바뀐 뒤 상한 밖 5회는 clamp된 같은 값을 반복 검증할 뿐이다.

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift:26`

**Interfaces:**
- Consumes: `KeyboardLayoutFigure.letterColumnWidthMultiplierRange`
- Produces: 없음

- [x] **Step 1: 루프 범위를 상한에 맞춘다**

리터럴 `0...15` 대신 범위 상수에서 계산해, 앞으로 상한이 바뀌어도 루프가 자동으로 따라오게 한다.

```swift
    @Test("글자 열 3개와 기능 열의 합은 항상 1이다")
    func testColumnRatiosAlwaysSumToOne() {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        // 상한 밖은 clamp돼 같은 값을 반복 검증할 뿐이므로 허용 범위 안만 돈다
        let lastStep = Int(((range.upperBound - range.lowerBound) * 100).rounded())

        for step in 0...lastStep {
            let multiplier = range.lowerBound + Double(step) * 0.01
            let total = 3 * KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: multiplier)
            + KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

            #expect(abs(total - 1.0) < Self.tolerance)
        }
    }
```

- [x] **Step 2: 테스트가 통과하고 실제로 16회 도는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests
```

Expected: PASS. `lastStep`은 `(1.15 - 1.0) * 100 = 15`이므로 `0...15`, 16회다.

- [x] **Step 3: 커밋**

```bash
git add SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift
git commit -m "test: #119 - 열 너비 정책 합계 루프를 허용 배율 범위로 제한"
```

**실행 결과 (커밋 `f99be1ed`):** `KeyboardColumnWidthPolicyTests` 5/5 PASS (Task 8 이전 시점 기준).

---

## Task 8: 슬라이더 파생 바인딩 왕복 검증 (이슈 9)

현재 테스트의 `(percent.upperBound - percent.lowerBound).truncatingRemainder(dividingBy: 1) == 0`은 정수 상수에 대한 **항진명제**라 실효가 없다. 실제 버그 지점인 퍼센트 ↔ 배율 왕복을 검증하도록 바꾼다.

SwiftUI `Slider` 자체는 단위 테스트가 어렵다. 현실적인 경계는 **파생 바인딩이 쓰는 변환 함수**이므로, `LetterColumnWidthSettingsView` 안에 인라인으로 있던 변환을 `KeyboardLayoutFigure`로 옮겨 테스트가 production 함수를 직접 호출하게 한다. **새 파일을 만들지 않는다** — 퍼센트 범위 상수가 이미 `KeyboardFigure.swift`에 있으므로 같은 자리에 둔다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift:48` 이후
- Modify: `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift:64-71,75`
- Test: `SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift:57-69`

**Interfaces:**
- Consumes: `KeyboardLayoutFigure.letterColumnWidthPercentRange`, `letterColumnWidthMultiplierRange`
- Produces:
  - `KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: Double) -> Double` (public static)
  - `KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: Double) -> Double` (public static)

- [x] **Step 1: 실패하는 테스트를 쓴다**

`KeyboardColumnWidthPolicyTests.swift`의 `testPercentRangeMatchesMultiplierRangeWithWholeSteps()`(57-69행)를 통째로 아래로 교체한다. 항진명제 단언은 제거한다.

```swift
    @Test("슬라이더 정수 범위는 배율 범위와 일치한다")
    func testPercentRangeMatchesMultiplierRange() {
        let percent = KeyboardLayoutFigure.letterColumnWidthPercentRange
        let multiplier = KeyboardLayoutFigure.letterColumnWidthMultiplierRange

        #expect(percent.lowerBound == 100)
        #expect(percent.upperBound == 115)
        #expect(abs(percent.lowerBound / 100 - multiplier.lowerBound) < Self.tolerance)
        #expect(abs(percent.upperBound / 100 - multiplier.upperBound) < Self.tolerance)
    }

    @Test("슬라이더 파생 바인딩은 전 구간에서 값을 잃지 않고 왕복한다")
    func testSliderBindingRoundTripsAcrossWholeRange() {
        let percentRange = KeyboardLayoutFigure.letterColumnWidthPercentRange

        for step in 0...Int(percentRange.upperBound - percentRange.lowerBound) {
            let percent = percentRange.lowerBound + Double(step)

            // set: 슬라이더가 준 정수 퍼센트 -> 저장할 배율
            let multiplier = KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: percent)
            // get: 저장된 배율 -> 슬라이더가 표시할 정수 퍼센트
            let roundTripped = KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: multiplier)

            #expect(abs(roundTripped - percent) < Self.tolerance)
            // 실수 step에서 상한에 닿지 못하던 버그의 회귀 방지: 정수로 정확히 떨어져야 한다
            #expect(roundTripped == roundTripped.rounded())
            #expect(percentRange.contains(roundTripped))
        }
    }

    @Test("상한 배율은 슬라이더 상한 퍼센트로 정확히 표시된다")
    func testUpperBoundMultiplierMapsToUpperBoundPercent() {
        let multiplierRange = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        let percentRange = KeyboardLayoutFigure.letterColumnWidthPercentRange

        // 실수 step 시절 상한에 닿지 못해 115 대신 114에서 멈추던 지점이다
        #expect(KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: multiplierRange.upperBound)
                == percentRange.upperBound)
        #expect(KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: percentRange.upperBound)
                == multiplierRange.upperBound)
    }
```

- [x] **Step 2: 테스트가 실패하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests
```

Expected: 컴파일 실패. `type 'KeyboardLayoutFigure' has no member 'letterColumnWidthMultiplier(fromPercent:)'`.

- [x] **Step 3: 변환 함수를 `KeyboardLayoutFigure`로 옮긴다**

`KeyboardFigure.swift`의 `letterColumnWidthPercentRange` 선언(48행) 바로 뒤에 더한다.

```swift
    /// 저장된 배율을 슬라이더가 표시할 정수 퍼센트로 바꾼다
    public static func letterColumnWidthPercent(fromMultiplier multiplier: Double) -> Double {
        return (multiplier * 100).rounded()
    }

    /// 슬라이더가 준 정수 퍼센트를 저장할 배율로 바꾼다
    public static func letterColumnWidthMultiplier(fromPercent percent: Double) -> Double {
        return percent / 100
    }
```

- [x] **Step 4: 설정 화면 바인딩이 이 함수를 쓰게 한다**

`LetterColumnWidthSettingsView.swift:64-71`을 교체한다.

```swift
private extension LetterColumnWidthSettingsView {
    /// 슬라이더용 정수 바인딩. 실수 step의 부동소수점 오차를 피한다
    var letterColumnWidthPercent: Binding<Double> {
        Binding(
            get: { KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier) },
            set: { tempLetterColumnWidthMultiplier = KeyboardLayoutFigure.letterColumnWidthMultiplier(fromPercent: $0) }
        )
    }
```

같은 파일 75행의 표시용 계산도 같은 함수를 쓰게 해 표시와 슬라이더가 어긋나지 않게 한다.

```swift
            Text("\(Int(KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier: tempLetterColumnWidthMultiplier)))")
```

- [x] **Step 5: 테스트가 통과하는지 확인한다**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests
```

Expected: 전부 PASS.

- [ ] **Step 6: 설정 화면이 그대로 동작하는지 확인한다** (미수행 — 사용자 확인 필요)

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

시뮬레이터에서 앱 → 글자 열 너비 화면을 연다.
- 슬라이더를 끝까지 밀면 **115**가 표시된다(114에서 멈추지 않는다).
- 왼쪽 끝은 100이다.
- 리셋 버튼이 100으로 되돌린다.
- 저장 후 다시 들어오면 저장한 값이 그대로 보인다.
- 미리보기 키보드의 열 폭이 값에 따라 변한다.

- [x] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift \
        SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift \
        SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift
git commit -m "test: #119 - 글자 열 너비 슬라이더 파생 바인딩 왕복 검증으로 교체"
```

**실행 결과 (커밋 `a404cf87`):** `KeyboardColumnWidthPolicyTests` 7/7 PASS. Step 6(설정 화면에서 슬라이더가 115에 도달하는지 등 육안 확인)은 사람이 화면을 봐야 하는 항목이라 미수행이다.

---

## Task 9: 리뷰 팝업 전 입력 지연 — 계측 후 수정 (이슈 5)

**이번 PR 범위에서 미구현.** 계측이 화면 녹화를 동반한 사람 관측을 요구하므로 이번 PR 범위에서 제외했고, 적용 가능한 패치와 측정 절차는 `.superpowers/sdd/2026-08-30-issue-119-landscape-labels-and-followups/task-9-measurement-guide.md`에 있다. 아래 Step 1~8은 코드로 수행하지 않았으며 체크박스는 모두 미완료로 남긴다.

**이 task는 원인을 확정하기 전에 코드를 고치지 않는다.** 이슈 본문이 후보 2가지를 제시했고 둘 중 어느 쪽인지에 따라 고칠 곳이 완전히 다르다.

- 후보 1: 의도적인 `Task.sleep(1초)`. 관찰된 "몇 초"보다 짧아 단독으로는 설명되지 않는다.
- 후보 2: StoreKit이 리뷰 프롬프트용 window를 먼저 올리고 App Store 연결을 기다리는 구간. 이 window가 터치를 삼킨다.

**Files:**
- Modify: `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift:74-79`

**Interfaces:**
- Consumes: `RequestReviewPolicy.recordDetailSettingsReturnAndEvaluate(...)`, `@Environment(\.requestReview)`
- Produces: 없음 (`presentReview()`는 계속 private)

- [ ] **Step 1: 계측을 넣는다** (미수행 — 사용자 확인 필요)

`presentReview()`에 구간 로그를 추가한다. 이 계측은 Step 4에서 결과를 기록한 뒤 제거하거나 `debug` 수준으로 남긴다.

```swift
    func presentReview() {
        let start = ContinuousClock.now
        Task {
            Self.logger.debug("[review] presentReview 진입")
            try? await Task.sleep(for: .seconds(1))
            Self.logger.debug("[review] sleep 종료 +\(start.duration(to: .now), privacy: .public)")
            requestReview()
            Self.logger.debug("[review] requestReview 반환 +\(start.duration(to: .now), privacy: .public)")
        }
    }
```

`ContinuousClock`은 iOS 16+에서 쓸 수 있다. 컴파일이 막히면 `Date()` 차이로 대체한다.

- [ ] **Step 2: 카운터를 임계값 직전으로 맞춰 재현한다** (미수행 — 사용자 확인 필요)

`RequestReviewPolicy.threshold`가 30이라 자연 재현에 세부 설정 화면 진입이 30번 필요하다. 재현을 위해 임시로 저장된 카운터를 올린다. **production 코드의 threshold는 바꾸지 않는다.**

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

시뮬레이터에서 앱을 실행한 뒤, 세부 설정 화면(예: 키보드 높이)에 29번 들어갔다 나온다. 30번째에 팝업이 뜬다. Console.app에서 `subsystem` 필터로 앱 번들 ID, `category`를 `RequestReviewViewModifier`로 걸고 위 세 줄을 본다.

동시에 **화면 녹화**를 켜서 다음 두 시각을 잰다.
- 세부 설정 화면이 사라진 시각
- 터치가 다시 먹기 시작한 시각 / 팝업이 뜬 시각

Expected 기록 항목:

| 구간 | 측정값 |
|---|---|
| `presentReview` 진입 → `sleep` 종료 | (기대 약 1.0s) |
| `sleep` 종료 → `requestReview` 반환 | |
| `requestReview` 반환 → 팝업 표시(녹화) | |
| 터치 먹통 총 길이(녹화) | |

- [ ] **Step 3: 결정적 실험 — sleep을 0으로 두고 다시 잰다** (미수행 — 사용자 확인 필요)

`Task.sleep` 한 줄만 주석 처리하고 Step 2를 반복한다.

```swift
            // try? await Task.sleep(for: .seconds(1))
```

- 먹통 구간이 **1초만큼만 줄고 나머지가 남으면** → 후보 2(StoreKit) 지배적.
- 먹통 구간이 **거의 사라지면** → 후보 1(sleep) 지배적.

두 결과 모두 계획 문서의 이 표에 실제 숫자로 적는다. **여기까지 하지 않고 다음 step으로 넘어가지 않는다.**

- [ ] **Step 4: 확정된 원인에 맞게 고친다** (미수행 — 사용자 확인 필요)

**후보 1로 확정된 경우** — sleep이 먹통의 대부분이다. 지연을 없앤다. `.onDisappear` 직후 즉시 호출하면 pop 애니메이션과 겹치므로, 화면 전환이 끝난 다음 run loop로만 미룬다.

```swift
    func presentReview() {
        // 화면 전환 애니메이션과 겹치지 않게 다음 run loop로만 미룬다.
        // 예전의 1초 sleep은 그동안 터치가 먹지 않는 구간을 만들었다
        Task { @MainActor in
            await Task.yield()
            requestReview()
        }
    }
```

**후보 2로 확정된 경우** — sleep을 지워도 먹통이 남는다. 지연 소유자는 StoreKit이고 앱이 줄일 수 없다. 할 수 있는 건 **먹통이 얹히는 순간을 옮기는 것**뿐이다. pop 애니메이션 위가 아니라 목록 화면이 안정된 뒤로 미룬다.

```swift
    func presentReview() {
        // StoreKit이 프롬프트용 window를 올리고 App Store 연결을 기다리는 동안 터치가 먹지 않는다.
        // 이 구간은 앱이 줄일 수 없으므로, 최소한 화면 전환 애니메이션 위에 겹치지 않도록
        // 목록 화면이 안정된 뒤로 미룬다
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            requestReview()
        }
    }
```

그리고 남는 지연이 StoreKit 소유임을 이슈 #119에 코멘트로 남긴다(Task 10에서 함께 처리).

**둘 다 아니거나 재현되지 않은 경우** — 수정하지 않는다. 계측 결과를 이 문서와 이슈에 적고, 이 항목을 **미확인**으로 남긴 채 나머지 task를 진행한다. 체크박스를 완료로 표시하지 않는다.

- [ ] **Step 5: 계측 로그를 정리한다** (미수행 — 사용자 확인 필요)

원인이 확정됐다면 Step 1에서 넣은 `[review]` 로그 세 줄을 제거한다. 기존 `Self.logger.debug("reviewCounter = ...")`는 그대로 둔다.

- [ ] **Step 6: 정책 테스트가 그대로 통과하는지 확인한다** (미수행 — 사용자 확인 필요)

`presentReview()`는 private이고 StoreKit에 의존해 단위 테스트 대상이 아니다. 트리거 조건을 담당하는 정책 테스트가 깨지지 않았는지만 본다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/RequestReviewPolicyTests
```

Expected: PASS.

- [ ] **Step 7: 실기기에서 먹통이 해소됐는지 확인한다** (미수행 — 사용자 확인 필요)

Step 2와 같은 방법으로 재현하고 화면 녹화로 먹통 구간을 다시 잰다. 후보 2였다면 **먹통이 사라지지 않고 위치만 바뀐다** — 그 사실을 그대로 기록한다.

- [ ] **Step 8: 커밋** (미수행 — 사용자 확인 필요)

```bash
git add SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift
git commit -m "fix: #119 - 리뷰 요청 팝업 전 입력이 막히는 구간 축소"
```

원인 미확인으로 끝났다면 코드 커밋 없이 다음 task로 간다.

---

## Task 10: 전체 검증과 마무리

**Files:**
- Modify: `docs/superpowers/plans/2026-08-30-issue-119-landscape-labels-and-followups.md` (이 문서)

**Interfaces:**
- Consumes: Task 1~9의 결과
- Produces: 없음

- [x] **Step 1: 전체 테스트를 돌린다**

`-only-testing`과 code coverage 옵션을 반드시 비운 상태로 실행한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 PASS. 테스트 개수를 기록한다.

**실행 결과:** `iPhone 13 mini / iOS 16.0`에서 위 명령을 `-only-testing`·coverage 옵션 없이 그대로 실행했다. `** TEST SUCCEEDED **`, 실패 0건.
`xcrun xcresulttool get test-results summary --path <xcresult>` 기준 `totalTestCount: 531`, `passedTests: 531`, `failedTests: 0`, `skippedTests: 0` (동적 파라미터 테스트 10개가 26회로 펼쳐져 디바이스 단위 `passedTests`는 547). 결과 파일: `~/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.30_01-57-48-+0900.xcresult`.

- [x] **Step 2: 세 keyboard extension을 빌드한다**

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' || echo "FAILED: $scheme"
done
```

Expected: 세 scheme 모두 `BUILD SUCCEEDED`.

**실행 결과:** `HangeulKeyboard` `BUILD SUCCEEDED`, `EnglishKeyboard` `BUILD SUCCEEDED`, `HangeulEnglishKeyboard` `BUILD SUCCEEDED`. `-only-testing`·coverage 옵션은 세 빌드 모두 사용하지 않았다.

- [x] **Step 3: 빌드 부수 효과를 되돌린다**

```sh
git status --short
```

`SYKeyboard.xcodeproj/xcshareddata/xcschemes/*.xcscheme`이 보이면 diff를 확인한다.

```sh
git diff SYKeyboard.xcodeproj/xcshareddata/xcschemes/
```

`RemotePath`만 바뀌었다면 되돌린다.

```sh
git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/
```

`RemotePath` 외의 항목이 바뀌었다면 되돌리지 말고 사용자에게 알린다.

**실행 결과:** Step 1·2 실행 전후 `git status --short`가 모두 빈 출력이었다. `.xcscheme` 변경을 포함해 어떤 빌드 부수 효과도 발생하지 않았고, 따라서 되돌릴 대상이 없었다.

- [x] **Step 4: 실기기 확인 항목을 표로 채운다**

**아래 표의 모든 항목은 실제 기기/시뮬레이터 화면과 손 조작이 필요한 사람 관측 항목이다. 이 작업(자동화 에이전트)은 키보드를 실제로 띄우거나 화면을 볼 수 없으므로 어떤 행도 관측하지 않았다.** 모든 칸을 임의로 채우지 않고 `미확인 (사용자 확인 대기)`로 남긴다. 사용자가 실기기/시뮬레이터에서 직접 확인한 뒤 표를 채워야 한다.

| 항목 | 세로 | 가로 | 기기·OS |
|---|---|---|---|
| `!#1` 힌트 라벨 겹침 없음 (나랏글) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| `!#1` 힌트 라벨 겹침 없음 (천지인) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| `!#1` 힌트 라벨 겹침 없음 (두벌식/쿼티) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| `!#1` 힌트 라벨 겹침 없음 (기호/숫자) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| `한/A` 사선 각도 동일 | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| `한/A` 글자가 버튼 안에 있음 | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| 한 손 모드에서 위 두 항목 유지 | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| 회전 시 Auto Layout 경고 없음 | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) | 미확인 (사용자 확인 대기) |
| 글자 열 너비 슬라이더가 115에 도달 | 미확인 (사용자 확인 대기) | — | 미확인 (사용자 확인 대기) |
| 리뷰 팝업 전 터치 먹통 해소 | 미확인 (사용자 확인 대기) | — | 미확인 (사용자 확인 대기) |

- [x] **Step 5: 계획 문서에 실제 결과를 반영한다**

이 문서의 모든 체크박스를 실제 완료 상태로 맞추고, Task 9의 계측 표에 측정값을 적는다. 이슈 10번(범위 밖 저장 배율)은 아래 문단을 이 문서 하단에 남긴다.

```markdown
## 처리하지 않기로 한 항목

### 이슈 10. 개발 빌드에서 저장된 범위 밖 배율

사용자 결정으로 코드 변경 없이 종료한다.

- 미출시 기능이라 실사용자 영향이 없다.
- 레이아웃은 `KeyboardColumnWidthPolicy`가 `clamped()`로 자르므로 키보드 자체는 정상이다.
- 영향은 상한 1.20 개발 빌드로 테스트한 기기의 설정 화면에서 `116`~`120`이 보이는 것뿐이다.
- 해당 기기는 설정 화면에서 값을 한 번 저장하면 정상 범위로 돌아온다.
```

- [x] **Step 6: 문서 커밋**

```bash
git add docs/superpowers/plans/2026-08-30-issue-119-landscape-labels-and-followups.md
git commit -m "docs: #119 - 대응 계획 실행 결과와 실기기 확인 내역 반영"
```

- [ ] **Step 7: PR을 만든다** (미수행 — 사용자 결정)

제목: `Fix/#119 가로 모드 버튼 라벨 렌더링, 회전 중 제약 경고, 동시성 경고 정리 + #112 후속`

본문은 `.github/pull_request_template.md`를 따르고 다음을 포함한다.
- 연관 이슈: `#119`
- 작업 내용: 이슈 항목 번호별로 무엇을 어떻게 고쳤는지
- 검증: Step 1~4에서 실제로 실행한 명령과 결과, 테스트 개수, 실기기 확인 표
- **실행하지 못한 검증과 그 이유**: Task 2의 단위 테스트 부재 근거, Task 9가 미확인으로 끝났다면 그 사실, 이슈 10번을 처리하지 않은 근거

---

## Self-Review

**스펙 커버리지**

| 이슈 항목 | Task | 상태 |
|---|---|---|
| 1. 가로 힌트 라벨 겹침 | Task 3 | 높이 기준 축소 (사용자 결정) |
| 2. `한/A` 사선 각도 | Task 4 | 45° 고정 + 박스 클램프 (사용자 결정) |
| 3. 회전 중 제약 경고 | Task 2 | priority 999 |
| 4. 동시성 경고 2건 | Task 1 | 클로저 래핑 |
| 5. 리뷰 팝업 입력 지연 | Task 9 | 미구현 — 이번 PR 범위에서 제외(아래 `## 이번 PR에서 빠진 항목` 참고) |
| 6. 붕괴 회귀 테스트 진입점 | Task 5 | `updateNextKeyboardButton` 경유 |
| 7. modifier 폭 절대 단언 | Task 6 | 열 절대 폭 추가 |
| 8. 정책 루프 범위 | Task 7 | 범위 상수 기반 |
| 9. 슬라이더 왕복 테스트 | Task 8 | 변환 함수 추출 + 왕복 검증 |
| 10. 범위 밖 저장값 | Task 10 Step 5 | 코드 변경 없음, 근거 문서화 (사용자 결정) |
| 전체 테스트·3개 extension 빌드 | Task 10 | Step 1~2 |
| 세로·가로 실기기 확인 | Task 10 | Step 4 표 |

**타입 일관성 확인**

- `SwitchButton.subLabelFontSize(forKeyWidth:keyHeight:)` — Task 3에서 정의, Task 3 테스트에서만 호출.
- `LanguageSwitchButton.dividerHalfExtents(forKeySize:)` → `CGSize` — Task 4에서 정의, Task 4 테스트에서만 호출. (`dividerAngle`은 최종 코드 리뷰에서 45°-바닥 규칙으로 교체되며 삭제됨)
- `KeyboardLayoutFigure.letterColumnWidthPercent(fromMultiplier:)` / `letterColumnWidthMultiplier(fromPercent:)` → `Double` — Task 8에서 정의, 같은 task의 뷰와 테스트에서 호출.
- Task 6의 절대값은 배율에 따라 달라지므로 task 안의 표로 테스트별 기대값을 고정했다.

---

## 처리하지 않기로 한 항목

### 이슈 10. 개발 빌드에서 저장된 범위 밖 배율

사용자 결정으로 코드 변경 없이 종료한다.

- 미출시 기능이라 실사용자 영향이 없다.
- 레이아웃은 `KeyboardColumnWidthPolicy`가 `clamped()`로 자르므로 키보드 자체는 정상이다.
- 영향은 상한 1.20 개발 빌드로 테스트한 기기의 설정 화면에서 `116`~`120`이 보이는 것뿐이다.
- 해당 기기는 설정 화면에서 값을 한 번 저장하면 정상 범위로 돌아온다.

## 이번 PR에서 빠진 항목

### 이슈 5. 리뷰 팝업 전 입력 지연 (Task 9)

Task 9는 이번 PR 범위에서 구현하지 않았다.

- 원인 후보 2가지(의도적 1초 `Task.sleep` vs StoreKit 프롬프트 window의 지연)를 가르려면 실기기/시뮬레이터에서 세부 설정 화면에 29번 들어갔다 나오며 화면 녹화로 먹통 구간 길이를 재는, 사람 관측이 필요한 계측이 필수다. 자동화 에이전트가 대신할 수 없다.
- 적용 가능한 계측 코드, 재현 절차, 결정적 실험(1초 sleep 주석 처리 후 재측정), 원인별 분기 패치는 `.superpowers/sdd/2026-08-30-issue-119-landscape-labels-and-followups/task-9-measurement-guide.md`에 정리해 두었다.
- 측정값을 관측하지 못했으므로 이 문서와 이슈에 임의의 수치를 적지 않았다. Task 9의 체크박스는 모두 미완료로 남아 있다.
