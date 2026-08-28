# 4x4 계열 키보드 글자 열 너비 조정 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 나랏글·천지인·숫자 키패드의 좌측 3열(글자·숫자)과 우측 1열(기능)의 너비 비율을 사용자가 슬라이더로 조정할 수 있게 한다. 기본값은 현재의 균등 분할이다.

**Architecture:** `KeyboardColumnWidthPolicy`(순수 계산)가 배율에서 열 비율을 산출하고, `FourColumnWidthLayoutController`(Auto Layout)가 세 뷰의 행 스택 `distribution`을 `.fill`로 바꾼 뒤 "1~3열 등폭 + 4열 비율" 제약을 설치·갱신한다. 배율은 App Group `UserDefaults`에 저장되고, 설정 화면 미리보기는 `NormalKeyboardLayoutProvider`의 새 메서드를 통해 실시간으로 갱신한다.

**Tech Stack:** Swift 5, UIKit(Auto Layout, `UIStackView`), SwiftUI(`@AppStorage`, `Slider`), Swift Testing, Firebase Analytics

**Spec:** `docs/superpowers/specs/2026-08-29-four-by-four-letter-column-width-design.md`

## Global Constraints

- 작업 브랜치는 `feat/#112-letter-column-width`다. 이미 생성되어 있다.
- 기본값 `1.0`에서 모든 키보드의 시각적 결과가 현재와 동일해야 한다.
- 배율 범위는 `1.0...1.2`, 슬라이더 step은 `0.01`, 표시는 `100`~`120`이다.
- 적용 대상은 `FourByFourKeyboardView`, `FourByFourPlusKeyboardView`, `NumericKeyboardView` 세 뷰뿐이다. `StandardKeyboardView`, `SymbolKeyboardView`, `TenkeyKeyboardView`는 건드리지 않는다.
- 하단 스페이스 배치에서도 **위치 기준**(1~3열 확대 / 4열 축소)으로 일괄 적용한다. 행마다 의미에 따라 다르게 적용하지 않는다.
- 입력 로직, 조합, 삭제, 커서 이동, 스페이스/리턴 동작, 버튼 이벤트 타이밍은 변경하지 않는다.
- **`Modules/` 아래에 새 `.swift` 파일을 추가하면 `SYKeyboard.xcodeproj/project.pbxproj`의 두 `membershipExceptions` 블록에 알파벳 순으로 등록해야 한다.** 등록하지 않으면 같은 모듈 안에서도 `cannot find ... in scope`로 컴파일이 실패한다.
  - `Exceptions for "Modules" folder in "SYKeyboard" target` (파일 상단 블록)
  - `Exceptions for "Modules" folder in "SYKeyboardCore" target` (아래 블록)
  - `SYKeyboardTests/`와 `SYKeyboard/` 아래의 새 `.swift` 파일은 등록이 필요 없다.
- 커밋 메시지는 `type: #112 - subject` 형식이다. subject는 한국어 명사/서술구이며 마침표를 붙이지 않는다.
- **각 Task의 체크박스는 해당 Task의 검증이 실제로 끝난 직후에만 체크한다.** Task마다 커밋을 하나 남기고, 실행한 명령과 결과(테스트 개수, 통과 여부)를 이 문서의 Task 끝 "결과" 줄에 기록한다. 여러 Task를 한 커밋으로 합치지 않는다.
- 기본 검증 대상은 `iPhone 13 mini / iOS 16.0`이다. 로컬에 해당 런타임이 없으면 가장 가까운 iOS 16+ 시뮬레이터로 바꾸고, 실제 사용한 기기명과 OS 버전을 결과에 적는다.
- `xcodebuild` 실패가 `CoreSimulatorService connection became invalid`, `Operation not permitted`, `error opening ... ModuleCache`, `.xcresult` 권한 오류 같은 환경 문제면 **코드 실패로 기록하지 않는다.** 사용자에게 프롬프트에서 `! <명령>`으로 직접 실행하도록 요청한다.

---

## File Structure

**Create:**

| 파일 | 책임 |
| --- | --- |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift` | 배율 → 열 비율 순수 계산. UI 의존 없음 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Frames/FourColumnWidthLayoutController.swift` | 4열 격자 행에 폭 제약 설치·갱신. 세 뷰가 공유 |
| `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift` | 슬라이더 설정 화면 |
| `SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift` | 정책 계산 검증 |
| `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift` | 컨트롤러와 세 뷰의 실제 프레임 폭 검증 |

**Modify:**

| 파일 | 변경 |
| --- | --- |
| `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift` | 열 개수·배율 범위·한영 전환 버튼 몫 상수 추가 |
| `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` | 키 추가 |
| `Modules/SYKeyboardCore/Storage/DefaultValues.swift` | 기본값 추가 |
| `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` | 프로퍼티 추가 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift` | 갱신 메서드 선언 + 기본 no-op |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift` | 컨트롤러 설치, 갱신 메서드 구현 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift` | 동일 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift` | 동일 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 미리보기 갱신 메서드 추가 |
| `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewKeyboardView.swift` | 바인딩 추가 |
| `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewHangeulKeyboardViewController.swift` | 바인딩 전달 |
| `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewEnglishKeyboardViewController.swift` | 바인딩 전달 |
| `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift` | 호출부 갱신 |
| `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift` | 호출부 갱신 |
| `SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift` | 진입점 추가 |
| `SYKeyboard/Resources/Localizable.xcstrings` | 라벨 문자열 추가 |
| `SYKeyboardTests/Storage/UserDefaultsContractTests.swift` | 키 계약 테스트 추가 |
| `SYKeyboard.xcodeproj/project.pbxproj` | 새 `Modules/` 파일 2개 등록 |

---

## Task 1: 계산 정책과 레이아웃 수치

배율에서 열 비율을 계산하는 순수 타입을 만든다. 이후 모든 Task가 이 값을 쓴다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift`
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift`

**Interfaces:**
- Consumes: 기존 `KeyboardLayoutFigure.languageSwitchButtonWidthRatio` (`CGFloat`, 값 `0.1`)
- Produces:
  - `KeyboardLayoutFigure.fourColumnCount: Int` (internal)
  - `KeyboardLayoutFigure.letterColumnWidthMultiplierRange: ClosedRange<Double>` (**public**, 설정 화면이 사용)
  - `KeyboardLayoutFigure.languageSwitchButtonFunctionColumnShare: CGFloat` (internal)
  - `enum KeyboardColumnWidthPolicy` (internal) — `clamped(_:) -> Double`, `letterColumnRatio(multiplier:) -> CGFloat`, `functionColumnRatio(multiplier:) -> CGFloat`, `languageSwitchButtonRatio(multiplier:) -> CGFloat`. 모두 `static`, 인자는 `Double`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift` 생성:

```swift
//
//  KeyboardColumnWidthPolicyTests.swift
//  SYKeyboardTests
//

import Testing
import CoreFoundation

@testable import SYKeyboardCore

