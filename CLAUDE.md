# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

이 문서는 이 저장소에서 Claude Code가 작업할 때 따라야 할 프로젝트별 지침이다. 답변보다 실제 완료를 우선하고, 변경 전후의 동작을 가능한 한 검증한다.

## 프로젝트 개요

- SY키보드는 iOS 16+용 한글/영문 커스텀 키보드 앱이다.
- 메인 앱(`SYKeyboard/`)은 SwiftUI 기반 설정/안내 화면이다.
- 키보드 확장(`Keyboards/HangeulKeyboard/`, `Keyboards/EnglishKeyboard/`, `Keyboards/HangeulEnglishKeyboard/`)은 UIKit 기반이다.
- 공통 키보드 UI와 입력 보조 기능은 `Modules/SYKeyboardCore/`에 있다.
- 한글 입력 조합 로직은 `Modules/HangeulKeyboardCore/Domain/`에 있으며, 나랏글/천지인/두벌식 Processor와 Automata 테스트가 중요하다.
- 영문 키보드 로직은 `Modules/EnglishKeyboardCore/`에 있다.
- 공통 XIB, 색상, 리소스는 로컬 SPM 패키지 `SYKeyboardAssets/`에서 제공한다.
- 외부 의존성은 SPM으로 관리하며 Firebase, Google Mobile Ads, Meta mediation이 포함된다.

## 아키텍처

**세 개의 키보드 extension이 하나의 Base 컨트롤러를 공유한다.**

```
UIInputViewController
└── BaseKeyboardViewController          (SYKeyboardCore, ~2400줄, 입력 흐름의 중심)
    ├── HangeulKeyboardCoreViewController → HangeulKeyboardViewController
    ├── EnglishKeyboardCoreViewController → EnglishKeyboardViewController
    └── HangeulEnglishKeyboardViewController   (Core VC 없이 Base를 직접 상속)
```

`BaseKeyboardViewController`가 텍스트 프록시 조작, 제스처, 자동완성, undo/redo, 높이·한손 모드,
`textWillChange`/`textDidChange` 동기화를 전담한다. 각 하위 VC는 `open` 프로퍼티/메서드
(`primaryKeyboardView`, `primaryKeyboardViews`, `updateKeyboardType()`, `shouldDeferUndoRedoCommit`,
`smartQuoteRule` 등)를 오버라이드해 언어별 차이만 주입한다. **언어 공통 동작을 하위 VC에 복제하지 말고
Base에 두거나 Policy로 분리한다.**

**언어별 입력 로직은 Adapter를 통해 들어온다.**
`HangeulKeyboardInputAdapter` / `EnglishKeyboardInputAdapter`가 VC와 Domain 사이의 유일한 경계다.
한글 Adapter는 `HangeulProcessable`(나랏글/천지인/두벌식 Processor) → `HangeulAutomata` 순으로 위임하고,
`CompositionResult`(committed/composing/consumedCommittedCount) · `DeleteResult` · `SpaceInputResult`를 반환한다.
VC는 이 값만 보고 프록시를 갱신하므로, 조합 규칙 변경은 Processor/Automata에서 끝내야 한다.

**한영 통합 키보드는 어댑터 2개 + Coordinator 조합이다.**
`HangeulEnglishKeyboardViewController`가 두 Adapter를 함께 들고,
`HangeulEnglishKeyboardModeCoordinator`(+ `KeyboardLanguageModePolicy`)가 현재 언어 모드를 결정한다.
`primaryKeyboardView`는 모드에 따라 다른 Adapter의 뷰를 돌려주고, `primaryKeyboardViews`는 양쪽 전부를 돌려준다
(전환 버튼·레이아웃 갱신이 이 차이에 의존한다).

**분기 로직은 Policy로 뽑혀 있다.**
`Modules/SYKeyboardCore/Presentation/Utils/Policies/`의 `KeyboardHeightPolicy`,
`KeyboardGesturePolicy`, `KeyboardSmartInputPolicy`, `KeyboardPeriodShortcutPolicy`,
`CursorDragAccelerationPolicy`, `KeyboardSuggestionSelectionPolicy` 등은 UI 의존 없는 순수 타입이고
각각 대응하는 테스트가 있다. **새 규칙/임계값은 VC 안에 if로 넣지 말고 Policy에 추가하고 테스트한다.**

