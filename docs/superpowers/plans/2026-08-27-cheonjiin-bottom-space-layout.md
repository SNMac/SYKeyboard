# 천지인 스페이스 하단 배치 설정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 천지인 키보드에서 스페이스를 맨 아랫줄로 옮기는 스위치 설정을 추가하고, 기본값(꺼짐)에서는 현재 배치와 완전히 동일하게 동작하게 한다.

**Architecture:** 설정은 App Group `UserDefaults` 키 하나로 두고, `CheonjiinKeyboardView`가 생성 시점에 읽어 `FourByFourPlusKeyboardView`에 주입한다. 배치가 바뀌면 `switchButton`이 4행 좌측 끝으로 이동하므로 키보드 선택 오버레이의 방향 계약(제스처 판정 · 오버레이 내부 순서 · 코너 힌트 라벨 · 오버레이 앵커) 네 곳이 함께 뒤집혀야 한다. 이 방향을 새 순수 타입 `KeyboardSelectDirectionPolicy` 한 곳에서 결정하고 네 소비처가 모두 그 값을 쓰게 만든다.

**Tech Stack:** Swift 5 / Xcode 26, UIKit(키보드 확장), SwiftUI(`@AppStorage` 설정 화면), Swift Testing, Firebase Analytics

**Spec:** [GitHub Issue #114](https://github.com/SNMac/SYKeyboard/issues/114) — 단, 아래 "확정된 설계 결정"이 이슈 본문보다 우선한다. 이슈의 안 A를 채택하되 적용 범위를 천지인으로 좁혔고, 설정 위치를 `AppearanceSettingsView`에서 `HangeulKeyboardSelectView`로 옮겼다.

---

## Global Constraints

- 설정 기본값은 **꺼짐(`false`)**이며, 꺼짐 상태의 렌더링 결과는 현재 `develop`과 픽셀 단위로 동일해야 한다.
- 적용 대상은 **천지인(`FourByFourPlusKeyboardView` / `CheonjiinKeyboardView`)뿐이다.** 나랏글(`FourByFourKeyboardView` / `NaratgeulKeyboardView`), 두벌식, 쿼티, 기호, 숫자 키보드는 **한 줄도 바뀌지 않아야 한다.**
- `UserDefaults` 키 문자열: `"isCheonjiinBottomSpaceEnabled"`. 기본값 `false`. App Group suite(`DefaultValues.groupBundleID`) 공유.
- Analytics User Property 이름: `pref_cheonjiin_bottom_space`. Event 이름: `cheonjiin_bottom_space`.
- 브랜치: `feat/#114-cheonjiin-bottom-space` (base: `develop`).
- 커밋 메시지: `feat: #114 - <결과 중심 한국어 서술구>`, 마침표 없음. 한 커밋에 한 목적.
- `Modules/`에 새 `.swift` 파일을 추가하면 `SYKeyboard.xcodeproj/project.pbxproj`의 **두 개** `membershipExceptions` 목록(`SYKeyboard` 타깃 블록, `SYKeyboardCore` 타깃 블록)에 알파벳 순으로 등록해야 한다. `SYKeyboardTests/`는 동기화 그룹이라 등록이 필요 없다.
- 검증 기준 시뮬레이터: `iPhone 13 mini / iOS 16.0`. 해당 런타임이 없으면 가장 가까운 iOS 16+ 시뮬레이터로 조정하고 최종 보고에 실제 기기명과 OS를 적는다.
- `-only-testing`이나 code coverage 옵션을 쓴 뒤 extension scheme을 빌드할 때는 옵션을 반드시 비운다.
- **버튼 프레임은 각자의 행 스택 좌표계에 있다.** `deleteButton`, `spaceButton`, `returnButton`, `switchButton`은 서로 다른 `KeyboardRowHStackView` 안에 있어 `frame.midY`가 전부 27.0(행 높이 54의 중앙)으로 같다. **행을 가로지르는 위치 비교는 반드시 키보드 뷰 좌표계로 변환한다**: `subview.convert(subview.bounds, to: view)`. 같은 컨테이너 안의 비교(`switchButton` vs `languageSwitchButton`, `@` vs `#`)와 폭 비교는 변환이 필요 없다.

---

## 확정된 설계 결정

이슈 본문의 미결 항목을 사용자와 확정한 결과다. 구현 중 이 표와 충돌하는 판단이 생기면 코드를 고치지 말고 사용자에게 확인한다.

| 항목 | 결정 |
|---|---|
| 배치안 | **안 A**(기존 천지인 배치 재현) |
| 적용 범위 | **천지인만.** 나랏글은 대상 아님 |
| 3행 우측 칸 | `.` / `,` (기존 `fourthRowLeftPrimaryButtonHStackView`를 그대로 재부모화) |
| 4행 우측 끝 칸 | `?` / `!` (기존 `fourthRowRightPrimaryButtonHStackView` 유지) |
| 4행 첫 칸 | modifier 스택. 좌→우 `!#1` → `한/영` → `🌐` |
| modifier 폭 분배 | **현재 계약 그대로.** 지구본 숨김 → `.fill`(한/영 `0.1W` 고정 + `!#1`이 나머지), 지구본 표시 → `.fillEqually`(3등분) |
| 선택 오버레이 방향 | **`targetDirection`까지 `.right`로 반전.** 오버레이가 `!#1` 오른쪽으로 열리고, 코너 힌트도 `123▶` 형태로 미러링 |
| 설정 위치 | `HangeulKeyboardSelectView`, `selectedHangeulKeyboard == .cheonjiin`일 때만 노출 |

### 켜짐 상태 배치 (천지인)

```
[꺼짐 = 현재]                        [켜짐]
ㅣ    ㆍ    ㅡ    ⌫                 ㅣ    ㆍ    ㅡ    ⌫
ㄱㅋ  ㄴㄹ  ㄷㅌ  space              ㄱㅋ  ㄴㄹ  ㄷㅌ  ↵ @ #
ㅂㅍ  ㅅㅎ  ㅈㅊ  ↵ @ #              ㅂㅍ  ㅅㅎ  ㅈㅊ  . ,
. ,  ㅇㅁ  ? !   🌐 한/영 !#1        !#1 한/영 🌐  ㅇㅁ  space  ? !
```

두 배치 모두 **네 행 전부가 4칸 균등 분할**을 유지한다. 어떤 칸도 폭 계약이 바뀌지 않으므로 `KeyboardRowHStackView` 자체는 손대지 않는다.

---

## File Structure

### 신규

| 경로 | 책임 |
|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift` | 키보드 종류 + 하단 배치 여부 → 선택 오버레이 방향(`PanDirection`). UI 의존 없는 순수 타입 |
| `SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift` | 위 policy 단위 테스트 |
| `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift` | 켜짐/꺼짐 배치, 오버레이 앵커, `UIKeyboardType` 5종 모드 회귀 |

### 수정

| 경로 | 변경 |
|---|---|
| `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` | 외형 설정 구역에 키 추가 |
| `Modules/SYKeyboardCore/Storage/DefaultValues.swift` | 외형 설정 구역에 기본값 `false` 추가 |
| `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` | `@UserDefaultsWrapper` 프로퍼티 추가 |
| `SYKeyboard/App/SYKeyboardApp.swift` | Analytics User Property 초기화 한 줄 |
| `SYKeyboard/Presentation/KeyboardSettings/HangeulKeyboardSelectView.swift` | 천지인 선택 시 `Toggle` 노출 |
| `SYKeyboard/Resources/Localizable.xcstrings` | 라벨·캡션 en 번역 |
| `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/Protocols/SwitchGestureHandling.swift` | `usesBottomSpaceLayout` 요구사항 + 기본값 `false` |
| `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift` | `setPanConfig()`의 방향 리터럴을 policy 호출로 교체 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift` | 코너 힌트 라벨 위치·화살표를 policy 결과로 결정 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/KeyboardSelectOverlayView.swift` | 내부 배치 순서를 policy 결과로 결정 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift` | 하단 배치 플래그, `setHierarchy()` 분기, 오버레이 앵커 분기 |
| `Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift` | 설정값을 읽어 base로 전달 |
| `SYKeyboardTests/Storage/UserDefaultsContractTests.swift` | 새 키 계약 테스트 |
| `SYKeyboard.xcodeproj/project.pbxproj` | policy 파일 membership 2곳 |

---

## Task 0: 브랜치 준비

**Files:** 없음

- [x] **Step 1: `develop`에서 작업 브랜치를 만든다** — 완료. `feat/#114-cheonjiin-bottom-space` 생성(base `a6a34477`의 부모 `0a6167b4`), `git status --short` 출력 없음

```bash
git switch develop
git pull
git status --short   # 출력이 비어 있어야 한다. 사용자 변경이 있으면 여기서 멈추고 확인한다
git switch -c feat/#114-cheonjiin-bottom-space
```

- [x] **Step 2: 기준 상태에서 전체 테스트가 통과하는지 확인한다** — 완료. 464 passed / 0 failed (iPhone 13 mini, iOS 16.0). xcresult: `Test-SYKeyboard-2026.08.27_23-12-13-+0900`

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `** TEST SUCCEEDED **`. 이 결과가 이후 회귀 판정의 기준선이다.
실패가 `CoreSimulatorService connection became invalid`, `Operation not permitted`, `error opening ... ModuleCache` 패턴이면 **코드 실패로 기록하지 않는다.** 사용자에게 프롬프트에서 `! <명령>`으로 직접 실행하도록 요청한다.

---

## Task 1: 설정 키·기본값·매니저·설정 화면

**Files:**
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Modify: `SYKeyboard/App/SYKeyboardApp.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/HangeulKeyboardSelectView.swift`
- Modify: `SYKeyboard/Resources/Localizable.xcstrings`
- Test: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `UserDefaultsKeys.isCheonjiinBottomSpaceEnabled: String` (값 `"isCheonjiinBottomSpaceEnabled"`)
  - `DefaultValues.isCheonjiinBottomSpaceEnabled: Bool` (값 `false`)
  - `UserDefaultsManager.shared.isCheonjiinBottomSpaceEnabled: Bool`

- [x] **Step 1: 실패하는 계약 테스트를 쓴다** — 완료. `testCheonjiinBottomSpaceDefaultFallbackAndKey` 추가

`SYKeyboardTests/Storage/UserDefaultsContractTests.swift`에서 `testNaratgeulDotLabelDefaultFallbackAndKey` 바로 아래에 추가한다.

```swift
    @Test("천지인 스페이스 하단 배치는 저장값이 없으면 false를 반환하고 공유 저장소 키를 유지")
    func testCheonjiinBottomSpaceDefaultFallbackAndKey() {
        let storage = UserDefaultsManager.shared.storage
        let key = UserDefaultsKeys.isCheonjiinBottomSpaceEnabled
        let originalValue = storage.object(forKey: key)

        storage.removeObject(forKey: key)
        defer { restore(originalValue, forKey: key, in: storage) }

        #expect(key == "isCheonjiinBottomSpaceEnabled")
        #expect(DefaultValues.isCheonjiinBottomSpaceEnabled == false)
        #expect(UserDefaultsManager.shared.isCheonjiinBottomSpaceEnabled == false)
    }
```

- [x] **Step 2: 컴파일이 실패하는지 확인한다** — 완료. `type 'UserDefaultsKeys' has no member 'isCheonjiinBottomSpaceEnabled'`로 컴파일 실패 확인

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

Expected: 컴파일 에러 `type 'UserDefaultsKeys' has no member 'isCheonjiinBottomSpaceEnabled'`

- [x] **Step 3: 키와 기본값을 추가한다** — 완료

`Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift` — 외형 설정 구역의 `isNaratgeulDotLabelEnabled` 바로 아래:

```swift
    /// 천지인 스페이스 버튼 하단 배치
    public static let isCheonjiinBottomSpaceEnabled = "isCheonjiinBottomSpaceEnabled"
```

`Modules/SYKeyboardCore/Storage/DefaultValues.swift` — 외형 설정 구역의 `isNaratgeulDotLabelEnabled` 바로 아래:

```swift
    /// 천지인 스페이스 버튼 하단 배치 여부 기본값
    public static let isCheonjiinBottomSpaceEnabled: Bool = false
```

`Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift` — `isNaratgeulDotLabelEnabled` 프로퍼티 바로 아래:

```swift
    /// 천지인 스페이스 버튼 하단 배치
    @UserDefaultsWrapper(key: UserDefaultsKeys.isCheonjiinBottomSpaceEnabled, defaultValue: DefaultValues.isCheonjiinBottomSpaceEnabled)
    public var isCheonjiinBottomSpaceEnabled: Bool
```

- [x] **Step 4: 테스트가 통과하는지 확인한다** — 완료

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

Expected: `** TEST SUCCEEDED **`

- [x] **Step 5: 설정 화면에 스위치를 추가한다** — 완료. `selectedHangeulKeyboard == .cheonjiin` 조건부 `Toggle`

`SYKeyboard/Presentation/KeyboardSettings/HangeulKeyboardSelectView.swift`의 `@AppStorage` 블록에 추가한다.

```swift
    @AppStorage(UserDefaultsKeys.isCheonjiinBottomSpaceEnabled, store: UserDefaultsManager.shared.storage)
    private var isCheonjiinBottomSpaceEnabled = DefaultValues.isCheonjiinBottomSpaceEnabled
```

`body`의 나랏글 `if` 블록 바로 아래에 추가한다.

```swift
        if selectedHangeulKeyboard == .cheonjiin {
            Toggle(isOn: $isCheonjiinBottomSpaceEnabled, label: {
                Text("스페이스 하단 배치")
                Text("스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림")
                    .font(.caption)
            })
            .onChange(of: isCheonjiinBottomSpaceEnabled) { newValue in
                Analytics.setUserProperty(newValue.analyticsValue,
                                          forName: "pref_cheonjiin_bottom_space")
                Analytics.logEvent("cheonjiin_bottom_space", parameters: [
                    "view": "HangeulKeyboardSelectView",
                    "enabled": newValue.analyticsValue
                ])
                hideKeyboard()
            }
        }
```

- [x] **Step 6: Analytics User Property 초기화를 추가한다** — 완료

`SYKeyboard/App/SYKeyboardApp.swift`의 `setAnalyticsProperty(keyboardSettingsManager.isNaratgeulDotLabelEnabled, forName: "pref_naratgeul_dot_label")` 바로 아래:

```swift
        setAnalyticsProperty(keyboardSettingsManager.isCheonjiinBottomSpaceEnabled, forName: "pref_cheonjiin_bottom_space")
```

- [x] **Step 7: 로컬라이징 문자열을 추가한다** — 완료. 사전순 위치·no-trailing-newline 유지, JSON 유효성 확인

`SYKeyboard/Resources/Localizable.xcstrings`의 `"strings"` 객체에 키 사전순 위치로 두 항목을 넣는다. 파일 끝에 개행이 없는 형식을 유지한다.

```json
    "스페이스 하단 배치" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Bottom Space Bar"
          }
        }
      }
    },
    "스페이스를 맨 아랫줄로 옮기고 리턴을 위로 올림" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Move the space bar to the bottom row and the return key up"
          }
        }
      }
    },
```

- [x] **Step 8: 앱 타깃 빌드를 확인한다** — 완료. `** BUILD SUCCEEDED **`

```bash
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `** BUILD SUCCEEDED **`

- [x] **Step 9: 커밋한다** — 완료. 커밋 `560e268a`. 전체 465 고유 / 0 failed

```bash
git add Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift \
        Modules/SYKeyboardCore/Storage/DefaultValues.swift \
        Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift \
        SYKeyboard/App/SYKeyboardApp.swift \
        SYKeyboard/Presentation/KeyboardSettings/HangeulKeyboardSelectView.swift \
        SYKeyboard/Resources/Localizable.xcstrings \
        SYKeyboardTests/Storage/UserDefaultsContractTests.swift
git commit -m "feat: #114 - 천지인 스페이스 하단 배치 설정 키와 스위치 추가"
```

---

## Task 2: `KeyboardSelectDirectionPolicy` 신설

키보드 선택 오버레이가 `switchButton` 기준 어느 쪽으로 열리는지를 한 곳에서 정한다. 이 task는 policy와 테스트만 추가하고 소비처는 건드리지 않으므로 **동작이 전혀 바뀌지 않는다.**

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift`
- Test: `SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `SYKeyboardType`(public enum: `.naratgeul`, `.cheonjiin`, `.dubeolsik`, `.qwerty`, `.symbol`, `.numeric`, `.tenKey`), `PanDirection`(internal enum: `.up`, `.left`, `.right`, `.down`, `.center`)
- Produces: `KeyboardSelectDirectionPolicy.targetDirection(for:usesBottomSpaceLayout:) -> PanDirection` (internal, `SYKeyboardCore` 모듈 내부 + `@testable` 접근)

- [x] **Step 1: 실패하는 테스트를 쓴다** — 완료. 5개 테스트 작성

`SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift`를 새로 만든다.

```swift
//
//  KeyboardSelectDirectionPolicyTests.swift
//  SYKeyboardTests
//

import Testing

@testable import SYKeyboardCore

@Suite("키보드 선택 오버레이 방향 정책")
struct KeyboardSelectDirectionPolicyTests {
    @Test("천지인 기본 배치는 왼쪽으로 열린다")
    func testCheonjiinDefaultOpensLeft() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .cheonjiin, usesBottomSpaceLayout: false) == .left
        )
    }

    @Test("천지인 하단 배치는 오른쪽으로 열린다")
    func testCheonjiinBottomSpaceOpensRight() {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .cheonjiin, usesBottomSpaceLayout: true) == .right
        )
    }

    @Test("나랏글은 하단 배치 플래그와 무관하게 항상 왼쪽",
          arguments: [false, true])
    func testNaratgeulAlwaysOpensLeft(_ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .naratgeul,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .left
        )
    }

    @Test("숫자 키보드는 하단 배치 플래그와 무관하게 항상 왼쪽",
          arguments: [false, true])
    func testNumericAlwaysOpensLeft(_ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: .numeric,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .left
        )
    }

    @Test("두벌식·쿼티·기호는 하단 배치 플래그와 무관하게 항상 오른쪽",
          arguments: [SYKeyboardType.dubeolsik, .qwerty, .symbol], [false, true])
    func testRightOpeningKeyboards(_ keyboard: SYKeyboardType, _ usesBottomSpaceLayout: Bool) {
        #expect(
            KeyboardSelectDirectionPolicy.targetDirection(for: keyboard,
                                                          usesBottomSpaceLayout: usesBottomSpaceLayout) == .right
        )
    }
}
```

`PanDirection`에 `Equatable` 준수가 필요하다. `enum PanDirection { case up, left, right, down, center }`처럼 associated value가 없으면 Swift가 `Equatable`을 자동 합성하므로 `==`가 그대로 동작한다. 컴파일 에러가 나면 그때만 `enum PanDirection: Equatable`로 바꾼다.

- [x] **Step 2: 컴파일이 실패하는지 확인한다** — 완료. `cannot find 'KeyboardSelectDirectionPolicy' in scope`로 컴파일 실패 확인

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSelectDirectionPolicyTests
```

