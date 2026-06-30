# Issue 46 Hangeul English Keyboard Context

Last Updated: 2026-07-01

## Relevant Files

- `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`: 현재 통합 키보드 principal class지만 템플릿 코드 상태다.
- `Keyboards/HangeulEnglishKeyboard/Resources/Info.plist`: `PrimaryLanguage = mul` 적용 여부를 확인하는 파일이다.
- `SYKeyboard.xcodeproj/project.pbxproj`: `HangeulEnglishKeyboard` target, embed, framework dependency, build settings가 들어 있다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 키보드 lifecycle, button action, text interaction, suggestion, current keyboard 표시 흐름의 공통 기반이다.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`: 현재 하나의 primary keyboard view를 nib에 주입한다.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`: 두벌식과 영어 qwerty가 공유하는 3-row primary layout이다.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift`: 나랏글 layout 기반이다.
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`: 천지인 layout 기반이다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`: `!#1`, `한글`, `ABC` symbol/primary 전환 버튼이며 one-handed/numeric gesture UI도 포함한다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/Bases/BaseKeyboardButton.swift`: 버튼 touch bounds와 visible background/shadow constraints를 분리한다.
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 한글 composition state, processor, 한글 입력/삭제/스페이스 정책을 가진다.
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`: 영어 qwerty 입력, shift/caps, auto capitalization 정책을 가진다.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: 자동완성, 텍스트 대치, n-gram 엔진 언어 상태를 가진다.

## Issue Facts Checked

- GitHub issue #46 제목: `[Feat] 한/영 통합 키보드 extension 추가`.
- issue 본문 요구:
  - 시스템 설정에서 한글, 영어, 한/영 통합 키보드를 각각 등록한다.
  - 통합 키보드 `Info.plist`의 `PrimaryLanguage`를 `mul`로 설정한다.
  - 통합 키보드 내부에 한/영 전환 버튼을 추가한다.
  - 한글 mode는 기존 한글 UI/processor/layout/조합 로직을 사용한다.
  - 영어 mode는 기존 영어 UI/layout을 사용한다.
  - 한/영 전환 시 composing, inputBuffer, 자동완성 상태 정책을 정한다.
  - globe/next keyboard와 내부 한/영 버튼 역할이 충돌하지 않게 설계한다.
  - 설정/안내 화면에서 키보드 3개 등록 안내 반영 여부를 검토한다.
- issue 체크리스트 중 `PrimaryLanguage = mul`만 완료로 표시되어 있었다.

## Repository Facts Checked

- `Keyboards/HangeulEnglishKeyboard/Resources/Info.plist`는 `PrimaryLanguage`가 `mul`이다.
- `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`는 `UIInputViewController`를 직접 상속하고 `Next Keyboard` 버튼만 추가한다.
- `SYKeyboard.xcodeproj/project.pbxproj`에는 `HangeulEnglishKeyboard.appex` product, app embed, `EnglishKeyboardCore.framework`, `HangeulKeyboardCore.framework` dependency가 보인다.
- `BaseKeyboardViewController.currentKeyboard`의 초기값은 `primaryKeyboardView.keyboard`다.
- `KeyboardView.loadFromNib(primaryKeyboardView:)`는 primary view 1개만 `keyboardLayoutView`에 추가한다.
- `BaseKeyboardViewController.setButtonFeedbackAction()`, `setTextInteractableButtonAction()`, `setSwitchButtonAction()`, `setExclusiveButtonAction()`은 action 등록 시점에 primary button 목록을 사용한다.
- `SwitchGestureController` 생성 시 현재는 `hangeulKeyboardView`와 `englishKeyboardView` 모두 `primaryKeyboardView as SwitchGestureHandling`으로 전달된다.
- `BaseKeyboardButton`은 전체 `UIButton` bounds를 touch 영역으로 쓰고, `backgroundView`/`shadowView` constraints를 visible 영역으로 관리한다.
- `DubeolsikKeyboardView`, `NaratgeulKeyboardView`, `CheonjiinKeyboardView`, `EnglishKeyboardView`는 현재 module-internal `final class`다.
- `HangeulKeyboardCoreViewController`의 `compositionState`, processor, 한글 view들은 `private`이라 통합 target에서 직접 재사용하기 어렵다.
- `EnglishKeyboardCoreViewController`의 영어 view와 shift state도 `private`이다.

## Decisions

- 한/영 버튼은 기존 globe/next keyboard 역할을 대체하지 않는다. globe/next keyboard는 iOS 시스템 키보드 전환, 한/영 버튼은 통합 keyboard 내부 mode 전환만 담당한다.
- 한/영 버튼 UI는 사용자가 정한 대로 `SwitchButton` 주변에 배치한다.
- `SwitchButton` 축소는 touch bounds가 아니라 visible 영역 기준으로 구현한다.
- 한글 mode에서 영어 mode로 전환할 때는 진행 중인 한글 조합을 확정 가능한 상태로 정리하고 한글 composition state와 processor를 reset한다.
- `inputBuffer`는 통합 keyboard session 단위로 공유하되, 자동완성 엔진 언어는 현재 mode에 맞춰 갱신한다.
- 설정/안내 화면 변경은 extension 동작 완성 후 현재 문구가 실제와 충돌하는지 확인한 뒤 최소 범위로 결정한다.

## Open Questions

- 통합 키보드의 최초 mode를 항상 한글로 시작할지, 마지막 사용 mode를 extension-local state로 저장할지 결정이 필요하다. 권장은 한글 시작 후 후속 사용성 피드백으로 last mode 저장을 검토하는 것이다.
- 자동완성 언어 전환 시 n-gram 파일을 언어별로 어떻게 분리하고 저장할지 구현 전 `NGramPredictiveTextEngine` 경로를 확인해야 한다.
- iOS 시스템 설정에서 `PrimaryLanguage = mul`이 실제로 어떻게 표시되는지는 시뮬레이터 또는 실기기에서 확인해야 한다.

## Verification Notes

- 실행함:

```sh
gh issue view 46 --repo SNMac/SYKeyboard --json number,title,body,state,labels,url
```

- 일반 sandbox에서는 GitHub API 네트워크 연결 실패가 발생했고, 권한 있는 실행에서 issue 본문 조회가 성공했다.
- 아직 빌드/테스트는 실행하지 않았다. 현재 작업은 구현 계획 문서 작성 범위다.