**자동완성은 `SuggestionController` 한 곳으로 모인다.**
`LexiconPredictiveTextEngine`(UILexicon), `TextCheckerPredictiveTextEngine`(UITextChecker),
`NGramPredictiveTextEngine`(학습형), `MathExpressionCompletionEvaluator`(수식)가
`PredictiveTextProvider`로 붙고 `SuggestionBarView`가 표시한다.

**뷰 계층**: `KeyboardView`(XIB, `SYKeyboardAssets` 번들에서 로드) 안에 `SuggestionBarView` +
primary/symbol/numeric/tenkey 레이아웃이 들어간다. 레이아웃은 `*KeyboardLayoutProvider` 프로토콜 구현체이며
`StandardKeyboardView` / `FourByFourKeyboardView` / `FourByFourPlusKeyboardView`를 베이스로 한다.

**저장소**: 앱과 3개 extension은 App Group(`DefaultValues.groupBundleID`) suite의 `UserDefaults`를
`UserDefaultsManager`로 공유한다. 모듈별 `UserDefaultsKeys+Extension` / `DefaultValues+Extension`으로 확장하며,
`SYKeyboardTests/Storage/UserDefaultsContractTests.swift`가 키 계약을 지킨다.
extension 프로세스 로컬 상태는 `KeyboardExtensionLocalStateStore`에 둔다.

## 작업 원칙

- **기존 구조와 네이밍을 먼저 따른다. 불필요한 아키텍처 변경이나 대규모 이동은 하지 않는다.**
- 파일을 수정하기 전에 관련 파일과 인접 구현을 읽는다.
- **기존 키보드 기능, 입력 흐름, 버튼 이벤트 타이밍은 명시 요청 없이 바꾸지 않는다. 기능 추가나 버그 수정은 현재 동작을 보존하는 방식으로 먼저 설계하고, 기존 동작 변경이 꼭 필요하면 사용자에게 확인한다.**
- **롤백·복원 작업은 기준 커밋과 그 이전 이력에서 실제 동작을 확인하고, 요청된 범위만 복원한다. 이전부터 존재한 버그·제약이나 개선 가능성은 이번 변경으로 생긴 회귀와 구분하며, 사용자가 명시적으로 요청하지 않은 기존 동작 개선을 같은 작업에 포함하지 않는다.**
- 코드 리뷰에서 더 안전하거나 일관된 구현이 제안되어도 바로 수정하지 않는다. 먼저 해당 동작이 이번 diff에서 발생한 회귀인지 과거 커밋과 실제 재현으로 확인하고, 기존 동작이었다면 별도 변경으로 분리하거나 사용자에게 범위 확대를 확인한다.
- **한글 입력, 삭제, 조합 상태, 커서 이동, 스페이스/리턴 동작 변경은 회귀 위험이 높으므로 테스트를 추가하거나 기존 테스트를 실행한다.**
- **현재 확인된 환경에서 `UIInputViewController.selectionWillChange(_:)`와 `selectionDidChange(_:)`는 호출되는 경우를 관찰하지 못했다. 커서/selection 상태 동기화를 이 콜백에만 의존하지 않는다. iOS 자체 문제이거나 아직 확인하지 못한 호출 조건일 수 있으므로, 관련 동작을 변경할 때는 실제 입력 앱에서 다시 확인한다.**
- **현재 확인된 환경에서 focus 중인 텍스트 필드 변경, 사용자의 텍스트 필드 탭, 커서 이동 시 `UIInputViewController.textWillChange(_:)`와 `textDidChange(_:)`가 호출된다. 외부 텍스트 컨텍스트 변경에 따른 `inputBuffer`, 자동완성 후보, undo/redo 상태 동기화는 이 콜백 경로를 함께 확인한다.**
- 키보드 확장은 메모리/높이/입력 지연에 민감하다. 무거운 작업, 불필요한 비동기 체인, 빈번한 재생성은 피한다.
- 앱 설정과 키보드 확장은 `UserDefaultsManager`와 `DefaultValues`를 공유한다. 설정 키 변경 시 앱/확장/Core 양쪽 영향을 확인한다.
- Firebase, AdMob, entitlements, bundle identifier, provisioning, `GoogleService-Info.plist`, `Secrets.xcconfig` 관련 변경은 사용자가 명시적으로 요청한 경우에만 한다.
- 사용자가 만든 변경이 있을 수 있으므로 작업 전후 `git status --short`로 범위를 확인하고, 무관한 변경은 되돌리지 않는다.
- 리뷰·판별·상태 확인 요청은 `cherry-pick`, `merge`, `rebase`, `squash`,
  `reset`, 브랜치 전환, push, PR 생성 권한을 포함하지 않는다. 사용자가 명시한
  통합 순서와 브랜치/worktree 제약을 그대로 지키고, 다음 단계가 명시적으로
  요청되기 전에는 읽기 전용 확인에 머문다.
