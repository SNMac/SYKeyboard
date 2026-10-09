# 한영 통합 키보드 Core VC 추출 설계

- 이슈: #190
- 날짜: 2026-10-09
- 목적: `HangeulEnglishKeyboardViewController`의 입력 로직을 새 static framework
  `HangeulEnglishKeyboardCore`의 `HangeulEnglishKeyboardCoreViewController`로 옮긴다.
  extension의 VC는 다른 두 키보드처럼 Firebase 설정과 메모리 경고 로그만 가진 껍데기가 된다.
  **동작은 바꾸지 않는다.**

## 배경

| VC | 위치 | 줄 수 | 단위 테스트 |
|---|---|---|---|
| `HangeulKeyboardCoreViewController` | `Modules/HangeulKeyboardCore/` | 354 | 가능 |
| `EnglishKeyboardCoreViewController` | `Modules/EnglishKeyboardCore/` | 162 | `EnglishKeyboardCoreViewControllerProxyReadTests` |
| `HangeulEnglishKeyboardViewController` | `Keyboards/HangeulEnglishKeyboard/` | 635 | **0개** |

extension 타깃은 모듈이 아니라 `SYKeyboardTests`가 import할 수 없다. 한영 VC의 테스트는
`HangeulEnglishKeyboardModeCoordinator`·`KeyboardLanguageModePolicy` 같은 순수 타입에만 있다.

`HangeulKeyboardCore`와 `EnglishKeyboardCore`를 둘 다 import하는 코드는 Core 모듈에 없다.
두 어댑터를 함께 쓰는 곳은 이 VC뿐이므로 Core VC를 둘 자리가 없다.

### 검토한 대안

1. **새 프레임워크 타깃 `HangeulEnglishKeyboardCore`** (채택). 다른 두 키보드와 같은 모양이 되고
   테스트 타깃이 import할 수 있다. 비용은 `project.pbxproj` 편집이다.
2. `HangeulKeyboardCore`에 두고 `EnglishKeyboardCore` 의존 추가. 한글 Core가 영어 Core를 의존하는
   비대칭이 생긴다. 기각.
3. extension 타깃 안에서 파일만 둘로 나누기. "Core"라는 이름이 거짓이 되고 테스트 가능성도 생기지
   않는다. 기각.

## 1. 모듈과 파일 배치

새 타깃 `HangeulEnglishKeyboardCore`는 `SYKeyboardCore`, `HangeulKeyboardCore`, `EnglishKeyboardCore`를
의존한다. 디렉터리는 `HangeulKeyboardCore` 모양을 따른다.

```
Modules/HangeulEnglishKeyboardCore/
└── Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift
```

leaf VC는 지금 자리 그대로 둔다.
`Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`가
`HangeulEnglishKeyboardCoreViewController`를 상속하는 껍데기가 된다.
`.docc`는 만들지 않는다. 기존 두 모듈의 `.docc`도 손대지 않은 템플릿이다.

## 2. Core VC와 leaf VC의 책임

### Core로 가는 것

Firebase를 건드리지 않는 전부다.

- 저장 프로퍼티: `hangeulAdapter`, `englishAdapter`, `initialLanguageMode`, `modeCoordinator`
- `init()`: 언어 모드 결정, `SwitchButton.previewPrimaryLanguage`,
  `super.init(language:nGramLanguage:)`, `primaryLanguage` 설정
- `viewDidLoad()`
- 모든 `override` 프로퍼티·메서드(`primaryKeyboardViews`부터 `deleteButtonPanDidStop`까지)
- `// MARK: - Language Mode` 절(`languageSwitchButtons`, `storedLanguageMode()`,
  `setupLanguageSwitchActions()`, `applyLanguageMode(...)`)
- `// MARK: - Adapter Routing` 절

접근 제어는 기존 Core VC 둘과 같다. 클래스는 `open class`, `init`은 `public init()`,
`required init?(coder:)`는 `@MainActor required public init?(coder:)`, 오버라이드는 `open override`.
private extension은 그대로 `private`이다.

### leaf에 남는 것

- `logger`
- `override init()` → `super.init()` 뒤 `setupFirebase()`
- `didReceiveMemoryWarning()`
- `setupFirebase()`
- `recordLanguageModeDecision`의 Crashlytics 호출(아래 훅)

### 진단 훅

지금 `inputTraitsDidChange()`는 `recordLanguageModeDecision(requiresLatinInput:resolved:)`를 불러
`logger.info`, `Crashlytics.log`, `Crashlytics.setCustomValue`를 호출한다. Core 모듈은 Firebase를
import하지 않으므로 이 로직을 옮길 수 없다. Core VC에 빈 `open` 훅을 둔다.

```swift
/// 시작 언어 판정 근거를 남길 자리. Core는 Firebase를 모르므로 extension이 구현한다
open func languageModeDecisionDidResolve(
    requiresLatinInput: Bool,
    resolved: HangeulEnglishLanguageMode
) {}
```

Core의 `inputTraitsDidChange()`가 지금 `recordLanguageModeDecision`을 부르던 바로 그 자리
(`applyLanguageMode` 호출 **앞**)에서 이 훅을 부른다. leaf가 오버라이드해 현재
`recordLanguageModeDecision` 본문을 글자 그대로 실행한다. 호출 순서와 기록 내용이 바뀌지 않고,
진단 코드가 Firebase가 있는 extension에 머문다. `didReceiveMemoryWarning`과 같은 배치다.

