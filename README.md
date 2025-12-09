<img src="https://github.com/user-attachments/assets/fb7e719e-7353-4649-8ecc-a11058a6c3d6" width="200">

# SY키보드
> SY키보드는 가볍고, 사용하기 간편한 나랏글 키보드입니다. (추후 두벌식 키보드 추가 예정)  
> [Figma](https://www.figma.com/design/0i3sNlaez0LG0QMfw80yJ4/SY%ED%82%A4%EB%B3%B4%EB%93%9C?node-id=0-1&t=L8rArjkBX9MJ3UJD-1)
> 
> 개발 기간: 2024.07.30 ~ 2025.01.15  
> 리팩토링 기간: 2025.07.09 ~ 2025.12.07

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
| 의존성 관리 도구 | `SPM` |
| 형상 관리 도구 | `Git`, `GitHub` |
| 디자인 패턴 | `Delegate`, `Singleton` |
| 인터페이스 | `UIKit`, `SwiftUI` |
| 활용 API | `Firebase Analytics`, `Firebase Crashlytics`, `Google AdMob` |
| 내부 저장소 | `UserDefaults` |
| 테스트 | `Swift Testing` |

<br><br>


## 🔨 개발 환경
![Static Badge](https://img.shields.io/badge/Swift%205-%23F05138?logo=swift&logoColor=white)
![Static Badge](https://img.shields.io/badge/Xcode%2016%20~-%23147EFB?logo=xcode&logoColor=white)
![Static Badge](https://img.shields.io/badge/16%20~%20-%23000000?logo=ios&logoColor=white)

<br><br>


## 👨‍💻 트러블 슈팅
### 복잡했던 버튼 코드
#### SwiftUI로 최초 개발
첫 iOS 프로젝트인 SY키보드를 SwiftUI로 개발하여 1월에 출시하였다.  
하지만 Swift 언어를 다루는 데에 미숙했던 것과 UIKit에 비해 부족한 터치 이벤트 및 상태 관리로 인해 키보드 버튼 코드가 매우 길어졌다.  
이후 4개월간의 UIKit 부트캠프를 수강하며 어느 정도 iOS 앱 개발에 익숙해지면서, 복잡한 상태 관리에는 SwiftUI보다 UIKit이 적합함을 알게 되었다.  
미숙했던 개발 실력과 SwiftUI의 특징이 맞물려 유지보수하기 어려웠던 SY키보드의 UIKit 리팩토링을 생각하게 되었고, 부트캠프 수료 이후 진행하였다.

<br>

#### SwiftUI ➡️ UIKit 리팩토링
##### 메인 앱
SY키보드의 메인 앱은 키보드 설정 위주의 단순한 구조이므로 기존 SwiftUI를 유지하면서 개선에 목적을 두었다.  

##### Keyboard Extension
Keyboard Extension 부분은 SwiftUI에서 UIKit으로 리팩토링하는 작업을 진행했다.  
리팩토링을 거치며 영어 키보드를 추가하였고, 천지인 키보드도 다음 업데이트를 위해 기본적인 UI를 만들어 두었다.  
또한, 다른 프로젝트에서 가져와 수정해서 사용했던 한글 오토마타 코드도 처음부터 다시 만들기로 결정했다.  

<br>

#### UIKit 리팩토링 작업
SwiftUI에서는 `Button`의 `action`이 `touchUpInside` 기준으로 고정되어 있어서, Gesture를 사용하여 우회적으로 다른 이벤트들을 구현해야 했다.  
하지만 UIKit에서는 `addTarget` 혹은 `addAction`의 `UIControlEvents`를 통해 `touchDown`, `touchUpInside`, `touchDownRepeat`로 세밀하게 제어할 수 있었다.  
또한 버튼이 눌렸을 때(`highlighted`, `selected`)에 대한 상태 변경도 더 직관적이었다.  

<details>
    <summary>기존 SwiftUI</summary>
    <div markdown="1">
        
``` swift
// KeyboardButton 구조체의 일부
Button(action: {}) {
            // Image 버튼들
            if systemName != nil {
                if systemName == "return.left" {  // 리턴 버튼
                    if state.returnButtonType == .default {
                        Image(systemName: "return.left")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .font(.system(size: imageSize))
                            .foregroundStyle(Color(uiColor: UIColor.label))
                            .background(checkPressed() ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
            // ...(중략)...
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0)
                .onEnded({ _ in
                    // 버튼 눌렀을 때
                    os_log("LongPressGesture() onEnded: pressed", log: log, type: .debug)
                    gesturePressed()
                })
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: state.longPressDuration, maximumDistance: cursorActiveDistance)
            // 버튼 길게 눌렀을 때
                .onEnded({ _ in
                    os_log("simultaneous_LongPressGesture() onEnded: longPressed", log: log, type: .debug)
                    gestureLongPressed()
                })
                .sequenced(before: DragGesture(minimumDistance: 10, coordinateSpace: .global))
            // 버튼 길게 누르고 드래그시 호출
                .onChanged({ value in
                    switch value {
                    case .first(_):
                        break
                    case .second(_, let dragValue):
                        if let value = dragValue {
                            os_log("LongPressGesture()->DragGesture() onChanged: longPressedDrag", log: log, type: .debug)
                            gestureLongPressedDrag(dragGestureValue: value)
                        }
                    }
                })
                .exclusively(before: DragGesture(minimumDistance: cursorActiveDistance, coordinateSpace: .global)
                             // 버튼 드래그 할 때
                    .onChanged({ value in
                        os_log("exclusively_DragGesture() onChanged: drag", log: log, type: .debug)
                        gestureDrag(dragGestureValue: value)
                    })
                            )
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
            // 버튼 뗐을 때
                .onEnded({ _ in
                    os_log("DragGesture() onEnded: released", log: log, type: .debug)
                    gestureReleased()
                })
        )
```
</details>

<details>
    <summary>UIKit 리팩토링 이후</summary>
    <div markdown="1">

``` swift
// BaseKeyboardViewController 클래스의 일부
func addInputActionToTextInterableButton(_ button: TextInteractable) {
    let inputAction = UIAction { [weak self] _ in
        guard let self,
              let currentPressedButton = buttonStateController.currentPressedButton,
              currentPressedButton === button else { return }
        performTextInteraction(for: button.button)
    }
    if button is DeleteButton {
        button.addAction(inputAction, for: .touchDown)
    } else {
        button.addAction(inputAction, for: .touchUpInside)
    }
}

// ButtonStateController 클래스의 일부
func setFeedbackActionToButtons(_ buttonList: [BaseKeyboardButton]) {
    buttonList.forEach { button in
        let playFeedbackAndSetPressed: UIAction
        if button is ShiftButton {
            playFeedbackAndSetPressed = UIAction { [weak self] _ in
                guard let self else { return }
                
                if let previousButton = currentPressedButton, previousButton != button {
                    previousButton.sendActions(for: .touchUpInside)
                }
                
                isShiftButtonPressed = true
                button.playFeedback()
            }
        } else {
            playFeedbackAndSetPressed = UIAction { [weak self] _ in
                guard let self else { return }
                
                if let previousButton = currentPressedButton, previousButton != button {
                    previousButton.sendActions(for: .touchUpInside)
                }
                
                currentPressedButton = button
                button.playFeedback()
            }
        }
        button.addAction(playFeedbackAndSetPressed, for: .touchDown)
    }
}

// PrimaryButton 클래스의 일부
func setStyles() {
        self.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            switch button.state {
            case .normal:
                backgroundView.backgroundColor = .primaryButton
            case .highlighted:
                backgroundView.backgroundColor = isPressed ? .primaryButtonPressed : .primaryButton
            case .selected:
                backgroundView.backgroundColor = .primaryButtonPressed
            default:
                break
            }
        }
    }
```
</details>

<br>

#### 결론 및 회고
명령형 프레임워크인 UIKit으로 리팩토링하면서 복잡한 버튼, 제스처 로직을 효율적으로 처리할 수 있었지만, 선언형 프레임워크인 SwiftUI보다 UI 구현 코드는 더 길어지게 되었다.  
현재로선 UIKit이 SwiftUI보다 세밀한 커스텀이 가능한 장점이 있어 SY키보드에는 UIKit이 좀더 적합하다고 생각된다.  
최근 WWDC에서 SwiftUI 위주의 업데이트가 계속 발표되고 있으니, 나중에는 더 커스텀하기 편하게 SwiftUI가 업데이트되지 않을까 싶다!  
그렇게 된다면 다시 UIKit에서 SwiftUI로 리팩토링을 하여 지금보다도 더 가독성, 유지보수에 좋은 코드를 만들 수 있을 것 같다.

<br>

---

<br>

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

- 이전 코드에서는 view의 모든 edge에 대해 상위 view와 같도록 제약조건을 설정하는 코드(`$0.edges.equalToSuperview()`)와 `translatesAutoresizingMaskIntoConstraints`를 `false`로 설정하는 코드가 없었음
- 이로 인해 Autoresizing Mask로 view의 크기와 위치를 정하려 하는 과정에서 Auto Layout의 높이 제약조건이 충돌을 일으켜 애니메이션에 글리칭이 발생한 것으로 추측
- `translatesAutoresizingMaskIntoConstraints`만 `false`로 설정하는 경우 아래 사진처럼 UI가 치우치는 현상이 발생함
  
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| UI 치우침 | <img src = "https://github.com/user-attachments/assets/5198d906-e813-4e79-b537-300e96bb52c2" width ="250"> |

<br>

#### 해결 과정
위 답변을 토대로 높이 제약조건 코드를 수정하고 방어코드를 추가하였다.
- 키보드 가로모드 대응 코드도 추가된 상태
``` swift
func setKeyboardHeight() {
    let keyboardHeight: CGFloat
    if let orientation = self.view.window?.windowScene?.effectiveGeometry.interfaceOrientation {
        keyboardHeight = orientation == .portrait ? UserDefaultsManager.shared.keyboardHeight : KeyboardLayoutFigure.landscapeKeyboardHeight
    } else {
        if !isPreview {
            assertionFailure("View가 window 계층에 없습니다.")
        }
        keyboardHeight = UserDefaultsManager.shared.keyboardHeight
    }
    
    if let keyboardHeightConstraint {
        keyboardHeightConstraint.constant = keyboardHeight
    } else {
        let constraint = self.view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        constraint.priority = .init(999)
        constraint.isActive = true
        
        keyboardHeightConstraint = constraint
    }
}
```

|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 해결 이후 | <img src = "https://github.com/user-attachments/assets/be7f5279-7b22-4dcd-830e-85a98ad7141a" width ="250"> |

출처: [Stack Overflow - iOS 8 Custom Keyboard: Changing the height without warning 'Unable to simultaneously satisfy constraints...'](https://stackoverflow.com/questions/26569476/ios-8-custom-keyboard-changing-the-height-without-warning-unable-to-simultaneo)

<br>

---

<br>


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
처음에는 iOS 11부터 지원하는 `preferredScreenEdgesDeferringSystemGestures` 프로퍼티를 사용하여 해결하려 했지만, `UIInputViewController`에서는 지원하지 않는듯 했다.  
그래서 `UISystemGestureGateGestureRecognizer`의 `delaysTouchesBegan`를 `false`로 설정하는 것으로 해결하였다.
``` swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard let window = self.view.window else { fatalError("View가 window 계층에 없습니다.") }
    let systemGestureRecognizer0 = window.gestureRecognizers?[0] as? UIGestureRecognizer
    let systemGestureRecognizer1 = window.gestureRecognizers?[1] as? UIGestureRecognizer
    systemGestureRecognizer0?.delaysTouchesBegan = false
    systemGestureRecognizer1?.delaysTouchesBegan = false
}
```

> <img width="881" height="67" alt="image" src="https://github.com/user-attachments/assets/2306bfa1-1788-428a-8755-6817e464e48c" />
>
> 설정 이후 side effect가 생길 수 있다는 경고 메세지가 콘솔창에 뜬다.  
> 애플에서 `UIInputViewController`에 `preferredScreenEdgesDeferringSystemGestures`를 지원하게된다면 수정해야겠다.

출처: [Stack Overflow - UISystemGateGestureRecognizer and delayed taps near bottom of screen](https://stackoverflow.com/questions/19799961/uisystemgategesturerecognizer-and-delayed-taps-near-bottom-of-screen)

<br>

---

<br>


## 📊 다이어그램
### 키보드 종류 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "monospace",
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
    namespace KeyboardGestureController {
      class TextInteractionGestureController
      class SwitchGestureController
    }

    namespace KeyboardGestureProtocol {
      class SwitchGestureHandling
    }

    namespace KeyboardTypeLayoutProtocol {
      class HangeulKeyboardLayoutProvider
      class EnglishKeyboardLayoutProvider
      class SymbolKeyboardLayoutProvider
      class NumericKeyboardLayoutProvider
      class TenkeyKeyboardLayoutProvider
    }

    namespace ParentKeyboardViewController {
      class BaseKeyboardViewController
    }

    namespace FinalKeyboardViewController {
      class HangeulKeyboardViewController
      class EnglishKeyboardViewController
    }

    class NormalKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class PrimaryKeyboardRepresentable:::SYKeyboard_primary { <<protocol>> }
    class HangeulKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class EnglishKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class SymbolKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class NumericKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class TenkeyKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class SwitchGestureHandling:::SYKeyboard_primary { <<protocol>> }

    BaseKeyboardViewController --> PrimaryKeyboardRepresentable: Association
    BaseKeyboardViewController *-- SymbolKeyboardLayoutProvider: Composition
    BaseKeyboardViewController *-- NumericKeyboardLayoutProvider: Composition
    BaseKeyboardViewController *-- TenkeyKeyboardLayoutProvider: Composition

    NormalKeyboardLayoutProvider <|-- PrimaryKeyboardRepresentable: Inheritance
    NormalKeyboardLayoutProvider <|-- SymbolKeyboardLayoutProvider: Inheritance
    NormalKeyboardLayoutProvider <|-- NumericKeyboardLayoutProvider: Inheritance

    BaseKeyboardViewController *-- TextInteractionGestureController: Composition
    BaseKeyboardViewController *-- SwitchGestureController: Composition

    SwitchGestureHandling <|-- NormalKeyboardLayoutProvider: Inheritance
    SwitchGestureController --> SwitchGestureHandling: Association

    BaseKeyboardViewController <|-- HangeulKeyboardViewController: Inheritance
    BaseKeyboardViewController <|-- EnglishKeyboardViewController: Inheritance

    HangeulKeyboardViewController *-- HangeulKeyboardLayoutProvider: Composition
    PrimaryKeyboardRepresentable <|-- HangeulKeyboardLayoutProvider: Inheritance

    EnglishKeyboardViewController *-- EnglishKeyboardLayoutProvider: Composition
    PrimaryKeyboardRepresentable <|-- EnglishKeyboardLayoutProvider: Inheritance

    classDef SYKeyboard_primary fill:#ffa6ed
```

---

### 키보드 레이아웃 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "monospace",
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
      class FourByFourPlusKeyboardView
      class StandardKeyboardView
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
    class SwitchGestureHandling:::SYKeyboard_primary { <<protocol>> }
    class PrimaryKeyboardRepresentable:::SYKeyboard_primary { <<protocol>> }
    class HangeulKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class EnglishKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class SymbolKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class NumericKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }
    class TenkeyKeyboardLayoutProvider:::SYKeyboard_primary { <<protocol>> }

    BaseKeyboardLayoutProvider <|-- NormalKeyboardLayoutProvider: Inheritance
    SwitchGestureHandling <|-- NormalKeyboardLayoutProvider: Inheritance
    BaseKeyboardLayoutProvider <|-- TenkeyKeyboardLayoutProvider: Inheritance

    NormalKeyboardLayoutProvider <|-- PrimaryKeyboardRepresentable: Inheritance

    TenkeyKeyboardLayoutProvider ..|> TenkeyKeyboardView: Implementation

    PrimaryKeyboardRepresentable <|-- HangeulKeyboardLayoutProvider: Inheritance

    FourByFourKeyboardView <|-- NaratgeulKeyboardView: Inheritance
    HangeulKeyboardLayoutProvider <|.. NaratgeulKeyboardView: Implementation
    FourByFourPlusKeyboardView <|-- CheonjiinKeyboardView: Inheritance
    HangeulKeyboardLayoutProvider <|.. CheonjiinKeyboardView: Implementation

    PrimaryKeyboardRepresentable <|-- EnglishKeyboardLayoutProvider: Inheritance

    EnglishKeyboardLayoutProvider ..|> EnglishKeyboardView: Implementation
    StandardKeyboardView <|-- EnglishKeyboardView: Inheritance

    NormalKeyboardLayoutProvider <|-- SymbolKeyboardLayoutProvider: Inheritance
    SymbolKeyboardLayoutProvider ..|> SymbolKeyboardView: Implementation

    NormalKeyboardLayoutProvider <|-- NumericKeyboardLayoutProvider: Inheritance
    NumericKeyboardLayoutProvider ..|> NumericKeyboardView: Implementation
    
    classDef SYKeyboard_primary fill:#ffa6ed
```

---

### 키보드 버튼 구조
``` mermaid
%%{
  init: {
    "theme": "default",
    "fontFamily": "monospace",
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

---

<br>


## 📱 주요 기능
1. **나랏글 키보드**  
기본에 충실한 나랏글(EZ한글) 키보드입니다.

<img src = "https://github.com/user-attachments/assets/82f8f17e-821f-4680-be27-fa55c4bd908b" width ="250">

<br><br>


2. **천지인 키보드**  
입력이 편리한 천지인 키보드입니다.

<img src = "https://github.com/user-attachments/assets/8f7fb0bf-3e14-4929-b55b-c00884f5ddd7" width ="250">

<br><br>


3. **두벌식 키보드**
대중적인 두벌식(한글 쿼티) 키보드입니다.
(구현 예정)

<br><br>


4. **영어 키보드**
대중적인 영어(QWERTY) 키보드입니다.

<img src = "https://github.com/user-attachments/assets/b918f869-a23a-4c0c-953d-7a6a1363b654" width ="250">

<br><br>


5. **숫자 키패드 탑재**  
숫자를 입력할 때 큰 버튼으로 편하게 입력할 수 있는 숫자 입력 전용 키패드를 탑재했습니다.

<img src="https://github.com/user-attachments/assets/99b11dac-2761-42d2-a54f-d5e440c421cb" width="250">
    
<br><br>


6. **한 손 키보드 모드**  
한 손으로 폰을 들고 있는 상태에서도 입력하기 수월하도록 한 손 키보드 모드를 제공합니다.

<img src="https://github.com/user-attachments/assets/8854953a-d0bd-4615-ad04-caa5c620e3db" width="250">

<br><br>


7. **다양하고 디테일한 키보드 설정**  
길게 누르기 동작, 커서 이동, 키보드 높이 및 한 손 키보드 너비 조절 등 사용자의 편의에 맞게 키보드 설정이 가능합니다.

<img src="https://github.com/user-attachments/assets/7163eff8-046c-4c2d-a2d9-1d635dac2cca" width="250">

<br><br>

