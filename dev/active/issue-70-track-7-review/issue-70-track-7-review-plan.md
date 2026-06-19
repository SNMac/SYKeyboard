# Issue 70 Track 7 Review Plan

Last Updated: 2026-06-19

## Goal

- GitHub Issue #70의 Track 7 리뷰 항목을 현재 코드 기준으로 검증하고, 타당한 항목만 수정한다.

## Current State

- 관련 이슈: `https://github.com/SNMac/SYKeyboard/issues/70`
- 관련 findings 문서: `dev/active/code-review-scope/code-review-scope-findings.md`
- 관련 파일:
  - `SYKeyboard/App/SYKeyboardApp.swift`
  - `SYKeyboard/Presentation/Content/ContentView.swift`
  - `SYKeyboard/Presentation/Content/BannerAd/BannerAdView.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/InitialSettingsView.swift`
  - `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift`
  - `SYKeyboard/Presentation/Utils/Extensions/View+Extension.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`

## Review Item Evaluation

### 1. [P2] 설정 이동 deep link가 최초 ATT 권한 요청과 충돌함

- 판단: 타당함.
- 확인한 사실:
  - `SYKeyboard/App/SYKeyboardApp.swift`의 `.onOpenURL`은 URL 종류와 무관하게 `UIApplication.openSettingsURLString`을 연다.
  - 같은 view chain의 `UIApplication.didBecomeActiveNotification` 구독은 ATT 상태가 `.notDetermined`이면 즉시 `ATTrackingManager.requestTrackingAuthorization()`을 호출한다.
  - `sykeyboard://`는 키보드 extension의 전체 접근 안내에서 사용된다.
- 수정 방향:
  - 설정 redirect 중에는 ATT 요청을 보류한다.
  - 가능하면 ATT 요청 시점을 온보딩 sheet가 내려간 뒤의 메인 앱 내부 상태로 제한한다.
  - `didBecomeActive`에서 무조건 요청하는 구조는 제거하거나 guard를 둔다.

### 2. [P2] 화면 폭 변경 후 adaptive banner가 최초 크기를 유지함

- 판단: 타당함.
- 확인한 사실:
  - `ContentView`는 `GeometryReader`의 `geometry.size.width`로 매 렌더링마다 `largeAnchoredAdaptiveBanner(width:)`를 계산한다.
  - `BannerAdView.updateUIView(_:context:)`가 비어 있어 생성된 `BannerView`의 `adSize`와 광고 요청이 갱신되지 않는다.
- 수정 방향:
  - `updateUIView`에서 `uiView`를 `BannerView`로 캐스팅하고 현재 `adSize`와 새 `adSize`를 비교한다.
  - 크기가 달라졌을 때 `banner.adSize`를 갱신하고 광고를 다시 요청한다.
  - 같은 크기에서는 중복 load를 피한다.

### 3. [P2] 광고를 받지 못해도 빈 하단 safe area가 유지됨

- 판단: 타당함.
- 확인한 사실:
  - `safeAreaInset(edge: .bottom)` 내부의 `BannerAdView`가 항상 `adSize.size.height`만큼 frame에 참여한다.
  - `opacity(0)`와 `allowsHitTesting(false)`는 레이아웃 높이를 제거하지 않는다.
- 수정 방향:
  - 광고 수신 전 또는 실패 상태에서는 container 높이를 0으로 둔다.
  - 광고 수신 후에만 `adSize.size.height`만큼 safe-area 공간을 확보한다.
  - `BannerAdCoordinator`는 광고 실패 시 이미 `isAdReceived = false`로 복구하므로 `ContentView`의 높이 전환에 집중한다.

### 4. [P2] 자동 인앱 리뷰 요청 modifier가 어떤 화면에도 연결되지 않음

- 판단: 현재 코드 기준으로는 미연결 finding이 비타당함. 다만 카운트 기준과 threshold 보정은 필요함.
- 확인한 사실:
  - `requestReviewViewModifier()` 호출은 다음 4개 화면에 존재한다.
    - `SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift`
    - `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`
    - `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift`
    - `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`
  - 따라서 “어떤 화면에도 연결되지 않음”이라는 finding은 현재 코드와 맞지 않는다.
- 처리:
  - 기능 제거는 하지 않는다.
  - 앱 실행을 카운트 기준에 추가한다.
  - 앱 시작 직후 요청 UI가 뜨지 않도록 앱 실행은 카운트만 증가시킨다.
  - 실제 요청 판단은 상세 설정 화면에서 메인 설정으로 돌아오는 시점에 유지한다.
  - threshold는 30회로 낮춘다.

## Approach

1. ATT 요청과 설정 redirect 충돌을 먼저 수정한다.
2. 광고 banner 크기 갱신과 빈 safe area 문제는 같은 변경 묶음으로 수정한다.
3. 리뷰 modifier 항목은 미연결 전제를 정정하고, 앱 실행 카운트 + 상세 복귀 카운트/요청 판단으로 보정한다.
4. 수정 후 `dev/active/code-review-scope/code-review-scope-findings.md`와 이 작업 문서의 상태를 갱신한다.

## Risks

- ATT 팝업은 iOS 정책과 시스템 상태에 의존하므로 자동 테스트만으로는 충분히 검증하기 어렵다.
- 광고 로딩은 네트워크, AdMob SDK, 테스트 광고 응답에 의존하므로 수동 확인 또는 로그 확인이 필요하다.
- safe area 높이를 0으로 전환할 때 광고 수신 직후 목록 하단이 급격히 움직일 수 있다. 기존 animation 의도를 유지할지 확인해야 한다.
- 자동 리뷰 요청은 시스템이 실제 팝업 표시를 보장하지 않으므로 counter와 build gate 중심으로 검증해야 한다.

## Verification

- 실행할 기본 빌드:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 필요 시 전체 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 수동 확인:
  - ATT 권한 상태를 초기화한 뒤 키보드 extension의 전체 접근 안내에서 `sykeyboard://` 흐름으로 진입해 Settings가 팝업 없이 열리는지 확인한다.
  - 일반 앱 실행에서는 온보딩 이후 정한 앱 내부 시점에 ATT 요청이 표시되는지 확인한다.
  - iPhone 세로 환경에서 광고 로드 후 `BannerView.adSize`, frame, SwiftUI 하단 영역이 일치하는지 확인한다.
  - 광고 실패 또는 오프라인 상태에서 하단 빈 공간이 남지 않는지 확인한다.

## Done Criteria

- 타당한 3개 항목이 코드로 수정된다.
- 리뷰 modifier 항목은 현재 코드 기준으로 범위 재정의 상태가 문서에 반영된다.
- `SYKeyboard` scheme 빌드가 통과하거나, 실행하지 못한 이유와 환경 오류가 기록된다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 7 상태가 갱신된다.
