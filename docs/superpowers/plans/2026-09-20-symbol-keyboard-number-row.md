# 기호 자판 숫자 행과 배열 재구성 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기호 자판에 숫자 행을 더해 비는 줄에 기호를 채우고, URL·이메일 자판을 한 페이지로 합치며, 기호 자판 셋째 줄 정렬 문제를 고친다.

**Architecture:** 기호 자판의 숫자 행은 두벌식·쿼티와 같은 조건, 같은 높이로 붙는다. 배열은 숫자 행 설정 하나로 정해지고 화면 방향과는 무관하므로 뷰를 만들 때 한 번 결정된다. 기호 배열은 `SymbolKeyboardMode.keyList(usesNumberRow:)`가 돌려주고, 행별 버튼 개수는 어떤 배열이든 10 / 10 / 5개를 지킨다.

**Tech Stack:** Swift 5, UIKit, Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`), Xcode 26 이상

**Spec:** `docs/superpowers/specs/2026-09-20-symbol-keyboard-number-row-design.md`

## Global Constraints

- 기준 브랜치는 `feat/#138-number-row`이고 커밋 메시지는 `type: #138 - subject` 형식을 쓴다. 마침표를 붙이지 않는다.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`를 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.
- **`Modules/` 아래에 새 파일을 만들지 않는다.** 만들면 `SYKeyboard.xcodeproj/project.pbxproj`의 타깃별 `membershipExceptions`를 함께 고쳐야 한다. 이 계획의 모든 변경은 기존 파일 수정이다.
- 기호 자판의 행별 버튼 개수는 생성 시점에 `keyList[0][행].count`로 고정된다. **모든 배열 변형이 10 / 10 / 5개를 지켜야 한다.** 모자라는 자리는 빈 키 `[]`로 채운다.
- 테스트 기준 기기는 `iPhone 13 mini / iOS 18.6`이다.
- 테스트 실행 시 `-parallel-testing-enabled NO`와 `GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'`를 명령줄에 붙인다. `SYKeyboard/Resources/Configs/Secrets.xcconfig`는 **절대 만들거나 고치지 않는다.**
- 빌드 후 `git status --short`에 `.xcscheme`이 보이면 내용을 확인하고 `RemotePath`만 바뀐 경우 `git checkout --`으로 되돌린다. 커밋하지 않는다.
- `SYKeyboard/Presentation/Content/ContentView.swift`에 사용자의 미커밋 변경이 있다. **건드리지 않고 커밋에도 포함하지 않는다.**
- 숫자 행 높이는 세로 46.5pt, 가로 35pt다. 두 방향 모두 표시한다.

## 파일 구조

| 파일 | 책임 | 변경 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift` | 기호 배열 정의 | 수정 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift` | 기호 자판 숫자 행, 배열 전환, 셋째 줄 정렬 | 수정 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift` | `⇧` 숨김 규칙 | 수정 |
| `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift` | 기호 자판 생성 시 숫자 행 여부 주입 | 수정 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 기호 자판에도 숫자 행 높이 전달 | 수정 |
| `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift` | 기호 자판 배열·정렬 테스트 | 생성 |

---

### Task 1: 가로모드에서 숫자 행 숨기기 — 철회됨

**2026-09-20 철회.** 가로모드에서도 숫자 행을 그대로 표시하기로 했다. 이 Task는
실행하지 않는다. 이미 구현·리뷰까지 끝난 커밋 `4130dbee`는 되돌린다.

되돌리면 아래가 복구된다.

- `KeyboardHeightPolicy.landscapeNumberRowHeight` 상수 (35pt)
- `numberRowHeight(...)`가 가로에서 `landscapeNumberRowHeight`를 반환하는 동작
- `StandardKeyboardView.updateNumberRowHeight(_:)`의 숨김 처리 없는 원래 구현
- 두 테스트 파일의 가로 기대값

이 철회 덕분에 뒤 Task들이 단순해진다. 기호 자판 배열이 화면 방향에 의존하지 않게
되어, 회전할 때 키 글자를 다시 적용할 필요가 없다.

---

### Task 2: 기호 자판 셋째 줄 정렬 수정

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift:199-220`
- Test: `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift` (생성)

**Interfaces:**
- Consumes: 없음
- Produces: `SymbolKeyboardView.updateThirdRowWidthConstraints()` (private). 셋째 줄에 빈 키가 섞여도 보이는 키들이 가운데에 고르게 놓인다.

