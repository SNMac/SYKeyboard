# Issue 71 Track 8 Hygiene Plan

Last Updated: 2026-06-20

## Goal

- GitHub Issue #71의 Track 8 open findings를 코드베이스 현실과 대조해 타당성을 판단하고, 타당한 항목의 수정 계획과 검증 기준을 정한다.

## Current State

- GitHub Issue #71의 open finding 2개는 타당한 항목으로 판단했고, 수정까지 적용했다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 8 해당 항목은 `Resolved`로 갱신했다.
- 관련 파일:
  - `README.md`
  - `AGENTS.md`
  - `SYKeyboardAssets/Package.swift`
  - `.gitignore`
  - `SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`
  - `dev/active/code-review-scope/code-review-scope-findings.md`

## Review Evaluation

### [P2] Xcode 16+ 문서 기준과 Swift tools 6.2 불일치

- 판단: 타당하다.
- 확인한 사실:
  - 최초 확인 시점의 `README.md`는 개발 환경 badge로 `Xcode 16 ~`를 표시했다.
  - 사용자 변경으로 현재 `README.md`의 Xcode 버전 badge는 제거됐다.
  - `AGENTS.md`는 Swift 5 프로젝트이며 Xcode 16 이상 기준이라고 설명한다.
  - 최초 확인 시점의 `SYKeyboardAssets/Package.swift`는 `// swift-tools-version: 6.2`를 선언했다.
  - 현재 `SYKeyboardAssets/Package.swift`는 `// swift-tools-version: 6.0`을 선언한다.
  - 현재 로컬 검증 환경은 `Xcode 26.5`, `Apple Swift version 6.3.2`다.
  - `SYKeyboardAssets/Package.swift`는 `.iOS(.v16)`, `.library`, `.target`, `.process("Resources")`만 사용한다.
- 기술 판단:
  - 문서가 말하는 최소 개발 환경과 package manifest가 요구하는 최소 Swift tools version이 서로 다른 것은 실제 bootstrap 실패로 이어질 수 있다.
  - 현재 manifest 내용만 보면 Swift tools 6.2 전용 기능을 쓰는 근거는 확인되지 않았다.
- 처리 방향:
  - `SYKeyboardAssets/Package.swift`의 tools version을 `6.0`으로 낮췄다.
  - README는 Xcode 버전 badge를 제거하고 local package의 tools version만 안내한다.
  - 현재 실사용 환경인 Xcode 26.5에서 package graph 해석과 앱 빌드를 검증했다.

### [P3] generated SwiftPM workspace metadata 추적

- 판단: 타당하다.
- 확인한 사실:
  - `.gitignore`에 `.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata` ignore 규칙이 있다.
  - `git ls-files` 결과 `SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`가 이미 추적 중이다.
  - 파일 내용은 Xcode/SwiftPM이 재생성 가능한 workspace metadata다.
- 기술 판단:
  - ignore 규칙과 실제 추적 상태가 충돌한다.
  - 생성 파일이므로 소스 산출물로 유지할 이유가 확인되지 않았다.
- 권장 수정 방향:
  - `git rm --cached SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`로 index에서만 제거한다.
  - 작업트리 파일은 삭제해도 Xcode가 재생성할 수 있으나, 이번 finding의 핵심은 추적 제거다.

## Approach

1. `SYKeyboardAssets/Package.swift`의 tools version을 `6.0`으로 낮췄다.
2. README와 AGENTS의 개발 환경 설명을 `swift-tools-version: 6.0` 기준과 맞췄다.
3. SwiftPM generated workspace metadata를 git 추적에서 제거했다.
4. nested SwiftPM workspace metadata도 ignore되도록 `.gitignore` 규칙을 보강했다.
5. `dev/active/code-review-scope/code-review-scope-findings.md`에서 두 finding의 상태와 처리/검증 결과를 갱신했다.

## Risks

- AGENTS에는 여전히 내부 작업 기준으로 Xcode 16 이상 표현이 남아 있다. README처럼 버전 없는 표현으로 바꿀지는 별도 결정이 필요하다.
- generated workspace 파일 제거는 staged deletion으로 남는다. 최종 커밋 전 `git status --short`로 범위를 확인해야 한다.

## Verification

- 현재 환경에서 실행할 검증:

```sh
xcodebuild -list -project SYKeyboard.xcodeproj
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
git status --short
```

- 실행 결과:
  - 일반 샌드박스의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 Xcode/SwiftPM 캐시와 CoreSimulator 권한 오류로 실패했다.
  - 권한 있는 환경의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 package graph 해석과 scheme 목록 출력을 완료했다.
  - 권한 있는 환경의 `xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`는 `BUILD SUCCEEDED`를 확인했다.
  - `git ls-files` 결과 generated workspace metadata는 더 이상 추적되지 않는다.
  - `git check-ignore -v` 결과 nested SwiftPM workspace metadata가 `.gitignore` 규칙으로 ignore된다.

## Done Criteria

- `SYKeyboardAssets/Package.swift`와 문서의 최소 개발 환경 설명이 서로 충돌하지 않는다.
- SwiftPM generated workspace metadata가 더 이상 git 추적 대상이 아니다.
- `dev/active/code-review-scope/code-review-scope-findings.md`의 Issue #71 관련 open finding 상태가 갱신된다.
- 가능한 빌드 또는 package graph 검증 결과가 기록된다.