@Suite("4열 격자 열 너비 정책")
struct KeyboardColumnWidthPolicyTests {
    private static let tolerance: CGFloat = 0.0001

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let letter = KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.0)
        let function = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.0)

        #expect(abs(letter - 0.25) < Self.tolerance)
        #expect(abs(function - 0.25) < Self.tolerance)
    }

    @Test("기본 배율의 한영 전환 버튼 비율은 기존 상수와 같다")
    func testDefaultLanguageSwitchRatioMatchesExistingConstant() {
        let ratio = KeyboardColumnWidthPolicy.languageSwitchButtonRatio(multiplier: 1.0)

        #expect(abs(ratio - KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < Self.tolerance)
    }

    @Test("글자 열 3개와 기능 열의 합은 항상 1이다")
    func testColumnRatiosAlwaysSumToOne() {
        for step in 0...20 {
            let multiplier = 1.0 + Double(step) * 0.01
            let total = 3 * KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: multiplier)
            + KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

            #expect(abs(total - 1.0) < Self.tolerance)
        }
    }

    @Test("배율을 올리면 글자 열이 넓어지고 기능 열이 좁아진다")
    func testHigherMultiplierWidensLetterColumns() {
        #expect(abs(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.2) - 0.3) < Self.tolerance)
        #expect(abs(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.2) - 0.1) < Self.tolerance)
        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.2)
                > KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 1.0))
        #expect(KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.2)
                < KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.0))
    }

    @Test("한영 전환 버튼 비율은 기능 열보다 좁고 기능 열과 함께 줄어든다")
    func testLanguageSwitchRatioShrinksWithFunctionColumn() {
        let function = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: 1.2)
        let languageSwitch = KeyboardColumnWidthPolicy.languageSwitchButtonRatio(multiplier: 1.2)

        #expect(languageSwitch < function)
        #expect(languageSwitch < KeyboardColumnWidthPolicy.languageSwitchButtonRatio(multiplier: 1.0))
    }

    @Test("범위 밖 배율은 허용 범위로 잘린다")
    func testMultiplierIsClampedToRange() {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange

        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 0.5)
                == KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: range.lowerBound))
        #expect(KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: 5.0)
                == KeyboardColumnWidthPolicy.letterColumnRatio(multiplier: range.upperBound))
        #expect(range.lowerBound == 1.0)
        #expect(range.upperBound == 1.2)
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests
```

기대: 컴파일 실패. `cannot find 'KeyboardColumnWidthPolicy' in scope`

- [x] **Step 3: `KeyboardLayoutFigure`에 상수 추가**

`Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift`의 `languageSwitchButtonWidthRatio` 선언 **바로 아래**에 추가한다:

```swift
    /// 4x4 계열 키보드의 열 개수
    static let fourColumnCount: Int = 4
    /// 4x4 계열 글자 열 너비 배율 범위.
    ///
    /// `1.0`이 현재의 균등 분할이고, 값이 커질수록 글자 열이 넓어지고 기능 열이 좁아진다
    public static let letterColumnWidthMultiplierRange: ClosedRange<Double> = 1.0...1.2
    /// 기능 열 안에서 한영 전환 버튼이 차지하는 몫.
    ///
    /// 기본 배율에서 `languageSwitchButtonWidthRatio`와 같은 폭이 되도록 기존 값에서 유도한다.
    /// 기능 열이 좁아지면 한영 전환 버튼도 같이 좁아져 `switchButton` 폭이 0이 되는 것을 막는다
    static let languageSwitchButtonFunctionColumnShare: CGFloat =
    languageSwitchButtonWidthRatio * CGFloat(fourColumnCount)
```

- [x] **Step 4: `KeyboardColumnWidthPolicy` 작성**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift` 생성:

```swift
//
//  KeyboardColumnWidthPolicy.swift
//  SYKeyboardCore
//

import CoreFoundation

/// 4열 격자 키보드(나랏글·천지인·숫자 키패드)의 열 너비 비율을 계산한다.
///
/// 모든 반환값은 행 전체 폭 대비 비율이다
enum KeyboardColumnWidthPolicy {

    /// 배율을 허용 범위로 자른다
    static func clamped(_ multiplier: Double) -> Double {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        return min(max(multiplier, range.lowerBound), range.upperBound)
    }

    /// 글자 열 하나가 차지하는 비율
    static func letterColumnRatio(multiplier: Double) -> CGFloat {
        CGFloat(clamped(multiplier)) / CGFloat(KeyboardLayoutFigure.fourColumnCount)
    }

    /// 기능 열(4열)이 차지하는 비율. 글자 열 3개가 쓰고 남은 폭이다
    static func functionColumnRatio(multiplier: Double) -> CGFloat {
        let letterColumnCount = CGFloat(KeyboardLayoutFigure.fourColumnCount - 1)
        return 1.0 - letterColumnCount * letterColumnRatio(multiplier: multiplier)
    }

    /// 한영 전환 버튼이 차지하는 비율. 기능 열 폭에 연동된다
    static func languageSwitchButtonRatio(multiplier: Double) -> CGFloat {
        functionColumnRatio(multiplier: multiplier)
        * KeyboardLayoutFigure.languageSwitchButtonFunctionColumnShare
    }
}
```

- [x] **Step 5: `project.pbxproj`에 새 파일 등록**

두 `membershipExceptions` 블록 각각에서 `SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift,` 줄 **바로 다음**에 아래 줄을 삽입한다. 들여쓰기는 주변 줄과 동일하게 탭 4개다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift,
```

두 블록은 각각 `Exceptions for "Modules" folder in "SYKeyboard" target`과 `Exceptions for "Modules" folder in "SYKeyboardCore" target`이다. 아래 명령으로 삽입 결과가 2줄인지 확인한다:

```sh
grep -c "Policies/KeyboardColumnWidthPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj
```

기대: `2`

- [x] **Step 6: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests
```

기대: 6개 테스트 통과

- [x] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift \
        Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift \
        SYKeyboard.xcodeproj/project.pbxproj \
        SYKeyboardTests/Utils/KeyboardColumnWidthPolicyTests.swift
git commit -m "feat: #112 - 4열 격자 열 너비 계산 정책 추가"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/KeyboardColumnWidthPolicyTests`
(iPhone 13 mini / iOS 16.0, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`) — Step 2에서 `cannot find
'KeyboardColumnWidthPolicy' in scope` 컴파일 실패를 확인한 뒤, Step 6에서 **6/6 통과
(TEST SUCCEEDED)**. `grep -c "Policies/KeyboardColumnWidthPolicy.swift" project.pbxproj` = `2`.
커밋 `7fc14984`.

---

## Task 2: 저장소 키

배율을 App Group `UserDefaults`에 저장한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Produces:
  - `UserDefaultsKeys.letterColumnWidthMultiplier: String` = `"letterColumnWidthMultiplier"` (public)
  - `DefaultValues.letterColumnWidthMultiplier: Double` = `1.0` (public)
  - `UserDefaultsManager.shared.letterColumnWidthMultiplier: Double` (public, 읽기·쓰기)

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Storage/UserDefaultsContractTests.swift`의 마지막 `@Test` 뒤, `restore` helper 앞에 추가:

```swift
    @Test("글자 열 너비 배율은 저장값이 없으면 1.0을 반환하고 공유 저장소 키를 유지")
    func testLetterColumnWidthMultiplierDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.letterColumnWidthMultiplier
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "letterColumnWidthMultiplier")
        #expect(DefaultValues.letterColumnWidthMultiplier == 1.0)
        #expect(UserDefaultsManager.shared.letterColumnWidthMultiplier == 1.0)
    }
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

기대: 컴파일 실패. `type 'UserDefaultsKeys' has no member 'letterColumnWidthMultiplier'`

- [x] **Step 3: 세 저장소 파일에 항목 추가**

`UserDefaultsKeys.swift`의 `// MARK: - 외형 설정` 구역, `oneHandedKeyboardWidth` 줄 바로 아래:

```swift
    /// 4x4 계열 글자 열 너비 배율
    public static let letterColumnWidthMultiplier = "letterColumnWidthMultiplier"
```

`DefaultValues.swift`의 `// MARK: - 외형 설정` 구역, `oneHandedKeyboardWidth` 줄 바로 아래:

```swift
    /// 4x4 계열 글자 열 너비 배율 기본값. 현재의 균등 분할과 같다
    public static let letterColumnWidthMultiplier: Double = 1.0
```

`UserDefaultsManager.swift`의 `// MARK: 외형 설정` 구역, `oneHandedKeyboardWidth` 프로퍼티 바로 아래:

```swift
    /// 4x4 계열 글자 열 너비 배율
    @UserDefaultsWrapper(key: UserDefaultsKeys.letterColumnWidthMultiplier, defaultValue: DefaultValues.letterColumnWidthMultiplier)
    public var letterColumnWidthMultiplier: Double
```

- [x] **Step 4: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

기대: 기존 테스트 + 새 테스트 1개 모두 통과

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift \
        Modules/SYKeyboardCore/Storage/DefaultValues.swift \
        Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift \
        SYKeyboardTests/Storage/UserDefaultsContractTests.swift