- 자동완성 후보의 가로 스크롤과 scroll edge effect는 롤백된 상태가 현재
  의도다. `SuggestionButtonView`의 기존 두 줄·글자 축소·중간 생략 동작을
  유지하고, 사용자가 다시 요청하지 않는 한 스크롤 컨테이너나 제스처 중재를
  재도입하지 않는다.

## 작업 인프라

- 라이브러리/API 문서 확인, 코드 생성, 설정 또는 구성 단계가 필요한 작업에서는 사용자가 명시적으로 요청하지 않아도 항상 Context7 MCP를 먼저 사용해 현재 문서와 권장 사용법을 확인한다.
- Context7 MCP가 응답하지 않거나 사용량 초과 등으로 사용할 수 없거나 필요한 정보를 찾지 못해도 작업을 중단하지 않는다. 우선 기존 지식을 바탕으로 계속 진행하고, 기존 지식만으로 해결하기 어려울 때 공식 문서를 확인한다. 최종 응답에는 Context7을 사용하지 못한 이유와, 대체 출처를 확인했다면 실제로 확인한 출처를 명시한다.
- 이 문서가 저장소 에이전트 지침의 단일 기준이다. `.github/copilot-instructions.md`는 GitHub Copilot 코드 리뷰 지침이며 프로젝트 구조와 일반 개발 규칙은 이 문서를 참조하므로, 이 문서의 규칙을 바꾸면 해당 항목도 함께 확인한다.

### Superpowers 계획 실행

- `docs/superpowers/plans/`의 구현 계획에 따라 작업할 때는 계획 문서를 진행 상태의 기준으로 사용한다.
- 각 step은 실제 작업과 해당 검증이 모두 끝난 직후에만 체크한다. 실행하지 않았거나 실패한 step을 미리 완료로 표시하지 않는다.
- step이 끝날 때마다 계획 문서의 체크박스와 실제 결과(테스트 개수, 빌드 결과, 확인하지 못한 항목)를 함께 갱신하고, 해당 step에서 변경한 코드·테스트·문서를 하나의 커밋으로 남긴다.
- 다음 step은 직전 step의 체크와 커밋이 완료된 뒤 시작한다. 여러 step을 한 커밋으로 합치거나 모든 체크를 작업 마지막에 한꺼번에 반영하지 않는다.
- 검증만 수행하는 step도 계획 문서에 실제 명령·대상·결과를 기록하고 문서
  커밋을 남긴다. `.xcresult`, 로그처럼 결과를 별도 산출물에서 판독했다면 실제
  산출물 경로와 결과 추출 명령도 함께 기록해 다른 작업자가 같은 결과를
  재확인할 수 있게 한다.
- step 커밋은 이 문서의 커밋 메시지 규칙을 따르며, 계획에 명시된 파일 범위 밖의 사용자 변경을 포함하지 않는다.
- `docs/superpowers/plans/`, `docs/superpowers/specs/`는 과거 계획·설계 기록이므로 **현재 제품 요구사항이나 현재 동작의 권위 있는 근거로 사용하지 않는다.** 사용자나 PR 설명이 특정 문서를 구현 기준으로 명시한 경우에만 요구사항으로 사용한다.

## 이슈 관리

