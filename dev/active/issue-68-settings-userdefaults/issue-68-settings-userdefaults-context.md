# Issue 68 Settings UserDefaults Context

Last Updated: 2026-06-18

## Relevant Files

- `Modules/EnglishKeyboardCore/Storage/UserDefaultsManager+Extension.swift`: 자동 대문자 manager getter가 absent key에서 `DefaultValues.isAutoCapitalizationEnabled`를 반환한다.
- `Modules/EnglishKeyboardCore/Storage/DefaultValues+Extension.swift`: 자동 대문자 기본값은 `true`다.
- `SYKeyboard/Presentation/KeyboardSettings/InputSettingsView.swift`: 자동 대문자 설정 화면은 `@AppStorage` 기본값으로 `DefaultValues.isAutoCapitalizationEnabled`를 사용한다.
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`: `updateShiftButton()`이 `UserDefaultsManager.shared.isAutoCapitalizationEnabled`를 직접 읽는다.
- `SYKeyboard/App/SYKeyboardApp.swift`: 앱 시작 시 초기 Analytics user property가 자동 대문자 manager getter를 직접 읽는다.
- `SYKeyboard/Storage/AppUserDefaultsManager.swift`: 앱 전용 온보딩/리뷰 값을 App Group 저장소에서 읽고, absent key fallback을 `AppDefaultValues`와 일치시킨다.
- `SYKeyboard/Storage/AppDefaultValues.swift`: 앱 전용 온보딩/리뷰 기본값을 선언한다.
- `SYKeyboard/Storage/AppUserDefaultsKeys.swift`: 앱 전용 온보딩/리뷰 key 문자열을 선언한다.
- `SYKeyboard/Presentation/Content/ContentView.swift`: 온보딩 표시 여부를 앱 전용 key/default/manager로 읽는다.
- `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift`: 앱 리뷰 요청 counter와 마지막 요청 build를 앱 전용 key/default/manager로 읽는다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 조건부 action/gesture와 suggestion 설정이 대부분 `viewDidLoad()`에서 구성된다. lifecycle 로그 확인 결과 키보드 재표시 시 새 controller 인스턴스와 `viewDidLoad()` 재호출이 확인됐다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift`: 커서 드래그/길게 누르기 gesture 등록 조건을 정의한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`: lexicon/engine 준비 조건을 정의한다.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: `isPredictiveTextEnabled`, `isTextReplacementEnabled`, `isSuspended` 변경 시 엔진과 후보 상태를 관리한다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: Issue #68의 원본 findings 상태를 담고 있다.

## Facts Checked

- `gh issue view`는 GraphQL `projectCards` deprecation 오류로 실패했으나, `gh api repos/SNMac/SYKeyboard/issues/68`와 comments API로 이슈 본문 및 댓글 없음 상태를 확인했다.
- Issue #68 제목은 `[Task] 코드리뷰 Track 5 - Settings And UserDefaults Contract findings 처리`다.
- Issue #68 comments API 결과는 빈 배열이었다.
- `UserDefaultsWrapper`는 absent key fallback을 `defaultValue`로 맞추지만, P1/P3의 extension getter는 이를 사용하지 않는다.
- `isOnboarding`, `reviewCounter`, `lastBuildPromptedForReview` 사용처를 `rg`로 확인했다. 앱 타깃의 `ContentView`와 `RequestReviewViewModifier`에서만 쓰이며, 키보드 extension/Core 모듈 사용처는 확인되지 않았다.
- 앱 전용 온보딩/리뷰 key 문자열은 기존과 같은 `isOnboarding`, `reviewCounter`, `lastBuildPromptedForReview`를 유지했다.
- 앱 전용 `AppUserDefaultsManager`의 기본 저장소는 기존과 같은 `DefaultValues.groupBundleID` App Group suiteName을 사용한다.
- `BaseKeyboardViewController.viewDidLoad()`에서 `suggestionController.isTextReplacementEnabled`, `suggestionController.isPredictiveTextEnabled`를 설정하고, 일부 lexicon load와 `updateSuggestionBarHidden()`을 호출한다.
- lifecycle 로그로 키보드가 다시 표시될 때 기존 controller 인스턴스를 재사용하지 않고 새 인스턴스를 생성하며 `viewDidLoad()`를 다시 거치는 것을 확인했다.
- `BaseKeyboardViewController.viewWillAppear()`는 `setKeyboardHeight()`와 `FeedbackManager.shared.prepareHaptic()`만 수행한다.
- `addPeriodShortcutActionToSpaceButton(_:)`는 설정이 켜져 있을 때만 `.touchDownRepeat` action을 추가한다.
- `addGesturesToTextInterableButton(_:)`는 설정값에 따라 pan/long press recognizer를 추가하지만, 이후 제거/갱신 경로는 확인되지 않았다.
- `addGesturesToSwitchButton(_:)`는 숫자 키패드/한 손 모드 설정값에 따라 switch button gesture를 추가하지만, 이후 제거/갱신 경로는 확인되지 않았다.

## Decisions

- P1은 타당하다. 최초 설치의 absent key 상태에서 설정 화면과 manager getter의 계약이 서로 다르고, 영어 키보드 런타임과 초기 Analytics에 실제 영향이 있다.
- P2는 Invalid로 판단한다. 현재 관찰된 키보드 lifecycle에서는 controller 재사용 전제가 성립하지 않고, 재표시 시 새 인스턴스가 생성되어 `viewDidLoad()` 설정 구성을 다시 거친다.
- P3는 타당하다. 현재 사용자 영향은 낮지만 manager getter 계약이 기본값 선언과 다르며, 더 근본적으로 앱 전용 상태를 `SYKeyboardCore.UserDefaultsManager`에 확장한 모듈 경계가 어색하다.
- P3 구현은 단순 fallback 수정 대신 앱 전용 `AppUserDefaultsManager`/key/default로 분리한다. 저장 key 문자열과 App Group suiteName은 유지한다.
- `HangeulKeyboardCore`와 `EnglishKeyboardCore`가 `SYKeyboardCore.UserDefaultsManager`를 쓰는 구조는 유지한다. 두 모듈이 읽는 값은 키보드 extension 런타임의 공유 설정이므로 Core manager 의존이 타당하다.
- 구현 계획은 P1의 기본값 fallback과 P3의 앱 전용 저장소 분리만 진행한다. P2의 action/gesture 재동기화는 구현하지 않는다.

## Open Questions

- 현재 없음.

## Verification Notes

- 실행한 명령:

```sh
git status --short
```

- 결과: 작업 시작 시점에는 출력 없음.
- 실행한 명령:

```sh
gh api repos/SNMac/SYKeyboard/issues/68
gh api repos/SNMac/SYKeyboard/issues/68/comments
```

- 결과: 이슈 본문 확인, 댓글 없음 확인.
- 추가 확인:

```sh
rg -n "isOnboarding|reviewCounter|lastBuildPromptedForReview|UserDefaultsManager\\.shared\\.(isOnboarding|reviewCounter|lastBuildPromptedForReview)|DefaultValues\\.(isOnboarding|reviewCounter|lastBuildPromptedForReview)|UserDefaultsKeys\\.(isOnboarding|reviewCounter|lastBuildPromptedForReview)" .
```

- 결과: 앱 전용 온보딩/리뷰 값은 `SYKeyboard/Presentation/Content/ContentView.swift`, `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift`, `SYKeyboard/Storage/*+Extension.swift`에서만 확인됐다. 키보드 모듈 사용처는 확인되지 않았다.
- 추가 확인: `BaseKeyboardViewController` lifecycle 로그로 키보드 재표시 시 새 controller 인스턴스 생성과 `viewDidLoad()` 재호출을 확인했다. 이 근거로 P2는 `Invalid` 처리한다.
- TDD red 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

- 일반 샌드박스 결과: CoreSimulator/Xcode 캐시 권한 오류로 실패했다.
- 권한 있는 환경의 구현 전 결과: `AppUserDefaultsManager`, `AppDefaultValues`, `AppUserDefaultsKeys` 미정의 compile error로 실패했다.
- 구현 후 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

- 결과: 권한 있는 환경에서 `TEST SUCCEEDED`.
- 전체 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 결과: 권한 있는 환경에서 `TEST SUCCEEDED`.
- 키보드 extension 빌드:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 결과: 권한 있는 환경에서 두 빌드 모두 `BUILD SUCCEEDED`.