Expected: 컴파일 에러 `cannot find 'KeyboardSelectDirectionPolicy' in scope`

- [x] **Step 3: policy를 만든다** — 완료

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift`:

```swift
//
//  KeyboardSelectDirectionPolicy.swift
//  SYKeyboardCore
//

/// 키보드 선택 오버레이가 `switchButton` 기준 어느 쪽으로 열리는지 결정한다.
///
/// 이 방향은 네 곳이 함께 지켜야 한다.
/// 제스처 판정(`SwitchGestureController`), 오버레이 내부 배치(`KeyboardSelectOverlayView`),
/// 코너 힌트 라벨(`SwitchButton`), 오버레이 앵커(`FourByFourPlusKeyboardView`).
/// 어긋나면 힌트와 실제 제스처 방향이 달라지므로 한 곳에서만 정한다
enum KeyboardSelectDirectionPolicy {
    /// - Parameters:
    ///   - keyboard: 현재 키보드 종류
    ///   - usesBottomSpaceLayout: 천지인 스페이스 하단 배치 사용 여부
    static func targetDirection(for keyboard: SYKeyboardType,
                                usesBottomSpaceLayout: Bool) -> PanDirection {
        switch keyboard {
        case .cheonjiin:
            // 하단 배치에서는 `switchButton`이 4행 좌측 끝으로 가므로
            // 오버레이가 펼쳐질 공간이 오른쪽밖에 없다
            return usesBottomSpaceLayout ? .right : .left
        case .naratgeul, .numeric:
            return .left
        case .dubeolsik, .qwerty, .symbol:
            return .right
        case .tenKey:
            // 텐키에는 키보드 선택 제스처가 없다. 기존 기본값을 유지한다
            return .left
        }
    }
}
```

- [x] **Step 4: pbxproj에 등록한다** — 완료. `grep -c` = 2 (SYKeyboard 타깃 블록, SYKeyboardCore 타깃 블록)

`SYKeyboard.xcodeproj/project.pbxproj`에서 `SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift,` 줄을 찾으면 두 곳(각각 `SYKeyboard` 타깃 블록과 `SYKeyboardCore` 타깃 블록)이 나온다. **두 곳 모두** 그 바로 아래에 아래 줄을 넣는다. 들여쓰기는 탭 4개로 주변 줄과 맞춘다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift,
```

