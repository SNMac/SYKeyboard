# Return Button Undo Redo Tasks

Last Updated: 2026-05-22

## Checklist

- [x] `dev/README.md`와 `dev/templates/` 구조를 확인한다.
- [x] 브랜치명, `BaseKeyboardViewController.swift` 길이, 리턴 버튼 현재 처리 경로를 확인한다.
- [x] 작업 문서 3종을 `dev/active/return-button-undo-redo/`에 작성한다.
- [x] 리턴 버튼 일반 입력을 전용 메서드로 분리한다.
- [x] 리턴 버튼 반복 입력을 전용 메서드로 분리한다.
- [x] 선행 리팩토링이 동작 변경을 만들지 않았는지 빌드로 확인한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [x] 다음 단계인 undo/redo 기능 추가 범위를 문서에 갱신한다.
- [x] `KeyboardUndoRedoManagerTests`를 먼저 추가하고 실패를 확인한다.
- [x] `KeyboardUndoRedoManager`를 구현하고 targeted 테스트 통과를 확인한다.
- [x] 리턴 버튼 pan undo/redo 설계를 제거한다.
- [x] 자동완성 바 우측에 undo/redo 버튼을 추가한다.
- [x] undo/redo 버튼을 `UIButton`이 아닌 후보 텍스트와 동일한 `UIView` 기반 터치 처리로 변경한다.
- [x] `isPredictiveTextEnabled && isUndoRedoEnabled` 조건에서만 undo/redo 기록과 실행을 허용한다.
- [x] undo/redo 기록을 debounce pending 그룹으로 묶도록 변경한다.
- [x] 한글 조합 중에는 천지인/나랏글/두벌식 모두 undo stack 확정을 지연한다.
- [x] cursor 이동만으로 undo/redo history를 초기화하지 않도록 text context 변경 감지를 완화한다.
- [x] cursor 이동 후 undo/redo 실행 시 저장된 context anchor로 편집 위치 복원을 시도한다.
- [x] 전체 `SYKeyboard` 테스트 통과를 확인한다.
- [x] 한글 키보드 extension 빌드를 확인한다.
- [x] 영문 키보드 extension 빌드를 확인한다.
- [ ] 실제 입력 앱에서 자동완성 바 undo/redo 버튼 표시, 활성화, 버튼 폭을 수동 확인한다.
- [ ] 기능 추가 이후 `BaseKeyboardViewController` 큰 리팩토링 범위를 다시 확정한다.