- 현재 작업 관리와 진행 추적은 Linear를 사용한다.
- 새 이슈 등록은 GitHub Issue에만 한다.
- Linear에는 GitHub Issue에서 파생된 작업 추적, 상태 관리, 연결 정보 정리에 집중한다.
- 새 이슈 생성을 요청받으면 기본 생성 위치를 GitHub Issue로 판단하고, Linear 이슈 생성은 사용자가 명시적으로 요청한 경우에만 한다.

## 코드 스타일

- Swift 5 프로젝트이며 Xcode 26 이상을 기준으로 한다. 현재 production 코드가
  `UIGlassEffect` 등 iOS 26 SDK 심볼을 직접 참조하므로, `#available`만으로
  Xcode 16 SDK 컴파일 호환성이 생기지 않는다. `SYKeyboardAssets` 패키지는
  `swift-tools-version: 6.0`을 사용한다.
- deprecated API의 신규 사용은 지양하고, 현재 지원되는 권장 API를 우선한다. 기존 deprecated API를 수정할 때도 변경 범위와 호환성을 확인해 가능한 경우 권장 대체 API로 전환한다.
- 기존 스타일처럼 `// MARK: -` 섹션, 명확한 접근 제어, 짧은 한국어 주석을 유지한다.
- Swift, Foundation, UIKit, SwiftUI가 제공하는 표준 API를 우선 사용한다. 예를 들어 UIKit gesture의 위치/속도처럼 프레임워크가 직접 제공하는 값이 있으면 별도 프레임워크 import나 직접 계산보다 이를 먼저 검토한다.
- SwiftUI 설정 화면은 `@AppStorage(..., store: UserDefaultsManager.shared.storage)` 패턴을 따른다.
- UIKit 키보드 UI는 `BaseKeyboardViewController`, `ButtonStateController`, gesture controller, layout provider 프로토콜의 책임을 유지한다.
- 입력 로직은 UI에 섞지 말고 `HangeulProcessable`, `HangeulAutomata`, 각 Processor 쪽에 둔다.
- 로컬라이징 문자열은 가능한 한 String Catalog(`.xcstrings`)를 사용한다.
- 새 설정값을 추가할 때는 관련 `UserDefaultsKeys`, `DefaultValues`, 앱 설정 화면, 키보드 런타임 반영 위치를 함께 확인한다.

## 주요 디렉터리

- `SYKeyboard/App/`: 앱 진입점, Firebase/AdMob 초기화.
- `SYKeyboard/Presentation/`: SwiftUI 설정, 안내, 미리보기 화면.
- `SYKeyboard/Storage/`: 앱 타깃의 UserDefaults 확장.
- `Keyboards/HangeulKeyboard/`: 한글 키보드 extension 진입점과 리소스.
- `Keyboards/EnglishKeyboard/`: 영문 키보드 extension 진입점과 리소스.
- `Keyboards/HangeulEnglishKeyboard/`: 한영 통합 키보드 extension 진입점과 리소스.
- `Keyboards/Common/`: 키보드 확장 공통 UI와 오류 타입.
- `Modules/SYKeyboardCore/`: 공통 키보드 UI, 버튼, 제스처, 자동완성, 저장소 기본 타입.
  - `Presentation/Utils/Policies/`, `Presentation/Utils/Coordinators/`: UI 의존 없는 순수 정책·모드 결정 타입.
- `Modules/HangeulKeyboardCore/`: 한글 오토마타, 입력 Processor, 한글 키보드 View.
- `Modules/EnglishKeyboardCore/`: 영문 키보드 View와 저장소 확장.
- `Modules/*/Presentation/Input/`: VC와 Domain의 경계인 InputAdapter.
- `SYKeyboardTests/`: Swift Testing 기반 한글 오토마타/Processor/Controller/Policy 테스트.
- `SYKeyboardAssets/`: XIB와 색상 asset을 제공하는 로컬 SPM 패키지.
- `Common/Firebase/`: Debug/Release Firebase plist. 민감 설정 변경에 주의한다.
- `docs/superpowers/`: 과거 계획·설계 기록. 현재 동작의 근거로 사용하지 않는다.

## 빌드와 테스트

가능하면 변경 범위에 맞춰 아래 명령을 실행한다. 기본 검증 기준은 `iPhone 13 mini / iOS 16.0`이며, 해당 런타임이 없는 로컬 환경에서는 가장 가까운 iOS 16+ 시뮬레이터로 조정하고 최종 응답에 실제 기기명과 OS 버전을 명시한다.