git commit -m "feat: #112 - 글자 열 너비 배율 설정 키 추가"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/UserDefaultsContractTests`
(iPhone 13 mini / iOS 16.0) — Step 2에서 `type 'UserDefaultsKeys' has no member
'letterColumnWidthMultiplier'` 컴파일 실패를 확인한 뒤, Step 4에서 **12/12 통과**
(기존 11 + 신규 1). `project.pbxproj` 변경 없음(새 파일 없음). 커밋 `579c2c2c`.

---

## Task 3: 4열 폭 제약 컨트롤러

세 뷰가 공유할 Auto Layout 제약 설치·갱신 로직을 만든다. 아직 어느 뷰에도 연결하지 않는다.

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/View/Components/Frames/FourColumnWidthLayoutController.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`

**Interfaces:**
- Consumes: `KeyboardColumnWidthPolicy.functionColumnRatio(multiplier:)`, `KeyboardColumnWidthPolicy.languageSwitchButtonRatio(multiplier:)`, `KeyboardLayoutFigure.fourColumnCount` (Task 1)
- Produces: `final class FourColumnWidthLayoutController` (internal)
  - `init()`
  - `func install(rows: [UIStackView], languageSwitchButton: UIView?, referenceView: UIView, multiplier: Double)`
  - `func update(multiplier: Double)`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift` 생성:

```swift
//
//  FourColumnWidthLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("4열 격자 열 너비 레이아웃")
struct FourColumnWidthLayoutTests {
    static let rowWidth: CGFloat = 400
    static let rowHeight: CGFloat = 50
    static let tolerance: CGFloat = 0.5

    /// 4열 스택 하나를 만들고 컨트롤러로 폭 제약을 설치한 뒤 레이아웃한다
    @MainActor
    private static func makeRow(multiplier: Double)
    -> (container: UIView, row: UIStackView, controller: FourColumnWidthLayoutController) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: rowWidth, height: rowHeight))
        let row = KeyboardRowHStackView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        (0..<4).forEach { _ in row.addArrangedSubview(UIView()) }

        let controller = FourColumnWidthLayoutController()
        controller.install(rows: [row],
                           languageSwitchButton: nil,
                           referenceView: container,
                           multiplier: multiplier)
        container.layoutIfNeeded()

        return (container, row, controller)
    }

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierSplitsEqually() {
        let (_, row, _) = Self.makeRow(multiplier: 1.0)
        let widths = row.arrangedSubviews.map(\.frame.width)

        widths.forEach { #expect(abs($0 - Self.rowWidth / 4) < Self.tolerance) }
    }

    @Test("배율을 올리면 1~3열이 등폭으로 넓어지고 4열이 좁아진다")
    func testHigherMultiplierWidensFirstThreeColumns() {
        let (_, row, _) = Self.makeRow(multiplier: 1.2)
        let widths = row.arrangedSubviews.map(\.frame.width)

        #expect(abs(widths[0] - widths[1]) < Self.tolerance)
        #expect(abs(widths[1] - widths[2]) < Self.tolerance)
        #expect(abs(widths[0] - Self.rowWidth * 0.3) < Self.tolerance)
        #expect(abs(widths[3] - Self.rowWidth * 0.1) < Self.tolerance)
        #expect(abs(widths.reduce(0, +) - Self.rowWidth) < Self.tolerance)
    }

    @Test("update로 배율을 바꾸면 폭이 다시 계산된다")
    func testUpdateRecalculatesWidths() {
        let (container, row, controller) = Self.makeRow(multiplier: 1.0)

        controller.update(multiplier: 1.2)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth * 0.1) < Self.tolerance)

        controller.update(multiplier: 1.0)
        container.layoutIfNeeded()
        #expect(abs(row.arrangedSubviews[3].frame.width - Self.rowWidth / 4) < Self.tolerance)
    }

    @Test("한영 전환 버튼 폭은 기능 열에 연동된다")
    func testLanguageSwitchButtonWidthFollowsFunctionColumn() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: Self.rowWidth, height: Self.rowHeight))
        let row = KeyboardRowHStackView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        (0..<3).forEach { _ in row.addArrangedSubview(UIView()) }

        let modifierStack = KeyboardRowHStackView()
        modifierStack.distribution = .fill
        let languageSwitchButton = UIView()
        modifierStack.addArrangedSubview(languageSwitchButton)
        modifierStack.addArrangedSubview(UIView())
        row.addArrangedSubview(modifierStack)

        let controller = FourColumnWidthLayoutController()
        controller.install(rows: [row],
                           languageSwitchButton: languageSwitchButton,
                           referenceView: container,
                           multiplier: 1.0)
        container.layoutIfNeeded()

        // 기본 배율에서는 기존 상수와 같은 폭이다
        #expect(abs(languageSwitchButton.frame.width
                    - Self.rowWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < Self.tolerance)

        controller.update(multiplier: 1.2)
        container.layoutIfNeeded()

        // 기능 열이 좁아지면 한영 전환 버튼도 좁아지고, 같은 열의 다른 버튼 폭이 남는다
        #expect(languageSwitchButton.frame.width < Self.rowWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio)
        #expect(languageSwitchButton.frame.width < modifierStack.frame.width)
        #expect(modifierStack.arrangedSubviews[1].frame.width > 0)
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/FourColumnWidthLayoutTests
```

기대: 컴파일 실패. `cannot find 'FourColumnWidthLayoutController' in scope`

- [x] **Step 3: 컨트롤러 작성**

`Modules/SYKeyboardCore/Presentation/View/Components/Frames/FourColumnWidthLayoutController.swift` 생성:

```swift
//
//  FourColumnWidthLayoutController.swift
//  SYKeyboardCore
//

import UIKit

/// 4열 격자 키보드 행의 열 폭 비율을 관리한다.
///
/// 각 행의 1~3열은 서로 등폭이고 4열만 배율에 따라 폭이 바뀐다.
/// 등폭 제약은 배율과 무관하므로 한 번만 만들고,
/// 4열 제약과 한영 전환 버튼 제약만 배율이 바뀔 때 다시 만든다
final class FourColumnWidthLayoutController {

    // MARK: - Properties

    private var rows: [UIStackView] = []
    private weak var languageSwitchButton: UIView?
    private weak var referenceView: UIView?
    /// 배율이 바뀌면 다시 만들어야 하는 제약
    private var ratioConstraints: [NSLayoutConstraint] = []

    // MARK: - Internal Methods

    /// 행 스택을 `.fill`로 바꾸고 열 폭 제약을 설치합니다.
    ///
    /// `setHierarchy()`가 끝나 각 행에 4개의 `arrangedSubviews`가 채워진 뒤 호출해야 합니다.
    /// - Parameters:
    ///   - rows: 각각 4열을 가진 행 스택
    ///   - languageSwitchButton: 한영 전환 버튼. 없으면 `nil`
    ///   - referenceView: 한영 전환 버튼 폭의 기준이 되는 키보드 뷰
    ///   - multiplier: 글자 열 너비 배율
    func install(rows: [UIStackView],
                 languageSwitchButton: UIView?,
                 referenceView: UIView,
                 multiplier: Double) {
        self.rows = rows
        self.languageSwitchButton = languageSwitchButton
        self.referenceView = referenceView

        for row in rows {
            let columns = row.arrangedSubviews
            assert(columns.count == KeyboardLayoutFigure.fourColumnCount,
                   "4열 격자 행이 아닙니다: \(columns.count)열")
            guard columns.count == KeyboardLayoutFigure.fourColumnCount else { continue }

            row.distribution = .fill
            // 1~3열은 배율과 무관하게 서로 등폭이다
            NSLayoutConstraint.activate([
                columns[0].widthAnchor.constraint(equalTo: columns[1].widthAnchor),
                columns[1].widthAnchor.constraint(equalTo: columns[2].widthAnchor)
            ])
        }

        activateRatioConstraints(multiplier: multiplier)
    }

