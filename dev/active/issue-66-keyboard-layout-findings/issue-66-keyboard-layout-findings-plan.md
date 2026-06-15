# Issue 66 Keyboard Layout Findings Plan

Last Updated: 2026-06-15

## Goal

- GitHub Issue #66의 Track 3 리뷰 사항 두 건을 현재 코드 기준으로 수정하고, 한 손 키보드 폭과 리턴 키 활성 상태 표시가 preview 및 실제 extension에서 일관되게 동작하도록 검증한다.

## Review Evaluation

### [P2] 한 손 키보드가 설정한 너비보다 확장될 수 있음

- 판단: 사실관계는 맞지만 최종 사용자 의도상 버그가 아니다.
- `keyboardLayoutView`에는 `greaterThanOrEqualToConstant` 너비 제약만 있고, 한 손 모드에서 표시되는 chevron과 함께 `keyboardHStackView`의 전체 폭을 채운다.
- 따라서 설정값 `300...340`은 실제 폭이 아니라 하한값이며, 넓은 화면이나 가로 화면에서 설정값보다 커질 수 있다.
- 최종 결정은 설정값을 최소 폭으로 유지하는 것이다. 중앙 모드에서는 키보드가 전체 폭을 채우고, 한 손 모드에서는 키보드가 설정값 이상을 차지하며 표시된 Chevron과 남은 공간을 나눠 갖는다.

### [P3] 비활성화된 기본 리턴 키 아이콘이 활성 색상으로 남음

- 판단: 타당하다.
- 기본 리턴 이미지는 `.alwaysOriginal`과 `.label` 색상으로 생성되어 `primaryKeyListImageView.tintColor` 변경의 영향을 받지 않는다.
- 이슈의 template rendering 제안은 방향이 맞지만, template 이미지로 바꾸는 것만으로는 활성화 복귀 시 tint 복원을 보장하지 않는다. 활성/강조/비활성 상태에서 이미지 tint를 라벨 색상과 함께 갱신해야 한다.

## Current State

- 두 finding의 코드 수정과 자동 검증을 완료했다.
- `KeyboardView`가 폭과 모드를 중복 저장하지 않고 전달받은 값으로 제약만 갱신하도록 단순화했다.
- Chevron hidden 상태는 `KeyboardView.updateOneHandedMode(_:)`에서 갱신하고, 최소 폭 제약은 항상 활성화하도록 책임을 정리했다.
- 실제 extension에서 `isHidden` 기반 전환은 필수 제약 충돌을 계속 발생시키는 것을 확인했다.
- 기준 커밋 `84a48326c9d492654074c863227b7330f3b2a97a`의 최소 폭 제약과 `isHidden` 기반 Chevron 표시 방식으로 복원했다.
- 시뮬레이터 앱 빌드·실행과 키보드 표시는 확인했지만, 커스텀 키보드 한 손 모드 선택 제스처 자동화가 불가능해 실제 extension의 세로·가로 전환 수동 검증은 남아 있다.
- 관련 파일:
  - `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ReturnButton.swift`
  - `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewHangeulKeyboardViewController.swift`
  - `SYKeyboard/Presentation/Components/PreviewKeyboard/PreviewEnglishKeyboardViewController.swift`
  - `SYKeyboardTests/`
  - `dev/active/code-review-scope/code-review-scope-findings.md`

## Approach

1. 한 손 키보드 폭 계약을 명확히 한다.
   - `keyboardLayoutView.widthAnchor`의 `greaterThanOrEqualToConstant` 최소 폭 제약을 항상 활성화한다.
   - 중앙 모드에서는 두 Chevron을 숨겨 키보드가 전체 폭을 채우게 한다.
   - 한 손 모드에서는 한쪽 Chevron만 표시하고 키보드와 남은 공간을 나눠 갖게 한다.

2. 모드 전환과 폭 갱신 경로를 연결한다.
   - `BaseKeyboardViewController.updateOneHandModekeyboard()`에서 chevron 표시 상태를 갱신한 뒤 `KeyboardView`에 현재 모드를 전달한다.
   - `updateOneHandedWidthForPreview(to:)`는 최소 폭 제약의 상수를 직접 갱신한다.
   - 기존 입력 흐름, 버튼 이벤트, 한 손 모드 선택 동작은 변경하지 않는다.

3. 기본 리턴 키 아이콘을 상태 기반 tint로 전환한다.
   - 기본 리턴 이미지는 template rendering을 사용한다.
   - `ReturnButton`의 configuration update 경로에서 라벨과 이미지 tint를 같은 활성/강조 색상으로 갱신한다.
   - `updateEnabled(false)`는 라벨, 이미지, 배경을 비활성 색상으로 유지한다.
   - `updateEnabled(true)` 후 configuration 갱신으로 활성 색상이 복원되는지 확인한다.

4. 회귀 검증을 추가한다.
   - `ReturnButton`은 기본 리턴 이미지의 template rendering과 비활성화 후 활성 복귀 tint를 검증하는 focused test를 추가한다.
   - 구현 후 findings 문서의 두 항목을 처리 결과와 실제 검증 결과로 갱신한다.

## Risks

- `equalToConstant` 고정 폭과 hidden arranged subview를 함께 사용하면 스택의 전체 폭 제약과 충돌한다.
- 최소 폭 계약에서는 넓은 화면에서 실제 키보드 폭이 설정값보다 커지는 것이 의도된 동작이다.
- template 이미지의 tint를 활성 상태에서 명시적으로 복원하지 않으면 비활성 색상이 남을 수 있다.

## Verification

- 자동 검증:

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

- 수동 검증:
  - 한글/영문 preview에서 설정 폭 `300`, `320`, `340`을 선택하고 세로와 가로 왼쪽/오른쪽 모드의 실제 키보드 폭이 설정값 이상인지 확인한다.
  - 중앙 모드에서 키보드가 전체 가용 폭을 사용하는지 확인한다.
  - portrait/landscape에서 제약 충돌 로그, 잘림, chevron 터치 영역 이상이 없는지 확인한다.
  - 실제 extension의 빈 텍스트 필드에서 기본 리턴 키 아이콘/배경이 비활성 색상인지 확인하고, 텍스트 입력 후 활성 색상으로 복원되는지 확인한다.

## Done Criteria

- Issue #66의 두 리뷰 사항이 코드와 검증 결과에 따라 처리된다.
- 중앙/한 손 모드와 회전 후 키보드 폭 동작이 정의된 계약을 만족한다.
- 기본 리턴 키의 비활성 및 활성 복귀 상태가 일관되게 표시된다.
- 관련 테스트와 한글/영문 extension 빌드가 통과하거나 실행하지 못한 이유가 기록된다.
- `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과가 반영된다.