**배경:** 셋째 줄 첫 버튼의 너비를 배열의 **맨 마지막** 버튼에 묶어 놨다. URL·이메일 자판은 셋째 줄 마지막 칸이 빈 키라 `PrimaryKeyButton`이 `isHidden = true`로 접고, 너비가 0이 되면서 거기 묶인 첫 버튼도 0이 된다. 그래서 남는 폭이 전부 왼쪽에 쏠려 키들이 오른쪽으로 밀린다. 어느 칸이 비는지는 모드에 따라 달라지므로, 제약을 생성 시점에 한 번만 잡으면 안 되고 배열이 바뀔 때마다 다시 잡아야 한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`를 새로 만든다.

```swift
//
//  SymbolKeyboardLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/20/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@MainActor
@Suite("기호 자판 배열과 정렬")
struct SymbolKeyboardLayoutTests {

    /// 세로 기본 높이(240)에서 프레임 여백 4를 뺀 키 영역
    private func makeView(mode: SymbolKeyboardMode) -> SymbolKeyboardView {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false)
        view.currentSymbolKeyboardMode = mode
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 236)
        view.layoutIfNeeded()

        return view
    }

    /// 셋째 줄에서 보이는 키들의 좌우 여백. 버튼 프레임이 아니라 실제로 그려지는
    /// `backgroundView` 기준이어야 한다. 프레임은 스택이 항상 꽉 채우므로 늘 0이 나온다
    private func thirdRowSideMargins(_ view: SymbolKeyboardView) -> (left: CGFloat, right: CGFloat)? {
        let visibleButtons = view.thirdRowPrimaryKeyButtonList.filter { !$0.isHidden }
        guard let firstButton = visibleButtons.first,
              let lastButton = visibleButtons.last else { return nil }

        func visualFrame(_ button: BaseKeyboardButton) -> CGRect {
            button.backgroundView.convert(button.backgroundView.bounds, to: view)
        }

        return (visualFrame(firstButton).minX - visualFrame(view.shiftButton).maxX,
                visualFrame(view.deleteButton).minX - visualFrame(lastButton).maxX)
    }

    @Test("셋째 줄이 다 찬 기본 자판은 좌우 여백이 같다")
    func test셋째줄_기본자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .default)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }

    @Test("셋째 줄에 빈 키가 있는 URL 자판도 좌우 여백이 같다")
    func test셋째줄_URL자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .URL)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }

    @Test("셋째 줄에 빈 키가 있는 이메일 자판도 좌우 여백이 같다")
    func test셋째줄_이메일자판_좌우여백() throws {
        let margins = try #require(thirdRowSideMargins(makeView(mode: .emailAddress)))

        #expect(margins.left >= 0)
        #expect(abs(margins.left - margins.right) < 1)
    }
}
```

테스트가 `thirdRowPrimaryKeyButtonList`, `shiftButton`, `deleteButton`을 읽어야 한다. `shiftButton`과 `deleteButton`은 이미 `public private(set)`이다. `SymbolKeyboardView.swift:88-97`의 세 줄 중 셋째 줄 배열만 접근 제어를 바꾼다.

```swift
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private(set) lazy var thirdRowPrimaryKeyButtonList = currentSymbolKeyboardMode.keyList[0][2].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SymbolKeyboardLayoutTests
```

예상: 기본 자판은 PASS, URL·이메일은 FAIL. 첫 키의 시각 요소가 `⇧` 쪽으로 넘어가 왼쪽 여백이 음수로 나온다. Auto Layout 제약 충돌 로그가 함께 찍힐 수 있는데, 같은 원인이므로 수정 후 사라져야 한다.

- [ ] **Step 3: 셋째 줄 제약을 다시 잡을 수 있게 고치기**

`SymbolKeyboardView.swift`의 프로퍼티 선언부(`fourthRowModifierWidthConstraint` 아래, `:45` 근처)에 저장 공간을 추가한다.

```swift
    /// 셋째 줄 키 너비 제약. 배열이 바뀌면 다시 만든다
    private var thirdRowWidthConstraints: [NSLayoutConstraint] = []
```

`setConstraints()`의 셋째 줄 반복문(`:199-220`)을 통째로 아래 한 줄로 바꾼다.

```swift
        updateThirdRowWidthConstraints()
