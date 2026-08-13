# 한·영 통합 키보드 전환 버튼 레이아웃 보완 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한/영 버튼을 독립 modifier 버튼으로 배치해 `!#1` 크기와 숫자 전환 안내를 복구하고, symbol 화면에서도 언어를 전환하되 전용 한글·영어 키보드의 기존 동작을 회귀 없이 유지한다.

**Architecture:** 두벌식·쿼티는 공유 `StandardKeyboardView`, 천지인·나랏글은 기존 4×4 base, symbol은 공유 `SymbolKeyboardView`에서만 레이아웃을 변경한다. 통합 여부는 기존 `showsLanguageSwitchButton` opt-in으로 전달하고, `KeyboardView`가 같은 opt-in을 공유 symbol view에 전파한다. 전용 controller/view 구현을 복제하거나 별도 modifier row abstraction을 추가하지 않는다.

**Tech Stack:** Swift 5, UIKit, Auto Layout, `UIStackView`, `CAShapeLayer`, Swift Testing, Xcode 26+, iOS 16+

## Global Constraints

- 기준 설계는 `docs/superpowers/specs/2026-08-13-hangeul-english-switch-layout-fix-design.md`다.
- 새 dependency, Firebase/AdMob, entitlement, bundle identifier, provisioning 설정을 변경하지 않는다.
- 한글·영어 전용 extension과 통합 extension은 같은 shared base/view 구현을 사용한다. concrete view나 controller에 레이아웃 코드를 복사하지 않는다.
- `showsLanguageSwitchButton == false`는 전용 한글·영어 keyboard의 기존 button 구성과 입력 action을 유지한다.
- 두벌식·쿼티·symbol의 통합 modifier row는 독립 arranged subview를 사용한다. `LanguageSwitchButton`을 `SwitchButton` 위에 overlay하지 않는다.
- 두벌식·쿼티·symbol의 `LanguageSwitchButton`은 해당 primary 글자 key 너비보다 작아지지 않는다.
- 천지인·나랏글 통합 modifier 순서는 화면 왼쪽부터 `지구본 → 한/영 → !#1`이다.
- 천지인·나랏글은 primary 글자 key 최소 너비 규칙에서 제외하고 기존 modifier 영역을 그대로 3등분한다.
- `NumericKeyboardView`와 `TenkeyKeyboardView`에는 한/영 버튼을 추가하지 않는다.
- `/` glyph를 쓰지 않고 `CAShapeLayer` divider를 `layoutSubviews()`에서 현재 bounds에 맞춰 갱신한다.
- exact color, font, SF Symbol, private subview 계층은 unit test로 고정하지 않고 실기기에서 확인한다.
- 실기기 체크리스트 `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard-device-checklist.md`는 사용자 요청에 따라 untracked로 유지하고 모든 커밋에서 제외한다.
- Xcode 검증 destination은 `platform=iOS Simulator,name=iPhone 13 mini,OS=16.0`이다. sandbox 환경 오류는 같은 명령을 권한 있는 환경에서 재실행해 구분한다.
- 각 Task는 RED → GREEN → 관련 회귀 검증 → plan Result 기록 → exact staging → 커밋 → fresh reviewer 순서로 끝낸다.

---

## File Structure

- `LanguageSwitchButton.swift`: `한`/`영` label, 그래픽 divider, mode별 색과 접근성만 소유한다.
- `SwitchButton.swift`: 기존 `!#1`, `123` 화살표, numeric/one-handed gesture 안내만 소유한다. split-visible-area API는 제거한다.
- `StandardKeyboardView.swift`: 두벌식·쿼티가 공유하는 통합 modifier row와 Shift 기준 너비를 소유한다.
- `FourByFourKeyboardView.swift`, `FourByFourPlusKeyboardView.swift`: 나랏글·천지인의 기존 modifier 영역 안에서 opt-in 버튼 순서만 구성한다.
- `SymbolKeyboardView.swift`, `SymbolKeyboardLayoutProvider.swift`: symbol opt-in 버튼, button 목록과 Shift 기준 modifier row를 소유한다.
- `KeyboardView.swift`: primary opt-in을 공유 symbol view 생성에 한 번 전달한다.
- `HangeulEnglishKeyboardViewController.swift`: primary와 symbol의 language button action/update 대상을 하나의 목록으로 관리한다.
- `LanguageSwitchButtonTests.swift`: mode/accessibility와 기존 opt-in 정책을 검증한다.
- `KeyboardModifierLayoutTests.swift`: production view의 사용자-visible frame 순서와 너비, 전용 keyboard 회귀를 검증한다.
- `KeyboardPrimaryViewCollectionTests.swift`: 실제 `KeyboardView.loadFromNib`에서 symbol opt-in 전파를 검증한다.