    /// 배율이 바뀌면 4열 제약과 한영 전환 버튼 제약만 다시 만듭니다.
    ///
    /// `NSLayoutConstraint.multiplier`가 읽기 전용이므로 재생성이 필요합니다.
    func update(multiplier: Double) {
        NSLayoutConstraint.deactivate(ratioConstraints)
        ratioConstraints.removeAll()
        activateRatioConstraints(multiplier: multiplier)
    }
}

// MARK: - Private Methods

private extension FourColumnWidthLayoutController {
    func activateRatioConstraints(multiplier: Double) {
        let functionColumnRatio = KeyboardColumnWidthPolicy.functionColumnRatio(multiplier: multiplier)

        for row in rows {
            let columns = row.arrangedSubviews
            guard columns.count == KeyboardLayoutFigure.fourColumnCount else { continue }

            ratioConstraints.append(
                columns[3].widthAnchor.constraint(equalTo: row.widthAnchor,
                                                  multiplier: functionColumnRatio)
            )
        }

        if let languageSwitchButton, let referenceView {
            languageSwitchButton.translatesAutoresizingMaskIntoConstraints = false
            let languageSwitchWidth = languageSwitchButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: KeyboardColumnWidthPolicy.languageSwitchButtonRatio(multiplier: multiplier)
            )
            // 지구본이 보이면 stack의 균등 분배(required)가 이기고 이 제약은 양보해야 하므로
            // required보다 낮춘다. 지구본이 숨겨지면 경쟁하는 제약이 없어 그대로 성립한다
            languageSwitchWidth.priority = .init(999)
            ratioConstraints.append(languageSwitchWidth)
        }

        NSLayoutConstraint.activate(ratioConstraints)
    }
}
```

- [x] **Step 4: `project.pbxproj`에 새 파일 등록**

두 `membershipExceptions` 블록 각각에서 `SYKeyboardCore/Presentation/View/Components/Frames/KeyboardLayoutVStackView.swift,` 줄 **바로 앞**에 아래 줄을 삽입한다(`F` < `K` 이므로 알파벳 순).

```
				SYKeyboardCore/Presentation/View/Components/Frames/FourColumnWidthLayoutController.swift,
```

확인:

```sh
grep -c "Frames/FourColumnWidthLayoutController.swift" SYKeyboard.xcodeproj/project.pbxproj
```

기대: `2`

- [x] **Step 5: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/FourColumnWidthLayoutTests
```

기대: 4개 테스트 통과. Auto Layout 충돌 경고(`Unable to simultaneously satisfy constraints`)가 로그에 나오면 실패로 간주하고 원인을 찾는다.

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Frames/FourColumnWidthLayoutController.swift \
        SYKeyboard.xcodeproj/project.pbxproj \
        SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "feat: #112 - 4열 격자 폭 제약 컨트롤러 추가"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/FourColumnWidthLayoutTests
-resultBundlePath /tmp/task3-verify.xcresult` (iPhone 13 mini / iOS 16.0, build 20A360) —
`xcresulttool get test-results summary` 기준 `result: Passed`, `totalTestCount: 4`,
`passedTests: 4`, `failedTests: 0`. Auto Layout 충돌 경고
(`Unable to simultaneously satisfy constraints`) **0건**.
`grep -c "Frames/FourColumnWidthLayoutController.swift" project.pbxproj` = `2`. 커밋 `95023df4`.

**계획 정정 (실행 중 확정):** Step 3의 `update(multiplier:)`에 결함이 있었다. 제약만 교체하고
레이아웃을 무효화하지 않아 `update()` 후 프레임이 갱신 전 값에 머물렀다(4열 폭 100 유지, 기대 40;
한영 전환 버튼 40.0 유지, 기대 40 미만). Auto Layout 충돌 경고가 0건이었으므로 옛 제약이 남아
경쟁한 것이 아니라 레이아웃이 재실행되지 않은 것이다. 제약 변경을 소유한 컨트롤러가 무효화도
소유해야 하므로 `update()` 끝에 아래를 추가했다.

```swift
        rows.forEach { $0.setNeedsLayout() }
        referenceView?.setNeedsLayout()
```

**이월된 minor 2건:** (1) `update()`는 `setNeedsLayout()`까지만 하고 `layoutIfNeeded()`는
호출자에게 맡긴다 — Task 4~6 연결 시 실제 반영 확인 필요. (2) `install()`을 두 번 호출하면
이전 `ratioConstraints`가 비활성화되지 않고 남는다 — 현재 호출부는 `setConstraints()`에서
1회만 호출하므로 발생하지 않는다.

---

## Task 4: 나랏글 키보드 적용

`FourByFourKeyboardView`에 컨트롤러를 연결하고, 갱신 메서드를 프로토콜에 추가한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`

**Interfaces:**
- Consumes: `FourColumnWidthLayoutController` (Task 3), `UserDefaultsManager.shared.letterColumnWidthMultiplier` (Task 2)
- Produces:
  - `NormalKeyboardLayoutProvider.updateLetterColumnWidthMultiplier(_ multiplier: Double)` — 프로토콜 요구사항 + extension 기본 no-op
  - `FourByFourKeyboardView.updateLetterColumnWidthMultiplier(_:)` — `public func`, 오버라이드 구현

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift` 상단 import에 추가:

```swift
@testable import HangeulKeyboardCore
```

같은 파일 안에 새 `@Suite`를 추가한다:

```swift
@MainActor
@Suite("나랏글 열 너비 레이아웃")
struct NaratgeulColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(multiplier: Double) -> NaratgeulKeyboardView {
        let view = NaratgeulKeyboardView(showsLanguageSwitchButton: true)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 행을 가로질러 비교하려면 변환해야 한다
    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @Test("기본 배율은 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let view = Self.makeView(multiplier: 1.0)
        let expected = Self.keyboardWidth / 4

        #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        #expect(abs(Self.rect(view.spaceButton, in: view).width - expected) < Self.tolerance)
        #expect(abs(Self.rect(view.returnButtonHStackView, in: view).width - expected) < Self.tolerance)
    }

    @Test("배율을 올리면 기능 열이 좁아지고 열 경계가 행마다 일치한다")
    func testHigherMultiplierNarrowsFunctionColumn() {
        let view = Self.makeView(multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnStack.width - expectedFunctionWidth) < Self.tolerance)

        // 1~4행 모두 4열이 같은 x에서 시작한다
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("배율을 올리면 글자 버튼이 넓어진다")
    func testHigherMultiplierWidensKeyButtons() throws {
        let defaultView = Self.makeView(multiplier: 1.0)
        let widenedView = Self.makeView(multiplier: 1.2)

        let defaultKey = try #require(defaultView.primaryButtonList.first as? PrimaryKeyButton)
        let widenedKey = try #require(widenedView.primaryButtonList.first as? PrimaryKeyButton)

        #expect(widenedKey.frame.width > defaultKey.frame.width)
        #expect(abs(widenedKey.frame.width - Self.keyboardWidth * 0.3) < Self.tolerance)
    }

    @Test("배율을 되돌리면 균등 분할로 돌아온다")
    func testUpdatingBackRestoresEqualColumns() {
        let view = Self.makeView(multiplier: 1.2)

        view.updateLetterColumnWidthMultiplier(1.0)
        view.layoutIfNeeded()

        #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NaratgeulColumnWidthLayoutTests
```

기대: 컴파일 실패. `value of type 'NaratgeulKeyboardView' has no member 'updateLetterColumnWidthMultiplier'`

- [x] **Step 3: 프로토콜에 메서드 추가**

`Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift`의 프로토콜 본문에서 `func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool)` 바로 아래에 추가:

```swift
    func updateLetterColumnWidthMultiplier(_ multiplier: Double)
```

같은 파일 `public extension`에서 `func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool) {}` 바로 아래에 추가:

```swift
    /// 4열 격자가 아닌 키보드는 글자 열 너비 배율의 영향을 받지 않는다
    func updateLetterColumnWidthMultiplier(_ multiplier: Double) {}
```

- [x] **Step 4: `FourByFourKeyboardView`에 컨트롤러 연결**

`Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift`

(4-1) `private let showsLanguageSwitchButton: Bool` 바로 아래에 프로퍼티 추가:

```swift
    /// 4열 폭 비율 제약 관리자
    private let columnWidthLayoutController = FourColumnWidthLayoutController()