```

`private extension SymbolKeyboardView`의 Update Methods 구역(`updateKeyButtonList()` 옆)에 아래를 추가한다.

```swift
    /// 셋째 줄에서 실제로 보이는 키만 대상으로 양 끝 정렬을 다시 잡는다.
    /// 빈 키는 `PrimaryKeyButton`이 숨겨 너비가 0이 되므로 기준으로 쓸 수 없다
    func updateThirdRowWidthConstraints() {
        NSLayoutConstraint.deactivate(thirdRowWidthConstraints)
        thirdRowWidthConstraints.removeAll()

        let visibleButtons = thirdRowPrimaryKeyButtonList.filter { !$0.isHidden }
        guard let firstButton = visibleButtons.first,
              let lastButton = visibleButtons.last else { return }

        let multiplier = 1.0 / CGFloat(firstRowPrimaryKeyButtonList.count)
        * KeyboardLayoutFigure.symbolThirdRowButtonWidthMultiplier

        // 양 끝 버튼이 남는 폭을 똑같이 나눠 갖고, 시각 요소는 안쪽으로 붙인다
        if firstButton !== lastButton {
            thirdRowWidthConstraints.append(firstButton.widthAnchor.constraint(equalTo: lastButton.widthAnchor))
        }
        for button in visibleButtons where button !== firstButton && button !== lastButton {
            thirdRowWidthConstraints.append(
                button.widthAnchor.constraint(equalTo: thirdRowHStackView.widthAnchor, multiplier: multiplier)
            )
        }
        NSLayoutConstraint.activate(thirdRowWidthConstraints)

        for button in visibleButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            if button === firstButton {
                button.updateKeyAlignment(.right, referenceView: thirdRowHStackView, multiplier: multiplier)
            } else if button === lastButton {
                button.updateKeyAlignment(.left, referenceView: thirdRowHStackView, multiplier: multiplier)
            } else {
                button.updateKeyAlignment(.center, referenceView: nil, multiplier: multiplier)
            }
        }
    }
```

`updateKeyButtonList()` 끝에 아래 한 줄을 추가한다. 배열이 바뀌면 어느 칸이 비는지도 바뀌기 때문이다.

```swift
        updateThirdRowWidthConstraints()