```sh
xcodebuild -list -project SYKeyboard.xcodeproj
```

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

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

공유 scheme은 `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` 4개다. `SYKeyboard`/키보드 extension scheme의 TestAction은 `SYKeyboardTests`를 포함한다.

특정 suite나 단일 테스트만 실행:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/NaratgeulProcessorTests
```

- `-only-testing:SYKeyboardTests/<SuiteName>/<testFunctionName>`으로 단일 테스트까지 좁힌다.
  suite 이름은 `@Suite(...)`의 표시 이름이 아니라 **타입 이름**을 쓴다.
- `-only-testing`이나 code coverage 옵션을 쓴 뒤 extension scheme을 빌드할 때는 옵션을 반드시 비운다.
- `SYKeyboard/Resources/Configs/Secrets.xcconfig`는 gitignore 대상이고 앱 타깃의 Debug/Release xcconfig가
  `#include`한다. Xcode Cloud에서는 `ci_scripts/ci_post_clone.sh`가 환경변수로 생성한다.
  로컬에서 이 파일을 새로 만들거나 커밋하지 않는다.

### 환경 오류와 코드 실패 구분

샌드박스나 권한 제약이 있는 실행 환경에서는 Xcode/SwiftPM 캐시, CoreSimulator, 사용자 프로비저닝 프로파일, `~/Library/Developer/Xcode/DerivedData`, `~/Library/Caches`, `~/.cache/clang` 접근이 막힐 수 있다. 이 경우 프로젝트 코드 문제가 아니어도 `xcodebuild`가 아래와 같은 오류로 멈춘다.

- `CoreSimulatorService connection became invalid`
- `Operation not permitted`
- `error opening ... ModuleCache`
- `cannot open ... ManifestLoading`
- `.xcresult` 접근 또는 삭제 권한 오류

이 오류들은 저장소 설정만으로 해결할 수 있는 범위가 아니다. 위 패턴으로 실패하면 **코드 실패로 기록하지 않는다.** 샌드박스를 벗어난 실행 허용을 요청하거나, 사용자에게 프롬프트에서 `! <명령>`으로 직접 실행하도록 안내해 같은 명령을 다시 확인한다. 최종 응답에는 환경 실패 여부와 권한 있는 환경에서의 실제 검증 결과를 구분해서 기록한다.

XcodeBuildMCP를 사용하는 경우 첫 build/test 전에 `session_show_defaults`로 project, scheme, simulator, `extraArgs`를 확인한다. 테스트에서 사용한 code coverage나 `-only-testing` 옵션이 extension 빌드에 남을 수 있으므로 scheme을 전환할 때 `extraArgs`를 명시적으로 비우거나 다시 설정한다. 세션 설정 때문에 컴파일 전에 중단된 실행은 코드 실패로 기록하지 않고, 설정을 바로잡은 같은 명령의 결과를 검증 근거로 사용한다.

## 테스트 지침

- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)을 사용한다.
- 한글 조합 변경 시 최소한 관련 Processor 테스트와 `HangeulAutomataTests`를 확인한다.
- 나랏글/천지인/두벌식은 동일한 기대 동작처럼 보여도 조합 상태와 스페이스 처리 규칙이 다를 수 있으므로 각각 검증한다.
- 삭제 로직은 `composing`, `committedTail`, 보호 상태, 겹받침/겹모음 분해를 함께 확인한다.
- UI 변경은 가능한 경우 빌드까지 확인하고, 키보드 extension은 실제 입력 앱에서 열리는 흐름까지 염두에 둔다.
- 커서 이동, focus 전환, 텍스트 필드 탭과 관련된 변경은 실제 입력 앱에서 `textWillChange(_:)`/`textDidChange(_:)` 호출과 내부 상태 동기화를 확인한다. `selectionWillChange(_:)`/`selectionDidChange(_:)` 호출을 전제로 검증을 생략하지 않는다.
- 테스트 개수와 통과 여부만으로 merge 가능성을 판정하지 않는다. 새 테스트는
  가능한 한 production 진입점을 호출하고 정확한 기대값을 검증한다. production
  코드를 호출하지 않는 helper 자체 검증, 구현을 복제한 simulator 검증,
  `!=`만 사용하는 약한 단언, 시간 경과만으로 성공하는 테스트는 추가하지 않는다.
