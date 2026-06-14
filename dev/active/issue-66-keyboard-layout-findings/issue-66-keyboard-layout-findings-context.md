# Issue 66 Keyboard Layout Findings Context

Last Updated: 2026-06-14

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`: 수평 stack과 `keyboardLayoutView` 너비 제약을 생성하고 preview 폭을 갱신한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 현재 한 손 모드, chevron 표시, preview 폭 갱신, 리턴 키 타입/활성 상태를 연결한다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ChevronButton.swift`: 한 손 모드에서 남는 수평 영역에 표시되는 chevron 버튼이다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ReturnButton.swift`: 리턴 이미지 생성과 활성/비활성 시각 상태를 관리한다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/Bases/BaseKeyboardButton.swift`: `primaryKeyListImageView`를 일반 `UIImageView`로 제공하며 별도 기본 tint를 지정하지 않는다.
- `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`: 한 손 키보드 폭 설정 범위가 `300...340`임을 정의한다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: Track 3 원본 finding과 구현 후 처리 결과를 기록할 문서다.

## Facts Checked

- GitHub Issue #66에는 Track 3 finding 두 건이 있으며 댓글은 없다.
- `KeyboardView`의 현재 너비 제약은 `keyboardLayoutView.widthAnchor.constraint(greaterThanOrEqualToConstant:)` 하나다.
- `keyboardHStackView`의 arranged subview 순서는 왼쪽 chevron, 키보드 레이아웃, 오른쪽 chevron이다.
- 중앙 모드에서는 두 chevron이 숨겨지고, 한 손 모드에서는 한쪽 chevron만 표시된다.
- `updateOneHandModekeyboard()`는 현재 chevron 표시 상태만 바꾸며 너비 제약 상태는 바꾸지 않는다.
- `viewWillTransition(to:with:)`는 현재 키보드 높이만 갱신한다.
- 기본 리턴 이미지는 `.withTintColor(.label, renderingMode: .alwaysOriginal)`로 생성된다.
- `updateEnabled(false)`는 `primaryKeyListImageView.tintColor`를 변경하지만 원본 렌더링 이미지에는 적용되지 않는다.
- `updateEnabled(true)`는 `setNeedsUpdateConfiguration()`만 호출하며, 현재 configuration handler는 이미지 tint를 활성 색상으로 갱신하지 않는다.
- 현재 `SYKeyboardTests`에는 `KeyboardView` 폭 또는 `ReturnButton` 시각 상태를 직접 검증하는 테스트가 없다.
- 작업 시작 시 `git status --short` 출력은 비어 있었다.

## Decisions

- 두 finding은 모두 `Valid`로 판단한다.
- P2는 단순히 `greaterThanOrEqualToConstant`를 `equalToConstant`로 교체하지 않고, 모드별 제약 활성화와 가용 폭 clamp를 함께 구현한다.
- P3는 template rendering과 상태별 tint 갱신을 함께 구현한다.
- 실제 코드는 아직 수정하지 않고, 이번 작업에서는 검토 결과와 수정 계획만 문서화한다.

## Open Questions

- 가용 폭이 설정 최소값보다 작은 실제 extension 환경에서 chevron이 확보해야 할 최소 폭은 구현 중 `systemLayoutSizeFitting` 결과와 실제 터치 영역을 기준으로 확정해야 한다.
- preview와 실제 extension에서 private `keyboardLayoutView.frame.width`를 반복 측정할 진단 방법은 구현 시 테스트 전용 접근자 또는 임시 로깅 중 더 작은 변경으로 선택해야 한다.

## Verification Notes

- 확인한 명령:

```sh
gh api repos/SNMac/SYKeyboard/issues/66
gh api repos/SNMac/SYKeyboard/issues/66/comments
git status --short
rg -n "updateOneHandedWidth|oneHanded|keyboardLayoutView|ReturnButton|returnButtonDisabledLabel|primaryKeyListImageView|enablesReturnKeyAutomatically" Modules Keyboards SYKeyboardTests dev/active/code-review-scope/code-review-scope-findings.md
git blame -L 168,182 -- Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift
git blame -L 35,85 -- Modules/SYKeyboardCore/Presentation/View/Components/Buttons/ReturnButton.swift
```

- `gh issue view 66 --repo SNMac/SYKeyboard --comments`는 GitHub Projects classic deprecation GraphQL 오류로 실패했고, REST API 조회로 이슈 본문과 댓글 부재를 확인했다.
- 코드 수정이나 빌드/테스트는 아직 수행하지 않았다.
