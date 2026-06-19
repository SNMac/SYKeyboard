# Issue 70 Track 7 Review Context

Last Updated: 2026-06-19

## Relevant Files

- `SYKeyboard/App/SYKeyboardApp.swift`: 앱 lifecycle, custom URL 처리, ATT 권한 요청이 있다.
- `SYKeyboard/App/AppTrackingAuthorizationPolicy.swift`: 온보딩/설정 redirect 상태에 따른 ATT 요청 정책을 제공한다.
- `SYKeyboard/Presentation/KeyboardSettings/InitialSettingsView.swift`: 메인 앱 내부의 시스템 설정 이동 버튼이다.
- `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift`: 키보드 extension에서 `sykeyboard://`를 여는 경로가 있다.
- `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift`: 키보드 extension에서 `sykeyboard://`를 여는 경로가 있다.
- `SYKeyboard/Presentation/Content/ContentView.swift`: 광고 safe area와 onboarding sheet를 구성한다.
- `SYKeyboard/Presentation/Content/BannerAd/BannerAdView.swift`: AdMob `BannerView`를 SwiftUI에 연결한다.
- `SYKeyboard/Presentation/Content/BannerAd/BannerAdLayoutPolicy.swift`: 광고 수신 상태에 따른 safe-area container 높이를 계산한다.
- `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift`: 자동 리뷰 요청 counter와 build gate를 관리한다.
- `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewPolicy.swift`: 자동 리뷰 카운트와 요청 판단 정책을 순수 함수로 제공한다.
- `SYKeyboard/Presentation/Utils/Extensions/View+Extension.swift`: 자동 리뷰 카운트/상세 복귀 요청 helper를 제공한다.
- `SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift`: 리뷰 modifier가 적용된 상세 설정 화면이다.
- `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`: 리뷰 modifier가 적용된 상세 설정 화면이다.
- `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift`: 리뷰 modifier가 적용된 상세 설정 화면이다.
- `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`: 리뷰 modifier가 적용된 상세 설정 화면이다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: Issue #70의 원본 findings 상태를 관리한다.

## Facts Checked

- `gh api repos/SNMac/SYKeyboard/issues/70`로 이슈 본문을 확인했다.
- 이슈 #70에는 댓글이 없고, 본문에 Track 7의 4개 P2 항목과 체크리스트가 있다.
- `SYKeyboard/App/SYKeyboardApp.swift`는 `.onOpenURL`에서 `UIApplication.openSettingsURLString`을 열고, `didBecomeActive`에서 ATT `.notDetermined`이면 권한 요청을 시작한다.
- `rg` 확인 결과 `ATTrackingManager.requestTrackingAuthorization()` 호출은 `SYKeyboard/App/SYKeyboardApp.swift` 한 곳뿐이다.
- `ContentView`는 광고 수신 여부와 무관하게 `safeAreaInset` 내부에 `BannerAdView`를 배치하고 `adSize.size.height`를 frame 높이로 사용한다.
- `BannerAdView.updateUIView(_:context:)`는 비어 있다.
- `BannerAdCoordinator`는 광고 수신 성공 시 `isAdReceived = true`, 실패 시 `isAdReceived = false`로 상태를 전파한다.
- `requestReviewViewModifier()` 호출은 4개 상세 설정 화면에 존재한다.
- `dev/active/code-review-scope/code-review-scope-findings.md`에는 Track 7의 4개 항목이 `[Open]`으로 남아 있다.
- 자동 리뷰 요청 기준 보정 후 앱 실행은 카운트만 증가시키고, 상세 설정 화면 복귀는 카운트 증가 후 요청 여부를 판단한다.
- 자동 리뷰 요청 threshold는 30회다.
- `AppTrackingAuthorizationPolicy`는 온보딩 중이거나 설정 redirect 처리 중이면 ATT 요청을 하지 않는다. 설정 redirect 상태는 다음 active notification에서 해제한다.
- 온보딩 모달을 닫아 `isOnboarding == false`가 되는 시점에는 설정 redirect 중이 아닐 때만 ATT 요청을 수행한다.
- `BannerAdView.updateUIView(_:context:)`는 `BannerView.adSize.size`가 새 `adSize.size`와 다를 때 `adSize`를 갱신하고 광고를 다시 요청한다.
- `BannerAdLayoutPolicy`는 광고 미수신 상태의 container 높이를 0으로 계산한다.

