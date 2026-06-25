# Hangeul Controller Domain Test Stabilization Tasks

Last Updated: 2026-06-26

## Checklist

- [x] Issue #91 본문과 체크리스트를 확인한다.
- [x] 작업 전 `git status --short`로 워크트리 상태를 확인한다.
- [x] `dev/README.md`와 `dev/templates/` 문서 규칙을 확인한다.
- [x] `dev/codex-skill-playbook.md`의 `docs-and-infrastructure` 섹션을 확인한다.
- [x] 관련 한글 controller/state/simulator 파일을 읽고 이슈 방향의 타당성을 판단한다.
- [x] suggestion/undo 관련 domain/policy 테스트 파일을 읽고 보강 범위를 판단한다.
- [x] `dev/active/hangeul-controller-domain-test-stabilization/` 작업 문서 3종을 만든다.
- [x] 수정 전 한글 controller/simulator 관련 baseline 테스트를 실행한다.
- [x] `HangeulCompositionStateTests`에 삭제 touchDown 후 첫 pan restore 정책 회귀 테스트를 추가한다.
- [x] `HangeulKeyboardCoreViewController`의 삭제 touchDown/pan/restore 상태 관리 중 `HangeulCompositionState`로 옮길 수 있는 부분을 정리한다.
- [x] `KeyboardControllerSimulator`가 controller의 두 번째 구현체처럼 커지지 않도록 역할을 확인한다.
- [x] `SuggestionControllerTextReplacementTests`에 기존 테스트와 중복되지 않는 text replacement 경계 테스트를 추가한다.
- [x] `SuggestionControllerPreparationTests`에 기존 테스트와 중복되지 않는 suggestion 준비/갱신 경계 테스트를 추가한다.
- [x] `KeyboardSuggestionSelectionPolicyTests`에 suggestion 선택/갱신 경계 테스트를 추가한다.
- [x] `KeyboardUndoRedoManagerTests`에 적용 중 기록 방지 테스트를 보강한다.
- [x] targeted 테스트를 통과시킨다.
- [x] 전체 `SYKeyboard` 테스트를 실행한다.
- [ ] `HangeulKeyboard` scheme 빌드를 확인한다. 샌드박스 CoreSimulator 실패, 권한 있는 재실행은 Crashlytics 외부 전송 가능성으로 자동 승인 거절.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [ ] 완료 내용과 검증 결과를 최종 응답에 요약한다.

## Baseline Commands

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

## Post-Change Commands

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 통과. `** TEST SUCCEEDED **`

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 샌드박스에서 `CoreSimulatorService connection became invalid`로 실패. 권한 있는 실행은 Crashlytics dSYM/build metadata 외부 전송 가능성 때문에 자동 승인 거절됨.
