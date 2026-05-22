# Suggestion Bar Undo Redo Tasks

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
- [x] undo debounce 간격을 0.8초로 조정한다.
- [x] 스페이스 입력 시 pending undo group을 즉시 확정한다.
- [x] 엔터 입력 시 pending undo group을 즉시 확정한다.
- [x] 단일 백스페이스 시작 시 기존 pending undo group을 확정한다.
- [x] 입력↔삭제 전환 시 기존 pending undo group을 확정하고 새 group을 시작한다.
- [x] 입력↔삭제 전환 테스트를 먼저 실패시킨 뒤 통과를 확인한다.
- [x] 한글 백스페이스 시작 시 조합 지연 여부와 관계없이 기존 undo group을 확정한다.
- [x] `안녕핫 -> 백스페이스 -> 안녕하 -> undo`가 삭제만 되돌리는 기록 단위 테스트를 추가한다.
- [x] undo/redo 적용 뒤 한글 조합 버퍼와 processor 상태를 초기화한다.
- [x] 접근성 label/traits 코드는 현재 범위에서 의도적으로 제외된 상태로 문서화한다.
- [x] 전체 `SYKeyboard` 테스트 통과를 확인한다.
- [x] 한글 키보드 extension 빌드를 확인한다.
- [x] 영문 키보드 extension 빌드를 확인한다.
- [x] 작업 문서에 최신 undo group 규칙과 검증 결과를 반영한다.
- [x] 실제 입력 앱에서 자동완성 바 undo/redo 버튼 표시, 활성화, 버튼 폭을 수동 확인한다.
- [x] 실제 한글 키보드에서 `안녕핫 -> 백스페이스 -> 안녕하 -> undo -> 안녕핫`을 수동 확인한다.
- [x] 실제 한글 키보드에서 undo/redo 후 새 입력이 이전 조합과 섞이지 않는지 수동 확인한다.
- [x] 기능 추가 이후 `BaseKeyboardViewController` 큰 리팩토링 범위를 다시 확정한다.
- [x] 리팩토링 시 undo/redo 세션 상태, 텍스트 프록시 wrapper, suggestion 연동을 어떤 단위로 분리할지 결정한다.
- [x] 리팩토링 시 접근성 label/traits 코드를 별도 요청 없이 재추가하지 않는다.
- [x] `KeyboardUndoRedoSession` 타입을 추가해 undo/redo debounce, deferred commit, text context change 감지를 분리한다.
- [x] `BaseKeyboardViewController`의 undo/redo 프로퍼티와 private helper를 새 세션 타입 호출로 교체한다.
- [x] undo/redo 적용 순서와 한글 조합 reset hook 호출 순서가 리팩토링 전과 동일한지 코드 diff로 확인한다.
- [x] 리팩토링 후 targeted undo/redo 테스트를 실행한다.
- [x] 리팩토링 후 `SYKeyboardCore` 빌드를 실행한다.
- [x] 리팩토링 후 전체 `SYKeyboard` 테스트를 실행한다.
- [x] 리팩토링 결과와 검증 결과를 작업 문서에 기록한다.
- [x] 다음 단계로 `SuggestionBarDelegate`의 suggestion 선택 흐름을 동작 변경 없이 작은 private 메서드로 분리한다.
- [x] suggestion 선택 흐름 분리 후 `SYKeyboardCore` 빌드를 실행한다.
- [x] suggestion 선택 흐름 분리 후 전체 `SYKeyboard` 테스트를 실행한다.
- [x] suggestion 선택 흐름 분리 결과와 검증 결과를 작업 문서에 기록한다.
- [ ] 다음 단계로 버튼 action binding 또는 gesture delegate 분리 범위를 확정한다.
