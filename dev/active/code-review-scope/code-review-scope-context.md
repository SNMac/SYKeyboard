# Code Review Scope Context

Last Updated: 2026-06-14

## Relevant Files

- `dev/README.md`: `dev/active/<task-name>/` 구조와 plan/context/tasks 역할을 정의한다.
- `dev/templates/task-plan-template.md`: 새 작업 계획 문서의 기본 형식을 제공한다.
- `dev/templates/task-context-template.md`: 새 작업 컨텍스트 문서의 기본 형식을 제공한다.
- `dev/templates/task-tasks-template.md`: 새 작업 체크리스트 문서의 기본 형식을 제공한다.
- `dev/codex-skill-playbook.md`: 작업 유형별로 읽어야 할 프로젝트 로컬 지침과 검증 명령을 정의한다.
- `README.md`: 앱의 기능, 기술 스택, UIKit 리팩토링 배경을 설명한다.
- `Modules/HangeulKeyboardCore/Domain/`: 한글 조합과 Processor 규칙의 중심이다.
- `Modules/SYKeyboardCore/`: 공통 키보드 런타임, 버튼, 제스처, 레이아웃, 자동완성, 저장소 기본 타입의 중심이다.
- `Modules/EnglishKeyboardCore/`: 영문 키보드 core view/controller와 저장소 확장이다.
- `SYKeyboard/`: SwiftUI 기반 메인 앱, 설정 화면, preview keyboard, 앱 리소스의 중심이다.
- `Keyboards/`: 한글/영문 keyboard extension target 진입점, plist, entitlements, localization 리소스가 있다.
- `SYKeyboardTests/`: Swift Testing 기반 한글 Processor, Controller, 정책, 자동완성 관련 테스트가 있다.
- `SYKeyboardAssets/`: 공통 XIB와 asset 접근 API를 제공하는 로컬 SPM 패키지다.
- `.github/`: PR/issue/dependabot 등 저장소 운영 파일이 있다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: 트랙별 코드리뷰 findings를 누적하는 종합 문서다.

## Facts Checked

- 문서 작성 전 `git status --short` 실행 결과 출력이 없었다. 확인 시점에는 작업트리에 변경사항이 없었다.
- 0번 baseline 리뷰 시점의 현재 브랜치는 `feat/#49-cursor-drag-acceleration`이다.
- 0번 baseline 리뷰 시점의 현재 HEAD는 `482463f04538d2e08e34fa8a09a147df6992ac75`이고, 직전 커밋은 `8494534d31699afbdc4d0f981573c19a74850149`이다.
- 0번 baseline 리뷰 시점의 `git status --short --branch`는 `?? dev/active/code-review-scope/`만 표시했다. 즉 코드리뷰 범위 문서는 아직 untracked 상태다.
- `git diff 8494534d31699afbdc4d0f981573c19a74850149..HEAD --stat` 기준 HEAD까지의 커밋 범위에는 #49 커서 드래그 가속 기능 변경 9개 파일이 포함되어 있다.
- 0번 baseline 리뷰 시점의 `dev/active/`에는 `code-review-scope` 자신을 포함해 다음 작업 문서가 있다.
  - `snm-40-predictive-loading`
  - `cursor-drag-acceleration`
  - `code-review-scope`
  - `base-keyboard-vc-responsibility-refactor`
  - `suggestion-bar-undo-redo`
- `dev/README.md`는 장기 작업에 `dev/active/<task-name>/` 아래 3종 문서를 만들도록 안내한다.
- `dev/templates/`에는 `task-plan-template.md`, `task-context-template.md`, `task-tasks-template.md`가 있다.
- `dev/codex-skill-playbook.md`에는 `hangeul-input-logic`, `ios-keyboard-extension`, `swiftui-settings`, `docs-and-infrastructure`, `xcode-sandbox-verification` 지침이 있다.
- 문서 작성 전 `dev/active/`에는 다음 작업 문서가 있었다.
  - `snm-40-predictive-loading`
  - `cursor-drag-acceleration`
  - `base-keyboard-vc-responsibility-refactor`
  - `suggestion-bar-undo-redo`