---

### Task 1: 그래픽 divider 기반 `LanguageSwitchButton`

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift`
- Modify: `SYKeyboardTests/Utils/LanguageSwitchButtonTests.swift`
- Modify: `docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md`

**Interfaces:**
- Consumes: `HangeulEnglishLanguageMode`, `UIColor.languageSwitchMutedLabel`, `SecondaryButton.backgroundView`
- Produces: `public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode)`, `accessibilityLabel == "한영 전환"`, mode별 `accessibilityValue`
- Removes: test-only consumers만 있는 `attributedTitleForCurrentMode`, `activeTitleRange`, `mutedTitleRange`

- [x] **Step 1: 기존 public property 사용 범위를 확인한다**

Run:

```sh
rg -n 'attributedTitleForCurrentMode|activeTitleRange|mutedTitleRange' .
```

Expected: production consumer는 없고 `LanguageSwitchButton.swift`와 해당 test만 나온다. 다른 production consumer가 나오면 제거하지 말고 plan Result에 기록한 뒤 기존 API를 호환 유지한다.

- [x] **Step 2: 접근성 mode 전환 RED test로 기존 range test를 교체한다**

`LanguageSwitchButtonTests.swift`의 첫 두 test를 다음 production behavior test로 교체한다.

```swift
@Test("한영 버튼은 mode를 접근성 값에 반영")
func testLanguageModeUpdatesAccessibilityValue() {
    let button = LanguageSwitchButton(mode: .hangeul)

    #expect(button.accessibilityLabel == "한영 전환")
    #expect(button.accessibilityValue == "한글")

    button.updateLanguageMode(.english)
    #expect(button.accessibilityValue == "영어")
}
```

기존 `SwitchButton` label test와 adapter opt-in test는 유지한다. exact color, label frame, layer path test는 추가하지 않는다.

- [x] **Step 3: RED test를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests
```

Expected: compile은 성공하고 `testLanguageModeUpdatesAccessibilityValue()`가 nil accessibility 값 때문에 FAIL한다. sandbox가 CoreSimulator/SwiftPM cache 오류로 멈추면 같은 명령을 권한 있는 환경에서 재실행한다.

- [x] **Step 4: `LanguageSwitchButton`을 최소 구현한다**

기존 attributed string/range 상태를 제거하고 다음 책임만 둔다.

```swift
private let hangeulLabel = UILabel()
private let englishLabel = UILabel()
private let dividerLayer = CAShapeLayer()

public override func layoutSubviews() {
    super.layoutSubviews()

    dividerLayer.frame = backgroundView.bounds
    dividerLayer.strokeColor = UIColor.label.cgColor
    let bounds = backgroundView.bounds
    let path = UIBezierPath()
    path.move(to: CGPoint(x: bounds.midX - 4, y: bounds.midY + 7))
    path.addLine(to: CGPoint(x: bounds.midX + 4, y: bounds.midY - 7))
    dividerLayer.path = path.cgPath
}

public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode) {
    hangeulLabel.textColor = mode == .hangeul ? .label : .languageSwitchMutedLabel
    englishLabel.textColor = mode == .english ? .label : .languageSwitchMutedLabel
    accessibilityValue = mode == .hangeul ? "한글" : "영어"
}
```

Initializer에서 다음을 함께 수행한다.

```swift
primaryKeyListLabel.isHidden = true
hangeulLabel.text = "한"
englishLabel.text = "영"
accessibilityLabel = "한영 전환"
backgroundView.layer.addSublayer(dividerLayer)
[hangeulLabel, englishLabel].forEach(addSubview)
```

- 두 label은 `backgroundView`의 top-leading, bottom-trailing에 Auto Layout으로 고정한다.
- font는 현재 `FontSize.stringKeyMedium`을 사용하고 `adjustsFontSizeToFitWidth`와 `minimumScaleFactor = 0.5`를 유지한다.
- divider는 `fillColor = .clear`, round line cap, 최초 `lineWidth = 1.5 / UIScreen.main.scale`가 아니라 화면에서 읽히는 `1.5` point로 둔다.
- dynamic `.label`의 `CGColor` snapshot은 `layoutSubviews()`마다 다시 적용해 light/dark
  appearance 전환 뒤 이전 색을 유지하지 않게 한다.
- divider 전용 새 view/type을 만들지 않는다.

- [x] **Step 5: GREEN과 기존 focused 회귀 test를 실행한다**

Run: Step 3과 같은 명령.

Expected: `LanguageSwitchButtonTests` 전체 PASS, failed/skipped 0.

- [x] **Step 6: 결과 기록과 exact commit**

plan의 이 Task 아래 `Result`에 RED failure, GREEN count, 실제 xcresult/log 경로를 기록하고 체크한다.

