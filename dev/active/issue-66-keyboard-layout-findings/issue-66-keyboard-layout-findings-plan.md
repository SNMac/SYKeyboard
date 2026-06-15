# Issue 66 Keyboard Layout Findings Plan

Last Updated: 2026-06-15

## Goal

- GitHub Issue #66의 Track 3 리뷰 사항 두 건을 현재 코드 기준으로 수정하고, 한 손 키보드 폭과 리턴 키 활성 상태 표시가 preview 및 실제 extension에서 일관되게 동작하도록 검증한다.

## Review Evaluation

### [P2] 한 손 키보드가 설정한 너비보다 확장될 수 있음

- 판단: 타당하다.
- `keyboardLayoutView`에는 `greaterThanOrEqualToConstant` 너비 제약만 있고, 한 손 모드에서 표시되는 chevron과 함께 `keyboardHStackView`의 전체 폭을 채운다.
- 따라서 설정값 `300...340`은 실제 폭이 아니라 하한값이며, 넓은 화면이나 가로 화면에서 설정값보다 커질 수 있다.
- 이슈의 수정 제안은 방향이 맞지만, `equalToConstant`로 바꾸는 것만으로는 부족하다. 중앙 모드에서는 제약을 비활성화하고, 한 손 모드에서는 가용 폭 clamp와 회전/preview 크기 변경 시 재계산이 필요하다.

### [P3] 비활성화된 기본 리턴 키 아이콘이 활성 색상으로 남음

- 판단: 타당하다.
- 기본 리턴 이미지는 `.alwaysOriginal`과 `.label` 색상으로 생성되어 `primaryKeyListImageView.tintColor` 변경의 영향을 받지 않는다.
- 이슈의 template rendering 제안은 방향이 맞지만, template 이미지로 바꾸는 것만으로는 활성화 복귀 시 tint 복원을 보장하지 않는다. 활성/강조/비활성 상태에서 이미지 tint를 라벨 색상과 함께 갱신해야 한다.

## Current State

- 두 finding의 코드 수정과 자동 검증을 완료했다.
- 현재 booted 시뮬레이터가 없어 preview 및 실제 extension 수동 검증은 남아 있다.
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
   - `KeyboardView`가 설정 폭과 현재 `OneHandedMode`를 보관하도록 한다.
   - 중앙 모드에서는 키보드 레이아웃 고정 폭 제약을 비활성화해 기존처럼 전체 폭을 사용한다.
   - 세로와 가로 왼쪽/오른쪽 모드에서는 `keyboardLayoutView.widthAnchor`의 고정 폭 제약을 활성화한다.
   - 적용 폭은 설정 폭과 `keyboardHStackView`의 가용 폭에서 표시 중인 chevron의 최소 필요 폭을 뺀 값 중 작은 값으로 정한다.
   - `layoutSubviews` 또는 동등한 레이아웃 갱신 경로에서 폭 변화가 있을 때만 상수를 다시 계산해 회전과 preview 크기 변경을 반영한다.

2. 모드 전환과 폭 갱신 경로를 연결한다.
   - `BaseKeyboardViewController.updateOneHandModekeyboard()`에서 chevron 표시 상태를 갱신한 뒤 `KeyboardView`에 현재 모드를 전달한다.
   - `updateOneHandedWidthForPreview(to:)`는 설정 폭을 저장하고, 현재 모드가 한 손 모드일 때 즉시 고정 폭을 다시 계산한다.
   - 기존 입력 흐름, 버튼 이벤트, 한 손 모드 선택 동작은 변경하지 않는다.

3. 기본 리턴 키 아이콘을 상태 기반 tint로 전환한다.
   - 기본 리턴 이미지는 template rendering을 사용한다.
   - `ReturnButton`의 configuration update 경로에서 라벨과 이미지 tint를 같은 활성/강조 색상으로 갱신한다.
   - `updateEnabled(false)`는 라벨, 이미지, 배경을 비활성 색상으로 유지한다.
   - `updateEnabled(true)` 후 configuration 갱신으로 활성 색상이 복원되는지 확인한다.

4. 회귀 검증을 추가한다.
   - 가능하면 폭 clamp 계산을 순수 정책으로 분리해 중앙/한 손 모드, 설정 폭, 작은 가용 폭 케이스를 Swift Testing으로 검증한다.
   - `ReturnButton`은 기본 리턴 이미지의 template rendering과 비활성화 후 활성 복귀 tint를 검증하는 focused test를 추가한다.
   - 구현 후 findings 문서의 두 항목을 처리 결과와 실제 검증 결과로 갱신한다.

## Risks

- 고정 폭 제약을 항상 활성화하면 중앙 모드도 설정 폭으로 축소되는 회귀가 발생한다.
- 작은 가용 폭에서 clamp하지 않으면 chevron과 고정 폭 제약이 충돌하거나 키보드 가장자리가 잘릴 수 있다.
- `layoutSubviews`에서 매번 제약 상수를 변경하면 불필요한 레이아웃 반복이 생길 수 있으므로 실제 값이 달라질 때만 갱신해야 한다.
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
  - 한글/영문 preview에서 설정 폭 `300`, `320`, `340`을 선택하고 세로와 가로 왼쪽/오른쪽 모드의 실제 키보드 폭이 설정값과 일치하는지 확인한다.
  - 중앙 모드에서 키보드가 전체 가용 폭을 사용하는지 확인한다.
  - portrait/landscape 및 설정 폭보다 좁은 가용 폭에서 제약 충돌 로그, 잘림, chevron 터치 영역 이상이 없는지 확인한다.
  - 실제 extension의 빈 텍스트 필드에서 기본 리턴 키 아이콘/배경이 비활성 색상인지 확인하고, 텍스트 입력 후 활성 색상으로 복원되는지 확인한다.

## Done Criteria

- Issue #66의 두 리뷰 사항이 코드와 검증 결과에 따라 처리된다.
- 중앙/한 손 모드와 회전 후 키보드 폭 동작이 정의된 계약을 만족한다.
- 기본 리턴 키의 비활성 및 활성 복귀 상태가 일관되게 표시된다.
- 관련 테스트와 한글/영문 extension 빌드가 통과하거나 실행하지 못한 이유가 기록된다.
- `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과가 반영된다.