- `README.md` 기준 앱은 한글 나랏글/천지인/두벌식, 영어 QWERTY, 한 손 키보드, 높이 조절, 자동완성 문구 추천을 주요 기능으로 가진다.
- `Modules/HangeulKeyboardCore/Domain/`에는 `HangeulAutomata`, `HangeulProcessable`, `DubeolsikProcessor`, `NaratgeulProcessor`, `CheonjiinProcessor`, `HangeulCompositionState`가 있다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/`에는 키보드 높이, 제스처, 텍스트 인터랙션, 자동완성 선택, 마침표 단축 입력, 커서 드래그 가속도, 심볼 입력, 표시 상태 정책 테스트 대상이 되는 파일들이 있다.
- `SYKeyboardTests/`에는 한글 Processor/Controller 테스트와 공통 정책 테스트가 분리되어 있다.
- `Keyboards/`에는 한글/영문 extension별 `Info.plist`, entitlements, xcconfig, localization 리소스가 분리되어 있다.
- `Common/Firebase/`에는 Debug/Release `GoogleService-Info.plist`가 있다. 프로젝트 지침상 이 파일들은 명시 요청 없이 수정하지 않는다.
- 일반 샌드박스에서 `xcodebuild -list -project SYKeyboard.xcodeproj`는 CoreSimulator, clang ModuleCache, SwiftPM ManifestLoading 권한 오류로 실패했다.
- 권한 있는 환경에서 `xcodebuild -list -project SYKeyboard.xcodeproj`는 성공했고, 실제 scheme 목록은 `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `SYKeyboardCore`, `HangeulKeyboardCore`, `EnglishKeyboardCore`, `SYKeyboardAssets`다.
- 2번 리뷰 시점의 현재 브랜치는 `refactor/#57-overall-code-review`, HEAD는 `879587f2ab9c8f167479cdc3fdfe728e1554c3b6`이며 작업트리는 깨끗했다.
- `0fc8cb81..879587f2`에는 리뷰 문서와 PR 템플릿 변경만 있고 Track 2 runtime 코드는 `origin/develop`과 같다.
- `ButtonStateController`의 해제 action은 `.touchUpInside`, `.touchUpOutside`만 처리하며 `.touchCancel`을 처리하지 않는다.
- `TextInteractionGestureController`와 `SwitchGestureController`는 `.ended`, `.cancelled`, `.failed`를 같은 종료 분기에서 처리한다.
- 현재 `SYKeyboardTests`에는 gesture controller의 취소/실패 상태나 `ButtonStateController`의 `.touchCancel` event 흐름을 직접 검증하는 테스트가 없다.
- 4번 리뷰 시점의 현재 브랜치는 `refactor/#57-overall-code-review`, HEAD는 `fda3b45e`이며 작업 시작 시 작업트리는 깨끗했다.
- `0fc8cb81..fda3b45e`에는 코드리뷰 문서와 PR 템플릿 변경만 있고 Track 4 자동완성 코드는 `origin/develop`과 같다.
- 사용자 수동 확인 결과 `selectionWillChange(_:)`와 `selectionDidChange(_:)`는 어떤 조건에서도 호출되는 것을 관찰하지 못했다. iOS 자체 문제이거나 아직 호출 조건을 찾지 못한 상태다.
- 사용자 수동 확인 결과 focus 중인 텍스트 필드 변경, 사용자의 텍스트 필드 탭, 커서 이동 시 `textWillChange(_:)`와 `textDidChange(_:)`가 호출된다.
- 현재 구현은 `textWillChange(_:)`에서 `resetInputBuffer()`를 호출하고 `textDidChange(_:)`에서 `updateSuggestions()`를 호출하므로, 외부 필드/커서 변경 시 `inputBuffer`와 후보 동기화는 selection 콜백이 아니라 text change 콜백을 기준으로 수행된다.
- `SuggestionController.attemptTextReplacement(baseText:)`는 단어 경계 없이 전체 `baseText`의 suffix로 단축어를 찾는다.
- `SuggestionController.attemptRestoreReplacement(...)`는 위치 anchor 없이 전체 `replacementHistory`를 탐색한다.
- lexicon 요청은 `viewDidAppear(_:)` 이후 비동기로 시작되고, lexicon 준비 전 `attemptTextReplacement(baseText:)`는 재시도 없이 실패한다.
- `NGramPredictiveTextEngine`의 load, save, reset은 서로 다른 실행 경로에서 직렬화 없이 파일과 메모리 상태를 변경한다.
- `NGramPredictiveTextEngine.addWord(_:)`와 `endSentence()`는 background load 완료 전 호출을 무시한다.
- 현재 Track 4 관련 테스트는 엔진 준비 횟수, n-gram callback main-thread 갱신, suggestion 선택 정책, undo/redo manager를 검증하지만 selection 변경, 텍스트 대치 경계/복구 위치, 저장소 경쟁 조건을 직접 검증하지 않는다.
- 5번 리뷰 시점의 현재 브랜치는 `refactor/#57-overall-code-review`, HEAD는 `6d4d6b07`이며 작업 시작 시 작업트리는 깨끗했다.
- `origin/develop..6d4d6b07`에는 리뷰 문서/운영 문서 변경만 있고 Track 5 설정 및 저장소 런타임 코드는 `origin/develop`과 같다.
- 영어 자동 대문자 기본값과 `InputSettingsView`의 `@AppStorage` 기본값은 `true`지만, `UserDefaultsManager.isAutoCapitalizationEnabled`는 absent key에서 `storage.bool(forKey:)`의 `false`를 반환한다.
- 영어 키보드의 `updateShiftButton()`과 앱 초기 Analytics는 `UserDefaultsManager.isAutoCapitalizationEnabled`를 직접 읽는다.
- 공통 키보드 런타임은 조건부 action/gesture와 suggestion 설정을 `viewDidLoad()`에서 구성하며, `viewWillAppear()`에서는 해당 설정을 다시 동기화하지 않는다.
- 앱 전용 `isOnboarding` manager getter도 선언된 기본값 `true`와 달리 absent key에서 `false`를 반환하지만, 현재 `ContentView`는 `@AppStorage` 기본값을 사용한다.
- `PredictiveTextSettingsView`의 학습 데이터 초기화는 임시 n-gram 엔진을 만들어 `resetAllData()`를 호출하므로, 기존 Track 4의 load/save/reset 경쟁 조건이 설정 화면의 전체 삭제 약속에도 영향을 준다.
- 현재 `SYKeyboardTests`에는 UserDefaults 키/기본값/type parity, absent-key fallback, 동일 keyboard controller 재진입 후 설정 동기화 테스트가 없다.
- 3번 리뷰 시점의 현재 브랜치는 `refactor/#57-overall-code-review`, HEAD는 `59912481`이며 작업 시작 시 작업트리는 깨끗했다.
- `origin/develop..59912481`에는 리뷰 문서/운영 문서 변경만 있고 Track 3 레이아웃/View/asset 런타임 코드는 `origin/develop`과 같다.
- `KeyboardView`의 `keyboardLayoutView` 너비는 설정값을 `greaterThanOrEqualToConstant` 하한으로만 사용하므로, 한 손 모드에서 설정한 폭보다 확장될 수 있다.
- 기본 리턴 키 이미지는 `.alwaysOriginal`과 `.label` 색상으로 생성되며, 비활성화 시 `UIImageView.tintColor`만 변경하므로 비활성 색상이 이미지에 적용되지 않는다.
- Track 3 포함 범위의 한글/영문 모드별 숨김 처리와 `SYKBDAssets.bundle`/XIB custom module/색상 asset 접근에서는 추가 concrete finding을 확인하지 못했다.
- `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/.DS_Store`는 로컬에 존재하지만 `.gitignore` 대상이며 git에는 추적되지 않는다.
- 6번 리뷰 시점의 현재 브랜치는 `refactor/#57-overall-code-review`, HEAD는 `7d14be52`이며 작업 시작 시 작업트리는 깨끗했다.
- `origin/develop..7d14be52`에는 리뷰 문서/운영 문서 변경만 있고 Track 6 extension entry point 런타임 코드는 `origin/develop`과 같다.
- 전체 접근 안내 오버레이는 `hasFullAccess == false`일 때 표시되지만 닫힘 상태는 app-group suite의 `isRequestFullAccessOverlayClosed`에 기록한다.
- HangeulKeyboard Debug/Release target에는 `APPLICATION_EXTENSION_API_ONLY = YES`가 있고 EnglishKeyboard Debug/Release target에는 해당 설정이 없다.
- 두 extension의 `openURL(_:)`은 responder chain에서 `UIApplication`을 찾지 못하거나 URL 열기에 실패해도 사용자 피드백이나 오류 기록 없이 종료한다.
- 한글/영문 extension의 Info.plist, entitlements, String Catalog 구성에서는 추가 concrete finding을 확인하지 못했다.