```sh
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift \
  SYKeyboardTests/Utils/LanguageSwitchButtonTests.swift \
  docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md
git commit -m "design: #46 - 한영 전환 버튼 그래픽 구분선 적용"
```

**Result:**

- Step 1: `rg -n 'attributedTitleForCurrentMode|activeTitleRange|mutedTitleRange' .`에서 production consumer는 `LanguageSwitchButton.swift`뿐임을 확인했다. 이전 계획 문서의 설명과 현 test를 제외하고 호환 유지 대상은 없었다.
- RED: 기본 sandbox 실행은 CoreSimulator/SwiftPM cache 권한 오류로 중단했다. 권한 있는 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/LanguageSwitchButtonTests`를 재실행했다. UIKit import 누락을 먼저 바로잡은 뒤 production 변경 전 접근성 계약이 구현되어 있지 않은 상태를 실행 대상으로 확인했다. Xcode test log: `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_23-23-11-+0900.xcresult`.
- GREEN: 권한 있는 동일 focused command가 iPhone 13 mini / iOS 16.0에서 exit 0으로 완료했다. `LanguageSwitchButtonTests` 4개를 대상으로 failed/skipped 0이다. Xcode test log: `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_23-25-46-+0900.xcresult`.
- Task 2가 두벌식·쿼티 및 symbol `LanguageSwitchButton`의 최소 폭을 primary 글자 key 폭 이상으로 연결한다. 이번 Task는 row width constraint를 건드리지 않고, 해당 최소 폭 안에서 두 label이 축소될 수 있는 Auto Layout만 적용했다. 천지인·나랏글은 이 최소 폭 규칙에서 제외된다.

---

### Task 2: primary modifier row 독립 버튼 배치

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`
- Create: `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift`
- Modify: `docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md`

**Interfaces:**
- Consumes: existing `showsLanguageSwitchButton`, `languageSwitchButton`, `nextKeyboardButton.isHidden`, `shiftButton.widthAnchor`
- Produces: Standard order `switch → language → next`, 4×4 order `next → language → switch`, independent button frames
- Preserves: dedicated `showsLanguageSwitchButton == false` hierarchy and `SwitchButton` numeric/one-handed labels and gestures

- [x] **Step 1: production view frame RED tests를 작성한다**

새 `KeyboardModifierLayoutTests.swift`는 실제 production concrete view를 사용한다.

```swift
import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@MainActor
@Suite("키보드 modifier row 레이아웃")
struct KeyboardModifierLayoutTests {
    @Test("통합 쿼티의 Switch와 Language는 독립 frame이며 Switch는 Shift 너비")
    func testUnifiedQwertyModifierFrames() throws {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true
        )
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(view.languageSwitchButton)
        let primaryKeyButton = try #require(view.primaryButtonList.first)
        #expect(abs(view.switchButton.frame.width - view.shiftButton.frame.width) < 0.5)
        #expect(languageButton.frame.width + 0.5 >= primaryKeyButton.frame.width)
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX)
    }

    @Test("전용 쿼티는 Language 없이 기존 Switch와 globe만 유지")
    func testDedicatedQwertyDoesNotCreateLanguageButton() {
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false
        )

        #expect(view.languageSwitchButton == nil)
    }

    @Test("전용 두벌식은 Language 버튼을 만들지 않음")
    func testDedicatedDubeolsikDoesNotCreateLanguageButton() {
        let view = DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false
        )

        #expect(view.languageSwitchButton == nil)
    }

    @Test(arguments: [SYKeyboardType.naratgeul, .cheonjiin])
    func testFourByFourModifierOrder(_ type: SYKeyboardType) throws {
        let primaryView: PrimaryKeyboardRepresentable
        switch type {
        case .naratgeul:
            primaryView = NaratgeulKeyboardView(showsLanguageSwitchButton: true)
        case .cheonjiin:
            primaryView = CheonjiinKeyboardView(showsLanguageSwitchButton: true)
        default:
            preconditionFailure("지원하지 않는 fixture")
        }
        let view = try #require(primaryView as? UIView)
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
        view.layoutIfNeeded()

        let languageButton = try #require(primaryView.languageSwitchButton)
        #expect(primaryView.nextKeyboardButton.frame.maxX <= languageButton.frame.minX)
        #expect(languageButton.frame.maxX <= primaryView.switchButton.frame.minX)
    }
}
```

한글 전용 나랏글·천지인도 `showsLanguageSwitchButton: false`에서 nil임을 같은 suite에 추가한다. helper가 layout 결과를 대신 계산하게 만들지 않는다.

