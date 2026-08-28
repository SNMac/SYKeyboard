# 4x4 계열 키보드 글자 열 너비 조정 설계

## 목적

GitHub Issue #112에 따라 4열 격자를 쓰는 키보드에서 좌측 3열(글자·숫자 버튼)과
우측 1열(기능 버튼)의 너비 비율을 사용자가 조정할 수 있게 한다.

우측 열(삭제·스페이스·리턴·전환)은 사용 빈도가 상대적으로 낮으므로 글자 열을
더 넓게 쓰는 선택지를 제공한다. 기본값은 현재의 균등 분할이며, 기본값에서는
지금과 완전히 동일하게 동작한다.

## 적용 대상

이슈 본문은 나랏글·천지인만 언급하지만, **숫자 키패드도 같은 4열 격자**이므로
함께 적용한다.

| 뷰 | 사용 키보드 | 적용 |
| --- | --- | --- |
| `FourByFourKeyboardView` → `NaratgeulKeyboardView` | 나랏글 | O |
| `FourByFourPlusKeyboardView` → `CheonjiinKeyboardView` | 천지인 | O |
| `NumericKeyboardView` | 숫자 키패드 | O |
| `StandardKeyboardView` → 두벌식·쿼티 | 두벌식, 영문 | X (10열) |
| `SymbolKeyboardView` | 기호 | X (10열) |
| `TenkeyKeyboardView` | `.numberPad`·`.decimalPad` | X (아래 참고) |

`NumericKeyboardView`는 `FourByFourPlusKeyboardView`를 상속하지 않지만 구조가
사실상 같다. 3행×3숫자 + 4열 기능 열, 동일한 `usesBottomSpaceLayout` 변형,
동일한 `fourthRowRightSecondaryButtonHStackView` modifier 스택, 동일한
`updateModifierDistribution`, 동일한 `languageSwitchButtonWidthRatio` 사용,
그리고 "4x4 계열은 4행 스택이 전체 폭을 4등분해"라는 같은 주석까지 공유한다.

`TenkeyKeyboardView`는 제외한다. 1~3행이 3버튼, 4행이 4버튼인 구조여서
"글자 3열 + 기능 1열" 격자가 아니고, `BaseKeyboardViewController` 1294행에서
`currentKeyboard != .tenKey`일 때 숨겨지는 배타적 키보드다.

## 확인한 기준

- 작업 브랜치: `feat/#112-letter-column-width` (`develop`의 `d2a99271`에서 분기)
- 대상 3개 뷰의 4개 행은 모두 `KeyboardRowHStackView`의 기본
  `distribution = .fillEqually`로 항상 4등분된다.
- 비균등 폭 선례: `StandardKeyboardView`가
  `widthAnchor.constraint(equalTo:multiplier:)`를 쓴다. 새 레이아웃 메커니즘을
  도입하지 않고 같은 방식을 쓴다.
- 프로토콜 선례: `NormalKeyboardLayoutProvider`의
  `nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey:)`가
  "프로토콜 선언 + extension 기본 no-op + 4x4 계열만 override" 형태로 이미 있다.
- 미리보기 제스처: `isPreview` 가드는 텍스트 삽입·삭제·자동완성 준비 경로에만
  있고 `addGesturesToSwitchButton`, `updateShowingKeyboard()`에는 없다.
  `OneHandedKeyboardWidthSettingsView`가 이미 미리보기 제스처 콜백
  (`onPreviewOneHandedModeChanged`)에 의존한다. 따라서 미리보기에서 `!#1`을
  드래그해 숫자 키패드를 직접 확인할 수 있고, 별도 강제 표시 장치가 필요 없다.

## 열 구성 확인

기본 배치는 세 뷰 모두 4행 전부 4열이 기능 열이다.