```

(4-2) `// MARK: - Update Methods` extension의 `updateModifierDistribution` 아래에 메서드 추가:

```swift
    /// 글자 열 너비 배율을 다시 적용합니다.
    public func updateLetterColumnWidthMultiplier(_ multiplier: Double) {
        columnWidthLayoutController.update(multiplier: multiplier)
        setNeedsLayout()
    }
```

(4-3) `setConstraints()`에서 아래 블록을

```swift
        if let languageSwitchButton {
            languageSwitchButton.translatesAutoresizingMaskIntoConstraints = false
            let languageSwitchWidth = languageSwitchButton.widthAnchor.constraint(
                equalTo: self.widthAnchor,
                multiplier: KeyboardLayoutFigure.languageSwitchButtonWidthRatio
            )
            // 지구본이 보이면 stack의 균등 분배(required)가 이기고 이 제약은 양보해야 하므로
            // required보다 낮춘다. 지구본이 숨겨지면 경쟁하는 제약이 없어 그대로 성립한다
            languageSwitchWidth.priority = .init(999)
            languageSwitchWidth.isActive = true
            updateModifierDistribution(isNextKeyboardButtonVisible: !nextKeyboardButton.isHidden)
        }
```

아래로 교체한다:

```swift
        // 4열 폭 비율은 컨트롤러가 관리한다.
        // 한영 전환 버튼 폭도 기능 열에 연동되므로 함께 넘긴다
        columnWidthLayoutController.install(
            rows: [firstRowHStackView,
                   secondRowHStackView,
                   thirdRowHStackView,
                   fourthRowHStackView],
            languageSwitchButton: languageSwitchButton,
            referenceView: self,
            multiplier: UserDefaultsManager.shared.letterColumnWidthMultiplier
        )

        if languageSwitchButton != nil {
            updateModifierDistribution(isNextKeyboardButtonVisible: !nextKeyboardButton.isHidden)
        }
```

- [x] **Step 5: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NaratgeulColumnWidthLayoutTests \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests
```

기대: 새 테스트 4개 통과, 기존 `KeyboardModifierLayoutTests`도 수정 없이 통과

- [x] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift \
        Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift \
        SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "feat: #112 - 나랏글 키보드 글자 열 너비 비율 적용"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/NaratgeulColumnWidthLayoutTests
-only-testing:SYKeyboardTests/KeyboardModifierLayoutTests -resultBundlePath /tmp/task4.xcresult`
(iPhone 13 mini / iOS 16.0, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`, build 20A360) —
`xcresulttool get test-results summary` 기준 `totalTestCount: 21`, `passedTests: 21`,
`failedTests: 0` (파라미터화 확장 포함 25 runs). Auto Layout 충돌 경고는
`xcresulttool get log --type action` 출력에서 **0건**. 기존 `KeyboardModifierLayoutTests`는
수정 없이 통과했다. `project.pbxproj` 변경 없음. 커밋 `aff74de1`.

Step 2에서 `value of type 'NaratgeulKeyboardView' has no member
'updateLetterColumnWidthMultiplier'` 컴파일 실패를 먼저 확인했다.

`FourColumnWidthLayoutTests` suite는 그대로 두고 `NaratgeulColumnWidthLayoutTests`를 파일 끝에
append했다(리뷰에서 확인).

**미확인:** 실제 입력 앱에서 기본 배율(1.0) 화면이 기존과 동일한지는 유닛 테스트의 프레임 비교로만
확인했고 육안 확인은 하지 않았다. 이 Task는 배율 조정 UI가 아직 연결되지 않은 배선 단계다.
Task 9의 수동 확인 항목으로 남아 있다.

---

## Task 5: 천지인 키보드 적용

`FourByFourPlusKeyboardView`에 같은 방식으로 연결한다. 하단 스페이스 배치까지 검증한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`

**Interfaces:**
- Consumes: Task 3의 `FourColumnWidthLayoutController`, Task 4의 프로토콜 메서드
- Produces: `FourByFourPlusKeyboardView.updateLetterColumnWidthMultiplier(_:)` — `public func`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`에 새 `@Suite` 추가:

```swift
@MainActor
@Suite("천지인 열 너비 레이아웃")
struct CheonjiinColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool, multiplier: Double) -> CheonjiinKeyboardView {
        let view = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
                                        usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @MainActor
    private static func keyButton(_ view: CheonjiinKeyboardView, primary: String) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        return try #require(keyButtons.first { $0.type.primaryKeyList.first == primary })
    }

    @Test("기본 배율은 두 배치 모두 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let expected = Self.keyboardWidth / 4

        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.0)
            #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        }
    }

    @Test("기본 배치에서 배율을 올리면 기능 열이 좁아지고 열 경계가 일치한다")
    func testDefaultLayoutNarrowsFunctionColumn() {
        let view = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnStack.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.2)
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let returnStack = Self.rect(view.returnButtonHStackView, in: view)
        // 3행 4열은 '?' '!' 글자 스택, 4행 4열은 '.' ',' 글자 스택이다
        let question = Self.rect(try Self.keyButton(view, primary: "?"), in: view)
        let period = Self.rect(try Self.keyButton(view, primary: "."), in: view)

        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnStack.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(question.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(period.minX - expectedColumnStart) < Self.tolerance)

        // 4행 1열의 modifier 스택은 넓어진 열에 놓인다
        #expect(abs(Self.rect(view.switchButton, in: view).minX) < Self.tolerance)
    }

    @Test("배율을 되돌리면 두 배치 모두 균등 분할로 돌아온다")
    func testUpdatingBackRestoresEqualColumns() {
        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.2)

            view.updateLetterColumnWidthMultiplier(1.0)
            view.layoutIfNeeded()

            #expect(abs(Self.rect(view.deleteButton, in: view).width - Self.keyboardWidth / 4) < Self.tolerance)
        }
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinColumnWidthLayoutTests
```

기대: 컴파일 실패. `value of type 'CheonjiinKeyboardView' has no member 'updateLetterColumnWidthMultiplier'`

- [x] **Step 3: `FourByFourPlusKeyboardView`에 컨트롤러 연결**

Task 4 Step 4와 동일한 세 가지 변경을 `FourByFourPlusKeyboardView.swift`에 적용한다.

(3-1) `public let usesBottomSpaceLayout: Bool` 바로 아래에 프로퍼티 추가:

```swift
    /// 4열 폭 비율 제약 관리자
    private let columnWidthLayoutController = FourColumnWidthLayoutController()
```

(3-2) `// MARK: - Update Methods` extension의 `updateModifierDistribution` 아래에 메서드 추가:

```swift
    /// 글자 열 너비 배율을 다시 적용합니다.
    public func updateLetterColumnWidthMultiplier(_ multiplier: Double) {
        columnWidthLayoutController.update(multiplier: multiplier)
        setNeedsLayout()
    }
```

(3-3) `setConstraints()`의 `if let languageSwitchButton { ... }` 블록 전체를 아래로 교체한다:

```swift
        // 4열 폭 비율은 컨트롤러가 관리한다.
        // 한영 전환 버튼 폭도 기능 열에 연동되므로 함께 넘긴다
        columnWidthLayoutController.install(
            rows: [firstRowHStackView,
                   secondRowHStackView,
                   thirdRowHStackView,
                   fourthRowHStackView],
            languageSwitchButton: languageSwitchButton,
            referenceView: self,
            multiplier: UserDefaultsManager.shared.letterColumnWidthMultiplier
        )

        if languageSwitchButton != nil {
            updateModifierDistribution(isNextKeyboardButtonVisible: !nextKeyboardButton.isHidden)
        }
```