## Decisions

- 전체 리뷰를 9개 트랙으로 나눈다.
  - 0. Baseline Inventory And Review Rules
  - 1. Hangeul Input Domain Logic
  - 2. Common Keyboard Interaction Runtime
  - 3. Keyboard Layout, Views, And Assets
  - 4. Predictive Text And Suggestion Bar
  - 5. Settings And UserDefaults Contract
  - 6. Keyboard Extension Entry Points
  - 7. Main App Shell, Onboarding, Ads, And Resources
  - 8. Build, Packaging, And Repository Hygiene
- 한글 조합 로직은 독립 트랙으로 둔다. 입력 조합/삭제 규칙은 회귀 위험이 높고 관련 테스트가 별도로 존재하기 때문이다.
- `BaseKeyboardViewController` 관련 리뷰는 공통 interaction runtime 트랙에 둔다. 이 파일은 여러 기능을 조율하므로 UI layout 트랙과 섞으면 리뷰 범위가 커진다.
- 자동완성/suggestion bar는 별도 트랙으로 둔다. 현재 활성 작업 문서가 있고 full access, loading, undo/redo, 입력 조합과의 충돌을 함께 봐야 하기 때문이다.
- Settings/UserDefaults는 별도 트랙으로 둔다. 앱과 extension이 같은 키/기본값을 공유하므로 단순 SwiftUI 리뷰로 처리하면 누락 위험이 있다.
- extension entry point는 layout 트랙과 분리한다. target lifecycle, plist, entitlements, full access는 UI 구성과 다른 검토 기준을 갖기 때문이다.
- 빌드/패키징/저장소 hygiene은 마지막에 둔다. 앞선 리뷰에서 발견된 target membership, 테스트, 문서 변경 필요성을 모아 확인하는 성격이 강하기 때문이다.
- 리뷰 findings와 후속 문서 변경은 현재 #49 기능 변경과 섞이지 않도록 별도 커밋 또는 별도 브랜치/작업트리로 분리하는 것을 기본 원칙으로 둔다.
- 각 리뷰 채팅은 시작 시 현재 브랜치, HEAD, `git status --short --branch`, 검증 명령 결과를 자체 baseline으로 다시 기록한다. 이전 문서의 Facts Checked는 과거 시점 기록으로만 사용한다.
- 전체 리뷰 findings는 `dev/active/code-review-scope/code-review-scope-findings.md`에 종합한다. 각 채팅 final answer는 즉시 공유용이고, 장기 추적은 findings 문서를 기준으로 한다.
- Track 6의 설정 이동 버튼은 비핵심 편의 기능이므로 URL 열기 실패 시 사용자 실패 UI나 복잡한 fallback을 추가하지 않는다. 현재 best-effort 동작을 유지하고 개발자 진단 로그만 후속 개선 대상으로 둔다.
- Track 6의 전체 접근 오버레이 닫힘 상태는 각 keyboard extension의 `UserDefaults.standard`에 저장한다. 한글/영문 extension별 상태는 독립적으로 유지하고 app-group 저장소와 동기화하거나 전체 접근 허용 후 마이그레이션하지 않는다.
- Track 6의 EnglishKeyboard Debug/Release target에도 HangeulKeyboard와 동일하게 `APPLICATION_EXTENSION_API_ONLY = YES`를 적용한다. 적용 후 EnglishKeyboard extension target 빌드로 app-extension-safe API 계약을 검증한다.