```
나랏글 / 천지인 기본 배치            숫자 키패드 기본 배치
1행 [글자, 글자, 글자, 삭제     ]     1행 [1,      2, 3,      삭제      ]
2행 [글자, 글자, 글자, 스페이스  ]     2행 [4,      5, 6,      스페이스   ]
3행 [글자, 글자, 글자, 리턴     ]     3행 [7,      8, 9,      리턴      ]
4행 [글자, 글자, 글자, 모디파이어]     4행 ['-'',', 0, '.''/', 모디파이어 ]
```

하단 스페이스 배치(`usesBottomSpaceLayout == true`)는 천지인·숫자 키패드
양쪽 모두 열 구성이 같은 방식으로 어긋난다.

```
천지인 하단 스페이스 배치                     숫자 키패드 하단 스페이스 배치
1행 [글자,      글자, 글자,     삭제       ]  1행 [1,         2, 3,      삭제      ]
2행 [글자,      글자, 글자,     리턴       ]  2행 [4,         5, 6,      리턴      ]
3행 [글자,      글자, 글자,     '?''!'    ]  3행 [7,         8, 9,      '-''/'   ]
4행 [모디파이어, 글자, 스페이스, '.'','    ]  4행 [모디파이어, 0, 스페이스, '.'','  ]
        ↑ 1열이 기능           ↑ 4열이 글자
```

## 결정: 위치 기준 일괄 적용

하단 스페이스 배치에도 **위치 기준으로** 1~3열 확대 / 4열 축소를 그대로
적용한다. 행마다 의미(글자/기능)에 따라 다르게 적용하면 열 경계가 행마다
어긋나 격자가 깨진다.

이 결정의 결과로 하단 스페이스 배치에서는 3행·4행의 문자 스택이 좁아지고
4행 모디파이어 열이 넓어진다. 의도와 반대되는 부작용이지만 격자 정렬을
우선한다.

## 설계

