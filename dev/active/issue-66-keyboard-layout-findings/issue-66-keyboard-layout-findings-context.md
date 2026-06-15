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
- 기존 `KeyboardView`의 너비 제약은 `keyboardLayoutView.widthAnchor.constraint(greaterThanOrEqualToConstant:)` 하나였다.
- `keyboardHStackView`의 arranged subview 순서는 왼쪽 chevron, 키보드 레이아웃, 오른쪽 chevron이다.
- 중앙 모드에서는 두 chevron이 숨겨지고, 한 손 모드에서는 한쪽 chevron만 표시된다.
- 기존 `updateOneHandModekeyboard()`는 chevron 표시 상태만 바꾸며 너비 제약 상태는 바꾸지 않았다.
- `viewWillTransition(to:with:)`는 현재 키보드 높이만 갱신한다.
- 기본 리턴 이미지는 `.withTintColor(.label, renderingMode: .alwaysOriginal)`로 생성된다.
- `updateEnabled(false)`는 `primaryKeyListImageView.tintColor`를 변경하지만 원본 렌더링 이미지에는 적용되지 않는다.
- `updateEnabled(true)`는 `setNeedsUpdateConfiguration()`만 호출하며, 현재 configuration handler는 이미지 tint를 활성 색상으로 갱신하지 않는다.
- 현재 `SYKeyboardTests`에는 `KeyboardView` 폭 또는 `ReturnButton` 시각 상태를 직접 검증하는 테스트가 없다.
- 작업 시작 시 `git status --short` 출력은 비어 있었다.
- 세로와 가로 한 손 모드에서는 키보드가 설정한 최소 폭 이상을 차지하고 표시된 Chevron과 남은 영역을 나눠 갖는다.
- 중앙 모드에서는 두 Chevron이 숨겨지고 키보드가 전체 폭을 사용한다.
- 기본 리턴 이미지는 template rendering으로 변경했고 활성/강조/비활성 상태에서 라벨과 이미지 tint를 함께 갱신한다.
- PR #74 리뷰에서 `layoutSubviews`가 제약 활성화 상태를 변경하는 점과 매 레이아웃마다 `systemLayoutSizeFitting`을 호출하는 점이 지적됐다.
- `ChevronButton`은 고정 폭 제약이 없고 `UIStackView`의 남는 공간을 차지하므로 리뷰에서 제안한 임의의 `44.0` 폭은 현재 레이아웃 계약과 일치하지 않는다.
- 최소 폭 제약은 항상 활성화하며 `layoutSubviews`에서는 폭을 재계산하지 않는다.
- 실제 extension에서 한 손 모드 전환 시 `UIView-Encapsulated-Layout-Width == 698`, `UIStackView` 내부 fill 제약, `keyboardLayoutView.width == 300`이 동시에 필수 우선순위로 활성화되어 제약 경고가 발생했다.
- 기준 커밋 `84a48326c9d492654074c863227b7330f3b2a97a`에서는 너비 제약이 `>= 설정 폭`이라 `UIStackView`가 키보드를 전체 폭으로 늘려도 경고가 없었다.
- 현재 `== 설정 폭` 계약에서는 Chevron을 hidden arranged subview로 제거하면 `UIStackView`가 키보드에 전체 폭을 요구하는 필수 내부 제약을 생성해 고정 폭 제약과 충돌한다.
- `isHidden` 변경 뒤 `layoutIfNeeded()`를 호출하는 방식으로도 실제 extension의 세로/가로 전환 경고가 해소되지 않았다.
- 고정 폭 제약 우선순위를 `999`로 낮추는 첫 수정은 `UIStackView`가 해당 제약을 깨고 키보드를 최소 크기로 압축하는 기능 회귀를 발생시켜 폐기했다.
- 최종 구현은 `KeyboardView`가 폭과 모드를 저장하지 않고 전달받은 최소 폭과 모드를 즉시 UI에 반영한다.
- Chevron은 기존처럼 hidden arranged subview로 관리한다.
- `KeyboardView.updateOneHandedMode(_:)`는 Chevron hidden 상태를 갱신하며, VC는 현재 모드 저장과 Chevron 탭 action만 관리한다.
- 사용자 View Hierarchy 확인에서 설정 폭 `320`, `340`이 정상 표시됨을 확인했다.

## Decisions