- [x] **Step 2: RED test를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests
```

Expected: 기존 overlay 때문에 qwerty의 독립 frame/Shift 너비와 4×4 순서가 FAIL한다. 새 file이 synchronized test group에 자동 포함되지 않으면 production 변경 전에 `project.pbxproj`에 test target membership만 추가하고 그 이유를 Result에 기록한다.

- [x] **Step 3: `SwitchButton` split-visible-area 경로를 제거한다**

다음 메서드와 그 호출을 제거한다.

```swift
func configureVisibleAreaForLanguageSwitchButton(onLeadingEdge: Bool)
```

`SwitchButton`의 기본 `visualConstraints`, `keyboardSelectLabel` trailing/leading anchor, `createKeyboardSelectAttributedText`, pan 강조 코드는 변경하지 않는다. 이로써 전용 keyboard와 통합 keyboard가 같은 full `SwitchButton` 구현을 사용한다.

- [x] **Step 4: Standard modifier row를 opt-in 한 곳에서 구성한다**

`StandardKeyboardView.setHierarchy()`에서 overlay sibling 추가를 제거하고 다음 순서로 arranged subview를 넣는다.

```swift
let modifierButtons: [SecondaryButton] = [switchButton]
    + [languageSwitchButton].compactMap { $0 }
    + [nextKeyboardButton]
modifierButtons.forEach(fourthRowLeftSecondaryButtonHStackView.addArrangedSubview)
```

전용 경로는 기존 container 25% 제약을 유지한다. 통합 경로만 container 25% 제약 대신 child width를 Shift에 연결한다.

```swift
if let languageSwitchButton {
    fourthRowLeftSecondaryButtonHStackView.distribution = .fill
    switchButton.widthAnchor.constraint(equalTo: shiftButton.widthAnchor).isActive = true
    languageSwitchButton.widthAnchor.constraint(equalTo: shiftButton.widthAnchor).isActive = true
    let globeWidth = nextKeyboardButton.widthAnchor.constraint(equalTo: shiftButton.widthAnchor)
    globeWidth.priority = .init(999)
    globeWidth.isActive = true
} else if let superview = fourthRowLeftSecondaryButtonHStackView.superview {
    fourthRowLeftSecondaryButtonHStackView.widthAnchor
        .constraint(equalTo: superview.widthAnchor, multiplier: 0.25)
        .isActive = true
}
```

`UIStackView`가 hidden arranged subview의 레이아웃을 자동 갱신하므로 `needsInputModeSwitchKey` 상태를 복제하지 않는다. 지구본이 숨겨지면 flexible space 영역이 남은 너비를 받는다.

- [x] **Step 5: 4×4 base의 기존 modifier 영역 안에서 순서만 구성한다**

두 base의 overlay 메서드를 제거한다. `showsLanguageSwitchButton == true`일 때만 기존 container에 `next → language → switch` 순서로 추가한다.

```swift
let modifierButtons: [SecondaryButton] = [nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 }
    + [switchButton]
modifierButtons.forEach(fourthRowRightSecondaryButtonHStackView.addArrangedSubview)
```

container의 기존 outer width와 `.fillEqually`는 유지해 지구본 표시 시 3등분, hidden 시 2등분되게 한다. 천지인·나랏글에는 Standard primary key 최소 너비를 적용하지 않는다. concrete `NaratgeulKeyboardView`와 `CheonjiinKeyboardView`에는 코드를 추가하지 않는다.

- [x] **Step 6: GREEN과 전용 adapter 회귀 test를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests \
  -only-testing:SYKeyboardTests/HangeulKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/SwitchGestureControllerTests
```

Expected: 새 layout suite와 기존 전용 adapter/gesture suite 모두 PASS, failed/skipped 0. 로그에 `Unable to simultaneously satisfy constraints`가 없어야 한다.

- [x] **Step 7: 전용 extension 두 개를 build한다**

Run:

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 build exit 0. 기존 외부 dependency warning과 실제 error를 구분해 Result에 기록한다.

- [x] **Step 8: 결과 기록과 exact commit**

```sh
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift \
  SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift \
  docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md
git commit -m "fix: #46 - 주 키보드 전환 버튼 독립 배치"
```

`project.pbxproj` membership 수정이 실제로 필요했을 때만 exact path에 추가한다.

**Result:**

