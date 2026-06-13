# Code Review Scope Tasks

Last Updated: 2026-06-14

## Setup Checklist

- [x] `dev-docs` 스킬 지침을 확인한다.
- [x] `dev/README.md`를 읽는다.
- [x] `dev/templates/`의 3종 템플릿을 확인한다.
- [x] `dev/codex-skill-playbook.md`의 `docs-and-infrastructure` 지침을 확인한다.
- [x] `git status --short`로 현재 변경 상태를 확인한다.
- [x] 저장소 주요 디렉터리와 Swift 파일 분포를 확인한다.
- [x] 기존 `dev/active/` 작업 문서 목록을 확인한다.
- [x] 코드리뷰 범위를 채팅 단위로 나눈다.
- [x] 각 범위별 주요 파일, 핵심 질문, 권장 검증 명령을 문서화한다.
- [x] 다음 채팅에서 재사용할 프롬프트 템플릿을 작성한다.

## Review Execution Checklist

- [x] `0. Baseline Inventory And Review Rules` 리뷰를 별도 채팅에서 진행한다.
- [x] `1. Hangeul Input Domain Logic` 리뷰를 별도 채팅에서 진행한다.
- [x] `2. Common Keyboard Interaction Runtime` 리뷰를 별도 채팅에서 진행한다.
- [x] `4. Predictive Text And Suggestion Bar` 리뷰를 별도 채팅에서 진행한다.
- [x] `5. Settings And UserDefaults Contract` 리뷰를 별도 채팅에서 진행한다.
- [x] `3. Keyboard Layout, Views, And Assets` 리뷰를 별도 채팅에서 진행한다.
- [x] `6. Keyboard Extension Entry Points` 리뷰를 별도 채팅에서 진행한다.
- [x] `7. Main App Shell, Onboarding, Ads, And Resources` 리뷰를 별도 채팅에서 진행한다.
- [x] `8. Build, Packaging, And Repository Hygiene` 리뷰를 별도 채팅에서 진행한다.
- [x] 각 채팅의 findings를 하나의 종합 목록으로 병합할지 결정한다.

## Completed Review Notes

