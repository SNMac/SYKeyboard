# 자동완성 후보 스크롤 롤백 설계

## 목적

자동완성 후보에 도입한 가로 스크롤과 edge effect가 실제 키보드에서 의도대로
표시되지 않으므로, 스크롤 도입 직전의 후보 표시와 터치 동작으로 복원한다.
수식 계산 자동완성과 그 밖의 후보 생성 로직은 유지한다.

## 접근 방식

검토한 방식은 다음 세 가지다.

1. `UIScrollView`만 제거하고 고정 16pt 한 줄 표시는 유지한다.
   긴 후보를 읽을 방법이 없어 요구사항에 맞지 않는다.
2. 현재 코드에서 스크롤 관련 분기를 수동으로 골라 제거한다.
   복원 범위를 세밀하게 조절할 수 있지만 이전 터치 흐름과 미세하게 달라질 위험이
   있다.
3. 스크롤 도입 커밋 `274aec93`의 직전 구현을 두 production 파일에 복원하고,
   스크롤 전용 테스트와 문서를 제거한다.
   검증된 이전 동작을 정확히 되살리고 다른 자동완성 기능을 보존할 수 있다.

세 번째 방식을 사용한다.

## Production 복원

### `SuggestionButtonView`

- `UIScrollView`, content offset, overflow 판정, 초기 trailing 위치와 모든
  `UIScrollEdgeEffect` 설정을 제거한다.
- `suggestionLabel`을 버튼에 직접 배치한다.
- 스크롤 도입 전 표시 계약을 복원한다.
  - `numberOfLines = 2`
  - `adjustsFontSizeToFitWidth = true`
  - `minimumScaleFactor = 0.7`
  - `lineBreakMode = .byTruncatingMiddle`
  - 좌우 여백 `4pt`
- 기존 둥근 배경, divider 연동과 하이라이트 색상은 유지한다.

### `SuggestionBarView`

- 스크롤 활성화 거리, 터치 시작 후보, 시작 offset과 스크롤 활성 상태를 제거한다.
- `beginTouchInteraction`, `moveTouchInteraction`, `endTouchInteraction`,
  `cancelTouchInteraction`에 추가된 스크롤 모드 분기를 제거한다.
- 스크롤 도입 전처럼 터치 위치에 있는 후보를 하이라이트하고 손을 떼면 선택하는
  endpoint 기반 흐름을 복원한다.
- preview 하이라이트, 햅틱·소리 피드백, 키보드 버튼과 후보 버튼의 배타 상태는
  유지한다.

## 테스트와 문서

- `SuggestionButtonViewScrollingTests.swift`와
  `SuggestionBarViewTouchInteractionTests.swift`는 스크롤 전용 계약이므로
  제거한다.
- 기존 `SuggestionBarViewPreviewHighlightTests`와
  `ButtonStateControllerTests`로 복원된 터치·하이라이트 흐름을 검증한다.
- 전체 `SYKeyboardTests`와 한글·영문 키보드 확장 빌드를 실행한다.
- 스크롤 도입 및 후속 edge effect만 설명하는 아래 계획·설계 문서를 제거한다.
  - `docs/superpowers/plans/2026-07-27-suggestion-overflow-scrolling.md`
  - `docs/superpowers/plans/2026-07-28-suggestion-horizontal-edge-effect.md`
  - `docs/superpowers/plans/2026-07-28-suggestion-scroll-edge-effect.md`
  - `docs/superpowers/plans/2026-07-28-suggestion-soft-edge-effect.md`
  - `docs/superpowers/specs/2026-07-28-suggestion-scroll-edge-effect-design.md`

## 보존 범위

- `2f1ae737`과 `5f114770`에 포함된 수식 계산 자동완성, 숫자 표기 확장과 관련
  테스트는 변경하지 않는다.
- 스크롤 도입 이전부터 존재한 후보 선택, preview, divider, 피드백과 키보드
  입력 흐름을 변경하지 않는다.
- Firebase, 광고, 권한, bundle identifier와 provisioning 설정은 변경하지 않는다.

## 완료 기준

- production 코드에 후보 텍스트용 `UIScrollView`,
  `UIScrollEdgeEffect`, 스크롤 offset 상태와 스크롤 터치 중재가 남아 있지 않다.
- 긴 후보가 스크롤 도입 전의 2줄·자동 축소·가운데 생략 방식으로 표시된다.
- 후보 선택과 하이라이트 관련 기존 테스트가 통과한다.
- 전체 테스트와 한글·영문 키보드 확장 빌드가 성공한다.
- 수식 자동완성 관련 production 코드와 테스트는 롤백 전 상태를 유지한다.
