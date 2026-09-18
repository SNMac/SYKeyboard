# 두벌식·쿼티 숫자 행 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 두벌식·쿼티 자판 맨 윗줄에 숫자 행(1~0)을 표시하는 설정을 추가하고, 숫자 행이 켜져 있으면 길게 누르기 보조 입력을 대문자·쌍자음으로 바꾼다.

**Architecture:** 높이 계산은 `KeyboardHeightPolicy`에 숫자 행 높이(세로 46.5 / 가로 35)를 더하는 규칙으로 넣고, `BaseKeyboardViewController.setKeyboardHeight()`가 그 값을 프레임 높이와 주 키보드 뷰에 함께 반영한다. 숫자 행 UI와 보조 키 교체는 두벌식·쿼티가 공유하는 `StandardKeyboardView` 안에서 끝내고, 보조 키 목록 계산은 `KeyboardTextInteractionPolicy`의 순수 함수로 둔다. 4x4·기호·숫자·텐키 자판은 코드 변경 없이 같은 `keyboardHStackView` 높이 안에서 늘어난다.

**Tech Stack:** Swift 5, UIKit(키보드 extension), SwiftUI(설정 앱), Swift Testing, App Group `UserDefaults`

**Spec:** `docs/superpowers/specs/2026-09-18-number-row-design.md`

## Global Constraints

- 작업 브랜치 `feat/#138-number-row`, 워크트리 `.claude/worktrees/feat-138-number-row`. push·PR 생성은 사용자 명령이 있을 때만 한다.
- 설정 키 `showsNumberRow`, 기본값 `false`. 꺼져 있으면 기존 높이·레이아웃·길게 누르기 동작이 바뀌지 않아야 한다.
- 세로 숫자 행 높이 `46.5` = `(190 - 4) / 4`, 가로 숫자 행 높이 `35` = `(188 - 44 - 4) / 4`. `keyboardHeight`와 자동완성 바 표시 여부에 따라 바뀌지 않는다.
- 숫자 행은 설정이 켜져 있고 extension에 두벌식 또는 쿼티 자판이 있을 때만 붙는다. 세로·가로 모두 해당한다.
- 나랏글·천지인, `LongPressAction`의 `repeatInput`·`disabled` 동작은 바꾸지 않는다. `LongPressAction` raw value는 바꾸지 않는다.
- `Modules/`에 새 파일을 만들지 않는다(만들면 `project.pbxproj` 예외 목록 수정 필요). 이 계획은 기존 파일만 수정한다.
- 테스트는 Swift Testing(`@Suite`, `@Test`, `#expect`)을 쓰고 production 진입점을 호출한다.
- 검증 기준 시뮬레이터 `iPhone 13 mini / iOS 18.6`. extension scheme 빌드 뒤 `.xcscheme`의 `RemotePath`만 바뀌었으면 `git checkout --`으로 되돌린다.
- 영어 문자열 인용은 둥근 큰따옴표(“”)를 쓴다.
- 각 Task가 끝나면 이 문서의 체크박스와 실제 결과(테스트 개수, 빌드 결과, 확인하지 못한 항목)를 갱신하고 코드·테스트·문서를 한 커밋으로 남긴다. 커밋 메시지 형식은 `type: #138 - subject`이며 끝에 `Co-Authored-By` 줄을 붙인다.

### 공통 명령

단일 suite 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/<SuiteTypeName>
```

`The test runner timed out while preparing to run tests.`로 실패하면 붙여넣기 권한 알림 문제다(CLAUDE.md 참고). 코드 실패로 기록하지 말고 알림에 응답한 뒤 다시 실행한다.

---

### Task 1: 숫자 행 설정 키와 기본값

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` (외형 설정 섹션, `keyboardHeight` 아래)
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift` (외형 설정 섹션, `keyboardHeight` 아래)
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` (외형 설정 섹션, `keyboardHeight` 아래)
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Produces: `UserDefaultsKeys.showsNumberRow: String`, `DefaultValues.showsNumberRow: Bool`, `UserDefaultsManager.shared.showsNumberRow: Bool`

**결과:** (최초 시도 시점) 이 워크트리에는 `Common/Firebase/Debug/GoogleService-Info.plist`가 없어 4개 scheme 모두 `xcodebuild test`가 Firebase 스크립트 단계에서 실패했고, 대신 `SYKeyboardCore` scheme 빌드로 세 파일의 컴파일만 확인했다. **차단 해소 후 재검증:** 사용자가 승인한 gitignored symlink(`Common/Firebase/{Debug,Release}/GoogleService-Info.plist`, `SYKeyboard/Resources/Configs/Secrets.xcconfig` → 메인 체크아웃 실제 파일)가 워크트리에 추가된 뒤 다시 검증했다. RED: `git checkout e56c1eaf -- Modules/SYKeyboardCore/Storage/{UserDefaultsKeys,DefaultValues,UserDefaultsManager}.swift` 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -only-testing:SYKeyboardTests/UserDefaultsContractTests` 실행 → `type 'UserDefaultsKeys' has no member 'showsNumberRow'` 등 예상한 컴파일 오류로 `** TEST FAILED **`. `git checkout HEAD -- <같은 세 파일>`로 복원, `git status --short` 클린 확인. GREEN: 동일 명령 + `-parallel-testing-enabled NO` + `GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'`(symlink된 `Secrets.xcconfig` placeholder가 `ADMOB_APP_ID`라는 잘못된 키를 정의해 실제 필요한 `GADApplicationIdentifier`가 비어 `GADInvalidInitializationException`으로 테스트 호스트가 부팅 전 크래시하는 문제를 커맨드라인 빌드 설정 override로 우회, symlink 자체는 손대지 않음) → `Test run with 17 tests in 1 suite passed after 0.083 seconds.`, `showsNumberRow` 테스트 포함 17/17 통과, `** TEST SUCCEEDED **`. `git status --short` 재확인 클린(symlink·`.xcscheme` 변경 없음). Step 2·4 모두 체크. 남은 참고사항: `GADApplicationIdentifier` override는 커맨드라인 한정이라 이후 태스크의 `SYKeyboard`/`HangeulKeyboard`/`EnglishKeyboard`/`HangeulEnglishKeyboard` scheme 테스트도 동일 플래그가 필요하다(또는 placeholder `Secrets.xcconfig`의 키 이름 수정 필요, 이번 태스크 범위 밖).

- [x] **Step 1: 실패하는 계약 테스트 작성**

`UserDefaultsContractTests`의 기존 `testNaratgeulDotLabelDefaultFallbackAndKey` 아래에 추가한다.

```swift
    @Test("숫자 행 표시는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testShowsNumberRowDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.showsNumberRow
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "showsNumberRow")
        #expect(DefaultValues.showsNumberRow == false)
        #expect(UserDefaultsManager.shared.showsNumberRow == false)
    }
```

- [x] **Step 2: 테스트가 컴파일 실패하는지 확인**

