# 브랜치 리뷰 수정 설계

## 목적

`bug/#102-cursor-drag-newline-boundary` 브랜치 리뷰에서 확인된 production 입력 유실과 테스트 품질
문제를 수정한다. 리뷰의 `기타` 항목은 이번 범위에서 제외한다.

이번 작업의 완료 조건은 다음과 같다.

- callback을 기다리는 released repeat 삭제 뒤의 새 delete touchDown을 잃지 않는다.
- 보류된 새 touchDown은 앞 요청의 확정 뒤 기존 FIFO와 semantic hook 경로에서 정확히 한 번 실행한다.
- 동일한 production 분기를 반복 검증하는 테스트를 하나로 합친다.
- production 동작을 호출하지 않고 테스트 안에서 기대 순서를 직접 만드는 검증을 제거한다.
- 서로 독립적인 테스트 헬퍼와 manager를 나란히 호출해 controller 통합처럼 보이게 하는 검증을 제거한다.
- 각 리뷰 수정은 독립 커밋으로 남긴다.

다음은 비목표다.

- 커서 드래그, 한글 automata, 삭제 mutation 판정 규칙의 기능 변경
- 반복 입력 timer 간격, feedback 시점, Undo/Redo grouping 의미 변경
- Firebase, 광고, entitlement, bundle identifier 변경
- `.gitignore`, AGENTS, 기존 계획 이력 등 리뷰의 `기타` 항목 수정
- Messages 실제 입력 화면과 물리 사운드·햅틱 자동 검증

## 입력 유실의 근본 원인

일반 delete touchDown과 pan boundary는 `DeleteInteractionCoordinator` generation과
`DeleteMutationLifecycle` 요청을 함께 시작한다. 반면 repeat tick은 lifecycle 요청만 시작한다.

repeat tick이 callback 전에 해제되면 lifecycle에는 `.releasedRepeatTick`이 남지만 coordinator는
idle일 수 있다. 이 상태에서 다음 delete touchDown이 오면:

1. coordinator는 새 generation을 만들고 `.performNow`를 반환한다.
2. lifecycle은 앞의 `.releasedRepeatTick` 때문에 새 요청을 `.deferred`로 거절한다.
3. controller는 두 상태를 취소하고 반환한다.

따라서 앞 repeat mutation의 late callback뿐 아니라 새 touchDown intent도 함께 사라진다.

## 선택한 production 설계

repeat mutation도 touchDown, pan boundary와 동일하게 coordinator generation이 소유한다.

`DeleteInteractionCoordinator`에 repeat mutation 시작 API를 추가한다. 이 API는 idle이면 새
generation을 만들고 resolution 대기 상태로 전환한다. 이미 generation이 있으면 현재 generation이
다른 mutation의 resolution을 기다리지 않을 때만 같은 generation을 다시 대기 상태로 전환한다.
입력 대상 식별자 규칙은 pan boundary와 동일하게 적용한다.

controller는 `DeleteMutationLifecycle.beginRepeat`보다 먼저 coordinator repeat mutation을 시작한다.
lifecycle 시작이 실패하면 방금 시작한 coordinator 상태도 함께 정리해 두 상태 머신을 다시 일치시킨다.

released repeat 요청이 남은 동안 새 delete touchDown이 오면 coordinator가 이를 `.enqueued`로
보존한다. late callback 또는 checkpoint가 앞 repeat 요청을 확정하면 기존 resolution 경로가
generation을 열고, FIFO drain이 저장된 버튼으로 다음 순서를 수행한다.

1. `textInteractionWillPerform(button:)`
2. 새 touchDown mutation 시작
3. 기존 delete body
4. `textInteractionDidPerform(button:)`
5. 새 요청이 확정된 경우에만 다음 FIFO 이벤트 진행

이 방식은 앞 mutation을 취소해 새 tap을 즉시 실행하는 대안과 달리 late callback의 Undo/Redo 기록을
보존한다. 새 touchDown을 controller 실패 분기에서 사후 재등록하는 대안과 달리 generation 소유권도
앞 mutation 시작 시점부터 일관되게 유지한다.

## 회귀 테스트

TDD 순서는 다음과 같다.

1. repeat mutation이 coordinator generation 없이 시작되는 현재 경로를 재현한다.
2. repeat release 뒤 새 touchDown이 `.performNow`가 되어 lifecycle에서 거절되고 사라지는 RED를
   확인한다.
