# Issue 66 Keyboard Layout Findings Tasks

Last Updated: 2026-06-15

## Checklist

- [x] GitHub Issue #66 본문과 댓글을 확인한다.
- [x] Track 3 두 finding을 현재 코드와 호출 경로에 대조한다.
- [x] 각 finding의 타당성과 원 제안의 보완점을 기록한다.
- [x] 구현 범위, 위험, 자동/수동 검증 계획을 작성한다.
- [x] P2 폭 동작의 focused test 또는 순수 폭 계산 정책 테스트를 먼저 추가한다.
- [x] P2 중앙/한 손 모드별 고정 폭 제약 활성화와 가용 폭 clamp를 구현한다.
- [x] P2 preview 및 회전 시 폭 재계산 경로를 연결한다.
- [x] P2 가로 한 손 모드에서도 설정 폭을 적용하고 정책 테스트를 추가한다.
- [x] P3 기본 리턴 이미지의 rendering mode와 상태별 tint 테스트를 먼저 추가한다.
- [x] P3 비활성/활성/강조 상태에서 라벨과 이미지 tint를 함께 갱신한다.
- [x] 전체 `SYKeyboard` 테스트를 실행한다.
- [x] `HangeulKeyboard`와 `EnglishKeyboard` scheme을 빌드한다.
- [ ] 한글/영문 preview 및 실제 extension에서 수동 검증한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과를 반영한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
