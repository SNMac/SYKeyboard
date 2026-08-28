# 숫자 키패드 스페이스 하단 배치 설정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 숫자 키패드에서 스페이스를 맨 아랫줄로 옮기는 스위치 설정을 추가하고, 기본값(꺼짐)에서는 현재 배치와 완전히 동일하게 동작하게 한다.

**Architecture:** 이슈 #114(천지인 스페이스 하단 배치)가 만든 배관을 그대로 재사용한다. `NumericKeyboardView`는 `FourByFourPlusKeyboardView`와 행 구조·modifier 폭 계약·오버레이 제약이 거의 동일하므로 같은 변환이 적용된다. 방향 계약을 결정하는 `KeyboardSelectDirectionPolicy`와 `SwitchButton`·`KeyboardSelectOverlayView`의 `usesBottomSpaceLayout` 파라미터, `SwitchGestureHandling`의 프로토콜 요구사항은 **이미 존재하므로 새로 만들지 않는다.**

**Tech Stack:** Swift 5 / Xcode 26, UIKit(키보드 확장), SwiftUI(`@AppStorage` 설정 화면), Swift Testing

**Spec:** GitHub Issue [#117](https://github.com/SNMac/SYKeyboard/issues/117) — [Feat] 숫자 키패드 스페이스 하단 배치 모드 추가. 이슈 본문과 아래 "확정된 설계 결정"이 이 계획의 기준이다. 남은 미결은 D1 하나뿐이다.

---

## Global Constraints

- 설정 기본값은 **꺼짐(`false`)**이며, 꺼짐 상태의 렌더링 결과는 현재와 픽셀 단위로 동일해야 한다.
- 적용 대상은 **숫자 키패드(`NumericKeyboardView`)뿐이다.** 천지인·나랏글·두벌식·쿼티·기호 키보드는 **한 줄도 바뀌지 않아야 한다.** 특히 `FourByFourPlusKeyboardView`(천지인, 이슈 #114 결과물)를 건드리지 않는다.
- `UserDefaults` 키 문자열: `"isNumericKeypadBottomSpaceEnabled"`. 기본값 `false`. App Group suite(`DefaultValues.groupBundleID`) 공유.
- Analytics User Property 이름: `pref_numeric_keypad_bottom_space`. Event 이름: `numeric_keypad_bottom_space`.
- 설정 스위치는 `AppearanceSettingsView`의 **`숫자 키패드 활성화` 토글 바로 아래**에 두고, `isNumericKeypadEnabled == true`일 때만 노출한다. 같은 파일의 `isOneHandedKeyboardEnabled` → `한 손 키보드 너비` 조건부 노출 패턴을 따른다.
- modifier 폭 분배는 **현재 계약 그대로**: 지구본 숨김 → `.fill`(한/영이 전체 폭의 1/10 고정, 전환 버튼이 나머지), 지구본 표시 → `.fillEqually`(3등분). `updateModifierDistribution`과 999 우선순위 폭 제약을 건드리지 않는다.
- **`Modules/`에 새 `.swift` 파일을 추가하지 않는다.** 따라서 `SYKeyboard.xcodeproj/project.pbxproj`도 변경되지 않아야 한다.
- 커밋 메시지: `type: #117 - <결과 중심 한국어 서술구>`, 마침표 없음. 한 커밋에 한 목적.
- Firebase / AdMob / entitlements / bundle identifier / provisioning / `GoogleService-Info.plist` / `Secrets.xcconfig` 변경 금지.
- 검증 기준 시뮬레이터: `iPhone 13 mini / iOS 16.0`.
- **버튼 프레임은 각자의 행 스택 좌표계에 있다.** `deleteButton`, `spaceButton`, `returnButton`, `switchButton`은 서로 다른 `KeyboardRowHStackView` 안에 있어 `frame.midY`가 전부 같다. **행을 가로지르는 위치 비교는 반드시 `subview.convert(subview.bounds, to: view)`로 변환한다.** 같은 컨테이너 안의 비교와 폭 비교는 변환이 필요 없다.
- `-only-testing`이나 code coverage 옵션을 쓴 뒤 extension scheme을 빌드할 때는 옵션을 반드시 비운다.

---

## 확정된 설계 결정

| 항목 | 결정 |
|---|---|
| 적용 범위 | **숫자 키패드만.** 천지인은 이미 #114로 별도 설정이 있다 |
| 설정 위치 | `AppearanceSettingsView`, `숫자 키패드 활성화` 바로 아래, 그 값이 `true`일 때만 노출 |
| 설정 키 | `isNumericKeypadBottomSpaceEnabled`, 기본값 `false` (#114의 `isCheonjiinBottomSpaceEnabled`와 별개) |
| 2행 우측 칸 | `returnButton` (기존 3행에서 올라옴) |
| 4행 첫 칸 | modifier 스택. 좌→우 `한글`/`ABC` → `한/영` → `🌐` (#114와 동일한 미러링) |
| 오버레이 방향 | `targetDirection`을 `.right`로 반전. `KeyboardSelectDirectionPolicy`가 `.numeric`에서도 플래그를 반영하게 확장 |
| modifier 폭 분배 | 기존 계약 유지 |

### 현재 숫자 키패드 배치

```
1     2     3     ⌫
4     5     6     space
7     8     9     ↵
- ,   0    . /    🌐 한/영 한글
```

`numericKeyList[3] = [ ["-"], [","], ["0"], ["."], ["/"] ]`이므로
`fourthRowLeftPrimaryButtonHStackView` = `-` `,`, `fourthRowPrimaryKeyButtonList[2]` = `0`,
`fourthRowRightPrimaryButtonHStackView` = `.` `/`.

### 켜짐 배치 (D1 확정 완료)

```
1     2     3     ⌫
4     5     6     ↵
7     8     9     -  /
한글 한/영 🌐  0  space  .  ,
```

**네 행 모두 4칸 균등 분할이 유지**되므로 새 레이아웃 클래스 없이 기존 스택 객체의
부모와 멤버십만 바꾼다.

---

## ~~미결 사항~~ (전부 확정 완료)

### ~~D1 — 3행 우측과 4행 끝에 어느 문장부호 스택을 둘 것인가~~ (완료)

**D1-c로 확정 (2026-08-28, 사용자 결정).** 3행 우측 `-` `/`, 4행 끝 `.` `,`.

숫자 입력 맥락에서 가장 빈번한 `.`과 `,`를 엄지에 가까운 4행 끝에 함께 둔다.
D1-a/D1-b는 두 키가 위아래로 갈라지므로 채택하지 않았다.

**범위 재평가:** 계획 초안은 D1-c를 "키 배열 자체를 바꾸는 일"로 보아 비권장했으나,
실제 코드에서 `numericKeyList`는 `NumericKeyboardView` private 상수이고
`fourthRowLeft/RightPrimaryButtonHStackView`는 순수 레이아웃 컨테이너다.
`fourthRowPrimaryKeyButtonList`의 **순서와 원소는 그대로 두고** 켜짐 분기에서
어느 버튼이 어느 스택에 들어가는지만 바꾸면 되므로, 변경 규모는 D1-a와 같다.

| 스택 | 꺼짐(현행 유지) | 켜짐 |
|---|---|---|
| `fourthRowLeftPrimaryButtonHStackView` | `[0]`=`-`, `[1]`=`,` (4행 좌측) | `[3]`=`.`, `[1]`=`,` (4행 끝) |
| `fourthRowRightPrimaryButtonHStackView` | `[3]`=`.`, `[4]`=`/` (4행 우측) | `[0]`=`-`, `[4]`=`/` (3행 우측) |

`allButtonList` / `primaryButtonList` / `totalTextInterableButtonList`는
`fourthRowPrimaryKeyButtonList`를 그대로 이어 붙이므로 **두 배치에서 동일하다.**
스택 멤버십은 시각 위치에만 영향을 준다.

### ~~D2 — 이슈 등록~~ (완료)

**이슈 #117로 등록 완료 (2026-08-28).** 브랜치명·커밋 메시지의 이슈 번호를 이 문서 전체에 반영했다. 이슈 본문에는 이 문서의 "확정된 설계 결정"과 D1 선택지가 옮겨져 있다.

---

## 재사용하는 것 (새로 만들지 않는다)

이슈 #114가 만든 것들이 그대로 쓰인다. **이 계획은 아래를 새로 만들지 않는다.**

| 자산 | 위치 | 이 계획에서의 역할 |
|---|---|---|
| `KeyboardSelectDirectionPolicy.targetDirection(for:usesBottomSpaceLayout:)` | `Modules/SYKeyboardCore/Presentation/Utils/Policies/` | `.numeric` 분기만 확장 |
| `SwitchButton.init(keyboard:usesBottomSpaceLayout:)` | `.../Components/Buttons/SwitchButton.swift` | 그대로 호출 |
| `KeyboardSelectOverlayView.init(keyboard:usesBottomSpaceLayout:)` | `.../Components/Overlays/` | 그대로 호출 |
| `SwitchGestureHandling.usesBottomSpaceLayout` | `.../GestureControllers/Protocols/` | `NumericKeyboardView`가 public stored let으로 충족 |
| `SwitchGestureController.setPanConfig()`의 `.numeric` case | `.../GestureControllers/` | 이미 `numericKeyboardView.usesBottomSpaceLayout`을 policy에 넘긴다. **변경 불필요** |

`SwitchButton`의 코너 힌트 화살표(`!#1◀` ↔ `▶!#1`)와 `KeyboardSelectOverlayView`의 내부 배치 순서는 policy 결과만 보고 이미 일반화돼 있으므로 **자동으로 따라온다.**

---

## File Structure

### 수정

| 경로 | 변경 |
|---|---|
| `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` | 외형 설정 구역에 키 추가 |
| `Modules/SYKeyboardCore/Storage/DefaultValues.swift` | 외형 설정 구역에 기본값 `false` 추가 |
| `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` | `@UserDefaultsWrapper` 프로퍼티 추가 |
| `SYKeyboard/App/SYKeyboardApp.swift` | Analytics User Property 초기화 한 줄 |
| `SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift` | 조건부 `Toggle` 추가 |
| `SYKeyboard/Resources/Localizable.xcstrings` | 라벨·캡션 en 번역 |
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift` | `.numeric`이 플래그를 반영 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift` | 플래그, `setHierarchy()` 분기, 오버레이 앵커 분기 |
| `SYKeyboardTests/Storage/UserDefaultsContractTests.swift` | 새 키 계약 테스트 |
| `SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift` | `.numeric` 분기 테스트 갱신 |

### 신규

| 경로 | 책임 |
|---|---|
| `SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift` | 켜짐/꺼짐 배치, 오버레이 앵커 회귀 |

`SYKeyboardTests/`는 동기화 그룹이므로 `project.pbxproj` 등록이 필요 없다.

---

## Task 0: 이슈 등록과 브랜치 준비

- [x] **Step 1: GitHub Issue를 등록한다** — 완료

[#117](https://github.com/SNMac/SYKeyboard/issues/117)로 등록했다. 본문에 "확정된 설계 결정" 표와 D1 선택지가 들어 있다.

- [x] **Step 2: D1을 확정한다** — 완료

**D1-c 확정 (2026-08-28).** 3행 우측 `-` `/`, 4행 끝 `.` `,`.
"켜짐 배치" 그림과 Task 3 Step 4 코드에 반영했다.

- [x] **Step 3: `develop`에서 작업 브랜치를 만든다** — 완료

브랜치명은 **`feat/#117-numeric-keypad-bottom-space`**다. 기준 커밋은 `4894613b`(PR #116 머지).

- [x] **Step 4: 기준선 전체 테스트를 기록한다** — 완료

```bash
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

개수는 로그가 아니라 `.xcresult`에서 읽는다.

```bash
RES=$(ls -td ~/Library/Developer/Xcode/DerivedData/SYKeyboard-*/Logs/Test/*.xcresult | head -1)
xcrun xcresulttool get test-results summary --path "$RES"
```

최상위 `passedTests`가 고유 테스트 수, `devicesAndConfigurations[].passedTests`가 파라미터 전개 포함 실행 수다. 이 두 수를 기준선으로 기록한다.

---

## Task 1: 설정 키·기본값·매니저·설정 화면

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Modify: `SYKeyboard/App/SYKeyboardApp.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift`
- Modify: `SYKeyboard/Resources/Localizable.xcstrings`
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `UserDefaultsKeys.isNumericKeypadBottomSpaceEnabled: String` (값 `"isNumericKeypadBottomSpaceEnabled"`)
  - `DefaultValues.isNumericKeypadBottomSpaceEnabled: Bool` (값 `false`)
  - `UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled: Bool`

**참고 이력:** 커밋 `18f8b9dd`(#114 Task 1)가 동일한 형태다. `git show 18f8b9dd`로 확인하고 그 패턴을 그대로 따른다.

- [x] **Step 1: 실패하는 계약 테스트를 쓴다** — 완료

`SYKeyboardTests/Storage/UserDefaultsContractTests.swift`의 `testCheonjiinBottomSpaceDefaultFallbackAndKey` 아래에 추가한다.

```swift
    @Test("숫자 키패드 스페이스 하단 배치는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testNumericKeypadBottomSpaceDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isNumericKeypadBottomSpaceEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isNumericKeypadBottomSpaceEnabled")
        #expect(DefaultValues.isNumericKeypadBottomSpaceEnabled == false)
        #expect(UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled == false)
    }
```

- [x] **Step 2: 컴파일이 실패하는지 확인한다** — 완료 (report: 3건 컴파일 에러, 기대와 일치)

```bash
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

Expected: `type 'UserDefaultsKeys' has no member 'isNumericKeypadBottomSpaceEnabled'`

- [x] **Step 3: 키와 기본값을 추가한다** — 완료

`UserDefaultsKeys.swift` — 외형 설정 구역의 `isCheonjiinBottomSpaceEnabled` 아래:

```swift
    /// 숫자 키패드 스페이스 버튼 하단 배치
    public static let isNumericKeypadBottomSpaceEnabled = "isNumericKeypadBottomSpaceEnabled"
```

`DefaultValues.swift` — 같은 위치:

```swift
    /// 숫자 키패드 스페이스 버튼 하단 배치 여부 기본값
    public static let isNumericKeypadBottomSpaceEnabled: Bool = false
```

`UserDefaultsManager.swift` — `isCheonjiinBottomSpaceEnabled` 프로퍼티 아래:

```swift
    /// 숫자 키패드 스페이스 버튼 하단 배치
    @UserDefaultsWrapper(key: UserDefaultsKeys.isNumericKeypadBottomSpaceEnabled, defaultValue: DefaultValues.isNumericKeypadBottomSpaceEnabled)
    public var isNumericKeypadBottomSpaceEnabled: Bool
```

- [x] **Step 4: 테스트가 통과하는지 확인한다** — 완료 (`UserDefaultsContractTests` 11개 전부 통과)

Step 2와 같은 명령. Expected: `** TEST SUCCEEDED **`

- [x] **Step 5: 설정 화면에 스위치를 추가한다** — 완료

`AppearanceSettingsView.swift`의 `@AppStorage` 블록에 추가한다.

```swift
    @AppStorage(UserDefaultsKeys.isNumericKeypadBottomSpaceEnabled, store: UserDefaultsManager.shared.storage)
    private var isNumericKeypadBottomSpaceEnabled = DefaultValues.isNumericKeypadBottomSpaceEnabled
```

`숫자 키패드 활성화` `Toggle`의 `.onChange` 블록 **바로 아래**에 추가한다. `한 손 키보드 활성화` → `한 손 키보드 너비`의 조건부 노출과 같은 형태다.

```swift
        if isNumericKeypadEnabled {
            Toggle(isOn: $isNumericKeypadBottomSpaceEnabled, label: {
                Text("숫자 키패드 스페이스 하단 배치")
                Text("스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림")
                    .font(.caption)
            })
            .onChange(of: isNumericKeypadBottomSpaceEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_numeric_keypad_bottom_space")
                Analytics.logEvent("numeric_keypad_bottom_space", parameters: [
                    "view": "AppearanceSettingsView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }
        }
```

- [x] **Step 6: Analytics User Property 초기화를 추가한다** — 완료

`SYKeyboardApp.swift`의 `setAnalyticsProperty(keyboardSettingsManager.isCheonjiinBottomSpaceEnabled, forName: "pref_cheonjiin_bottom_space")` 아래:

```swift
        setAnalyticsProperty(keyboardSettingsManager.isNumericKeypadBottomSpaceEnabled, forName: "pref_numeric_keypad_bottom_space")
```

- [x] **Step 7: 로컬라이징 문자열을 추가한다** — 완료 (stale 없음, 89 → 90)

`Localizable.xcstrings`의 `"strings"` 객체에 키 사전순 위치로 넣는다. 파일 끝에 개행이 없는 형식을 유지한다. 캡션 `"스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림"`은 #114가 이미 등록했으므로 **재사용하고 새로 추가하지 않는다.**

```json
    "숫자 키패드 스페이스 하단 배치" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Bottom Space Bar on Number Pad"
          }
        }
      }
    },
```

검증:

```bash
python3 -c "import json;d=json.load(open('SYKeyboard/Resources/Localizable.xcstrings'));print(len(d['strings']),[k for k,v in d['strings'].items() if v.get('extractionState')=='stale'])"
```

Expected: stale 목록이 비어 있어야 한다.

- [x] **Step 8: 앱 타깃 빌드를 확인한다** — 완료 (`** BUILD SUCCEEDED **`)

```bash
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- [x] **Step 9: 커밋한다** — 완료 (커밋 `70d36749`)

```bash
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift \
        Modules/SYKeyboardCore/Storage/DefaultValues.swift \
        Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift \
        SYKeyboard/App/SYKeyboardApp.swift \
        SYKeyboard/Presentation/KeyboardSettings/AppearanceSettingsView.swift \
        SYKeyboard/Resources/Localizable.xcstrings \
        SYKeyboardTests/Storage/UserDefaultsContractTests.swift
git commit -m "feat: #117 - 숫자 키패드 스페이스 하단 배치 설정 키와 스위치 추가"
```

---

## Task 2: 방향 정책이 `.numeric`에서 플래그를 반영

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift`
- Test: `SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift`

**Interfaces:**
- Consumes: `SYKeyboardType`, `PanDirection` (둘 다 internal)
- Produces: 시그니처 변화 없음. `.numeric` 반환값만 플래그에 반응

**현재 구현:**

```swift
        case .cheonjiin:
            return usesBottomSpaceLayout ? .right : .left
        case .naratgeul, .numeric:
            return .left
```

**변경 후:**

```swift
        case .cheonjiin, .numeric:
            // 하단 배치에서는 `switchButton`이 4행 좌측 끝으로 가므로
            // 오버레이가 펼쳐질 공간이 오른쪽밖에 없다
            return usesBottomSpaceLayout ? .right : .left
        case .naratgeul:
            return .left
```

`.naratgeul`은 하단 배치 대상이 아니므로 플래그를 무시한다. 이 이중 방어를 유지한다.

- [x] **Step 1: 실패하는 테스트를 쓴다** — 완료

`KeyboardSelectDirectionPolicyTests.swift`의 기존 `testNumericAlwaysOpensLeft`를 **교체**한다. 이름이 더 이상 사실이 아니므로 남겨두면 안 된다.

```swift
    @Test("숫자 키보드 기본 배치는 왼쪽으로 열린다")
    func testNumericDefaultOpensLeft() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric, usesBottomSpaceLayout: false) == .left
        )
    }

    @Test("숫자 키보드 하단 배치는 오른쪽으로 열린다")
    func testNumericBottomSpaceOpensRight() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric, usesBottomSpaceLayout: true) == .right
        )
    }
```

- [ ] **Step 2: 테스트가 실패하는지 확인한다**

```bash
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSelectDirectionPolicyTests
```

Expected: `testNumericBottomSpaceOpensRight`가 `.left`를 받아 실패한다.

> **미완료 (task-2-report.md 자체 기록):** policy 수정을 먼저 적용한 뒤 이 단계를 실행해
> red 상태를 직접 캡처하지 못했다. 대신 scoped 실행에서 두 테스트가 모두 통과함을 확인해
> 정책 변경이 실제로 필요했음을 간접 확인했다. 이 체크박스는 실행하지 않은 것으로 남긴다.

- [x] **Step 3: policy를 고친다** — 완료

위 "변경 후" 코드로 교체한다.

- [x] **Step 4: 테스트가 통과하는지 확인한다** — 완료 (scoped 실행 `** TEST SUCCEEDED **`, 신규 테스트 2개 통과)

Step 2와 같은 명령. Expected: `** TEST SUCCEEDED **`

- [x] **Step 5: 전체 테스트로 회귀가 없는지 확인한다** — 완료

`-only-testing`을 비우고 전체를 돌린다. 이 시점에는 아직 아무도 `.numeric`에 `true`를 넘기지 않으므로 **동작이 바뀌지 않아야 한다.** 기준선 대비 개수 증가분만 있어야 한다.

- [x] **Step 6: 커밋한다** — 완료 (커밋 `169a8d0b`)

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift \
        SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift
git commit -m "feat: #117 - 방향 정책이 숫자 키보드 하단 배치를 반영"
```

---

## Task 3: 숫자 키패드 4행 재배치

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift` (신규)

**Interfaces:**
- Consumes: `UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled` (Task 1), `SwitchButton.init(keyboard:usesBottomSpaceLayout:)`, `KeyboardSelectOverlayView.init(keyboard:usesBottomSpaceLayout:)`, `SwitchGestureHandling.usesBottomSpaceLayout` (모두 #114 결과물)
- Produces:
  - `NumericKeyboardView.init(showsLanguageSwitchButton: Bool = false, usesBottomSpaceLayout: Bool = UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled)`
  - `NumericKeyboardView.usesBottomSpaceLayout: Bool` (public stored let — `SwitchGestureHandling` 요구사항 충족)
  - `SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift`의 `makeView`·`rect` 헬퍼 (Task 4가 재사용)

**참고 이력:** 커밋 `284c5a73`(#114 Task 4)가 동일한 변환이다. `git show 284c5a73`로 확인한다.

**주의:**
- `NumericKeyboardView`는 `final class ... : UIView, NumericKeyboardLayoutProvider`이고 상속 관계가 없다. `FourByFourPlusKeyboardView`와 코드가 유사하지만 **별도 클래스이므로 공통 베이스로 추출하지 않는다.** 그 리팩터는 이 계획의 범위 밖이다.
- `KeyboardView.swift:85`가 `NumericKeyboardView(showsLanguageSwitchButton:)`만 호출하므로 기본 인자가 설정값을 집어온다. **배관을 추가하지 않는다.**
- `usesBottomSpaceLayout`은 stored property이므로 `super.init(frame:)` 이전에 대입되어야 하고, `setupUI()`와 lazy var(`languageSwitchButton`)가 그 값을 읽는다.
- `switchButton`과 `keyboardSelectOverlayView`는 현재 `var`(비-lazy)로 즉시 초기화된다. `usesBottomSpaceLayout`을 넘기려면 **`lazy var`로 바꿔야 한다.** `FourByFourPlusKeyboardView`가 이미 그 형태다.

- [x] **Step 1: 실패하는 배치 테스트를 쓴다** — 완료

`SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift`를 새로 만든다. `CheonjiinBottomSpaceLayoutTests.swift`의 구조를 그대로 따른다.

```swift
//
//  NumericBottomSpaceLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("숫자 키패드 스페이스 하단 배치")
struct NumericBottomSpaceLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool) -> NumericKeyboardView {
        let view = NumericKeyboardView(showsLanguageSwitchButton: true,
                                       usesBottomSpaceLayout: usesBottomSpaceLayout)
        view.frame = CGRect(x: 0, y: 0, width: keyboardWidth, height: keyboardHeight)
        view.layoutIfNeeded()

        return view
    }

    /// 버튼 프레임은 각자의 행 스택 좌표계에 있어 `midY`가 전부 같다.
    /// 행을 가로질러 비교하려면 키보드 뷰 좌표계로 변환해야 한다
    @MainActor
    private static func rect(_ subview: UIView, in view: UIView) -> CGRect {
        subview.convert(subview.bounds, to: view)
    }

    @Test("꺼짐 상태는 스페이스가 리턴보다 위, 전환 버튼이 우측 끝")
    func testDefaultLayoutKeepsSpaceAboveReturn() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(space.midY < returnRect.midY)
        #expect(returnRect.midY < switchRect.midY)
        // 꺼짐 배치의 modifier 스택은 4행 우측 끝에 붙는다
        #expect(abs(switchRect.maxX - Self.keyboardWidth) < 0.5)
    }

    @Test("켜짐 상태는 리턴이 스페이스보다 위, 스페이스가 전환 버튼과 같은 행")
    func testBottomSpaceLayoutMovesSpaceToLastRow() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(returnRect.midY < space.midY)
        #expect(abs(space.midY - switchRect.midY) < 0.5)
        #expect(switchRect.maxX <= space.minX + 0.5)
        // 켜짐 배치의 modifier 스택은 4행 좌측 끝에 붙는다
        #expect(abs(switchRect.minX) < 0.5)
    }

    @Test("두 배치 모두 삭제·스페이스 버튼이 한 칸 폭을 유지",
          arguments: [false, true])
    func testDeleteAndSpaceKeepSingleColumnWidth(_ usesBottomSpaceLayout: Bool) {
        let view = Self.makeView(usesBottomSpaceLayout: usesBottomSpaceLayout)
        let columnWidth = Self.keyboardWidth / 4

        // 폭은 좌표계와 무관하므로 변환이 필요 없다
        #expect(abs(view.deleteButton.frame.width - columnWidth) < 0.5)
        #expect(abs(view.spaceButton.frame.width - columnWidth) < 0.5)
    }

    @Test("켜짐 상태에서도 지구본 숨김 시 한/영이 글자 버튼 한 칸 너비")
    func testBottomSpaceLayoutKeepsLanguageSwitchWidthContract() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(view.languageSwitchButton)

        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(languageButton.frame.width
                - Self.keyboardWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 같은 modifier 스택 안이라 변환 없이 비교한다. 좌→우 전환 → 한/영
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
    }
}
```

**D1-c 확정에 따른 행 배치 테스트를 같은 파일에 함께 넣는다.** `CheonjiinBottomSpaceLayoutTests.testBottomSpaceLayoutRowAssignment` / `testDefaultLayoutRowAssignment`와 같은 형태다. `numericKeyList[3]`의 원소를 `PrimaryKeyButton.type.primaryKeyList.first`로 찾는다.

```swift
    /// `numericKeyList[3]`의 문장부호 버튼을 표시 문자로 찾는다
    @MainActor
    private static func keyButton(_ key: String, in view: NumericKeyboardView) throws -> PrimaryKeyButton {
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }

        return try #require(keyButtons.first { $0.type.primaryKeyList.first == key })
    }

    @Test("켜짐 상태는 '-'·'/'가 3행 우측, '.'·','가 4행 끝")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let hyphen = Self.rect(try Self.keyButton("-", in: view), in: view)
        let slash = Self.rect(try Self.keyButton("/", in: view), in: view)
        let period = Self.rect(try Self.keyButton(".", in: view), in: view)
        let comma = Self.rect(try Self.keyButton(",", in: view), in: view)
        let zero = Self.rect(try Self.keyButton("0", in: view), in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)

        // 2행(리턴) < 3행('-'·'/') < 4행('.'·',')
        #expect(returnRect.midY < hyphen.midY)
        #expect(hyphen.midY < period.midY)
        // 3행 우측 칸 안에서 좌→우 '-' → '/'
        #expect(abs(slash.midY - hyphen.midY) < 0.5)
        #expect(hyphen.maxX <= slash.minX + 0.5)
        #expect(abs(slash.maxX - Self.keyboardWidth) < 0.5)
        // 4행 안에서 좌→우 modifier → '0' → space → '.' → ','
        #expect(abs(comma.midY - period.midY) < 0.5)
        #expect(abs(zero.midY - period.midY) < 0.5)
        #expect(zero.maxX <= space.minX + 0.5)
        #expect(space.maxX <= period.minX + 0.5)
        #expect(period.maxX <= comma.minX + 0.5)
        #expect(abs(comma.maxX - Self.keyboardWidth) < 0.5)
    }

    @Test("꺼짐 상태는 4행이 좌→우 '-' ',' '0' '.' '/' modifier 순서를 유지")
    func testDefaultLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let hyphen = Self.rect(try Self.keyButton("-", in: view), in: view)
        let comma = Self.rect(try Self.keyButton(",", in: view), in: view)
        let zero = Self.rect(try Self.keyButton("0", in: view), in: view)
        let period = Self.rect(try Self.keyButton(".", in: view), in: view)
        let slash = Self.rect(try Self.keyButton("/", in: view), in: view)
        let switchRect = Self.rect(view.switchButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)

        // 다섯 글자 버튼이 모두 4행이고 리턴(3행)보다 아래다
        #expect(returnRect.midY < hyphen.midY)
        [comma, zero, period, slash].forEach { #expect(abs($0.midY - hyphen.midY) < 0.5) }
        #expect(abs(hyphen.minX) < 0.5)
        #expect(hyphen.maxX <= comma.minX + 0.5)
        #expect(comma.maxX <= zero.minX + 0.5)
        #expect(zero.maxX <= period.minX + 0.5)
        #expect(period.maxX <= slash.minX + 0.5)
        #expect(slash.maxX <= switchRect.minX + 0.5)
    }
```

- [x] **Step 2: 컴파일이 실패하는지 확인한다** — 완료 (기대한 문구와 정확히 일치, 0개 실행 허위 성공 아님을 확인)

Expected: `extra argument 'usesBottomSpaceLayout' in call`

- [x] **Step 3: `NumericKeyboardView`에 플래그를 넣고 하위 컴포넌트에 전달한다** — 완료

`private let showsLanguageSwitchButton: Bool` 아래에 추가:

```swift
    /// 스페이스를 맨 아랫줄로 내리는 배치 사용 여부.
    /// `SwitchGestureHandling` 요구사항이므로 `public`이어야 한다
    public let usesBottomSpaceLayout: Bool
```

`switchButton`과 `keyboardSelectOverlayView`를 `lazy var`로 바꾸고 플래그를 전달한다.

```swift
    public private(set) lazy var switchButton = SwitchButton(
        keyboard: .numeric,
        usesBottomSpaceLayout: usesBottomSpaceLayout
    )
```

```swift
    private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(
            keyboard: .numeric,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        overlayView.isHidden = true

        return overlayView
    }()
```

`init` 교체:

```swift
    init(showsLanguageSwitchButton: Bool = false,
         usesBottomSpaceLayout: Bool = UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled) {
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.usesBottomSpaceLayout = usesBottomSpaceLayout
        super.init(frame: .zero)
        setupUI()
    }
```

- [x] **Step 4: `setHierarchy()`를 분기한다** — 완료 (꺼짐 분기 컨테이너별 순서를 `169a8d0b` 원본과 대조해 일치 확인)

D1-c 확정 코드다. 스택 객체 두 개는 그대로 쓰고, **어느 버튼이 어느 스택에 들어가는지**를
분기 안으로 옮긴다. 꺼짐 분기의 멤버십·순서는 현행과 한 글자도 다르지 않아야 한다.

```swift
    func setHierarchy() {
        [layoutVStackView,
         keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }

        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { layoutVStackView.addArrangedSubview($0) }

        firstRowPrimaryKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.addArrangedSubview(deleteButton)

        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        thirdRowPrimaryKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }

        let modifierButtons: [SecondaryButton]
        if usesBottomSpaceLayout {
            // 스페이스가 4행으로 내려가면서 리턴이 2행, 우측 글자 스택이 3행 우측 칸으로
            // 올라가고 좌측 글자 스택이 4행 끝으로 간다.
            // 모든 행은 그대로 4칸 균등 분할이다.
            // 숫자 입력에서 가장 잦은 '.'과 ','를 엄지에 가까운 4행 끝에 모으고
            // '-'와 '/'를 3행 우측으로 올린다
            [fourthRowPrimaryKeyButtonList[3], fourthRowPrimaryKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
            [fourthRowPrimaryKeyButtonList[0], fourthRowPrimaryKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }

            secondRowHStackView.addArrangedSubview(returnButton)
            thirdRowHStackView.addArrangedSubview(fourthRowRightPrimaryButtonHStackView)

            [fourthRowRightSecondaryButtonHStackView,
             fourthRowPrimaryKeyButtonList[2],
             spaceButton,
             fourthRowLeftPrimaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }

            modifierButtons = [switchButton]
            + [languageSwitchButton].compactMap { $0 }
            + [nextKeyboardButton]
        } else {
            [fourthRowPrimaryKeyButtonList[0], fourthRowPrimaryKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
            [fourthRowPrimaryKeyButtonList[3], fourthRowPrimaryKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }

            secondRowHStackView.addArrangedSubview(spaceButton)
            thirdRowHStackView.addArrangedSubview(returnButton)

            [fourthRowLeftPrimaryButtonHStackView,
             fourthRowPrimaryKeyButtonList[2],
             fourthRowRightPrimaryButtonHStackView,
             fourthRowRightSecondaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }

            modifierButtons = [nextKeyboardButton]
            + [languageSwitchButton].compactMap { $0 }
            + [switchButton]
        }
        modifierButtons.forEach(fourthRowRightSecondaryButtonHStackView.addArrangedSubview)
    }
```

**꺼짐 분기 검증:** `git show <기준커밋>:Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift`의 원본 `setHierarchy()`와 컨테이너별 `arrangedSubviews` 순서를 대조한다. 호출 순서가 아니라 **부모별 결과 순서**가 기준이다.

- [x] **Step 5: 배치 테스트가 통과하는지 확인한다** — 완료 (`NumericBottomSpaceLayoutTests` 6개 + `KeyboardModifierLayoutTests` 숫자 관련 3개 전부 통과)

```bash
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NumericBottomSpaceLayoutTests \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests
```

`KeyboardModifierLayoutTests`의 기존 숫자 키보드 테스트 3개(`:206`, `:223`, `:246`)가 함께 통과해야 한다.

**주의:** 그 3개는 `NumericKeyboardView(showsLanguageSwitchButton:)`만 호출하므로 새 기본 인자를 통해 영속 `UserDefaults`를 읽게 된다. #114에서 `FourByFourFixture.cheonjiin`이 같은 문제로 `usesBottomSpaceLayout: false`를 명시하도록 고쳤다(커밋 `0b7bf055`). **세 곳 모두 `usesBottomSpaceLayout: false`를 명시하도록 함께 고친다.**

- [x] **Step 6: 커밋한다** — 완료 (커밋 `73f5ab9b`)

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift \
        SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift \
        SYKeyboardTests/Utils/KeyboardModifierLayoutTests.swift
git commit -m "feat: #117 - 숫자 키패드 하단 배치에서 스페이스와 리턴 행 재구성"
```

---

## Task 4: 선택 오버레이 앵커 반전

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift`

**Interfaces:**
- Consumes: `NumericKeyboardView.usesBottomSpaceLayout` (Task 3), `KeyboardLayoutFigure.keyboardSelectBoundaryInset`(4.0), `keyboardSelectCancelMinWidth`(32.0), `selectOverlayHeight`(60.0), `oneHandedModeSelectOverlayWidth`(240.0)
- Produces: 없음

**참고 이력:** 커밋 `0b7bf055`(#114 Task 5)가 동일한 변환이다.

- [x] **Step 1: 실패하는 앵커 테스트를 쓴다** — 완료

`NumericBottomSpaceLayoutTests.swift` 끝에 추가한다.

**중요 — #114에서 얻은 교훈:** 취소 경계 제약(우선순위 999)은 `switchButton`이 `keyboardSelectCancelMinWidth`(32)보다 넉넉히 넓을 때만 성립한다. 지구본이 보이면 modifier 칸이 `.fillEqually`로 3등분되어 버튼이 ~32.5pt로 좁아지고 999가 required에 양보한다(실측 오차 15.67pt). **취소 경계를 단언하는 테스트는 반드시 지구본을 숨긴 뒤 검증한다.**

```swift
    @Test("켜짐 상태의 키보드 선택 오버레이는 좌측에서 시작하고 취소 경계가 전환 버튼 우측 모서리 안쪽")
    func testBottomSpaceLayoutKeyboardSelectOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        // 취소 경계(우선순위 999)는 `switchButton`이 최소 폭 32보다 넉넉할 때만 성립한다.
        // 지구본이 보이면 modifier 칸이 3등분되어 버튼이 좁아지고 999가 양보하므로 숨긴다
        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let overlay = view.keyboardSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        // 오버레이는 키보드 뷰의 직접 subview라 frame이 이미 뷰 좌표계다
        #expect(abs(overlay.frame.minX - 4) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)

        let xmarkInView = overlay.convert(overlay.xmarkImageContainerView.frame, to: view)
        #expect(
            abs(xmarkInView.maxX
                - (switchRect.maxX - KeyboardLayoutFigure.keyboardSelectBoundaryInset)) < 0.5
        )
        #expect(xmarkInView.width >= KeyboardLayoutFigure.keyboardSelectCancelMinWidth)
        // `.right` 방향이면 X가 스택의 첫 칸이라 오버레이 왼쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.minX
                - overlay.directionalLayoutMargins.leading) < 0.5
        )
    }

    @Test("켜짐 상태의 한 손 모드 오버레이는 전환 버튼 위 좌측에 놓임")
    func testBottomSpaceLayoutOneHandedOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.oneHandedModeSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        let overlay = view.oneHandedModeSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.minX - 4) < 0.5)
        #expect(overlay.frame.maxY <= switchRect.minY - 4 + 0.5)
        #expect(abs(overlay.frame.width - KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth) < 0.5)
    }

    @Test("꺼짐 상태의 오버레이는 기존처럼 우측 정렬을 유지")
    func testDefaultLayoutOverlayKeepsTrailingAnchor() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        view.keyboardSelectOverlayView.isHidden = false
        view.layoutIfNeeded()

        view.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        let overlay = view.keyboardSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.maxX - (Self.keyboardWidth - 4)) < 0.5)

        let xmarkInView = overlay.convert(overlay.xmarkImageContainerView.frame, to: view)
        #expect(
            abs(xmarkInView.minX
                - (switchRect.minX + KeyboardLayoutFigure.keyboardSelectBoundaryInset)) < 0.5
        )
        #expect(xmarkInView.width >= KeyboardLayoutFigure.keyboardSelectCancelMinWidth)
        // `.left` 방향이면 X가 스택의 마지막 칸이라 오버레이 오른쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.maxX
                - (overlay.bounds.width - overlay.directionalLayoutMargins.trailing)) < 0.5
        )
    }
```

- [x] **Step 2: 테스트가 실패하는지 확인한다** — 완료 (`testBottomSpaceLayoutKeyboardSelectOverlayAnchors`/`testBottomSpaceLayoutOneHandedOverlayAnchors` FAIL, 나머지 PASS — 기대와 일치)

Expected: 켜짐 앵커 테스트 2개가 실패하고 꺼짐 테스트는 통과한다.

- [x] **Step 3: `setConstraints()`의 오버레이 제약을 분기한다** — 완료

`keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false`부터 함수 끝까지를 교체한다. 공통 제약을 분기 밖으로 빼고 분기 안에는 정렬만 남긴다. **취소 경계의 우선순위 999는 두 분기 모두 유지한다** — 분기 밖 단일 지점에서 설정하면 누락이 구조적으로 불가능하다.

```swift
        keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        oneHandedModeSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            keyboardSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            keyboardSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight),
            oneHandedModeSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            oneHandedModeSelectOverlayView.widthAnchor.constraint(equalToConstant: KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth),
            oneHandedModeSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight)
        ])

        // 취소 영역의 경계선을 `switchButton`의 바깥 모서리보다 안쪽에 둔다.
        // 오버레이가 열리는 순간 손가락이 이미 목표 쪽에 있게 된다
        let cancelBoundary: NSLayoutConstraint
        if usesBottomSpaceLayout {
            // `switchButton`이 4행 좌측 끝이므로 오버레이는 오른쪽으로 펼쳐진다
            NSLayoutConstraint.activate([
                keyboardSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
                oneHandedModeSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4)
            ])
            cancelBoundary = keyboardSelectOverlayView.xmarkImageContainerView.trailingAnchor.constraint(
                equalTo: switchButton.trailingAnchor,
                constant: -KeyboardLayoutFigure.keyboardSelectBoundaryInset
            )
        } else {
            NSLayoutConstraint.activate([
                keyboardSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
                oneHandedModeSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4)
            ])
            cancelBoundary = keyboardSelectOverlayView.xmarkImageContainerView.leadingAnchor.constraint(
                equalTo: switchButton.leadingAnchor,
                constant: KeyboardLayoutFigure.keyboardSelectBoundaryInset
            )
        }
        cancelBoundary.priority = .init(999)
        NSLayoutConstraint.activate([
            cancelBoundary,
            keyboardSelectOverlayView.xmarkImageContainerView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: KeyboardLayoutFigure.keyboardSelectCancelMinWidth
            )
        ])
    }
```

- [x] **Step 4: 테스트가 통과하는지 확인한다** — 완료 (`NumericBottomSpaceLayoutTests` 10개 전부 PASS, `HangeulEnglishKeyboard` 빌드도 확인)

Expected: `** TEST SUCCEEDED **`, 앵커 테스트 3개 모두 통과

- [x] **Step 5: 커밋한다** — 완료 (커밋 `396920cc`)

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/NumericKeyboardView.swift \
        SYKeyboardTests/Utils/NumericBottomSpaceLayoutTests.swift
git commit -m "feat: #117 - 숫자 키패드 하단 배치에서 선택 오버레이 방향 반전"
```

---

## Task 5: 전체 검증

- [x] **Step 1: 전체 테스트를 실행한다** — 완료

```bash
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

기준선(Task 0 Step 4) 대비 **증가분만 있고 감소는 없어야 한다.**

- [x] **Step 2: 세 키보드 extension을 빌드한다** — 완료

`-only-testing`이나 coverage 옵션이 남지 않은 새 명령으로 실행한다.

```bash
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' || break
done
```

- [x] **Step 3: 변경 범위를 확인한다** — 완료 (범위 초과 없음)

```bash
git status --short
git diff --stat develop...HEAD
```

`FourByFourPlusKeyboardView.swift`, `FourByFourKeyboardView.swift`, `CheonjiinKeyboardView.swift`, `NaratgeulKeyboardView.swift`, `DubeolsikKeyboardView.swift`, `EnglishKeyboardView.swift`, `StandardKeyboardView.swift`, `SymbolKeyboardView.swift`, `project.pbxproj`가 diff에 있으면 **범위 초과다.**

- [x] **Step 4: 계획 문서에 검증 결과를 기록하고 커밋한다** — 완료 (본 절, 아래 검증 기록 표)

실제 명령, 시뮬레이터 기기명·OS, 테스트 개수(고유/전개), 빌드 결과, `.xcresult` 경로와 추출 명령을 남긴다.

- [x] **Step 5: 실제 입력 앱에서 수동 확인한다 (자동 테스트로 대체 불가)** — **사용자 직접 확인 완료 (2026-08-28)**

> **확인 주체는 사용자다.** CLI 세션에서는 호스트 앱에서 키보드 확장을 활성화하고
> 레이아웃·제스처·오버레이를 관찰할 수 없으므로, 사용자가 실기기에서 직접 확인한 뒤
> 문제 없음을 보고했다. 자동 테스트가 원리적으로 검증할 수 없는 두 가지 —
> (1) 켜짐 배치 선택 오버레이의 실제 화면 외형과 드래그 취소 제스처 방향,
> (2) 전환 버튼 코너 힌트 화살표가 실제 제스처 방향과 일치하는지 — 도 여기에 포함된다.
>
> 아래 표의 ☑은 **사용자의 전체 확인 보고를 근거로 한 일괄 표기**이며, 세션에서 항목별로
> 관찰 결과를 개별 기록한 것이 아니다. 항목별 근거가 필요하면 사용자에게 재확인해야 한다.

| 확인 항목 | 꺼짐 | 켜짐 |
|---|---|---|
| 외형 설정에서 `숫자 키패드 활성화`가 켜졌을 때만 새 스위치가 보임 | ☑ | ☑ |
| 숫자 키패드 진입(`!#1`/`한글` 드래그) 후 배치 | ☑ | ☑ |
| 스페이스 입력·길게 눌러 커서 드래그 | ☑ | ☑ |
| 리턴 입력 | ☑ | ☑ |
| 전환 버튼에서 목표 방향 드래그 → 기호 키보드 전환 | ☑ 왼쪽 | ☑ 오른쪽 |
| 전환 버튼 코너 힌트 화살표가 실제 제스처 방향과 일치 | ☑ | ☑ |
| 전환 버튼 위로 드래그 → 한 손 모드 오버레이가 버튼 위에 뜸 | ☑ | ☑ |
| 한 손 키보드 좌/우 모드에서 오버레이가 화면 밖으로 잘리지 않음 | ☑ | ☑ |
| 한 손 최소 폭 × 켜짐 × 지구본 표시 조합에서 4행이 깨지지 않음 | ☑ | ☑ |
| 한영 통합 키보드에서 한/영 버튼 폭과 순서 | ☑ | ☑ |
| 천지인 하단 배치 설정과 **독립적으로** 동작(한쪽만 켜도 다른 쪽 불변) | ☑ | ☑ |

---

## 검증 기록

> Task 5 Step 4에서 채운다. 실행하지 못한 항목은 이유와 함께 남긴다.

| 항목 | 명령 | 결과 | 비고 |
|---|---|---|---|
| 기준선 테스트 (Task 0 Step 4, 브랜치 시작 시점) | `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` | `** TEST SUCCEEDED **`. 고유 481 / 전개 497, 실패 0. 시뮬레이터: iPhone 13 mini / iOS 16.0 | `.xcresult`: `~/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.28_21-17-22-+0900.xcresult` (`progress.md` 기록). 추출: `RES=$(ls -td ~/Library/Developer/Xcode/DerivedData/SYKeyboard-*/Logs/Test/*.xcresult \| head -1); xcrun xcresulttool get test-results summary --path "$RES"` |
| 최종 전체 테스트 (Task 5 Step 1, 이 세션) | 위와 동일 명령, foreground, timeout 600000ms | `** TEST SUCCEEDED **`. 고유(top-level `passedTests`) 492, 전개(`devicesAndConfigurations[0].passedTests`) 508, `failedTests` 0, `result: "Passed"`. 시뮬레이터: iPhone 13 mini / iOS 16.0 | `.xcresult`: `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.28_22-16-47-+0900.xcresult`. 추출 명령은 위와 동일. 기준선(481/497) 대비 증가만 있고 감소 없음(+11 unique / +11 expanded, 감소분 없음). Task 1→2→3→4 진행에 따른 고유 개수: 481→482→483→489→492, 이 세션에서 신규 테스트 추가 없이 동일하게 492 확인 |
| HangeulKeyboard 빌드 (Task 5 Step 2) | `xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` | `** BUILD SUCCEEDED **` | `-only-testing`/coverage 옵션 없는 별도 foreground 호출 |
| EnglishKeyboard 빌드 (Task 5 Step 2) | `xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` | `** BUILD SUCCEEDED **` | 별도 foreground 호출 |
| HangeulEnglishKeyboard 빌드 (Task 5 Step 2) | `xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` | `** BUILD SUCCEEDED **` | 별도 foreground 호출. Task 4에서도 이미 한 차례 빌드 확인함(리뷰 지시로 선반영) |
| 변경 범위 (Task 5 Step 3) | `git status --short` / `git diff --stat 4894613b...HEAD` (`4894613b`는 `develop`과의 merge-base, `develop...HEAD`와 동일한 diff) | `git status --short` 출력 없음(클린). `git diff --stat` 14개 파일 변경: `KeyboardSelectDirectionPolicy.swift`, `NumericKeyboardView.swift`, `DefaultValues.swift`, `UserDefaultsKeys.swift`, `UserDefaultsManager.swift`, `SYKeyboardApp.swift`, `AppearanceSettingsView.swift`, `Localizable.xcstrings`, `UserDefaultsContractTests.swift`, `KeyboardModifierLayoutTests.swift`, `KeyboardPrimaryViewCollectionTests.swift`, `KeyboardSelectDirectionPolicyTests.swift`, `NumericBottomSpaceLayoutTests.swift`(신규), 계획 문서 자신(신규) | **범위 초과 없음.** 브리프가 금지한 9개 파일(`FourByFourPlusKeyboardView.swift` 등, `project.pbxproj` 포함) 전부 diff에 없음. `.superpowers/`는 git-ignored라 diff에 없음(의도대로) |
| 수동 확인 (Task 5 Step 5) | (CLI 명령 없음 — 사용자가 실기기에서 직접 확인) | **사용자 확인 완료 (2026-08-28).** 사용자가 실기기에서 확인 후 문제 없음을 보고함 | 세션이 관찰한 것이 아니라 사용자 보고를 옮긴 기록이다. 체크리스트의 ☑은 전체 확인 보고에 따른 일괄 표기이며 항목별 관찰 로그가 아니다. 자동 테스트로 증명 불가능한 두 항목 — (1) 켜짐 배치 선택 오버레이의 실제 외형과 드래그 취소 제스처 방향, (2) 전환 버튼 코너 힌트 화살표와 실제 제스처 방향의 일치 — 도 이 확인에 포함된다 |

### 최종 리뷰 fix wave 이후 재검증

브랜치 전체 리뷰(`4894613b..c1d933d0`)에서 Important 1건이 나와 fix wave를 한 차례 돌렸다.

| 항목 | 명령 | 결과 | 비고 |
|---|---|---|---|
| fix wave 후 전체 테스트 | `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` | `** TEST SUCCEEDED **`. 고유 493 / 전개 509, 실패 0 | `.xcresult`: `~/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.28_22-46-01-+0900.xcresult`. 추출 명령은 위와 동일. 492 → 493의 +1은 신규 `testDefaultLayoutOneHandedOverlayAnchors` |

수정한 내용은 커밋 `afd8f169`(test), `94ed2056`(docs) 두 개다.

- **`KeyboardPrimaryViewCollectionTests`가 새 설정 OFF에 암묵 의존.** `KeyboardView.loadFromNib(...)`이
  `numericKeyboardView`를 새 기본 인자로 lazy 생성하므로, 사용자가 앱에서 설정을 켠 시뮬레이터에서는
  modifier 순서 단언이 실패해 제품 회귀처럼 보인다. `UserDefaultsContractTests`의
  `restore(_:forKey:in:)` 관용구로 값을 `false`로 고정하고 `defer`로 복원하도록 고쳤다.
  계획서 함정 목록 4번과 같은 유형인데, 뷰가 간접 생성돼 `KeyboardModifierLayoutTests` 수정 때 놓쳤다.
- **OFF 상태 `oneHandedModeSelectOverlayView` 앵커 회귀 테스트 부재.** Task 4에서 한 손 오버레이 제약이
  분기 블록으로 옮겨졌는데 OFF 쪽 trailing 앵커를 고정하는 테스트가 없었다.
  `testDefaultLayoutOneHandedOverlayAnchors`를 추가했다.
- **`KeyboardSelectDirectionPolicy.swift` 주석 정확성.** 아래 보류 항목에 있던 문서 부정확을 함께 해소했다.

### 알려진 보류 항목 (비고)

- **~~`KeyboardSelectDirectionPolicy.swift` 문서 정확성~~ (해소).** 타입 헤더 주석이 오버레이 앵커를
  `FourByFourPlusKeyboardView`로만 지칭하고 `usesBottomSpaceLayout` 파라미터 문서도
  "천지인 ... 여부"로 남아 있던 문제를 커밋 `94ed2056`에서 고쳤다.
- **커밋 `396920cc`의 목적 혼합.** 오버레이 방향 반전(Task 4 본 변경)과 Task 3 리뷰에서
  나온 테스트 강화 후속 조치 2건(OFF 경계를 `nextKeyboardButton`에 고정, ON 3행 `-`/`/`
  칸 폭 4분할 단언)이 한 커밋에 같이 들어갔다. 저장소 관례(커밋 1개 = 목적 1개)와
  어긋나지만, 히스토리 재작성 비용이 이득보다 크다고 판단해 그대로 둔다.

---

## 이슈 #114에서 가져온 함정 목록

같은 실수를 반복하지 않기 위해 기록한다. 전부 실제로 발생했다.

1. **프레임 좌표계.** 버튼 프레임은 각자의 행 스택 좌표계에 있어 `frame.midY`가 전부 27.0으로 같다. 행 간 비교는 `subview.convert(subview.bounds, to: view)` 필수. 변환을 빠뜨리면 항상 통과하거나 항상 실패하는 공허한 단언이 된다.
2. **flush 위치 단언.** 꺼짐 배치에서 `spaceButton`과 `switchButton`은 둘 다 우측 끝(`maxX == W`)이라 서로 비교하는 엄격 부등호가 성립하지 않는다. 키보드 폭에 직접 걸어라(`abs(switchRect.maxX - keyboardWidth) < 0.5` / `abs(switchRect.minX) < 0.5`).
3. **취소 경계와 지구본.** 지구본이 보이면 `switchButton`이 ~32.5pt로 좁아져 999 우선순위 취소 경계가 required 최소 폭 32에 밀린다(오차 15.67pt). 취소 경계를 단언하기 전에 `updateNextKeyboardButton(needsInputModeSwitchKey: false, ...)`로 지구본을 숨겨라. **이건 `develop`에도 있는 기존 제약이며 고치지 않는다.**
4. **영속 설정에 의존하는 기존 테스트.** 기본 인자가 `UserDefaults`를 읽으므로, 기존 테스트가 그 뷰를 인자 없이 만들면 시뮬레이터 상태에 따라 flaky해진다. `KeyboardModifierLayoutTests`의 `NumericKeyboardView(...)` 3곳에 `usesBottomSpaceLayout: false`를 명시하라.
5. **공허한 성공.** `-only-testing`으로 좁힌 실행이 0개 실행하고 `TEST SUCCEEDED`를 내는 경우가 있다. 로그에 실행 흔적이 없으면 통과로 세지 마라. 최종 확인은 전체 스위트로.
6. **백그라운드 테스트 대기 금지.** `xcodebuild`를 포그라운드로 호출하고 그 한 번의 호출 안에서 결과를 기다려라. 백그라운드 대기 중 멈추면 진행이 막힌다.
7. **테스트 이름 ↔ 커버리지 일치.** `CLAUDE.md` 규칙이다. 이름이 검증 범위보다 넓으면 리뷰에서 지적된다.
