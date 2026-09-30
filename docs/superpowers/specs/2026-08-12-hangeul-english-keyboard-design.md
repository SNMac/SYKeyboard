# 한·영 통합 키보드 설계

## 목적

GitHub Issue #46에 따라 기존 한글·영문 전용 keyboard extension을 유지하면서,
하나의 `HangeulEnglishKeyboard` extension 안에서 한글과 영어를 전환해 입력할 수
있게 한다.

통합 키보드는 기존 한글 조합·삭제·스페이스 정책과 영어 Shift·caps·Smart
Punctuation 정책을 복제하지 않고 재사용한다. globe 버튼은 iOS 시스템 키보드
전환을 계속 담당하고, 새 한/영 버튼은 통합 extension 내부 언어 전환만 담당한다.

## 완료된 기반 작업

현재 브랜치에는 다음 기반 작업이 이미 커밋돼 있다.

- `5999cae3` (`feat: #46 - 한영 통합 키보드 extension 추가 및 초기 설정`)
  - `HangeulEnglishKeyboard` target과 app embed 설정
  - Debug/Release xcconfig, entitlements, `Info.plist`
  - `PrimaryLanguage = mul`
  - Xcode 템플릿 수준의 `HangeulEnglishKeyboardViewController`
- `18e21fa9` (`feat: #46 - textDocumentProxy의 keyboardAppearance 적용 및 키보드 전환 버튼 위치 수정`)
  - 현재 `BaseKeyboardViewController` lifecycle에 맞춘 공통 변경

이 기반 작업은 새 implementation plan에서 다시 구현할 task로 취급하지 않는다.
다만 target membership, embed, plist, entitlement는 최종 빌드에서 다시 검증한다.

2026-08-12 baseline 검증은 iPhone 13 mini / iOS 16.0에서 수행했다.

- `SYKeyboard` Debug build 성공
- `HangeulEnglishKeyboard.appex`가 앱 build 산출물에 포함됨
- `SYKeyboardTests` 383개 통과, 실패·스킵 0개
- 위 결과는 현재 기반 코드의 검증이며 아직 통합 언어 전환 기능의 검증은 아니다.

## 현재 제약

- `HangeulEnglishKeyboardViewController`는 아직 `UIInputViewController` 템플릿이며
  기존 keyboard UI나 입력 로직을 사용하지 않는다.
- `BaseKeyboardViewController`와 `KeyboardView`는 하나의 primary view를 전제로
  action, feedback, gesture, 표시 상태를 구성한다.
- `HangeulKeyboardCoreViewController`의 composition state, Processor와 한글 view는
  controller 내부에 결합돼 있다.
- `EnglishKeyboardCoreViewController`의 영어 view와 Shift 상태도 controller 내부에
  결합돼 있다.
- Swift 단일 상속 때문에 통합 controller가 두 Core ViewController를 동시에
  상속할 수 없다.
- `SuggestionController.language`는 초기화 후 바뀌지 않아 mode 전환 시
  `UITextChecker`와 n-gram 언어를 전환할 수 없다.
- `SwitchButton`의 symbol/numeric 복귀 라벨은 생성 시점의 bundle
  `PrimaryLanguage`에 의존한다. `mul` extension에서는 현재 언어 mode를 표현하지
  못한다.
- `HangeulEnglishKeyboard` shared scheme은 현재 scheme 목록에 없다.

## 목표

- 통합 키보드에서 한글과 영어 primary view를 즉시 전환한다.
- 한글·영문 전용 extension의 기존 입력 동작과 이벤트 timing을 유지한다.
- 한글 조합 중 영어로 전환해도 문서에 반영된 글자를 잃지 않고 내부 조합 상태를
  안전하게 종료한다.
- TextField focus 변경 시 host가 제공하는 입력 언어 hint를 우선 사용하고,
  판별할 수 없으면 마지막 사용 언어, 저장값도 없으면 한글로 시작한다.
- 같은 TextField에서는 사용자의 수동 언어 선택을 callback이 덮어쓰지 않는다.
- mode에 맞춰 자동완성, n-gram, `primaryLanguage`, symbol/numeric 복귀 라벨을
  함께 전환한다.
- 기존 globe, one-handed, numeric, cursor/delete gesture 동작을 유지한다.