- 0번 baseline 리뷰에서 현재 브랜치, HEAD, 작업트리 상태, active 작업 문서, scheme 목록, Xcode 샌드박스 재시도 절차를 확인했다.
- 0번 baseline 리뷰 결과로 `code-review-scope-context.md`에 현재 inventory, priority criteria, 검증 결과를 보강했다.
- 사용자가 각 채팅의 findings를 종합 문서로 모으는 방식을 선택했다.
- `code-review-scope-findings.md`를 추가하고 0번 baseline 리뷰 findings를 반영 완료 상태로 기록했다.
- 1번 한글 입력 도메인 리뷰에서 나랏글 이중모음 교차 입력 처리 P2, 천지인 전체 삭제 검증 누락 P3를 발견해 `code-review-scope-findings.md`에 누적했다. 이후 사용자가 나랏글 이중모음 교차 입력 처리는 의도된 동작이라고 확인해 해당 P2를 `Invalid`로 정정했다.
- 1번 리뷰 검증으로 일반 샌드박스와 권한 있는 환경에서 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행했다. 일반 샌드박스는 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 실행은 `TEST SUCCEEDED`로 통과했다.
- 2번 공통 키보드 interaction runtime 리뷰에서 취소된 텍스트 팬의 입력 실행 P1, `touchCancel` 눌림 상태 잔존 P1, 취소된 키보드 전환 제스처 확정 P2를 발견해 `code-review-scope-findings.md`에 누적했다.
- 2번 리뷰 검증으로 일반 샌드박스와 권한 있는 환경에서 동일한 `xcodebuild test`를 실행했다. 일반 샌드박스는 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 `iPhone 13 mini / iOS 16.0` 실행은 `TEST SUCCEEDED`로 통과했다. 기존 테스트에는 제스처 취소 및 `touchCancel` 상태 전이 검증이 없다.
- 4번 자동완성/suggestion bar 리뷰에서 selection 변경 후 stale 후보 적용 P1, 다른 위치의 동일 대치 문구 복구 P1, 단어 내부 suffix 텍스트 대치 P1, 첫 lexicon 로딩 전 대치 누락 P2, n-gram reset 경쟁 조건 P2, 로딩 전 n-gram 기록 누락 P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 4번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 코드 경로 검토를 교차검증했다.
- 4번 리뷰의 Track 4 집중 테스트는 일반 샌드박스에서 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 `iPhone 13 mini / iOS 16.0` 실행은 `TEST SUCCEEDED`로 통과했다. 기존 테스트에는 새 findings의 상태 전이를 직접 검증하는 케이스가 없다.
- 4번 리뷰의 권한 있는 전체 `SYKeyboard` 테스트도 `iPhone 13 mini / iOS 16.0`에서 `TEST SUCCEEDED`로 통과했다.
- 사용자 수동 확인 결과 필드 변경/텍스트 필드 탭/커서 이동 시 `textWillChange(_:)`와 `textDidChange(_:)`가 호출되어 input buffer와 후보가 갱신됨을 확인했다. 이에 따라 selection 변경 후 stale 후보 적용 P1을 `Invalid`로 정정했다.
- 5번 Settings/UserDefaults 계약 리뷰에서 최초 설치 자동 대문자 기본값 불일치 P1, 키보드 controller 재진입 시 설정 미동기화 P2, 앱 전용 온보딩 manager 기본값 불일치 P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 5번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 코드 경로 검토를 교차검증했다.
- 5번 리뷰에서 학습 데이터 초기화 화면이 기존 Track 4의 n-gram reset 경쟁 조건 영향을 받는 것을 확인했으며, 중복 finding 대신 Track 4/5 handoff로 기록했다.
- 5번 리뷰의 일반 샌드박스 `xcodebuild -list`는 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 `SYKeyboard` 앱 빌드는 `iPhone 13 mini / iOS 16.0`에서 `BUILD SUCCEEDED`로 통과했다.
- 3번 Keyboard Layout, Views, And Assets 리뷰에서 한 손 키보드가 설정 폭보다 확장될 수 있는 P2와 비활성 기본 리턴 키 아이콘 색상 P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 3번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 코드 경로 검토를 교차검증했다.
- 3번 리뷰의 일반 샌드박스 HangeulKeyboard/EnglishKeyboard 빌드는 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 `iPhone 13 mini / iOS 16.0` 실행은 두 scheme 모두 `BUILD SUCCEEDED`로 통과했다.
- Track 3 findings는 실제 extension과 preview에서 portrait/landscape 수동 확인이 필요하다. 로컬 리소스 폴더의 ignored `.DS_Store` 실제 패키징 여부는 Track 8로 넘긴다.
- 6번 Keyboard Extension Entry Points 리뷰에서 전체 접근 미허용 상태의 오버레이 닫힘 저장 P2, EnglishKeyboard app-extension-safe API 검사 누락 P2, 설정 이동 실패 무시 P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 6번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 코드/target 설정 검토를 교차검증했다.
- 6번 리뷰의 일반 샌드박스 Xcode 확인은 CoreSimulator/SwiftPM cache 권한 오류로 실패했다. 권한 있는 `iPhone 13 mini / iOS 16.0` HangeulKeyboard 빌드와 별도 DerivedData 경로의 EnglishKeyboard 빌드는 성공했다.
- 6번 리뷰에서 한글/영문 extension Info.plist와 entitlements는 `plutil -lint`를 통과했다. 전체 접근 미허용 상태의 닫힘 유지와 설정 이동 버튼은 실제 extension 수동 검증이 남아 있다.
- 사용자 결정에 따라 설정 이동 실패 무시 P3는 `Deferred`로 변경했다. 사용자 실패 UI는 추가하지 않고 개발자 진단 로그만 후속 개선 대상으로 둔다.
- 사용자 결정에 따라 전체 접근 오버레이 닫힘 상태는 각 keyboard extension의 `UserDefaults.standard`에 저장하기로 했다. app-group 동기화/마이그레이션 없이 한글/영문 상태를 독립적으로 유지한다.
- 사용자 결정에 따라 EnglishKeyboard Debug/Release target에도 `APPLICATION_EXTENSION_API_ONLY = YES`를 적용하기로 했다. 후속 코드 변경 시 EnglishKeyboard extension target 빌드로 검증한다.
- 7번 Main App Shell, Onboarding, Ads, And Resources 리뷰에서 설정 이동 deep link와 최초 ATT 요청 충돌 P2, 화면 폭 변경 후 adaptive banner 크기 미동기화 P2, 광고 미수신 시 빈 하단 safe area P2, 자동 인앱 리뷰 요청 연결 해제 P2, 한국어 온보딩 문구의 영문 `or` P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 7번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 코드/리소스 경로 검토를 교차검증했다.
- 7번 리뷰의 일반 샌드박스 `SYKeyboard` 빌드는 CoreSimulator/SwiftPM cache 권한 오류로 실패했고, 권한 있는 `iPhone 13 mini / iOS 16.0` 실행은 `BUILD SUCCEEDED`로 통과했다.
- Track 7의 `sykeyboard://`는 현재 extension의 설정 이동 전용 URL이므로 URL 종류를 구분하지 않는 동작 자체는 finding으로 보지 않았다. 향후 다른 deep link를 추가할 때 명시적인 routing을 정의한다.
- Track 7의 ATT 충돌은 iOS 26.5 시뮬레이터에서 재현됐고, banner 성공/실패 및 회전/resize와 자동 리뷰 요청 흐름은 실제 UI 수동 검증이 남아 있다.
- Track 7의 한국어 온보딩 문구 P3는 `or`를 `드래그하거나` 표현으로 수정하고 실제 안내, preview, String Catalog 반영을 확인해 `Resolved` 처리했다.
- 8번 Build, Packaging, And Repository Hygiene 리뷰에서 fresh clone 빌드 준비 절차 부재 P2, Xcode 16+ 문서와 `swift-tools-version: 6.2` 계약 불일치 P2, 앱 번들에 저장소 문서/CI 스크립트 포함 P3, Meta mediation의 mutable `main` 의존 P3, 메인 앱 Info.plist 중복 key P3, generated SwiftPM workspace metadata 추적 P3를 발견해 `code-review-scope-findings.md`에 누적했다.
- 8번 리뷰는 `requesting-code-review` 지침에 따라 독립 코드리뷰 서브에이전트 결과와 로컬 project/package/산출물 검토를 교차검증했다.
- 8번 리뷰의 일반 샌드박스 `xcodebuild -list`와 `swift package` 확인은 CoreSimulator/SwiftPM cache 권한 오류로 실패했다. 권한 있는 환경의 `xcodebuild -list`와 별도 DerivedData 경로의 `SYKeyboard` 빌드는 `iPhone 13 mini / iOS 16.0`에서 성공했다.
- 빌드 산출물에서 `SYKeyboard.app/README.md`와 `SYKeyboard.app/ci_post_clone.sh` 포함을 확인했고, `SYKeyboardAssets` resource bundle에는 ignored `.DS_Store`가 포함되지 않은 것을 확인했다.
- 사용자 확인에 따라 Xcode Cloud의 secret 생성과 정상 CI/CD를 clean-environment 계약으로 인정해 fresh clone bootstrap finding을 `Invalid` 처리했다.
- 사용자가 `README.md` resource membership, `ci_post_clone.sh` app target membership, 중복 `DeveloperEmail`을 수정했고, `SYKeyboard` 재빌드 및 산출물 검사 후 관련 findings를 `Resolved` 처리했다.
- Meta mediation은 다른 라이브러리의 전이 의존성이 아니라 프로젝트와 메인 앱 Frameworks에 직접 추가된 package임을 확인했다. 이후 release version 기반 requirement로 다시 추가하고 Meta adapter `6.21.101` resolve와 앱 빌드를 확인해 mutable `main` branch finding을 `Resolved` 처리했다.

