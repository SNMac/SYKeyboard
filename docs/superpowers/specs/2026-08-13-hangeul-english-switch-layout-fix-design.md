# #46 한·영 통합 키보드 전환 버튼 레이아웃 보완 설계

**작성일:** 2026-08-13  
**대상:** `feat/#46-hangeul-english-unified-keyboard`  
**선행 설계:** `2026-08-12-hangeul-english-keyboard-design.md`

## 목적

통합 키보드의 한/영 버튼을 기존 `SwitchButton` 위에 겹치는 방식에서 독립 버튼
배치로 바꾼다. 다음 세 회귀를 함께 해결한다.

1. primary 키보드의 `!#1` visible area가 Shift보다 작아진 문제
2. symbol 키보드에 한/영 버튼이 없는 문제
3. `!#1` 모서리의 `123`과 우측 화살표 안내가 한/영 버튼에 가려진 문제

기존 한글·영어 전용 extension의 레이아웃과 입력 동작도 회귀 없이 동작해야 한다.
이를 위해 전용·통합 구현을 복사해 분기하지 않고 기존 shared base/view를 한 번만
수정한다. 통합 여부는 기존 `showsLanguageSwitchButton` opt-in으로만 결정한다.

## 확인된 원인

현재 통합 primary view는 `LanguageSwitchButton`을 `SwitchButton`의 절반 위에
frontmost sibling으로 올리고, `SwitchButton.backgroundView`도 나머지 절반만
보이게 한다. 따라서 `!#1` 배경은 원래 버튼의 절반으로 줄고,
`SwitchButton.keyboardSelectLabel`이 같은 영역에 가려진다.

`SymbolKeyboardView`는 통합 여부를 전달받지 않고 항상 기본 생성되므로 한/영
버튼을 만들지 않는다. 이는 런타임 action 누락이 아니라 view 생성 범위가
primary view로 한정된 설계 문제다.

## 채택한 배치

한/영 버튼을 `SwitchButton`과 별도의 arranged subview로 배치한다. 기존
`SwitchButton`의 touch bounds나 visible background를 나누지 않는다.

### 두벌식·쿼티 primary

화면 왼쪽에서 오른쪽 순서는 다음과 같다.

```text
!#1 | 한/영 | 지구본(필요한 경우) | 스페이스 | ...
```

- `!#1` 버튼 너비는 같은 view의 Shift 버튼 너비와 같게 한다.
- 한/영 버튼은 가능하면 같은 secondary slot 너비를 사용하되 두벌식·쿼티의
  primary 글자 key 너비보다 작아지지 않는다.
- 지구본 버튼은 첫 구현에서 같은 secondary slot 너비를 사용한다.
- 지구본이 표시될 때 modifier 영역이 그 너비만큼 늘어나고, 유연한 스페이스
  영역이 같은 양만큼 줄어든다.
- 지구본이 숨겨지면 해당 arranged subview가 빠지고 스페이스가 그 너비를
  돌려받는다.
- URL, 이메일 등 기존 fourth-row 특수 key와 Return 영역의 정책은 유지한다.

### 천지인·나랏글 primary

현재 코드의 기존 순서는 화면 왼쪽에서 오른쪽으로 `지구본 → !#1`이다. 통합
키보드는 이 modifier 영역의 순서를 다음과 같이 유지하며 같은 영역을 세 칸으로
나눈다.

```text
지구본(필요한 경우) | 한/영 | !#1
```

- 지구본이 표시될 때 세 버튼은 기존 modifier 영역을 3등분한다.
- 지구본이 숨겨지면 한/영과 `!#1`이 기존 modifier 영역을 2등분한다.
- 천지인·나랏글에는 Shift 기준 너비가 없으므로 기존 modifier 영역 바깥의
  숫자·문자 key 폭은 변경하지 않는다.
- 천지인·나랏글은 사용자가 실기기에서 타협점을 확인할 수 있도록 두벌식·쿼티
  primary 글자 key 최소 너비 규칙에서 제외한다.

### symbol 키보드

통합 키보드의 symbol 화면 순서는 다음과 같다.

```text
한글/ABC | 한/영 | 지구본(필요한 경우) | 스페이스 | ...
```

- `한글/ABC` 복귀 버튼 너비는 symbol Shift인 `1/2` 버튼 너비와 같게 한다.
- 한/영 버튼은 symbol primary 글자 key 너비보다 작아지지 않는다.
- 현재 mode에 따라 복귀 버튼은 기존처럼 `한글` 또는 `ABC`를 표시한다.
- symbol 화면에서 한/영을 전환해도 화면은 symbol에 유지된다.
- 다시 primary 화면으로 돌아가면 선택한 언어의 키보드가 표시된다.
- `NumericKeyboardView`와 `TenkeyKeyboardView`에는 한/영 버튼을 추가하지 않는다.

## 한/영 버튼 시각 구성

사용자가 제공한 레퍼런스처럼 `/` glyph를 표시 문자열에 넣지 않는다.

- `한`: 버튼의 위쪽 leading에 배치한 별도 `UILabel`
- `영`: 버튼의 아래쪽 trailing에 배치한 별도 `UILabel`
- divider: 버튼 중앙에 `/` 방향으로 그린 얇은 `CAShapeLayer`

