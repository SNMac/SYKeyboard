# 자동완성 후보 바 가로 스크롤 설계

GitHub Issue: [#141](https://github.com/SNMac/SYKeyboard/issues/141)
기준 브랜치: `feat/#139-suggestion-removal` (#139 위에 쌓는다)

## 목적

자동완성 후보 영역을 가로 스크롤로 만들어 후보를 최대 10개까지 노출한다.
갤럭시 키보드와 같은 방식이다. 지금은 후보 버튼이 3개로 고정되어 있고
엔진도 그 개수에 맞춰 조기 종료하므로, UI와 후보 생성 상한을 함께 바꾼다.

## 배경: #98 롤백과 무엇이 다른가

`a2941eff`(#98)에서 후보 스크롤을 되돌린 적이 있다. 이번 작업은 목적과 구현이
모두 다르므로, 같은 실패를 반복하지 않도록 차이를 명시한다.

| 항목 | #98 (롤백됨) | 이번 작업 |
| --- | --- | --- |
| 스크롤 대상 | 후보 버튼 **안의 긴 텍스트** | 후보 **목록** |
| 스크롤 구현 | `setScrollOffsetX`로 offset 직접 조작 | `UIScrollView`에 팬 제스처 위임 |
| 터치 중재 | `scrollActivationDistance = 8`pt를 직접 측정 | 중재 코드 없음. `UIScrollView` 기본 동작 사용 |
| 가장자리 효과 | `UIScrollEdgeEffect` (iOS 26 전용) | `CAGradientLayer` mask (iOS 16+) |

`CLAUDE.md`의 "스크롤 컨테이너나 제스처 중재를 재도입하지 않는다" 조항은 이번
결정으로 갱신한다. 갱신하지 않으면 이후 작업자가 이 변경을 회귀로 오인한다.

## 확정된 결정

사용자가 직접 결정한 항목이며, 구현 중 바꾸지 않는다.

1. 후보는 최대 10개까지 노출한다.
2. 입력 중 모드의 `"현재단어"` 버튼도 함께 스크롤되어 화면 밖으로 나가도 된다.
3. 가로 드래그는 스크롤이다. **끌어서 후보를 옮겨가며 고르고 떼면 선택되던
   기존 동작은 의도적으로 제거한다.** 선택은 탭으로만 한다.
4. 후보 버튼 폭은 지금과 같은 등폭을 유지한다. 후보 영역(클립보드·undo/redo
   버튼을 뺀 나머지)을 3등분한 폭이다.
5. 더 볼 후보가 있다는 사실은 가장자리 페이드로 알린다.

## 1. 후보 상한 확장

- `SuggestionController.maxSuggestions`: `3` → `10`.
  입력 중 모드는 0번 칸이 `"현재단어"`이므로 엔진 몫은 `maxSuggestions - 1 = 9`,
  n-gram 예측 모드는 10이다. 이 계산식은 이미 코드에 있으므로 수식은 바꾸지 않는다.
- `NGramPredictiveTextEngine.maxPredictions`: `3` → `10`.
  `maxEntriesPerKey = 24`는 유지한다. 이 상수의 주석이 `maxPredictions`를
  언급하므로 문구를 함께 확인한다.
- `TextCheckerPredictiveTextEngine`의 `limit`은 호출부에서
  `maxSuggestions - 1`을 넘기므로 따로 고치지 않는다.
- `LexiconPredictiveTextEngine`은 원래 상한이 없다. 변경하지 않는다.

`rankedUnigramCandidates()`는 전체 정렬 대신 상위 `maxPredictions`개만 유지하는
부분 삽입 정렬이다. `top[top.count - 1].value` 비교와 삽입 위치 계산이 N=3에
맞춰 검증된 코드이므로, **N을 늘리기 전에 실패하는 테스트를 먼저 쓴다.**

### 알려진 영향

후보 품질이 희석된다. TextChecker의 `guesses`(오타 교정)가 거의 매 입력마다
호출되고, n-gram은 trigram/bigram이 부족하면 unigram으로 나머지를 채운다.
뒤쪽 후보 대부분은 문맥과 무관한 상용 단어가 된다. 후보가 10개까지 차지 않아
스크롤이 생기지 않는 경우도 정상 동작으로 본다.

`guesses` 호출은 2026-09-02 성능 작업에서 의도적으로 생략시킨 12~22ms짜리
경로다. 다만 `textCheckerQueue` 비동기 + 세대 검사 경로라 타이핑을 막지 않는다.
메인 스레드에 실제로 추가되는 비용은 버튼 레이아웃이다.

## 2. 바 레이아웃

지금은 클립보드 버튼, 후보 3개, undo/redo 버튼이 모두 하나의
`buttonContainerHStackView`에 들어 있다. 후보 구간만 떼어 스크롤 컨테이너로
바꾸고 기능 버튼은 고정한다.

```
[클립보드] │ [ ← UIScrollView: 후보0 │ 후보1 │ 후보2 │ 후보3 … → ] │ [undo] │ [redo]
```

- `buttonContainerHStackView`의 arranged subview 중
  `suggestionButton1`, `leftDivider`, `suggestionButton2`, `rightDivider`,
  `suggestionButton3`을 스크롤 뷰 하나로 대체한다.
  `clipboardButton`, `clipboardDivider`, `undoRedoLeadingDivider`,
  `undoButton`, `undoRedoMiddleDivider`, `redoButton`은 그대로 둔다.
- 스크롤 뷰 안에는 content view 하나를 두고, 그 안에 후보 버튼과 divider를
  가로로 배치한다.
- 후보 버튼은 고정 3개 대신 **재사용 풀**에서 필요한 개수만큼 꺼내 쓴다.
  버튼 사이 divider도 같은 방식으로 만든다(버튼 N개에 divider N-1개).
  후보 수가 줄면 남는 뷰는 제거하고, 늘면 풀에서 추가한다.
- 버튼 폭은 **스크롤 뷰 뷰포트(`bounds.width`)의 1/3**로 잡는다. 이 값이 지금
  등폭 제약으로 나오는 폭과 같다. 스크롤 뷰의 프레임 너비는 스택이 기능 버튼을
  배치하고 남긴 공간으로 고정되고, 후보가 늘어날 때 커지는 것은 `contentSize`뿐이다.
  클립보드·undo/redo 버튼은 숨겨질 수 있어 후보 영역 너비가 변하므로, 폭은
  상수가 아니라 뷰포트 기준으로 매 레이아웃마다 갱신한다.
- 높이 제약, 좌우 `layoutMargins`, 배경, 하이라이트 색상은 유지한다.
- `SuggestionButtonView`는 수정하지 않는다. 2줄·자동 축소·가운데 생략 표시
  계약을 그대로 둔다.
- `updateSuggestions(currentWord:suggestions:)`는 고정 3개 배열 대신 후보 수에
  맞춰 버튼을 구성하도록 바꾼다. 입력 중 모드에서 0번이 `"현재단어"`이고
  나머지가 후보라는 규칙은 그대로다.

## 3. 터치 전달

**터치 중재 코드를 새로 만들지 않는다.** `UIScrollView`의 기본 동작을 쓴다.

- `delaysContentTouches = false`
  손을 대는 즉시 하이라이트가 켜져야 한다. 키보드라 기본 150ms 지연은 쓸 수 없다.
- `canCancelContentTouches = true` (기본값)
  손가락을 끌면 UIKit이 content view에 `touchesCancelled`를 보낸다.

content view는 받은 `touchesBegan/Moved/Ended/Cancelled`를 **`SuggestionBarView`의
같은 이름 터치 오버라이드로 그대로 넘긴다.** `UITouch.location(in:)`은 대상 뷰를 인자로
받으므로, 어느 뷰가 터치를 받았든 바 좌표가 정확히 나온다. 따라서
`beginTouchInteraction(at:)`, `moveTouchInteraction(to:)`,
`endTouchInteraction(at:playsFeedback:)`, `cancelTouchInteraction()`의
본문은 바꾸지 않는다.

이 구조에서 얻어지는 동작:

- 탭 → `endTouchInteraction`에서 후보 선택 (지금과 동일)
- 드래그 → 스크롤 시작 시 `touchesCancelled` → `cancelTouchInteraction()` →
  `resetTouchInteraction()`이 하이라이트를 지우고, **#139의 0.7초 삭제 타이머를
  `cancelRemovalLongPress()`로 취소하며**, 키보드 버튼 입력을 다시 켠다.
- 길게 누르기 → 손가락이 거의 안 움직이면 스크롤이 시작되지 않으므로 타이머가
  살아남아 #139의 삭제 확인 오버레이가 뜬다.

즉 스크롤·탭·길게 누르기 세 동작의 분리를 `UIScrollView`가 담당하고, 이 저장소의
코드는 상태 변수를 하나도 추가하지 않는다.

기능 버튼(클립보드·undo/redo)은 스크롤 뷰 밖이므로 `SuggestionBarView` 자신의
터치 오버라이드가 지금처럼 처리한다. `suggestionButton(at:)`과
`actionButton(at:)`은 `convert(_:to:)` 기반이라 스크롤 offset이 자동 반영된다.
변경하지 않는다.

## 4. 가장자리 페이드

- 스크롤 뷰의 `layer.mask`에 가로 `CAGradientLayer`를 건다.
  `UIScrollEdgeEffect`는 iOS 26 전용이고 #98에서 의도대로 표시되지 않았으므로
  쓰지 않는다.
- 남은 내용이 있는 방향에만 켠다. 왼쪽은 `contentOffset.x > 0`,
  오른쪽은 `contentOffset.x + bounds.width < contentSize.width`일 때다.
  사용자 요청은 오른쪽이지만, 같은 그라디언트에 정지점을 하나 더 두는 수준이라
  양쪽을 대칭으로 처리한다.
- mask는 뒤 배경을 비추므로 라이트/다크 모드와 반투명 키보드 배경에서 결과가
  달라진다. 실기기 수동 확인 항목으로 둔다.
- `scrollViewDidScroll`과 `layoutSubviews`에서 프레임과 정지점을 갱신한다.
  `CALayer` 암시적 애니메이션은 끈다.

## 5. divider

`updateDividers()`는 지금 `suggestionButton1/2/3`을 직접 참조한다. 가변 개수에
맞춰 다음 규칙으로 일반화한다.

- 후보 사이 divider `i`(버튼 `i`와 `i+1` 사이): 양쪽 버튼 중 하나라도
  하이라이트면 투명, 아니면 `.suggestionDividerColor`.
- `clipboardDivider`: 클립보드 버튼 또는 **첫 후보 버튼**이 하이라이트일 때 투명.
- `undoRedoLeadingDivider`: undo 버튼 또는 **마지막 후보 버튼**이 하이라이트일 때 투명.
- 단, 경계 버튼이 스크롤되어 스크롤 뷰 bounds 밖으로 완전히 나가 있으면 경계
  divider는 지우지 않는다. 보이지 않는 버튼 때문에 divider가 사라지는 것을 막는다.
- `undoRedoMiddleDivider` 규칙은 그대로다.

## 6. 수식 모드와 preview

- **수식 모드는 스크롤 대상이 아니다.** 3칸의 역할이 고정이다
  (원문 / 원문+결과 / 결과 대치). 후보 수가 3이라 `contentSize`가 bounds를
  넘지 않으므로 스크롤도 페이드도 자동으로 생기지 않는다. 별도 분기를 넣지 않는다.
- `updatePreviewHighlight(index:)`의 유효 범위는 후보 버튼 개수를 따른다.
  현재 문서 주석의 `0~2` 표기를 고친다. preview 대상이 화면 밖에 있어도
  자동 스크롤하지 않는다.
- 후보가 갱신되면 `contentOffset`을 0으로 되돌린다. 이전 스크롤 위치를 유지하면
  새 후보 목록에서 엉뚱한 위치가 보인다.

## 7. 되돌릴 수 있게 만든다

스크롤과 페이드의 발생 조건은 **오직 `contentSize.width > bounds.width`** 다.
후보 개수를 따로 분기하지 않는다. 버튼 폭이 뷰포트의 1/3이므로 후보가 3개
이하이면 `contentSize`가 뷰포트를 넘지 않는다. 따라서 품질이나 성능이 기대에 못 미치면
`maxSuggestions`를 `3`으로 되돌리는 것만으로 스크롤과 페이드가 사라지고 예전
화면으로 돌아간다.

## 테스트

Swift Testing으로 작성한다. production 진입점을 호출하지 않는 helper 검증은
추가하지 않는다.

- `NGramPredictiveTextEngine`
  - `maxPredictions`를 늘린 뒤 trigram → bigram → unigram 보충 순서와 중복 제거가
    유지되는지.
  - `rankedUnigramCandidates()`가 빈도 상위 N개를 내림차순으로 반환하는지.
    항목 수가 N보다 적을 때, 같을 때, 많을 때를 모두 본다. **이 테스트를 먼저 쓴다.**
- `SuggestionController`
  - 입력 중 모드에서 후보가 9칸까지 차되 현재 입력 단어가 제외되고 중복이
    제거되는지.
  - #139의 `removableSuggestionText(atBarIndex:)`가 10칸에서도 올바른 후보를
    가리키는지(`barIndex - 1` 매핑).
- `SuggestionHighlightPolicy`: 이미 `suggestionCount`를 인자로 받으므로 확장된
  개수에 대한 케이스를 추가한다.
- `SuggestionBarView`
  - 후보 수가 10 → 3 → 10으로 바뀔 때 이전 후보 텍스트나 divider가 남지 않는지.
    표시 텍스트와 divider 표시 여부 같은 공개 동작으로만 검증하고 subview 계층은
    고정하지 않는다.
  - content view가 받은 `touchesCancelled`가 하이라이트를 지우고 #139의 삭제
    타이머를 취소하는지. 기존 `SuggestionBarViewRemovalLongPressTests`에 붙인다.

## 실기기 수동 확인

iPhone 13 mini / iOS 18.6, 실제 입력 앱에서 확인한다. 자동 테스트로 대체하지 않는다.

- [ ] 짧은 탭으로 후보가 선택되고, 끌면 스크롤된다
- [ ] 후보에 손을 댄 즉시 하이라이트가 켜진다(`delaysContentTouches = false`)
- [ ] 스크롤 중에는 삭제 확인 오버레이가 뜨지 않는다
- [ ] 제자리에서 0.7초 누르면 삭제 확인 오버레이가 뜬다(#139 회귀 확인)
- [ ] 라이트/다크 모드에서 가장자리 페이드가 의도대로 보인다
- [ ] 클립보드·undo/redo 버튼이 스크롤과 무관하게 동작한다
- [ ] 수식 후보 3칸이 스크롤되지 않는다
- [ ] 타이핑 지연이 체감되지 않는다. `OSSignposter` 구간으로 전후를 실측해
      계획 문서에 기록한다

## 보존 범위

- `SuggestionButtonView`의 표시 계약(2줄, 자동 축소 0.7, 가운데 생략, 좌우 4pt)
- 후보 선택·preview·햅틱/사운드 피드백과 키보드 버튼 배타 상태
- 수식 자동완성의 origin 계약과 확정 대치 방식
- 클립보드 패널, undo/redo 동작
- Firebase, 광고, 권한, bundle identifier, provisioning 설정

## 완료 기준

- 후보가 10개까지 노출되고, 화면을 넘으면 가로로 스크롤된다.
- 드래그가 스크롤로 동작하고 탭으로 후보가 선택된다. 끌어서 고르는 이전 동작은
  남아 있지 않다.
- 스크롤 시작이 #139의 삭제 타이머를 취소한다.
- 후보 버튼 폭이 지금과 같다(후보 영역의 1/3).
- 남은 방향에만 가장자리 페이드가 보인다.
- `maxSuggestions`를 3으로 되돌리면 스크롤과 페이드가 사라진다.
- 전체 `SYKeyboardTests`와 세 키보드 extension 빌드가 성공한다.
- `CLAUDE.md`의 후보 스크롤 금지 조항이 이번 결정에 맞게 갱신되었다.
- 실기기 수동 확인 항목의 결과가 계획 문서에 기록되었다.
