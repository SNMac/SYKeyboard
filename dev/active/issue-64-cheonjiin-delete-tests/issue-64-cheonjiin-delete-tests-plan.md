# Issue 64 Cheonjiin Delete Tests Plan

Last Updated: 2026-06-14

## Goal

- 천지인 Processor의 완성형 한글 삭제와 천지인 고유 비표준 모음 삭제 경로에 대한 회귀 테스트를 보강한다.
- 키보드 앱의 production 동작은 변경하지 않는다.

## Current State

- `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`의 11,172자 heavy test는 생성만 검증한다.
- `ㆍ`, `ᆢ`, `committedTail`, `consumedCommittedCount`, `isProtected` 경로는 전체 완성형 문자 삭제 루프로 검증할 수 없다.

## Approach

1. 완성형 한글의 중성·종성 구조를 기준으로 예상 삭제 횟수를 계산한다.
2. 천지인 11,172자 생성 성공 후 예상 횟수만큼 삭제하여 잔여물이 없는지 검증한다.
3. 천지인 고유 비표준 모음 삭제와 committed 복원 계약은 별도 매트릭스로 검증한다.
4. 임시 production mutation으로 새 테스트가 실제 회귀를 검출하는지 확인한 뒤 mutation을 복구한다.
5. 전체 `SYKeyboard` 테스트 결과를 findings 문서에 반영한다.

## Risks

- 천지인 키 입력 횟수와 삭제 횟수는 일치하지 않는다. 자음 순환 입력 횟수를 삭제 횟수로 사용하지 않는다.
- 완성형 한글 전체 삭제 테스트는 `ㆍ`, `ᆢ`가 남아 있는 중간 상태를 검증하지 못한다.
- `isProtected`는 Processor 단위에서 직접 호출해 계약을 검증하고, production controller 동작은 변경하지 않는다.

## Verification

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/CheonjiinProcessorTests
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

## Done Criteria

- production Swift 파일이 변경되지 않는다.
- 천지인 11,172자 전체 생성 및 삭제 검증이 통과한다.
- 비표준 모음과 committed 복원 삭제 매트릭스가 통과한다.
- findings 문서의 #64 finding이 검증 결과와 함께 `Resolved`로 변경된다.