Run: 공통 명령, `<SuiteTypeName>` = `UserDefaultsContractTests`
Expected: `type 'UserDefaultsKeys' has no member 'showsNumberRow'` 컴파일 오류

- [x] **Step 3: 키·기본값·프로퍼티 추가**

`UserDefaultsKeys.swift`, `keyboardHeight` 줄 아래:

```swift
    /// 두벌식·쿼티 숫자 행 표시
    public static let showsNumberRow = "showsNumberRow"
```

`DefaultValues.swift`, `keyboardHeight` 줄 아래:

```swift
    /// 두벌식·쿼티 숫자 행 표시 여부 기본값
    public static let showsNumberRow: Bool = false
```

`UserDefaultsManager.swift`, `keyboardHeight` 프로퍼티 아래:

```swift
    /// 두벌식·쿼티 숫자 행 표시
    @UserDefaultsWrapper(key: UserDefaultsKeys.showsNumberRow, defaultValue: DefaultValues.showsNumberRow)
    public var showsNumberRow: Bool
```

- [x] **Step 4: 테스트 통과 확인**

Run: 공통 명령, `UserDefaultsContractTests`
Expected: `** TEST SUCCEEDED **`, 새 테스트 포함 전체 통과

- [x] **Step 5: 계획 문서 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift Modules/SYKeyboardCore/Storage/DefaultValues.swift Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift SYKeyboardTests/Storage/UserDefaultsContractTests.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 숫자 행 표시 설정 키와 기본값 추가"
```

---

### Task 2: 숫자 행 높이 정책

**결과:** `xcodebuild test -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' -parallel-testing-enabled NO` → `** TEST SUCCEEDED **`, `KeyboardHeightPolicyTests` 16개(기존 9 + 신규 7) 전부 통과. `xcodebuild build -scheme SYKeyboard ...`(HangeulKeyboard/EnglishKeyboard/HangeulEnglishKeyboard extension 포함) → `** BUILD SUCCEEDED **`, 변경 파일에서 새 경고 없음. 별도 extension별 build는 실행하지 않음(SYKeyboard scheme build가 세 extension을 임베드 빌드로 이미 포함).

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift` (`landscapeKeyboardHeight` 위)
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardHeightPolicy.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift:78` (슬라이더 범위)
- Test: `SYKeyboardTests/Utils/KeyboardHeightPolicyTests.swift`

**Interfaces:**
- Produces:
  - `KeyboardLayoutFigure.keyboardHeightRange: ClosedRange<Double>` (public, `190...290`)
  - `public enum KeyboardHeightPolicy` (접근 수준을 internal → public으로 올림. 앱 미리보기가 사용)
  - `KeyboardHeightPolicy.portraitNumberRowHeight: CGFloat` (46.5), `landscapeNumberRowHeight: CGFloat` (35)
  - `KeyboardHeightPolicy.numberRowHeight(isEnabled: Bool, primaryKeyboards: [SYKeyboardType], isPortrait: Bool) -> CGFloat` (public)
  - `KeyboardHeightPolicy.height(keyboardSettingsHeight:landscapeKeyboardHeight:suggestionBarHeight:isSuggestionBarVisible:isPortrait:numberRowHeight:)` — 마지막 인자 `numberRowHeight: CGFloat = 0` 추가, 기존 호출은 그대로 컴파일된다

- [x] **Step 1: 실패하는 테스트 작성**

`KeyboardHeightPolicyTests`의 마지막 테스트 뒤에 추가한다.

```swift
    // MARK: - 숫자 행

    @Test("키보드 높이 설정 범위는 190...290")
    func test키보드높이범위() {
        #expect(KeyboardLayoutFigure.keyboardHeightRange == 190...290)
    }

    @Test("숫자 행 높이는 세로 46.5, 가로 35로 고정")
    func test숫자행높이_고정값() {
        #expect(KeyboardHeightPolicy.portraitNumberRowHeight == 46.5)
        #expect(KeyboardHeightPolicy.landscapeNumberRowHeight == 35)
    }

    @Test("숫자 행 설정이 꺼져 있으면 두벌식·쿼티여도 숫자 행 높이는 0")
    func test숫자행_설정꺼짐() {
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: false, primaryKeyboards: [.qwerty], isPortrait: true) == 0)
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: false, primaryKeyboards: [.dubeolsik], isPortrait: false) == 0)
    }

    @Test("숫자 행 설정이 켜져 있어도 두벌식·쿼티가 없으면 0")
    func test숫자행_4x4만있음() {
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, primaryKeyboards: [.naratgeul], isPortrait: true) == 0)
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, primaryKeyboards: [.cheonjiin], isPortrait: false) == 0)
    }

    @Test("두벌식·쿼티가 하나라도 있으면 방향별 숫자 행 높이를 반환")
    func test숫자행_방향별높이() {
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, primaryKeyboards: [.dubeolsik], isPortrait: true) == 46.5)
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, primaryKeyboards: [.qwerty], isPortrait: false) == 35)
        // 한영 통합: 4x4 한글 + 쿼티
        #expect(KeyboardHeightPolicy.numberRowHeight(isEnabled: true, primaryKeyboards: [.naratgeul, .qwerty], isPortrait: true) == 46.5)
    }

    @Test("세로 화면 숫자 행은 설정 높이와 자동완성 바 위에 더함")
    func test세로화면_숫자행높이계산() {
        let height = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: true,
            numberRowHeight: 46.5
        )

        #expect(height.keyboardViewHeight == 330.5)
        #expect(height.keyboardHStackViewHeight == 286.5)
    }

    @Test("가로 화면 숫자 행은 고정 높이 188 위에 더하고 자동완성 바는 기존처럼 뺌")
    func test가로화면_숫자행높이계산() {
        let visible = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: true,
            isPortrait: false,
            numberRowHeight: 35
        )
        #expect(visible.keyboardViewHeight == 223)
        #expect(visible.keyboardHStackViewHeight == 179)

        let hidden = KeyboardHeightPolicy.height(
            keyboardSettingsHeight: 240,
            landscapeKeyboardHeight: 188,
            suggestionBarHeight: 44,
            isSuggestionBarVisible: false,
            isPortrait: false,
            numberRowHeight: 35
        )
        #expect(hidden.keyboardViewHeight == 223)
        #expect(hidden.keyboardHStackViewHeight == 223)
    }
```

- [x] **Step 2: 테스트가 컴파일 실패하는지 확인**

Run: 공통 명령, `KeyboardHeightPolicyTests`
Expected: `type 'KeyboardLayoutFigure' has no member 'keyboardHeightRange'` 등 컴파일 오류

- [x] **Step 3: 범위 상수 추가**

`KeyboardFigure.swift`, `/// 키보드 가로모드 높이` 줄 위:

```swift
    /// 키보드 높이 설정 슬라이더 범위
    public static let keyboardHeightRange: ClosedRange<Double> = 190...290
```