## Inferences

- 추정: 각 리뷰 채팅은 하나의 트랙만 다루는 것이 적절하다. 현재 파일 수와 테스트 분포상 한 트랙이 1회 코드리뷰 대화에서 다룰 수 있는 현실적인 최대 범위에 가깝다.
- 추정: `0. Baseline Inventory And Review Rules`를 먼저 진행하면 이후 트랙의 발견사항 형식과 검증 기준이 흔들릴 가능성이 줄어든다.
- 추정: `3. Keyboard Layout, Views, And Assets`와 `6. Keyboard Extension Entry Points`는 실제 시뮬레이터 수동 확인까지 하면 각각 별도 채팅으로 두는 편이 낫다.

## Open Questions

- 각 트랙에서 실제 코드 변경까지 진행할지, 리뷰 findings만 수집할지 아직 정하지 않았다.
- 수동 시뮬레이터 검증을 Codex가 직접 수행할지, 사용자가 실제 기기/시뮬레이터에서 확인할지 아직 정하지 않았다.

## Suggested Finding Format

```text
## Findings

- [P1] 파일:라인 - 사용자 영향 또는 회귀 위험
  - 근거:
  - 제안:
  - 검증:

## Open Questions

- 확인이 필요한 전제

## Verification Suggestions

- 실행할 명령 또는 수동 확인 흐름

## Handoff

- 다음 리뷰 트랙으로 넘길 내용
```

## Finding Priority Criteria