```

- [ ] **Step 4: 테스트가 통과하는지 확인**

Step 2와 같은 명령을 실행한다. 예상: 세 테스트 모두 PASS.

- [ ] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift \
        SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift
git commit -F - <<'EOF'
fix: #138 - 기호 자판 셋째 줄에 빈 키가 있으면 키가 오른쪽으로 몰리던 현상 수정

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: 기본·웹 검색 자판의 숫자 행 배열

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift:29-71`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift` (호출부)
- Test: `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `SymbolKeyboardMode.keyList(usesNumberRow: Bool) -> [[[[String]]]]`. 기존 `var keyList: [[[[String]]]]`는 사라지고, 호출부는 `keyList(usesNumberRow:)`를 쓴다. Task 5가 `usesNumberRow`를 넘긴다.

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`에 아래를 추가한다.

```swift
    @Test("숫자 행이 꺼지면 기본 자판 배열은 그대로다")
    func test기본자판_숫자행꺼짐() {
        let keyList = SymbolKeyboardMode.default.keyList(usesNumberRow: false)

        #expect(keyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(keyList[0][1].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[1][0].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
    }

    @Test("숫자 행이 켜지면 기본 자판 첫 줄이 기존 둘째 줄로 올라오고 도형 줄이 생김")
    func test기본자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.default.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
        #expect(keyList[0][1].map(\.first) == ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
        #expect(keyList[0][2].map(\.first) == [".", ",", "?", "!", "’"])
        #expect(keyList[1][0].map(\.first) == ["_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•"])
        #expect(keyList[1][1].map(\.first) == ["※", "☆", "★", "○", "●", "□", "■", "△", "▲", "♡"])
        #expect(keyList[1][2].map(\.first) == [".", ",", "?", "!", "’"])
    }

    @Test("웹 검색 자판은 기본 자판과 같은 배열을 쓴다")
    func test웹검색자판_기본자판과동일() {
        #expect(SymbolKeyboardMode.webSearch.keyList(usesNumberRow: true)
                == SymbolKeyboardMode.default.keyList(usesNumberRow: true))
        #expect(SymbolKeyboardMode.webSearch.keyList(usesNumberRow: false)
                == SymbolKeyboardMode.default.keyList(usesNumberRow: false))
    }

    @Test("모든 배열이 행별 10·10·5개를 지킨다")
    func test모든배열_행별키개수() {
        let modes: [SymbolKeyboardMode] = [.default, .webSearch, .URL, .emailAddress]
        for mode in modes {
            for usesNumberRow in [true, false] {
                let keyList = mode.keyList(usesNumberRow: usesNumberRow)
                for layer in keyList {
                    #expect(layer.map(\.count) == [10, 10, 5])
                }
            }
        }
    }
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SymbolKeyboardLayoutTests
```

예상: `keyList(usesNumberRow:)`가 없어 컴파일 실패.

- [ ] **Step 3: 기본·웹 검색 배열 구현**

`SymbolKeyboardMode.swift`의 `var keyList: [[[[String]]]]` 선언을 아래 함수로 바꾼다. `case .URL`과 `case .emailAddress`의 본문은 Task 4에서 고치므로 지금은 기존 배열을 `usesNumberRow`와 무관하게 그대로 돌려준다.

```swift
    /// 기호 자판 배열
    /// - Parameter usesNumberRow: 자판 위에 숫자 행이 있는지 여부.
    ///   숫자 행이 있으면 첫 줄 숫자가 중복되므로 기호로 채운다
    func keyList(usesNumberRow: Bool) -> [[[[String]]]] {
        switch self {
        case .default, .webSearch:
            guard usesNumberRow else {
                return [
                    [
                        [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                        [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["”"] ],
                        [ ["."], [","], ["?"], ["!"], ["’"] ]
                    ],
                    [
                        [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
                        [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
                        [ ["."], [","], ["?"], ["!"], ["’"] ]
                    ]
                ]
            }
            // 숫자 밑에 있던 줄을 숫자 행 밑에 그대로 두고, 새 줄을 그 아래에 넣는다
            return [
                [
                    [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["”"] ],
                    [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
                    [ ["."], [","], ["?"], ["!"], ["’"] ]
                ],
                [
                    [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
                    [ ["※"], ["☆"], ["★"], ["○"], ["●"], ["□"], ["■"], ["△"], ["▲"], ["♡"] ],
                    [ ["."], [","], ["?"], ["!"], ["’"] ]
                ]
            ]
        case .URL:
            return [
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ ["@"], ["&"], ["%"], ["?"], [","], ["="], ["["], ["]"], [], [] ],
                    [ ["_"], [":"], ["-"], ["+"], [] ]
                ],
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ ["*"], ["$"], ["#"], ["!"], ["’"], ["^"], ["["], ["]"], [], [] ],
                    [ ["~"], [";"], ["("], [")"], [] ]
                ]
            ]
        case .emailAddress:
            return [
                [
                    [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
                    [ ["$"], ["!"], ["~"], ["&"], ["="], ["#"], ["["], ["]"], [], [] ],
                    [ ["."], ["_"], ["-"], ["+"], [] ]
                ],
                [
                    [ ["’"], ["|"], ["{"], ["}"], ["?"], ["%"], ["^"], ["*"], ["/"], ["’"] ],
                    [ ["$"], ["!"], ["~"], ["&"], ["="], ["#"], ["["], ["]"], [], [] ],
                    [ ["."], ["_"], ["-"], ["+"], [] ]
                ]
            ]
        }
    }
```

- [ ] **Step 4: 호출부 고치기**

`SymbolKeyboardView.swift`에서 `currentSymbolKeyboardMode.keyList[...]`를 쓰는 네 곳을 찾는다.

```sh
grep -n "currentSymbolKeyboardMode.keyList" Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift
```

네 곳 모두 `currentSymbolKeyboardMode.keyList(usesNumberRow: false)[...]`로 바꾼다. Task 5에서 실제 값으로 바꾼다.

- [ ] **Step 5: 테스트가 통과하는지 확인**

Step 2와 같은 명령을 실행한다. 예상: 이 suite의 모든 테스트가 PASS.

- [ ] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift \
        Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift \
        SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift
git commit -F - <<'EOF'
feat: #138 - 숫자 행이 켜졌을 때의 기본 기호 자판 배열 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: URL·이메일 자판을 한 페이지로 합치기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift`
- Test: `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`

**Interfaces:**
- Consumes: `SymbolKeyboardMode.keyList(usesNumberRow: Bool) -> [[[[String]]]]` (Task 3)
- Produces: `usesNumberRow == true`일 때 `.URL`과 `.emailAddress`의 두 층이 서로 같은 내용이다. Task 5가 이 성질을 보고 `⇧`를 숨긴다.

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`에 추가한다.

```swift
    @Test("숫자 행이 켜지면 URL 자판이 한 페이지로 합쳐진다")
    func testURL자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.URL.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["@", "&", "%", "?", ",", "=", "[", "]", nil, nil])
        #expect(keyList[0][1].map(\.first) == ["*", "$", "#", "!", "’", "^", "~", ";", "(", ")"])
        #expect(keyList[0][2].map(\.first) == ["_", ":", "-", "+", nil])
        #expect(keyList[1] == keyList[0])
    }

    @Test("숫자 행이 켜지면 이메일 자판이 한 페이지로 합쳐진다")
    func test이메일자판_숫자행켜짐() {
        let keyList = SymbolKeyboardMode.emailAddress.keyList(usesNumberRow: true)

        #expect(keyList[0][0].map(\.first) == ["$", "!", "~", "&", "=", "#", "[", "]", nil, nil])
        #expect(keyList[0][1].map(\.first) == ["’", "|", "{", "}", "?", "%", "^", "*", "/", nil])
        #expect(keyList[0][2].map(\.first) == [".", "_", "-", "+", nil])
        #expect(keyList[1] == keyList[0])
    }

    @Test("합친 URL·이메일 자판은 기호를 더하거나 빼지 않는다")
    func test합친자판_기호집합유지() {
        for mode in [SymbolKeyboardMode.URL, .emailAddress] {
            let before = Set(mode.keyList(usesNumberRow: false).flatMap { $0.flatMap { $0.flatMap { $0 } } })
                .subtracting(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
            let after = Set(mode.keyList(usesNumberRow: true).flatMap { $0.flatMap { $0.flatMap { $0 } } })

            #expect(before == after)
        }
    }

    @Test("숫자 행이 꺼지면 URL·이메일 자판은 두 페이지 그대로다")
    func testURL이메일자판_숫자행꺼짐() {
        let urlKeyList = SymbolKeyboardMode.URL.keyList(usesNumberRow: false)
        #expect(urlKeyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(urlKeyList[1][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])

        let emailKeyList = SymbolKeyboardMode.emailAddress.keyList(usesNumberRow: false)
        #expect(emailKeyList[0][0].map(\.first) == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
        #expect(emailKeyList[1][0].map(\.first) == ["’", "|", "{", "}", "?", "%", "^", "*", "/", "’"])
    }
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SymbolKeyboardLayoutTests
```

예상: 합친 배열 테스트 세 개가 FAIL.

- [ ] **Step 3: 합친 배열 구현**

`SymbolKeyboardMode.swift`의 `case .URL` 본문 맨 앞에 아래를 넣는다.

```swift
        case .URL:
            if usesNumberRow {
                // 1페이지에 있던 줄은 자리를 지키고 2페이지 내용이 그 아래로 내려온다.
                // 양쪽에 있던 `[`, `]` 중복은 하나로 줄인다
                let merged: [[[String]]] = [
                    [ ["@"], ["&"], ["%"], ["?"], [","], ["="], ["["], ["]"], [], [] ],
                    [ ["*"], ["$"], ["#"], ["!"], ["’"], ["^"], ["~"], [";"], ["("], [")"] ],
                    [ ["_"], [":"], ["-"], ["+"], [] ]
                ]
                // `⇧`를 숨기므로 두 층이 같아도 인덱스 접근이 안전하다
                return [merged, merged]
            }
```

`case .emailAddress` 본문 맨 앞에도 같은 방식으로 넣는다.

```swift
        case .emailAddress:
            if usesNumberRow {
                // 둘째 줄 양 끝에 두 번 있던 `’`는 하나로 줄인다
                let merged: [[[String]]] = [
                    [ ["$"], ["!"], ["~"], ["&"], ["="], ["#"], ["["], ["]"], [], [] ],
                    [ ["’"], ["|"], ["{"], ["}"], ["?"], ["%"], ["^"], ["*"], ["/"], [] ],
                    [ ["."], ["_"], ["-"], ["+"], [] ]
                ]
                return [merged, merged]
            }
```

- [ ] **Step 4: 테스트가 통과하는지 확인**

Step 2와 같은 명령을 실행한다. 예상: 이 suite의 모든 테스트가 PASS.

- [ ] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift \
        SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift
git commit -F - <<'EOF'
feat: #138 - 숫자 행이 켜지면 URL·이메일 기호 자판을 한 페이지로 통합

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: 기호 자판에 숫자 행 붙이기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift`
- Test: `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`

**Interfaces:**
- Consumes: `SymbolKeyboardMode.keyList(usesNumberRow:)` (Task 3·4), `updateThirdRowWidthConstraints()` (Task 2)
- Produces: `SymbolKeyboardView.init(showsLanguageSwitchButton: Bool = false, showsNumberRow: Bool = false)`. `NormalKeyboardLayoutProvider`의 `showsNumberRow`와 `updateNumberRowHeight(_:)`를 구현한다. Task 6이 이 생성자와 메서드를 호출한다.

**배경:** 숫자 행 표시 여부는 설정 하나로 정해진다. 화면 방향은 조건이 아니다. 숫자 행이 세로·가로 모두 보이므로, 기호 자판 배열도 뷰를 만들 때 한 번 정해지고 회전해도 바뀌지 않는다. 회전할 때 달라지는 것은 숫자 행 높이(46.5pt ↔ 35pt)뿐이고, 그건 `updateNumberRowHeight(_:)`가 제약 상수만 바꿔 처리한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`에 추가한다.

```swift
    @Test("숫자 행을 켜면 숫자 키가 생기고 기본 자판 배열이 바뀐다")
    func test기호자판_숫자행표시() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.portraitNumberRowHeight)
        // keyboardHStackView(240 + 46.5)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 282.5)
        view.layoutIfNeeded()

        #expect(view.showsNumberRow)
        #expect(view.numberRowPrimaryKeyButtonList.map(\.type.primaryKeyList)
                == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map { [$0] })
        #expect(view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])

        let numberButton = try #require(view.numberRowPrimaryKeyButtonList.first)
        #expect(abs(numberButton.frame.height - 46.5) < 0.5)
    }

    @Test("가로 높이를 주면 숫자 행만 35로 줄고 배열은 그대로다")
    func test기호자판_가로높이() throws {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)
        view.updateNumberRowHeight(KeyboardHeightPolicy.landscapeNumberRowHeight)
        // 가로 keyboardHStackView(188 - 44 + 35)에서 프레임 여백 4를 뺀 높이
        view.frame = CGRect(x: 0, y: 0, width: 667, height: 175)
        view.layoutIfNeeded()

        let numberButton = try #require(view.numberRowPrimaryKeyButtonList.first)
        #expect(abs(numberButton.frame.height - 35) < 0.5)
        #expect(view.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "”"])
    }

    @Test("합친 URL·이메일 자판에서는 페이지 전환 버튼을 숨긴다")
    func test기호자판_합친자판_shift숨김() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: true)

        view.currentSymbolKeyboardMode = .URL
        #expect(view.shiftButton.isHidden)

        view.currentSymbolKeyboardMode = .default
        #expect(view.shiftButton.isHidden == false)

        view.currentSymbolKeyboardMode = .emailAddress
        #expect(view.shiftButton.isHidden)
    }

    @Test("숫자 행이 꺼져 있으면 URL 자판도 두 페이지라 전환 버튼을 유지한다")
    func test기호자판_숫자행꺼짐_shift유지() {
        let view = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: false)
        view.currentSymbolKeyboardMode = .URL

        #expect(view.shiftButton.isHidden == false)
    }
