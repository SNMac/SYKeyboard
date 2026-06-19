# Issue 71 Track 8 Hygiene Context

Last Updated: 2026-06-20

## Relevant Files

- `README.md`: 개발 환경 섹션에서 Swift/iOS와 local package tools version을 안내한다.
- `AGENTS.md`: 프로젝트 작업 기준으로 Xcode 16 이상과 `SYKeyboardAssets` tools version을 설명한다.
- `SYKeyboardAssets/Package.swift`: 로컬 SPM package manifest이며 현재 `swift-tools-version: 6.2`를 선언한다.
- `.gitignore`: SwiftPM/Xcode generated workspace metadata ignore 규칙을 포함한다.
- `SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`: ignore 대상과 일치하지만 git에 추적 중인 generated metadata다.
- `dev/active/code-review-scope/code-review-scope-findings.md`: Track 8 findings의 원본 추적 문서다.

## Facts Checked

- GitHub Issue #71 REST API 확인 결과 이슈 제목은 `[Task] 코드리뷰 Track 8 - Build, Packaging, And Repository Hygiene findings 처리`다.
- Issue #71 본문에는 open checklist 2개가 있다.
  - `[P2] 문서의 Xcode 16+ 지원 기준과 로컬 package 최소 tools version이 일치하지 않음`
  - `[P3] generated SwiftPM workspace metadata가 git에 추적됨`
- Issue #71에는 추가 issue comment가 없다.
- 최초 확인 시점의 `README.md`에는 `Xcode 16 ~` badge가 있었다.
- `AGENTS.md`에는 `Swift 5 프로젝트이며 Xcode 16 이상을 기준으로 한다. SYKeyboardAssets 패키지는 swift-tools-version: 6.2를 사용한다.`는 설명이 있다.
- `SYKeyboardAssets/Package.swift` 첫 줄은 `// swift-tools-version: 6.2`다.
- `SYKeyboardAssets/Package.swift` 첫 줄을 `// swift-tools-version: 6.0`으로 변경했다.
- `README.md` 개발 환경 섹션에 로컬 SPM package가 `swift-tools-version: 6.0` manifest 기준이라는 설명을 추가했다.
- 사용자 변경으로 `README.md`의 Xcode 버전 badge가 제거됐다. README의 local package 설명도 Xcode 버전을 직접 언급하지 않도록 조정했다.
- `AGENTS.md`의 `SYKeyboardAssets` tools version 설명을 `6.0`으로 변경했다.
- 현재 로컬 도구 버전:
  - `xcodebuild -version`: `Xcode 26.5`, `Build version 17F42`
  - `xcrun swift --version`: `Apple Swift version 6.3.2`
- `SYKeyboardAssets/Package.swift`는 Swift tools 6.2 전용으로 보이는 manifest 기능을 사용하지 않는다.
- `.gitignore`에는 `.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata` 규칙이 있다.
- `git ls-files SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`는 해당 파일이 추적 중임을 보여준다.
- 해당 workspace metadata 파일 내용은 `self:` FileRef만 담은 생성 가능한 XML이다.
- 추적 제거 후 기존 `.gitignore` 규칙만으로는 `SYKeyboardAssets/.swiftpm/...` 파일이 ignore되지 않아 `**/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata` 규칙을 추가했다.
- `git ls-files SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata` 출력이 비어 있음을 확인했다.
- `git check-ignore -v SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata`가 `.gitignore:129` 규칙을 출력했다.
- 일반 샌드박스의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 Xcode/SwiftPM 캐시와 CoreSimulator 권한 오류로 실패했다.
- 권한 있는 환경의 `xcodebuild -list -project SYKeyboard.xcodeproj`는 package graph 해석과 scheme 목록 출력을 완료했다.
- 권한 있는 환경의 `xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`는 `BUILD SUCCEEDED`를 확인했다.
- 작업 시작 시 `git status --short --branch`는 `task/#71-track-8...origin/task/#71-track-8`만 표시했고, tracked/untracked 변경은 없었다.

## Decisions

- 두 리뷰 항목은 모두 타당한 finding으로 보고 수정했다.
- [P2]는 문서를 Xcode 26.x 기준으로 올리는 것보다 `SYKeyboardAssets` tools version을 낮추는 방향으로 처리했다.
- [P2]의 최종 검증은 현재 실사용 환경인 Xcode 26.5 기준으로 기록한다. README에서 Xcode 버전 기준을 제거했으므로 Xcode 16 실환경 검증은 필수 조건으로 두지 않는다.
- [P3]는 generated file을 git index에서 제거하고, nested package 경로까지 ignore되도록 `.gitignore`를 보강했다.

## Open Questions

- AGENTS의 내부 작업 기준인 Xcode 16 이상 설명도 README처럼 버전 없는 표현으로 바꿀지 여부는 별도 결정이 필요하다.

## Verification Notes

- 실행한 명령:

```sh
git status --short
sed -n '1,240p' dev/README.md
find dev/templates -maxdepth 1 -type f -print
gh issue view 71 --repo SNMac/SYKeyboard --comments
gh api repos/SNMac/SYKeyboard/issues/71
gh api repos/SNMac/SYKeyboard/issues/71/comments --paginate
sed -n '1,220p' dev/templates/task-plan-template.md
sed -n '1,220p' dev/templates/task-context-template.md
sed -n '1,220p' dev/templates/task-tasks-template.md
sed -n '1,220p' dev/codex-skill-playbook.md
sed -n '1,140p' README.md
sed -n '1,140p' AGENTS.md
sed -n '1,220p' SYKeyboardAssets/Package.swift
sed -n '110,145p' .gitignore
git ls-files SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
xcodebuild -version
rg -n "Track 8|Xcode 16|generated SwiftPM|swift-tools-version|package.xcworkspace|DeveloperEmail|mutable" dev/active/code-review-scope/code-review-scope-findings.md README.md AGENTS.md SYKeyboardAssets/Package.swift .gitignore
git ls-files -s SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
sed -n '1,80p' SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
xcrun swift --version
sed -n '309,390p' dev/active/code-review-scope/code-review-scope-findings.md
git status --short --branch
git rm --cached SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
xcodebuild -list -project SYKeyboard.xcodeproj
git check-ignore -v SYKeyboardAssets/.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- `gh issue view`는 GitHub GraphQL의 classic Projects deprecation 오류로 실패했지만, REST API 조회는 성공했다.
- 첫 `gh issue view` 일반 실행은 네트워크 제한으로 실패했고, 권한 있는 실행으로 REST API를 조회했다.
- `git rm --cached` 일반 실행은 `.git/index.lock` 생성 권한 오류로 실패했고, 권한 있는 실행으로 재시도해 성공했다.
- `xcodebuild -list` 일반 실행은 샌드박스 권한 오류로 실패했고, 권한 있는 실행에서 성공했다.
- `xcodebuild build`는 권한 있는 환경에서 성공했다.