### 1. 계산 정책 — `KeyboardColumnWidthPolicy`

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardColumnWidthPolicy.swift`
(신규). UI 의존이 없는 순수 타입이며 전체 폭 대비 비율을 돌려준다.

| 항목 | 식 | `r = 1.00` | `r = 1.20` |
| --- | --- | --- | --- |
| 글자 열 1개 | `0.25 × clamp(r)` | `0.2500` | `0.3000` |
| 기능 열 | `1 − 3 × 글자 열` | `0.2500` | `0.1000` |
| 한영 전환 버튼 | `기능 열 × 0.4` | `0.1000` | `0.0400` |

- `clamp(r)`은 `1.00...1.20`으로 자른다.
- 한영 전환 버튼 몫 `0.4`는 상수를 새로 박지 않고 기존 값에서 유도한다.
  `languageSwitchButtonWidthRatio(0.1) ÷ 0.25 = 0.4`이므로, 기본 배율에서
  한영 전환 버튼 폭이 지금과 **구조적으로** 같아진다(우연한 일치가 아니다).
- 이 연동이 없으면 기능 열이 `0.10`이 될 때 고정 폭 `0.1`인 한영 전환 버튼이
  열 전체를 차지해 `switchButton` 폭이 0이 된다.
- 상수(열 개수 `4`, 배율 범위 `1.00...1.20`, 한영 전환 버튼 몫)는
  `KeyboardLayoutFigure`에 기존 계수와 나란히 정의한다.

### 2. 레이아웃 제약

`FourByFourKeyboardView`, `FourByFourPlusKeyboardView`, `NumericKeyboardView`의
`setConstraints()`에 다음을 추가한다. 세 뷰의 처리는 동일하다.

- 4개 행 스택의 `distribution`을 `.fill`로 변경한다. 중첩 스택
  (`returnButtonHStackView`, `fourthRowLeftPrimaryButtonHStackView`,
  `fourthRowRightPrimaryButtonHStackView`,
  `fourthRowRightSecondaryButtonHStackView`)은 기존 값을 유지한다.
- 행마다 1~3열끼리 `widthAnchor.constraint(equalTo:)` 2개를 건다.
  **이 제약은 배율과 무관하므로 한 번만 만들고 다시 만들지 않는다.**
- 행마다 4열에
  `widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 기능 열 비율)`
  1개를 건다. **이 4개만 프로퍼티로 보관한다.**
- 한영 전환 버튼 제약의 multiplier를 정책 값으로 교체한다. 기존 priority 999와
  `updateModifierDistribution` 동작은 유지한다.

4열 + 등폭 2개 + 스택의 `.fill`이 만드는 "폭 합 = 행 폭" 관계로 미지수 4개가
모두 결정되므로 Auto Layout 모호성이 없다. `r = 1.00`이면 결과가
`fillEqually`와 수학적으로 동일하다.

`.fillEqually` → `.fill` 전환의 안전성 근거: 대상 행 스택의 **직속 자식은
숨겨지지 않는다.** `HangeulKeyboardLayoutProvider`의 4개 모드 전부에서
`spaceButton.isHidden = false`이고, `returnButton`·`secondaryAtButton`·
`secondarySharpButton`·`nextKeyboardButton`은 모두 중첩 스택 안에 있다.
숫자 키패드는 모드 전환에 따른 숨김 처리가 없다.

### 3. 배율 주입과 갱신

- 초기값은 `setConstraints()`에서 `UserDefaultsManager.shared`로 읽는다.
  `isCheonjiinBottomSpaceEnabled`·`isNumericKeypadBottomSpaceEnabled`와 같은
  방식이며, 키보드 확장은 열릴 때마다 새로 생성되므로 별도의 설정 감시 장치가
  필요 없다.
- 실행 중 갱신은 `updateLetterColumnWidthMultiplier(_:)` 한 메서드로 한다.
  보관한 기능 열 제약 4개와 한영 전환 버튼 제약을 비활성화한 뒤 새 multiplier로
  다시 만든다. `NSLayoutConstraint.multiplier`가 읽기 전용이라 재생성이 필요하다.
- 이 메서드는 `NormalKeyboardLayoutProvider`에 선언하고 extension에 **기본
  no-op**을 둔다. `nextKeyboardButtonVisibilityDidChange`와 같은 형태이며,
  두벌식·영문·기호·텐키는 코드 변경 없이 무시한다.
- `BaseKeyboardViewController.updateLetterColumnWidthForPreview(to:)`가
  `primaryKeyboardViews`와 **`numericKeyboardView`** 양쪽에 전달하고
  `view.layoutIfNeeded()`를 호출한다. 숫자 키패드는 `primaryKeyboardViews`에
  포함되지 않으므로 따로 호출해야 한다. `updateOneHandedWidthForPreview`
  패턴을 따른다.

한영 통합 키보드(`HangeulEnglishKeyboardViewController`)의 나랏글·천지인 뷰와
숫자 키패드는 같은 타입을 쓰므로 자동으로 따라온다. 폭이 multiplier 기반이라
한 손 키보드와 가로 모드도 별도 처리가 필요 없다.

### 4. 저장소

`SYKeyboardCore`의 외형 설정 구역에 추가한다.

- `UserDefaultsKeys.letterColumnWidthMultiplier = "letterColumnWidthMultiplier"`
- `DefaultValues.letterColumnWidthMultiplier: Double = 1.0`
- `UserDefaultsManager.letterColumnWidthMultiplier: Double`

나랏글·천지인·숫자 키패드가 **하나의 값을 공유한다.** 키보드별 개별 설정은
두지 않는다.

### 5. 설정 화면

`SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift`
(신규). `OneHandedKeyboardWidthSettingsView` 구조를 그대로 따른다.

- 상단에 현재 값을 `100`~`120`으로 표시한다.
- `Slider(value:in: 1.0...1.2, step: 0.01)`
- 취소 / 리셋 / 저장 툴바. 저장 시 Analytics
  (`pref_letter_column_width` 사용자 속성, `letter_column_width` 이벤트).
- 하단에 `PreviewKeyboardView`.
- `.requestReviewOnDetailSettingsReturn()` 적용.

`AppearanceSettingsView`에는 "키보드 높이" 바로 다음에 `NavigationLink`를 두고,
제목과 함께 적용 범위를 부제목으로 표시한다(`isNumericKeypadBottomSpaceEnabled`
등에서 쓰는 두 줄 라벨 형태). 노출 조건은 **`selectedHangeulKeyboard`가
`.naratgeul` 또는 `.cheonjiin`이거나, `isNumericKeypadEnabled`가 켜져 있을
때**다. 둘 다 아닌 사용자에게는 적용 대상이 하나도 없으므로 숨긴다.
`AppearanceSettingsView`는 `selectedHangeulKeyboard`를 읽기 위해
`HangeulKeyboardCore`를 import한다.

미리보기는 현재 구조를 그대로 쓴다. 사용자는 미리보기 키보드에서 `!#1` 버튼을
드래그해 숫자 키패드로 전환한 상태로도 슬라이더 효과를 확인할 수 있다.

