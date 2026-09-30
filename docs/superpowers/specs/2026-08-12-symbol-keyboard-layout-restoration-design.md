# UIKeyboardType별 기호 키보드 레이아웃 복원 설계

## 목적

GitHub Issue #108에 따라 커밋 `7bdf59fd`에서 하나로 통합된 기호 키보드를
기본·URL·이메일·웹 검색 입력 환경별 레이아웃으로 복원한다.

통합 커밋 전체를 revert하지 않는다. 해당 커밋 이후 추가된 Smart Punctuation,
닫는 따옴표, 한 손 키보드 오버레이와 Auto Layout 충돌 방지 변경을 유지하면서
제거된 모드·키 배열·하단 행·`UIKeyboardType` 연결만 현재 코드에 맞게 복원한다.

## 확인한 기준

- 통합 커밋: `7bdf59fd` (`fix: #41 - 기호 키보드 단일화`)
- 복원 기준 커밋: `7bdf59fd^`
- 현재 작업 기준: `develop`의 `64d6eba4` 이후
- 작업 브랜치: `feat/#108-uikeyboardtype-rollback`
- UIKit 문서:
  - 커스텀 키보드는 `textDocumentProxy.keyboardType`으로 입력 환경을 확인한다.
  - `.URL`은 마침표, 슬래시, `.com` 접근을 강조한다.
  - `.webSearch`는 공백과 마침표 접근을 강조한다.

## 선택한 방식

### 하나의 모드 값으로 키 배열과 하단 행 전환

`SymbolKeyboardMode`를 다시 추가하고 다음 네 모드를 표현한다.

- `.default`
- `.URL`
- `.emailAddress`
- `.webSearch`

모드는 두 가지 책임만 갖는다.

1. `UIKeyboardType?`을 기호 키보드 모드로 매핑한다.
2. 해당 모드의 일반·Shift 키 배열을 제공한다.

`SymbolKeyboardView`는 기존처럼 하나의 뷰 인스턴스를 유지한다. 모드가 바뀌면
기존 버튼의 `TextInteractableType`과 하단 arranged subview의 `isHidden`만
업데이트한다. 입력 이벤트 등록과 버튼 객체 수명은 바꾸지 않는다.

### UIKeyboardType 매핑

| `UIKeyboardType` | `SymbolKeyboardMode` |
|---|---|
| `.URL` | `.URL` |
| `.emailAddress` | `.emailAddress` |
| `.webSearch` | `.webSearch` |
| 그 외 및 `nil` | `.default` |

한글·영문 ViewController는 이 공통 매핑 결과를 각각의
`symbolKeyboardView.currentSymbolKeyboardMode`에 설정한다. 숫자·전화·십진 입력
환경은 실제 표시 키보드가 TenKey여도 기호 모드는 `.default`로 초기화해 다음 입력
대상 전환에 이전 URL/이메일 상태가 남지 않게 한다.

### 키 배열

기본 및 웹 검색 모드는 통합 전 기본 배열을 사용한다. 단, 통합 이후 수정된
닫는 큰따옴표 `”`와 닫는 작은따옴표 `’`를 유지한다.

URL과 이메일 모드는 `7bdf59fd^`의 전용 일반·Shift 배열을 복원한다. 빈 키 위치도
버튼 개수를 바꾸지 않고 빈 primary key 배열로 유지해 기존 행 정렬과 Shift 전환
방식을 보존한다.

### 하단 행

기호 키보드의 가운데 영역을 `spaceButtonHStackView`로 다시 묶고
`spaceButton`, `atButton`, `periodButton`, `slashButton`, `dotComButton`을
arranged subview로 유지한다.

| 모드 | 표시 버튼 |
|---|---|
| `.default` | 스페이스 |
| `.URL` | `.`, `/`, `.com` |
| `.emailAddress` | 스페이스, `@`, `.` |
| `.webSearch` | 스페이스, `.` |

모드 전환 시 Shift 상태는 일반 상태로 초기화한다. 숨김 가능한 하단 버튼의
nonzero 너비 제약은 현재 `StandardKeyboardView`와 같은 priority `999`를 사용해
UIKit의 required 숨김 제약과 경쟁하지 않게 한다.

## 고려한 대안

### `git revert 7bdf59fd`

통합 이후의 프로토콜 이름 변경, 닫는 따옴표, Smart Punctuation, 오버레이와
Auto Layout 수정까지 되돌리거나 충돌시킬 수 있어 채택하지 않는다.

### 모드별 `SymbolKeyboardView` 인스턴스 생성

각 모드의 UI는 분리되지만 버튼 action·gesture·overlay 등록이 중복되고 키보드
확장 메모리가 늘어난다. 기존 단일 인스턴스 전환 구조로 충분하므로 채택하지
않는다.

### ViewController마다 직접 모드 매핑

통합 전 구현과 가장 가깝지만 한글·영문에 같은 switch가 중복된다. 매핑 누락을
한 곳에서 방지하고 직접 테스트할 수 있도록 `SymbolKeyboardMode`가 매핑을
소유한다.

## 변경 범위

- `Modules/SYKeyboardCore/Presentation/Utils/Enums/KeyboardMode/SymbolKeyboardMode.swift`
  - 모드, `UIKeyboardType` 매핑, 키 배열 복원
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/SymbolKeyboardLayoutProvider.swift`
  - 모드 전환과 하단 행 계약 복원
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/SymbolKeyboardView.swift`
  - 모드별 키·하단 행 전환 복원
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
  - 한글 키보드의 기호 모드 연결
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
  - 영문 키보드의 기호 모드 연결
- `SYKeyboard.xcodeproj/project.pbxproj`
  - 동기화 그룹의 target membership exception에 새 파일 반영
- `SYKeyboardTests/Utils/KeyboardSymbolInputPolicyTests.swift`
  - 모드 매핑, 키 배열 반영, 하단 행 전환, 따옴표 회귀 검증

한글 Processor/Automata, 입력 buffer, suggestion 엔진, UserDefaults, 앱 설정,
Firebase/AdMob 설정은 변경하지 않는다.

## 검증

- TDD RED 단계에서 `SymbolKeyboardMode`와 모드 전환 API가 없어 테스트가
  컴파일되지 않는 것을 확인한다.
- GREEN 단계에서 `KeyboardSymbolInputPolicyTests`를 실행한다.
- `SYKeyboard` 전체 테스트를 iPhone 13 mini / iOS 16.0에서 실행한다.
- `HangeulKeyboard`, `EnglishKeyboard`, `SYKeyboard` scheme을 같은 destination에서
  빌드한다.
- 실제 입력 앱에서 기본·URL·이메일·웹 검색 필드의 일반/Shift 배열과 하단 행을
  확인한다. 실제 관찰을 수행하지 못하면 자동 테스트가 이를 대체했다고
  표현하지 않는다.

## 완료 기준

- 기본·URL·이메일·웹 검색 입력 환경에서 지정된 기호 배열과 하단 행이 표시된다.
- 한글·영문 키보드가 동일한 `UIKeyboardType` 매핑을 사용한다.
- 모드 전환 시 Shift 상태와 표시 키가 새 모드의 일반 상태로 초기화된다.
- Smart Punctuation과 닫는 따옴표 동작이 유지된다.
- 현재 한 손 키보드 오버레이와 숨김 제약 충돌 방지 변경이 유지된다.
- 관련 테스트와 전체 테스트, 세 scheme 빌드 결과가 기록된다.