- [x] **Step 4: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinColumnWidthLayoutTests \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests
```

기대: 새 테스트 4개 통과, 기존 `CheonjiinBottomSpaceLayoutTests`도 수정 없이 통과

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift \
        SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "feat: #112 - 천지인 키보드 글자 열 너비 비율 적용"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/CheonjiinColumnWidthLayoutTests
-only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests -resultBundlePath /tmp/task5.xcresult`
(iPhone 13 mini / iOS 16.0, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`) —
`xcresulttool get test-results summary` 기준 `totalTestCount: 18`, `passedTests: 18`,
`failedTests: 0` (기기별 파라미터화 확장 포함 22 runs). Auto Layout 충돌 경고 **0건**.
기존 `CheonjiinBottomSpaceLayoutTests`는 수정 없이 통과했다.
`project.pbxproj` 변경 없음. 커밋 `ee2ae1d5`.

`FourColumnWidthLayoutTests`·`NaratgeulColumnWidthLayoutTests` suite는 그대로 두고
`CheonjiinColumnWidthLayoutTests`를 파일 끝에 append했다. `@testable import HangeulKeyboardCore`는
Task 4에서 추가된 것을 재사용했고 중복 추가하지 않았다(리뷰에서 확인).

**위치 기준 적용 확인(리뷰):** `setHierarchy()`의 하단 스페이스 분기에서 3행 4열이
`fourthRowRightPrimaryButtonHStackView`(`'?'`,`'!'`), 4행 1열이 modifier 스택, 4행 4열이
`fourthRowLeftPrimaryButtonHStackView`(`'.'`,`','`)임을 저장소 코드와 대조했다.
`install()`이 `arrangedSubviews`의 인덱스만 보고 제약을 걸므로 의미 분기 없이 위치 기준으로
동작한다. 오버레이 제약(`keyboardSelectOverlayView`, `oneHandedModeSelectOverlayView`,
`cancelBoundary`)은 미변경이다.

**이월된 minor 1건:** `testBottomSpaceLayoutNarrowsFourthColumnByPosition`의
`switchButton.minX ≈ 0` 단언은 1열이 실제로 넓어졌는지를 검증하지 못한다(계획 단계의 설계 여지).
같은 테스트의 `'?'`·`'.'` `minX` 단언이 4열 축소를 검증하므로 커버리지 공백은 아니다.

**미확인:** 실기기 렌더링과 하단 스페이스 배치의 체감 사용성은 Task 9의 수동 확인 항목이다.

---

## Task 6: 숫자 키패드 적용

`NumericKeyboardView`에 같은 방식으로 연결한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`

**Interfaces:**
- Consumes: Task 3의 `FourColumnWidthLayoutController`, Task 4의 프로토콜 메서드
- Produces: `NumericKeyboardView.updateLetterColumnWidthMultiplier(_:)` — `public func`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift`에 새 `@Suite` 추가:

```swift
@MainActor
@Suite("숫자 키패드 열 너비 레이아웃")
struct NumericColumnWidthLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216
    private static let tolerance: CGFloat = 0.5

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool, multiplier: Double) -> NumericKeyboardView {
        let view = NumericKeyboardView(showsLanguageSwitchButton: true,
                                       usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.updateLetterColumnWidthMultiplier(multiplier)
        view.layoutIfNeeded()

        return view
    }

    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @MainActor
    private static func keyButton(_ view: NumericKeyboardView, primary: String) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        return try #require(keyButtons.first { $0.type.primaryKeyList.first == primary })
    }

    @Test("기본 배율은 두 배치 모두 네 열을 균등 분할한다")
    func testDefaultMultiplierKeepsEqualColumns() {
        let expected = Self.keyboardWidth / 4

        for usesBottomSpaceLayout in [false, true] {
            let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout, multiplier: 1.0)
            #expect(abs(Self.rect(view.deleteButton, in: view).width - expected) < Self.tolerance)
        }
    }

    @Test("기본 배치에서 배율을 올리면 기능 열이 좁아지고 열 경계가 일치한다")
    func testDefaultLayoutNarrowsFunctionColumn() {
        let view = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)
        let expectedFunctionWidth = Self.keyboardWidth * 0.1
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let nextKeyboard = Self.rect(view.nextKeyboardButton, in: view)

        #expect(abs(delete.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(space.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(returnRect.width - expectedFunctionWidth) < Self.tolerance)
        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(space.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnRect.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(nextKeyboard.minX - expectedColumnStart) < Self.tolerance)
    }

    @Test("하단 스페이스 배치도 위치 기준으로 4열이 좁아지고 열 경계가 일치한다")
    func testBottomSpaceLayoutNarrowsFourthColumnByPosition() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true, multiplier: 1.2)
        let expectedColumnStart = Self.keyboardWidth * 0.9

        let delete = Self.rect(view.deleteButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        // 3행 4열은 '-' '/' 스택, 4행 4열은 '.' ',' 스택이다
        let minus = Self.rect(try Self.keyButton(view, primary: "-"), in: view)
        let period = Self.rect(try Self.keyButton(view, primary: "."), in: view)

        #expect(abs(delete.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(returnRect.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(minus.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(period.minX - expectedColumnStart) < Self.tolerance)
        #expect(abs(Self.rect(view.switchButton, in: view).minX) < Self.tolerance)
    }

    @Test("배율을 올리면 숫자 버튼이 넓어진다")
    func testHigherMultiplierWidensKeyButtons() throws {
        let defaultView = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.0)
        let widenedView = Self.makeView(usesBottomSpaceLayout: false, multiplier: 1.2)

        let defaultKey = try Self.keyButton(defaultView, primary: "1")
        let widenedKey = try Self.keyButton(widenedView, primary: "1")

        #expect(widenedKey.frame.width > defaultKey.frame.width)
        #expect(abs(widenedKey.frame.width - Self.keyboardWidth * 0.3) < Self.tolerance)
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NumericColumnWidthLayoutTests
```

기대: 컴파일 실패. `value of type 'NumericKeyboardView' has no member 'updateLetterColumnWidthMultiplier'`

- [x] **Step 3: `NumericKeyboardView`에 컨트롤러 연결**

(3-1) `public let usesBottomSpaceLayout: Bool` 바로 아래에 프로퍼티 추가:

```swift
    /// 4열 폭 비율 제약 관리자
    private let columnWidthLayoutController = FourColumnWidthLayoutController()
```

(3-2) `extension NumericKeyboardView`의 `updateModifierDistribution` 아래에 메서드 추가:

```swift
    /// 글자 열 너비 배율을 다시 적용합니다.
    public func updateLetterColumnWidthMultiplier(_ multiplier: Double) {
        columnWidthLayoutController.update(multiplier: multiplier)
        setNeedsLayout()
    }
```

(3-3) `setConstraints()`의 `if let languageSwitchButton { ... }` 블록 전체를 아래로 교체한다:

```swift
        // 4열 폭 비율은 컨트롤러가 관리한다.
        // 한영 전환 버튼 폭도 기능 열에 연동되므로 함께 넘긴다
        columnWidthLayoutController.install(
            rows: [firstRowHStackView,
                   secondRowHStackView,
                   thirdRowHStackView,
                   fourthRowHStackView],
            languageSwitchButton: languageSwitchButton,
            referenceView: self,
            multiplier: UserDefaultsManager.shared.letterColumnWidthMultiplier
        )

        if languageSwitchButton != nil {
            updateModifierDistribution(isNextKeyboardButtonVisible: !nextKeyboardButton.isHidden)
        }
```

- [x] **Step 4: 테스트 통과 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NumericColumnWidthLayoutTests \
  -only-testing:SYKeyboardTests/NumericBottomSpaceLayoutTests
```

기대: 새 테스트 4개 통과, 기존 `NumericBottomSpaceLayoutTests`도 수정 없이 통과

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift \
        SYKeyboardTests/Utils/FourColumnWidthLayoutTests.swift