- [x] **Step 4: 높이 정책 구현**

`KeyboardHeightPolicy.swift`에서 `enum KeyboardHeightPolicy {`를 `public enum KeyboardHeightPolicy {`로 바꾸고, `struct Height` 위에 추가한다.

```swift
    /// 세로 모드 숫자 행 높이. 키보드 높이 설정 최소값일 때의 글자 행 높이와 같다
    public static let portraitNumberRowHeight: CGFloat = letterRowHeight(
        keyboardAreaHeight: CGFloat(KeyboardLayoutFigure.keyboardHeightRange.lowerBound)
    )
    /// 가로 모드 숫자 행 높이. 자동완성 바가 보일 때의 가로 글자 행 높이와 같다.
    /// 바가 숨겨져 글자 행이 커져도 숫자 행은 이 값을 유지한다
    public static let landscapeNumberRowHeight: CGFloat = letterRowHeight(
        keyboardAreaHeight: KeyboardLayoutFigure.landscapeKeyboardHeight
        - KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing
    )

    /// 키 영역 높이에서 프레임 여백을 빼고 4행으로 나눈 글자 행 높이
    static func letterRowHeight(keyboardAreaHeight: CGFloat) -> CGFloat {
        (keyboardAreaHeight - KeyboardLayoutFigure.keyboardFrameSpacing) / 4
    }

    /// 주 키보드 구성에 맞는 숫자 행 높이. 숫자 행이 없으면 0을 반환한다
    /// - Parameters:
    ///   - isEnabled: 숫자 행 설정 여부
    ///   - primaryKeyboards: extension의 주 키보드 종류 목록
    ///   - isPortrait: 세로 화면 여부
    public static func numberRowHeight(
        isEnabled: Bool,
        primaryKeyboards: [SYKeyboardType],
        isPortrait: Bool
    ) -> CGFloat {
        let hasNumberRowKeyboard = primaryKeyboards.contains { $0 == .dubeolsik || $0 == .qwerty }
        guard isEnabled, hasNumberRowKeyboard else { return 0 }
        return isPortrait ? portraitNumberRowHeight : landscapeNumberRowHeight
    }
```

`height(...)` 함수를 아래로 교체한다. `struct Height`는 그대로 둔다.

```swift
    static func height(
        keyboardSettingsHeight: CGFloat,
        landscapeKeyboardHeight: CGFloat,
        suggestionBarHeight: CGFloat,
        isSuggestionBarVisible: Bool,
        isPortrait: Bool,
        numberRowHeight: CGFloat = 0
    ) -> Height {
        let visibleSuggestionBarHeight = isSuggestionBarVisible ? suggestionBarHeight : 0

        if isPortrait {
            return Height(
                keyboardViewHeight: keyboardSettingsHeight + visibleSuggestionBarHeight + numberRowHeight,
                keyboardHStackViewHeight: keyboardSettingsHeight + numberRowHeight
            )
        } else {
            return Height(
                keyboardViewHeight: landscapeKeyboardHeight + numberRowHeight,
                keyboardHStackViewHeight: landscapeKeyboardHeight - visibleSuggestionBarHeight + numberRowHeight
            )
        }
    }
```

- [x] **Step 5: 슬라이더가 범위 상수를 쓰도록 수정**

`KeyboardHeightSettingsView.swift`:

```swift
            Slider(value: $tempKeyboardHeight, in: KeyboardLayoutFigure.keyboardHeightRange, step: 1)
```

- [x] **Step 6: 테스트 통과 확인**

Run: 공통 명령, `KeyboardHeightPolicyTests`
Expected: `** TEST SUCCEEDED **`, 기존 테스트와 새 테스트 7개 모두 통과

- [x] **Step 7: 계획 문서 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardFigure.swift Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardHeightPolicy.swift SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift SYKeyboardTests/Utils/KeyboardHeightPolicyTests.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 숫자 행 높이를 키보드 높이 정책에 추가"
```

---

### Task 3: shift 짝 보조 키 목록 정책

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift` (`shouldInsertSecondaryKey` 근처)
- Test: `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`

**Interfaces:**
- Produces: `KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from primaryKeyList: [[[[String]]]]) -> [[[[String]]]]`
  - 입력·출력 모양은 `[shift 층(0: 비shift, 1: shift)][행][키][문자열]`
  - 비shift 층의 보조 키는 같은 자리의 shift 층 문자, shift 층의 보조 키는 비shift 층 문자
  - 두 층 문자가 같은 자리는 `[]`(보조 키 없음)
  - 층이 2개가 아니면 모든 자리를 `[]`로 채운 같은 모양을 반환

**결과:** `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' -parallel-testing-enabled NO` → RED: `type 'KeyboardTextInteractionPolicy' has no member 'shiftPairSecondaryKeyList'` 컴파일 오류 확인. GREEN: `Test run with 31 tests in 1 suite passed` (`** TEST SUCCEEDED **`), 신규 테스트 3개(`testShiftPairSecondaryKeyList_쿼티`, `testShiftPairSecondaryKeyList_두벌식`, `testShiftPairSecondaryKeyList_층불일치`) 포함 모두 통과. 확인하지 못한 항목 없음.

- [x] **Step 1: 실패하는 테스트 작성**

`KeyboardTextInteractionPolicyTests.swift` 709행의 `}`(첫 번째 suite `KeyboardTextInteractionPolicyTests`의 끝) 바로 위에 추가한다. 같은 파일 711행부터는 다른 suite(`삭제 mutation lifecycle 검증`)다.

```swift
    @Test("shift 짝 보조 키: 쿼티는 모든 키가 대소문자로 짝지어짐")
    func testShiftPairSecondaryKeyList_쿼티() {
        let primary: [[[[String]]]] = [
            [[["q"], ["w"]], [["a"]]],
            [[["Q"], ["W"]], [["A"]]]
        ]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [
            [[["Q"], ["W"]], [["A"]]],
            [[["q"], ["w"]], [["a"]]]
        ])
    }

    @Test("shift 짝 보조 키: 두벌식은 쌍자음·ㅒㅖ 자리만 짝이 생기고 나머지는 보조 키 없음")
    func testShiftPairSecondaryKeyList_두벌식() {
        let primary: [[[[String]]]] = [
            [[["ㅂ"], ["ㅛ"], ["ㅐ"]], [["ㅁ"]]],
            [[["ㅃ"], ["ㅛ"], ["ㅒ"]], [["ㅁ"]]]
        ]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [
            [[["ㅃ"], [], ["ㅒ"]], [[]]],
            [[["ㅂ"], [], ["ㅐ"]], [[]]]
        ])
    }

    @Test("shift 짝 보조 키: 층이 2개가 아니면 보조 키 없이 같은 모양 반환")
    func testShiftPairSecondaryKeyList_층불일치() {
        let primary: [[[[String]]]] = [[[["q"], ["w"]]]]

        let result = KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primary)

        #expect(result == [[[[], []]]])
    }
```

