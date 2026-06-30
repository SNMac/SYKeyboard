# Issue 46 Hangeul English Keyboard Plan

Last Updated: 2026-07-01

## Goal

- GitHub issue #46의 한/영 통합 키보드 extension을 완성하고, 통합 키보드 안에서 한/영 전환 버튼으로 기존 한글/영어 입력 UI와 입력 로직을 전환한다.

## Current State

- `HangeulEnglishKeyboard` target과 app embed 설정은 이미 `SYKeyboard.xcodeproj/project.pbxproj`에 존재한다.
- `Keyboards/HangeulEnglishKeyboard/Resources/Info.plist`는 `PrimaryLanguage = mul`로 설정되어 있다.
- `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`는 Xcode 기본 키보드 템플릿 수준이라 기존 키보드 UI와 입력 흐름을 사용하지 않는다.
- 한글 전용 target은 `HangeulKeyboardViewController -> HangeulKeyboardCoreViewController -> BaseKeyboardViewController` 흐름을 사용한다.
- 영어 전용 target은 `EnglishKeyboardViewController -> EnglishKeyboardCoreViewController -> BaseKeyboardViewController` 흐름을 사용한다.
- `BaseKeyboardViewController`와 `KeyboardView`는 현재 하나의 `primaryKeyboardView`만 주입받는 구조다.
- 두벌식/영어 qwerty는 `StandardKeyboardView`, 나랏글/천지인은 `FourByFourKeyboardView` 또는 `FourByFourPlusKeyboardView` 계열을 사용한다.

## Approach

### 1. 통합 키보드용 공유 구조를 먼저 만든다

- `BaseKeyboardViewController`가 하나의 primary view만 전제로 삼는 지점을 확인하고, 통합 키보드가 한글 primary view와 영어 primary view를 모두 보유할 수 있게 확장한다.
- 기존 한글/영어 전용 키보드 동작은 그대로 유지한다.
- 추천 방향:
  - `KeyboardView`가 primary view를 1개만 받는 현재 생성 API를 유지하되, 통합 키보드용으로 여러 primary view를 받는 overload 또는 container view를 추가한다.
  - `BaseKeyboardViewController`에는 기본값이 현재와 같은 `primaryKeyboardViews: [PrimaryKeyboardRepresentable]` 확장 지점을 둔다.
  - 버튼 action, feedback, gesture 등록은 현재 primary 1개가 아니라 `primaryKeyboardViews` 전체에 적용한다.
  - `primaryKeyboardView`는 현재 활성 모드의 view를 반환하도록 유지해 기존 symbol/numeric/return/update 흐름을 최대한 재사용한다.

### 2. 한/영 통합 입력 컨트롤러를 추가한다

- `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`를 템플릿 코드에서 실제 통합 키보드 컨트롤러로 교체한다.
- 별도 Core target을 새로 만들기보다, 우선 extension target에서 통합 VC를 구현하고 필요한 Core 타입 공개 범위만 좁게 조정한다.
- 통합 VC는 다음 상태를 가진다.
  - `currentLanguageMode`: `.hangeul` 또는 `.english`
  - 한글 mode일 때 활성 primary view: 사용자 설정의 `selectedHangeulKeyboard`에 맞는 나랏글/천지인/두벌식
  - 영어 mode일 때 활성 primary view: qwerty
- 한/영 전환 시:
  - 한글 mode에서 영어 mode로 전환하기 전에 진행 중인 한글 조합을 확정 또는 정리한다.
  - 초기 정책은 "전환 시 composing을 현재 문서에 반영된 상태로 확정하고, 한글 processor/composition state를 reset"으로 둔다.
  - 영어 mode에서 한글 mode로 전환할 때 영어 shift/caps 상태는 초기화한다.
  - `currentKeyboard`를 활성 primary view의 `keyboard` 값으로 갱신하고 `didSetCurrentKeyboard()` 경로로 표시 상태, return key, symbol/numeric 복귀 흐름을 동기화한다.

### 3. 한/영 전환 버튼 UI를 공통 레이아웃에 추가한다