`PreviewKeyboardView`에 `letterColumnWidthMultiplier` 바인딩을 추가하고
`PreviewHangeulKeyboardViewController`와
`PreviewEnglishKeyboardViewController` 양쪽의 `updateUIViewController`에서
전달한다. **영문 미리보기도 숫자 키패드를 공유하므로 함께 전달해야 한다.**
기존 호출부 두 곳(`KeyboardHeightSettingsView`,
`OneHandedKeyboardWidthSettingsView`)은 저장된 값을 `.constant`로 넘겨 현재
동작을 유지한다.

로컬라이징 문자열은 `SYKeyboard/Resources/Localizable.xcstrings`에 추가한다.

### 6. 테스트

- `KeyboardColumnWidthPolicyTests` (신규)
  - 범위 밖 입력 clamp
  - 글자 열 3개 + 기능 열 합이 1.0
  - `r = 1.00`에서 모든 열이 `0.25`이고 한영 전환 비율이
    `KeyboardLayoutFigure.languageSwitchButtonWidthRatio`와 같음
- `FourByFourColumnWidthLayoutTests` (신규)
  - `CheonjiinBottomSpaceLayoutTests` 하네스를 따라 실제
    `NaratgeulKeyboardView`, `CheonjiinKeyboardView`(양쪽 배치),
    `NumericKeyboardView`(양쪽 배치)를 만들고 `layoutIfNeeded()` 후 프레임
    폭을 검증한다.
  - `r = 1.00`이 균등 분할과 같은지 고정한다.
  - `r = 1.20`에서 글자 열이 넓어지고 4열이 좁아지는지, 그리고 **행 간 열
    경계가 정렬되는지**(1~3행과 4행의 열 경계 x좌표 일치) 검증한다.
- `UserDefaultsContractTests`에 새 키를 추가한다.
- 기존 `KeyboardModifierLayoutTests`, `CheonjiinBottomSpaceLayoutTests`,
  `NumericBottomSpaceLayoutTests`는 `languageSwitchButtonWidthRatio` 값이
  기본 배율에서 바뀌지 않으므로 수정 없이 통과할 것으로 예상한다. 실제 실행으로
  확인한다.

## 변경 요약

이슈에 명시된 변경:

1. `KeyboardLayoutFigure`에 비율 계수 추가
2. `FourByFourKeyboardView` / `FourByFourPlusKeyboardView` 비율 폭 제약
3. `UserDefaultsKeys` / `DefaultValues` / `UserDefaultsManager` 키 추가
4. 슬라이더 설정 화면과 `AppearanceSettingsView` 진입점
5. 미리보기 실시간 반영

이슈에 없지만 필요한 변경:

1. **숫자 키패드(`NumericKeyboardView`)도 적용 대상에 포함한다.** 이슈는
   나랏글·천지인만 언급했으나 같은 4열 격자다.
2. **한영 전환 버튼 폭 계산식이 기능 열에 연동된다.** 기본값에서 값은 동일하다.
3. **행 스택 `distribution`을 `.fill`로 바꾼다.** `fillEqually`의 등폭 제약이
   required라 제약만 추가하면 충돌한다.
4. **`NormalKeyboardLayoutProvider`에 메서드 1개 추가** (기본 no-op).
5. **`PreviewKeyboardView` 시그니처에 바인딩 1개 추가** → 기존 호출부 2곳 수정.
   동작은 유지한다.
6. **설정 진입점 조건부 노출** — 나랏글·천지인 선택 또는 숫자 키패드 활성화.

배율을 올린 사용자에게만 생기는 변화:

| 대상 | 변화 |
| --- | --- |
| 나랏글, 천지인 기본 배치, 숫자 키패드 기본 배치 | 글자·숫자 3열 확대 / 기능 열 축소 (의도한 동작) |
| 천지인 하단 스페이스 배치 | 3행 `'?' '!'`, 4행 `'.' ','` 축소 / 모디파이어 열 확대 |
| 숫자 키패드 하단 스페이스 배치 | 3행 `'-' '/'`, 4행 `'.' ','` 축소 / 모디파이어 열 확대 |
| 한영 통합 키보드 | 나랏글·천지인 모드와 숫자 키패드에 동일 적용 |
| 두벌식·영문 사용자 | 주 키보드는 그대로, **숫자 키패드만** 바뀜 |
| 한영 전환·지구본·전환 버튼 | 기능 열과 함께 축소 |
| 키보드 선택 오버레이 | 취소 영역이 기존 최소폭 32pt 가드에 걸릴 수 있음 |

변하지 않는 것:

- 두벌식, 영문(쿼티), 기호, 텐키 레이아웃
- 입력 로직, 조합, 삭제, 커서 이동, 스페이스/리턴 동작
- 키보드 높이 계산, 한 손 모드 동작

## 리스크와 수동 확인 항목

- **터치 타깃**: `r = 1.20`에서 기능 열은 한 손 키보드 기본 폭(320pt) 기준
  32pt, 최소 폭(300pt) 기준 30pt가 된다. 지구본이 보이면 `switchButton`이 그
  절반까지 좁아진다. Apple HIG 최소 터치 타깃 44pt보다 작다. 사용자가 상한
  `1.20`을 선택했으므로 그대로 구현하되, 실기 확인 후 상한 조정이 필요하면
  별도로 논의한다.
- **자동 테스트로 판정할 수 없어 미확인으로 남는 항목**
  - 한 손 모드·가로 모드 실제 화면
  - 실제 입력 앱에서 기본값이 기존 배치와 동일한지
  - 좁은 기능 열에서 키보드 선택 오버레이 취소 영역 동작
  - 미리보기에서 `!#1` 드래그로 숫자 키패드 전환 후 슬라이더 반영
  - 천지인·숫자 키패드 하단 스페이스 배치의 체감 사용성
- `Modules/`에 새 파일(`KeyboardColumnWidthPolicy.swift`)을 추가하므로
  `SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboardCore` 타깃과
  `SYKeyboard` 타깃 `membershipExceptions`에 알파벳 순으로 등록해야 한다.
- 이슈 #112 본문과 체크리스트에 숫자 키패드가 빠져 있으므로, 구현 착수 전
  이슈를 갱신하거나 PR 설명에 범위 확대를 명시한다.

## 검증 계획

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

로컬 환경에 `iOS 16.0` 런타임이 없으면 가장 가까운 iOS 16+ 시뮬레이터로
조정하고 실제 기기명과 OS 버전을 결과에 명시한다.