- [x] **Step 2: 테스트가 컴파일 실패하는지 확인**

Run: 공통 명령, `KeyboardTextInteractionPolicyTests`
Expected: `type 'KeyboardTextInteractionPolicy' has no member 'shiftPairSecondaryKeyList'` 컴파일 오류

- [x] **Step 3: 정책 구현**

`KeyboardTextInteractionPolicy.swift`의 `shouldInsertSecondaryKey(...)` 함수 바로 아래에 추가한다.

```swift
    /// 숫자 행을 쓸 때 길게 누르기로 입력할 shift 짝 보조 키 목록.
    ///
    /// 비shift 층은 같은 자리의 shift 문자(대문자·쌍자음), shift 층은 비shift 문자를 보조 키로 쓴다.
    /// 두 층의 문자가 같으면(두벌식 ㅁ, ㅛ 등) 보조 키를 두지 않는다
    /// - Parameter primaryKeyList: `[shift 층][행][키][문자열]` 모양의 키 배열
    static func shiftPairSecondaryKeyList(from primaryKeyList: [[[[String]]]]) -> [[[[String]]]] {
        guard primaryKeyList.count == 2 else {
            return primaryKeyList.map { $0.map { $0.map { _ in [] } } }
        }

        func pair(_ source: [[[String]]], with target: [[[String]]]) -> [[[String]]] {
            zip(source, target).map { sourceRow, targetRow in
                zip(sourceRow, targetRow).map { sourceKey, targetKey in
                    sourceKey == targetKey ? [] : targetKey
                }
            }
        }

        return [
            pair(primaryKeyList[0], with: primaryKeyList[1]),
            pair(primaryKeyList[1], with: primaryKeyList[0])
        ]
    }
```

- [x] **Step 4: 테스트 통과 확인**

Run: 공통 명령, `KeyboardTextInteractionPolicyTests`
Expected: `** TEST SUCCEEDED **`

- [x] **Step 5: 계획 문서 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 숫자 행용 shift 짝 보조 키 목록 정책 추가"
```

---

### Task 4: `StandardKeyboardView` 숫자 행과 보조 키 교체

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift` (init)
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift` (init)
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift:32-41` (주석 수치)
- Test: `SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift` (기존 fixture에 `showsNumberRow: false` 명시)
- Test: `SYKeyboardTests/Utils/KeyboardNumberRowLayoutTests.swift` (새 파일. `SYKeyboardTests`는 폴더 동기화 타깃이라 pbxproj 수정 불필요. 빌드 시 `cannot find` 오류가 나면 기존 테스트 파일이 어떻게 등록돼 있는지 `project.pbxproj`에서 확인한다)

**Interfaces:**
- Consumes: `UserDefaultsManager.shared.showsNumberRow`(Task 1), `KeyboardHeightPolicy.portraitNumberRowHeight`(Task 2), `KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from:)`(Task 3)
- Produces:
  - `NormalKeyboardLayoutProvider.showsNumberRow: Bool { get }` — 기본 구현 `false`
  - `NormalKeyboardLayoutProvider.updateNumberRowHeight(_ height: CGFloat)` — 기본 구현 no-op
  - `StandardKeyboardView.init(getIsShiftedLetterInput:setIsShiftedLetterInput:showsLanguageSwitchButton:showsNumberRow:)` — `showsNumberRow: Bool = UserDefaultsManager.shared.showsNumberRow`
  - `DubeolsikKeyboardView`, `EnglishKeyboardView` init에도 같은 `showsNumberRow` 인자(같은 기본값) 추가
  - 숫자 행 버튼은 `totalTextInterableButtonList`와 `primaryButtonList`의 **맨 앞**에 들어간다

**결과:** RED 확인: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -only-testing:SYKeyboardTests/KeyboardNumberRowLayoutTests GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' -parallel-testing-enabled NO` → `value of type 'DubeolsikKeyboardView'/'EnglishKeyboardView' has no member 'showsNumberRow'`/`'updateNumberRowHeight'` 컴파일 오류로 예상대로 실패. 구현 후 GREEN: 동일 명령 재실행 → `Test run with 6 tests in 1 suite passed`(`KeyboardNumberRowLayoutTests`), 이어서 `-only-testing:SYKeyboardTests/KeyboardModifierLayoutTests` → `Test run with 17 tests in 1 suite passed`. 회귀 확인: `-only-testing:SYKeyboardTests/KeyboardHeightPolicyTests -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests` → `Test run with 47 tests in 2 suites passed`. `xcodebuild build -scheme SYKeyboard`(동일 destination)로 컴파일러 경고 없음을 확인(`AppIntents.framework` 관련 기존 무관 경고만 존재). `numberRowHeightConstraint`는 `.priority` 조정 없이도 레이아웃 테스트 전체가 경고 없이 통과해 브리프의 999 우선순위 예외를 적용하지 않았다. 미확인: HangeulKeyboard/EnglishKeyboard/HangeulEnglishKeyboard extension scheme 빌드와 실제 입력 앱 수동 확인은 Task 5(VC 높이 반영)·Task 8 범위이므로 이 Task에서는 실행하지 않았다.

- [x] **Step 1: 기존 레이아웃 테스트 fixture를 설정값과 무관하게 고정**

`KeyboardModifierLayoutTests.swift`의 `EnglishKeyboardView(`와 `DubeolsikKeyboardView(` 생성 5곳(37, 60, 91, 118, 143행 근처)에 `showsLanguageSwitchButton:` 인자 다음 줄로 `showsNumberRow: false`를 추가한다. 예:

```swift
        let view = EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true,
            showsNumberRow: false
        )
```

- [x] **Step 2: 실패하는 레이아웃·보조 키 테스트 작성**

`SYKeyboardTests/Utils/KeyboardNumberRowLayoutTests.swift`:

```swift
//
//  KeyboardNumberRowLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/18/26.
//

import Testing
import UIKit

@testable import EnglishKeyboardCore
@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@MainActor
@Suite("두벌식·쿼티 숫자 행 레이아웃과 보조 키")
struct KeyboardNumberRowLayoutTests {

    private static let numberKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    private func makeDubeolsik(showsNumberRow: Bool) -> DubeolsikKeyboardView {
        DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: showsNumberRow
        )
    }

    private func makeQwerty(showsNumberRow: Bool) -> EnglishKeyboardView {
        EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: showsNumberRow
        )
    }

    @Test("숫자 행이 켜지면 1~0 키가 입력 버튼 목록 맨 앞에 들어감")
    func test숫자행_버튼목록() {
        let view = makeDubeolsik(showsNumberRow: true)

        let numberButtons = view.totalTextInterableButtonList.prefix(10)
        #expect(numberButtons.map(\.type.primaryKeyList) == Self.numberKeys.map { [$0] })
        #expect(numberButtons.allSatisfy { $0.type.secondaryKey == nil })
        #expect(view.showsNumberRow)
    }

    @Test("숫자 행이 꺼지면 숫자 키가 없고 첫 줄 보조 키는 기존 숫자")
    func test숫자행꺼짐_기존보조키유지() {
        let view = makeQwerty(showsNumberRow: false)

        #expect(view.totalTextInterableButtonList.first?.type.primaryKeyList == ["q"])
        #expect(view.totalTextInterableButtonList.first?.type.secondaryKey == "1")
        #expect(view.showsNumberRow == false)
    }

    @Test("세로 기본 높이에서 숫자 행은 46.5, 글자 행은 59")
    func test숫자행_세로높이() throws {
        let view = makeDubeolsik(showsNumberRow: true)
        // keyboardHStackView(240 + 46.5)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first as? UIView)
        let letterButton = try #require(view.totalTextInterableButtonList[10] as? UIView)
        #expect(abs(numberButton.frame.height - 46.5) < 0.5)
        #expect(abs(letterButton.frame.height - 59) < 0.5)
        #expect(abs(letterButton.convert(letterButton.bounds, to: view).minY - 46.5) < 0.5)
    }

    @Test("가로 숫자 행 높이로 갱신하면 숫자 행은 35")
    func test숫자행_가로높이갱신() throws {
        let view = makeQwerty(showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
        // 가로 keyboardHStackView(188 - 44 + 35)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
        view.layoutIfNeeded()

        let numberButton = try #require(view.totalTextInterableButtonList.first as? UIView)
        let letterButton = try #require(view.totalTextInterableButtonList[10] as? UIView)
        #expect(abs(numberButton.frame.height - 35) < 0.5)
        #expect(abs(letterButton.frame.height - 35) < 0.5)
    }

    @Test("숫자 행이 켜진 쿼티는 길게 누르기 보조 키가 대문자, shift 중에는 소문자")
    func test쿼티_보조키교체() {
        let view = makeQwerty(showsNumberRow: true)
        let qButton = view.totalTextInterableButtonList[10]
        let aButton = view.totalTextInterableButtonList[20]

        #expect(qButton.type.primaryKeyList == ["q"])
        #expect(qButton.type.secondaryKey == "Q")
        #expect(aButton.type.secondaryKey == "A")

        view.isShifted = true
        #expect(qButton.type.primaryKeyList == ["Q"])
        #expect(qButton.type.secondaryKey == "q")
    }

    @Test("숫자 행이 켜진 두벌식은 쌍자음·ㅒㅖ 자리만 보조 키가 생김")
    func test두벌식_보조키교체() {
        let view = makeDubeolsik(showsNumberRow: true)
        let firstRow = view.totalTextInterableButtonList[10..<20]
        let mButton = view.totalTextInterableButtonList[20]

        #expect(firstRow.map(\.type.secondaryKey) == ["ㅃ", "ㅉ", "ㄸ", "ㄲ", "ㅆ", nil, nil, nil, "ㅒ", "ㅖ"])
        #expect(mButton.type.primaryKeyList == ["ㅁ"])
        #expect(mButton.type.secondaryKey == nil)

        view.isShifted = true
        #expect(firstRow.map(\.type.secondaryKey) == ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ", nil, nil, nil, "ㅐ", "ㅔ"])
    }
}
```

- [x] **Step 3: 테스트가 컴파일 실패하는지 확인**

Run: 공통 명령, `KeyboardNumberRowLayoutTests`
Expected: `extra argument 'showsNumberRow' in call` 컴파일 오류

- [x] **Step 4: 프로토콜 요구사항 추가**

`NormalKeyboardLayoutProvider.swift` 프로토콜 본문, `updateLetterColumnWidthMultiplier` 선언 아래:

```swift
    /// 두벌식·쿼티 숫자 행 표시 여부
    var showsNumberRow: Bool { get }
    /// 숫자 행 높이를 갱신한다. 숫자 행이 없는 키보드는 무시한다
    func updateNumberRowHeight(_ height: CGFloat)
```

같은 파일 extension, `updateLetterColumnWidthMultiplier(_:) {}` 아래:

```swift
    /// 숫자 행은 두벌식·쿼티(`StandardKeyboardView`)에만 있다
    var showsNumberRow: Bool { false }

    func updateNumberRowHeight(_ height: CGFloat) {}
```

- [x] **Step 5: `StandardKeyboardView`에 숫자 행과 보조 키 교체 구현**

(1) Properties 섹션, `secondaryKeyList` 선언 아래:

```swift
    /// 두벌식·쿼티 숫자 행 표시 여부
    public let showsNumberRow: Bool
    /// 실제 버튼에 쓰는 보조 키 배열. 숫자 행이 켜져 있으면 숫자 대신 shift 짝 문자를 쓴다
    private var resolvedSecondaryKeyList: [[[[String]]]] {
        showsNumberRow
        ? KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primaryKeyList)
        : secondaryKeyList
    }
```

(2) `primaryButtonList`, `totalTextInterableButtonList` 정의의 맨 앞에 숫자 행 버튼을 붙인다:

```swift
    public private(set) lazy var primaryButtonList: [PrimaryButton] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
```

```swift
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, secondaryAtButton, secondarySharpButton]
```

(3) `/// 숫자 행 높이 제약` 프로퍼티를 `fourthRowModifierWidthConstraint` 아래에:

```swift
    /// 숫자 행 높이 제약. 방향에 따라 `updateNumberRowHeight(_:)`가 상수를 바꾼다
    private var numberRowHeightConstraint: NSLayoutConstraint?
```

(4) UI Components, `firstRowHStackView` 위:

```swift
    /// 숫자 행
    private let numberRowHStackView = KeyboardRowHStackView()
```

(5) 버튼 배열, `firstRowPrimaryKeyButtonList` 위:

```swift
    /// 숫자 행 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    private lazy var numberRowPrimaryKeyButtonList: [PrimaryKeyButton] = showsNumberRow
    ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map {
        PrimaryKeyButton(keyboard: keyboard, button: .keyButton(primary: [$0], secondary: nil))
    }
    : []
```

(6) `firstRowPrimaryKeyButtonList`, `secondRowPrimaryKeyButtonList`, `thirdRowPrimaryKeyButtonList`의 `secondaryKeyList[0][n]`을 `resolvedSecondaryKeyList[0][n]`으로 바꾼다. `updateKeyButtonList()`의 `let secondaryKeyList = secondaryKeyList[keyListIndex][rowIndex][buttonIndex]`도 `resolvedSecondaryKeyList`로 바꾼다. 반복 안에서 매번 계산하지 않도록 함수 첫 줄에서 한 번 받아 둔다:

```swift
    final public func updateKeyButtonList() {
        let keyListIndex = (isShifted ? 1 : 0)
        let resolvedSecondaryKeyList = resolvedSecondaryKeyList
        let rowList = [firstRowPrimaryKeyButtonList, secondRowPrimaryKeyButtonList, thirdRowPrimaryKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let primaryKeyList = primaryKeyList[keyListIndex][rowIndex][buttonIndex]
                let secondaryKeyList = resolvedSecondaryKeyList[keyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: secondaryKeyList.first))
            }
        }
    }
```

(7) init 시그니처와 저장:

```swift
    public init(
        getIsShiftedLetterInput: @escaping () -> Bool,
        setIsShiftedLetterInput: @escaping (Bool) -> (),
        showsLanguageSwitchButton: Bool = false,
        showsNumberRow: Bool = UserDefaultsManager.shared.showsNumberRow
    ) {
        self.getIsShiftedLetterInput = getIsShiftedLetterInput
        self.setIsShiftedLetterInput = setIsShiftedLetterInput
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.showsNumberRow = showsNumberRow
        super.init(frame: .zero)

        setupUI()
    }
```

(8) `setHierarchy()`의 첫 줄 `[layoutVStackView, keyboardSelectOverlayView, oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }`를 아래로 바꾼다. 오버레이가 숫자 행 위에 그려지도록 숫자 행을 오버레이보다 먼저 추가한다.

```swift
        self.addSubview(layoutVStackView)
        if showsNumberRow {
            self.addSubview(numberRowHStackView)
            numberRowPrimaryKeyButtonList.forEach { numberRowHStackView.addArrangedSubview($0) }
        }
        [keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }
```

(9) `setConstraints()`의 `layoutVStackView` 제약 블록을 교체한다. 숫자 행이 꺼져 있으면 기존 제약과 같다.

```swift
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        if showsNumberRow {
            numberRowHStackView.translatesAutoresizingMaskIntoConstraints = false
            let heightConstraint = numberRowHStackView.heightAnchor.constraint(
                equalToConstant: KeyboardHeightPolicy.portraitNumberRowHeight
            )
            NSLayoutConstraint.activate([
                numberRowHStackView.topAnchor.constraint(equalTo: self.topAnchor),
                numberRowHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                numberRowHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                heightConstraint,
                layoutVStackView.topAnchor.constraint(equalTo: numberRowHStackView.bottomAnchor)
            ])
            numberRowHeightConstraint = heightConstraint
        } else {
            layoutVStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        }
```

(10) `// MARK: - Update Methods` extension, `nextKeyboardButtonVisibilityDidChange` 위:

```swift
    final public func updateNumberRowHeight(_ height: CGFloat) {
        guard let numberRowHeightConstraint,
              numberRowHeightConstraint.constant != height else { return }
        numberRowHeightConstraint.constant = height
    }
```

- [x] **Step 6: 두벌식·쿼티 init에 인자 전달**

`DubeolsikKeyboardView.swift`와 `EnglishKeyboardView.swift`의 `override init(...)`을 둘 다 아래 형태로 바꾼다(본문의 `updateLayoutToDefault()` 호출은 유지).

```swift
    override init(
        getIsShiftedLetterInput: @escaping () -> Bool,
        setIsShiftedLetterInput: @escaping (Bool) -> (),
        showsLanguageSwitchButton: Bool = false,
        showsNumberRow: Bool = UserDefaultsManager.shared.showsNumberRow
    ) {
        super.init(
            getIsShiftedLetterInput: getIsShiftedLetterInput,
            setIsShiftedLetterInput: setIsShiftedLetterInput,
            showsLanguageSwitchButton: showsLanguageSwitchButton,
            showsNumberRow: showsNumberRow
        )
        updateLayoutToDefault()
    }
```

`EnglishKeyboardView.swift`가 `SYKeyboardCore`를 import하지 않으면 `UserDefaultsManager`를 찾지 못한다. 파일 상단 import를 확인하고 없으면 `import SYKeyboardCore`를 추가한다.

- [x] **Step 7: `SwitchButton` 주석 수치 정정**

`SwitchButton.swift` 32~41행 주석에서 슬라이더 최소값(190)의 세로 쿼티 키 높이를 `39.5pt`에서 `38.5pt`로, "8.0이 아닌 7.9"를 실제 비율에 맞게 고친다. 계산식: 행 높이 `(190 - 4) / 4 = 46.5`, 키 배경 `46.5 - 4 × 2 = 38.5`, 힌트 글자 `8.0 × 38.5 / 40 = 7.7`. 세로 4x4 기본 높이 표기(56pt), 기본 높이 쿼티(52pt)도 같은 방식으로 다시 계산해 고친다: 기본 행 `(240 - 4) / 4 = 59`, 쿼티 키 `59 - 8 = 51`, 4x4 키 `59 - 4 = 55`. `primaryLabelFullSizeKeyHeight` 주석의 `39.5pt`도 `38.5pt`로 고친다. 상수 값(40.0, 36.0)은 바꾸지 않는다.

- [x] **Step 8: 테스트 통과 확인**

Run: 공통 명령, `KeyboardNumberRowLayoutTests`, 이어서 `KeyboardModifierLayoutTests`
Expected: 두 suite 모두 `** TEST SUCCEEDED **`

- [x] **Step 9: 계획 문서 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/NormalKeyboardLayoutProvider.swift Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift SYKeyboardTests/Utils/KeyboardNumberRowLayoutTests.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 두벌식·쿼티 자판에 숫자 행과 shift 짝 보조 키 추가"
```

`project.pbxproj` 변경이 필요했다면 같은 커밋에 포함한다.

---

### Task 5: 키보드 extension 높이에 숫자 행 반영

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (`setKeyboardHeight()`, 978행 근처)

**Interfaces:**
- Consumes: `KeyboardHeightPolicy.numberRowHeight(isEnabled:primaryKeyboards:isPortrait:)`, `height(...numberRowHeight:)`(Task 2), `NormalKeyboardLayoutProvider.showsNumberRow`, `updateNumberRowHeight(_:)`(Task 4)

VC 메서드는 단위 테스트 대상이 아니다. 계산은 Task 2 정책 테스트가, 뷰 반영은 Task 4 레이아웃 테스트가 검증한다. 이 Task는 빌드와 Task 8의 수동 확인으로 검증한다.

**결과:** Step 1~3 완료. `setKeyboardHeight()`에 브리프와 동일한 코드를 반영. 세 extension scheme 빌드 각각 `** BUILD SUCCEEDED **`(`xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard|EnglishKeyboard|HangeulEnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'`), 매 빌드 후 `git status --short`에 `.xcscheme` 변경 없음(되돌릴 필요 없었음). `KeyboardHeightPolicyTests` 재실행(`xcodebuild test ... -only-testing:SYKeyboardTests/KeyboardHeightPolicyTests -parallel-testing-enabled NO`) → `Test run with 16 tests in 1 suite passed`, `** TEST SUCCEEDED **`. 미확인: 실제 입력 앱에서의 높이 반영 수동 확인(Task 8 범위).

