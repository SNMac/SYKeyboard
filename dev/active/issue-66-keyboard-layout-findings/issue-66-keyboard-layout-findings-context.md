# Issue 66 Keyboard Layout Findings Context

Last Updated: 2026-06-15

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
- 세로와 가로 한 손 모드의 고정 폭은 설정 폭과 `keyboardHStackView` 가용 폭에서 표시 중인 chevron 압축 폭을 뺀 폭 중 작은 값으로 계산하도록 구현했다.
- 중앙 모드에서는 고정 폭 제약을 비활성화하고, `layoutSubviews`에서 회전과 가용 폭 변경을 재계산한다.
- 기본 리턴 이미지는 template rendering으로 변경했고 활성/강조/비활성 상태에서 라벨과 이미지 tint를 함께 갱신한다.

## Decisions

- 두 finding은 모두 `Valid`로 판단한다.
- P2는 화면 방향과 무관하게 한 손 모드에서 고정 폭과 가용 폭 clamp를 적용한다.
- P3는 template rendering과 상태별 tint 갱신을 함께 구현한다.
- preview 모드 변경은 `updateOneHandedModeForPreview(to:)`를 통해 실제 extension과 같은 폭 갱신 경로를 사용한다.

## Open Questions

- 현재 booted 시뮬레이터가 없어 preview와 실제 extension의 portrait/landscape 프레임 측정 및 리턴 키 시각 상태 수동 확인이 남아 있다.

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
- TDD RED:
  - 폭 정책 테스트는 정책 미구현으로 컴파일 실패하는 것을 확인했다.
  - 리턴 버튼 테스트는 template rendering과 활성 tint 복원 두 케이스가 실패하는 것을 확인했다.
- TDD GREEN:
  - 병렬 테스트를 끈 focused 테스트 실행이 exit code 0으로 완료됐다.
  - 가로 한 손 모드에서도 설정 폭을 적용하는 정책 테스트가 exit code 0으로 완료됐다.
- 전체 검증:

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -enableCodeCoverage NO
```

- 전체 `SYKeyboard` 테스트가 exit code 0으로 완료됐다.
- `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드가 iPhone 13 mini / iOS 16.0에서 exit code 0으로 완료됐다.
- 병렬 focused 테스트는 테스트 결과 출력 후 Xcode result 기록 단계에서 멈춰 종료했으며, 병렬 테스트를 끈 실행에서는 정상 종료됐다.