등록 확인:

```bash
grep -c "Policies/KeyboardSelectDirectionPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [x] **Step 5: 테스트가 통과하는지 확인한다** — 완료

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSelectDirectionPolicyTests
```

Expected: `** TEST SUCCEEDED **`, 10개 테스트 통과(파라미터 조합 포함)

- [x] **Step 6: 커밋한다** — 완료. 커밋 `5dee8001`. 전체 466 고유 / 0 failed

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift \
        SYKeyboardTests/Utils/KeyboardSelectDirectionPolicyTests.swift \
        SYKeyboard.xcodeproj/project.pbxproj
git commit -m "feat: #114 - 키보드 선택 오버레이 방향 정책 타입 추가"
```

- [x] **Step 7(추가): 리뷰 지적에 따른 `.tenKey` 분기 검증 추가** — 완료. 커밋 `93899f83`

계획에는 없던 step이다. Task 2 리뷰가 "Global Constraints 표는 `.tenKey → .left`를 명시하는데 브리프의 테스트 파일이 그 조합을 빠뜨렸다"는 plan-mandated Important를 올렸고, 컨트롤러가 수정하기로 판정했다. `KeyboardSelectDirectionPolicyTests`에 두 플래그 값 모두에서 `.left`를 반환하는지 확인하는 테스트를 추가했다. 전체 467 고유 / 479 전개 / 0 failed.

---

## Task 3: 방향 계약 소비처를 policy로 통일

`SwitchButton`, `KeyboardSelectOverlayView`, `SwitchGestureController`가 각자 들고 있던 `switch keyboard` 분기를 policy 호출로 바꾼다. 이 task에서는 아직 어떤 뷰도 `usesBottomSpaceLayout: true`를 넘기지 않으므로 **동작이 전혀 바뀌지 않는다.** 기존 테스트가 전부 통과해야 한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/KeyboardSelectOverlayView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/Protocols/SwitchGestureHandling.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`

