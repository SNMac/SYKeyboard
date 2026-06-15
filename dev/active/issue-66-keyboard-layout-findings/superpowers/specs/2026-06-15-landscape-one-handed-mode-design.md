# Landscape One-Handed Mode Design

Last Updated: 2026-06-15

## Goal

가로 화면에서는 한 손 키보드 모드를 일시적으로 중앙 모드처럼 표시하고, 세로 화면으로 복귀하면 사용자가 저장한 왼쪽/오른쪽 모드를 자동 복원한다.

## Behavior Contract

- `UserDefaultsManager.lastOneHandedMode`와 preview의 `previewOneHandedMode`는 화면 회전으로 변경하지 않는다.
- 세로 화면에서는 저장된 한 손 모드를 표시한다.
- 가로 화면에서는 저장된 모드와 관계없이 `.center`를 표시한다.
- 가로 화면에서는 좌우 chevron을 숨기고 한 손 모드 너비 제약을 적용하지 않는다.
- 가로 화면에서는 한 손 모드 선택 pan/long press 제스처를 무시한다.
- 가로 전환 중 표시 중이던 한 손 모드 선택 overlay를 닫는다.
- 세로 화면으로 복귀하면 별도 저장 작업 없이 기존 저장 모드를 다시 표시한다.
- 실제 키보드와 앱 preview에 동일한 표시 정책을 적용한다.

## Architecture

`KeyboardPresentationStatePolicy`에 저장 모드와 화면 방향을 받아 실제 표시 모드를 반환하는 순수 정책을 추가한다. `BaseKeyboardViewController`는 현재 화면 방향을 세션 상태로 보관하고, chevron 표시와 `KeyboardView` 너비 갱신에는 저장 모드가 아니라 정책이 반환한 표시 모드를 전달한다.

저장 모드 변경은 기존 `currentOneHandedMode` setter만 담당한다. 회전은 표시 상태만 갱신하므로 UserDefaults와 preview 바인딩에 영향을 주지 않는다.

## Components

### Presentation Policy

- 입력: 저장된 `OneHandedMode`, `isPortrait`
- 출력: 세로에서는 저장 모드, 가로에서는 `.center`
- 제스처 허용 여부는 `isPortrait`로 판단한다.

### BaseKeyboardViewController

- `isPortraitLayout` 상태를 보관한다.
- 최초 표시와 `viewWillTransition(to:with:)`에서 방향 상태를 갱신한다.
- `updateOneHandModekeyboard()`는 표시 모드를 기준으로 chevron과 `KeyboardView`를 갱신한다.
- 가로 전환 시 현재 키보드 레이아웃들의 한 손 모드 overlay를 숨긴다.
- 가로에서는 한 손 모드 pan/long press handler를 조기에 종료한다.

### KeyboardView

- 컨트롤러가 전달한 표시 모드가 `.center`이므로 가로에서 한 손 모드 관련 너비 제약을 모두 비활성화한다.
- 화면 방향을 직접 해석하지 않고 표시 모드만 따른다.

## Testing

- 저장 모드가 `.left` 또는 `.right`일 때 세로 표시 모드가 유지되는지 검증한다.
- 저장 모드가 한 손 모드여도 가로 표시 모드는 `.center`인지 검증한다.
- 가로 후 세로 정책 계산에서 원래 저장 모드가 복원되는지 검증한다.
- 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드를 실행한다.
- 실제 키보드와 preview에서 가로 회전 시 중앙 표시, chevron 숨김, 제스처 무시, 세로 복귀 복원을 수동 확인한다.

## Risks

- 회전 시 저장 모드 자체를 `.center`로 변경하면 세로 복귀 복원이 불가능해진다.
- preview는 실제 extension과 lifecycle 호출 순서가 다를 수 있으므로 최초 방향 갱신과 회전 갱신을 모두 연결해야 한다.
- 진행 중인 제스처 overlay를 가로 전환 시 닫지 않으면 중앙 표시 위에 overlay가 남을 수 있다.
