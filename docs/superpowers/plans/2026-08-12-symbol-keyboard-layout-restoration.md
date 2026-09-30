# UIKeyboardType별 기호 키보드 레이아웃 복원 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GitHub Issue #108에 따라 기본·URL·이메일·웹 검색 입력 환경별 기호 키 배열과 하단 행을 복원한다.

**Architecture:** `SymbolKeyboardMode`가 `UIKeyboardType?` 매핑과 키 배열을 소유하고, 한글·영문 ViewController가 같은 매핑을 `SymbolKeyboardView`에 전달한다. `SymbolKeyboardView`는 새 인스턴스를 만들지 않고 기존 버튼의 키와 하단 arranged subview 표시 상태만 전환한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+

## Global Constraints

- iOS 16+ 지원과 현재 UIKit 키보드 구조를 유지한다.
- 커밋 `7bdf59fd` 전체를 revert하지 않는다.
- 통합 이후 추가된 Smart Punctuation, 닫는 따옴표, 한 손 키보드 overlay와 Auto Layout 충돌 방지 변경을 유지한다.
- 한글 Processor/Automata, 입력 buffer, suggestion 엔진, UserDefaults, Firebase/AdMob 설정은 변경하지 않는다.
- 버튼 객체와 입력 action 등록 수명은 유지하고 모드 전환 시 키와 `isHidden`만 갱신한다.
- 숨김 가능한 하단 버튼의 nonzero 너비 제약은 priority `999`를 사용한다.
- 새 production 동작은 테스트 실패를 먼저 확인한 뒤 최소 구현한다.
- 각 task는 실제 작업과 검증 결과를 이 문서에 기록한 직후 하나의 커밋으로 남긴다.

---

### Task 1: UIKeyboardType 매핑과 모드별 키 배열 복원

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `SYKeyboardTests/Utils/KeyboardSymbolInputPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md`

**Interfaces:**
- Produces: `public enum SymbolKeyboardMode: Equatable { case default, URL, emailAddress, webSearch }`
- Produces: `public init(keyboardType: UIKeyboardType?)`
- Produces: internal `var keyList: [[[[String]]]]`
- Consumes: UIKit `UIKeyboardType`와 기존 `SymbolKeyboardView` 버튼 구조

- [x] **Step 1: 모드 매핑과 키 배열을 요구하는 실패 테스트 추가**

`KeyboardSymbolInputPolicyTests`에 다음 테스트를 추가한다. 배열 기대값은
`7bdf59fd^`의 사용자 표시 계약에서 직접 작성하며 production helper로 계산하지
않는다.

```swift
@Test("UIKeyboardType은 대응하는 기호 키보드 모드로 매핑")
func testUIKeyboardType별기호키보드모드() {
    #expect(SymbolKeyboardMode(keyboardType: nil) == .default)
    #expect(SymbolKeyboardMode(keyboardType: .default) == .default)
    #expect(SymbolKeyboardMode(keyboardType: .numbersAndPunctuation) == .default)
    #expect(SymbolKeyboardMode(keyboardType: .URL) == .URL)
    #expect(SymbolKeyboardMode(keyboardType: .emailAddress) == .emailAddress)
    #expect(SymbolKeyboardMode(keyboardType: .webSearch) == .webSearch)
    #expect(SymbolKeyboardMode(keyboardType: .twitter) == .default)
}

@Test("기호 키보드 모드는 일반과 Shift 키 배열을 제공")
func test기호키보드모드별키배열() {
    #expect(SymbolKeyboardMode.default.keyList[0][1].map { $0.first ?? "" } ==
            ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
    #expect(SymbolKeyboardMode.URL.keyList[0][2].map { $0.first ?? "" } ==
            ["_", ":", "-", "+", ""])
    #expect(SymbolKeyboardMode.emailAddress.keyList[0][2].map { $0.first ?? "" } ==
            [".", "_", "-", "+", ""])
    #expect(SymbolKeyboardMode.webSearch.keyList == SymbolKeyboardMode.default.keyList)
}
```

