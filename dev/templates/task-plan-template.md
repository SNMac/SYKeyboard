# <Task Name> Plan

Last Updated: YYYY-MM-DD

## Goal

- 한 문장으로 작업 목표를 적는다.

## Current State

- 확인한 현재 구조와 관련 동작을 적는다.
- 관련 파일:
  - `path/to/file.swift`

## Approach

- 구현 또는 문서화 방향을 단계별로 적는다.
- 기존 패턴을 어떻게 따를지 명시한다.

## Risks

- 입력 조합, 삭제, 설정 저장, 키보드 extension 런타임, Firebase/AdMob 등 위험 요소를 적는다.

## Verification

- 실행할 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- 수동 확인이 필요한 경우:
  - 예: 메시지 앱에서 한글 키보드 extension을 열고 입력/삭제 흐름 확인

## Done Criteria

- 요청한 동작 또는 산출물이 완성되었다.
- 관련 테스트나 빌드가 통과했거나, 실행하지 못한 이유가 기록되었다.
- 변경 범위가 의도한 파일에 한정된다.

