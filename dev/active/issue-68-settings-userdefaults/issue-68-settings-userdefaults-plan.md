# Issue 68 Settings UserDefaults Plan

Last Updated: 2026-06-18

## Goal

- GitHub Issue #68의 `Settings And UserDefaults Contract` 리뷰 항목 3개를 검증하고, 타당한 항목을 기본값 계약과 앱 전용 저장소 경계 관점에서 수정한다.

## Current State

- Issue #68 본문에는 P1/P2/P3 세 항목이 있으며 댓글은 없다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 5 원문과 Issue #68 내용은 같은 세 항목을 가리킨다.
- 현재 워킹트리는 작업 시작 시점 기준 깨끗했다.
- 구현 결과 P1/P3는 수정 및 검증을 완료했고, P2는 lifecycle 로그 근거로 Invalid 처리했다.

### Reviewed Items

- [타당] P1: 최초 설치에서 자동 대문자 기본값이 설정 화면과 영어 키보드 런타임에서 다르게 해석됨.
  - `DefaultValues.isAutoCapitalizationEnabled == true`
  - `InputSettingsView`의 `@AppStorage` 기본값도 `true`
  - `UserDefaultsManager.isAutoCapitalizationEnabled` getter는 absent key에서 `storage.bool(forKey:) == false`를 반환한다.
  - `EnglishKeyboardCoreViewController.updateShiftButton()`과 앱 초기 Analytics가 manager getter를 직접 읽으므로 실제 영향이 있다.
- [Invalid] P2: 기존 키보드 컨트롤러 인스턴스가 재사용될 때 `viewDidLoad()`에서만 구성한 설정 일부가 최신 저장값과 어긋날 수 있음.
  - 실제 lifecycle 로그 확인 결과 키보드가 다시 표시될 때 기존 controller 인스턴스를 재사용하지 않고 새 인스턴스를 생성하며 `viewDidLoad()`를 다시 거친다.
  - 따라서 현재 관찰된 환경에서는 stale 설정 전제가 성립하지 않는다.
  - action/gesture 재동기화 로직을 `viewWillAppear()`에 추가하면 중복 등록/제거와 입력 타이밍 회귀 위험이 생기므로 구현하지 않는다.
- [타당] P3: 앱 전용 UserDefaults 상태의 모듈 경계와 기본값 계약 정리.
  - `DefaultValues.isOnboarding == true`
  - `ContentView`는 `@AppStorage` 기본값을 사용하므로 현재 첫 화면 영향은 낮다.
  - `UserDefaultsManager.isOnboarding` getter는 absent key에서 `false`를 반환하므로 manager 계약은 불일치한다.
  - 추가 판단: `isOnboarding`, `reviewCounter`, `lastBuildPromptedForReview`는 앱 타깃에서만 쓰이므로 `SYKeyboardCore.UserDefaultsManager` 확장이 아니라 앱 전용 UserDefaults manager로 분리하는 편이 모듈 경계에 맞다.

## Approach

1. 기본값 계약과 저장소 경계 수정
   - `Modules/EnglishKeyboardCore/Storage/UserDefaultsManager+Extension.swift`의 `isAutoCapitalizationEnabled` getter를 absent-key fallback이 `DefaultValues.isAutoCapitalizationEnabled`가 되도록 수정한다.
   - 앱 전용 `AppUserDefaultsManager`, `AppUserDefaultsKeys`, `AppDefaultValues`를 `SYKeyboard/Storage/`에 둔다.
   - `isOnboarding`, `reviewCounter`, `lastBuildPromptedForReview`는 앱 전용 manager/key/default로 옮긴다.
   - 기존 key 문자열은 유지해서 기존 사용자 데이터 위치와 의미를 보존한다.
   - 저장 컨테이너는 기존처럼 App Group `UserDefaults(suiteName: DefaultValues.groupBundleID)`를 사용해 데이터 위치 변경을 피한다.
   - `SYKeyboard/Storage/UserDefaultsManager+Extension.swift`, `UserDefaultsKeys+Extension.swift`, `DefaultValues+Extension.swift`는 앱 전용 타입으로 대체하거나 더 이상 필요 없으면 제거한다.
   - `HangeulKeyboardCore`와 `EnglishKeyboardCore`가 `SYKeyboardCore.UserDefaultsManager`를 쓰는 구조는 유지한다. 두 모듈의 설정값은 키보드 extension 런타임에서 실제로 읽는 공유 키보드 설정이다.

2. 테스트와 문서 반영
   - 기본값 계약 테스트를 추가해 absent key에서 자동 대문자 manager getter가 `DefaultValues`와 일치하는지 검증한다.
   - 앱 전용 저장소 타입은 `ContentView`, `RequestReviewViewModifier`가 앱 전용 key/default/manager를 사용하도록 컴파일 검증한다.
   - P2는 `dev/active/code-review-scope/code-review-scope-findings.md`에서 `Invalid`로 갱신한다.
   - 수정 후 `dev/active/code-review-scope/code-review-scope-findings.md`에서 P1/P3 항목을 `Resolved`로 갱신한다.

## Risks

- 앱 전용 저장소 타입을 만들 때 저장 key 문자열이나 suiteName을 바꾸면 기존 온보딩/리뷰 상태가 초기화될 수 있다. key 문자열과 App Group suiteName은 유지한다.

## Verification

실행할 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

수동 확인이 필요한 경우:

- P2는 현재 관찰된 lifecycle에서 기존 controller 재사용 전제가 성립하지 않아 수정하지 않는다. 동일 환경에서 키보드가 새 인스턴스를 생성하고 `viewDidLoad()`를 거치는지 lifecycle 로그로 확인했다.

검증 결과:

- 권한 있는 환경에서 `UserDefaultsContractTests` targeted 테스트가 `TEST SUCCEEDED`.
- 권한 있는 환경에서 전체 `SYKeyboard` 테스트가 `TEST SUCCEEDED`.
- 권한 있는 환경에서 `HangeulKeyboard`, `EnglishKeyboard` 빌드가 모두 `BUILD SUCCEEDED`.

## Done Criteria

- P1 manager getter가 absent key에서 선언된 기본값을 반환한다.
- P3 앱 전용 온보딩/리뷰 상태가 `SYKeyboardCore.UserDefaultsManager` 확장에서 분리되고, 기존 key 문자열과 저장 컨테이너를 유지한다.
- P2가 lifecycle 확인 근거와 함께 `Invalid`로 문서화된다.
- 관련 테스트 또는 빌드가 통과하거나, 실행 불가 사유가 기록된다.
- Issue #68 체크리스트와 findings 문서 상태를 실제 처리 결과와 맞춘다.
