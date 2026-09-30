# 단일 삭제 released touchDown 복구 설계

## 목적

수식 결과를 스페이스로 확정한 뒤 단일 삭제를 반복할 때, 이전 삭제의
`textDidChange` 완료 신호가 누락되어도 다음 단일 탭을 소비하지 않고 삭제를
계속한다.

```text
1 1 + 2 =3  --삭제 반복-->  1 1  --다음 삭제 1회-->  1␠
```

길게 눌러 반복 삭제할 때만 복구되는 현재 비대칭을 제거하되, 정상 callback,
selection 삭제, 반복 삭제, 삭제 드래그의 기존 계약은 유지한다.

## Root cause

단일 삭제는 `touchDown`에서 proxy 편집을 실행하고 `touchUp`에서
`DeleteMutationLifecycle.finishTouchDown`으로 결과를 확인한다. release 시점의
`documentContextBeforeInput`이 아직 삭제 전 문맥이면 요청은
`releasedTouchDown`으로 남아 늦은 `textDidChange`를 기다린다.

늦은 callback이 오지 않는 경우에도 실제 proxy 문맥은 이후 갱신될 수 있다.
하지만 다음 단일 탭은 이전 요청을 현재 문맥으로 checkpoint하지 않고
`DeleteInteractionCoordinator`에 enqueue된 뒤 즉시 반환한다. 새 proxy 편집이
없으므로 새 callback도 발생하지 않아 이후 탭이 계속 대기한다.

반복 삭제 시작 경로는 `actionForNextRepeat`에서 현재 문맥으로 이전 요청을
checkpoint하므로 같은 상태에서 복구된다. 이 차이가 “단일 탭은 멈추지만 길게
누르면 지워짐” 증상과 일치한다.

한글 조합 상태와 `inputBuffer`는 직접 원인이 아니다. 수식 결과 뒤 최종 공백은
한글 조합 상태를 비우며, `inputBuffer`가 비어도 `deleteText()`는 proxy 삭제를
항상 실행한다.

## 선택한 방식

다음 단일 `touchDown`을 coordinator에 전달하기 직전에 lifecycle의
`releasedTouchDown` 요청만 현재 proxy 문맥으로 checkpoint한다.

1. 이전 삭제 결과가 정확히 확인되면 기존 `DeleteMutationResolution` 처리
   경로로 undo/redo 기록과 coordinator generation을 완료한다.
2. 이어서 같은 `touchDown`을 새 요청으로 시작하고 proxy 삭제를 정확히 한 번
   실행한다.
3. 이전 삭제가 확인되지 않으면 현재의 enqueue/대기 동작을 유지한다.
4. lifecycle이 `touchDown`, `repeatTick`, `releasedRepeatTick`, `panBoundary`
   상태이면 이 복구 API는 아무 동작도 하지 않는다.

따라서 복구를 유발한 다음 탭은 완료 확인에만 소비되지 않는다.

## 고려한 대안

### release 뒤 비동기 checkpoint 예약

다음 main run loop에서 재확인할 수 있지만 host callback과의 순서에 의존하고,
문맥 갱신이 더 늦으면 동일한 문제가 남는다.

### 미확정 요청 취소 후 새 삭제 강행

진행은 보장하지만 이전 삭제의 undo/redo mutation을 잃거나 동일 탭이 중복
적용될 수 있어 채택하지 않는다.

## 변경 범위

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
  - `releasedTouchDown` 전용 checkpoint API를 추가한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 단일 삭제 시작 직전에 복구 API를 호출하고 기존 resolution 처리 경로를
    재사용한다.
- `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
  - callback 누락 뒤 다음 단일 탭의 이전 요청 완료와 현재 탭 1회 실행을
    검증한다.

`UITextDocumentProxy` mock이나 DEBUG 전용 production API는 추가하지 않는다.
수식 평가, 일반 자동완성, 텍스트 대치, 한글 조합, `inputBuffer`, 반복 삭제,
삭제 드래그 동작은 변경하지 않는다.

## 완료 기준

- `"1 1 "`의 공백 삭제가 release에서 미확정된 뒤 문맥만 `"1 1"`로 갱신되어도
  다음 단일 탭이 이전 mutation을 확정한다.
- 복구를 유발한 같은 탭이 새 단일 삭제 요청을 시작해 정확히 한 번 실행된다.
- 확인되지 않은 이전 요청은 기존처럼 enqueue 상태를 유지한다.
- late `textDidChange`가 뒤늦게 와도 mutation이나 탭이 중복 처리되지 않는다.
- 기존 단일/반복/selection/pan lifecycle 테스트가 통과한다.
- 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드가
  통과한다.
