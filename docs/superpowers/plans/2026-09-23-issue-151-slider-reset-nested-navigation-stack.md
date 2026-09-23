# 슬라이더 직후 리셋 수정과 중첩 NavigationStack 제거 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** push되는 설정 화면 6곳의 중첩 `NavigationStack`을 걷어내고, iOS 27에서 슬라이더를 놓은 직후 누른 '리셋'이 한 번에 적용되게 한다.

**Architecture:** 먼저 스택만 걷어내고 화면·동작이 전과 같은지 확인한 뒤, 같은 재현 스크립트로 리셋 현상이 남는지 다시 본다. 남으면 리셋할 때마다 `Slider`의 `.id`를 바꿔 놓기 직후 상태의 이전 슬라이더를 버린다. 새 타입·새 파일·공용 컴포넌트는 만들지 않는다. 화면마다 `@State` 카운터 하나와 `.id` 한 줄이다.

**Tech Stack:** Swift 5, SwiftUI(`NavigationStack`, `Slider`, `.id`), Xcode 26 이상, `idb`(시뮬레이터 UI 조작), `xcrun simctl`

**Spec:** GitHub Issue #151 (`gh issue view 151`). 별도 spec 문서는 없고 이슈 본문을 요구사항으로 쓴다.

## Global Constraints