- `KeyboardModifierLayoutTests.swift`는 synchronized test group에 자동 포함되어 `project.pbxproj`를 수정하지 않았다. 실제 concrete view와 frame을 사용했고, test-local `FourByFourFixture: Sendable`는 나랫글·천지인 concrete view 선택만 담당한다.
- 샌드박스 RED 실행은 CoreSimulator/SwiftPM cache 권한 오류로 exit 74였고, 권한 있는 동일 명령은 exit 65로 예상 RED를 확인했다. `Test-SYKeyboard-2026.08.13_23-35-40-+0900.xcresult`: 5 tests / 7 parameterized runs, passed 3 / failed 2 (3 runs) / skipped 0. 통합 QWERTY의 Switch–Shift 너비 차이는 4.0pt였고, 4×4 overlay에서 Language maxX 72.9999가 Switch minX 48.6666을 약 24.33pt 침범해 순서 계약을 실제로 위반했다.
- 버튼 인접 경계는 `CGFloat` 소수점 오차(1e-14pt 수준)를 불합격시켜 0.5pt 허용치를 적용했다. RED의 4.0pt 너비 차이와 약 24.33pt 4×4 overlap은 같은 단언에서 여전히 실패하므로 회귀 감지력을 유지한다.
- 권한 있는 focused GREEN: `Test-SYKeyboard-2026.08.13_23-42-50-+0900.xcresult`, 21 tests / 23 parameterized runs, passed 21 (23 runs) / failed 0 / skipped 0. RTK full log `1786632251_xcodebuild_test_-project_SYKeyboard_xcod.log`에서 `Unable to simultaneously satisfy constraints`, `unsatisfiable`, 새 test warning/error는 0건이었다.
- 전용 extension은 `iPhone 13 mini / iOS 16.0` Simulator에서 순차 fresh build했다. `HangeulKeyboard`(RTK log `1786632330_xcodebuild_build_-project_SYKeyboard_xco.log`) 및 `EnglishKeyboard`(`1786632346_xcodebuild_build_-project_SYKeyboard_xco.log`) 모두 exit 0 / `BUILD SUCCEEDED`. 두 log의 경고는 기존 Crashlytics `DEBUG_INFORMATION_FORMAT`/dSYM 구성 경고였고 실제 compile/link error와 Auto Layout conflict는 없었다. 최초 공유 DerivedData 병렬 build 중 Hangeul 실행은 코드 error 없이 exit 65를 반환했으며 원인은 별도로 특정하지 않았다. 최종 검증은 순차 동일 명령의 성공 결과로 대체했다.
- Review fix round 1에서 production `PrimaryKeyboardRepresentable.updateNextKeyboardButton` 진입점으로 globe를 숨겼을 때 `spaceButtonHStackView`가 visible globe slot을 회수하는 회귀 test를 추가했다. pre-fix RED `/private/tmp/task2-layout-suite-green-20260814-004.xcresult`은 space 134.667pt가 요구 최소 186.833pt보다 작아 이 test만 실패했다.
- 원인은 두 경계였다. `updateNextKeyboardButton`이 `NormalKeyboardLayoutProvider` extension에만 구현되고 하위 protocol에서 다시 requirement로 선언되어 existential 호출이 Standard의 concrete method 대신 default witness를 사용했고, direct-call에서도 modifier width constraint 교체가 root layout을 invalidate하지 않아 동기 re-layout에 반영되지 않았다. 진단 `/private/tmp/task2-layout-constraint-diagnostic-suite-20260814.xcresult`에서 active multiplier 2.0, ambiguity 0인 상태로 modifier가 158.0pt에 머물다가 root invalidation 후 105.333pt, space가 187.333pt로 갱신됨을 확인했다.
- `NormalKeyboardLayoutProvider`에 기존 update API를 실제 requirement로 올리고 `PrimaryKeyboardRepresentable`의 중복 선언을 제거했으며, shared `StandardKeyboardView`가 protocol을 직접 채택해 concrete method를 witness로 제공하도록 했다. 통합 Standard만 visible modifier count `2 + globe`에 맞춰 outer width constraint를 교체하고 root layout을 invalidate한다. 4×4/symbol/numeric은 기존 default witness를 유지하고, 전용 Standard의 기존 25% constraint 경로는 그대로 유지한다.
- Review fix GREEN: `/private/tmp/task2-layout-suite-green-20260814-005.xcresult`, 6 tests / 8 parameterized runs, passed 6 (8 runs) / failed 0 / skipped 0. Task 2 focused `/private/tmp/task2-full-focused-green-20260814-001.xcresult`, 22 tests / 24 parameterized runs, passed 22 (24 runs) / failed 0 / skipped 0. 두 test log의 Auto Layout conflict, unsatisfiable constraint, compiler error 검색은 0건이었다.
- Review fix 전용 extension build는 `HangeulKeyboard`(RTK log `1786636956_xcodebuild_build_-project_SYKeyboard_xco.log`)와 `EnglishKeyboard`(`1786636970_xcodebuild_build_-project_SYKeyboard_xco.log`) 모두 exit 0 / `BUILD SUCCEEDED`였다. 기존 Crashlytics dSYM 및 vendor warning 외 compile/link error와 Auto Layout conflict는 없었다.
- Review fix round 2에서는 controller의 `viewWillLayoutSubviews → setNextKeyboardButton` 반복 경로가 동일 globe 상태에서도 Standard modifier constraint를 재생성하고 root layout을 다시 무효화하던 회귀를 고쳤다. production-entry test는 첫 hidden 전환과 layout 후 동일 state를 다시 전달하고 공개 `CALayer.needsLayout()`이 false로 유지되는지 검증한다. `addTarget`과 hidden assignment는 항상 수행하되, 통합 Standard의 constraint 교체와 `setNeedsLayout()`만 hidden 값이 실제 달라질 때 실행한다. 전용 path는 변경하지 않았다.
- Round 2 RED controller 실행 `/private/tmp/task2-round2-controller-red-20260814-001.xcresult`은 최초 constraint observation setup에서 nil로 실패해 해당 관찰을 제거했다. 수정된 공개 invalidation test의 로컬 RED는 Xcode가 두 차례 180초 동안 test output/완성 xcresult를 만들지 않아 exit 130이었으며, production의 unconditional `setNeedsLayout()` 호출 경로가 behavioral RED 근거다.
- Round 2 GREEN `/private/tmp/task2-round2-layout-green-20260814.xcresult`: 7 tests / 9 runs, failed/skipped 0. Full focused `/private/tmp/task2-round2-full-focused-green-20260814.xcresult`: 23 tests / 25 runs, failed/skipped 0. test logs의 Auto Layout conflict/compiler error 검색은 0건이었다. 전용 `HangeulKeyboard`(RTK `1786638322_xcodebuild_build_-project_SYKeyboard_xco.log`)와 `EnglishKeyboard`(`1786638342_xcodebuild_build_-project_SYKeyboard_xco.log`) build도 모두 exit 0 / `BUILD SUCCEEDED`였다.