- [x] **Step 1: `setKeyboardHeight()`에서 숫자 행 높이 계산·반영**

`let isPortrait = KeyboardHeightPolicy.isPortrait(...)` 블록과 `let height = KeyboardHeightPolicy.height(...)` 사이에 추가한다.

```swift
        // 숫자 행 여부는 설정값이 아니라 실제로 만들어진 뷰를 기준으로 판단한다.
        // extension이 살아 있는 동안 설정이 바뀌어도 뷰와 프레임 높이가 어긋나지 않는다
        let numberRowHeight = KeyboardHeightPolicy.numberRowHeight(
            isEnabled: primaryKeyboardViews.contains { $0.showsNumberRow },
            primaryKeyboards: primaryKeyboardViews.map(\.keyboard),
            isPortrait: isPortrait
        )
        primaryKeyboardViews.forEach { $0.updateNumberRowHeight(numberRowHeight) }
```

`KeyboardHeightPolicy.height(...)` 호출의 `isPortrait: isPortrait` 다음 줄에 `numberRowHeight: numberRowHeight`를 추가한다.

- [x] **Step 2: 세 extension 빌드**

Run (차례로):

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: 세 번 모두 `** BUILD SUCCEEDED **`. 이후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀌었는지 `git diff`로 확인하고 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌린다.

- [x] **Step 3: 높이 정책 테스트 재실행**

Run: 공통 명령, `KeyboardHeightPolicyTests`
Expected: `** TEST SUCCEEDED **`

- [x] **Step 4: 계획 문서 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 숫자 행 높이를 키보드 extension 프레임 높이에 반영"
```

---

### Task 6: 설정 화면과 미리보기

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift` (토글 추가)
- Modify: `SYKeyboard/Presentation/KeyboardSettings/InputSettingsView.swift` (`LongPressMode.displayStr`)
- Modify: `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewKeyboardView.swift` (미리보기 높이)
- Modify: `SYKeyboard/Resources/Localizable.xcstrings` (영어 번역 3개)

**Interfaces:**
- Consumes: `UserDefaultsKeys.showsNumberRow`, `DefaultValues.showsNumberRow`(Task 1), `KeyboardHeightPolicy.numberRowHeight(...)`(Task 2)

- [x] **Step 1: 외형 설정에 토글 추가**

`AppearanceSettingsView.swift` Properties, `isNumericKeypadEnabled` 선언 위:

```swift
    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow
```

body의 `NavigationLink("키보드 높이") { ... }` 바로 아래:

```swift
        Toggle(isOn: $showsNumberRow, label: {
            Text("숫자 행 표시")
            Text("두벌식·쿼티 자판 맨 윗줄에 숫자 키 표시")
                .font(.caption)
        })
        .onChange(of: showsNumberRow) { newValue in
            // 사용자 속성 25개 한도 때문에 이벤트로만 남긴다
            Analytics.logEvent("number_row", parameters: [
                "view": "AppearanceSettingsView",
                "enabled": newValue.analyticsValue
            ])
            hideKeyboard()
        }
```

- [x] **Step 2: 길게 누르기 항목 이름 변경**

`InputSettingsView.swift` Properties, `selectedLongPressAction` 선언 아래:

```swift
    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow
```

`LongPressMode`의 `var displayStr: String`을 아래로 교체한다.

```swift
        /// 숫자 행이 켜져 있으면 두벌식·쿼티의 길게 누르기가 숫자 대신 shift 문자를 입력한다
        func displayStr(showsNumberRow: Bool) -> String {
            switch self {
            case .repeatInput:
                String(localized: "반복 입력")
            case .numberInput:
                showsNumberRow
                ? String(localized: "대문자·쌍자음 입력")
                : String(localized: "숫자 입력")
            case .disabled:
                String(localized: "비활성화")
            }
        }
```

Picker의 `Text($0.displayStr)`를 `Text($0.displayStr(showsNumberRow: showsNumberRow))`로 바꾼다. 다른 곳에서 `LongPressMode.displayStr`을 쓰는지 `grep -rn "displayStr" SYKeyboard`로 확인하고, 있으면 같은 방식으로 인자를 넘긴다. `analyticsValue`(`number_input`)는 바꾸지 않는다.

- [x] **Step 3: 미리보기 높이에 숫자 행 반영**

`PreviewKeyboardView.swift` 상단에 `import HangeulKeyboardCore`를 추가하고, Properties에:

```swift
    @AppStorage(UserDefaultsKeys.showsNumberRow, store: UserDefaultsManager.shared.storage)
    private var showsNumberRow = DefaultValues.showsNumberRow

    @AppStorage(UserDefaultsKeys.selectedHangeulKeyboard, store: UserDefaultsManager.shared.storage)
    private var selectedHangeulKeyboard = DefaultValues.selectedHangeulKeyboard
```

UI Components extension에 추가:

```swift
    /// 미리보기는 항상 세로 화면이므로 세로 숫자 행 높이를 더한다
    func previewFrameHeight(for keyboard: SYKeyboardType) -> CGFloat {
        keyboardHeight + KeyboardHeightPolicy.numberRowHeight(
            isEnabled: showsNumberRow,
            primaryKeyboards: [keyboard],
            isPortrait: true
        )
    }

    var previewHangeulKeyboardType: SYKeyboardType {
        switch selectedHangeulKeyboard {
        case .naratgeul: .naratgeul
        case .cheonjiin: .cheonjiin
        case .dubeolsik: .dubeolsik
        }
    }
```

`previewHangeulKeyboard`의 `.frame(height: keyboardHeight)`를 `.frame(height: previewFrameHeight(for: previewHangeulKeyboardType))`로, `previewEnglishKeyboard`의 것을 `.frame(height: previewFrameHeight(for: .qwerty))`로 바꾼다.

미리보기 VC는 `isPreview`라 `setKeyboardHeight()`를 거치지 않는다. 숫자 행 높이는 `StandardKeyboardView`의 초기 제약(세로 46.5)을 그대로 쓴다.

- [x] **Step 4: 영어 번역 추가**

`SYKeyboard/Resources/Localizable.xcstrings`의 `"strings"` 객체에 아래 3개를 추가한다. 기존 항목 형식(`"key" : {`, 들여쓰기 2칸)을 그대로 따른다. 파일 전체를 다시 정렬·재포맷하지 않도록 Edit으로 넣고, `git diff --stat`이 이 파일에서 추가 줄만 보이는지 확인한다.

```json
    "숫자 행 표시" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Number Row"
          }
        }
      }
    },
    "두벌식·쿼티 자판 맨 윗줄에 숫자 키 표시" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Show number keys above the Dubeolsik and QWERTY layouts"
          }
        }
      }
    },
    "대문자·쌍자음 입력" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Uppercase & Double Consonant Input"
          }
        }
      }
    },
```

- [x] **Step 5: 앱 빌드**