## Per-Chat Checklist

- [ ] 시작 시 `git status --short`를 확인한다.
- [ ] `dev/active/code-review-scope/`의 plan/context/tasks를 읽는다.
- [ ] 해당 트랙의 포함 파일과 제외 파일을 명시한다.
- [ ] 리뷰 중 다른 트랙 이슈를 발견하면 현재 채팅에서 깊게 파지 말고 handoff 항목으로 남긴다.
- [ ] 발견사항은 사용자 영향, 재현/근거, 제안, 검증 방법을 함께 쓴다.
- [ ] 발견사항을 `dev/active/code-review-scope/code-review-scope-findings.md`에 누적한다.
- [ ] 가능한 경우 관련 테스트나 빌드 명령을 실행한다.
- [ ] Codex 샌드박스 환경 실패와 실제 코드 실패를 구분해 기록한다.
- [ ] 마지막에 다음 리뷰 트랙으로 넘길 사항을 정리한다.

## Review Prompt Shortcuts

### Baseline

```text
SYKeyboard 전체 코드리뷰의 0번 범위인 "Baseline Inventory And Review Rules"만 리뷰해줘.
먼저 dev/active/code-review-scope/의 3종 문서를 읽고, 현재 git 상태, scheme, 검증 기준, 기존 active 작업 문서와 충돌 가능성을 확인해줘.
```

