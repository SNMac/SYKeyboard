# Issue 69 Keyboard Entry Points Plan

Last Updated: 2026-06-19

## Goal

- GitHub Issue #69의 Track 6 `Keyboard Extension Entry Points` findings가 현재 코드에서 타당한지 판단하고, 타당한 항목의 수정 계획과 검증 기준을 정한다.

## Current State

- 관련 이슈: `https://github.com/SNMac/SYKeyboard/issues/69`
- 관련 findings 문서: `dev/active/code-review-scope/code-review-scope-findings.md`
- 처리한 finding:
  - `[P2] 전체 접근 미허용 상태에서 오버레이 닫힘 상태를 공유 컨테이너에 저장함`
  - `[P2] EnglishKeyboard target에 app-extension-safe API 검사가 비활성화되어 있음`
- 관련 파일:
  - `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift`
  - `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
  - `Modules/SYKeyboardCore/Storage/KeyboardExtensionLocalStateStore.swift`
  - `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
  - `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
  - `SYKeyboard.xcodeproj/project.pbxproj`

## Review Evaluation

### Finding 1: 전체 접근 미허용 상태에서 오버레이 닫힘 상태를 공유 컨테이너에 저장함

- 판단: 타당함.
- 근거:
  - `BaseKeyboardViewController.needToShowFullAccessGuide`는 `!hasFullAccess && !keyboardSettingsManager.isRequestFullAccessOverlayClosed`를 사용한다.
  - 한글/영문 close action은 모두 `keyboardSettingsManager.isRequestFullAccessOverlayClosed = true`를 호출한다.
  - `UserDefaultsManager`와 `UserDefaultsWrapper`는 `UserDefaults(suiteName: DefaultValues.groupBundleID)` 기반 app-group 저장소를 사용한다.
  - keyboard extension의 전체 접근 미허용 상태에서는 app-group 공유 컨테이너 접근이 제한될 수 있으므로, 닫힘 상태가 다음 extension 세션에 유지되지 않을 위험이 있다.
- 결정: 닫힘 상태는 각 keyboard extension의 `UserDefaults.standard`에 저장한다. 한글/영문은 독립 상태를 유지한다. app-group 값과 동기화하거나 migration하지 않는다.

### Finding 2: EnglishKeyboard target에 app-extension-safe API 검사가 비활성화되어 있음

- 판단: 타당함.
- 근거:
  - `SYKeyboard.xcodeproj/project.pbxproj`의 `HangeulKeyboard` Debug/Release에는 `APPLICATION_EXTENSION_API_ONLY = YES`가 있다.
  - 같은 역할의 `EnglishKeyboard` Debug/Release에는 해당 설정이 없다.
  - 이 차이는 영어 extension에 app-extension-safe API 검사가 빠지는 구성 불일치다.
- 결정: `EnglishKeyboard` Debug/Release build settings에 `APPLICATION_EXTENSION_API_ONLY = YES`를 추가한다.

## Approach

1. 오버레이 닫힘 상태 저장소를 extension-local로 분리했다.
   - `Modules/SYKeyboardCore/Storage/KeyboardExtensionLocalStateStore.swift`를 추가하고 기본 저장소를 `UserDefaults.standard`로 뒀다.
   - 테스트에서는 별도 suite를 주입해 shared app-group 저장소에 쓰지 않는 계약을 검증했다.
   - `needToShowFullAccessGuide`와 한글/영문 close action은 local store를 사용한다.
2. EnglishKeyboard target build settings를 한글 target과 맞췄다.
   - Debug/Release 양쪽에 `APPLICATION_EXTENSION_API_ONLY = YES`를 추가했다.
3. 문서 상태를 갱신했다.
   - `dev/active/code-review-scope/code-review-scope-findings.md`의 두 항목을 `Resolved`로 변경하고 처리/검증 결과를 기록했다.
   - 이 작업 문서의 tasks/context도 실제 결과로 갱신했다.

## Risks

- 오버레이 표시 여부는 extension entry point에서 결정되므로 실제 키보드 extension lifecycle과 전체 접근 미허용 상태에서 수동 확인이 필요하다.
- `APPLICATION_EXTENSION_API_ONLY = YES` 추가 후 EnglishKeyboard 빌드가 app-extension-unsafe API 사용을 새로 드러낼 수 있다. 이 경우 build setting만 추가하고 끝내지 말고, 실제 unsafe API 사용 여부를 별도 판단한다.
- `Keyboards/Common`에 새 파일을 추가할 경우 target membership이 의도대로 한글/영문 extension에만 적용되는지 확인해야 한다.

## Verification

- 실행한 자동 검증:

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

- 추가 실행:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

- 결과:
  - 일반 샌드박스의 focused 테스트는 Xcode/SwiftPM/CoreSimulator 캐시 권한 오류로 실패했다.
  - rename 작업에서 테스트를 먼저 `KeyboardExtensionLocalStateStore`로 바꾼 뒤, 권한 있는 환경에서 local state store 타입 미정의 compile error로 RED를 확인했다.
  - 권한 있는 환경의 focused `UserDefaultsContractTests`는 `TEST SUCCEEDED`.
  - 권한 있는 환경의 `HangeulKeyboard` build는 `BUILD SUCCEEDED`.
  - 권한 있는 환경의 `EnglishKeyboard` build는 `BUILD SUCCEEDED`.
  - 권한 있는 환경의 전체 `SYKeyboard` test는 `TEST SUCCEEDED`.

- 수동 확인:
  - 전체 접근 미허용 상태에서 한글 키보드 오버레이를 닫고 extension을 종료/재실행했을 때 닫힘 상태가 유지된다.
  - 전체 접근 미허용 상태에서 영어 키보드 오버레이를 닫고 extension을 종료/재실행했을 때 닫힘 상태가 유지된다.
  - 한글에서 닫아도 영어의 닫힘 상태가 자동으로 닫히지 않고, 영어에서 닫아도 한글의 닫힘 상태가 자동으로 닫히지 않는다.
  - 2026-06-19 사용자 실기기 확인에서 정상 동작을 확인했다.

## Done Criteria

- 두 P2 finding의 코드 수정이 적용되었다.
- `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드 결과가 기록되었다.
- 전체 접근 미허용 상태의 오버레이 닫힘 유지 동작은 사용자 실기기 확인 결과를 기록했다.
- `dev/active/code-review-scope/code-review-scope-findings.md`와 이 작업 문서가 실제 처리 상태를 반영한다.