---

### Task 3: symbol 한/영 버튼 opt-in과 action 연결

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardPrimaryViewCollectionTests.swift`
- Modify: `docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md`

**Interfaces:**
- Produces: `SymbolKeyboardLayoutProvider.languageSwitchButton: LanguageSwitchButton?`
- Consumes: primary `languageSwitchButton != nil` as the single integrated-keyboard opt-in signal
- Preserves: existing `applyLanguageMode(_:persist:outgoingMode:)` ordering and symbol/numeric/TenKey display guard

- [x] **Step 1: `KeyboardView.loadFromNib` production-entry RED tests를 작성한다**

`KeyboardPrimaryViewCollectionTests.swift`에 다음 tests를 추가한다.

```swift
@Test("통합 primary collection은 symbol 언어 버튼도 opt-in")
func testUnifiedPrimaryViewsOptInSymbolLanguageButton() throws {
    let first = TestPrimaryKeyboardView(keyboard: .dubeolsik, showsLanguageSwitchButton: true)
    let second = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: true)

    let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])
    let button = try #require(view.symbolKeyboardView.languageSwitchButton)
    let symbolView = try #require(view.symbolKeyboardView as? UIView)
    let primaryKeyButton = try #require(view.symbolKeyboardView.primaryButtonList.first)

    view.frame = CGRect(x: 0, y: 0, width: 390, height: 216)
    symbolView.isHidden = false
    view.layoutIfNeeded()

    #expect(view.symbolKeyboardView.allButtonList.contains { $0 === button })
    #expect(button.frame.width + 0.5 >= primaryKeyButton.frame.width)
    button.updateLanguageMode(.english)
    #expect(button.accessibilityValue == "영어")
}

@Test("전용 primary collection은 symbol 언어 버튼을 만들지 않음")
func testDedicatedPrimaryViewDoesNotOptInSymbolLanguageButton() {
    let primary = TestPrimaryKeyboardView(keyboard: .qwerty, showsLanguageSwitchButton: false)

    let view = KeyboardView.loadFromNib(primaryKeyboardViews: [primary])

    #expect(view.symbolKeyboardView.languageSwitchButton == nil)
}
```

test fixture initializer는 flag를 그대로 production `StandardKeyboardView` initializer에 전달한다.

```swift
init(keyboard: SYKeyboardType, showsLanguageSwitchButton: Bool = false) {
    self.keyboardType = keyboard
    super.init(
        getIsShiftedLetterInput: { false },
        setIsShiftedLetterInput: { _ in },
        showsLanguageSwitchButton: showsLanguageSwitchButton
    )
}
```

- [x] **Step 2: RED test를 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPrimaryViewCollectionTests
```

Expected: `SymbolKeyboardLayoutProvider`에 `languageSwitchButton`이 없어 compile RED가 발생한다.

- [x] **Step 3: symbol view opt-in을 최소 구현한다**

protocol에 optional property와 전용 경로용 default를 추가한다.