### Hangeul Domain

```text
SYKeyboard 전체 코드리뷰의 1번 범위인 "Hangeul Input Domain Logic"만 리뷰해줘.
Modules/HangeulKeyboardCore/Domain/와 관련 SYKeyboardTests/HangeulAutomataTests.swift, SYKeyboardTests/Processor/, SYKeyboardTests/Controller/를 중심으로 findings first 형식으로 리뷰해줘.
```

### Common Runtime

```text
SYKeyboard 전체 코드리뷰의 2번 범위인 "Common Keyboard Interaction Runtime"만 리뷰해줘.
BaseKeyboardViewController, ButtonStateController, GestureControllers, Policies, KeyboardUndoRedoManager, 버튼 이벤트 흐름을 중심으로 리뷰하고 UI layout 자체는 다음 트랙으로 넘겨줘.
```

### Layout And Assets

```text
SYKeyboard 전체 코드리뷰의 3번 범위인 "Keyboard Layout, Views, And Assets"만 리뷰해줘.
Modules/SYKeyboardCore/Presentation/View/, Modules/HangeulKeyboardCore/Presentation/View/, Modules/EnglishKeyboardCore/.../View/, SYKeyboardAssets/를 중심으로 레이아웃 안정성과 asset 접근을 리뷰해줘.
```

### Predictive Text

```text
SYKeyboard 전체 코드리뷰의 4번 범위인 "Predictive Text And Suggestion Bar"만 리뷰해줘.
SuggestionController, PredictiveText engines, SuggestionBarView, SuggestionButtonView, 관련 tests와 dev/active/snm-40-predictive-loading, dev/active/suggestion-bar-undo-redo 문서를 함께 확인해줘.
```

### Settings Contract

```text
SYKeyboard 전체 코드리뷰의 5번 범위인 "Settings And UserDefaults Contract"만 리뷰해줘.
SYKeyboard/Presentation/KeyboardSettings/, PreviewKeyboard, SYKeyboard/Storage/, Modules/*/Storage/를 중심으로 앱과 extension의 설정 키/기본값 계약을 리뷰해줘.
```

### Extension Entry Points

```text
SYKeyboard 전체 코드리뷰의 6번 범위인 "Keyboard Extension Entry Points"만 리뷰해줘.
Keyboards/HangeulKeyboard, Keyboards/EnglishKeyboard, Keyboards/Common의 extension lifecycle, full access, plist, entitlements, localization을 중심으로 리뷰해줘.
```

### Main App Shell

```text
SYKeyboard 전체 코드리뷰의 7번 범위인 "Main App Shell, Onboarding, Ads, And Resources"만 리뷰해줘.
SYKeyboard/App, SYKeyboard/Presentation/Content, InstructionsTab, BannerAd, RequestReview, SYKeyboard/Resources, Common/Firebase, Common/Configs를 중심으로 리뷰해줘.
```

### Build And Hygiene

```text
SYKeyboard 전체 코드리뷰의 8번 범위인 "Build, Packaging, And Repository Hygiene"만 리뷰해줘.
SYKeyboard.xcodeproj, SYKeyboardAssets/Package.swift, .github, README.md, AGENTS.md, dev/를 중심으로 scheme, target membership, package resources, 문서/저장소 hygiene을 리뷰해줘.
```