leaf 훅이 읽는 `textDocument.documentInputMode`·`keyboardType`·`textContentType`은
`textDidChange`의 `withReadCaching` 범위 안이라 추가 프록시 읽기가 생기지 않는다.

## 3. `project.pbxproj` 변경

- `PBXNativeTarget` 추가. Debug/Release 빌드 설정은 `EnglishKeyboardCore`의 것을 복사하고
  `PRODUCT_BUNDLE_IDENTIFIER`만 `com.snmac.HangeulEnglishKeyboardCore`로 바꾼다.
  `MACH_O_TYPE = staticlib`이라 embed 단계는 필요 없다.
- `PBXTargetDependency`: 새 타깃 → `SYKeyboardCore`, `HangeulKeyboardCore`, `EnglishKeyboardCore`.
  Frameworks 단계에 세 프레임워크를 링크한다.
- `Modules` 동기화 그룹에 새 타깃용 `PBXFileSystemSynchronizedBuildFileExceptionSet`을 추가해
  위 파일을 넣는다. `SYKeyboard` 앱 타깃의 exception set에도 같은 경로를 알파벳 순서로 넣는다.
  앱 타깃이 `Modules` 그룹을 소유하므로 앱 쪽 목록은 제외 목록이다. 넣지 않으면 앱이 그 파일을
  직접 컴파일해 프레임워크와 중복된다.
- `HangeulEnglishKeyboard` extension: Frameworks 단계에 새 프레임워크 추가, 타깃 의존 추가.
  기존 `HangeulKeyboardCore`/`EnglishKeyboardCore` 링크는 그대로 둔다.
- `SYKeyboard` 앱: Frameworks 단계와 의존에 새 프레임워크 추가. 테스트 타깃은 Frameworks 단계가
  비어 있고 호스트 앱이 링크한 모듈을 `@testable import`하므로, 앱이 링크해야 테스트에서
  import된다.
- 스킴은 손대지 않는다. 4개 공유 스킴 모두 앱 타깃 의존으로 새 타깃이 빌드된다.
  빌드 뒤 `.xcscheme`의 `RemotePath` 변경은 되돌린다.

## 4. 테스트

`SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift`를
추가한다. `EnglishKeyboardCoreViewControllerProxyReadTests`와 같은 틀이다.

- `.sharedUserDefaults` trait 아래에서 `lastHangeulEnglishLanguageMode = .english`를 넣고 VC를
  만든 뒤 `textWillChange(nil)`이 `autocapitalizationType`과 `documentContextBeforeInput`을 각각
  한 번만 읽는지 확인한다. 이 VC의 `textWillChange` 오버라이드에서 `withReadCaching`이 사라지면
  실패한다.
- 해제 테스트. `UIWindow`에 올렸다 참조를 놓고 `RunLoop.main.run(until:)` 뒤 `weak == nil`을
  확인한다. `BaseKeyboardViewControllerDeleteUndoBehaviorTests`의 기존 방식을 따른다. 어댑터 2개와
  `UIAction` 클로저를 가진 VC라 순환 참조 검사가 의미 있다.

기존 테스트는 그대로 통과해야 한다. `ModeCoordinator`·`Policy`는 `SYKeyboardCore`에 남으니
import 변경이 없다.

## 5. 문서

`CLAUDE.md`, `README.md`의 클래스 다이어그램, `docs/architecture/전체 아키텍처.md`,
`docs/architecture/한영 통합 키보드.md`, `docs/architecture/한글 입력 로직.md`에서
"Core VC 없이 Base를 직접 상속" 문구와 경로를 고친다. `.github/copilot-instructions.md`는 구조를
`CLAUDE.md`에 위임하므로 확인만 한다.

## 6. 비목표

- `HangeulEnglishKeyboardModeCoordinator`, `KeyboardLanguageModePolicy`, `HangeulEnglishLanguageMode`,
  `LanguageSwitchButton`은 `SYKeyboardCore`에 둔다. `KeyboardView`와 레이아웃 뷰가
  `HangeulEnglishLanguageMode`를 쓰므로 옮길 수 없고, 나머지는 옮겨도 얻는 게 없다.
- `HangeulKeyboardCoreViewController`와 중복된 한글 라우팅 코드를 합치지 않는다. 이번 작업은
  **이동**이지 동작 변경이 아니다. leaf와 Core를 합친 코드가 옮기기 전 파일과 로직상 같아야 한다.
- 앱 설정 화면의 한영 키보드 미리보기(`PreviewHangeulEnglishKeyboardViewController`)는 만들지
  않는다. 이 리팩토링으로 가능해지는 후속 작업이다.

## 7. 검증

- `SYKeyboard` 스킴 전체 테스트, `HangeulKeyboard`·`EnglishKeyboard`·`HangeulEnglishKeyboard` 스킴
  빌드. 기준은 `iPhone 13 mini / iOS 18.6`.
- 시뮬레이터 입력 앱에서 한/A 전환, 한글 입력, 영어 자동 대문자, 필드 전환 시 자동 영어 전환
  (`textContentType`이 Latin을 요구하는 필드)을 확인한다.
- `deinit` live log stream으로 키보드를 N회 내렸다 올려 VC와 Coordinator 4개의 해제 횟수가 N으로
  같은지 확인한다(`CLAUDE.md` > 키보드 extension의 해제·누수 확인).
