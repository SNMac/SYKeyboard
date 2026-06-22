# Issue 84 Cursor Drag Selection Tasks

Last Updated: 2026-06-20

## Checklist

- [x] Issue #84 원문을 확인한다.
- [x] `dev/README.md`, `dev/templates/`, `dev/codex-skill-playbook.md`의 관련 지침을 확인한다.
- [x] 현재 cursor drag gesture와 cursor 이동 적용 위치를 확인한다.
- [x] selection 상태 동기화와 관련된 `textWillChange(_:)`, `textDidChange(_:)`, `selectionWillChange(_:)`, `selectionDidChange(_:)` 위치를 확인한다.
- [x] 작업 문서 3종을 `dev/active/issue-84-cursor-drag-selection/` 아래에 만든다.
- [x] `setMarkedText(_:selectedRange:)` spike 범위를 작게 정하고 실험용 정책 코드를 준비한다.
- [ ] 실제 입력 앱에서 marked text 선택 표시가 가능한지 확인한다.
- [ ] `unmarkText()` 이후 선택 범위가 남는지, 커밋되는지, 선택이 해제되는지 기록한다.
- [ ] selection mode 중 `selectedText`, `documentContextBeforeInput`, `documentContextAfterInput` 반영 타이밍을 기록한다.
- [ ] spike 결과를 `issue-84-cursor-drag-selection-context.md`에 업데이트한다.
- [x] selection mode 상태 모델을 설계한다.
- [x] 기본 iPhone 방식 selection range 정책 테스트를 추가한다.
- [x] 내부 anchor 기반 selection range 정책 테스트를 추가한다.
- [x] selection 정책 타입을 구현한다.
- [x] `TextInteractionGestureController`에서 pan 중 두 번째 터치 감지 테스트를 추가한다.
- [x] `TextInteractionGestureController`에서 selection mode 진입 callback 분기를 구현한다.
- [ ] 종료/취소/실패 시 cursor active와 selection mode 상태가 정리되는 테스트를 추가한다.
- [x] `BaseKeyboardViewController`에서 selection mode 진입 전 input buffer 정리 흐름을 안전한 placeholder로 구현한다.
- [ ] selection mode 중 `textWillChange(_:)`/`textDidChange(_:)`가 들어올 때 내부 상태가 충돌하지 않는지 테스트 또는 수동 검증 항목을 추가한다.
- [x] 기본 정책에서 왼쪽 선택 시작 후 오른쪽으로 방향 전환해도 기존 선택 범위가 줄어들지 않는 테스트를 추가한다.
- [x] 기본 정책에서 오른쪽 선택 시작 후 왼쪽으로 방향 전환해도 기존 선택 범위가 줄어들지 않는 테스트를 추가한다.
- [x] 내부 anchor 정책에서 시작점으로 되돌아올 때 선택 범위가 줄어드는 테스트를 추가한다.
- [x] 내부 anchor 정책에서 시작점을 넘어가면 반대 방향 선택으로 전환되는 테스트를 추가한다.
- [ ] 두벌식 조합 중 selection mode 진입 회귀 테스트를 추가하거나 기존 controller 테스트로 확인한다.
- [ ] 나랏글 조합 중 selection mode 진입 회귀 테스트를 추가하거나 기존 controller 테스트로 확인한다.
- [ ] 천지인 조합 중 selection mode 진입 회귀 테스트를 추가하거나 기존 controller 테스트로 확인한다.
- [ ] undo/redo control, return button, 자동완성 후보 갱신이 selection mode 종료 후 올바른지 확인한다.
- [x] `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행한다.
- [x] `xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행한다.
- [x] `xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행한다.
- [ ] 실제 입력 앱에서 한글/영문 커서 드래그, 두 번째 터치, 방향 전환, 손가락 해제 후 선택 상태를 수동 확인한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [x] 구현 결과와 검증 결과를 작업 문서와 최종 응답에 요약한다.
