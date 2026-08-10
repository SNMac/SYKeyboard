# 키보드 수명주기·Auto Layout 크래시 방지 설계

## 목적

키보드 확장이 표시되거나 크기가 변경되는 전환 구간에서 발생한 다음 두
Crashlytics 경로를 방어한다.

- `UIInputViewController`의 document state reset과
  `textDocumentProxy.autocorrectionType` 접근이 겹치는 경로
- 숨겨진 `UIStackView.arrangedSubview`의 nonzero 크기 제약과 UIKit 내부 숨김
  제약이 경쟁하는 경로

한글·영문 입력, 자동완성 표시 조건, 키보드 모드별 키 배열, 세로·가로 높이와
현재 버튼 너비 비율은 변경하지 않는다.

## Root cause

### 조기 document proxy 접근

`viewDidLoad`와 `viewWillAppear`에서 자동완성 표시 여부와 키보드 높이를 계산하며
`textDocumentProxy.autocorrectionType`을 직접 읽는다. 키보드 표시 또는 입력 대상
전환 중 UIKit의 `_didResetDocumentState`와 이 접근이 겹치면 private document state가
안정되기 전에 다시 생성되는 경로가 열린다.

프로젝트에서 실제 입력 대상과 selection 변경 시 호출을 확인한
`textWillChange(_:)`/`textDidChange(_:)`는 host 입력 trait 동기화 지점으로 사용한다.

### 숨김 arranged subview의 required 크기 제약

`suggestionBarView`와 영어 키보드의 `atButton`, `periodButton`, `slashButton`,
`dotComButton`은 `UIStackView.arrangedSubview`이면서 동적으로 숨겨진다. 이 뷰의
nonzero 높이·너비 제약이 required priority로 유지되어, 숨김 시 UIKit이 만드는
0 크기 제약과 경쟁한다.

## 선택한 방식

### autocorrection trait 캐시

`BaseKeyboardViewController`가 마지막으로 확인한 `UITextAutocorrectionType`을
보관한다. 초기값은 기존 nil fallback과 같은 `.default`다.

1. `textWillChange(_:)`와 `textDidChange(_:)` 진입 시 현재
   `textDocumentProxy.autocorrectionType`을 캐시에 반영한다.
2. `updateSuggestionBarHidden()`과 `setKeyboardHeight()`는 proxy를 다시 읽지 않고
   캐시와 기존 `KeyboardPresentationStatePolicy`를 사용한다.
3. `viewDidLoad`와 `viewWillAppear`에서는 host document state에 접근하지 않는다.
4. 자동완성 설정, 현재 키보드 종류와 `.no` trait를 조합하는 기존 정책은
   그대로 유지한다.

### 숨김 가능한 크기 제약 priority 조정

숨김 가능한 arranged subview의 nonzero 크기 제약만 priority `999`로 설정한다.

- 뷰가 보일 때는 경쟁하는 제약이 없으므로 기존 크기를 그대로 결정한다.
- 뷰가 숨겨질 때는 UIKit의 required 0 크기 제약이 우선해 충돌 없이 접힌다.
- stack distribution, arranged subview 순서와 모드별 `isHidden` 전환은 바꾸지
  않는다.

## 고려한 대안

### viewDidAppear까지 모든 trait 갱신 지연

document state 경쟁은 줄일 수 있지만 첫 프레임에서 자동완성 바와 키보드 높이가
달라질 수 있어 채택하지 않는다.

### 숨김 상태마다 크기 제약 활성화·비활성화

visible 상태에서는 required 크기를 유지할 수 있지만 모든 모드 전환에서 제약
수명을 함께 관리해야 한다. 누락 위험과 코드량이 priority 조정보다 크므로
채택하지 않는다.

### NSException 포착 또는 재시도

Swift에서 UIKit 내부 `NSException`을 정상 오류 흐름으로 처리할 수 없고 원인인
조기 접근을 남기므로 채택하지 않는다.

## 변경 범위

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - autocorrection trait 캐시 및 callback 동기화
  - 자동완성 표시·높이 계산의 직접 proxy 접근 제거
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
  - suggestion bar 높이 제약 priority 조정
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
  - 숨김 가능한 영문 특수 키 너비 제약 priority 조정

`DeleteButton`, 한글 processor/automata, suggestion 엔진, 키 입력 이벤트 타이밍은
변경하지 않는다.

## 검증

- 기존 `KeyboardPresentationStatePolicyTests`로 자동완성 표시 조건을 확인한다.
- 기존 `KeyboardHeightPolicyTests`로 세로·가로 및 suggestion bar 표시별 높이를
  확인한다.
- 전체 `SYKeyboard` 테스트를 실행한다.
- `HangeulKeyboard`, `EnglishKeyboard` scheme을 빌드한다.
- 가능한 경우 Simulator 실제 입력 화면에서 다음을 확인한다.
  - predictive text 켜짐/꺼짐
  - autocorrection default/no 입력 필드 전환
  - default, URL, email, Twitter, web search, TenKey 레이아웃
  - 세로·가로 회전과 빠른 키보드 열기·닫기
  - Auto Layout 충돌 로그 부재

## 완료 기준

- `viewDidLoad`와 `viewWillAppear`의 높이·자동완성 계산이
  `textDocumentProxy.autocorrectionType`을 직접 읽지 않는다.
- `.no` trait와 TenKey에서 자동완성 바가 숨겨지는 기존 정책을 유지한다.
- 숨김 가능한 arranged subview의 nonzero 크기 제약이 UIKit required 숨김 제약과
  경쟁하지 않는다.
- 키보드 높이, 영문 특수 키 비율과 입력 동작이 유지된다.
- 관련 테스트와 두 키보드 extension 빌드가 통과한다.
