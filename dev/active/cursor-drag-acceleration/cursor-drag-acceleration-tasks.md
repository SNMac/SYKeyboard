# Cursor Drag Acceleration Tasks

Last Updated: 2026-06-05

## Checklist

- [x] Issue #49 원문을 확인한다.
- [x] `dev/README.md`, `dev/templates/`, `dev/codex-skill-playbook.md`의 관련 지침을 확인한다.
- [x] 좌우 드래그 커서 이동 관련 기존 구현 위치를 확인한다.
- [x] 현재 이동량 산정 기준이 거리 기반 `cursorMoveInterval`인지 정리한다.
- [x] 가속도 수치와 삭제 버튼 적용 범위의 미확정 지점을 문서화한다.
- [x] `cursorMoveInterval`은 느린 드래그의 1칸 이동 기준 간격으로 유지한다는 사용자 의도를 반영한다.
- [x] 빠른 드래그 보정 방식을 곱셈형(`baseTicks * multiplier`) 또는 덧셈형(`baseTicks + boost`) 중 하나로 확정한다.
- [x] 최대 step, 속도 threshold, 가속도 threshold 초깃값을 확정한다.
- [x] 삭제 버튼 drag에도 step 가속을 적용할지 확정한다.
- [x] step 계산을 담당하는 순수 policy 타입을 추가한다.
- [x] 느린 드래그는 `cursorMoveInterval`마다 `step = 1`이 되는 단위 테스트를 추가한다.
- [x] 한 update에서 여러 `cursorMoveInterval`이 누적되면 `baseTicks`가 2 이상이 되는 단위 테스트를 추가한다.
- [x] 빠른 드래그 또는 가속 구간은 `step > 1`이 되는 단위 테스트를 추가한다.
- [x] 최대 step clamp 테스트를 추가한다.
- [x] 방향 전환 중 interval 미만 이동에서는 step이 생성되지 않는 테스트를 추가한다.
- [x] `TextInteractionGestureController`가 policy 결과를 사용해 delegate에 step을 전달하도록 변경한다.
- [x] `BaseKeyboardViewController`에서 primary cursor 이동을 `steps`만큼 적용하되 입력 버퍼 초기화 정책을 유지한다.
- [x] 삭제 버튼은 step 가속을 적용하지 않고 기존 delete pan 삭제/복구 회귀 테스트로 확인한다.
- [x] `HangeulDeleteButtonDragControllerTests`를 실행해 삭제/복구 회귀를 확인한다.
- [x] `KeyboardUndoRedoManagerTests`를 실행해 cursor context/anchor 회귀를 확인한다.
- [x] 변경 범위에 맞춰 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행한다.
- [x] `HangeulKeyboard` scheme 빌드를 실행한다.
- [x] `EnglishKeyboard` scheme 빌드를 실행한다.
- [x] 실기기 테스트에서 보고된 첫 이동 4칸 튐 증상의 원인을 확인한다.
- [x] cursor 활성화 첫 이동은 활성화 누적 거리를 가속 step으로 쓰지 않는 회귀 테스트를 추가한다.
- [x] cursor 활성화 첫 이벤트를 최대 1칸 이동으로 분리하고 이후 기준점을 현재 위치로 재설정한다.
- [x] 회귀 수정 후 `xcodebuild test`를 재실행한다.
- [x] `QuartzCore`/`CACurrentMediaTime()` 직접 속도 계산을 UIKit `UIPanGestureRecognizer.velocity(in:)` 기반으로 변경한다.
- [x] velocity 기반 policy API 변경을 RED/GREEN으로 확인한다.
- [x] AGENTS.md에 Foundation/UIKit/SwiftUI 표준 API 우선 사용 원칙을 추가한다.
- [x] 사용자 설정 범위를 반영해 threshold를 `900/1600/900`으로 재조정한다.
- [x] 첫 velocity 샘플에는 가속 증가 보정을 적용하지 않는 테스트를 추가한다.
- [x] threshold 조정 후 `xcodebuild test`, 한글/영문 키보드 scheme 빌드를 재실행한다.
- [ ] 실제 입력 앱에서 한글/영문 느린 드래그, 빠른 드래그, 경계 이동, 조합 중 이동을 수동 확인한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [x] 구현 결과와 검증 결과를 최종 응답에 요약한다.
