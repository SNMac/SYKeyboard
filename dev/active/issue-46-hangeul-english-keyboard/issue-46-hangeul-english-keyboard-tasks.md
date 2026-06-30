# Issue 46 Hangeul English Keyboard Tasks

Last Updated: 2026-07-01

## Checklist

- [x] GitHub issue #46 본문을 확인한다.
- [x] `dev/README.md`, `dev/templates/*`, `dev/codex-skill-playbook.md`, `dev/coding-conventions.md`를 확인한다.
- [x] 현재 `HangeulEnglishKeyboard` target, plist, template VC 상태를 확인한다.
- [x] `BaseKeyboardViewController`, `KeyboardView`, 공통 layout, 한글/영어 Core VC의 재사용 제약을 확인한다.
- [x] 사용자가 정한 한/영 버튼 배치 정책을 계획에 반영한다.
- [x] `dev/active/issue-46-hangeul-english-keyboard/` 작업 문서 3종을 만든다.
- [ ] 구현 시작 전 `xcodebuild -list -project SYKeyboard.xcodeproj`로 scheme 상태를 확인한다.
- [ ] 다중 primary view 지원 설계를 코드에 반영한다.
- [ ] 통합 target이 필요한 한글/영어 Core view와 상태 API의 공개 범위를 최소 조정한다.
- [ ] `LanguageSwitchButton`을 추가한다.
- [ ] `StandardKeyboardView`에 통합 키보드용 한/영 버튼 배치와 `SwitchButton` visible 영역 축소를 적용한다.
- [ ] `FourByFourKeyboardView`에 통합 키보드용 한/영 버튼 배치를 적용한다.
- [ ] `FourByFourPlusKeyboardView`에 통합 키보드용 한/영 버튼 배치를 적용한다.
- [ ] `HangeulEnglishKeyboardViewController`를 실제 통합 키보드 VC로 교체한다.
- [ ] 한글 composing 중 한/영 전환 정책을 구현하고 테스트한다.
- [ ] 자동완성 언어 전환 API를 추가하고 mode 전환에 연결한다.
- [ ] Firebase/Crashlytics/전체 접근 허용 overlay를 기존 extension 패턴과 맞춘다.
- [ ] `SYKeyboard` test scheme을 실행한다.
- [ ] `HangeulKeyboard` build를 실행한다.
- [ ] `EnglishKeyboard` build를 실행한다.
- [ ] `HangeulEnglishKeyboard` build를 실행한다.
- [ ] 실제 입력 앱에서 통합 키보드 한글/영어 입력, 삭제, 스페이스, 리턴, 한/영 전환, globe/next keyboard 전환을 확인한다.
- [ ] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [ ] 완료 내용과 검증 결과를 최종 응답에 요약한다.