```

테스트가 `numberRowPrimaryKeyButtonList`와 `firstRowPrimaryKeyButtonList`를 읽어야 하므로 두 선언의 `private`을 `private(set)`으로 바꾼다.

- [ ] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SymbolKeyboardLayoutTests
```

예상: 새 생성자 인자가 없어 컴파일 실패.

- [ ] **Step 3: 숫자 행 UI와 상태 추가**

`SymbolKeyboardView.swift`에 아래를 더한다. 위치는 `StandardKeyboardView`의 같은 이름 멤버와 맞춘다.

프로퍼티 구역:

```swift
    private let showsNumberRowSetting: Bool
    private var numberRowHeightConstraint: NSLayoutConstraint?
```

`NormalKeyboardLayoutProvider` 구현:

```swift
    public var showsNumberRow: Bool { showsNumberRowSetting }
```

UI 구역:

```swift
    /// 키보드 숫자 행
    private let numberRowHStackView = KeyboardRowHStackView()
    /// 숫자 행 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    private(set) lazy var numberRowPrimaryKeyButtonList: [PrimaryKeyButton] = showsNumberRowSetting
    ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: [$0], secondary: nil))
    }
    : []
```

생성자를 바꾼다.

```swift
    init(showsLanguageSwitchButton: Bool = false, showsNumberRow: Bool = false) {
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.showsNumberRowSetting = showsNumberRow
        super.init(frame: .zero)
        setupUI()
        updateLayoutToDefault()
    }
```

