# 두벌식·쿼티 숫자 행 설계

## 목적

GitHub Issue #138에 따라 두벌식·쿼티 자판 맨 윗줄에 숫자 행(1~0)을 표시하는 설정을
추가한다. 숫자 행이 켜져 있으면 첫 줄의 길게 누르기 숫자 입력이 중복되므로, 길게
누르기 보조 입력을 대문자·쌍자음 입력으로 바꾼다. 나랏글·천지인은 바꾸지 않는다.

## 확인한 기준

- 작업 브랜치: `feat/#138-number-row`, 기준 커밋 `9049f8cd`(develop).
- 세로 높이는 `KeyboardHeightPolicy.height(...)`가 `keyboardHeight`(기본 240, 설정
  슬라이더 190~290) + 자동완성 바 44로 계산한다. 가로는
  `KeyboardLayoutFigure.landscapeKeyboardHeight` 188로 고정이다.
- 행 높이는 키 영역에서 프레임 여백 4pt를 뺀 값을 4로 나눈다. 세로 기본값 59pt,
  슬라이더 최소값 46.5pt, 가로(188 - 44 = 144) 35pt다.
- 두벌식(`DubeolsikKeyboardView`)과 쿼티는 `StandardKeyboardView`를 베이스로 한다.
  `primaryKeyList`/`secondaryKeyList`는 `[비shift, shift]` 두 층으로 되어 있고,
  현재 두 층 모두 첫 줄 `secondaryKeyList`가 1~0이다
  (`EnglishKeyboardMode.secondaryKeyList`, `DubeolsikKeyboardView.secondaryKeyList`).
- 길게 누르기 동작은 `LongPressAction`(`repeatInput` 기본 / `numberInput` / `disabled`)
  설정이며, 설정 화면은 `InputSettingsView`다. 보조 키 입력 여부는
  `KeyboardTextInteractionPolicy.shouldInsertSecondaryKey(...)`가 결정한다.
- 한글 보조 키 입력은 `HangeulKeyboardCoreViewController.insertSecondaryKeyText(from:)`가
  `inputAdapter.input(secondaryKey)`로 오토마타를 거치므로 쌍자음 조합 규칙은 기존
  Processor가 처리한다.
- 한글 extension의 자판은 `selectedHangeulKeyboard`(기본 `.naratgeul`)로 고른다.
  한영 통합 extension의 영문 자판은 쿼티다.

## 결정 사항

### 설정

- `UserDefaultsKeys.showsNumberRow`, `DefaultValues.showsNumberRow = false`를 추가하고
  `UserDefaultsManager`에 노출한다. `UserDefaultsContractTests`에 키를 등록한다.
- 앱 설정의 '키보드 높이' 근처에 '숫자 행 표시' 토글을 둔다.
- 기본값이 꺼짐이므로 기존 사용자의 높이·레이아웃·길게 누르기 동작은 바뀌지 않는다.

### 높이

- 숫자 행 높이는 `keyboardHeight`와 무관한 방향별 고정값이다.
- 세로 모드 숫자 행은 키보드 높이 슬라이더 최소값(190)일 때의 글자 행 높이와 같다. 현재 수식으로 `(190 - keyboardFrameSpacing 4) / 4 =
  46.5pt`이고, 그 안의 키 버튼 높이는 `insetDy` 4를 위아래로 뺀 38.5pt다.
  - 최소값 190은 지금 `KeyboardHeightSettingsView`의 슬라이더 범위에 하드코딩되어 있다.
    `KeyboardLayoutFigure`에 키보드 높이 범위 상수로 올려 슬라이더와
    `KeyboardHeightPolicy`가 함께 사용한다.
  - `SwitchButton`의 주석은 최소 키 높이를 39.5pt로 적고 있으나, `9049f8cd`에서
    프레임 여백을 위아래로 나눈 뒤 실제 값은 38.5pt다. 구현 시 실제 값을 테스트로
    확인하고 주석을 바로잡는다.
- 글자 4행 영역은 사용자가 설정한 `keyboardHeight` 그대로 유지한다. 숫자 행 높이는
  그 위에 더한다. 기본값 기준 세로 키 영역은 240 + 46.5 = 286.5pt다.