**Interfaces:**
- Consumes: `KeyboardSelectDirectionPolicy.targetDirection(for:usesBottomSpaceLayout:)` (Task 2)
- Produces:
  - `SwitchButton.init(keyboard: SYKeyboardType, usesBottomSpaceLayout: Bool = false)`
  - `KeyboardSelectOverlayView.init(keyboard: SYKeyboardType, usesBottomSpaceLayout: Bool = false)`
  - `SwitchGestureHandling.usesBottomSpaceLayout: Bool` (프로토콜 요구사항, extension 기본값 `false`)

- [x] **Step 1: `SwitchGestureHandling`에 플래그를 추가한다** — 완료

`Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/Protocols/SwitchGestureHandling.swift`의 프로토콜 본문 맨 위(`switchButton` 선언 위)에 추가한다.

```swift
    /// 천지인 스페이스 하단 배치처럼 `switchButton`이 행 좌측 끝에 놓이는 레이아웃인지 여부.
    /// 키보드 선택 오버레이가 열리는 방향이 이 값에 따라 뒤집힌다
    var usesBottomSpaceLayout: Bool { get }
```

같은 파일의 `public extension SwitchGestureHandling` 맨 위에 기본 구현을 넣는다.

```swift
    var usesBottomSpaceLayout: Bool { false }
```

- [x] **Step 2: 빌드해서 기존 채택 타입이 모두 기본값으로 컴파일되는지 확인한다** — 완료. `** BUILD SUCCEEDED **`

```bash
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `** BUILD SUCCEEDED **`

- [x] **Step 3: `SwitchGestureController.setPanConfig()`의 방향 리터럴을 policy 호출로 바꾼다** — 완료. **컨트롤러 판정 R1로 브리프 수정**: `.dubeolsik`을 별도 case로 두지 않고 `case .naratgeul, .cheonjiin, .dubeolsik:`으로 병합(policy 도입 후 본문이 동일해지고 분리 근거가 추측뿐이었음)

`Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift`의 `setPanConfig()` 전체를 아래로 교체한다.

```swift
    func setPanConfig() -> PanConfig {
        let config: PanConfig
        
        let currentKeyboard = getCurrentKeyboard()
        switch currentKeyboard {
        case .naratgeul, .cheonjiin:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            config = (gestureHandler: hangeulKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: KeyboardSelectDirectionPolicy.targetDirection(
                        for: currentKeyboard,
                        usesBottomSpaceLayout: hangeulKeyboardView.usesBottomSpaceLayout))
        case .dubeolsik:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            config = (gestureHandler: hangeulKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: KeyboardSelectDirectionPolicy.targetDirection(
                        for: currentKeyboard,
                        usesBottomSpaceLayout: hangeulKeyboardView.usesBottomSpaceLayout))
        case .qwerty:
            guard let englishKeyboardView else { fatalError("옵셔널 바인딩 실패 - englishKeyboardView가 nil입니다.") }
            config = (gestureHandler: englishKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: KeyboardSelectDirectionPolicy.targetDirection(
                        for: currentKeyboard,
                        usesBottomSpaceLayout: englishKeyboardView.usesBottomSpaceLayout))
        case .symbol:
            guard let symbolKeyboardView else { fatalError("옵셔널 바인딩 실패 - symbolKeyboardView가 nil입니다.") }
            config = (gestureHandler: symbolKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: KeyboardSelectDirectionPolicy.targetDirection(
                        for: currentKeyboard,
                        usesBottomSpaceLayout: symbolKeyboardView.usesBottomSpaceLayout))
        case .numeric:
            guard let numericKeyboardView else { fatalError("옵셔널 바인딩 실패 - numericKeyboardView가 nil입니다.") }
            config = (gestureHandler: numericKeyboardView,
                      keyboardSelectTargetkeyboard: .symbol,
                      keyboardSelectTargetDirection: KeyboardSelectDirectionPolicy.targetDirection(
                        for: currentKeyboard,
                        usesBottomSpaceLayout: numericKeyboardView.usesBottomSpaceLayout))
        case .tenKey:
            fatalError("도달할 수 없는 case입니다.")
        }
        return config
    }
```

`.dubeolsik`은 `.naratgeul, .cheonjiin`과 본문이 같아졌지만, 각 case가 서로 다른 `keyboardSelectTargetkeyboard`를 갖게 되는 향후 변경에 대비해 기존 case 구분을 그대로 둔다.

- [x] **Step 4: `KeyboardSelectOverlayView`가 policy를 쓰게 한다** — 완료

`Modules/SYKeyboardCore/Presentation/View/Components/Overlays/KeyboardSelectOverlayView.swift`

프로퍼티 `private var isEmphasizingTarget: Bool?` 아래에 추가:

```swift
    private let keyboardSelectDirection: PanDirection
```

`init`을 교체:

```swift
    public init(keyboard: SYKeyboardType, usesBottomSpaceLayout: Bool = false) {
        self.keyboard = keyboard
        self.keyboardSelectDirection = KeyboardSelectDirectionPolicy.targetDirection(
            for: keyboard,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        super.init(frame: .zero)
        
        setupUI()
    }
```

`setHierarchy()`를 교체:

```swift
    func setHierarchy() {
        self.addSubview(blurView)
        
        xmarkImageContainerView.addSubview(xmarkImageView)
        
        let targetLabel: UILabel
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol:
            targetLabel = numericLabel
        case .numeric:
            targetLabel = symbolLabel
        default:
            assertionFailure("구현되지 않은 case입니다.")
            return
        }
        
        // 목표 라벨은 손가락이 향하는 쪽에, 취소(X)는 `switchButton` 위에 놓인다
        switch keyboardSelectDirection {
        case .right:
            [xmarkImageContainerView, targetLabel].forEach { self.addArrangedSubview($0) }
        default:
            [targetLabel, xmarkImageContainerView].forEach { self.addArrangedSubview($0) }
        }
    }
```

- [x] **Step 5: `SwitchButton`이 policy를 쓰게 한다** — 완료

`Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`

프로퍼티 `private let keyboard: SYKeyboardType` 아래에 추가:

```swift
    private let keyboardSelectDirection: PanDirection
