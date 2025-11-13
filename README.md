<img src="https://github.com/user-attachments/assets/fb7e719e-7353-4649-8ecc-a11058a6c3d6" width="200">

# SY키보드
> SY키보드는 가볍고, 사용하기 간편한 나랏글 키보드입니다. (추후 천지인 키보드 추가 예정)  
> [Figma](https://www.figma.com/design/0i3sNlaez0LG0QMfw80yJ4/SY%ED%82%A4%EB%B3%B4%EB%93%9C?node-id=0-1&t=L8rArjkBX9MJ3UJD-1)
> 
> 개발 기간: 2024.07.30 ~ 2025.01.15  
> 리팩토링 기간: 2025.07.09 ~ 2025.11.30

<br>

<a href="https://apps.apple.com/kr/app/sy키보드/id6670792957">
    <img src="https://github.com/user-attachments/assets/dbf89ce7-436b-452f-8319-e411f65a589e">
</a>

<br><br>


## 👥 대상 사용자
- 나랏글 키보드/천지인 키보드(예정)를 계속 사용해 왔던 사람
- 나랏글 키보드/천지인 키보드(예정)에 입문하는 사람
- 필수적인 기능들을 포함하되, 가벼운 키보드 앱을 찾는 사람

<br><br>


## 🛠️ 기술 스택
| 범위 | 기술 이름 |
|:---------:|:----------|
| 의존성 관리 도구 | `SPM`, `CocoaPods` |
| 형상 관리 도구 | `Git`, `GitHub` |
| 디자인 패턴 | `Delegate`, `Singleton` |
| 인터페이스 | `UIKit`, `SwiftUI` |
| 활용 API | `Firebase Analytics`, `Google AdMob`, `Meta Audience` |
| 레이아웃 구성 | `SnapKit`, `Then` |
| 내부 저장소 | `UserDefaults` |

<br><br>


## 🔨 개발 환경
![Static Badge](https://img.shields.io/badge/Xcode%2016.3-147EFB?logo=xcode&logoColor=white&logoSize=auto)
![Static Badge](https://img.shields.io/badge/16.0-000000?logo=ios&logoColor=white&logoSize=auto)

<br><br>


## 👨‍💻 트러블 슈팅
### SwiftUI ➡️ UIKit 리팩토링 이유

<br><br>

### 키보드 높이 제약조건 지정 시 키보드 표시 애니메이션 글리칭 현상
#### 문제 상황
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 애니메이션<br>글리칭 | <img src = "https://github.com/user-attachments/assets/4a33c68c-40f8-43d7-a968-d539f51a7ccf" width ="250"> |

애플 공식 문서([레거시](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [최신](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface#Adapt-to-different-layouts)) 기반으로 키보드 높이 조절 코드를 구현했을 때, 위 GIF처럼 키보드가 잠깐동안 높이 튀어오르는 현상이 발생하였다.
``` swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setKeyboardHeight()
    FeedbackManager.shared.prepareHaptic()
}
  
func setKeyboardHeight() {
    let heightConstraint = self.view.heightAnchor.constraint(equalToConstant: UserDefaultsManager.shared.keyboardHeight)
    heightConstraint.priority = .init(999)
    heightConstraint.isActive = true
}
```
- view를 위한 애니메이션이 구성되기 직전인 `viewWillAppear` 메서드에 높이 제약조건 코드 구현

<br>

#### 원인 분석
문제 해결을 위해 찾아보던 중 Stack Overflow의 한 [질문글의 답변](https://stackoverflow.com/a/62114742)에서 힌트를 얻을 수 있었다.
``` swift
private var constraintsHaveBeenAdded = false

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    initKeyboardConstraints()
}

private func initKeyboardConstraints() {
    if constraintsHaveBeenAdded { return }
    guard let superview = view.superview else { return }
    view.translatesAutoresizingMaskIntoConstraints = false
    view.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    view.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
    view.heightAnchor.constraint(equalToConstant: 250.0).isActive = true
    constraintsHaveBeenAdded = true
}
```
> 1. 제약조건이 설정되었는지를 판단하는 플래그 변수 `constraintsHaveBeenAdded` 설정
> 2. 제약조건이 이미 설정되었거나, 상위 view가 설정되지 않은 경우 실행 X (방어 코드)
> 3. **view의 모든 edge에 대해 상위 view와 같도록 제약조건 설정**
> 4. `constraintsHaveBeenAdded`를 true로 설정  

- 이전 코드에선 view의 모든 edge에 대해 상위 view와 같도록 제약조건을 설정하는 코드(`$0.edges.equalToSuperview()`)와 `translatesAutoresizingMaskIntoConstraints`를 `false`로 설정하는 코드가 없었음
- 이로 인해 Autoresizing Mask로 view의 크기와 위치를 정하려 하는 과정에서 Auto Layout의 높이 제약조건이 충돌을 일으켜 애니메이션에 글리칭이 발생한 것으로 추측
- `translatesAutoresizingMaskIntoConstraints`만 `false`로 설정하는 경우 아래 사진처럼 UI가 치우치는 현상이 발생함
  
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| UI 치우침 | <img src = "https://github.com/user-attachments/assets/5198d906-e813-4e79-b537-300e96bb52c2" width ="250"> |

<br>

#### 해결 과정
위 답변을 토대로 높이 제약조건 코드를 수정하고 방어코드를 추가하였다.
``` swift
func setKeyboardHeight() {
    if !isHeightConstraintAdded, self.view.superview != nil {
        self.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(999)
        }
        isHeightConstraintAdded = true
    }
}
```
- `SnapKit`을 통해 자동으로 `translatesAutoresizingMaskIntoConstraints`가 `false`로 설정됨

|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 해결 이후 | <img src = "https://github.com/user-attachments/assets/be7f5279-7b22-4dcd-830e-85a98ad7141a" width ="250"> |

정말 오랫동안 고민하던 문제였고, 글리칭이 없는 다른 키보드 어플에선 어떻게 해결했는지 개발자에게 여쭤보고 싶을 정도로 해결 방법이 궁금했었다.  
해결하고 나니 속이 시원하다...

출처: [Stack Overflow - iOS 8 Custom Keyboard: Changing the height without warning 'Unable to simultaneously satisfy constraints...'](https://stackoverflow.com/questions/26569476/ios-8-custom-keyboard-changing-the-height-without-warning-unable-to-simultaneo)

<br><br>


### 키보드 가장자리 터치 딜레이
#### 문제 상황
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 터치 딜레이<br>영역 | <img src = "https://github.com/user-attachments/assets/31aed9f1-ac3b-4839-aa42-b7a21e0693ab" width ="250"> |

실 기기에서 키보드 테스트 도중 위 사진의 빨간색 네모 영역을 터치할 때 딜레이가 존재하는 것을 발견했다.
- 단일 터치 시 인식까지 딜레이 존재, 반복 터치 시 손가락을 뗄 때만 반응

<br>

#### 원인 분석
<img width="785" height="159" alt="image" src="https://github.com/user-attachments/assets/7581e20e-d7e7-4fa4-a486-180576543ea4" />

> 1. 키보드 앱이 실행되면 `viewWillAppear` 단계에서 `self.view.window`를 포함한 모든 `UIView`에 앱의 `UIWindow`가 할당됨
> 2. 이때 `UIWindow`에 있는 2개의 `UISystemGestureGateGestureRecognizer`가 화면 하단의 제스처 바 혹은 화면 왼쪽, 오른쪽 모서리의 시스템 제스처 인식을 담당함
> - 예: 홈 화면으로 가기, 뒤로 가기 등
> 3. 사용자가 사진의 빨간색 네모 영역을 터치
> 4. `UISystemGestureGateGestureRecognizer`가 사진의 빨간색 네모 영역의 터치를 키보드의 `UIButton`보다 먼저 인식
> 5. 시스템 제스처가 아닌 경우, 터치 이벤트를 소비하지 않고 키보드 버튼으로 넘겨줌
> 6. `UIButton`의 `UIControl`에서 터치 이벤트 소비

`UISystemGestureGateGestureRecognizer`가 사용자의 터치 이벤트를 시스템 제스처인지 판단하는 과정(4, 5)을 거치면서 딜레이가 생기게 된다.

<br>

#### 해결 과정
처음에는 iOS 11부터 지원하는 `preferredScreenEdgesDeferringSystemGestures` 프로퍼티를 사용하여 해결하려 했지만, `UIInputViewController`에선 지원하지 않는듯 했다.  
그래서 `UISystemGestureGateGestureRecognizer`의 `delaysTouchesBegan`를 `false`로 설정하는 것으로 해결하였다.
``` swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let window = self.view.window!
    let systemGestureRecognizer0 = window.gestureRecognizers?[0] as? UIGestureRecognizer
    let systemGestureRecognizer1 = window.gestureRecognizers?[1] as? UIGestureRecognizer
    systemGestureRecognizer0?.delaysTouchesBegan = false
    systemGestureRecognizer1?.delaysTouchesBegan = false
}
```

<img width="881" height="67" alt="image" src="https://github.com/user-attachments/assets/2306bfa1-1788-428a-8755-6817e464e48c" />

설정 이후 side effect가 생길 수 있다는 경고 메세지가 콘솔창에 뜨지만, 애플에서 `preferredScreenEdgesDeferringSystemGestures`를 `UIInputViewController`에 지원해주지 않는 이상 해결 방법이 없어보인다 🙄

출처: [Stack Overflow - UISystemGateGestureRecognizer and delayed taps near bottom of screen](https://stackoverflow.com/questions/19799961/uisystemgategesturerecognizer-and-delayed-taps-near-bottom-of-screen)

<br><br>


## 📊 다이어그램
### 키보드 종류 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "JetBrainsMono NFP",
    "elk": {
        "mergeEdges": false,
        "nodePlacementStrategy": "BRANDES_KOEPF",
        "forceNodeModelOrder": false,
        "considerModelOrder": "NODES_AND_EDGES"
    },
    "class": {
        "hideEmptyMembersBox": true
    }
  }
}%%
classDiagram
direction LR
    %% Keyboard Type
    namespace ParentKeyboardViewController {
      class BaseKeyboardViewController
    }

    namespace FinalKeyboardViewController {
      class HangeulKeyboardViewController
      class EnglishKeyboardViewController
    }

    BaseKeyboardViewController <|-- HangeulKeyboardViewController: Inheritance
    BaseKeyboardViewController <|-- EnglishKeyboardViewController: Inheritance
```

### 키보드 레이아웃 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "JetBrainsMono NFP",
    "elk": {
        "mergeEdges": false,
        "nodePlacementStrategy": "BRANDES_KOEPF",
        "forceNodeModelOrder": false,
        "considerModelOrder": "NODES_AND_EDGES"
    },
    "class": {
        "hideEmptyMembersBox": true
    }
  }
}%%
classDiagram
direction LR
    %% Keyboard Layout
    namespace KeyboardGestureProtocol {
      class TextInteractionGestureHandling
      class SwitchGestureHandling
    }

    namespace KeyboardTypeLayoutProtocol {
      class HangeulKeyboardLayoutProvider
      class EnglishKeyboardLayoutProvider
      class SymbolKeyboardLayoutProvider
      class NumericKeyboardLayoutProvider
      class TenkeyKeyboardLayoutProvider
    }

    namespace ParentKeyboardView {
      class FourByFourKeyboardView
      class QwertyKeyboardView
    }

    namespace FinalKeyboardView {
      class NaratgeulKeyboardView
      class CheonjiinKeyboardView
      class EnglishKeyboardView
      class SymbolKeyboardView
      class NumericKeyboardView
      class TenkeyKeyboardView
    }

    class BaseKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class NormalKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class TextInteractionGestureHandling:::SYKeyboard_primary { <<protocol>> }
    class SwitchGestureHandling:::SYKeyboard_primary { <<protocol>> }
    class PrimaryKeyboardRepresentable:::SYKeyboard_primary { <<protocol>> }
    class HangeulKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class EnglishKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class SymbolKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class NumericKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class TenkeyKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }

    BaseKeyboardLayoutProvider <|-- NormalKeyboardLayoutProvider: Inheritance
    BaseKeyboardLayoutProvider <|-- TenkeyKeyboardLayoutProvider: Inheritance

    NormalKeyboardLayoutProvider <|-- PrimaryKeyboardRepresentable: Inheritance
    NormalKeyboardLayoutProvider <|-- PrimaryKeyboardRepresentable: Inheritance

    TenkeyKeyboardLayoutProvider ..|> TenkeyKeyboardView: Implementation

    PrimaryKeyboardRepresentable <|-- HangeulKeyboardLayoutProvider: Inheritance
    TextInteractionGestureHandling <|-- HangeulKeyboardLayoutProvider: Inheritance
    SwitchGestureHandling <|-- HangeulKeyboardLayoutProvider: Inheritance
    HangeulKeyboardLayoutProvider ..|> FourByFourKeyboardView: Implementation

    FourByFourKeyboardView <|-- NaratgeulKeyboardView: Inheritance
    FourByFourKeyboardView <|-- CheonjiinKeyboardView: Inheritance

    PrimaryKeyboardRepresentable <|-- EnglishKeyboardLayoutProvider: Inheritance

    TextInteractionGestureHandling <|-- EnglishKeyboardLayoutProvider: Inheritance
    SwitchGestureHandling <|-- EnglishKeyboardLayoutProvider: Inheritance
    EnglishKeyboardLayoutProvider ..|> EnglishKeyboardView: Implementation
    QwertyKeyboardView <|-- EnglishKeyboardView: Inheritance

    NormalKeyboardLayoutProvider <|-- SymbolKeyboardLayoutProvider: Inheritance
    TextInteractionGestureHandling <|-- SymbolKeyboardLayoutProvider: Inheritance
    SwitchGestureHandling <|-- SymbolKeyboardLayoutProvider: Inheritance
    SymbolKeyboardLayoutProvider ..|> SymbolKeyboardView: Implementation

    NormalKeyboardLayoutProvider <|-- NumericKeyboardLayoutProvider: Inheritance
    TextInteractionGestureHandling <|-- NumericKeyboardLayoutProvider: Inheritance
    SwitchGestureHandling <|-- NumericKeyboardLayoutProvider: Inheritance
    NumericKeyboardLayoutProvider ..|> NumericKeyboardView: Implementation
    
    classDef SYKeyboard_primary fill:#ffa6ed
```

### 키보드 버튼 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "JetBrainsMono NFP",
    "elk": {
        "mergeEdges": false,
        "nodePlacementStrategy": "BRANDES_KOEPF",
        "forceNodeModelOrder": false,
        "considerModelOrder": "NODES_AND_EDGES"
    },
    "class": {
        "hideEmptyMembersBox": true
    }
  }
}%%
classDiagram
direction LR
    %% Keyboard Button
    namespace TextInteractionProtocol {
      class TextInteractable
    }

    namespace ParentKeyboardButton {
      class BaseKeyboardButton
      class PrimaryButton
      class SecondaryButton
    }

    namespace FinalKeyboardButton {
      class PrimaryKeyButton
      class SpaceButton
      class SecondaryKeyButton
      class ShiftButton
      class DeleteButton
      class SwitchButton
      class NextKeyboardButton
      class ReturnButton
    }

    class TextInteractable:::SYKeyboard_primary { <<protocol>> }

    BaseKeyboardButton <|-- PrimaryButton: Inheritance
    BaseKeyboardButton <|-- SecondaryButton: Inheritance
    BaseKeyboardButton <|-- TextInteractable: Constraint

    PrimaryButton <|-- PrimaryKeyButton: Inheritance
    PrimaryButton <|-- SpaceButton: Inheritance

    PrimaryKeyButton ..|> TextInteractable: Implementation

    SecondaryButton <|-- DeleteButton: Inheritance
    SecondaryButton <|-- NextKeyboardButton: Inheritance
    SecondaryButton <|-- ReturnButton: Inheritance
    SecondaryButton <|-- SecondaryKeyButton: Inheritance
    SecondaryButton <|-- ShiftButton: Inheritance
    SecondaryButton <|-- SwitchButton: Inheritance

    SecondaryKeyButton ..|> TextInteractable: Implementation

    DeleteButton ..|> TextInteractable: Implementation
    ReturnButton ..|> TextInteractable: Implementation
    SpaceButton ..|> TextInteractable: Implementation

    classDef SYKeyboard_primary fill:#ffa6ed
```

<br><br>


## 📱 주요 기능
1. **나랏글 키보드**  
기본에 충실한 나랏글 키보드입니다.

<img src = "https://github.com/user-attachments/assets/4c27c194-2ae4-4489-bd39-d927ce6563bf" width ="250">

<br><br>


2. **숫자 키패드 탑재**  
숫자를 입력할 때 큰 버튼으로 편하게 입력할 수 있는 숫자 전용 키패드를 탑재했습니다.

<img src="https://github.com/user-attachments/assets/195133c7-a7d9-44a8-af03-b409efd88788" width="250">
    
<br><br>


3. **한 손 키보드 모드**  
한 손으로 폰을 들고 있는 상태에서도 입력하기 수월하도록 한 손 키보드 모드를 제공합니다.

<img src="https://github.com/user-attachments/assets/45a6282e-9438-4bdd-af69-eec1541a53b4" width="250">

<br><br>


4. **다양하고 디테일한 키보드 설정**  
반복 입력, 커서 이동, 키보드 높이 및 한 손 키보드 너비 조절 등 사용자의 편의에 맞게 키보드 설정이 가능합니다.

<img src="https://github.com/user-attachments/assets/a27ee88f-75db-4b3f-82d8-99543718bb71" width="250">

<br><br>

