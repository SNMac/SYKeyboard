# Issue 67 Predictive Suggestion Findings Tasks

Last Updated: 2026-06-16

## Checklist

- [x] GitHub Issue #67 본문을 확인한다.
- [x] `dev/README.md`와 작업 문서 템플릿을 확인한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 4 상태를 확인한다.
- [x] `dev/active/snm-40-predictive-loading/` 문서의 관련 open question을 확인한다.
- [x] 관련 코드 경로를 읽고 finding의 전제가 현재 코드와 맞는지 확인한다.
- [x] Issue #67 작업 문서 3종을 생성한다.
- [ ] 텍스트 대치 suffix 오작동을 재현하는 실패 테스트를 추가한다.
- [ ] 텍스트 대치가 현재 단어와 단축어의 정확한 일치만 허용하도록 수정한다.
- [ ] 대치 복구 이력이 다른 위치의 동일 문구를 복구하지 않는 실패 테스트를 추가한다.
- [ ] 대치 직후 삭제 복구는 유지하면서 커서/focus/context 변경 후 복구 이력을 무효화한다.
- [ ] lexicon 로딩 전 첫 텍스트 대치 누락 정책을 테스트 가능한 단위로 확정한다.
- [ ] 확정한 정책에 따라 lexicon 준비/재평가 경로를 수정한다.
- [ ] n-gram background load/save/reset race를 재현하는 테스트를 추가한다.
- [ ] n-gram load/save/reset 세대 관리 또는 직렬화 로직을 구현한다.
- [ ] n-gram 로딩 전 `addWord(_:)`/`endSentence()` 보존 테스트를 추가한다.
- [ ] n-gram 로딩 전 입력 queue를 구현하고 reset 시 폐기되도록 한다.
- [ ] 커서 이동 후 제안이 초기 상태로 돌아가는 동작을 재현하는 테스트를 추가한다.
- [ ] `textDidChange(_:)` 이후 커서 앞 문맥의 마지막 단어를 기준으로 자동완성 제안을 갱신한다.
- [ ] 문서 컨텍스트 기반 제안 선택 시 replace/delete count가 안전한지 테스트한다.
- [ ] 커서 이동 후 selected text가 있는 경우 이전 후보가 남지 않는지 테스트한다.
- [ ] focused 테스트를 실행한다.
- [ ] 전체 `SYKeyboard` 테스트를 실행한다.
- [ ] `HangeulKeyboard`와 `EnglishKeyboard` extension 빌드를 실행한다.
- [ ] `dev/active/code-review-scope/code-review-scope-findings.md`와 이 작업 문서에 처리/검증 결과를 반영한다.
- [ ] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [ ] 완료 내용과 검증 결과를 최종 응답에 요약한다.