```

`init`에서 `override`를 떼고 파라미터를 추가한다. `SwitchButton`은 `final`이고 자체 designated init을 가지므로 상위 `init(keyboard:)`를 상속하지 않는다. 기존 5개 호출부는 기본값 덕분에 그대로 컴파일된다.

```swift
    public init(keyboard: SYKeyboardType, usesBottomSpaceLayout: Bool = false) {
        self.keyboard = keyboard
        self.keyboardSelectDirection = KeyboardSelectDirectionPolicy.targetDirection(
            for: keyboard,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        switch keyboard {
```

(이하 `switch keyboard { case .naratgeul, ... }` 본문과 `super.init(keyboard: keyboard)`, `setupUI()`는 그대로 둔다.)

`setConstraints()`의 `switch keyboard` 블록을 교체한다.

```swift
        // 목표 라벨이 오른쪽에 있으면 힌트도 오른쪽 아래 모서리에 붙는다
        switch keyboardSelectDirection {
        case .right:
            constraints.append(oneHandedLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
            constraints.append(keyboardSelectLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))
            
        default:
            constraints.append(oneHandedLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX))
            constraints.append(keyboardSelectLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX))
        }
```

`createOneHandedAttributedText(needToEmphasize:)`의 `switch keyboard` 블록을 교체한다.

```swift
        let fullString: NSMutableAttributedString?
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol, .numeric:
            switch keyboardSelectDirection {
            case .right:
                fullString = NSMutableAttributedString(attachment: arrowtriangleUp)
                fullString?.append(NSAttributedString(attachment: attachment))
            default:
                fullString = NSMutableAttributedString(attachment: attachment)
                fullString?.append(NSAttributedString(attachment: arrowtriangleUp))
            }
        default:
            fullString = nil
        }
        return fullString
