# Task 1 반복 삭제 mutation 확인 상태 모델 보고서

## 상태

- 완료 범위: `RepeatDeleteRequest` 순수 상태 모델과 회귀 테스트
- 작업 기준 커밋: `a4cc301`
- 작업 브랜치: `bug/#102-cursor-drag-newline-boundary`
- Task 2 controller 통합은 포함하지 않았다.

## Step별 결과와 커밋

| Step | 결과 | 커밋 |
|---|---|---|
| 1 | 일반 문자, 메시지 앱 동일 앞 문맥, 빈 앞 문맥의 직전 줄 노출, 권위 조합 치환을 검증하는 4개 회귀 테스트를 추가했다. | `9e5a9ad test: #102 - 반복 삭제 실제 mutation 회귀 테스트` |
| 2 | iPhone 13 mini / iOS 16.0 집중 테스트에서 새 상태 모델 타입이 없어 의도한 RED 컴파일 실패를 확인했다. | `0ff2048 docs: #102 - 반복 삭제 mutation RED 검증` |
| 3 | proxy 문맥과 권위 mutation을 구분하고 callback 문맥으로 일반 문자 또는 줄바꿈을 확정하는 최소 상태 모델을 추가했다. | `524c87b fix: #102 - 반복 삭제 mutation 확인 상태 추가` |
| 4 | 기존 성공/무효 단일 완료 lifecycle 테스트를 새 요청 모델로 이전했다. | `1d03bc6 test: #102 - 반복 삭제 lifecycle 회귀 테스트 이전` |
| 5 | 집중 테스트 GREEN에서 15개 통과, 실패 0건을 확인했다. | `8d63e8d docs: #102 - 반복 삭제 mutation GREEN 검증` |
| 6 | 공백 오류와 변경 범위를 검토하고 `RepeatDeleteBoundaryRequest` 보존을 확인했다. | `docs: #102 - 반복 삭제 mutation Task 1 검토` |

## TDD 검증

### RED

XcodeBuildMCP `test_sim`으로 아래 집중 테스트를 iPhone 13 mini / iOS 16.0에서 실행했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

결과는 실패였고, `RepeatDeleteRequest`와 `RepeatDeleteMutationDraft`를 찾지 못하는 오류 및 `.proxyContext`/`.authoritative` 문맥 추론 오류를 포함한 16개 컴파일 오류였다. 새 테스트가 기존 코드가 아닌 신규 모델을 요구함을 확인했다.

### GREEN

같은 명령을 다시 실행해 15개 통과, 실패 0건, skip 0건을 확인했다.

중간 GREEN 시도에서 Swift Testing `#expect` 매크로가 mutating `capture` 호출을 immutable expression으로 평가해 5개 컴파일 오류가 발생했다. `capture`의 반환값을 지역 변수에 저장한 뒤 `#expect`로 검증하도록 테스트만 보정했고, Step 4 커밋을 amend했다. 상태 모델의 동작 변경은 없었다.

## 변경 파일

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardTextInteractionPolicy.swift`
- `SYKeyboardTests/Utils/KeyboardTextInteractionPolicyTests.swift`
- `docs/superpowers/plans/2026-07-24-repeat-delete-confirmed-undo.md`
- `.superpowers/sdd/task-1-confirmed-undo-report.md`

## 자체 검토

- `RepeatDeleteRequest`는 요청 문맥과 draft만 관리하며 controller나 undo session을 직접 변경하지 않는다.
- callback의 뒤 문맥이 요청 시점과 같은 경우에만 확정한다.
- 권위 draft는 원형을 유지하고, proxy draft는 일반 삭제 문맥 또는 메시지 앱 줄 경계 문맥을 확인한 뒤에만 확정한다.
- 완료 또는 취소 시 요청 문맥과 draft를 모두 소비한다.
- 기존 `RepeatDeleteBoundaryRequest`는 Task 2까지 유지했다.
- `git diff HEAD~5..HEAD --check`는 출력 없이 통과했고, Task 1의 코드·테스트·계획 문서만 변경됐다.

## 남은 사항 및 우려

- Task 1은 순수 상태 모델만 제공한다. controller의 `begin → capture → textDidChange` 통합과 실제 undo 기록은 Task 2 범위다.
- 전체 테스트, 키보드 extension 빌드, 메시지 앱의 수동 반복 삭제 검증은 Task 3 범위이므로 이번 Task 1에서는 수행하지 않았다.