## Decisions

- ATT/deep link 항목은 수정 대상으로 본다.
- adaptive banner 크기 갱신 항목은 수정 대상으로 본다.
- 광고 실패 시 빈 하단 safe area 항목은 수정 대상으로 본다.
- 자동 리뷰 요청 modifier 항목은 현재 코드 기준으로 “미연결” finding이 성립하지 않는다. 범위를 “상세 설정 화면에만 묶인 카운트 기준 보정”으로 재정의하고, 앱 실행도 카운트에 포함하도록 수정했다.
- ATT/deep link 항목은 온보딩/설정 redirect guard 정책으로 수정했다. 최초 온보딩 사용자는 모달을 닫은 직후 ATT를 보고, `sykeyboard://` 설정 이동 중에는 ATT를 보지 않는다.
- adaptive banner 크기 갱신 항목은 `updateUIView`에서 size 변경을 비교해 다시 load하는 방식으로 수정했다.
- 광고 실패 시 빈 하단 safe area 항목은 광고 수신 상태에 따라 container 높이를 0/실제 광고 높이로 전환하는 방식으로 수정했다.

## Open Questions

- 자동 리뷰 요청은 앱 실행과 상세 설정 복귀를 카운트 기준으로 삼고, 요청 판단은 상세 설정 복귀 시점에만 수행한다.

## Verification Notes

- 실행한 명령:

```sh
git status --short
gh api repos/SNMac/SYKeyboard/issues/70
sed -n '1,220p' SYKeyboard/App/SYKeyboardApp.swift
sed -n '1,220p' SYKeyboard/Presentation/Content/ContentView.swift
sed -n '1,220p' SYKeyboard/Presentation/Content/BannerAd/BannerAdView.swift
sed -n '1,180p' SYKeyboard/Presentation/Content/BannerAd/BannerAdCoordinator.swift
rg -n "requestReviewViewModifier|RequestReviewViewModifier|reviewCounter|requestReview|SKStoreReviewController|Review" SYKeyboard Modules Keyboards SYKeyboardTests
rg -n "AppTrackingTransparency|ATTrackingManager|trackingAuthorizationStatus|requestTrackingAuthorization" SYKeyboard Keyboards Modules SYKeyboardTests
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- `gh issue view 70 --repo SNMac/SYKeyboard --comments`는 GitHub GraphQL의 classic Projects deprecation 오류로 실패했다.
- 같은 이슈 본문은 `gh api repos/SNMac/SYKeyboard/issues/70`로 확인했다.
- 자동 리뷰 요청 정책 테스트 추가 후 `xcodebuild test`가 통과했다.
- 일반 샌드박스의 `xcodebuild build`는 `CoreSimulatorService connection became invalid`, SwiftPM/clang cache `Operation not permitted` 오류로 실패했다.
- 같은 `xcodebuild build` 명령을 권한 있는 실행으로 재시도해 `BUILD SUCCEEDED`를 확인했다.
- ATT/banner 정책 테스트 추가 후 `xcodebuild test`를 다시 실행했고 `TEST SUCCEEDED`를 확인했다.
- ATT/banner 수정 후 일반 샌드박스의 `xcodebuild build`는 동일한 권한 오류로 실패했고, 권한 있는 실행으로 재시도해 `BUILD SUCCEEDED`를 확인했다.
- 온보딩 dismissal ATT 정책 테스트 추가 후 `xcodebuild test`를 다시 실행했고 `TEST SUCCEEDED`를 확인했다.