```

`createKeyboardSelectAttributedText(needToEmphasize:)`의 `switch keyboard` 블록을 교체한다.

```swift
        let text: String
        switch keyboard {
        case .naratgeul, .cheonjiin, .dubeolsik, .qwerty, .symbol:
            text = "123"
        case .numeric:
            text = "!#1"
        default:
            return nil
        }
        
        let arrowtriangle = NSTextAttachment()
        let textAttributedString = NSAttributedString(string: text, attributes: attributes)
        let fullString: NSMutableAttributedString
        
        switch keyboardSelectDirection {
        case .right:
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.right.fill" : "arrowtriangle.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            fullString = NSMutableAttributedString(attributedString: textAttributedString)
            fullString.append(NSAttributedString(attachment: arrowtriangle))
        default:
            arrowtriangle.image = UIImage(systemName: needToEmphasize ? "arrowtriangle.left.fill" : "arrowtriangle.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
            fullString = NSMutableAttributedString(attachment: arrowtriangle)
            fullString.append(textAttributedString)
        }
        
        return fullString
```

기존 함수 시그니처가 `-> NSAttributedString?`이므로 `return fullString` 그대로 동작한다. 함수 상단의 `let arrowtriangle = NSTextAttachment()`와 `let fullString: NSMutableAttributedString?` 선언이 중복되지 않도록 위 블록으로 완전히 대체한다.

- [x] **Step 6: 동작이 바뀌지 않았는지 전체 테스트로 확인한다** — 완료. 467 고유 / 479 전개 / 0 failed — Task 2 종료 시점과 동일(테스트 미추가 리팩터의 기대 결과)

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `** TEST SUCCEEDED **`. Task 0 Step 2에서 기록한 테스트 개수와 같아야 하고(Task 1·2에서 추가된 것만 증가), 실패가 하나도 없어야 한다.

- [x] **Step 7: 커밋한다** — 완료. 커밋 `b4ff99c6`

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift \
        Modules/SYKeyboardCore/Presentation/View/Components/Overlays/KeyboardSelectOverlayView.swift \
        Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/Protocols/SwitchGestureHandling.swift \
        Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/SwitchGestureController.swift
git commit -m "refactor: #114 - 키보드 선택 방향 분기를 정책 타입으로 일원화"
```

---

## Task 4: 천지인 4행 재배치

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`

**Interfaces:**
- Consumes: `SwitchButton.init(keyboard:usesBottomSpaceLayout:)`, `KeyboardSelectOverlayView.init(keyboard:usesBottomSpaceLayout:)`, `SwitchGestureHandling.usesBottomSpaceLayout` (Task 3), `UserDefaultsManager.shared.isCheonjiinBottomSpaceEnabled` (Task 1)
- Produces:
  - `FourByFourPlusKeyboardView.init(showsLanguageSwitchButton: Bool = false, usesBottomSpaceLayout: Bool = false)`
  - `FourByFourPlusKeyboardView.usesBottomSpaceLayout: Bool` (public stored let, `SwitchGestureHandling` 요구사항 충족)
  - `CheonjiinKeyboardView.init(showsLanguageSwitchButton: Bool = false, usesBottomSpaceLayout: Bool = UserDefaultsManager.shared.isCheonjiinBottomSpaceEnabled)`

- [x] **Step 1: 실패하는 배치 테스트를 쓴다** — 완료. **계획 정정 반영**: 버튼 프레임이 각자의 행 스택 좌표계라 행 간 비교가 불가능해 `Self.rect(_:in:)` 변환 헬퍼 도입(정정 커밋 `93758fb2`). 추가로 `#expect(switchRect.maxX > space.maxX)`가 꺼짐 배치에서 실측 390.0 > 390.0으로 성립 불가여서, 키보드 폭에 직접 거는 형태(꺼짐 `maxX == 390`, 켜짐 `minX == 0`)로 교체

`SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`를 새로 만든다.
행 판정은 `deleteButton`(1행)과 `switchButton`(4행)을 기준점으로 삼아 내부 스택 구조가 바뀌어도 사용자 동작이 같으면 통과하게 한다.

```swift
//
//  CheonjiinBottomSpaceLayoutTests.swift
//  SYKeyboardTests
//

import Testing
import UIKit

@testable import HangeulKeyboardCore
@testable import SYKeyboardCore

@MainActor
@Suite("천지인 스페이스 하단 배치")
struct CheonjiinBottomSpaceLayoutTests {
    private static let keyboardWidth: CGFloat = 390
    private static let keyboardHeight: CGFloat = 216

    @MainActor
    private static func makeView(usesBottomSpaceLayout: Bool) -> CheonjiinKeyboardView {
        let view = CheonjiinKeyboardView(showsLanguageSwitchButton: true,
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

    @Test("꺼짐 상태는 스페이스가 리턴보다 위, !#1이 우측 끝")
    func testDefaultLayoutKeepsSpaceAboveReturn() {
        let view = Self.makeView(usesBottomSpaceLayout: false)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(space.midY < returnRect.midY)
        #expect(returnRect.midY < switchRect.midY)
        #expect(switchRect.maxX > space.maxX)
    }

    @Test("켜짐 상태는 리턴이 스페이스보다 위, 스페이스가 !#1과 같은 행")
    func testBottomSpaceLayoutMovesSpaceToLastRow() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let space = Self.rect(view.spaceButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let switchRect = Self.rect(view.switchButton, in: view)

        #expect(returnRect.midY < space.midY)
        #expect(abs(space.midY - switchRect.midY) < 0.5)
        #expect(switchRect.maxX <= space.minX + 0.5)
    }

    @Test("켜짐 상태의 리턴은 2행, 마침표·쉼표는 3행")
    func testBottomSpaceLayoutRowAssignment() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let keyButtons = view.primaryButtonList.compactMap { $0 as? PrimaryKeyButton }
        let periodButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "." })
        let questionButton = try #require(keyButtons.first { $0.type.primaryKeyList.first == "?" })

        let deleteRect = Self.rect(view.deleteButton, in: view)
        let returnRect = Self.rect(view.returnButton, in: view)
        let periodRect = Self.rect(periodButton, in: view)
        let space = Self.rect(view.spaceButton, in: view)
        let questionRect = Self.rect(questionButton, in: view)

        // 1행(삭제) < 2행(리턴) < 3행(마침표) < 4행(스페이스)
        #expect(deleteRect.midY < returnRect.midY)
        #expect(returnRect.midY < periodRect.midY)
        #expect(periodRect.midY < space.midY)
        // '?'·'!'는 4행 우측 끝에 남는다
        #expect(abs(questionRect.midY - space.midY) < 0.5)
        #expect(questionRect.minX >= space.maxX - 0.5)
    }

    @Test("두 배치 모두 네 행이 4칸 균등 분할을 유지",
          arguments: [false, true])
    func testAllRowsKeepFourEqualColumns(_ usesBottomSpaceLayout: Bool) {
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

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: false,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(view.nextKeyboardButton.isHidden)
        #expect(
            abs(languageButton.frame.width
                - Self.keyboardWidth * KeyboardLayoutFigure.languageSwitchButtonWidthRatio) < 0.5
        )
        // 남는 너비는 전환 버튼이 채운다
        #expect(languageButton.frame.width < view.switchButton.frame.width)
        // 같은 modifier 스택 안이라 변환 없이 비교한다. 좌→우 !#1 → 한/영
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
    }

    @Test("켜짐 상태에서 지구본이 보이면 modifier 세 버튼이 균등 분배")
    func testBottomSpaceLayoutEqualModifierDistributionWithGlobe() throws {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        let languageButton = try #require(view.languageSwitchButton)

        let primaryView: PrimaryKeyboardRepresentable = view
        primaryView.updateNextKeyboardButton(
            needsInputModeSwitchKey: true,
            nextKeyboardAction: NSSelectorFromString("unusedNextKeyboardAction:")
        )
        view.layoutIfNeeded()

        #expect(!view.nextKeyboardButton.isHidden)
        #expect(abs(view.switchButton.frame.width - languageButton.frame.width) < 1.0)
        #expect(abs(languageButton.frame.width - view.nextKeyboardButton.frame.width) < 1.0)
        // 좌→우 !#1 → 한/영 → 🌐
        #expect(view.switchButton.frame.maxX <= languageButton.frame.minX + 0.5)
        #expect(languageButton.frame.maxX <= view.nextKeyboardButton.frame.minX + 0.5)
    }
}
```

`updateNextKeyboardButton(needsInputModeSwitchKey:nextKeyboardAction:)`은 `NormalKeyboardLayoutProvider`의 프로토콜 extension 멤버다. 구체 타입에서 바로 호출되지 않으면 기존 `KeyboardModifierLayoutTests`처럼 `let primaryView: PrimaryKeyboardRepresentable = view`로 받아 호출한다.

`PrimaryKeyButton.type`은 `public private(set) var type: TextInteractableType`이고 `TextInteractableType.primaryKeyList`는 `public`이므로 위 접근자가 그대로 동작한다. `primaryButtonList`의 원소 타입은 `PrimaryButton`이라 `PrimaryKeyButton`으로 다운캐스팅해야 한다(`spaceButton`은 `PrimaryKeyButton`이 아니므로 `compactMap`에서 자연스럽게 걸러진다).

- [x] **Step 2: 컴파일이 실패하는지 확인한다** — 완료. `extra argument 'usesBottomSpaceLayout' in call`로 컴파일 실패 확인

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests
```

Expected: 컴파일 에러 `extra argument 'usesBottomSpaceLayout' in call`

- [x] **Step 3: `FourByFourPlusKeyboardView`에 플래그를 넣고 하위 컴포넌트에 전달한다** — 완료

`Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`

`private let showsLanguageSwitchButton: Bool` 아래에 추가:

```swift
    /// 스페이스를 맨 아랫줄로 내리는 배치 사용 여부.
    /// `SwitchGestureHandling` 요구사항이므로 `public`이어야 한다
    public let usesBottomSpaceLayout: Bool
```

`switchButton`, `keyboardSelectOverlayView` 생성부를 교체:

```swift
    public private(set) lazy var switchButton = SwitchButton(
        keyboard: keyboard,
        usesBottomSpaceLayout: usesBottomSpaceLayout
    )
```

```swift
    public private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(
            keyboard: keyboard,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        overlayView.isHidden = true
        
        return overlayView
    }()
```

`init` 교체:

```swift
    public init(showsLanguageSwitchButton: Bool = false,
                usesBottomSpaceLayout: Bool = false) {
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.usesBottomSpaceLayout = usesBottomSpaceLayout
        super.init(frame: .zero)
        setupUI()
    }
```

- [x] **Step 4: `setHierarchy()`를 분기한다** — 완료

같은 파일의 `setHierarchy()` 전체를 교체한다.

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
        
        [returnButton, secondaryAtButton, secondarySharpButton].forEach { returnButtonHStackView.addArrangedSubview($0) }
        [fourthRowPrimaryKeyButtonList[0], fourthRowPrimaryKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
        [fourthRowPrimaryKeyButtonList[3], fourthRowPrimaryKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }
        
        let modifierButtons: [SecondaryButton]
        if usesBottomSpaceLayout {
            // 스페이스가 4행으로 내려가면서 리턴 영역이 2행, 좌측 글자 스택('.', ',')이
            // 3행 우측 칸으로 올라가고 우측 글자 스택('?', '!')만 4행 끝에 남는다.
            // 모든 행은 그대로 4칸 균등 분할이다
            secondRowHStackView.addArrangedSubview(returnButtonHStackView)
            thirdRowHStackView.addArrangedSubview(fourthRowLeftPrimaryButtonHStackView)
            
            [fourthRowRightSecondaryButtonHStackView,
             fourthRowPrimaryKeyButtonList[2],
             spaceButton,
             fourthRowRightPrimaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }
            
            modifierButtons = [switchButton]
            + [languageSwitchButton].compactMap { $0 }
            + [nextKeyboardButton]
        } else {
            secondRowHStackView.addArrangedSubview(spaceButton)
            thirdRowHStackView.addArrangedSubview(returnButtonHStackView)
            
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

- [x] **Step 5: `CheonjiinKeyboardView`가 설정을 읽게 한다** — 완료

`Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift`의 `init`을 교체한다.

```swift
    override init(showsLanguageSwitchButton: Bool = false,
                  usesBottomSpaceLayout: Bool = UserDefaultsManager.shared.isCheonjiinBottomSpaceEnabled) {
        super.init(showsLanguageSwitchButton: showsLanguageSwitchButton,
                   usesBottomSpaceLayout: usesBottomSpaceLayout)
        updateLayoutToDefault()
    }
```

`HangeulKeyboardInputAdapter`는 `CheonjiinKeyboardView(showsLanguageSwitchButton:)`만 호출하므로, 기본 인자가 설정값을 집어와 별도 배관이 필요 없다.

**네이밍 주의:** 하단 배치에서 `fourthRowLeftPrimaryButtonHStackView`는 3행에 붙는다. 이름이 위치와 어긋나지만, 두 배치가 같은 스택 객체를 공유하므로 어느 쪽 이름을 써도 한쪽에서는 어긋난다. 기존 이름을 유지하고 위 주석으로 의도를 남긴다. 이름 변경은 이번 변경 범위 밖이다.

- [x] **Step 6: 배치 테스트가 통과하는지 확인한다** — 완료. `CheonjiinBottomSpaceLayoutTests` 6개 + `KeyboardModifierLayoutTests` 전부 통과

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests \
  -only-testing:SYKeyboardTests/KeyboardModifierLayoutTests
```

Expected: `** TEST SUCCEEDED **`. `KeyboardModifierLayoutTests`의 기존 천지인 테스트도 함께 통과해야 한다(기본값 꺼짐이므로 영향 없음).

- [x] **Step 7: 커밋한다** — 완료. 커밋 `0e0b6c0c`. 전체 473 고유 / 486 전개 / 0 failed, Auto Layout 경고 0건

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift \
        Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift \
        SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift
git commit -m "feat: #114 - 천지인 하단 배치에서 스페이스와 리턴 영역 행 재구성"
```

---

## Task 5: 선택 오버레이 앵커 반전

`switchButton`이 좌측 끝으로 이동했으므로 오버레이가 그 위·오른쪽으로 열려야 한다. Task 3에서 오버레이 내부 순서와 코너 힌트는 이미 `.right` 기준으로 뒤집히고, 이 task가 뷰 앵커를 맞춘다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`

**Interfaces:**
- Consumes: `FourByFourPlusKeyboardView.usesBottomSpaceLayout` (Task 4), `KeyboardSelectOverlayView.xmarkImageContainerView`, `KeyboardLayoutFigure.keyboardSelectBoundaryInset`(4.0), `KeyboardLayoutFigure.keyboardSelectCancelMinWidth`(32.0), `KeyboardLayoutFigure.selectOverlayHeight`(60.0), `KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth`(240.0)
- Produces: 없음(내부 제약만 변경)

- [x] **Step 1: 실패하는 앵커 테스트를 쓴다** — 완료

`SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift` 마지막 테스트 아래에 추가한다.

```swift
    @Test("켜짐 상태의 키보드 선택 오버레이는 좌측에서 시작하고 취소 경계가 !#1 우측 모서리 안쪽")
    func testBottomSpaceLayoutKeyboardSelectOverlayAnchors() {
        let view = Self.makeView(usesBottomSpaceLayout: true)
        view.keyboardSelectOverlayView.isHidden = false
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
        #expect(xmarkInView.width >= KeyboardLayoutFigure.keyboardSelectCancelMinWidth - 0.5)
        // `.right` 방향이면 X가 스택의 첫 칸이라 오버레이 왼쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.minX
                - overlay.directionalLayoutMargins.leading) < 0.5
        )
    }

    @Test("켜짐 상태의 한 손 모드 오버레이는 !#1 위 좌측에 놓임")
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

        let overlay = view.keyboardSelectOverlayView
        let switchRect = Self.rect(view.switchButton, in: view)
        #expect(abs(overlay.frame.maxX - (Self.keyboardWidth - 4)) < 0.5)

        let xmarkInView = overlay.convert(overlay.xmarkImageContainerView.frame, to: view)
        #expect(
            abs(xmarkInView.minX
                - (switchRect.minX + KeyboardLayoutFigure.keyboardSelectBoundaryInset)) < 0.5
        )
        // `.left` 방향이면 X가 스택의 마지막 칸이라 오버레이 오른쪽 끝에 붙는다
        #expect(
            abs(overlay.xmarkImageContainerView.frame.maxX
                - (overlay.bounds.width - overlay.directionalLayoutMargins.trailing)) < 0.5
        )
    }
```

- [x] **Step 2: 테스트가 실패하는지 확인한다** — 완료. 방향 불일치 테스트 2개는 예상대로 실패. **`testDefaultLayoutOverlayKeepsTrailingAnchor`도 production 무변경 상태에서 실패** — 지구본이 보이면 modifier 칸이 `.fillEqually`로 3등분되어 `switchButton`이 ~32.5pt가 되고, 우선순위 999인 취소 경계가 required인 `keyboardSelectCancelMinWidth`(32)와 동시에 성립할 수 없어 Auto Layout이 999를 버린다(실측 오차 15.67pt). `develop`에도 있던 기존 제약이며 이번 브랜치 회귀 아님. **컨트롤러 판정**: 3개 테스트 모두 단언 전에 `updateNextKeyboardButton(needsInputModeSwitchKey: false, ...)`로 지구본을 숨긴다(같은 파일 기존 테스트의 관례)

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests
```

Expected: `testBottomSpaceLayoutKeyboardSelectOverlayAnchors`와 `testBottomSpaceLayoutOneHandedOverlayAnchors`가 실패한다(오버레이가 여전히 우측 정렬). `testDefaultLayoutOverlayKeepsTrailingAnchor`는 통과한다.

- [x] **Step 3: `setConstraints()`의 오버레이 제약을 분기한다** — 완료

`Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`의 `setConstraints()`에서 `keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false`부터 함수 끝까지를 교체한다.

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

- [x] **Step 4: 테스트가 통과하는지 확인한다** — 완료

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests
```

Expected: `** TEST SUCCEEDED **`, 오버레이 테스트 3개 모두 통과

- [x] **Step 5: 커밋한다** — 완료. 커밋 `6099784d`. 전체 476 고유 / 489 전개 / 0 failed, Auto Layout 경고 0건. **컨트롤러 판정으로 범위 추가**: `KeyboardModifierLayoutTests.swift`의 `FourByFourFixture.cheonjiin`이 새 기본 인자를 통해 영속 설정값을 읽게 되어 flaky해지므로 `usesBottomSpaceLayout: false`를 명시

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift \
        SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift
git commit -m "feat: #114 - 천지인 하단 배치에서 선택 오버레이 방향 반전"
```

---

## Task 6: `UIKeyboardType` 5종 모드 회귀 확인

이슈 체크리스트의 `UIKeyboardType`별 레이아웃 모드 5종 항목이다. 모드 전환은 `isHidden`만 조작하므로 배치가 바뀌어도 규칙이 유지되어야 한다.

**Files:**
- Test: `SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift`

**Interfaces:**
- Consumes: `CheonjiinKeyboardView.currentHangeulKeyboardMode: HangeulKeyboardMode`(`.default`, `.URL`, `.emailAddress`, `.twitter`, `.webSearch`), `spaceButton.isHidden`, `returnButton.isHidden`, `secondaryAtButton.isHidden`, `secondarySharpButton.isHidden`
- Produces: 없음

- [x] **Step 1: 5종 모드 테스트를 쓴다** — 완료. `arguments:`가 그대로 컴파일되어 대안 형태 불필요

`SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift` 마지막에 추가한다.
`.default`는 `CheonjiinKeyboardView`의 초기 모드이므로 `didSet` 기반 갱신이 걸리지 않는다. 다른 모드를 거쳤다 돌아오는 방식으로 검증한다.

```swift
    @Test("하단 배치에서도 리턴 표시 모드 4종은 스페이스·리턴을 함께 노출",
          arguments: [HangeulKeyboardMode.default, .URL, .emailAddress, .webSearch])
    func testBottomSpaceLayoutReturnVisibleModes(_ mode: HangeulKeyboardMode) {
        let view = Self.makeView(usesBottomSpaceLayout: true)

        view.currentHangeulKeyboardMode = .twitter
        view.currentHangeulKeyboardMode = mode
        view.layoutIfNeeded()

        #expect(!view.spaceButton.isHidden)
        #expect(!view.returnButton.isHidden)
        #expect(view.secondaryAtButton.isHidden)
        #expect(view.secondarySharpButton.isHidden)
    }

    @Test("하단 배치의 twitter 모드는 리턴 대신 @·#을 2행에 노출")
    func testBottomSpaceLayoutTwitterMode() {
        let view = Self.makeView(usesBottomSpaceLayout: true)

        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(!view.spaceButton.isHidden)
        #expect(view.returnButton.isHidden)
        #expect(!view.secondaryAtButton.isHidden)
        #expect(!view.secondarySharpButton.isHidden)
        // @·#은 리턴이 있던 2행 우측 칸에 그대로 남고 스페이스보다 위에 있다
        #expect(Self.rect(view.secondaryAtButton, in: view).midY
                < Self.rect(view.spaceButton, in: view).midY)
        // 둘은 같은 returnButtonHStackView 안이라 변환 없이 비교한다
        #expect(view.secondaryAtButton.frame.maxX <= view.secondarySharpButton.frame.minX + 0.5)
    }

    @Test("꺼짐 상태의 twitter 모드는 기존처럼 @·#이 스페이스보다 아래")
    func testDefaultLayoutTwitterMode() {
        let view = Self.makeView(usesBottomSpaceLayout: false)

        view.currentHangeulKeyboardMode = .twitter
        view.layoutIfNeeded()

        #expect(view.returnButton.isHidden)
        #expect(!view.secondaryAtButton.isHidden)
        #expect(Self.rect(view.secondaryAtButton, in: view).midY
                > Self.rect(view.spaceButton, in: view).midY)
    }
