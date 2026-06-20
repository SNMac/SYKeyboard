# Selected Text Return Key Tasks

Last Updated: 2026-06-20

## Checklist

- [x] GitHub Issue #85 본문과 댓글을 확인한다.
- [x] 관련 정책, 컨트롤러, 테스트 파일을 읽는다.
- [x] SDK 헤더에서 `UITextDocumentProxy.selectedText`와 `enablesReturnKeyAutomatically` 계약을 확인한다.
- [x] 리뷰 finding의 타당성을 판단한다.
- [x] 변경 범위를 확정한다.
- [x] `KeyboardPresentationStatePolicy.isReturnButtonEnabled(...)`에 `selectedText` 파라미터를 추가한다.
- [x] `BaseKeyboardViewController.updateReturnButtonEnabled()`에서 `textDocumentProxy.selectedText`를 전달한다.
- [x] `KeyboardPresentationStatePolicyTests`에 selected text만 있는 케이스를 추가하고 기존 호출부를 갱신한다.
- [x] `rg -n "isReturnButtonEnabled"`로 누락 호출부가 없는지 확인한다.
- [x] focused 정책 테스트를 실행한다.
- [x] 전체 `SYKeyboard` 테스트를 실행한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`에 처리 상태와 검증 결과를 반영한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [x] 완료 내용과 검증 결과를 최종 응답에 요약한다.