- 숫자가 포함되어 있다는 이유만으로 UI 구현 테스트로 판단하지 않는다. 입력
  임계값, 키보드 높이 계산식, 반복 타이머 하한처럼 사용자 동작과 안전성에
  영향을 주는 정책 수치는 검증한다.
- exact color, font, SF Symbol 이름, corner radius, effect subclass, private
  subview 계층, `Mirror` 기반 private 상태는 unit test에서 고정하지 않는다.
- production 동작을 검증한다고 설명하는 테스트는 해당 production 진입점을
  호출해야 한다. helper가 결과를 직접 계산하거나 production 로직을 복제한
  경우 통합 검증으로 인정하지 않는다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. 의미 있는 상태
  계산은 production policy로 분리하고 UI 결과는 공개된 동작으로 검증한다.
- processor 단위 테스트는 processor 반환값을 검증하고, controller 수준의
  committed/composing 상태 전이는 `HangeulCompositionState`를 사용한다.
- 테스트·suite·harness 이름과 설명은 실제로 호출한 production 범위와 일치해야
  한다. `HangeulCompositionState` harness는 ViewController 또는 자동완성 통합
  테스트로 부르지 않고 조합/상태 동작으로 한정한다.
- synthetic 자동완성 필드, 수동 상태 갱신, 그 결과에 대한 단언만으로는 실제
  자동완성 검증을 주장하지 않는다. 자동완성 통합 테스트는 controller,
  `inputBuffer`, `SuggestionController` 등 실제 production 경로를 거치며, 그렇지
  않으면 조합/상태 동작으로 이름과 범위를 한정한다.
- 수식 evaluator 변경은 정상 예시뿐 아니라 비유한 숫자 토큰·중간 결과, 주변
  일반 텍스트와 구분자, `x`/`X` 경계, 반올림된 음수 0 같은 적대 입력도
  검토한다. 전체 테스트가 통과해도 이 경계 사례를 별도로 확인한다.
- 실제 화면, 햅틱, 사운드 또는 host 앱 상호작용이 완료 조건이면 자동 테스트와
  빌드가 수동 관찰을 대체하지 않는다. 광고·overlay·키보드 미활성화로 관찰하지
  못한 항목은 미확인 상태와 정확한 차단 경로를 기록하고 완료 또는
  production-ready로 표시하지 않는다.
- selection에서 생성한 수식 후보는 생성 당시 `selectedText`와 현재
  `selectedText`가 정확히 일치할 때만 action을 허용한다. 현재 selection이
  `nil`, 빈 문자열 또는 다른 문자열이면 preview, 후보 탭, 스페이스의 모든
  수식 action을 막고, 미선택 상태에서 생성한 후보의 기존 동작은 유지한다.
- 수식 후보 preview, 후보 탭, 스페이스는 동일한 origin-aware action 계약을
  사용한다. 확정 대치는 `UITextDocumentProxy.insertText`를 사용하고
  `setMarkedText`를 사용하지 않는다.

### 테스트 경계 예시

- 유지: 커서 속도별 이동 step, suggestion bar 표시 여부, 키보드 높이 계산,
  제스처 취소 후 입력 복구
- 제거하거나 실제 화면 검증으로 이동: 정확한 tint, blur/glass 구체 타입,
  SF Symbol 이름, private subview 구조
- 명시적 UI 회귀 계약: 자동완성 후보의 스크롤 없음·두 줄·자동 축소·중간 생략
- 명명 예시: `HangeulCompositionState` harness의 committed/composing 검증은
  조합/상태 테스트이며 ViewController·자동완성 통합 테스트가 아님
- 자동완성 통합 예시: controller 입력에서 `inputBuffer`를 거쳐
  `SuggestionController` 결과를 확인한다. synthetic 필드 수동 갱신은
  조합/상태 테스트로만 설명한다.

새 테스트 추가 전 확인:

- 이 테스트가 실패할 production 동작을 한 문장으로 설명할 수 있는가?
- production 진입점을 실제로 호출하는가?
- helper가 기대 결과나 상태 전이를 다시 구현하고 있지 않은가?
- 테스트·suite·harness 이름과 설명이 실제 production 호출 범위와 일치하는가?
- 자동완성 통합을 주장한다면 controller/`inputBuffer`/`SuggestionController`의
  실제 production 경로를 거치는가? 아니라면 조합/상태 테스트로 한정했는가?
- UI 구조가 바뀌어도 사용자 동작이 같으면 통과하는가?
- 시각 속성을 고정한다면 명시된 제품 계약 또는 접근성 요구가 있는가?

## 커밋 메시지 규칙

- Udacity Git Commit Message Style을 따른다.
- 기본 형식은 `type: subject`다.
- 이슈 번호가 있는 작업은 기존 이력처럼 `type: #이슈번호 - subject` 형식을 우선 사용한다.
- subject는 한국어를 기본으로, 변경 내용을 명령형보다 결과 중심의 짧은 명사/서술구로 쓴다.
- 마침표를 붙이지 않는다.
- 너무 일반적인 `Update README.md` 같은 메시지는 피하고, 무엇이 바뀌었는지 드러내는 `docs: README에 자동완성 엔진 설명 반영`처럼 쓴다.
- 한 커밋에는 한 가지 목적의 변경만 담는다. 버전/빌드 번호 변경은 기능 변경과 분리하고 `chore`를 사용한다.
- 주로 사용하는 타입:
  - `feat`: 새 기능, 동작 추가, 사용자 설정 추가
  - `fix`: 일반 버그 수정
  - `hotfix`: 긴급 수정이나 릴리스 직전/운영 영향 버그 수정
  - `refactor`: 동작 변경 없는 구조 개선
  - `docs`: README, 개발 문서, 주석 중심 변경
  - `chore`: 빌드 번호, 설정, 의존성, 유지보수 작업
  - `design`: UI 수치, 색상, 레이아웃 같은 시각 조정
  - `remove`: 불필요한 파일이나 코드 제거
  - `rename`: 파일명이나 심볼명 변경
- 예시:
  - `feat: #31 - 활성화 드래그 거리 값 조정`
  - `fix: #44 - NGram에서 단어가 중복되어 저장되는 현상 수정`
  - `hotfix: 높이 조절 로직 크래시 방지 코드 추가`
  - `docs: #44 - 문서에 변경된 자동완성 엔진 반영`
  - `chore: #31 - 버전 및 빌드 번호 변경`

## 변경 전 체크리스트

- 관련 모듈과 인접 테스트를 읽었는가?
- 변경 대상이 앱 설정, 키보드 extension, Core 모듈 중 어디까지 영향을 주는가?
- 현재 키보드 기능, 입력 흐름, 버튼 이벤트 타이밍을 유지하는가? 바뀐다면 사용자가 명시적으로 요청했거나 확인했는가?
- 롤백·복원 작업이라면 각 변경이 기준 커밋 이전 동작의 복원인지 확인했는가? 기존부터 존재한 동작 개선을 섞고 있지는 않은가?
- 코드 리뷰 지적을 반영하기 전에 이번 diff의 회귀인지, 과거에도 동일했던 동작인지 이력과 재현으로 구분했는가?
- 저장소 키, 기본값, 로컬라이징, 미리보기, 테스트가 함께 필요한가?
- Firebase/AdMob/권한/번들 설정 같은 외부 영향 파일을 건드리고 있지는 않은가?

## 완료 전 체크리스트

- 요청한 산출물이 실제로 생성 또는 수정되었는가?
- 변경한 파일만 의도적으로 수정되었는가?
- 가능한 빌드/테스트/명령 검증을 실행했는가?
- 실행하지 못한 검증이 있다면 이유를 구체적으로 남겼는가?
- 남은 TODO, 불확실한 추정, 사용자 확인이 필요한 사항을 완료로 표현하지 않았는가?

## 문서 작성 규칙

- 문서는 한국어를 기본으로 하고, 명령/파일명/API 이름은 원문 그대로 쓴다.
- 원칙만 쓰지 말고 명령, 체크리스트, 예시 중 하나 이상을 포함한다.
- README, 한글 입력 로직 정리 문서, 자동완성 로직 정리 문서의 기존 설명과 충돌하지 않게 쓴다.