- [x] **Step 2: 테스트가 기능 부재로 실패하는지 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests
```

Expected: `SymbolKeyboardMode`를 찾을 수 없어 test build가 실패한다. 문법 오류나
Simulator 오류는 RED로 인정하지 않는다.

- [x] **Step 3: SymbolKeyboardMode 최소 구현 추가**

다음 공개 모드와 매핑을 추가한다. `keyList`에는 아래 네 모드의 일반·Shift 배열을
완전하게 작성하고 기본 배열의 큰따옴표는 현재 계약인 `”`를 사용한다.

```swift
import UIKit

public enum SymbolKeyboardMode: Equatable {
    case `default`
    case URL
    case emailAddress
    case webSearch

    public init(keyboardType: UIKeyboardType?) {
        switch keyboardType {
        case .URL:
            self = .URL
        case .emailAddress:
            self = .emailAddress
        case .webSearch:
            self = .webSearch
        default:
            self = .default
        }
    }

    var keyList: [[[[String]]]] {
        switch self {
        case .default, .webSearch:
            return [
                [
                    [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"]],
                    [["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["”"]],
                    [["."], [","], ["?"], ["!"], ["’"]]
                ],
                [
                    [["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="]],
                    [["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"]],
                    [["."], [","], ["?"], ["!"], ["’"]]
                ]
            ]
        case .URL:
            return [
                [
                    [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"]],
                    [["@"], ["&"], ["%"], ["?"], [","], ["="], ["["], ["]"], [], []],
                    [["_"], [":"], ["-"], ["+"], []]
                ],
                [
                    [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"]],
                    [["*"], ["$"], ["#"], ["!"], ["’"], ["^"], ["["], ["]"], [], []],
                    [["~"], [";"], ["("], [")"], []]
                ]
            ]
        case .emailAddress:
            return [
                [
                    [["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"]],
                    [["$"], ["!"], ["~"], ["&"], ["="], ["#"], ["["], ["]"], [], []],
                    [["."], ["_"], ["-"], ["+"], []]
                ],
                [
                    [["’"], ["|"], ["{"], ["}"], ["?"], ["%"], ["^"], ["*"], ["/"], ["’"]],
                    [["$"], ["!"], ["~"], ["&"], ["="], ["#"], ["["], ["]"], [], []],
                    [["."], ["_"], ["-"], ["+"], []]
                ]
            ]
        }
    }
}
```

`SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboard`와 `SYKeyboardCore` target용
`Modules` membership exception 목록에서 `TenkeyKeyboardMode.swift` 인접 위치에
다음 경로를 각각 추가한다.

```text
SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift,
```

- [x] **Step 4: 관련 테스트 통과 확인**

Step 2와 같은 명령을 실행한다. Expected: `KeyboardSymbolInputPolicyTests` 전체 PASS.

- [x] **Step 5: 결과 기록 및 커밋**

RED/GREEN 명령, exit code, 고유 테스트 개수와 xcresult 경로를 이 task 아래
`Result`에 기록한 뒤 다음 파일만 커밋한다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/KeyboardSymbolInputPolicyTests.swift \
  docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md
git commit -m "feat: #108 - UIKeyboardType별 기호 배열 복원"
```

**Result:**

- RED: iPhone 13 mini / iOS 16.0에서 test build가
  `Cannot find 'SymbolKeyboardMode' in scope`로 실패했다(`xcodebuild` exit 65).
  xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_21-55-43-+0900.xcresult`다.
- GREEN: 같은 destination에서 `KeyboardSymbolInputPolicyTests` 고유 테스트 6개가
  모두 통과했다(`xcodebuild` exit 0). xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_21-56-32-+0900.xcresult`다.

### Task 2: 기호 키보드의 모드별 키와 하단 행 전환 복원

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift`
- Modify: `SYKeyboardTests/Utils/KeyboardSymbolInputPolicyTests.swift`
- Modify: `docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md`

**Interfaces:**
- Consumes: Task 1의 `SymbolKeyboardMode`와 `keyList`
- Produces: `var currentSymbolKeyboardMode: SymbolKeyboardMode { get set }`
- Produces: `spaceButtonHStackView`, `atButton`, `periodButton`, `slashButton`, `dotComButton`
- Produces: 모드별 `updateLayoutToDefault/URL/EmailAddress/WebSearch()`

- [x] **Step 1: 실제 SymbolKeyboardView 전환을 요구하는 실패 테스트 추가**

테스트 helper는 production 결과를 계산하지 않고 현재 버튼에 표시된 값만 읽는다.

```swift
private extension SymbolKeyboardView {
    var rowPrimaryKeyValues: [String] {
        primaryButtonList
            .compactMap { $0 as? PrimaryKeyButton }
            .prefix(25)
            .map { $0.type.primaryKeyList.first ?? "" }
    }
}
```

다음 테스트를 `KeyboardSymbolInputPolicyTests`에 추가한다.

```swift
@MainActor
@Test("URL 기호 모드는 전용 키 배열과 하단 키를 표시")
func testURL기호키보드레이아웃() {
    let view = SymbolKeyboardView()
    view.isShifted = true
    view.currentSymbolKeyboardMode = .URL

    #expect(view.isShifted == false)
    #expect(Array(view.rowPrimaryKeyValues.suffix(5)) == ["_", ":", "-", "+", ""])
    #expect(view.spaceButton.isHidden)
    #expect(view.atButton.isHidden)
    #expect(view.periodButton.isHidden == false)
    #expect(view.slashButton.isHidden == false)
    #expect(view.dotComButton.isHidden == false)
}

@MainActor
@Test("이메일 기호 모드는 전용 키 배열과 스페이스 골뱅이 마침표를 표시")
func test이메일기호키보드레이아웃() {
    let view = SymbolKeyboardView()
    view.currentSymbolKeyboardMode = .emailAddress

    #expect(Array(view.rowPrimaryKeyValues.suffix(5)) == [".", "_", "-", "+", ""])
    #expect(view.spaceButton.isHidden == false)
    #expect(view.atButton.isHidden == false)
    #expect(view.periodButton.isHidden == false)
    #expect(view.slashButton.isHidden)
    #expect(view.dotComButton.isHidden)
}

@MainActor
@Test("웹 검색 기호 모드는 기본 배열과 스페이스 마침표를 표시")
func test웹검색기호키보드레이아웃() {
    let view = SymbolKeyboardView()
    view.currentSymbolKeyboardMode = .webSearch

    #expect(Array(view.rowPrimaryKeyValues[10..<20]) ==
            ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
    #expect(view.spaceButton.isHidden == false)
    #expect(view.atButton.isHidden)
    #expect(view.periodButton.isHidden == false)
    #expect(view.slashButton.isHidden)
    #expect(view.dotComButton.isHidden)
}
```

- [x] **Step 2: 테스트가 모드 전환 API 부재로 실패하는지 확인**

Task 1과 같은 only-testing 명령을 실행한다. Expected:
`currentSymbolKeyboardMode`, `atButton`, `periodButton`, `slashButton` 또는
`dotComButton` 부재로 test build 실패.

- [x] **Step 3: 프로토콜과 SymbolKeyboardView 최소 구현**

`SymbolKeyboardLayoutProvider`에 모드, 하단 행과 하단 버튼 요구사항을 복원하고
다음 모드 전환을 제공한다. 기존 `updateShiftButton(to:)` 이름은 유지한다.

```swift
func updateLayoutForCurrentSymbolKeyboardMode(oldMode: SymbolKeyboardMode) {
    guard oldMode != currentSymbolKeyboardMode else { return }
    switch currentSymbolKeyboardMode {
    case .default:
        updateLayoutToDefault()
    case .URL:
        updateLayoutToURL()
    case .emailAddress:
        updateLayoutToEmailAddress()
    case .webSearch:
        updateLayoutToWebSearch()
    }
}

func updateLayoutToDefault() {
    spaceButton.isHidden = false
    atButton.isHidden = true
    periodButton.isHidden = true
    slashButton.isHidden = true
    dotComButton.isHidden = true
    initShiftButton()
}

func updateLayoutToURL() {
    spaceButton.isHidden = true
    atButton.isHidden = true
    periodButton.isHidden = false
    slashButton.isHidden = false
    dotComButton.isHidden = false
    updatePeriodButtonWidthConstraint(multiplier: nil)
    initShiftButton()
}

func updateLayoutToEmailAddress() {
    spaceButton.isHidden = false
    atButton.isHidden = false
    periodButton.isHidden = false
    slashButton.isHidden = true
    dotComButton.isHidden = true
    updatePeriodButtonWidthConstraint(multiplier: 0.25)
    initShiftButton()
}

func updateLayoutToWebSearch() {
    spaceButton.isHidden = false
    atButton.isHidden = true
    periodButton.isHidden = false
    slashButton.isHidden = true
    dotComButton.isHidden = true
    updatePeriodButtonWidthConstraint(multiplier: 0.20)
    initShiftButton()
}
```

`SymbolKeyboardView`는 다음 원칙으로 현재 코드를 수정한다.

```swift
var currentSymbolKeyboardMode: SymbolKeyboardMode = .default {
    didSet(oldMode) {
        updateLayoutForCurrentSymbolKeyboardMode(oldMode: oldMode)
        isShifted = false
    }
}

private lazy var firstRowPrimaryKeyButtonList = currentSymbolKeyboardMode.keyList[0][0].map {
    PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
}
private lazy var secondRowPrimaryKeyButtonList = currentSymbolKeyboardMode.keyList[0][1].map {
    PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
}
private lazy var thirdRowPrimaryKeyButtonList = currentSymbolKeyboardMode.keyList[0][2].map {
    PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
}
```

- `primaryButtonList`와 `totalTextInterableButtonList`에 하단 다섯 버튼을 포함한다.
- `spaceButtonHStackView`에 하단 다섯 버튼을 arranged subview로 추가한다.
- 현재 overlay 위치·크기 제약은 변경하지 않는다.
- `spaceButtonHStackView`는 fourth row 너비의 `0.5`를 사용한다.
- `atButton`은 `0.25`, `periodButton` 기본 제약은 `0.2`, `slashButton`과
  `dotComButton`은 각각 `1.0 / 3.0`을 사용한다.
- 숨김 가능한 네 특수 키의 너비 제약과 갱신되는 period 제약은 priority `999`를
  사용한다.
- `updateKeyButtonList()`는 고정 `keyList` 대신
  `currentSymbolKeyboardMode.keyList`를 읽는다.
- 초기화 마지막에 `updateLayoutToDefault()`를 호출한다.

- [x] **Step 4: 관련 테스트와 Auto Layout 로그 확인**

Task 1과 같은 only-testing 명령을 실행한다. Expected: 관련 테스트 전체 PASS이며
테스트 로그에 `Unable to simultaneously satisfy constraints`가 없다.

- [x] **Step 5: 결과 기록 및 커밋**

RED/GREEN 결과와 xcresult 경로를 기록한 뒤 다음 파일만 커밋한다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift \
  SYKeyboardTests/Utils/KeyboardSymbolInputPolicyTests.swift \
  docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md
git commit -m "feat: #108 - 기호 키보드 모드별 레이아웃 복원"
```

**Result:**

- RED: iPhone 13 mini / iOS 16.0에서 test build가 `SymbolKeyboardView`의
  `currentSymbolKeyboardMode`, `atButton`, `periodButton`, `slashButton`,
  `dotComButton`을 찾을 수 없어 실패했다(`xcodebuild` exit 65). xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_21-58-47-+0900.xcresult`다.
- GREEN: 같은 destination에서 `KeyboardSymbolInputPolicyTests` 고유 테스트
  10개가 모두 통과했다(`xcodebuild` exit 0). xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_22-00-22-+0900.xcresult`다.
- GREEN 실행 출력에 `Unable to simultaneously satisfy constraints`가 없었고,
  `git diff --check`도 통과했다.

### Task 3: 한글·영문 키보드 연결과 전체 회귀 검증

**Files:**
- Modify: `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
- Modify: `docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md`

**Interfaces:**
- Consumes: `SymbolKeyboardMode.init(keyboardType:)`
- Consumes: `symbolKeyboardView.currentSymbolKeyboardMode`
- Preserves: 각 ViewController의 기존 primary/TenKey 선택 switch

- [x] **Step 1: 두 ViewController가 공통 모드 매핑을 사용하도록 연결**

두 `updateKeyboardType()`의 guard 다음, 기존 switch 앞에 같은 코드를 추가한다.
모드 매핑 자체는 Task 1에서 RED/GREEN 검증한 production policy를 사용하며 별도
synthetic controller mock은 만들지 않는다.

```swift
let symbolKeyboardMode = SymbolKeyboardMode(keyboardType: textDocumentProxy.keyboardType)
symbolKeyboardView.currentSymbolKeyboardMode = symbolKeyboardMode
```

- [x] **Step 2: 관련 정책·뷰 테스트 재실행**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSymbolInputPolicyTests \
  -only-testing:SYKeyboardTests/KeyboardSmartInputPolicyTests
```

Expected: 기호 레이아웃과 Smart Punctuation 관련 테스트 전체 PASS.

- [x] **Step 3: 전체 테스트 실행**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: exit 0, 실패 0. 고유 테스트 개수와 xcresult 경로를 기록한다.

- [x] **Step 4: 앱과 두 키보드 extension 빌드**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 세 scheme 모두 exit 0.

- [x] **Step 5: 실제 입력 화면 smoke test 또는 미확인 경로 기록**

실제 입력 앱에서 한글·영문 키보드 각각 다음을 확인한다.

- 기본 필드: 기본 배열, 스페이스만 표시
- URL 필드: URL 배열, `.`, `/`, `.com` 표시
- 이메일 필드: 이메일 배열, 스페이스, `@`, `.` 표시
- 웹 검색 필드: 기본 배열, 스페이스, `.` 표시
- 각 모드의 Shift 배열과 모드 전환 후 일반 상태 초기화
- 따옴표 입력의 Smart Punctuation 동작
- 전환 중 Auto Layout 충돌 로그 부재

키보드 extension 활성화나 host 앱 상태로 관찰하지 못하면 차단 경로를 정확히
기록하고 완료 또는 production-ready로 표현하지 않는다.

- [x] **Step 6: 변경 범위 점검, 결과 기록 및 커밋**

```sh
git diff --check
git status --short
git diff --stat develop...HEAD
```

전체 검증 결과와 수동 확인 상태를 기록한 뒤 controller와 계획 문서만 커밋한다.

```sh
git add \
  Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift \
  docs/superpowers/plans/2026-08-12-symbol-keyboard-layout-restoration.md
git commit -m "feat: #108 - 한글·영문 기호 레이아웃 모드 연결"
```

**Result:**

- 관련 테스트: iPhone 13 mini / iOS 16.0에서
  `KeyboardSymbolInputPolicyTests` 10개와 `KeyboardSmartInputPolicyTests` 13개,
  고유 테스트 23개가 모두 통과했다(`xcodebuild` exit 0). xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_22-04-46-+0900.xcresult`다.
- 전체 테스트: 같은 destination에서 총 383개가 통과했고 실패·스킵은 0개다
  (`xcodebuild` exit 0). `xcresulttool` summary에서도 `result: Passed`,
  `totalTestCount: 383`, `failedTests: 0`, `skippedTests: 0`을 확인했다.
  xcresult는
  `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.12_22-06-03-+0900.xcresult`다.
- 빌드: iPhone 13 mini / iOS 16.0에서 `SYKeyboard`, `HangeulKeyboard`,
  `EnglishKeyboard` scheme이 모두 성공했다(각 `xcodebuild` exit 0).
  `SYKeyboard` 빌드에는 외부 `FBAudienceNetwork` 정적 라이브러리의 누락된
  module cache 관련 디버그 정보 경고가 있었지만 빌드는 성공했다.
- 실제 입력 화면: XcodeBuildMCP에서 사용 가능한 Simulator 51개가 모두
  `Shutdown` 상태였다. `ios-debugger-agent` 지침에 따라 요청 없이 부팅하지 않아
  한글·영문 extension의 기본/URL/이메일/웹 검색 필드별 표시, Shift 조작,
  Smart Punctuation 입력, 런타임 Auto Layout 로그는 이번 실행에서 관찰하지
  못했다. 따라서 실제 화면 검증과 production-ready 판정은 미완료 상태다.
- 변경 범위: `git diff --check`가 통과했고, 커밋 전 작업 트리에는 두
  ViewController와 이 계획 문서만 수정된 상태임을 확인했다.
