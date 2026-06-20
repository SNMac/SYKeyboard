# Codex Skill Playbook

이 문서는 Claude Code showcase의 skill 개념을 SYKeyboard 프로젝트에 맞게 변환한 프로젝트 로컬 플레이북이다. Codex 전역 스킬로 자동 설치되는 파일은 아니며, `AGENTS.md`의 지시에 따라 관련 작업 전에 참고한다.

## 사용 방법

- Swift 코드를 작성하거나 수정할 때는 먼저 `dev/coding-conventions.md`의 관련 섹션을 확인한다.
- 한글 입력/삭제/조합 로직을 바꿀 때는 `hangeul-input-logic` 섹션을 먼저 읽는다.
- 키보드 extension UI나 터치/제스처를 바꿀 때는 `ios-keyboard-extension` 섹션을 먼저 읽는다.
- SwiftUI 설정 화면을 바꿀 때는 `swiftui-settings` 섹션을 먼저 읽는다.
- 여러 영역을 건드리면 관련 섹션을 모두 읽고, `dev/active/<task-name>/` 작업 문서를 만든다.

## hangeul-input-logic

### Trigger

- `HangeulAutomata`
- `HangeulProcessable`
- `DubeolsikProcessor`
- `NaratgeulProcessor`
- `CheonjiinProcessor`
- `composing`, `committed`, `committedTail`
- 한글 조합, 삭제, 겹모음, 겹받침, 스페이스 처리

### Rules

- `dev/coding-conventions.md`의 한글 입력 로직과 테스트 스타일을 따른다.
- UI에서 직접 조합 규칙을 만들지 않는다. 입력 처리는 `Modules/HangeulKeyboardCore/Domain/`에 둔다.
- Processor별 차이를 명시한다. 나랏글/천지인/두벌식은 스페이스와 조합 진행 상태가 다를 수 있다.
- 삭제 변경은 `composing`만 보지 말고 `committedTail`, 보호 상태, 종성 복원 가능성을 함께 본다.
- 비한글 입력이 조합을 끊는지, 기존 composing을 commit해야 하는지 확인한다.
- 테스트는 Swift Testing 스타일을 따른다.

### Verification

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

집중 검증이 필요하면 관련 테스트 파일을 먼저 확인한다.

- `SYKeyboardTests/HangeulAutomataTests.swift`
- `SYKeyboardTests/Processor/DubeolsikProcessorTests.swift`
- `SYKeyboardTests/Processor/NaratgeulProcessorTests.swift`
- `SYKeyboardTests/Processor/CheonjiinProcessorTests.swift`
- `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`
- `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`
- `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`

## ios-keyboard-extension

### Trigger

- `BaseKeyboardViewController`
- `ButtonStateController`
- `TextInteractionGestureController`
- `SwitchGestureController`
- `PrimaryKeyButton`, `SecondaryKeyButton`, `DeleteButton`, `SpaceButton`, `ReturnButton`
- 키보드 높이, 한 손 키보드, 길게 누르기, 드래그 커서 이동, 다음 키보드 전환

### Rules

- `dev/coding-conventions.md`의 UIKit 키보드 UI, 접근 제어, 로깅 관례를 따른다.
- 키보드 extension은 UIKit 기반이다. SwiftUI 설정 화면 패턴을 extension 런타임으로 끌고 오지 않는다.
- 버튼 터치 흐름은 `touchDown`, `touchUpInside`, 반복 입력, 드래그 상태가 서로 영향을 준다. 이벤트 순서를 먼저 확인한다.
- `BaseKeyboardViewController.isPreview` 경로와 실제 extension 경로를 구분한다.
- `hasFullAccess`, `textDocumentProxy`, 키보드 높이 변경, orientation 전환은 실제 extension 제약을 고려한다.
- 무거운 초기화는 입력 지연으로 이어질 수 있으므로 `viewDidLoad`, `viewWillAppear`, 입력 이벤트 내부 작업량을 확인한다.

### Verification

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