- [ ] **Step 4: 계층과 제약 추가**

`setHierarchy()`의 `self.addSubview(layoutVStackView)` 다음에 넣는다.

```swift
        if showsNumberRowSetting {
            self.addSubview(numberRowHStackView)
            numberRowPrimaryKeyButtonList.forEach { numberRowHStackView.addArrangedSubview($0) }
        }
```

`setConstraints()`의 `layoutVStackView` 제약 블록을 아래로 바꾼다. 기존에는 `topAnchor`가 항상 `self.topAnchor`에 묶여 있다.

```swift
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        if showsNumberRowSetting {
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

- [ ] **Step 5: 배열 적용과 `⇧` 숨김 구현**

높이 갱신은 제약 상수만 바꾼다. `StandardKeyboardView`와 같은 모양이다.

```swift
    public func updateNumberRowHeight(_ height: CGFloat) {
        guard let numberRowHeightConstraint,
              numberRowHeightConstraint.constant != height else { return }
        numberRowHeightConstraint.constant = height
    }
```

`private extension` 안에 추가한다.

```swift
    /// 합친 배열에서는 넘길 페이지가 없으므로 `⇧`를 숨긴다
    func updateShiftButtonVisibility() {
        let isMergedLayout = showsNumberRowSetting
        && (currentSymbolKeyboardMode == .URL || currentSymbolKeyboardMode == .emailAddress)
        shiftButton.isHidden = isMergedLayout
    }
