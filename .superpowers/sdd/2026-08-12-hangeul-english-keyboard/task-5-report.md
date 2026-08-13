# Task 5 실행 보고서

## 상태

완료 — TDD RED, adapter/Smart Punctuation GREEN, `EnglishKeyboard` extension build를 확인했다.

## 구현 범위

- `EnglishKeyboardInputAdapter`가 `EnglishKeyboardView`, 대문자 입력 플래그, Shift/CapsLock, 자동 대문자와 영어 layout 상태를 소유하도록 구현했다.
- 전용 `EnglishKeyboardCoreViewController`는 adapter의 `primaryKeyboardView`, layout, 입력 후 Shift, 자동 대문자 API를 호출한다.
- 기존 `super` 호출 순서, `insertTypedText`, `treatsDefaultSmartQuotesAsEnabled == false`, `.englishSystem`, `buttonStateController.isShiftButtonPressed` guard 의미를 유지했다.
- 테스트는 production adapter와 실제 `EnglishKeyboardView` 상태를 사용하며 `Mirror`나 private view hierarchy를 사용하지 않는다.

## 검증 결과

### RED

기본 sandbox 실행은 CoreSimulator/SwiftPM cache 권한 오류로 컴파일 전에 종료되었다(exit 74). 같은 명령을 권한 있는 환경에서 실행해 exit 65와 `Cannot find 'EnglishKeyboardInputAdapter' in scope`를 확인했다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/KeyboardSmartInputPolicyTests
```

- RED 전체 로그: `/Users/macmillan/Library/Application Support/rtk/tee/1786554015_xcodebuild_test_-project_SYKeyboard_xcod.log`

### 중간 진단

구현 후 첫 runtime 실행은 컴파일을 통과했다. `KeyboardSmartInputPolicyTests` 13개는 모두 통과했지만 `EnglishKeyboardInputAdapterTests` 3개는 0.000초에 공통 실패하고 runner가 재시작했다. 기존 UIKit view suite와 비교해 새 suite에만 빠진 `@MainActor` 격리를 추가했다.

- 실패 xcresult: `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_02-05-08-+0900.xcresult`
- 실패 전체 로그: `/Users/macmillan/Library/Application Support/rtk/tee/1786554473_xcodebuild_test_-project_SYKeyboard_xcod.log`
- 정적 검증: `git diff --check` 통과

### GREEN

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/KeyboardSmartInputPolicyTests
```

- 결과: 고유 16/16 passed, failed 0, skipped 0
- destination: iPhone 13 mini / iOS 16.0 (arm64)
- xcresult: `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_20-28-46-+0900.xcresult`

### BUILD

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 결과: exit 0, `** BUILD SUCCEEDED **`
- build log: `/Users/macmillan/Library/Application Support/rtk/tee/1786620655_xcodebuild_build_-project_SYKeyboard_xco.log`

## 변경 파일

- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift`
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
- `SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift`
- `SYKeyboard.xcodeproj/project.pbxproj`
- `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`
- `.superpowers/sdd/2026-08-12-hangeul-english-keyboard/task-5-report.md`

`EnglishKeyboardView.swift`와 `EnglishKeyboardLayoutProvider.swift`는 같은 모듈 내부 adapter가 기존 internal API로 소유할 수 있어 접근 수준을 추가로 열지 않았다.