```

`HangeulKeyboardMode`가 `CaseIterable`이 아니어도 위처럼 명시 배열을 쓰면 된다. 파라미터 배열에 쓰려면 `HangeulKeyboardMode`가 `Sendable`이어야 하므로, 컴파일 에러가 나면 `arguments:` 대신 4개 모드를 순회하는 단일 테스트로 바꾼다.

- [x] **Step 2: 테스트를 실행한다** — 완료

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinBottomSpaceLayoutTests
```

Expected: `** TEST SUCCEEDED **`

실패하면 Task 4의 `setHierarchy()` 분기에서 `returnButtonHStackView`가 2행에 붙지 않았거나, `secondaryAtButton`/`secondarySharpButton`이 스택에서 빠진 것이다. `HangeulKeyboardLayoutProvider`의 모드 메서드는 수정하지 않는다.

- [x] **Step 3: 커밋한다** — 완료. 커밋 `632a11c3`. 전체 479 고유 / 495 전개 / 0 failed

```bash
git add SYKeyboardTests/Utils/CheonjiinBottomSpaceLayoutTests.swift
git commit -m "test: #114 - 천지인 하단 배치의 UIKeyboardType 모드별 표시 규칙 검증"
```

---

## Task 7: 전체 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-08-27-cheonjiin-bottom-space-layout.md` (결과 기록)