```

Task 3 Step 4에서 `keyList(usesNumberRow: false)`로 임시 고정해 둔 네 곳을 모두 실제 값으로 바꾼다. 세 개의 행별 `lazy var`와 `updateKeyButtonList()` 안이다.

```swift
        currentSymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)
```

`updateKeyButtonList()`에서 배열을 읽는 줄은 아래가 된다. **Task 2가 이 메서드 끝에 넣은 `updateThirdRowWidthConstraints()` 호출을 지우지 않는다.**

```swift
                let primaryKeyList = currentSymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[symbolKeyListIndex][rowIndex][buttonIndex]
```

`currentSymbolKeyboardMode`의 `didSet`에 `updateShiftButtonVisibility()` 호출을 더한다.

```swift
    var currentSymbolKeyboardMode: SymbolKeyboardMode = .default {
        didSet(oldMode) {
            updateLayoutForCurrentSymbolKeyboardMode(oldMode: oldMode)
            isShifted = false
            updateShiftButtonVisibility()
        }
    }
```

`setupUI()` 끝에도 한 번 호출해 처음 상태를 맞춘다.

```swift
        updateShiftButtonVisibility()
```

- [ ] **Step 6: 테스트가 통과하는지 확인**

Step 2와 같은 명령을 실행한다. 예상: 이 suite의 모든 테스트가 PASS.

- [ ] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift \
        SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift
git commit -F - <<'EOF'
feat: #138 - 기호 자판에 숫자 행 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: 기호 자판에 숫자 행 높이 전달하기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift:79-86`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:994-1000`
- Test: `SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`

**Interfaces:**
- Consumes: `SymbolKeyboardView.init(showsLanguageSwitchButton:showsNumberRow:)`, `updateNumberRowHeight(_:)` (Task 5)
- Produces: 없음. 이 Task가 기능을 실제로 연결한다.

**배경:** 기호 자판의 숫자 행은 주 자판과 **같은 높이**를 써야 한다. 주 자판에 숫자 행이 없는데 기호 자판에만 있으면 전체 프레임 높이와 어긋난다. 그래서 설정값을 다시 읽지 않고, 주 자판 뷰가 실제로 숫자 행을 가졌는지로 판단한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift`에 추가한다.

```swift
    @Test("주 자판에 숫자 행이 없으면 기호 자판에도 숫자 행이 없다")
    func test기호자판_주자판을따라감() {
        let withoutNumberRow = SymbolKeyboardView(showsLanguageSwitchButton: false, showsNumberRow: false)
        withoutNumberRow.updateNumberRowHeight(KeyboardHeightPolicy.portraitNumberRowHeight)

        #expect(withoutNumberRow.showsNumberRow == false)
        #expect(withoutNumberRow.numberRowPrimaryKeyButtonList.isEmpty)
        #expect(withoutNumberRow.firstRowPrimaryKeyButtonList.map(\.type.primaryKeyList.first)
                == ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"])
    }
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -only-testing:SYKeyboardTests/SymbolKeyboardLayoutTests/test기호자판_주자판을따라감
```

예상: Task 5의 `guard showsNumberRowSetting else { return }` 덕분에 이미 PASS할 수 있다. PASS하면 회귀 방지용으로 남기고 Step 3으로 넘어간다.

- [ ] **Step 3: `KeyboardView`에서 숫자 행 여부 주입**

`KeyboardView.swift:74-76`의 `showsLanguageSwitchButton` 아래에 같은 모양으로 추가한다.

