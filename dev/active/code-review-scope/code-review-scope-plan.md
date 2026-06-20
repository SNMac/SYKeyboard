# Code Review Scope Plan

Last Updated: 2026-06-06

## Goal

- SYKeyboard 전체 코드리뷰를 한 번에 진행하지 않고, 서로 다른 Codex 채팅에서 독립적으로 다룰 수 있는 범위로 나눈다.
- 각 리뷰 범위는 관련 파일, 핵심 질문, 선행/후행 관계, 검증 명령을 포함해야 한다.
- 각 트랙의 findings는 `dev/active/code-review-scope/code-review-scope-findings.md`에 종합해 추적한다.

## Current State

- 저장소는 iOS 16+ 커스텀 키보드 앱이며, 메인 앱은 SwiftUI, 키보드 extension과 공통 키보드 런타임은 UIKit 기반이다.
- 한글 입력 조합 로직은 `Modules/HangeulKeyboardCore/Domain/`에 집중되어 있고, 관련 테스트가 `SYKeyboardTests/Processor/`, `SYKeyboardTests/Controller/`, `SYKeyboardTests/HangeulAutomataTests.swift`에 있다.
- 공통 키보드 이벤트/상태/레이아웃은 `Modules/SYKeyboardCore/`에 집중되어 있다.
- 설정 저장 계약은 `SYKeyboard/Storage/`, `Modules/SYKeyboardCore/Storage/`, `Modules/HangeulKeyboardCore/Storage/`, `Modules/EnglishKeyboardCore/Storage/`와 SwiftUI 설정 화면이 함께 봐야 한다.
- 이미 진행 중인 관련 작업 문서가 있다.
  - `dev/active/snm-40-predictive-loading/`
  - `dev/active/cursor-drag-acceleration/`
  - `dev/active/base-keyboard-vc-responsibility-refactor/`
  - `dev/active/suggestion-bar-undo-redo/`

## Scope Split Principles

- 도메인 규칙이 다른 영역은 분리한다. 예: 한글 조합, UIKit 이벤트 처리, SwiftUI 설정 저장.
- 같은 테스트 세트로 검증되는 영역은 같은 리뷰 범위에 둔다.
- 한 리뷰 채팅은 기본적으로 1-2개 최상위 디렉터리와 관련 테스트만 다룬다.
- `BaseKeyboardViewController`처럼 여러 기능을 조율하는 파일은 단독으로 크게 보지 않고, 이벤트/입력 흐름 범위에서 먼저 리뷰한 뒤 필요하면 책임 분리 작업으로 넘긴다.
- Firebase, AdMob, entitlements, `Secrets.xcconfig`, bundle id는 사용자가 명시적으로 요청하지 않는 한 수정 대상이 아니라 검토/위험 기록 대상으로만 둔다.

## Recommended Review Tracks

### 0. Baseline Inventory And Review Rules

- 목적: 전체 리뷰 전에 현재 빌드/테스트 기준, 활성 작업 문서, 변경 중인 파일을 확정한다.
- 주요 파일:
  - `AGENTS.md`
  - `dev/README.md`
  - `dev/codex-skill-playbook.md`
  - `dev/coding-conventions.md`
  - `SYKeyboard.xcodeproj`
  - `.github/pull_request_template.md`
- 핵심 질문:
  - 현재 작업 중인 브랜치/변경사항이 리뷰 결과와 섞이지 않는가?
  - 리뷰 중 발견사항의 우선순위 형식과 검증 기준이 정해져 있는가?
  - Xcode 샌드박스 실패와 실제 코드 실패를 구분할 절차가 있는가?
- 권장 검증:

```sh
git status --short
xcodebuild -list -project SYKeyboard.xcodeproj
```

### 1. Hangeul Input Domain Logic