- [ ] **Step 1: 전체 테스트를 실행한다**

```bash
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `** TEST SUCCEEDED **`. 테스트 개수를 Task 0 Step 2 기준선과 비교해 **증가분만 있고 감소는 없어야** 한다.

- [ ] **Step 2: 세 키보드 extension을 빌드한다**

`-only-testing`이나 coverage 옵션이 남아 있지 않은 새 명령으로 실행한다.

```bash
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' || break
done
```

Expected: 세 scheme 모두 `** BUILD SUCCEEDED **`

- [ ] **Step 3: 변경 범위를 확인한다**

```bash
git status --short
git diff --stat develop...HEAD
```

Expected: 계획에 나열한 파일만 나타난다. `FourByFourKeyboardView.swift`, `NaratgeulKeyboardView.swift`, `DubeolsikKeyboardView.swift`, `EnglishKeyboardView.swift`, `StandardKeyboardView.swift`, `NumericKeyboardView.swift`, `SymbolKeyboardView.swift`가 diff에 있으면 **범위 초과이므로 되돌린다.**

- [ ] **Step 4: 계획 문서에 검증 결과를 기록한다**

이 문서 하단의 "검증 기록"에 실제 실행한 명령, 시뮬레이터 기기명·OS, 테스트 개수, 빌드 결과를 적는다. `.xcresult`에서 결과를 읽었다면 산출물 경로와 추출 명령도 함께 남긴다.

- [ ] **Step 5: 문서 커밋**

```bash
git add docs/superpowers/plans/2026-08-27-cheonjiin-bottom-space-layout.md
git commit -m "docs: #114 - 천지인 하단 배치 계획 검증 결과 기록"
```

- [ ] **Step 6: 실제 입력 앱에서 수동 확인한다 (자동 테스트로 대체 불가)**

시뮬레이터 또는 실기기에 앱을 설치하고 설정 > 일반 > 키보드에서 SY키보드를 활성화한 뒤, 메모 등 실제 입력 앱에서 확인한다. **관찰하지 못한 항목은 미확인으로 남기고 완료로 표시하지 않는다.**

| 확인 항목 | 꺼짐 | 켜짐 |
|---|---|---|
| 한글 키보드 선택 화면에 스위치가 천지인일 때만 보임 | ☐ | ☐ |
| 스페이스 입력·길게 눌러 커서 드래그 | ☐ | ☐ |
| 리턴 입력, `.` 단축키(스페이스 연타) | ☐ | ☐ |
| `!#1`에서 목표 방향으로 드래그 → 숫자 키보드 전환 | ☐ 왼쪽 | ☐ 오른쪽 |
| `!#1` 코너 힌트 화살표 방향이 실제 제스처 방향과 일치 | ☐ | ☐ |
| `!#1` 위로 드래그 → 한 손 모드 오버레이가 버튼 위에 뜸 | ☐ | ☐ |
| 한 손 키보드 좌/우 모드에서 오버레이가 잘리지 않음 | ☐ | ☐ |
| 숫자 키패드 동시 표시 상태에서 배치 정상 | ☐ | ☐ |
| 한영 통합 키보드에서 한/영 버튼 폭과 순서 | ☐ | ☐ |
| iPhone SE 등 지구본 표시 기기에서 modifier 3버튼 균등 분배 | ☐ | ☐ |
| URL·이메일·트위터·웹검색 입력 필드에서 리턴/@/# 표시 | ☐ | ☐ |

---

## 검증 기록

> Task 7 Step 4에서 채운다. 실행하지 못한 항목은 이유와 함께 남긴다.

| 항목 | 명령 | 결과 | 비고 |
|---|---|---|---|
| 전체 테스트 | | | |
| HangeulKeyboard 빌드 | | | |
| EnglishKeyboard 빌드 | | | |
| HangeulEnglishKeyboard 빌드 | | | |
| 수동 확인 | | | |

---

## 이슈 체크리스트 대응

| 이슈 체크리스트 | 대응 |
|---|---|
| 켜짐 상태의 배치를 안 A / 안 B 중 결정 | 확정된 설계 결정 표 (안 A, 천지인 한정) |
| `UserDefaultsKeys` 및 `DefaultValues`에 배치 설정 키 추가 | Task 1 Step 3 |
| `AppearanceSettingsView`에 스위치 추가 | Task 1 Step 5 — **`HangeulKeyboardSelectView`로 변경**(사용자 확정) |
| 나랏글 키보드 배치 적용 | **범위에서 제외**(사용자 확정) |
| 천지인 키보드 배치 적용 | Task 4, Task 5 |
| `UIKeyboardType`별 레이아웃 모드 5종 표시 규칙 확인 | Task 6 |
| 한 손 키보드 및 숫자 키패드 동시 표시 확인 | Task 7 Step 6 수동 확인표 |
| 선택 오버레이 2종 위치 확인 | Task 5 Step 1 자동 테스트 + Task 7 Step 6 |
| `UserDefaultsContractTests` 갱신 | Task 1 Step 1 |
| 레이아웃 회귀 테스트 추가 | Task 4 Step 1, Task 5 Step 1 |
| `SYKeyboard` 전체 테스트 통과 | Task 7 Step 1 |
| 세 extension 빌드 통과 | Task 7 Step 2 |
| 설정 꺼짐 상태가 기존 배치와 동일한지 확인 | Task 4 Step 1 `testDefaultLayoutKeepsSpaceAboveReturn`, Task 5 Step 1 `testDefaultLayoutOverlayKeepsTrailingAnchor`, Task 7 Step 3 |
| 실제 입력 앱에서 스페이스·리턴·커서 드래그 확인 | Task 7 Step 6 |