- `P1`: 즉시 수정해야 하는 문제. 빌드/테스트 실패, 사용자 입력 손상, 데이터 손실, 크래시, 보안/권한 위험, 명백한 기능 회귀처럼 다음 단계 진행을 막는 항목이다.
- `P2`: 다음 트랙이나 병합 전 수정해야 하는 문제. 회귀 가능성이 높은 설계 결함, 검증 누락, 모듈 계약 불일치, 문서와 실제 절차의 불일치처럼 방치하면 리뷰 결론을 흐릴 수 있는 항목이다.
- `P3`: 추적하면 좋은 개선 사항. PR 템플릿 보강, 문서 표현 정리, 유지보수 편의 개선처럼 즉시 기능 위험은 낮지만 후속 작업 품질을 높이는 항목이다.

## Verification Notes

- 문서 작성 전 `git status --short`를 실행했고 출력이 없었다.
- 0번 baseline 리뷰에서 `git status --short --branch`, `git branch -vv`, `git log --oneline --decorate -8`, `git diff 8494534d31699afbdc4d0f981573c19a74850149..HEAD --stat`를 실행했다.
- 일반 샌드박스에서 `xcodebuild -list -project SYKeyboard.xcodeproj`가 권한 오류로 실패한 뒤, 권한 있는 환경에서 같은 명령을 재실행해 성공을 확인했다.
- 사용자가 전체 리뷰 findings를 종합 문서로 모으기로 결정해 `dev/active/code-review-scope/code-review-scope-findings.md`를 추가했다.
- 코드 빌드나 테스트는 실행하지 않았다. 이번 작업은 리뷰 범위와 baseline 절차 문서화이며 코드 동작 변경이 없다.
- 2번 리뷰에서 일반 샌드박스의 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`는 CoreSimulatorService, clang ModuleCache, SwiftPM ManifestLoading 권한 오류로 실패했다.
- 같은 테스트를 권한 있는 환경에서 재실행했고 `iPhone 13 mini / iOS 16.0`에서 `TEST SUCCEEDED`를 확인했다.
- 4번 리뷰에서 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트를 실행하고 Track 4 findings를 교차검증했다.
- 4번 리뷰의 Track 4 집중 테스트는 일반 샌드박스에서 CoreSimulatorService, clang ModuleCache, SwiftPM ManifestLoading 권한 오류로 실패했다.
- 같은 집중 테스트를 권한 있는 환경에서 재실행했고 `iPhone 13 mini / iOS 16.0`에서 `TEST SUCCEEDED`를 확인했다.
- 4번 리뷰에서 권한 있는 환경의 전체 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`도 `TEST SUCCEEDED`를 확인했다.
- 5번 리뷰에서 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트를 실행하고 Track 5 findings를 교차검증했다.
- 5번 리뷰에서 일반 샌드박스의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 CoreSimulator/SwiftPM cache 권한 오류로 실패했다.
- 5번 리뷰에서 권한 있는 환경의 `xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`는 `BUILD SUCCEEDED`로 통과했다.
- 3번 리뷰에서 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트를 실행하고 Track 3 findings를 교차검증했다.
- 3번 리뷰에서 일반 샌드박스의 HangeulKeyboard/EnglishKeyboard 빌드는 CoreSimulator/SwiftPM cache 권한 오류로 실패했다.
- 같은 빌드를 권한 있는 환경에서 재실행했고 `iPhone 13 mini / iOS 16.0`에서 HangeulKeyboard와 EnglishKeyboard 모두 `BUILD SUCCEEDED`를 확인했다.
- Track 3의 두 finding은 빌드로 재현되지 않는 시각/Auto Layout 문제이므로 실제 extension과 preview 수동 검증이 남아 있다.
- 6번 리뷰에서 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트를 실행하고 Track 6 findings를 교차검증했다.
- 6번 리뷰의 일반 샌드박스 `xcodebuild -showBuildSettings`는 CoreSimulator/SwiftPM cache 권한 오류로 실패했다.
- 6번 리뷰에서 권한 있는 `HangeulKeyboard` 빌드는 `iPhone 13 mini / iOS 16.0`에서 성공했다.
- 6번 리뷰의 첫 EnglishKeyboard 빌드는 HangeulKeyboard와 동일 DerivedData에서 병렬 실행되어 build database/Info.plist 작업 충돌로 실패했다. 별도 `/private/tmp/SYKeyboard-Track6-English` DerivedData 경로에서 단독 재실행한 빌드는 성공했다.
- EnglishKeyboard에 `APPLICATION_EXTENSION_API_ONLY=YES`를 명령행에서 전역 override한 검증은 host app에도 설정이 적용되어 `UIApplication.shared`에서 실패했다. target 단독 override 재시도는 DerivedData 내부 충돌로 완료하지 못했다.
- `plutil -lint`로 한글/영문 extension의 Info.plist와 entitlements, 메인 앱 Info.plist가 모두 유효함을 확인했다.