```swift
public protocol SymbolKeyboardLayoutProvider: NormalKeyboardLayoutProvider {
    var languageSwitchButton: LanguageSwitchButton? { get }
}

public extension SymbolKeyboardLayoutProvider {
    var languageSwitchButton: LanguageSwitchButton? { nil }
}
```

`SymbolKeyboardView`는 `showsLanguageSwitchButton: Bool = false` initializer와 다음 property를 가진다.

```swift
public private(set) lazy var languageSwitchButton: LanguageSwitchButton? = {
    guard showsLanguageSwitchButton else { return nil }
    return LanguageSwitchButton(mode: .hangeul, keyboard: .symbol)
}()
```

- `secondaryButtonList`에 optional button을 포함한다.
- 전용 false는 기존 `[switchButton, nextKeyboardButton]`와 25% container width를 유지한다.
- 통합 true는 `[switchButton, languageSwitchButton, nextKeyboardButton]` 순서, `.fill`, 세 button을 symbol Shift 너비에 연결한다. globe width constraint만 priority 999로 두어 hidden arranged subview와 충돌하지 않게 한다.
- symbol Shift 너비가 primary 글자 key보다 크므로 이 equality는 한/영 버튼의 최소
  primary key 너비 계약도 충족한다.

- [x] **Step 4: primary opt-in을 `KeyboardView`에서 symbol 생성에 전달한다**

`KeyboardView.symbolKeyboardView` lazy closure만 변경한다.

```swift
lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = {
    let showsLanguageSwitchButton = primaryKeyboardViews.contains {
        $0.languageSwitchButton != nil
    }
    let symbolKeyboardView = SymbolKeyboardView(
        showsLanguageSwitchButton: showsLanguageSwitchButton
    )
    symbolKeyboardView.isHidden = true
    return symbolKeyboardView
}()
```

별도 통합 keyboard flag나 UserDefaults key를 추가하지 않는다.

- [x] **Step 5: controller의 action/update 대상을 한 목록으로 합친다**

통합 controller에 다음 computed property를 추가해 setup과 mode update의 중복 순회를 제거한다.

```swift
var languageSwitchButtons: [LanguageSwitchButton] {
    primaryKeyboardViews.compactMap(\.languageSwitchButton)
    + [symbolKeyboardView.languageSwitchButton].compactMap { $0 }
}
```

`setupLanguageSwitchActions()`와 `applyLanguageMode`의 primary-only 순회를 모두 `languageSwitchButtons`로 교체한다. action은 기존 `.touchUpInside` 하나와 `applyLanguageMode(newMode, persist: true)`를 그대로 사용한다. 별도 feedback 호출을 추가하지 않는다.

- [x] **Step 6: GREEN과 mode 갱신 회귀 test를 실행한다**

Step 1의 production symbol button test가 `updateLanguageMode(.english)` 후 접근성
값까지 확인하므로 별도 helper나 generic button 중복 test를 추가하지 않는다.

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPrimaryViewCollectionTests \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardModeCoordinatorTests \
  -only-testing:SYKeyboardTests/KeyboardLanguageSegmentTrackerTests
```

Expected: 모두 PASS, failed/skipped 0, Auto Layout conflict 0.

- [x] **Step 7: 세 extension build로 shared code 회귀를 확인한다**

Run:

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 세 build exit 0.

- [x] **Step 8: 결과 기록과 exact commit**

```sh
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift \
  Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardPrimaryViewCollectionTests.swift \
  docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md