## 비목표

- 한글 Processor/Automata 규칙 변경
- 영어 자동 대문자나 Smart Punctuation 규칙 변경
- 사용자가 선택하는 별도 “기본 통합 키보드 언어” 설정 화면 추가
- host 앱이 제공하지 않는 TextField 언어를 문맥 분석으로 추측
- 통합 키보드를 위해 별도 `HangeulEnglishKeyboardCore` target 추가
- 자동완성 후보 가로 스크롤 또는 scroll edge effect 재도입
- Firebase, AdMob, bundle identifier, provisioning 구조 변경

## 확인한 UIKit 계약

- [`UITextDocumentProxy.documentInputMode`](https://developer.apple.com/documentation/uikit/uitextdocumentproxy/documentinputmode)는
  host document가 제공하는 현재 text input mode를 노출한다.
- [`UITextInputMode.primaryLanguage`](https://developer.apple.com/documentation/uikit/uitextinputmode/primarylanguage)는
  BCP 47 언어 식별자를 제공할 수 있다.
- host가 input mode를 저장하지 않거나 다국어 mode를 전달하면 값이 `nil`, `mul`
  또는 지원하지 않는 언어일 수 있으므로 확정값이 아닌 hint로 사용한다.
- `UIInputViewController.primaryLanguage`은 현재 통합 키보드 mode에 맞춰
  `ko-KR` 또는 `en-US`로 갱신한다.
- focus 변경과 TextField 탭은 현재 확인된 환경의 `textWillChange(_:)`와
  `textDidChange(_:)` 경로에서 동기화한다. 호출이 관찰되지 않은
  `selectionWillChange(_:)`/`selectionDidChange(_:)`에 의존하지 않는다.

## 선택한 구조

### 모드별 입력 어댑터를 조합하는 통합 ViewController

`HangeulEnglishKeyboardViewController`는 `BaseKeyboardViewController`를 상속하고
한글·영문 입력 어댑터를 조합한다.

- 한글 어댑터는 composition state, 선택된 Processor, 한글 입력·삭제·스페이스와
  전환 종료 API를 소유한다.
- 영어 어댑터는 Shift/caps 임시 상태, 자동 대문자 갱신과 typed text 입력 정책을
  소유한다.
- 기존 `HangeulKeyboardCoreViewController`와
  `EnglishKeyboardCoreViewController`도 같은 어댑터를 사용한다.
- 통합 controller는 mode 판정, active view 전환과 어댑터 routing만 담당한다.

이 방식은 한글 controller를 상속해 영어 예외를 누적하거나 입력 로직을 통합
controller에 복사하지 않는다. 기존 전용 extension과 통합 extension이 같은 입력
구현을 사용하므로 후속 수정이 서로 어긋나는 것을 방지한다.

### Core 경계

`SYKeyboardCore`는 언어에 독립적인 공통 상태와 UI 경계를 소유한다.

- `HangeulEnglishLanguageMode`
  - `.hangeul`, `.english`
  - locale 식별자 `ko-KR`, `en-US`
- `KeyboardLanguageModePolicy`
  - document language hint와 저장값을 mode로 매핑하는 순수 정책
- `UserDefaultsKeys`, `DefaultValues`, `UserDefaultsManager`
  - 마지막 통합 키보드 mode 저장
  - 기본값 `.hangeul`
- `BaseKeyboardViewController`, `KeyboardView`
  - 전체 primary view 목록과 active primary view를 구분
  - 공통 action/feedback/gesture는 전체 목록에 한 번만 등록
  - 표시·return·symbol/numeric 복귀는 active view 기준
- `SuggestionController`
  - 현재 prediction language 변경 계약 제공

`HangeulKeyboardCore`와 `EnglishKeyboardCore`는 각 언어 어댑터와 layout view를
제공한다. 접근 제어는 통합 target에 필요한 최소 API만 공개한다.

## primary view와 action 수명

`BaseKeyboardViewController`에는 다음 두 개념을 분리한다.

- 안정적인 `primaryKeyboardViews`: controller 수명 동안 바뀌지 않는 전체 목록
- 동적인 `primaryKeyboardView`: 현재 mode의 active view

`KeyboardView`는 전체 primary view를 같은 container에 한 번 추가한다. mode
전환은 view를 재생성하지 않고 `isHidden`과 active 참조만 변경한다.

다음 작업은 전체 primary 목록을 사용한다.

- button feedback action 등록
- text interaction action 등록
- exclusive/modifier action 등록
- 전체 버튼 configuration 갱신
- gesture controller의 한글·영문 primary 대상

다음 작업은 active primary view를 사용한다.

- 현재 표시 keyboard 판정
- return/space/shift 갱신
- symbol/numeric에서 primary로 복귀
- one-handed 표시 상태

비활성 primary view는 화면과 hit testing에서 제외한다. mode를 반복 전환해도 action을
다시 추가하지 않아 한 번의 touch가 중복 처리되지 않게 한다.

## 시작 언어 판정

새 `textInput` 식별자를 확인했을 때만 시작 mode를 판정한다.

1. `textDocumentProxy.documentInputMode?.primaryLanguage`이 `ko` 계열이면 한글
2. `en` 계열이면 영어
3. `nil`, `mul`, 빈 값 또는 다른 언어이면 저장된 마지막 mode
4. 저장값도 없거나 손상됐으면 한글

판정 결과가 active mode로 적용되면 마지막 사용 mode도 같은 값으로 갱신한다.
따라서 이후 언어 hint가 없는 TextField는 실제로 마지막에 사용한 mode를 이어받는다.

같은 `textInput` 식별자에서 발생한 `textDidChange(_:)`, cursor 이동과 selection
변경은 시작 mode를 다시 판정하지 않는다. 사용자가 한/영 버튼으로 고른 mode가
같은 TextField 안에서 유지돼야 한다.

`keyboardType`이 숫자·전화·십진 입력을 요구하면 언어 mode는 유지하고 표시
keyboard만 TenKey로 바꾼다. symbol keyboard에서도 mode는 유지한다.

## 수동 한/영 전환

한/영 버튼을 누르면 다음 순서를 지킨다.

1. 반복 입력과 현재 눌림 상태를 종료한다.
2. 한글에서 영어로 전환하면 문서에 이미 반영된 글자는 유지한다.
3. 한글 composition state와 Processor를 reset하고 지연된 undo group을 확정한다.
4. 영어에서 한글로 전환하면 영어 Shift/caps 임시 상태를 초기화한다.
5. active primary view와 `currentKeyboard`를 새 mode에 맞춘다.
6. 마지막 사용 mode를 저장한다.
7. `UIInputViewController.primaryLanguage`을 갱신한다.
8. symbol/numeric 복귀 대상, return, space, shift, one-handed 표시를 동기화한다.
9. 이전 후보를 지우고 새 언어의 후보 갱신을 요청한다.

`inputBuffer`는 같은 TextField의 keyboard session 문맥이므로 공유한다. 단,
composition state, Shift/caps, suggestion 후보와 n-gram 문장 버퍼는 mode 전환
경계에서 정리한다. 자동완성과 n-gram에는 mode 전환 이후의 active-language
segment만 전달해 이전 언어의 단어가 새 언어 엔진에 기록되지 않게 한다.

## 자동완성 언어 전환

`SuggestionController`는 language 변경 시 다음 계약을 따른다.

1. 동일 언어 요청이면 아무 작업도 하지 않는다.
2. 이전 n-gram 데이터를 저장한다.
3. 현재 후보, 문장 버퍼와 언어별 임시 상태를 초기화한다.
4. `UITextChecker`와 n-gram 엔진을 해제한다.
5. 새 language를 저장한다.
6. 새 엔진은 기존 첫 표시 지연 생성 정책을 유지한다.
7. Lexicon 엔진은 언어 독립이므로 재사용한다.

`NGramPredictiveTextEngine`은 기존 `ngram_{language}.plist` 파일과 언어별 queue를
사용하므로 `ko-KR`과 `en-US` 데이터가 분리된다. language가 바뀔 때 단조 증가하는
generation 값을 갱신하고, 비동기 load callback은 자신이 캡처한 generation과
language가 현재 값과 모두 일치할 때만 후보를 갱신한다.

## 전환 버튼 UI

### `LanguageSwitchButton`

- `SecondaryButton` 하위 타입이다.
- 표시 문자열은 항상 `한/영`이다.
- 한글 mode에서는 `한/`을 `.label`, `영`을
  `.languageSwitchMutedLabel`로 표시한다.
- 영어 mode에서는 `한`을 `.languageSwitchMutedLabel`, `/영`을 `.label`로
  표시한다.
- 하나의 attributed label에서 active/muted 범위를 갱신한다.
- text interaction 목록에는 넣지 않고 별도 mode 전환 action과 secondary button
  feedback만 연결한다.
- 통합 키보드의 primary view에만 표시한다.
- 기존 `SwitchButton` 옆에 배치한다.
- 공간 확보 시 `SwitchButton`의 `backgroundView`/`shadowView` visible 영역만
  줄이고 실제 `UIButton` touch bounds는 유지한다.

`SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/SYKeyboardAssets.xcassets/Colors/KeyboardButton/Secondary/`
아래에 `LanguageSwitchMutedLabelColor` asset을 만들고
`UIColor.languageSwitchMutedLabel` 접근자를 추가한다. 초기 light/dark 값은
`SuggestionButtonLabelColor`와 같지만 별도 asset으로 유지한다. 실제 화면 확인 후
한/영 버튼 색상만 독립 조정할 수 있어야 한다. 기존
`SuggestionButtonLabelColor`와 `.suggestionButtonLabel` 이름·동작은 변경하지
않는다.

### 기존 `SwitchButton`

| 현재 화면 | 언어 mode | 표시 라벨 |
|---|---|---|
| 한글 또는 영어 primary | 각 active mode | `!#1` |
| symbol/numeric | 한글 | `한글` |
| symbol/numeric | 영어 | `ABC` |

symbol/numeric 복귀 라벨은 생성 시점의 `Bundle.primaryLanguage`에 고정하지 않고
현재 mode를 전달받아 갱신한다. 기존 한글·영문 전용 extension은 각각 고정
`ko-KR`/`en-US`를 전달해 현재 표시를 유지한다. `mul`은 assertion 대상이 아니다.

## 설정·안내 화면

마지막 사용 mode는 내부 runtime 상태로 저장하며 별도 설정 항목을 추가하지 않는다.
앱의 키보드 등록 안내 문구는 실제 iOS 설정에서 세 extension이 별도 항목으로
표시되는지 확인한다. 현재 문구가 명백히 충돌할 때만 같은 이슈에서 최소 수정한다.

## 오류와 edge case

- 알 수 없는 language code는 assertion 없이 마지막 mode로 fallback한다.
- 손상된 저장 raw value는 한글 기본값으로 fallback한다.
- 동일 focus callback은 같은 `textInput` 식별자로 중복 판정을 막는다.
- mode 전환 중 이전 언어의 async suggestion callback은 새 mode 상태를 변경하지
  않는다.
- 한글 조합 종료가 실패 가능한 edit를 새로 만들지 않는다. 문서에 이미 반영된
  텍스트를 유지하고 내부 상태만 확정·초기화한다.
- 비활성 primary view는 action을 보유하더라도 hit testing되지 않는다.
- `textInput` identity를 확인할 수 없는 경우 현재 mode를 유지하고 강제 전환하지
  않는다.
- 외부 text context 변경은 `textWillChange(_:)`/`textDidChange(_:)`에서
  `inputBuffer`, 후보와 undo/redo 상태를 기존 정책대로 동기화한다.

## 고려한 대안

### 한글 Core ViewController 상속 후 영어 예외 추가

초기 수정량은 적지만 한글 전용 input/delete/space/undo override마다 영어 mode
guard가 필요하다. 누락 시 영어 입력이 한글 composition state를 거치므로 채택하지
않는다.

### 기존 입력 로직을 통합 ViewController에 복사

구현은 빠르지만 전용 keyboard와 통합 keyboard의 버그 수정이 분리된다. 동일한
입력 정책이 세 벌로 늘어나므로 채택하지 않는다.

### child ViewController 두 개를 교체

각 child가 전체 keyboard view, suggestion controller와 lifecycle을 소유해
`textDocumentProxy`, 높이, callback과 메모리가 중복된다. 커스텀 keyboard
extension에서 불필요하게 무거우므로 채택하지 않는다.

### 별도 HangeulEnglishKeyboardCore target

현재 extension target이 두 Core framework를 이미 연결한다. 새 target은 순환
의존성 또는 중간 public API를 늘리므로 채택하지 않는다.

## 변경 범위

- `Modules/SYKeyboardCore/`
  - language mode/policy, 저장값, 다중 primary view, dynamic `SwitchButton`,
    suggestion language 전환
- `Modules/HangeulKeyboardCore/`
  - 한글 입력 어댑터와 기존 controller 적용
- `Modules/EnglishKeyboardCore/`
  - 영어 입력 어댑터와 기존 controller 적용
- `Keyboards/HangeulEnglishKeyboard/`
  - 실제 통합 controller와 extension 초기화
- `SYKeyboardAssets/`
  - `LanguageSwitchMutedLabelColor`
- `SYKeyboardTests/`
  - production policy, adapter, controller integration과 회귀 테스트
- `SYKeyboard.xcodeproj/`
  - 새 파일 target membership과 통합 extension 독립 build 경로
- 필요할 때만 `SYKeyboard/Presentation/`
  - 세 키보드 등록 안내 최소 수정

## 검증

### 자동 테스트

- `ko`/`en`/`nil`/`mul`/기타 language hint 매핑
- 저장된 마지막 mode와 기본 한글 fallback
- 동일 TextField에서 수동 mode 보존, focus 변경 시 재판정
- 한글 → 영어 전환 시 문서 글자 유지와 composition/Processor/undo 정리
- 영어 → 한글 전환 시 Shift/caps 초기화
- suggestion language 전환의 save/reset/lazy recreation/stale callback 차단
- 전체 primary view action 단일 등록과 비활성 view 입력 차단
- `LanguageSwitchButton`의 active/muted 문자열 범위
- `SwitchButton`의 `!#1`/`한글`/`ABC` mode별 라벨

정확한 RGB, font, corner radius와 private subview 구조는 unit test로 고정하지
않는다. attributed 문자열의 active/muted 의미는 production policy로 검증하고
실제 색상은 화면에서 확인한다.

### 빌드와 전체 테스트

- `SYKeyboard` 전체 테스트
- `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard` build
- `HangeulEnglishKeyboard` shared scheme을 추가하고 독립 build
- `SYKeyboard` build 산출물에 통합 appex embed 확인
- `git diff --check`, `git status --short`로 문서와 코드 범위 확인

기본 destination은 iPhone 13 mini / iOS 16.0이다. 실제 설치된 가장 가까운
runtime을 사용하면 최종 결과에 기기와 OS를 정확히 기록한다.

### 실제 입력 화면

- iOS 16과 iOS 26 Simulator의 통합 키보드 활성화와 입력
- light/dark mode의 `LanguageSwitchMutedLabelColor`
- 한글 조합 중 전환, 영어 Shift/caps, 삭제, 스페이스, 리턴
- symbol/numeric에서 `SwitchButton` 동적 복귀 라벨
- globe, one-handed, numeric, cursor/delete gesture 충돌 부재
- `ko`/`en` document input mode가 있는 TextField focus 변경과 fallback
- iOS 설정에서 세 extension 등록 항목 확인

실제 host 화면을 관찰하지 못한 항목은 자동 테스트나 build로 대체했다고 표현하지
않으며 완료 또는 production-ready 판정에서 제외한다.

## 완료 기준

- 통합 extension이 기존 keyboard UI를 사용해 한글·영어 입력을 제공한다.
- focus 변경 시 document language hint, 마지막 mode, 한글 기본값 순서가 지켜진다.
- 같은 TextField의 수동 mode가 callback에 의해 덮어써지지 않는다.
- 한글 조합과 영어 Shift/caps가 mode 전환 경계에서 정의한 대로 정리된다.
- 자동완성과 n-gram이 현재 mode 언어와 일치하고 데이터가 언어별로 분리된다.
- 한/영 버튼과 기존 `SwitchButton` 라벨·역할이 정의한 매핑과 일치한다.
- 기존 한글·영문 extension의 입력 흐름과 gesture timing이 유지된다.
- 관련 테스트, 전체 테스트, 네 keyboard/app build 결과가 기록된다.
- iOS 16과 iOS 26 실제 입력 화면 검증 결과 또는 정확한 미확인 사유가 기록된다.