Run:

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
```

Expected: `** BUILD SUCCEEDED **`. 빌드가 `Localizable.xcstrings`를 재정렬했다면 `git diff`로 새 3개 항목 외 변경이 없는지 확인하고, 순서만 바뀐 경우 그대로 둔다(Xcode 표준 형식).

- [x] **Step 6: 계획 문서 갱신 후 커밋**

```bash
git add SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift SYKeyboard/Presentation/KeyboardSettings/InputSettingsView.swift SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewKeyboardView.swift SYKeyboard/Resources/Localizable.xcstrings docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "feat: #138 - 숫자 행 설정 토글과 미리보기 높이·길게 누르기 항목 이름 반영"
```

**결과:**
- Step 1~4: 브리프 코드 그대로 적용. `LongPressMode.displayStr`을 쓰는 다른 곳은
  `HangeulKeyboardSelectView`, `PreviewKeyboardLanguage`뿐으로 둘 다 별개 타입의
  동일 이름 프로퍼티라 영향 없음(`grep -rn "displayStr" SYKeyboard`로 확인).
- Step 5: `xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'` →
  `** BUILD SUCCEEDED **`. `grep -iE "warning:|error:"`로 새 경고 없음 확인.
  `git diff --stat -- SYKeyboard/Resources/Localizable.xcstrings`는 추가 30줄만
  표시, 재정렬·`.xcscheme` 변경 없음.
- SwiftUI 뷰 변경이라 유닛 테스트는 대상이 아님(브리프대로 미실행).

---

### Task 7: 두벌식 쌍자음·ㅒㅖ 조합 회귀 테스트

길게 누르기로 입력한 쌍자음은 `inputAdapter.input("ㅆ")`로 기존 오토마타를 거친다. production 코드는 바꾸지 않으므로 이 Task의 테스트는 처음부터 통과하는 **회귀 가드**다. 기존 테스트에 같은 경우가 있으면 중복 추가하지 않는다.

**Files:**
- Test: `SYKeyboardTests/Processor/DubeolsikProcessorTests.swift` (`// MARK: - 2.` 섹션 위)

- [ ] **Step 1: 기존 커버리지 확인**

Run: `grep -n "ㅆ\|ㄲ\|ㅒ\|ㅖ" SYKeyboardTests/Processor/DubeolsikProcessorTests.swift`
계획 작성 시점(`aa1116d4`)에는 328행 헬퍼의 모음 목록 외에 이 네 문자를 입력하는 테스트가 없었다. 결과를 계획 문서에 기록하고, 그 사이 같은 경우가 추가됐으면 Step 2에서 뺀다.

- [ ] **Step 2: 회귀 테스트 추가**

```swift
    @Test("shift 짝 입력: 쌍자음 ㅆ·ㄲ가 받침으로, ㅒ·ㅖ가 모음으로 조합")
    func testShift짝입력_조합() {
        var (c, p) = ("", "")
        for 글자 in ["ㄱ", "ㅏ", "ㅆ"] { (c, p) = applyInput(글자, committed: c, composing: p) }
        #expect(c + p == "갔")

        (c, p) = ("", "")
        for 글자 in ["ㄱ", "ㅏ", "ㄲ"] { (c, p) = applyInput(글자, committed: c, composing: p) }
        #expect(c + p == "갂")

        (c, p) = ("", "")
        for 글자 in ["ㄱ", "ㅒ"] { (c, p) = applyInput(글자, committed: c, composing: p) }
        #expect(c + p == "걔")

        (c, p) = ("", "")
        for 글자 in ["ㅅ", "ㅖ"] { (c, p) = applyInput(글자, committed: c, composing: p) }
        #expect(c + p == "셰")
    }
```

- [ ] **Step 3: 테스트 실행**

Run: 공통 명령, `DubeolsikProcessorTests`, 이어서 `HangeulAutomataTests`
Expected: 두 suite 모두 `** TEST SUCCEEDED **`

- [ ] **Step 4: 계획 문서 갱신 후 커밋**

```bash
git add SYKeyboardTests/Processor/DubeolsikProcessorTests.swift docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "test: #138 - 두벌식 shift 짝 문자 조합 회귀 테스트 추가"
```

---

### Task 8: 전체 검증과 수동 확인

**Files:**
- Modify: `docs/superpowers/plans/2026-09-18-number-row.md` (결과 기록만)

- [ ] **Step 1: 전체 테스트**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' -resultBundlePath /tmp/number-row-tests.xcresult
```

Expected: `** TEST SUCCEEDED **`. 통과·실패 개수는 `xcrun xcresulttool get test-results summary --path /tmp/number-row-tests.xcresult`로 읽어 기록한다.

- [ ] **Step 2: 네 scheme 빌드**

Run: Task 5 Step 2의 세 명령 + Task 6 Step 5의 `SYKeyboard` 빌드(옵션 없이)
Expected: 모두 `** BUILD SUCCEEDED **`. `.xcscheme` `RemotePath` 변경은 되돌린다.

- [ ] **Step 3: 수동 확인 (시뮬레이터 iPhone 13 mini / iOS 18.6, 메모 앱 등 실제 입력 앱)**

설정 앱에서 '숫자 행 표시'를 켜고 각 항목을 확인해 결과를 기록한다. 확인하지 못한 항목은 이유와 함께 미확인으로 남긴다.

- [ ] 영어 키보드 세로: 숫자 행 표시, 탭하면 숫자 입력, 전체 높이가 꺼졌을 때보다 46.5pt 높음
- [ ] 영어 키보드 가로: 숫자 행 표시, 전체 223pt(자동완성 바 표시 시)
- [ ] 한글 키보드(두벌식 선택): 조합 중 숫자 탭 시 조합이 확정되고 숫자가 붙음
- [ ] 한글 키보드(나랏글 선택): 숫자 행 없음, 높이 변화 없음
- [ ] 한영 통합(나랏글 + 쿼티): 한영 전환 시 프레임 높이 유지, 4x4 행이 늘어남
- [ ] 기호·숫자 자판 전환 시 프레임 높이 유지
- [ ] 길게 누르기 '대문자·쌍자음 입력'(= `numberInput`): 쿼티 q → Q, shift 중 Q → q, 두벌식 ㅂ → ㅃ, 가+ㅅ 길게 → 갔, 키 모서리 힌트가 새 문자로 표시
- [ ] 길게 누르기 '반복 입력': 기존처럼 반복 입력
- [ ] 설정의 키보드 높이 미리보기: 두벌식·쿼티 미리보기에 숫자 행이 보이고 잘리지 않음
- [ ] 숫자 행 끔: 기존과 같은 높이·레이아웃, 첫 줄 길게 누르기 숫자 입력

- [ ] **Step 4: 결과 기록 후 커밋**

```bash
git add docs/superpowers/plans/2026-09-18-number-row.md
git commit -m "docs: #138 - 숫자 행 전체 테스트·빌드·수동 확인 결과 기록"
```