git commit -m "feat: #112 - 숫자 키패드 글자 열 너비 비율 적용"
```

**결과:** 완료. `xcodebuild test -only-testing:SYKeyboardTests/NumericColumnWidthLayoutTests
-only-testing:SYKeyboardTests/NumericBottomSpaceLayoutTests -resultBundlePath /tmp/task6.xcresult`
(iPhone 13 mini / iOS 16.0, `CBD992D3-5364-4F69-AC5F-0077ADF1A292`) —
`xcresulttool get test-results summary` 기준 `result: Passed`, `totalTestCount: 14`,
`passedTests: 14`, `failedTests: 0`, `skippedTests: 0` (parameterized 포함 15회 실행).
Auto Layout 충돌 경고 **0건**. 기존 `NumericBottomSpaceLayoutTests` 9개는 수정 없이 통과했다.
`project.pbxproj` 변경 없음. 커밋 `2048eb0e`.

기존 세 suite를 그대로 두고 `NumericColumnWidthLayoutTests`를 파일 끝에 append했다.
`@testable import SYKeyboardCore`가 이미 있어 새 import는 추가하지 않았다.

**키 배열 대조(리뷰):** `numericKeyList[3] = ["-", ",", "0", ".", "/"]`이고 하단 스페이스 분기에서
`fourthRowLeftPrimaryButtonHStackView = [list[3], list[1]] = [".", ","]`,
`fourthRowRightPrimaryButtonHStackView = [list[0], list[4]] = ["-", "/"]`이다.
따라서 3행 4열의 첫 요소가 `'-'`, 4행 4열의 첫 요소가 `'.'`이며 테스트 단언과 일치한다.
숫자 키패드의 `returnButton`은 중첩 스택이 아니라 행의 직속 자식(2행 또는 3행)이므로
프레임을 바로 비교하는 것이 맞다.

**미확인:** 실기기 렌더링은 Task 9의 수동 확인 항목이다. 설정값 변경을 런타임에 반영하는 배선은
Task 7 범위다.

---

## Task 7: 미리보기 갱신 경로

설정 화면 슬라이더가 미리보기 키보드에 실시간으로 반영되도록 경로를 잇는다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewKeyboardView.swift`
- Modify: `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewHangeulKeyboardViewController.swift`
- Modify: `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewEnglishKeyboardViewController.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`

**Interfaces:**
- Consumes: Task 4의 `NormalKeyboardLayoutProvider.updateLetterColumnWidthMultiplier(_:)`
- Produces:
  - `BaseKeyboardViewController.updateLetterColumnWidthForPreview(to multiplier: Double)` (public)
  - `PreviewKeyboardView.init(keyboardHeight:oneHandedKeyboardWidth:letterColumnWidthMultiplier:needsInputModeSwitchKey:previewKeyboardLanguage:oneHandedMode:)` — 세 번째 파라미터가 새로 추가된 `Binding<Double>`
  - `PreviewHangeulKeyboardViewController` / `PreviewEnglishKeyboardViewController`에 `@Binding var letterColumnWidthMultiplier: Double`

이 Task는 UI 배선이라 단위 테스트를 추가하지 않는다. 검증은 빌드 통과와 Task 9의 수동 확인으로 한다.

- [ ] **Step 1: `BaseKeyboardViewController`에 갱신 메서드 추가**

`// MARK: - Public Methods` 안, `updateOneHandedModeForPreview(to:)` 바로 아래에 추가:

```swift
    /// 미리보기에서 글자 열 너비 배율을 실시간으로 반영합니다.
    ///
    /// 숫자 키패드는 `primaryKeyboardViews`에 포함되지 않으므로 따로 갱신합니다
    public func updateLetterColumnWidthForPreview(to multiplier: Double) {
        primaryKeyboardViews.forEach { $0.updateLetterColumnWidthMultiplier(multiplier) }
        numericKeyboardView.updateLetterColumnWidthMultiplier(multiplier)
        self.view.layoutIfNeeded()
    }
```

- [ ] **Step 2: `PreviewKeyboardView`에 바인딩 추가**

`@Binding var oneHandedKeyboardWidth: Double` 바로 아래에 추가:

```swift
    @Binding var letterColumnWidthMultiplier: Double
```

`previewHangeulKeyboard`와 `previewEnglishKeyboard` 두 곳의 생성자 호출에 인자를 추가한다. `oneHandedKeyboardWidth` 다음 줄이다:

```swift
        PreviewHangeulKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode)
```

```swift
        PreviewEnglishKeyboardViewController(keyboardHeight: $keyboardHeight,
                                             oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                             letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                             oneHandedMode: $oneHandedMode)
```

- [ ] **Step 3: 두 Preview Representable에 바인딩 전달**

`PreviewHangeulKeyboardViewController.swift`와 `PreviewEnglishKeyboardViewController.swift` **양쪽 모두**에 같은 변경을 한다. 영문 키보드도 같은 숫자 키패드를 공유하므로 빠뜨리면 안 된다.

(3-1) `@Binding var oneHandedKeyboardWidth: Double` 바로 아래:

```swift
    @Binding var letterColumnWidthMultiplier: Double
```

(3-2) `updateUIViewController(_:context:)`의 `uiViewController.updateOneHandedWidthForPreview(to: oneHandedKeyboardWidth)` 바로 아래:

```swift
        uiViewController.updateLetterColumnWidthForPreview(to: letterColumnWidthMultiplier)
```

(3-3) 파일 상단 주석에 한 줄 추가:

```swift
/// - 글자 열 너비 배율은 `updateLetterColumnWidthForPreview` 메서드로 조정
```

- [ ] **Step 4: 기존 호출부 2곳 갱신**

`KeyboardHeightSettingsView.swift`와 `OneHandedKeyboardWidthSettingsView.swift`의 `PreviewKeyboardView(...)` 호출에 인자를 추가한다. 두 화면은 배율을 편집하지 않으므로 저장된 값을 그대로 넘겨 현재 동작을 유지한다.

두 파일 각각에 `@AppStorage` 프로퍼티를 추가한다(`oneHandedKeyboardWidth` 선언 아래):

```swift
    @AppStorage(UserDefaultsKeys.letterColumnWidthMultiplier, store: UserDefaultsManager.shared.storage)
    private var letterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier
```

그리고 호출부에 인자를 추가한다:

```swift
            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
```

`OneHandedKeyboardWidthSettingsView`는 두 번째 인자가 `$tempOneHandedKeyboardWidth`이므로 그 부분은 바꾸지 않는다.

- [ ] **Step 5: 앱 빌드 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

기대: BUILD SUCCEEDED

- [ ] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
        SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewKeyboardView.swift \
        SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewHangeulKeyboardViewController.swift \
        SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewEnglishKeyboardViewController.swift \
        SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift
git commit -m "feat: #112 - 미리보기에 글자 열 너비 배율 반영 경로 추가"
```

**결과:** (실행 후 기록)

---

## Task 8: 설정 화면과 진입점

슬라이더 설정 화면을 만들고 외형 설정에 연결한다.

**Files:**
- Create: `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift`
- Modify: `SYKeyboard/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `KeyboardLayoutFigure.letterColumnWidthMultiplierRange` (Task 1), `UserDefaultsKeys.letterColumnWidthMultiplier` / `DefaultValues.letterColumnWidthMultiplier` (Task 2), `PreviewKeyboardView`의 새 시그니처 (Task 7)
- Produces: `struct LetterColumnWidthSettingsView: View`

- [ ] **Step 1: 설정 화면 작성**

`SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift` 생성:

```swift
//
//  LetterColumnWidthSettingsView.swift
//  SYKeyboard
//
//  Created by 서동환 on 8/29/26.
//

import SwiftUI

import SYKeyboardCore

import FirebaseAnalytics

struct LetterColumnWidthSettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(UserDefaultsKeys.keyboardHeight, store: UserDefaultsManager.shared.storage)
    private var keyboardHeight = DefaultValues.keyboardHeight
    
    @AppStorage(UserDefaultsKeys.oneHandedKeyboardWidth, store: UserDefaultsManager.shared.storage)
    private var oneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
    
    @AppStorage(UserDefaultsKeys.letterColumnWidthMultiplier, store: UserDefaultsManager.shared.storage)
    private var letterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier
    
    @AppStorage(UserDefaultsKeys.isPredictiveTextEnabled, store: UserDefaultsManager.shared.storage)
    private var isPredictiveTextEnabled = DefaultValues.isPredictiveTextEnabled
    
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaultsManager.shared.storage)
    private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    
    @AppStorage("previewKeyboardLanguage") private var previewKeyboardLanguage: PreviewKeyboardLanguage = .hangeul
    
    @State private var previewOneHandedMode: OneHandedMode = .center
    @State private var previewKeyboardHeight: Double = DefaultValues.keyboardHeight
    @State private var tempLetterColumnWidthMultiplier: Double = DefaultValues.letterColumnWidthMultiplier
    
    // MARK: - Content
    
    var body: some View {
        NavigationStack {
            letterColumnWidthSettings
            
            Spacer()
            
            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $tempLetterColumnWidthMultiplier,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempLetterColumnWidthMultiplier = letterColumnWidthMultiplier
            updatePreviewKeyboardHeight()
        }.requestReviewOnDetailSettingsReturn()
    }
}

// MARK: - UI Components

private extension LetterColumnWidthSettingsView {
    var letterColumnWidthSettings: some View {
        VStack {
            Text("\(Int((tempLetterColumnWidthMultiplier * 100).rounded()))")
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
            Slider(value: $tempLetterColumnWidthMultiplier,
                   in: KeyboardLayoutFigure.letterColumnWidthMultiplierRange,
                   step: 0.01)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
        }
        .navigationTitle("글자 열 너비")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("취소")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tempLetterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier
                } label: {
                    Text("리셋")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    letterColumnWidthMultiplier = tempLetterColumnWidthMultiplier
                    Analytics.setUserProperty(String(format: "%.2f", letterColumnWidthMultiplier),
                                              forName: "pref_letter_column_width")
                    Analytics.logEvent("letter_column_width", parameters: [
                        "view": "LetterColumnWidthSettingsView",
                        "value": letterColumnWidthMultiplier
                    ])
                    
                    dismiss()
                } label: {
                    Text("저장")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension LetterColumnWidthSettingsView {
    func updatePreviewKeyboardHeight() {
        let suggestionBarHeight = isPredictiveTextEnabled
        ? KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing + KeyboardLayoutFigure.keyboardFrameSpacing
        : 0
        previewKeyboardHeight = keyboardHeight + suggestionBarHeight
    }
}

// MARK: - Preview

#Preview {
    LetterColumnWidthSettingsView()
}
```

- [ ] **Step 2: `AppearanceSettingsView`에 진입점 추가**

(2-1) `import SYKeyboardCore` 아래에 추가:

```swift
import HangeulKeyboardCore
```

(2-2) `isNumericKeypadEnabled` 프로퍼티 위에 추가:

```swift
    @AppStorage(UserDefaultsKeys.selectedHangeulKeyboard, store: UserDefaultsManager.shared.storage)
    private var selectedHangeulKeyboard = DefaultValues.selectedHangeulKeyboard
```

(2-3) `body`의 `NavigationLink("키보드 높이") { KeyboardHeightSettingsView() }` 블록 **바로 아래**에 추가:

```swift
        if showsLetterColumnWidthSettings {
            NavigationLink {
                LetterColumnWidthSettingsView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("글자 열 너비")
                    Text("나랏글·천지인·숫자 키패드에 적용")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
```

(2-4) `struct AppearanceSettingsView` 본문 안, `body` 아래에 계산 프로퍼티를 추가한다:

```swift
    /// 4열 격자 키보드를 하나라도 쓰는 사용자에게만 노출한다
    private var showsLetterColumnWidthSettings: Bool {
        selectedHangeulKeyboard == .naratgeul
        || selectedHangeulKeyboard == .cheonjiin
        || isNumericKeypadEnabled
    }
```

- [ ] **Step 3: 로컬라이징 문자열 추가**

`SYKeyboard/Resources/Localizable.xcstrings`의 `strings` 객체에 아래 3개 키를 추가한다. 기존 항목과 같은 형식이며, `sourceLanguage`가 `ko`이므로 한국어 키에 영어 번역만 넣는다.

```json
    "글자 열 너비" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Letter Column Width"
          }
        }
      }
    },
    "나랏글·천지인·숫자 키패드에 적용" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Applies to Naratgeul, Cheonjiin, and the numeric keypad"
          }
        }
      }
    }
```

`취소`, `리셋`, `저장`은 기존 설정 화면에서 이미 쓰고 있으므로 이미 존재하는지 확인하고, 없을 때만 추가한다:

```sh
python3 -c "
import json
d = json.load(open('SYKeyboard/Resources/Localizable.xcstrings'))
for k in ['글자 열 너비', '나랏글·천지인·숫자 키패드에 적용', '취소', '리셋', '저장']:
    print(k, k in d['strings'])
"
```

기대: 5개 키 모두 `True`

- [ ] **Step 4: 앱 빌드 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

기대: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift \
        SYKeyboard/Resources/Localizable.xcstrings
git commit -m "feat: #112 - 글자 열 너비 설정 화면 추가"
```

**결과:** (실행 후 기록)

---

## Task 9: 전체 검증

전체 테스트와 세 extension 빌드를 확인하고, 자동 검증으로 판정할 수 없는 항목을 기록한다.

**Files:**
- Modify: `docs/superpowers/plans/2026-08-29-four-by-four-letter-column-width.md` (이 문서의 "결과" 줄)

- [ ] **Step 1: 전체 테스트 실행**

`-only-testing`과 code coverage 옵션이 남아 있지 않은지 확인하고 실행한다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

기대: 전체 통과. 특히 아래 기존 suite가 수정 없이 통과해야 한다.
- `KeyboardModifierLayoutTests`
- `CheonjiinBottomSpaceLayoutTests`
- `NumericBottomSpaceLayoutTests`
- `UserDefaultsContractTests`

- [ ] **Step 2: 세 extension 빌드 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

기대: 3개 모두 BUILD SUCCEEDED

- [ ] **Step 3: 변경 범위 확인**

```sh
git status --short
git diff --stat develop...HEAD
```

기대: 이 계획의 File Structure 표에 있는 파일만 변경되어 있다. 사용자가 만든 무관한 변경이 섞여 있으면 되돌리지 않고 사용자에게 알린다.

- [ ] **Step 4: 수동 확인 항목을 미확인으로 기록**

아래 항목은 자동 테스트로 판정할 수 없다. 실제 기기에서 확인하기 전에는 **완료로 표시하지 않는다.** 확인했다면 결과를, 확인하지 못했다면 차단 사유를 이 문서에 적는다.

- [ ] 실제 입력 앱에서 기본값(100)이 기존 배치와 동일한가
- [ ] 배율을 올렸을 때 나랏글·천지인·숫자 키패드의 실제 화면
- [ ] 한 손 키보드 모드에서의 레이아웃
- [ ] 가로 모드에서의 레이아웃
- [ ] 상한(120)에서 삭제·스페이스·리턴·전환 버튼의 터치 정확도. 한 손 키보드 320pt 기준 32pt로 HIG 최소 44pt보다 작다
- [ ] 좁은 기능 열에서 `!#1` 드래그 시 키보드 선택 오버레이 취소 영역 동작
- [ ] 설정 화면 미리보기에서 `!#1`을 드래그해 숫자 키패드로 전환한 뒤 슬라이더가 반영되는지
- [ ] 한영 통합 키보드에서 한영 전환 버튼과 지구본 버튼의 폭

- [ ] **Step 5: 이 문서의 "결과" 줄 갱신 후 커밋**

각 Task의 "결과" 줄에 실제 실행한 명령, 사용한 시뮬레이터 기기명·OS 버전, 테스트 개수와 통과 여부를 적는다.

```bash
git add docs/superpowers/plans/2026-08-29-four-by-four-letter-column-width.md
git commit -m "docs: #112 - 구현 계획에 검증 결과 반영"
```

**결과:** (실행 후 기록)

---

## 미해결 항목

- 이슈 #112 본문과 체크리스트에 숫자 키패드가 빠져 있다. 구현 착수 전 이슈를 갱신하거나 PR 설명에 범위 확대를 명시할지 사용자에게 확인이 필요하다.
- 상한 `1.20`에서 기능 열이 HIG 최소 터치 타깃보다 좁아진다. Task 9 Step 4의 실기 확인 결과에 따라 상한 조정 여부를 별도로 논의한다.
