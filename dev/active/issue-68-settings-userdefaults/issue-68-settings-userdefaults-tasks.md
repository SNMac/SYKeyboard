# Issue 68 Settings UserDefaults Tasks

Last Updated: 2026-06-18

## Checklist

- [x] GitHub Issue #68 본문과 댓글을 확인한다.
- [x] `dev/README.md`, `dev/templates/`, `dev/codex-skill-playbook.md`, `dev/coding-conventions.md`의 관련 지침을 확인한다.
- [x] P1 자동 대문자 기본값 불일치의 코드 경로를 검증한다.
- [x] P2 키보드 컨트롤러 재사용 시 설정 재반영 누락 경로를 검증한다.
- [x] P2 lifecycle 로그 확인 결과 기존 controller 재사용 전제가 성립하지 않아 Invalid로 판단한다.
- [x] P3 앱 전용 UserDefaults 상태의 모듈 경계와 기본값 계약 불일치 경로를 검증한다.
- [x] 앱 전용 온보딩/리뷰 상태와 키보드 모듈 공유 설정의 UserDefaults manager 경계를 검토한다.
- [x] 각 리뷰 항목의 타당성 판단을 기록한다.
- [x] 수정 계획과 검증 계획을 `dev/active/issue-68-settings-userdefaults/`에 문서화한다.
- [x] P1: `isAutoCapitalizationEnabled` getter를 default-aware fallback으로 수정한다.
- [x] P3: 앱 전용 `AppUserDefaultsManager`, `AppUserDefaultsKeys`, `AppDefaultValues`를 추가한다.
- [x] P3: `ContentView`와 `RequestReviewViewModifier`가 앱 전용 저장소 타입을 사용하도록 수정한다.
- [x] P3: `SYKeyboardCore.UserDefaultsManager/UserDefaultsKeys/DefaultValues`의 앱 전용 extension을 제거하거나 대체한다.
- [x] P3: 기존 key 문자열과 App Group suiteName을 유지해 저장 데이터 위치를 바꾸지 않는다.
- [x] 기본값 계약 테스트를 추가한다. 자동 대문자는 absent key fallback을 검증하고, 앱 전용 값은 컴파일/사용처 검증 범위를 정한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`의 Issue #68 관련 항목 상태를 처리 결과에 맞춰 갱신한다.
- [x] 변경 범위에 맞는 `xcodebuild test`와 keyboard extension build를 실행한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [ ] 완료 내용과 검증 결과를 최종 응답 또는 후속 작업 문서에 요약한다.
