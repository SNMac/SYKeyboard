# Issue 69 Keyboard Entry Points Context

Last Updated: 2026-06-19

## Relevant Files

- `dev/active/code-review-scope/code-review-scope-findings.md`: Track 6 findings 원문과 현재 상태.
- `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift`: 한글 keyboard extension entry point. 전체 접근 오버레이 표시와 닫기 action을 갖는다.
- `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift`: 영어 keyboard extension entry point. 한글과 동일한 전체 접근 오버레이 표시와 닫기 action을 갖는다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: `needToShowFullAccessGuide`가 `hasFullAccess`와 shared `UserDefaultsManager` 값을 함께 본다.
- `Modules/SYKeyboardCore/Storage/KeyboardExtensionLocalStateStore.swift`: keyboard extension별 local 상태를 `UserDefaults.standard`에 저장하는 새 저장소.
- `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`: `UserDefaults(suiteName: DefaultValues.groupBundleID)` 기반 app-group 저장소를 사용한다.
- `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`: `isRequestFullAccessOverlayClosed` key 문자열을 정의한다.
- `Modules/SYKeyboardCore/Storage/DefaultValues.swift`: `isRequestFullAccessOverlayClosed` 기본값을 `false`로 정의한다.
- `SYKeyboard.xcodeproj/project.pbxproj`: Hangeul/English extension target build settings를 정의한다.

## Facts Checked

- GitHub Issue #69의 본문을 `gh api repos/SNMac/SYKeyboard/issues/69`로 확인했다.
- Issue #69 댓글 API는 빈 배열이었다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 6에는 두 P2 항목이 `Open` 상태로 남아 있다.
- `HangeulKeyboardViewController.swift:38`과 `EnglishKeyboardViewController.swift:38`은 `needToShowFullAccessGuide`가 참이면 오버레이를 추가한다.
- `HangeulKeyboardViewController.swift:70`과 `EnglishKeyboardViewController.swift:70`은 닫기 action에서 `keyboardSettingsManager.isRequestFullAccessOverlayClosed = true`를 기록한다.
- `BaseKeyboardViewController.swift:31-32`는 `!hasFullAccess && !keyboardSettingsManager.isRequestFullAccessOverlayClosed`로 오버레이 표시 필요 여부를 계산한다.
- `UserDefaultsManager.swift:19-24`, `UserDefaultsManager.swift:87-88`은 app-group suiteName 기반 `UserDefaults`를 사용한다.
- `UserDefaultsManager.swift:180-181`은 `isRequestFullAccessOverlayClosed`를 shared manager property로 제공한다.
- `SYKeyboard.xcodeproj/project.pbxproj:1418`, `SYKeyboard.xcodeproj/project.pbxproj:1452`에는 HangeulKeyboard Debug/Release의 `APPLICATION_EXTENSION_API_ONLY = YES`가 있다.
- `SYKeyboard.xcodeproj/project.pbxproj:1485-1511`, `SYKeyboard.xcodeproj/project.pbxproj:1519-1545`에는 EnglishKeyboard Debug/Release의 `APPLICATION_EXTENSION_API_ONLY` 설정이 없다.
- `Keyboards/HangeulKeyboard/Resources/HangeulKeyboard.entitlements`와 `Keyboards/EnglishKeyboard/Resources/EnglishKeyboard.entitlements`는 둘 다 같은 app group을 선언한다.
- `KeyboardExtensionLocalStateStore`는 기본 저장소로 `UserDefaults.standard`를 사용하고, 테스트에서는 별도 suite를 주입할 수 있다.
- `BaseKeyboardViewController.needToShowFullAccessGuide`는 이제 shared `UserDefaultsManager`가 아니라 `keyboardExtensionLocalStateStore.isClosed`를 본다.
- 한글/영문 overlay close action은 이제 `keyboardExtensionLocalStateStore.isClosed = true`를 기록한다.
- EnglishKeyboard Debug/Release build settings에 `APPLICATION_EXTENSION_API_ONLY = YES`를 추가했다.
- 오버레이 전용 local store 이름은 확장별 local 상태가 늘어날 가능성을 반영해 `KeyboardExtensionLocalStateStore`로 변경했다.

## Decisions

- 두 P2 finding은 현재 코드 기준으로 타당하다.
- 오버레이 닫힘 상태는 app-group 저장소가 아니라 각 extension의 `UserDefaults.standard`에 저장한다.
- 한글/영문 오버레이 닫힘 상태는 서로 독립적으로 유지한다.
- app-group 저장소와 extension-local 저장소 사이 migration은 하지 않는다.
- EnglishKeyboard target도 HangeulKeyboard target과 동일하게 `APPLICATION_EXTENSION_API_ONLY = YES`를 적용한다.
- local state store 타입은 오버레이 전용 이름이 아니라 keyboard extension별 local 상태를 담을 수 있는 `KeyboardExtensionLocalStateStore`를 사용한다.

## Open Questions

- 현재 없음.

## Verification Notes

- 실행함:

```sh
git status --short
```

결과: 출력 없음. 작업 전 tracked/untracked 변경 없음.

- 실행함:

```sh
gh issue view 69 --repo SNMac/SYKeyboard --comments
```

결과: 샌드박스 네트워크 제한으로 실패.

- 실행함:

```sh
gh api repos/SNMac/SYKeyboard/issues/69
gh api repos/SNMac/SYKeyboard/issues/69/comments
```

결과: 권한 있는 실행에서 이슈 본문 확인 성공. 댓글은 빈 배열.

- 실행함:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

결과:
- 일반 샌드박스: CoreSimulatorService, ModuleCache, SwiftPM ManifestLoading 권한 오류로 실패.
- 권한 있는 실행, 구현 전: local state store 타입 미정의로 실패해 RED 확인.
- 권한 있는 실행, 구현 후 target membership 추가 전: Core target에서 같은 타입 미정의로 실패.
- 권한 있는 실행, target membership 추가 후: `TEST SUCCEEDED`.
- rename 작업 중 테스트를 먼저 `KeyboardExtensionLocalStateStore`로 변경한 뒤, 권한 있는 실행에서 `cannot find 'KeyboardExtensionLocalStateStore' in scope` compile error로 RED를 확인했다.
- rename 적용 후 같은 focused 테스트를 권한 있는 실행에서 재실행해 `TEST SUCCEEDED`를 확인했다.

- 실행함:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 권한 있는 실행에서 `BUILD SUCCEEDED`.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 권한 있는 실행에서 `BUILD SUCCEEDED`.

- 실행함:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 권한 있는 실행에서 `TEST SUCCEEDED`.

- 수동 검증:
  - 2026-06-19 사용자 실기기 확인에서 전체 접근 미허용 상태의 한글/영문 오버레이 닫힘 유지 동작이 정상이라고 확인했다.