3. coordinator repeat mutation 소유권을 최소 구현한다.
4. 같은 시나리오에서 새 touchDown이 `.enqueued`되고 late callback 뒤 정확히 한 번 replay되는
   GREEN을 확인한다.
5. replay 전에는 delete body가 실행되지 않고, replay 후 lifecycle이 새 touchDown을 pending으로
   소유하는지 확인한다.

테스트는 controller가 실제 사용하는 `DeleteInteractionCoordinator`와
`DeleteMutationLifecycle`의 production API를 함께 호출한다. 테스트 자체가 hook/body/did 문자열을
직접 추가하는 방식은 사용하지 않는다.

## 테스트 정리 원칙

### 완전 중복

동일한 request, candidate, callback, completion을 사용하는 검증은 한 테스트만 남긴다. 더 강한
assertion이 있는 경우 유지할 테스트에 병합한다.

- 일반 문자 callback 후보 확정과 pending 요청 callback 확정
- Messages 동일 앞 문맥 줄바꿈 확정과 동일 문맥 callback 줄바꿈 확정
- 권위 있는 `"한" → "하"` 치환 검증 세 개
- coordinator cancel을 두 번 호출해 pan cleanup 1회를 확인하는 검증 두 개

### 책임이 잘못 배치된 테스트

- `HangeulCompositionStateTests`에서 한글 state를 사용하지 않는 repeat request 검증은 policy
  suite의 단일 검증으로 통합한다.
- 빈 한글 state와 독립 request를 한 테스트에서 결합한 검증은 실제 state 결과만 검증하도록 줄인다.
- hard-coded 전체 삭제 배열만 manager에 기록하는 검증은 lifecycle과 manager를 함께 통과하는 기존
  검증과 겹치므로 제거한다.

### 무효 또는 오해 소지가 있는 테스트

- enum을 테스트 내부 함수로 0/1에 매핑한 뒤 `<= 1`을 확인하는 tick 테스트는 제거한다.
- 빈 no-op을 manager에 직접 기록하고 독립 request가 끝나는지만 확인하는 문서 시작 테스트는
  lifecycle resolution을 manager 기록 경계까지 전달하는 기존 검증으로 통합한다.
- 테스트가 스스로 `will/body/did` 문자열을 추가하는 hook 순서 검증은 제거한다.
- coordinator 단위 재진입 검증을 그대로 복제하는 harness 재진입 검증은 제거한다.
- suggestion/undo/view-stop이라는 이름만 붙이고 같은 cancellation helper를 호출하는 검증은 삭제하고,
  공통 non-delete cancellation boundary의 실제 결과를 한 곳에서 검증한다.
- 줄바꿈 버퍼 순서를 테스트 harness가 production 코드와 같은 순서로 재작성한 검증은 제거한다.
  남는 테스트 이름과 설명은 실제로 호출하는 production 경계를 넘어서 controller 통합을 보장한다고
  표현하지 않는다.

실제 `BaseKeyboardViewController` 진입점 검증을 위해 production에 테스트 전용 API나 의존성 주입을
추가하지 않는다. UIKit host가 제공하는 `textDocumentProxy`와 private 상태를 가짜로 재구성하면 다시
같은 false-positive 문제가 생기기 때문이다. controller wiring은 production 변경 diff 검토와 전체
scheme 테스트·extension build로 확인하고, unit suite는 검증 가능한 production policy 계약만
정확하게 명명한다.

## 커밋 경계

다음 논리 수정은 섞지 않는다.

1. repeat mutation generation 소유권과 입력 유실 회귀
2. request/callback 완전 중복 테스트 통합
3. coordinator cancellation 완전 중복 테스트 통합
4. Undo/Redo manager의 중복·무효 반복 삭제 테스트 정리
5. Hangeul suite에 잘못 배치된 repeat request 테스트 정리
6. non-delete 경계의 이름만 다른 harness 테스트 정리
7. 수동 hook·재진입·줄바꿈 순서 harness 테스트 정리
8. tautological repeat tick 테스트 정리

각 커밋 전에는 해당 focused test를 실행하고, 마지막 커밋 뒤 전체 `SYKeyboard` 테스트와
`HangeulKeyboard`, `EnglishKeyboard` extension build를 iPhone 13 mini / iOS 16.0에서 새로
실행한다.