- 작업 브랜치는 `fix/#151-slider-reset-nested-navigation-stack`이고 `origin/develop`(`3892d822`, #152 머지 커밋)에서 딴다. 로컬 `develop`은 뒤처져 있으므로 반드시 `origin/develop`에서 딴다.
- 커밋 메시지는 `type: #151 - subject` 형식, 한국어, 마침표 없음. 끝에 아래 줄을 **이 문장 그대로** 넣는다. 자기 모델 이름으로 바꾸지 않는다.

  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  ```

- CLAUDE.md 「Superpowers 계획 실행」을 따른다. step은 작업과 검증이 모두 끝난 직후에만 체크하고, 체크와 실제 결과(빌드 결과, 재현 횟수, 확인하지 못한 항목)를 이 문서에 적어 그 step의 코드와 함께 **한 커밋**으로 남긴다. 검증만 하는 step도 이 문서를 고쳐 커밋한다.
- 변경 대상은 `SYKeyboard/Presentation/KeyboardSettings/`의 아래 6개 파일뿐이다. `Modules/`, 키보드 extension, `project.pbxproj`, 테스트 파일은 건드리지 않는다. 새 파일을 만들지 않는다.
  - `KeyboardHeightSettingsView.swift`, `LetterColumnWidthSettingsView.swift`, `OneHandedKeyboardWidthSettingsView.swift`, `LongPressSettingsView.swift`, `CursorMovementSettingsView.swift`, `ClipboardHistorySettingsView.swift`
- **유지하는 스택**: `ContentView`(최상위), `OpenSourceLicenseView`(`fullScreenCover`), 클립보드 `addSheet`·`detailSheet`(`sheet`), `KeyboardTypeTestView`의 `#Preview`. 건드리지 않는다.
- 제목·툴바·`.navigationBarBackButtonHidden()`·`.onAppear`·`.onDisappear`·`.requestReviewOnDetailSettingsReturn()` 등 기존 modifier는 순서와 위치를 그대로 둔다. 바뀌는 것은 감싸는 컨테이너뿐이다.
- 이 변경은 SwiftUI 화면 구조와 iOS 27 `Slider`의 런타임 동작에 관한 것이라 unit test로 고정할 production 로직이 없다. CLAUDE.md는 private subview 계층·`ForTesting` 메서드 테스트를 금지한다. **검증은 아래 재현 스크립트와 시뮬레이터 화면 비교로 한다.** 새 unit test를 만들지 않는다.
- `SYKeyboard/Resources/Configs/Secrets.xcconfig`는 만들거나 고치지 않는다. Firebase·AdMob·entitlements·bundle 설정도 건드리지 않는다.
- 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌린다. 그 외 항목이 바뀌었으면 되돌리지 말고 사용자에게 알린다.
- `git add`는 항상 파일을 명시한다. push·PR 생성은 사용자가 명시할 때만 한다.
- `xcodebuild`는 수 분 걸린다. 실행 전에 사용자에게 오래 걸린다고 알리고, 로그는 파일로 남긴다. 서브에이전트에 맡길 때는 foreground로 `timeout: 600000`을 주고, 몇 분씩 진행이 없으면 기다리지 말고 보고하게 한다(CLAUDE.md 「호스트 앱이 뜨지도 않고 테스트가 매달리는 경우」).

### 시뮬레이터

| 용도 | 기기 | UDID |
|---|---|---|
| 재현·수정 확인 | iPhone Air / iOS 27.0 | `30C7D731-84B5-4F30-B889-138E061E8910` |
| 회귀 확인·테스트 기준 | iPhone 13 mini / iOS 18.6 | `82146144-24DE-4F91-B25D-23D147A91142` |

UDID가 다르면 `xcrun simctl list devices available`로 다시 찾아 이 표를 고친다.

### 앱 빌드·설치 명령

`<UDID>`와 `<DD>`(DerivedData 경로, 실행 세션의 scratchpad 아래 `issue-151/dd`)를 채워 쓴다.

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -derivedDataPath <DD> \
  > <DD>/../build-<UDID>.log 2>&1; echo "exit=$?"; tail -5 <DD>/../build-<UDID>.log

xcrun simctl boot <UDID> 2>/dev/null; true
xcrun simctl install <UDID> <DD>/Build/Products/Debug-iphonesimulator/SYKeyboard.app
xcrun simctl status_bar <UDID> override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3
xcrun simctl terminate <UDID> github.com-SNMac.SYKeyboard 2>/dev/null; xcrun simctl launch <UDID> github.com-SNMac.SYKeyboard
```

앱이 붙여넣기 권한 알림을 띄우면 화면을 캡처해 확인하고 '허용'을 탭한 뒤 진행한다.

### 조작 도구 (실행 세션의 scratchpad에 저장해 쓴다)

`ax.py`: 현재 화면의 접근성 요소를 한 줄씩 출력한다. 화면 이동에 쓸 좌표를 찾을 때 쓴다.

```python
import json, subprocess, sys
U = sys.argv[1]
for e in json.loads(subprocess.check_output(["idb", "ui", "describe-all", "--udid", U])):
    print(e["type"], repr(e.get("AXLabel")), repr(e.get("AXValue")), {k: round(v) for k, v in e["frame"].items()})
```

- 앱은 시뮬레이터 언어에 따라 영어로 뜰 수 있다(예: 'One-Handed Keyboard Width', 'Long Press Input', 'Cursor Movement', 'Manage Clipboard History').
- 메인 화면은 테스트 텍스트 필드에 키보드가 올라와 있고 하단에 광고가 있어 스와이프가 가로막힌다. 먼저 `idb ui tap --udid <UDID> 210 180`처럼 키보드 밖 목록을 탭해 키보드를 내리고, 광고·키보드를 피한 구간(iPhone Air 기준 y 170~600)에서 `idb ui swipe --udid <UDID> --duration 0.3 210 600 210 300`으로 스크롤한다.
- **툴바 버튼('취소'·'리셋'·'저장')은 `describe-all`에 나오지 않는다.** 화면을 캡처해 좌표를 읽는다. 캡처는 픽셀 단위이므로 3으로 나눠 pt로 바꾼다(iPhone Air·13 mini 모두 @3x). 2026-09-23 iPhone Air 기준 '리셋'은 약 (298, 90), '취소'는 약 (62, 90)이었다. 스택을 걷어낸 뒤에는 위치가 바뀔 수 있으므로 매번 캡처로 다시 확인한다.

```sh
xcrun simctl io <UDID> screenshot <경로>.png
```

`slider_reset_repro.py`: 슬라이더를 끝까지 민 직후 리셋을 눌러 값이 기본값에 머무는지 본다. **실패가 버그 재현이고 PASS가 수정 확인이다.** 리셋 좌표가 틀리면 스스로 멈춘다.

```python
"""슬라이더를 끝까지 민 직후 리셋을 눌러 값이 기본값에 머무는지 확인한다.
사용: python3 slider_reset_repro.py <UDID> <리셋X> <리셋Y> [슬라이더순번=0] [반복=5]
화면은 미리 대상 설정 화면에 열어 두고, 슬라이더는 기본값 상태여야 한다."""
import json, subprocess, sys, time

udid, reset_x, reset_y = sys.argv[1], sys.argv[2], sys.argv[3]
index = int(sys.argv[4]) if len(sys.argv) > 4 else 0
rounds = int(sys.argv[5]) if len(sys.argv) > 5 else 5

def slider():
    items = json.loads(subprocess.check_output(["idb", "ui", "describe-all", "--udid", udid]))
    sliders = sorted((e for e in items if e["type"] == "Slider"), key=lambda e: e["frame"]["y"])
    return sliders[index]

def idb(*args):
    subprocess.run(["idb", "ui", *args, "--udid", udid], check=True)

baseline = slider()["AXValue"]
failures = 0
for n in range(1, rounds + 1):
    s = slider()
    f = s["frame"]
    y = f["y"] + f["height"] / 2
    thumb_x = f["x"] + f["width"] * float(s["AXValue"])
    idb("swipe", "--duration", "0.3", str(round(thumb_x)), str(round(y)), str(round(f["x"] + f["width"] - 2)), str(round(y)))
    idb("tap", reset_x, reset_y)
    time.sleep(1.0)
    value = slider()["AXValue"]
    ok = value == baseline
    failures += not ok
    print(f"{n}: {'PASS' if ok else 'FAIL'} baseline={baseline} after={value}")
    if not ok:
        # 두 번째 리셋은 기본값으로 돌아와야 한다. 아니면 리셋 좌표가 틀린 것이다
        idb("tap", reset_x, reset_y)
        time.sleep(1.0)
        if slider()["AXValue"] != baseline:
            sys.exit("리셋 탭이 값을 되돌리지 못함: 리셋 좌표를 다시 확인")
print(f"재현 {failures}/{rounds}")
sys.exit(1 if failures else 0)
```

- `슬라이더순번`은 화면 위에서부터 0, 1이다. '길게 누르기 입력'·'커서 이동'은 슬라이더가 둘이고 각 행에 '리셋'이 따로 있다. 이 두 화면의 행 '리셋'은 `describe-all`에 `Button 'Reset'`/`'리셋'`으로 나올 수 있으니 먼저 `ax.py`로 찾고, 없으면 캡처로 찾는다.
- 이 스크립트는 계획 작성 중(2026-09-23) iPhone Air / iOS 27에 이미 설치돼 있던 빌드(커밋 미확인)의 '한 손 키보드 너비' 화면에서 5/5, 3/3 재현을 확인했다. 잘못된 리셋 좌표(10, 400)로는 첫 회에 스스로 멈추는 것도 확인했다.

## Review Focus

이슈가 직접 말하지 않았지만 사용자가 가장 먼저 부딪힐 만한 경우다. 각 줄의 확인을 담당 task에 넣었다.

1. **가장자리 스와이프로 뒤로 가기**: 키보드 높이·글자 열 너비·한 손 너비는 `.navigationBarBackButtonHidden()`으로 '취소'만 보인다. 지금은 이 modifier가 안쪽 스택에 걸려 있고, 스택을 걷으면 바깥 스택의 push 화면에 걸린다. 스와이프로 뒤로 가기가 되는지가 바뀌면 사용자가 알아챈다. → Task 1 Step 2에서 전 동작을 기록하고 Task 2 Step 3에서 비교한다. 다르면 멈추고 사용자에게 묻는다.
2. **세로 간격**: `NavigationStack` 루트에 여러 뷰를 두던 배치를 `VStack`으로 바꾸면 기본 간격이 달라질 수 있다. → Task 2 Step 3에서 전후 캡처를 비교하고, 다르면 `VStack(spacing: 0)`으로 맞춘다.
3. **리셋 뒤 '저장'**: 사용자가 실제로 보는 결과는 저장된 값이다. 빠른 리셋 뒤 '저장'하고 다시 들어갔을 때 기본값이어야 하고, '취소'하면 원래 값이어야 한다. → Task 4 Step 1·2에서 확인한다.
4. **리셋 직후 다시 드래그**: `.id`로 슬라이더를 새로 만들면 바로 이어진 드래그가 먹히지 않거나 썸이 튈 수 있다. → Task 4 Step 1·2에서 리셋 직후 곧바로 드래그해 값이 따라오는지 본다.
5. **클립보드 화면에서 나온 뒤 하단 바**: 편집 모드에서 하단 바를 켠 채 뒤로 가면, 스택을 공유하게 된 상위 '키보드 툴바 설정' 화면에 빈 하단 바가 남을 수 있다. → Task 3 Step 2에서 확인한다.

---

## 작업 순서를 이렇게 잡은 이유

이슈는 중첩 스택이 리셋 현상에 관여하는지 분리해 확인하지 않았다. 스택부터 걷어내고(Task 2·3) 같은 스크립트로 다시 재현해 보면(Task 4 Step 0) 두 원인이 섞이지 않는다. 스택 제거만으로 사라지면 `.id` 수정은 필요 없다.

---

### Task 1: 브랜치 준비와 변경 전 기준 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md` (이 문서)

**Interfaces:**
- Consumes: 없음
- Produces: 변경 전 캡처 폴더 경로, 화면별 뒤로 가기 스와이프 동작, 화면별 리셋 재현 횟수. Task 2~4가 이 기록과 비교한다.

- [x] **Step 1: 브랜치를 만들고 이 계획을 커밋한다**

```sh
git status --short   # 이 계획 파일(untracked) 외에 변경이 없어야 한다
git fetch origin
git switch -c fix/#151-slider-reset-nested-navigation-stack origin/develop
git log --oneline -1  # 3892d822 Merge pull request #152 ...
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 슬라이더 리셋 수정과 중첩 NavigationStack 제거 계획 추가

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: 변경 전 빌드로 화면·뒤로 가기·리셋 기준을 기록한다**

Global Constraints의 빌드·설치 명령으로 이 브랜치(아직 코드 변경 없음)를 **두 시뮬레이터 모두**에 설치한다. 각 기기에서 아래 6개 화면을 열어 확인하고 캡처를 `<scratchpad>/issue-151/before/<기기>-<화면>.png`로 남긴다.

| 화면 | 진입 경로 |
|---|---|
| 키보드 높이 | 메인 → 외형 설정 '키보드 높이' |
| 글자 열 너비 | 메인 → 외형 설정 '글자 열 너비' (링크가 없으면 표시 조건을 켜는 설정을 먼저 켠다. `AppearanceSettingsView.showsLetterColumnWidthSettings` 참고) |
| 한 손 키보드 너비 | 메인 → 외형 설정 '한 손 키보드' 켜기 → '한 손 키보드 너비' |
| 길게 누르기 입력 | 메인 → 입력 설정 '길게 누르기 입력' |
| 커서 이동 | 메인 → 입력 설정 '커서 이동' |
| 클립보드 기록 관리 | 메인 → '클립보드 기록 관리' |

화면마다 아래를 확인한다.

1. 캡처 1장(진입 직후)
2. 가장자리 스와이프로 뒤로 가기: `idb ui swipe --udid <UDID> --duration 0.3 2 450 300 450` 후 캡처. 이전 화면으로 돌아갔는지 기록한다. 돌아가지 않았으면 '취소'(또는 뒤로) 버튼으로 나온다.
3. 슬라이더가 있는 5개 화면은 iPhone Air에서만 `slider_reset_repro.py`를 슬라이더마다 5회 돌려 재현 횟수를 기록한다. 시작 전 '리셋'을 한 번 눌러 기본값에 둔다. iPhone 13 mini / iOS 18.6에서는 키보드 높이 화면만 3회 돌린다(이슈 기록은 0/3).

결과를 아래 표에 채운다.

| 화면 | iOS 27 뒤로 스와이프 | iOS 18.6 뒤로 스와이프 | iOS 27 리셋 재현 |
|---|---|---|---|
| 키보드 높이 |  |  | /5 |
| 글자 열 너비 |  |  | /5 |
| 한 손 키보드 너비 |  |  | /5 |
| 길게 누르기 입력 (지연 시간 / 반복 속도) |  |  | /5, /5 |
| 커서 이동 (활성화 거리 / 이동 간격) |  |  | /5, /5 |
| 클립보드 기록 관리 |  |  | 해당 없음 |

iOS 18.6 키보드 높이 리셋 재현: /3

캡처 폴더 실제 경로:

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 변경 전 화면·뒤로 가기·리셋 재현 기준 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: 슬라이더 설정 화면 5곳의 중첩 NavigationStack 제거

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift:50,142-144`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift:50,145-147`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift:50,146-148`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift:27,105-107`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift:27,106-108`

**Interfaces:**
- Consumes: Task 1 Step 2의 기준표와 캡처
- Produces: 각 화면 `body`의 최상위 컨테이너가 `VStack`이 된다. Task 4는 이 구조 위에서 `Slider`에 `.id`를 붙인다.

- [ ] **Step 1: 키보드 높이·글자 열 너비·한 손 키보드 너비 화면의 스택을 걷어낸다**

세 파일 모두 `body` 첫 줄의 `NavigationStack {`만 `VStack {`으로 바꾼다. 닫는 `}`과 뒤따르는 `.onAppear`·`.onChange`·`.requestReviewOnDetailSettingsReturn()`은 그대로 둔다.

`KeyboardHeightSettingsView.swift` 결과:

```swift
    var body: some View {
        VStack {
            keyboardHeightSettings
            
            Spacer()
            
            PreviewKeyboardView(keyboardHeight: $previewKeyboardHeight,
                                keyboardSettingsHeight: tempKeyboardHeight,
                                oneHandedKeyboardWidth: $oneHandedKeyboardWidth,
                                letterColumnWidthMultiplier: $letterColumnWidthMultiplier,
                                needsInputModeSwitchKey: $needsInputModeSwitchKey,
                                previewKeyboardLanguage: $previewKeyboardLanguage,
                                oneHandedMode: $previewOneHandedMode)
        }.onAppear {
            tempKeyboardHeight = keyboardHeight
            updatePreviewKeyboardHeight()
        }.onChange(of: tempKeyboardHeight) { _ in
            updatePreviewKeyboardHeight()
        }.requestReviewOnDetailSettingsReturn()
    }
```

`LetterColumnWidthSettingsView.swift`, `OneHandedKeyboardWidthSettingsView.swift`도 50번째 줄 `NavigationStack {` → `VStack {` 한 줄만 바꾼다.

세 파일의 `#Preview`는 툴바가 미리보기에 보이도록 스택으로 감싼다.

```swift
#Preview {
    NavigationStack {
        KeyboardHeightSettingsView()
    }
}
```

```swift
#Preview {
    NavigationStack {
        LetterColumnWidthSettingsView()
    }
}
```

```swift
#Preview {
    NavigationStack {
        OneHandedKeyboardWidthSettingsView()
    }
}
```

빌드한다(iOS 18.6 기기, Global Constraints의 `xcodebuild build`). `exit=0`과 `** BUILD SUCCEEDED **`를 확인하고 `git status --short`로 `.xcscheme` 부수 변경을 정리한다.

```sh
git add SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
refactor: #151 - 키보드 높이·글자 열 너비·한 손 키보드 너비 화면의 중첩 NavigationStack 제거

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: 길게 누르기 입력·커서 이동 화면의 스택을 걷어낸다**

두 파일 모두 27번째 줄 `NavigationStack {` → `VStack {` 한 줄만 바꾼다. `List` 안쪽의 `.navigationTitle`·`.navigationBarTitleDisplayMode`·`.requestReviewOnDetailSettingsReturn()`과 바깥 `.onDisappear`는 그대로 둔다.

`LongPressSettingsView.swift` 결과:

```swift
    var body: some View {
        VStack {
            KeyboardTestView()
            List {
                Section {
                    longPressDurationSetting
                } header: {
                    Text("길게 누르기 지연 시간")
                }
                
                Section {
                    repeatRateSetting
                } header: {
                    Text("키 반복 속도")
                }
            }
            .navigationTitle("길게 누르기 입력")
            .navigationBarTitleDisplayMode(.inline)
            .requestReviewOnDetailSettingsReturn()
        }.onDisappear {
```

`#Preview`:

```swift
#Preview {
    NavigationStack {
        LongPressSettingsView()
    }
}
```

```swift
#Preview {
    NavigationStack {
        CursorMovementSettingsView()
    }
}
```

빌드해 `exit=0`을 확인하고 커밋한다.

```sh
git add SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
refactor: #151 - 길게 누르기 입력·커서 이동 화면의 중첩 NavigationStack 제거

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3: 5개 화면을 변경 전 기준과 비교한다**

두 시뮬레이터에 현재 브랜치를 설치하고 Task 1 Step 2와 같은 절차로 캡처를 `<scratchpad>/issue-151/after/`에 남긴다. 각 화면에서 아래를 확인한다.

- 제목, '취소'·'리셋'·'저장' 위치와 표시, 슬라이더·설명 문구·미리보기 키보드의 세로 위치가 before 캡처와 같다. 캡처를 나란히 열어 비교한다.
  - 세로 간격이 달라졌으면 해당 파일의 `VStack {`을 `VStack(spacing: 0) {`으로 바꿔 다시 비교하고, 무엇이 맞았는지 아래에 적는다. 그래도 다르면 멈추고 사용자에게 캡처를 보여 준다.
- '취소'는 저장하지 않고 나간다. '저장'은 값을 저장하고 나간다(다시 들어가 숫자 확인).
- 가장자리 스와이프 뒤로 가기가 Task 1 기준표와 같다. **다르면 멈추고 사용자에게 알린다**(Review Focus 1). 임의로 `.navigationBarBackButtonHidden()`을 바꾸지 않는다.
- 길게 누르기·커서 이동: 테스트 텍스트 필드 탭 시 키보드가 뜨고, 슬라이더를 움직이면 키보드가 내려간다(`hideKeyboard()`).

| 화면 | iOS 27 화면 동일 | iOS 18.6 화면 동일 | 뒤로 스와이프 동일 | 취소·저장 |
|---|---|---|---|---|
| 키보드 높이 |  |  |  |  |
| 글자 열 너비 |  |  |  |  |
| 한 손 키보드 너비 |  |  |  |  |
| 길게 누르기 입력 |  |  |  | 해당 없음 |
| 커서 이동 |  |  |  | 해당 없음 |

`VStack(spacing: 0)` 조정 여부:

조정했다면 해당 Swift 파일도 함께 커밋한다.

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 슬라이더 설정 화면 스택 제거 전후 비교 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: 클립보드 기록 관리 화면의 중첩 NavigationStack 제거

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift:72-121,753-755`

**Interfaces:**
- Consumes: Task 1 Step 2의 클립보드 화면 캡처
- Produces: `body`의 최상위가 `Group`이 된다. `addSheet`(320행)·`detailSheet`(579행)의 `NavigationStack`은 그대로다.

- [ ] **Step 1: `body`의 바깥 스택만 걷어낸다**

73행 `NavigationStack {`과 짝인 120행 `}`를 지우고 그 사이를 4칸 내어쓴다. modifier는 하나도 빼거나 옮기지 않는다. 결과:

```swift
    var body: some View {
        Group {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Text("복사한 텍스트나 이미지가 여기에 표시됩니다.")
                    limitDescription
                    imageLimitDescription
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            } else {
                historyList
            }
        }
        // 편집 모드에서 선택이 있으면 제목이 선택 수를 보여준다
        .navigationTitle(
            editMode.isEditing && !selection.isEmpty
            ? Text("\(selection.count)개 선택")
            : Text("클립보드 기록")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        // iOS 16은 bottomBar 항목을 나중에 추가하면 바가 안 뜨므로 항목은 두고 표시만 토글한다
        .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
        // 편집 버튼과 List가 같은 편집 상태를 보도록 toolbar 바깥에 둔다
        .environment(\.editMode, $editMode)
        // 시트가 떠 있는 동안 키보드가 기록을 바꿀 수 있으므로 닫힐 때 다시 읽는다
        .sheet(isPresented: $isAddSheetPresented, onDismiss: synchronizeAndReload) { addSheet }
        .sheet(item: $detailPresentation, onDismiss: { isDeletedItemAlertPresented = false }) { detailSheet(for: $0.item) }
        // 스와이프·편집 모드 삭제는 사용자가 의도한 동작이므로 HIG대로 알림이 아니라 action sheet로 확인한다. 취소는 시스템이 붙인다
        .onAppear(perform: synchronizeAndReload)
        .onChange(of: scenePhase) { phase in
            if phase == .active { synchronizeAndReload() }
        }
        // 앱 활성화 동기화(SYKeyboardApp)가 먼저 changeCount를 소비하면 이 화면의 동기화는 건너뛰므로,
        // 백그라운드 저장이 끝난 이미지는 알림으로 받아 목록을 다시 읽는다
        .onReceive(NotificationCenter.default.publisher(for: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification)) { _ in
            reload()
        }
        // 상세 시트에서 본문 일부를 복사하는 등 앱 안에서 pasteboard가 바뀌면 목록에 바로 반영한다. 열린 시트는 reload가 유지한다.
        // 시트의 "복사" 버튼은 쓴 직후 changeCount를 맞추므로, 그 갱신이 끝난 다음 runloop에서 확인해 중복 기록하지 않는다
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            DispatchQueue.main.async { synchronizeAndReload() }
        }
        .requestReviewOnDetailSettingsReturn()
    }
```

`#Preview`:

```swift
#Preview {
    NavigationStack {
        ClipboardHistorySettingsView()
    }
}
```

빌드해 `exit=0`을 확인하고 `git diff -w`로 들여쓰기 외 변경이 `NavigationStack {`·`}` 삭제와 `#Preview`뿐인지 본다.

```sh
git diff -w --stat
git add SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
refactor: #151 - 클립보드 기록 관리 화면의 중첩 NavigationStack 제거

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: 편집 모드·하단 바·시트 동작을 두 OS에서 확인한다**

항목이 2개 이상 있어야 한다. 없으면 '추가'(+)로 텍스트 고정 항목을 두 개 만든다. 두 시뮬레이터에서 아래를 확인하고 캡처를 `after/`에 남긴다.

| 확인 | iOS 27 | iOS 18.6 |
|---|---|---|
| 진입 시 제목 '클립보드 기록', 오른쪽 '+'·'선택' 표시, 하단 바 없음 (before 캡처와 같음) |  |  |
| '선택' → 하단 바 표시, 버튼이 '완료'로 바뀜 |  |  |
| 행 선택 시 제목이 'n개 선택'으로 바뀜 |  |  |
| 하단 바 '전체 선택'/'선택 해제' 토글 |  |  |
| 하단 바 고정 버튼으로 고정/해제 후 편집 모드 종료 |  |  |
| 하단 바 삭제 → 확인 시트가 삭제 버튼 근처에 뜸 → 취소 |  |  |
| 행 왼쪽 스와이프(고정)·오른쪽 스와이프(삭제 확인 시트) |  |  |
| 행 탭 → 상세 시트, 제목·툴바 표시, 닫기 |  |  |
| '+' → '고정 항목 추가' 시트, 취소·저장 |  |  |
| 편집 모드 중 뒤로 가기 → 상위 '키보드 툴바 설정' 화면에 빈 하단 바가 남지 않음 (Review Focus 5) |  |  |
| 뒤로 스와이프 동작이 Task 1 기준표와 같음 |  |  |

어느 항목이든 before와 다르면 멈추고 사용자에게 캡처와 함께 알린다. 하단 바 문제면 `.toolbar(... for: .bottomBar)` 주석(iOS 16 대응)을 근거로 임의 수정하지 않는다. iOS 16 화면은 Xcode 27 환경에서 확인할 수 없으므로 '미확인(iOS 16 런타임 없음)'으로 적는다.

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 클립보드 기록 관리 화면 스택 제거 후 동작 확인 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: 슬라이더 직후 리셋이 한 번에 적용되도록 수정

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift`
- Modify: `SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift`
- 조건부(Step 0 결정에 따라): `LongPressSettingsView.swift`, `CursorMovementSettingsView.swift`

**Interfaces:**
- Consumes: Task 2의 `VStack` 구조, `slider_reset_repro.py`
- Produces: 화면마다 `@State private var sliderResetCount = 0`과 `Slider(...).id(sliderResetCount)`. 리셋 버튼이 값과 함께 `sliderResetCount += 1`을 한다.

- [ ] **Step 0: 스택 제거 후 리셋 현상을 다시 재현한다 (결정 지점)**

iPhone Air / iOS 27에 현재 브랜치를 설치하고 Task 1 Step 2와 같은 방법으로 슬라이더마다 `slider_reset_repro.py`를 5회 돌린다.

| 화면 | 스택 제거 전 (Task 1) | 스택 제거 후 |
|---|---|---|
| 키보드 높이 | /5 | /5 |
| 글자 열 너비 | /5 | /5 |
| 한 손 키보드 너비 | /5 | /5 |
| 길게 누르기 입력 (지연 시간 / 반복 속도) | /5, /5 | /5, /5 |
| 커서 이동 (활성화 거리 / 이동 간격) | /5, /5 | /5, /5 |

결정:

- **모든 화면이 0/5**: 중첩 스택이 원인이었다. Step 1·2를 건너뛰고(체크하지 않고 '불필요: 스택 제거로 해소'라고 적는다) Task 5로 간다.
- **키보드 높이·글자 열 너비·한 손 너비 중 하나라도 재현**: Step 1로 간다.
- **길게 누르기·커서 이동이 재현**: 이슈는 이 두 화면을 수정 범위에 넣지 않았다. **멈추고 사용자에게 결과를 보여 준 뒤 Step 3을 진행할지 묻는다.** 답을 아래에 적는다.

사용자 결정(길게 누르기·커서 이동):

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 스택 제거 후 슬라이더 리셋 재현 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 1: 키보드 높이 화면에 `.id` 교체를 넣고 재현 스크립트로 확인한다**

`@State` 선언부(44~45행 부근, `tempKeyboardHeight` 아래)에 추가:

```swift
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var sliderResetCount = 0
```

`keyboardHeightSettings`의 슬라이더:

```swift
            Slider(value: $tempKeyboardHeight, in: KeyboardLayoutFigure.keyboardHeightRange, step: 1)
                .id(sliderResetCount)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
```

'리셋' 버튼:

```swift
                Button {
                    tempKeyboardHeight = DefaultValues.keyboardHeight
                    sliderResetCount += 1
                } label: {
                    Text("리셋")
                }
```

빌드해 iPhone Air / iOS 27에 설치하고 키보드 높이 화면에서 확인한다.

1. `python3 slider_reset_repro.py 30C7D731-84B5-4F30-B889-138E061E8910 <리셋X> <리셋Y> 0 5` → **`재현 0/5`, exit 0**이어야 한다.
2. 리셋 직후 곧바로 슬라이더를 드래그해 값과 숫자가 따라오는지 본다(Review Focus 4).
3. 끝까지 민 직후 리셋 → '저장' → 다시 들어가 숫자가 기본값(100)인지 본다. 다른 값으로 저장해 두고 끝까지 민 직후 리셋 → '취소' → 다시 들어가 원래 값인지 본다(Review Focus 3).

**1이 0/5가 아니면 멈춘다.** 코드 변경을 `git checkout -- SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift`로 되돌리고, 재현 결과를 아래에 적어 사용자에게 보고한다. 이슈의 나머지 후보(길이가 사실상 0인 편집 세션 무시, 드래그 직후 리셋 잠시 비활성화)는 동작·UX를 바꾸므로 사용자 결정 없이 시도하지 않는다.

결과:

```sh
git add SYKeyboard/Presentation/KeyboardSettings/KeyboardHeightSettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
fix: #151 - 키보드 높이 슬라이더를 놓은 직후 리셋이 마지막 드래그 값으로 되돌아가는 현상 수정

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: 글자 열 너비·한 손 키보드 너비 화면에 같은 수정을 넣고 확인한다**

`LetterColumnWidthSettingsView.swift` — `tempLetterColumnWidthMultiplier` 선언 아래:

```swift
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var sliderResetCount = 0
```

```swift
            Slider(value: letterColumnWidthPercent,
                   in: KeyboardLayoutFigure.letterColumnWidthPercentRange,
                   step: 1)
                .id(sliderResetCount)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
```

```swift
                Button {
                    tempLetterColumnWidthMultiplier = DefaultValues.letterColumnWidthMultiplier
                    sliderResetCount += 1
                } label: {
                    Text("리셋")
                }
```

`OneHandedKeyboardWidthSettingsView.swift` — `tempOneHandedKeyboardWidth` 선언 아래:

```swift
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var sliderResetCount = 0
```

```swift
            Slider(value: $tempOneHandedKeyboardWidth, in: 300...340, step: 1)
                .id(sliderResetCount)
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
```

```swift
                Button {
                    tempOneHandedKeyboardWidth = DefaultValues.oneHandedKeyboardWidth
                    sliderResetCount += 1
                } label: {
                    Text("리셋")
                }
```

빌드·설치 후 두 화면 각각에서 Step 1의 확인 1~3을 한다. 둘 다 `재현 0/5`여야 한다.

| 화면 | 재현 | 리셋 직후 드래그 | 리셋 후 저장·취소 |
|---|---|---|---|
| 글자 열 너비 | /5 |  |  |
| 한 손 키보드 너비 | /5 |  |  |

```sh
git add SYKeyboard/Presentation/KeyboardSettings/LetterColumnWidthSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/OneHandedKeyboardWidthSettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
fix: #151 - 글자 열 너비·한 손 키보드 너비 슬라이더 직후 리셋이 되돌아가는 현상 수정

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 3 (Step 0에서 사용자가 승인한 경우만): 길게 누르기 입력·커서 이동 화면에 같은 수정을 넣는다**

승인하지 않았으면 체크하지 않고 '범위 밖: 사용자 결정'이라고 적는다.

이 두 화면은 슬라이더가 둘이고 리셋이 행마다 있으므로 슬라이더마다 카운터를 둔다. `LongPressSettingsView.swift` — `repeatRate` 선언 아래:

```swift
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var longPressDurationResetCount = 0
    @State private var repeatRateResetCount = 0
```

```swift
            Slider(value: $longPressDuration, in: 0.1...0.9, step: 0.05) { _ in
                hideKeyboard()
            }
            .id(longPressDurationResetCount)
            Button {
                longPressDuration = DefaultValues.longPressDuration
                longPressDurationResetCount += 1
                hideKeyboard()
            } label: {
                Text("리셋")
            }
```

```swift
            Slider(value: $repeatRate, in: 0.01...0.09, step: 0.005) { _ in
                hideKeyboard()
            }
            .id(repeatRateResetCount)
            Button {
                repeatRate = DefaultValues.repeatRate
                repeatRateResetCount += 1
                hideKeyboard()
            } label: {
                Text("리셋")
            }
```

`CursorMovementSettingsView.swift` — `cursorMoveInterval` 선언 아래:

```swift
    /// 리셋할 때마다 바꿔 `Slider`를 새로 만든다. iOS 27 `Slider`는 놓은 직후 값이 바깥에서 바뀌면
    /// 마지막 드래그 값을 다시 커밋하므로, 이전 슬라이더를 버려 그 커밋을 끊는다
    @State private var cursorActiveDistanceResetCount = 0
    @State private var cursorMoveIntervalResetCount = 0
```

```swift
            Slider(value: $cursorActiveDistance, in: 10.0...50.0, step: 1.0) { _ in
                hideKeyboard()
            }
            .id(cursorActiveDistanceResetCount)
            Button {
                cursorActiveDistance = DefaultValues.cursorActiveDistance
                cursorActiveDistanceResetCount += 1
                hideKeyboard()
            } label: {
                Text("리셋")
            }
```

```swift
            Slider(value: $cursorMoveInterval, in: 1.0...9.0, step: 0.5) { _ in
                hideKeyboard()
            }
            .id(cursorMoveIntervalResetCount)
            Button {
                cursorMoveInterval = DefaultValues.cursorMoveInterval
                cursorMoveIntervalResetCount += 1
                hideKeyboard()
            } label: {
                Text("리셋")
            }
```

빌드·설치 후 슬라이더 4개 각각 `slider_reset_repro.py <UDID> <행 리셋X> <행 리셋Y> <순번> 5`가 `재현 0/5`인지, 리셋 직후 드래그가 따라오는지 확인한다. 이 두 화면은 슬라이더가 `@AppStorage`에 바로 쓰므로 '저장' 확인 대신 화면을 나갔다 다시 들어와 기본값인지 본다.

| 슬라이더 | 재현 | 리셋 직후 드래그 | 재진입 값 |
|---|---|---|---|
| 길게 누르기 지연 시간 | /5 |  |  |
| 키 반복 속도 | /5 |  |  |
| 활성화 드래그 거리 | /5 |  |  |
| 이동 드래그 간격 | /5 |  |  |

```sh
git add SYKeyboard/Presentation/KeyboardSettings/LongPressSettingsView.swift \
        SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift \
        docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
fix: #151 - 길게 누르기 입력·커서 이동 슬라이더 직후 리셋이 되돌아가는 현상 수정

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: iOS 18.6에서 회귀가 없는지 확인한다**

iPhone 13 mini / iOS 18.6에 설치하고 수정한 화면마다 확인한다.

- `slider_reset_repro.py`가 `재현 0/5` (18.6은 원래 재현되지 않았으므로 여전히 0이어야 한다)
- 리셋 직후 드래그, 리셋 후 저장·취소(또는 재진입 값)가 iOS 27과 같다

| 화면 | 재현 | 드래그·저장·취소 |
|---|---|---|
| 키보드 높이 | /5 |  |
| 글자 열 너비 | /5 |  |
| 한 손 키보드 너비 | /5 |  |
| (Step 3 진행 시) 길게 누르기 입력 | /5, /5 |  |
| (Step 3 진행 시) 커서 이동 | /5, /5 |  |

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 iOS 18.6 슬라이더 리셋 회귀 확인 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 전체 검증과 실기기 확인

**Files:**
- Modify: 이 문서

**Interfaces:**
- Consumes: Task 2~4의 결과
- Produces: PR 본문 「검증」 절에 옮길 명령과 결과

- [ ] **Step 1: 전체 테스트와 extension 빌드를 돌린다**

앱 타깃만 바꿨지만 `SYKeyboardTests`는 앱 타깃(`SYKeyboardTests/Presentation/`)도 포함하므로 한 번 돌린다. 수 분 걸린다고 먼저 알린다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -parallel-testing-enabled NO \
  GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511' \
  > <scratchpad>/issue-151/test.log 2>&1; echo "exit=$?"
grep -E "Test run with|TEST SUCCEEDED|TEST FAILED|✘" <scratchpad>/issue-151/test.log | tail -20
```

타임아웃·호스트 앱 미실행은 CLAUDE.md 「환경 오류와 코드 실패 구분」대로 처리하고 코드 실패로 적지 않는다.

키보드 extension은 바뀌지 않았으므로 빌드는 `HangeulEnglishKeyboard` 하나만 확인한다(호스트 앱 포함 빌드).

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > <scratchpad>/issue-151/build-hek.log 2>&1; echo "exit=$?"
git status --short   # .xcscheme RemotePath 부수 변경이면 되돌린다
```

결과(테스트 개수·통과 여부, 빌드 exit, 로그 경로):

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 전체 테스트와 빌드 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: 실기기 확인을 사용자에게 요청하고 결과를 기록한다**

에이전트는 실기기를 조작할 수 없다. 사용자에게 iPhone 15 Pro Max / iOS 27 실기기에서 아래를 확인해 달라고 요청하고, 답을 받기 전에는 이 step을 체크하지 않는다. 미확인이면 PR 본문에도 미확인으로 적는다.

- 키보드 높이·글자 열 너비·한 손 키보드 너비(Step 3 진행 시 길게 누르기·커서 이동 포함): 슬라이더를 끝까지 민 직후 '리셋' 한 번으로 기본값이 유지된다
- 6개 화면의 제목·툴바·뒤로 가기, 클립보드 편집 모드·하단 바·시트가 전과 같다

실기기 결과:

```sh
git add docs/superpowers/plans/2026-09-23-issue-151-slider-reset-nested-navigation-stack.md
git commit -m "$(cat <<'EOF'
docs: #151 - 계획 문서에 실기기 확인 결과 기록

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
)"
```

이후 통합(PR 생성 등)은 superpowers:finishing-a-development-branch로 사용자와 정한다. PR 제목은 `Fix/#151 iOS 27 슬라이더 직후 리셋 수정 및 설정 화면 중첩 NavigationStack 제거` 형식을 쓴다.

---

## 되돌리는 법

- 리셋 수정만 되돌리기: Task 4의 `fix:` 커밋들을 `git revert`한다. 화면마다 `sliderResetCount`(또는 슬라이더별 카운터) 선언, `.id(...)`, `+= 1` 세 곳뿐이다.
- 스택 제거 되돌리기: Task 2·3의 `refactor:` 커밋을 `git revert`한다. Task 4 커밋이 같은 파일을 고쳤으므로 Task 4를 먼저 되돌린다.