- 목적: 한글 조합, 삭제, 스페이스 처리, Processor별 상태 전이를 집중 리뷰한다.
- 주요 파일:
  - `Modules/HangeulKeyboardCore/Domain/Automata/HangeulAutomata.swift`
  - `Modules/HangeulKeyboardCore/Domain/Processor/Protocols/HangeulProcessable.swift`
  - `Modules/HangeulKeyboardCore/Domain/Processor/DubeolsikProcessor.swift`
  - `Modules/HangeulKeyboardCore/Domain/Processor/NaratgeulProcessor.swift`
  - `Modules/HangeulKeyboardCore/Domain/Processor/CheonjiinProcessor.swift`
  - `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
  - `Modules/HangeulKeyboardCore/Domain/Utils/Character+Extension.swift`
  - `SYKeyboardTests/HangeulAutomataTests.swift`
  - `SYKeyboardTests/Processor/`
  - `SYKeyboardTests/Controller/`
- 핵심 질문:
  - `composing`, `committed`, `committedTail` 상태가 Processor마다 일관되게 해석되는가?
  - 삭제/겹받침/겹모음/비한글 입력 처리에서 회귀 위험이 있는가?
  - 테스트가 나랏글/천지인/두벌식의 차이를 충분히 드러내는가?
- 권장 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

### 2. Common Keyboard Interaction Runtime

- 목적: UIKit 키보드 입력 이벤트, 버튼 상태, 제스처, 반복 입력, undo/redo, 커서 이동 정책을 리뷰한다.
- 주요 파일:
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/`
  - `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/`
  - `SYKeyboardTests/Utils/`
  - `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
- 핵심 질문:
  - `touchDown`, `touchUpInside`, programmatic `sendActions`, long press, drag 흐름이 충돌하지 않는가?
  - 삭제 반복, 스페이스 단축 입력, 커서 드래그, undo/redo가 동시에 활성화될 때 상태가 깨지지 않는가?
  - 정책 객체와 ViewController 책임 경계가 유지되는가?
- 권장 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

### 3. Keyboard Layout, Views, And Assets

- 목적: 한글/영문 키보드 View, 공통 레이아웃, 버튼 시각 상태, XIB/asset 패키지를 리뷰한다.
- 주요 파일:
  - `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
  - `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/`
  - `Modules/SYKeyboardCore/Presentation/View/Components/`
  - `Modules/HangeulKeyboardCore/Presentation/View/`
  - `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/`
  - `SYKeyboardAssets/Package.swift`
  - `SYKeyboardAssets/Sources/SYKeyboardAssets/`
- 핵심 질문:
  - 키보드 높이, 한 손 모드, 기기 회전, preview 경로에서 레이아웃이 안정적인가?
  - 버튼 highlight/selected/gesturing 상태 표현이 입력 상태와 어긋나지 않는가?
  - XIB와 SPM asset 접근이 앱/extension 양쪽에서 안전한가?
- 권장 검증:

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

### 4. Predictive Text And Suggestion Bar

- 목적: 자동완성 엔진, suggestion controller, suggestion bar 표시/선택/준비 상태를 리뷰한다.
- 주요 파일:
  - `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
  - `Modules/SYKeyboardCore/Domain/PredictiveText/`
  - `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
  - `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SuggestionButtonView.swift`
  - `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`
  - `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`
  - `dev/active/snm-40-predictive-loading/`
  - `dev/active/suggestion-bar-undo-redo/`
- 핵심 질문:
  - `UILexicon`, `UITextChecker`, NGram 결과가 UI 상태와 안전하게 연결되는가?
  - 초기 로딩, full access 유무, extension 메모리/지연 제약이 반영되어 있는가?
  - 추천 선택과 undo/redo가 조합 중 한글 입력과 충돌하지 않는가?
- 권장 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

### 5. Settings And UserDefaults Contract

- 목적: SwiftUI 설정 화면, 저장 키, 기본값, extension 런타임 반영 계약을 리뷰한다.
- 주요 파일:
  - `SYKeyboard/Presentation/KeyboardSettings/`
  - `SYKeyboard/Presentation/Components/PreviewKeyboard/`
  - `SYKeyboard/Storage/`
  - `Modules/SYKeyboardCore/Storage/`
  - `Modules/HangeulKeyboardCore/Storage/`
  - `Modules/EnglishKeyboardCore/Storage/`
- 핵심 질문:
  - `@AppStorage(..., store: UserDefaultsManager.shared.storage)` 패턴이 일관되는가?
  - 앱과 keyboard extension이 같은 키/기본값을 같은 의미로 해석하는가?
  - 설정 변경이 즉시 반영되는 항목과 다음 키보드 세션부터 반영되는 항목이 구분되는가?
- 권장 검증:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

### 6. Keyboard Extension Entry Points

- 목적: 한글/영문 extension 진입점, Info.plist, entitlements, full access 안내, 실제 extension lifecycle을 리뷰한다.
- 주요 파일:
  - `Keyboards/HangeulKeyboard/Presentation/ViewController/HangeulKeyboardViewController.swift`
  - `Keyboards/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardViewController.swift`
  - `Keyboards/Common/`
  - `Keyboards/HangeulKeyboard/Resources/`
  - `Keyboards/EnglishKeyboard/Resources/`
- 핵심 질문:
  - extension 초기화가 무겁지 않고 입력 지연을 만들지 않는가?
  - full access 미허용 상태와 허용 상태가 UI/기능상 안전하게 분기되는가?
  - target별 plist, entitlements, localization이 실제 extension 동작과 맞는가?
- 권장 검증:

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

### 7. Main App Shell, Onboarding, Ads, And Resources

- 목적: 메인 앱 진입점, 설정 탭 구조, 안내 화면, 광고/Firebase 초기화, localization/resource 구성을 리뷰한다.
- 주요 파일:
  - `SYKeyboard/App/SYKeyboardApp.swift`
  - `SYKeyboard/Presentation/Content/`
  - `SYKeyboard/Presentation/InstructionsTab/`
  - `SYKeyboard/Presentation/Components/ViewModifiers/RequestReviewViewModifier.swift`
  - `SYKeyboard/Presentation/Content/BannerAd/`
  - `SYKeyboard/Resources/`
  - `Common/Firebase/`
  - `Common/Configs/`
