# Code Review Scope Tasks

Last Updated: 2026-06-06

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
- [ ] `1. Hangeul Input Domain Logic` 리뷰를 별도 채팅에서 진행한다.
- [ ] `2. Common Keyboard Interaction Runtime` 리뷰를 별도 채팅에서 진행한다.
- [ ] `4. Predictive Text And Suggestion Bar` 리뷰를 별도 채팅에서 진행한다.
- [ ] `5. Settings And UserDefaults Contract` 리뷰를 별도 채팅에서 진행한다.
- [ ] `3. Keyboard Layout, Views, And Assets` 리뷰를 별도 채팅에서 진행한다.
- [ ] `6. Keyboard Extension Entry Points` 리뷰를 별도 채팅에서 진행한다.
- [ ] `7. Main App Shell, Onboarding, Ads, And Resources` 리뷰를 별도 채팅에서 진행한다.
- [ ] `8. Build, Packaging, And Repository Hygiene` 리뷰를 별도 채팅에서 진행한다.
- [x] 각 채팅의 findings를 하나의 종합 목록으로 병합할지 결정한다.

## Completed Review Notes

- 0번 baseline 리뷰에서 현재 브랜치, HEAD, 작업트리 상태, active 작업 문서, scheme 목록, Xcode 샌드박스 재시도 절차를 확인했다.
- 0번 baseline 리뷰 결과로 `code-review-scope-context.md`에 현재 inventory, priority criteria, 검증 결과를 보강했다.
- 사용자가 각 채팅의 findings를 종합 문서로 모으는 방식을 선택했다.
- `code-review-scope-findings.md`를 추가하고 0번 baseline 리뷰 findings를 반영 완료 상태로 기록했다.

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