- 가로 모드 숫자 행은 가로 글자 행 높이와 같은 35pt(키 버튼 27pt)다.
  기존 188 고정 높이 위에 더해 전체 223pt가 된다. 자동완성 바가 보이면 기존처럼
  188 안에서 44를 빼므로 글자 4행 영역은 지금과 같다.
  - 35pt는 자동완성 바가 보일 때의 가로 행 높이 `(188 - 44 - 4) / 4`로 고정한다.
    바가 숨겨져 글자 행이 46pt로 커져도 숫자 행은 35pt를 유지한다.
  - 화면 높이 375pt 기기(iPhone 13 mini·SE)의 가로 모드에서 앱 영역은 약 152pt 남는다.
- 추가 높이는 다음을 모두 만족할 때만 적용한다. 세로·가로 모두 해당한다.
  1. `showsNumberRow == true`
  2. 현재 extension이 두벌식 또는 쿼티 자판을 가진다
     - 영어 extension: 항상
     - 한글 extension: `selectedHangeulKeyboard == .dubeolsik`일 때만
     - 한영 통합 extension: 항상 (영문 자판이 쿼티)

### 레이아웃

- `StandardKeyboardView` 최상단에 숫자 행(1~0)을 추가한다. 두벌식·쿼티가 공유한다.
- 숫자 행은 설정이 켜져 있으면 세로·가로 모두 보인다.
- 기호·숫자·텐키 자판과 한영 통합의 4x4 한글 자판은 숫자 행 없이 **같은 전체 높이**
  안에서 기존 행이 늘어난다. 자판 전환·한영 전환 시 프레임 높이가 바뀌지 않는다.
- 숫자 키 탭은 숫자를 입력한다. 두벌식 조합 중이면 조합을 확정한 뒤 입력한다.
  기호 자판의 숫자 입력 경로를 재사용하며, 구체 경로는 구현 계획에서 코드로 확인한다.
- 숫자 키는 보조 키가 없다. 길게 누르기는 현재 `LongPressAction` 설정에 따른다.
- 앱 설정 미리보기(`PreviewKeyboardView`)도 숫자 행 높이를 반영한다.

### 길게 누르기

- `showsNumberRow == true`이고 `LongPressAction == .numberInput`이면 두벌식·쿼티의
  보조 키가 shift 짝 문자로 바뀐다. 기존 두 층 구조에서 비shift 층의 보조 키는 shift
  층 문자, shift 층의 보조 키는 비shift 층 문자가 된다.
  - 쿼티: 모든 글자 키. 비shift는 대문자, shift는 소문자.
  - 두벌식: ㅂㅈㄷㄱㅅㅐㅔ ↔ ㅃㅉㄸㄲㅆㅒㅖ. shift 짝이 없는 키는 보조 키가 없어
    기존처럼 기본 문자를 입력한다.
  - 키 모서리 힌트도 새 보조 문자를 표시한다.
- 한글 보조 입력은 기존처럼 `inputAdapter.input(secondaryKey)`를 거친다.
- `repeatInput`, `disabled` 설정과 나랏글·천지인은 바뀌지 않는다.
- 저장 값(`LongPressAction` raw value)은 바꾸지 않는다. `InputSettingsView`의
  `numberInput` 항목 표시 이름만 숫자 행이 켜져 있으면 '대문자·쌍자음 입력'으로
  바꾼다. 문자열은 `.xcstrings`에 추가한다.

## 범위 밖

- 나랏글·천지인 숫자 행
- 숫자 행 높이 사용자 설정
- 숫자 키의 길게 누르기 기호 입력

## 테스트

- `KeyboardHeightPolicy`: 설정 on/off × 세로/가로 × 자동완성 바 표시 여부 × 두벌식·쿼티
  유무 조합별 전체 높이와 숫자 행 높이의 정확한 값 (세로 46.5, 가로 35)
- 보조 키 선택 규칙: `showsNumberRow`, `LongPressAction`, shift 상태 조합별 결과
  (production 규칙을 호출해 정확한 문자로 검증)
- 두벌식 Processor: 길게 눌러 입력한 ㅆ·ㄲ가 초성·받침으로 조합되는지, ㅒ·ㅖ가
  모음으로 조합되는지
- 빌드: `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard`
  scheme을 `iPhone 13 mini / iOS 18.6`에서 빌드
- 수동: 실제 입력 앱에서 세 extension의 자판·한영 전환 시 높이 유지, 가로 전환 시
  숫자 행 표시와 223pt 높이, 설정 미리보기 높이를 확인한다