- P3는 `Valid`, P2는 최종 사용자 의도상 `Invalid`로 판단한다.
- P2 설정값은 정확한 폭이 아니라 최소 폭이며, 한 손 모드에서 키보드가 설정값 이상을 차지하고 표시된 Chevron과 남은 영역을 나눠 갖도록 한다.
- P3는 template rendering과 상태별 tint 갱신을 함께 구현한다.
- preview 모드 변경은 `updateOneHandedModeForPreview(to:)`를 통해 실제 extension과 같은 폭 갱신 경로를 사용한다.
- PR #74 리뷰의 제약 활성화 분리와 반복 fitting 제거 지적은 타당하다고 판단해 반영한다. 최종 구현에서는 fitting 계산 자체가 필요하지 않다.
- 한 손 키보드 최소 폭 제약은 `greaterThanOrEqualToConstant`로 항상 활성화한다.
- Chevron은 기존 `isHidden` 방식으로 표시하며 별도 폭 0 제약, alpha, 터치 상태 축소 처리를 사용하지 않는다.
- 한 손 모드 UI 상태의 소유자는 `KeyboardView`로 두고, VC에서 Chevron hidden 상태를 직접 변경하지 않는다.

## Open Questions

- 현재 변경본의 실제 extension에서 portrait/landscape 한 손 모드 전환 시 제약 경고가 없는지 사용자 수동 확인이 남아 있다.
- 리턴 키의 실제 extension 비활성/활성 복원 상태 수동 확인이 남아 있다.

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
  - 가로 한 손 모드에서도 설정 폭을 적용하는 기존 정책 테스트가 exit code 0으로 완료됐으나, 최종 계약에서 clamp 정책이 제거되어 해당 테스트도 제거했다.
  - 제약 우선순위를 `999`로 낮춘 수정은 실제 extension에서 키보드 레이아웃 전체가 최소 크기로 압축되는 회귀를 발생시켜 폐기했다.
  - Chevron 숨김 상태를 먼저 레이아웃하는 수정 후 focused 테스트, 전체 `SYKeyboard` 테스트, `HangeulKeyboard`, `EnglishKeyboard` 빌드가 모두 exit code 0으로 완료됐다.
  - 이후 실제 extension의 세로/가로 한 손 모드 전환에서 같은 제약 경고가 재현되어 위 수정은 최종 해결책이 아닌 것으로 확인됐다.
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
- PR #74 리뷰 대응 후 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드를 같은 대상에서 다시 실행해 모두 exit code 0을 확인했다.
- 폭·모드 상태 단순화와 clamp 정책 제거 후 `ReturnButtonTests`, 전체 `SYKeyboard` 테스트, `HangeulKeyboard`, `EnglishKeyboard` 빌드를 다시 실행해 모두 exit code 0을 확인했다.
- Chevron hidden 상태와 폭 제약 갱신을 `KeyboardView`로 통합한 뒤 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드를 다시 실행해 모두 exit code 0을 확인했다.
- 고정 폭 및 Chevron 폭 0 축소 정책은 최종 계약에서 제거했다.
- 최소 폭 계약 복원 후 iPhone 13 mini / iOS 16.0에서 전체 `SYKeyboard` 테스트와 `HangeulKeyboard`, `EnglishKeyboard` 빌드를 다시 실행해 모두 exit code 0을 확인했다.
- XcodeBuildMCP의 기존 DerivedData 실행은 오래된 `GoogleMobileAds` module cache 충돌로 실패했으나, 새 `/private/tmp/SYKeyboard-XcodeBuildMCP-DerivedData` 경로에서는 앱 빌드·실행이 성공했다.
- 시뮬레이터 앱의 테스트 입력 필드에서 키보드 표시까지 확인했지만, UI 자동화로 커스텀 키보드의 한 손 모드 선택 제스처를 실행할 수 없어 현재 변경본의 portrait/landscape 전환 경고는 직접 확인하지 못했다.
- `KeyboardView`의 최소 폭 제약, 초기 Chevron hidden 상태, `updateOneHandedWidth(_:)` 경로는 경고가 없었던 기준 커밋 `84a48326c9d492654074c863227b7330f3b2a97a`과 동일하며, Chevron hidden 갱신 책임만 `KeyboardView.updateOneHandedMode(_:)`로 이동했다.
- 병렬 focused 테스트는 테스트 결과 출력 후 Xcode result 기록 단계에서 멈춰 종료했으며, 병렬 테스트를 끈 실행에서는 정상 종료됐다.