UI/입력 변경은 가능하면 시뮬레이터에서 메시지 앱 등 실제 텍스트 입력 환경으로 확인한다.

## swiftui-settings

### Trigger

- `SYKeyboard/Presentation/KeyboardSettings/`
- `@AppStorage`
- `UserDefaultsManager`
- `DefaultValues`
- 설정 토글, Picker, NavigationLink, 미리보기 키보드

### Rules

- `dev/coding-conventions.md`의 SwiftUI 설정 화면과 UserDefaults 설정값 관례를 따른다.
- 설정값은 앱과 키보드 extension에서 함께 읽힐 수 있다. 키를 추가하면 앱 타깃과 Core/extension 쪽 기본값을 모두 확인한다.
- 기존 설정 화면처럼 `@AppStorage(..., store: UserDefaultsManager.shared.storage)`를 사용한다.
- Analytics 이벤트를 추가하거나 이름을 바꿀 때는 기존 user property/event 네이밍과 충돌하지 않게 한다.
- 로컬라이징 대상 문구는 String Catalog 사용을 우선한다.
- 설정 화면 변경이 키보드 런타임에 즉시 반영되는지, 다음 키보드 세션부터 반영되는지 구분한다.

### Verification

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

설정 저장 동작은 앱을 재실행하거나 키보드 extension을 다시 열어 유지 여부를 확인한다.

## docs-and-infrastructure

### Trigger

- `AGENTS.md`
- `dev/`
- `dev/coding-conventions.md`
- README나 개발 문서
- 작업 계획, 체크리스트, Codex 운영 규칙

### Rules

- 문서는 한국어를 기본으로 쓴다.
- 원칙만 나열하지 말고 명령, 체크리스트, 예시 중 하나 이상을 포함한다.
- Claude Code 전용 hook/settings를 Codex에 그대로 적용한다고 쓰지 않는다.
- Codex에서 실제로 작동하는 방식과 참고용 패턴을 구분한다.
- 장기 작업은 `dev/active/<task-name>/`에 plan/context/tasks 3종 문서를 둔다.
- Superpowers의 설계 문서와 구현 계획은 `docs/superpowers/` 대신 `dev/active/<task-name>/superpowers/specs/`와 `dev/active/<task-name>/superpowers/plans/`에 저장한다.
- Superpowers 문서는 스킬 고유의 형식과 상세 수준을 유지하고 `dev/templates/` 형식으로 축약하지 않는다.

### Verification

```sh
sed -n '1,220p' AGENTS.md
sed -n '1,220p' dev/README.md
git status --short
```

## xcode-sandbox-verification

### Trigger

- `xcodebuild test`
- `xcodebuild build`
- SwiftPM package graph resolve
- CoreSimulator 실행
- `.xcresult` 조회
- `~/Library/Developer/Xcode`, `~/Library/Caches`, `~/.cache/clang` 권한 오류

### Rules

- Codex 샌드박스의 Xcode/SwiftPM/CoreSimulator 권한 오류는 저장소 코드나 사용자 로컬 설정 문제로 단정하지 않는다.
- `CoreSimulatorService connection became invalid`, `Operation not permitted`, `ModuleCache`, `ManifestLoading`, `.xcresult` 접근 오류가 보이면 환경 실패로 분류한다.
- 환경 실패가 검증을 막으면 같은 명령을 권한 있는 실행으로 재시도한다.
- 최종 응답에는 샌드박스 실패와 권한 있는 실행 결과를 분리해서 쓴다.
- 권한 있는 실행에서도 실패할 때만 코드/테스트 실패로 보고 원인을 추적한다.

### Verification Pattern

먼저 일반 실행을 시도한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

샌드박스 권한 오류로 실패하면 Codex는 동일 명령을 `require_escalated`로 재실행한다. 사용자가 직접 터미널/Xcode에서 실행하는 경우에는 이 문제가 재현되지 않을 수 있으며, 그때는 사용자 환경의 정상 실행 결과를 우선한다.