- 핵심 질문:
  - 앱 시작 시 Firebase/AdMob 초기화와 사용자 설정 접근 순서가 안전한가?
  - 광고/리뷰 요청/안내 화면이 설정 중심 앱 흐름을 방해하지 않는가?
  - localization과 asset 참조가 누락되지 않았는가?
- 권장 검증:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

### 8. Build, Packaging, And Repository Hygiene

- 목적: Xcode project, SPM package, xcconfig, GitHub 템플릿, 문서/운영 규칙을 리뷰한다.
- 주요 파일:
  - `SYKeyboard.xcodeproj`
  - `SYKeyboardAssets/Package.swift`
  - `Common/Configs/Version.xcconfig`
  - `.github/`
  - `README.md`
  - `AGENTS.md`
  - `dev/`
- 핵심 질문:
  - shared scheme, target membership, package resource 설정이 현재 구조와 맞는가?
  - `.DS_Store` 같은 불필요 파일이 추적되거나 리뷰 노이즈가 되지 않는가?
  - README/dev 문서의 검증 명령이 실제 scheme와 맞는가?
- 권장 검증:

```sh
git status --short
xcodebuild -list -project SYKeyboard.xcodeproj
```

## Suggested Order

1. `0. Baseline Inventory And Review Rules`
2. `1. Hangeul Input Domain Logic`
3. `2. Common Keyboard Interaction Runtime`
4. `4. Predictive Text And Suggestion Bar`
5. `5. Settings And UserDefaults Contract`
6. `3. Keyboard Layout, Views, And Assets`
7. `6. Keyboard Extension Entry Points`
8. `7. Main App Shell, Onboarding, Ads, And Resources`
9. `8. Build, Packaging, And Repository Hygiene`

## Reusable Chat Prompt Template

```text
SYKeyboard 전체 코드리뷰 중 "<범위 이름>"만 리뷰해줘.

문서 먼저 읽기:
- dev/active/code-review-scope/code-review-scope-plan.md
- dev/active/code-review-scope/code-review-scope-context.md
- dev/active/code-review-scope/code-review-scope-tasks.md
- dev/active/code-review-scope/code-review-scope-findings.md

이번 채팅의 포함 범위:
- <plan.md의 해당 트랙 주요 파일>

이번 채팅의 제외 범위:
- 다른 트랙 파일은 발견사항의 영향 설명에 필요한 경우에만 읽고, 수정 제안은 하지 말 것.

원하는 출력:
- Findings first: 버그/회귀/테스트 누락/설계 위험을 심각도순으로 파일:라인과 함께 정리
- Findings는 final answer에 정리한 뒤 dev/active/code-review-scope/code-review-scope-findings.md에도 누적
- Open questions
- Verification suggestions
- 다음 리뷰 트랙에 넘길 사항
```

## Risks

- 한 리뷰 채팅에서 `BaseKeyboardViewController`와 한글 Processor를 동시에 깊게 보면 입력 이벤트와 조합 규칙이 섞여 결론이 흐려질 수 있다.
- 자동완성/undo-redo는 현재 활성 작업 문서가 있으므로, 해당 작업의 최신 상태를 읽지 않으면 오래된 전제를 바탕으로 리뷰할 수 있다.
- Xcode 검증은 Codex 샌드박스에서 환경 실패가 날 수 있으므로, 샌드박스 실패와 권한 있는 재실행 결과를 분리해서 기록해야 한다.

## Verification

- 이 문서를 만들기 위해 확인한 명령:

```sh
git status --short
sed -n '1,220p' dev/README.md
rg --files dev/templates
sed -n '1,240p' dev/codex-skill-playbook.md
find . -maxdepth 3 -type d
rg --files -g '*.swift'
find dev/active -maxdepth 2 -type f
find SYKeyboard -type f -name '*.swift'
find Keyboards -type f
find Modules/HangeulKeyboardCore -type f -name '*.swift'
find Modules/SYKeyboardCore -type f -name '*.swift'
find Modules/EnglishKeyboardCore -type f -name '*.swift'
find SYKeyboardTests -type f -name '*.swift'
find SYKeyboardAssets -maxdepth 4 -type f
find .github Common SYKeyboard/Resources -maxdepth 4 -type f
```

## Done Criteria

- 전체 코드리뷰 범위가 서로 다른 채팅에서 진행 가능한 단위로 나뉘어 있다.
- 각 범위마다 주요 파일, 핵심 질문, 권장 검증 명령이 있다.
- 다음 채팅에서 바로 복사해 쓸 수 있는 프롬프트 템플릿이 있다.
- 현재 활성 작업 문서와 충돌할 수 있는 영역이 표시되어 있다.
- 트랙별 findings를 누적할 종합 문서가 있다.