divider는 글자가 아닌 고정 그래픽이며 항상 `.label` 색을 사용한다. 언어 mode별
색상은 다음과 같다.

| mode | `한` | divider | `영` |
|---|---|---|---|
| 한글 | `.label` | `.label` | `.languageSwitchMutedLabel` |
| 영어 | `.languageSwitchMutedLabel` | `.label` | `.label` |

divider path는 `layoutSubviews()`에서 현재 bounds를 기준으로 다시 계산해 키보드
너비와 appearance 변경에 대응한다. 별도 재사용 가능한 divider component는 만들지
않고 `LanguageSwitchButton` 내부 구현으로 한정한다.

VoiceOver에는 시각적 세 요소를 개별 노출하지 않고 버튼 하나로 노출한다.
`accessibilityLabel`은 `한영 전환`, `accessibilityValue`는 현재 mode의 `한글` 또는
`영어`로 갱신한다.

## 생성과 action 흐름

`KeyboardView.loadFromNib(primaryKeyboardViews:)`는 전달된 primary view 중
`languageSwitchButton`이 있는지로 통합 keyboard opt-in 여부를 판정한다. 이 값으로
공유 `SymbolKeyboardView`를 생성한다.

`SymbolKeyboardLayoutProvider`는 primary protocol과 같은 방식으로 optional
`languageSwitchButton`을 제공한다. 통합 opt-in일 때만 다음 목록에 포함한다.

- `secondaryButtonList`와 `allButtonList`
- Base의 feedback·pressed-state 처리
- 통합 controller의 `.touchUpInside` 언어 전환 action
- 현재 mode에 따른 active/muted label 갱신

한글·영어 전용 extension은 primary view에 한/영 버튼이 없으므로 symbol view도
기존처럼 버튼 없이 생성된다. 통합 controller의 기존 `applyLanguageMode` 순서,
조합 종료, suggestion 언어 경계, symbol 화면 유지 로직은 바꾸지 않는다.

두벌식과 쿼티의 modifier 배치는 공통 `StandardKeyboardView`에만 구현하고 각 concrete
view에 복사하지 않는다. 천지인과 나랏글도 각각 구현하지 않고 현재 공유하는 4×4
base 계층의 기존 modifier row 구성 지점에서 처리한다. 전용 controller나 adapter에
통합 전용 레이아웃 코드를 복제하지 않는다.

## 숫자 전환 안내와 gesture

`123`과 우측 화살표는 기존 `SwitchButton.keyboardSelectLabel`과
`SwitchGestureController`를 그대로 사용한다. 한/영 버튼이 독립 arranged subview가
되면 label을 가리는 view가 없어지므로 별도 복제나 새로운 overlay를 만들지 않는다.

다음 기존 동작을 유지한다.

- 숫자 키패드 사용 설정에 따른 안내 표시 여부
- pan 중 화살표 강조
- `KeyboardSelectOverlayView` 표시와 선택
- 한손 키보드 안내와 gesture

## 테스트와 검증

자동 테스트는 exact color, font, private label 계층 또는 SF Symbol 이름을 고정하지
않는다. 실제 production view 진입점을 통해 다음 계약을 검증한다.

- 통합 primary view의 한/영 버튼이 `SwitchButton`과 독립된 버튼이다.
- 두벌식·쿼티의 `!#1` layout width가 Shift layout width와 같다.
- 두벌식·쿼티·symbol의 한/영 버튼 layout width가 해당 primary 글자 key보다
  작지 않다.
- 통합 primary view를 전달한 `KeyboardView`의 symbol view에는 한/영 버튼이 있다.
- 전용 primary view를 전달한 경우 symbol view에는 한/영 버튼이 없다.
- 전용 한글·영어 adapter의 primary modifier row는 한/영 버튼 없이 기존 순서와
  `SwitchButton` full visible area를 유지한다.
- symbol 한/영 버튼이 mode 변경을 반영하고 secondary feedback 목록에 포함된다.
- 지구본 표시 여부가 바뀌어도 버튼 순서와 Auto Layout이 유효하다.

자동 테스트와 네 scheme build 후 실기기에서 다음을 확인한다.

- 두벌식·쿼티에서 지구본 표시 시 스페이스만 의도한 만큼 줄어드는지
- 천지인·나랏글에서 `지구본 → 한/영 → !#1` 3등분이 읽히는지
- symbol 화면에서 `한글/ABC → 한/영 → 지구본` 순서와 전환 동작
- `!#1`의 `123` 우측 화살표, pan 강조와 선택 overlay
- 레퍼런스와 같은 `한`/divider/`영` 대각 배치와 light/dark 가독성
- 버튼 touch 충돌, Auto Layout conflict와 extension crash 부재

실기기에서 언어 버튼이나 지구본 너비의 시각 조정이 필요하면 이 구조 안의 width
constraint만 조정한다. 입력 action과 mode 전환 흐름은 함께 변경하지 않는다.

## 제외 범위

- 한글·영어 전용 extension의 한/영 버튼 추가
- numeric/TenKey 화면의 한/영 버튼 추가
- `SuggestionButtonLabelColor` 변경
- `LanguageSwitchMutedLabelColor`의 RGB 재조정
- 키보드 입력·조합·삭제·자동완성 정책 변경
