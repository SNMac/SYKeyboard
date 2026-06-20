# Issue 64 Cheonjiin Delete Tests Context

Last Updated: 2026-06-14

## Relevant Files

- `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`
- `SYKeyboardTests/Utils/HangeulProcessorTestable.swift`
- `Modules/HangeulKeyboardCore/Domain/Processor/CheonjiinProcessor.swift`
- `dev/active/code-review-scope/code-review-scope-findings.md`

## Facts Checked

- GitHub issue #64는 천지인 전체 문자 테스트의 삭제 경로 누락을 다룬다.
- 현재 heavy test 이름은 생성 및 삭제 검증이지만 실제 구현은 생성만 검증한다.
- `CheonjiinProcessor.delete(...)`는 composing에 비표준 모음이 있으면 마지막 문자를 직접 제거한다.
- committed 끝이 비표준 모음일 때 복원하는 경로는 `consumedCommittedCount`와 `isProtected`에 의존한다.
- 완성형 11,172자 생성 결과에는 `ㆍ`, `ᆢ`가 남지 않으므로 별도 매트릭스가 필요하다.
- 작업 시작 시 `git status --short --untracked-files=all`는 비어 있었다.

## Decisions

- production 코드는 수정하지 않는다.
- 전체 문자 삭제는 천지인 입력 키 개수가 아니라 완성형 글자의 중성·종성 구조 기반 예상 삭제 횟수를 사용한다.
- 천지인 고유 삭제 경로는 Processor 직접 호출 매트릭스로 검증한다.

## Verification Notes

- 일반 샌드박스 targeted 테스트는 CoreSimulator/Xcode/SwiftPM 캐시 권한 오류로 실패했다.
- 권한 있는 환경의 천지인 targeted 테스트는 정상 코드에서 `TEST SUCCEEDED`였다.
- 첫 임시 mutation인 `composingContains비표준모음(...) == false`는 테스트가 통과했다. 확인 결과 현재 매트릭스 입력에서는 오토마타도 같은 외부 삭제 결과를 만들므로 분기 사용 여부 자체를 검증하지 않는다.
- 두 번째 임시 mutation인 비표준 모음 삭제 시 `remaining = composing`에서는 `test비표준모음_Composing삭제()` 실패를 확인했다.
- 두 번째 mutation 실행은 테스트 실패 확인 후 xcodebuild 종료 정리에서 멈춰 중단했고, production 코드는 원복했다.
- `git diff -- Modules/HangeulKeyboardCore/Domain/Processor/CheonjiinProcessor.swift` 출력이 비어 production 변경이 남지 않았음을 확인했다.
- production 원복 후 권한 있는 환경에서 천지인 targeted 테스트를 fresh 재실행해 `TEST SUCCEEDED`를 확인했다.
- 권한 있는 환경에서 전체 `SYKeyboard` 테스트를 실행해 `TEST SUCCEEDED`를 확인했다.

## Current Uncommitted State

- `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`
- `dev/active/code-review-scope/code-review-scope-findings.md`
- `dev/active/issue-64-cheonjiin-delete-tests/`

## Next Action

- 구현과 검증이 완료됐다. findings 상태를 `Resolved`로 반영했다.