```swift
    /// 주 키보드에 숫자 행이 있는지 여부
    private var showsNumberRow: Bool {
        primaryKeyboardViews.contains { $0.showsNumberRow }
    }
```

`symbolKeyboardView` 생성 부분을 바꾼다.

```swift
    lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = {
        let symbolKeyboardView = SymbolKeyboardView(
            showsLanguageSwitchButton: showsLanguageSwitchButton,
            showsNumberRow: showsNumberRow
        )
        symbolKeyboardView.isHidden = true
        
        return symbolKeyboardView
    }()
```

- [ ] **Step 4: 뷰 컨트롤러에서 높이 전달**

`BaseKeyboardViewController.swift`의 `setKeyboardHeight()`에서 아래 줄을 찾는다.

```swift
        primaryKeyboardViews.forEach { $0.updateNumberRowHeight(numberRowHeight) }
```

바로 다음 줄에 추가한다.

```swift
        // 기호 자판은 주 자판과 같은 높이를 써야 프레임과 어긋나지 않는다
        keyboardView.symbolKeyboardView.updateNumberRowHeight(numberRowHeight)
```

- [ ] **Step 5: 전체 테스트와 네 scheme 빌드**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'
```

예상: 전체 PASS.

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' || break
done
```

예상: 세 scheme 모두 BUILD SUCCEEDED.

빌드 후 `git status --short`를 확인한다. `.xcscheme`이 보이고 `RemotePath`만 바뀌었으면 되돌린다.

```sh
git status --short
git diff SYKeyboard.xcodeproj/xcshareddata/xcschemes/
```

- [ ] **Step 6: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift \
        Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
        SYKeyboardTests/Utils/SymbolKeyboardLayoutTests.swift
git commit -F - <<'EOF'
feat: #138 - 기호 자판에도 주 자판과 같은 숫자 행 높이를 적용

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: 문서 갱신과 최종 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-09-20-symbol-keyboard-number-row.md` (이 문서)

**Interfaces:**
- Consumes: Task 2~6의 결과
- Produces: 없음

- [ ] **Step 1: 계획 문서에 결과 기록**

이 문서의 각 Task 끝에 `**결과:**` 줄을 더해 실제 테스트 개수와 빌드 결과를 적는다. 확인하지 못한 항목은 미확인이라고 쓴다.

- [ ] **Step 2: 전체 테스트 재실행**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  -resultBundlePath /tmp/symbol-number-row-tests.xcresult
```

결과를 계획 문서에 적는다. 통과 개수는 아래로 읽는다.

```sh
xcrun xcresulttool get test-results summary --path /tmp/symbol-number-row-tests.xcresult
```

- [ ] **Step 3: 커밋**

```bash
git add docs/superpowers/plans/2026-09-20-symbol-keyboard-number-row.md
git commit -F - <<'EOF'
docs: #138 - 기호 자판 숫자 행 작업 결과 반영

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

## 수동 확인 목록

자동 테스트와 빌드로는 확인할 수 없다. 실제 입력 앱에서 `iPhone 13 mini / iOS 18.6` 기준으로 확인하고, 확인하지 못한 항목은 미확인으로 남긴다.

- [ ] 세로에서 기호 자판을 열면 숫자 행이 두벌식·쿼티와 같은 자리, 같은 높이로 보인다
- [ ] 기호 자판 1페이지 첫 줄이 `- / : ; ( ) ₩ & @ ”`, 둘째 줄이 `[ ] { } # % ^ * + =`다
- [ ] `⇧`를 누르면 첫 줄이 `_ \ | ~ < > $ £ ¥ •`, 둘째 줄이 `※ ☆ ★ ○ ● □ ■ △ ▲ ♡`다
- [ ] 도형 열 개가 모두 제 모양으로 보이고, `♡`가 빨간 이모지로 바뀌지 않는다
- [ ] 자판을 전환해도(한영·기호·숫자) 전체 프레임 높이가 바뀌지 않는다
- [ ] 가로로 돌려도 숫자 행이 그대로 있고 기호 배열도 같다. 숫자 행만 얇아진다(35pt)
- [ ] URL 입력란에서 자판이 한 페이지로 보이고 `⇧`가 없다
- [ ] 이메일 입력란에서 자판이 한 페이지로 보이고 `⇧`가 없다
- [ ] URL·이메일 자판의 셋째 줄 키가 좌우 가운데에 놓인다
- [ ] 숫자 행 설정을 끄면 기호 자판이 지금 배열로 돌아온다
- [ ] 나랏글·천지인만 쓰는 한글 extension에서는 기호 자판에도 숫자 행이 없다