- 새 버튼 타입 예시: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift`.
- 버튼 표시는 현재 mode의 반대 언어 또는 현재 언어를 명확히 나타내는 짧은 텍스트로 정한다.
  - 권장: 현재 mode 표시보다 전환 대상 표시가 동작 예측이 쉬우므로 한글 mode에서는 `ABC`, 영어 mode에서는 `한글`.
- 사용자가 정한 배치 정책:
  - 한/영 전환 버튼은 `SwitchButton` 영역 옆에 둔다.
  - `SwitchButton`의 visible 영역만 `ShiftButton`의 visible 크기만큼 줄인다.
  - 터치 범위 기준으로 과하게 줄이지 않는다. `BaseKeyboardButton`의 `backgroundView`/`shadowView` 시각 영역과 실제 `UIButton` touch bounds를 구분해서 구현한다.
- 적용 대상:
  - `StandardKeyboardView`: 두벌식/영어 qwerty
  - `FourByFourKeyboardView`: 나랏글
  - `FourByFourPlusKeyboardView`: 천지인
- 기존 한글/영어 전용 keyboard에서는 버튼이 숨겨지고 기존 `SwitchButton`, `NextKeyboardButton`, one-handed/numeric gesture 동작을 유지한다.
- 통합 키보드에서만 `LanguageSwitchButton`을 `allButtonList`와 feedback/exclusive button 목록에 포함한다.

### 4. 자동완성/inputBuffer 정책을 명시하고 구현한다

- `inputBuffer`는 현재 `BaseKeyboardViewController`가 세션 단위로 관리한다.
- 통합 키보드에서 한/영을 오갈 때도 같은 텍스트 필드 안에서 입력한 문맥은 유지할 수 있으므로 `inputBuffer`는 공유한다.
- 다만 후보 엔진의 언어는 현재 mode와 맞아야 한다.
- `SuggestionController` 또는 `SuggestionService`에 현재 language를 갱신하는 API를 추가한다.
  - 한글 mode: `ko-KR`
  - 영어 mode: `en-US`
  - mode 전환 시 기존 n-gram 데이터를 저장하고, 새 언어 엔진은 지연 생성 패턴을 유지한다.
- 조합 중인 한글은 영어 자동완성 후보 갱신 전에 정리한다.

### 5. 안내/설정 화면 반영 여부를 검토한다

- issue 본문은 "사용자가 추가할 수 있는 키보드가 3개라는 점을 반영할지 검토"라고 되어 있다.
- 구현 본 작업에서는 extension 동작을 우선 완성하고, 설정/안내 문구는 별도 작은 후속 변경으로 분리하는 것을 권장한다.
- 단, iOS 설정에서 세 키보드가 별도 등록되는지 확인한 뒤 안내 화면의 현재 문구가 명백히 틀리면 같은 PR에서 최소 수정한다.

## Implementation Tasks

1. 현재 `HangeulEnglishKeyboard` target의 build 설정, plist, scheme 노출 상태를 확인한다.
2. `BaseKeyboardViewController`와 `KeyboardView`에 다중 primary view 지원을 추가하되 기존 단일 primary 사용자는 기본값으로 보존한다.
3. 한글/영어 primary view와 필요한 layout protocol/type의 공개 범위를 통합 target이 사용할 수 있는 최소 수준으로 조정한다.
4. `LanguageSwitchButton`을 추가하고 `StandardKeyboardView`, `FourByFourKeyboardView`, `FourByFourPlusKeyboardView`에 통합 키보드 전용 배치 옵션을 추가한다.
5. `SwitchButton` visible 영역 축소를 실제 touch bounds와 분리해 구현한다.
6. 통합 VC에서 `.hangeul`/`.english` mode, 활성 primary view, 한/영 버튼 action, mode 전환 시 상태 초기화 정책을 구현한다.
7. 한글 composing 확정/reset 경로를 통합 VC에서 안전하게 호출할 수 있도록 한글 Core의 공개 API를 좁게 추가한다.
8. `SuggestionController` 언어 갱신 API를 추가하고 mode 전환 시 후보 엔진 언어를 동기화한다.
9. Firebase/Crashlytics/전체 접근 허용 overlay는 기존 한글/영어 extension VC 패턴과 동일하게 통합 VC에 적용한다.
10. 기존 한글/영어 전용 target의 UI와 입력 흐름이 바뀌지 않았는지 빌드와 수동 확인으로 검증한다.

## Risks

- `BaseKeyboardViewController`는 lazy property와 action 등록 시점이 많아, 활성 primary view를 단순 computed property로 바꾸면 비활성 버튼에 action이 붙지 않을 수 있다.
- `SwitchGestureController`는 현재 `hangeulKeyboardView`와 `englishKeyboardView`를 둘 다 `primaryKeyboardView`로 받는다. 통합 키보드에서는 실제 한글/영어 view를 각각 전달하거나, gesture 대상 목록을 재설계해야 한다.
- `SwitchButton` 옆에 한/영 버튼을 추가하면 one-handed/numeric keypad pan gesture hit testing과 충돌할 수 있다.
- 한글 composing 중 mode 전환은 문서 텍스트, `compositionState`, processor, undo/redo group, 자동완성 후보가 함께 움직이므로 회귀 위험이 높다.
- `SuggestionController` 언어 변경은 n-gram 저장 파일과 텍스트 검사 엔진 재생성 정책을 건드린다.
- Xcode project 변경, target membership, entitlements, InfoPlist string catalog는 빌드 설정 회귀 위험이 있다.

## Verification

실행할 자동 검증:

```sh
xcodebuild -list -project SYKeyboard.xcodeproj
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

수동 확인:

- iOS 설정에서 `한글 키보드`, `영어 키보드`, `한/영 통합 키보드`가 별도 항목으로 등록되는지 확인한다.
- 통합 키보드를 실제 텍스트 입력 앱에서 열고 한글 mode 입력/삭제/스페이스/리턴을 확인한다.
- 통합 키보드에서 한글 composing 중 `ABC` 전환 시 조합 상태가 깨지지 않고 확정/reset되는지 확인한다.
- 영어 mode 입력/삭제/스페이스/리턴/shift/caps lock을 확인한다.
- `!#1` symbol 전환과 기존 globe/next keyboard 버튼이 한/영 전환 버튼과 충돌하지 않는지 확인한다.
- one-handed mode와 numeric keypad gesture가 통합 키보드에서도 동작하는지 확인한다.

## Done Criteria

- `HangeulEnglishKeyboard` extension이 기존 공통 키보드 UI를 사용해 빌드된다.
- 통합 키보드 안에서 한/영 전환 버튼으로 한글 mode와 영어 mode가 전환된다.
- 한/영 전환 버튼은 사용자가 정한 `SwitchButton` 주변 배치와 visible-size 축소 정책을 따른다.
- 한글 composing 중 전환 정책, inputBuffer 공유 정책, 자동완성 언어 정책이 코드와 문서에 반영된다.
- 기존 `HangeulKeyboard`, `EnglishKeyboard` target 동작이 유지된다.
- 위 자동 빌드/테스트와 수동 확인 결과가 기록된다.