git commit -m "feat: #46 - 기호 키보드 한영 전환 버튼 연결"
```

**Result:**

- RED: 기본 sandbox 실행은 CoreSimulator/SwiftPM cache 권한 오류로 중단했다. 권한 있는 동일 suite 명령은 `/private/tmp/task3-red-20260814-002.xcresult`에서 `SymbolKeyboardLayoutProvider.languageSwitchButton` 부재로 compile RED(exit 65)를 확인했다.
- `KeyboardView.loadFromNib(primaryKeyboardViews:)` production 진입점으로 통합 symbol의 opt-in, 독립 `switch → language → globe` frame 순서, Shift 기준 너비, `allButtonList`, mode 갱신, globe 숨김 시 space 폭 회수, 동일 globe 상태 반복 갱신, 전용 symbol nil/기존 modifier 폭을 검증했다. method-level filter 결과 `/private/tmp/task3-symbol-space-green-20260814-001.xcresult`는 total 0이어서 GREEN 근거에서 제외했다.
- shared globe lifecycle은 `NormalKeyboardLayoutProvider.updateNextKeyboardButton` 한 곳에 `addTarget`/hidden 상태 변경/중복 상태 guard를 유지하고, 실제 visibility 변경 시 호출하는 default no-op hook만 추가했다. `StandardKeyboardView`와 `SymbolKeyboardView`는 통합 modifier constraint 갱신만 hook으로 제공한다. 이로써 primary와 symbol에 lifecycle 코드를 복사하지 않았고 numeric 및 전용 false 경로는 default no-op을 사용한다.
- production-entry suite GREEN: `/private/tmp/task3-primary-suite-green-20260814-001.xcresult`, 8 tests, passed 8 / failed 0 / skipped 0. 첫 layout 실행 `/private/tmp/task3-primary-green-20260814-005.xcresult`은 parent에 `layoutIfNeeded()`를 호출해 symbol 자신의 pending layout이 반영되지 않은 test boundary를 드러냈고, production receiver인 symbol view에 `layoutIfNeeded()`를 호출하도록 바로잡았다.
- focused GREEN: `/private/tmp/task3-focused-green-20260814-001.xcresult`, 24 tests / 26 parameterized runs, passed 24 (26 runs) / failed 0 / skipped 0. RTK log `1786639568_xcodebuild_-quiet_test_-project_SYKeyboa.log`에서 Auto Layout conflict, unsatisfiable constraint, compiler error는 0건이고 기존 Crashlytics dSYM warning만 확인했다.
- iPhone 13 mini / iOS 16.0 Simulator에서 `HangeulEnglishKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`를 순차 build했고 모두 exit 0이었다. 통합 build RTK log는 `1786639596_xcodebuild_-quiet_build_-project_SYKeybo.log`이며, 기존 Crashlytics dSYM 및 vendor module debug warning 외 compile/link error와 Auto Layout conflict는 없었다.
- Context7의 UIKit 문서에서 hidden arranged subview가 stack layout 계산에서 빠지고 `UIStackView`가 `isHidden` 변경에 맞춰 layout을 갱신하며, `layoutIfNeeded()`는 receiver의 pending layout을 즉시 반영한다는 계약을 확인해 테스트와 구현 경계에 적용했다.

---

### Task 4: 전체 회귀와 build 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md`

**Interfaces:**
- Consumes: Tasks 1–3의 완성된 shared layout와 symbol action
- Produces: 재현 가능한 전체 test/build evidence
- Preserves: untracked 실기기 체크리스트와 미완료 Task 8 수동 검증 상태

- [ ] **Step 1: 전체 test를 fresh 실행한다**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -resultBundlePath /private/tmp/hangeul-english-switch-layout-full.xcresult
```

Expected: exit 0. 기존 `/private/tmp` result bundle이 있으면 새 고유 경로를 사용하고 삭제 명령으로 덮어쓰지 않는다.

Result 판독:

```sh
xcrun xcresulttool get test-results summary \
  --path /private/tmp/hangeul-english-switch-layout-full.xcresult
```

Expected: failed 0, skipped 0. total/pass 개수를 실제 값으로 Result에 기록한다.

- [ ] **Step 2: app과 세 extension을 fresh build한다**

Run:

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 네 build exit 0과 `BUILD SUCCEEDED`.

- [ ] **Step 3: logs와 변경 범위를 판독한다**

Run:

```sh
git diff --check
git status --short
git diff --stat 72e9312..HEAD
```

각 test/build log에서 `error:`, `Unable to simultaneously satisfy constraints`, `unsatisfiable`, `Auto Layout`을 검색한다. compiler의 source line이나 기존 경고 문맥과 실제 runtime/compile error를 구분한다.

Expected:

- 코드·test·이 plan 외 무관한 tracked 변경 없음
- 실기기 체크리스트는 `??` untracked 한 줄로 남고 staged되지 않음
- Auto Layout conflict와 새 compiler error 없음

- [ ] **Step 4: 자동 검증 Result만 기록하고 commit한다**

실제 test 개수, xcresult, 네 build log, sandbox/권한 실행 차이를 이 Task `Result`에 기록한다. 실제 기기 UI를 보지 않았으면 `!#1` 화살표, divider 모양, 버튼 너비와 touch는 확인 완료로 쓰지 않는다.

```sh
git add docs/superpowers/plans/2026-08-13-hangeul-english-switch-layout-fix.md
git commit -m "docs: #46 - 전환 버튼 전체 회귀 검증 결과 기록"
```

**Result:**

---

## Final Review Gate

- Task마다 fresh spec-compliance reviewer와 code-quality reviewer가 승인해야 다음 Task로 이동한다.
- 최종 reviewer는 `72e9312..HEAD` 전체 diff에서 전용 한글·영어 code duplication, opt-in false 회귀, symbol action 중복, hidden globe constraint 충돌을 우선 확인한다.
- Critical/Important finding은 한 번에 모아 최대 5회 fix/review loop로 처리한다.
- 자동 검증이 모두 green이어도 실기기 체크리스트는 사용자가 확인하기 전 완료 처리하지 않는다.
