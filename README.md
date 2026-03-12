<img src="https://github.com/user-attachments/assets/fb7e719e-7353-4649-8ecc-a11058a6c3d6" width="200">

# SY키보드
> SY키보드는 가볍고, 사용하기 간편한 한글, 영어 키보드입니다.
> - 한글 키보드: 나랏글, 천지인, 두벌식
> - 영어 키보드: QWERTY  
> 
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
- 나랏글/천지인 키보드를 사용 중이거나 입문하는 사람
-  키보드 앱을 찾는 사람
- 키보드 자체 기능과 더불어 기본적인 편의 기능이 있는 키보드를 사용해 보고 싶은 사람
  - 한 손 키보드, 키보드 높이 조절, 자동완성 문구 추천 등
- 한글 키보드를 사용해 보고 싶은 외국인

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
| 로컬라이징 | `String Catalog` |
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
    let inputAction = UIAction { [weak self] action in
        guard let self, let currentButton = action.sender as? TextInteractable else { return }
        
        if currentButton.isProgrammaticCall {
            // 코드(sendActions)로 호출된 경우 -> 무조건 입력 수행
            performTextInteraction(for: currentButton)
            
        } else {
            // 사용자가 touchUpInside한 경우 -> currentPressedButton 확인
            if let currentPressedButton = buttonStateController.currentPressedButton,
               currentPressedButton == currentButton {
                performTextInteraction(for: currentButton)
            }
        }
    }
    if button is DeleteButton {
        button.addAction(inputAction, for: .touchDown)
    } else if let spaceButton = button as? SpaceButton {
        button.addAction(inputAction, for: .touchUpInside)
        addPeriodShortcutActionToSpaceButton(spaceButton)
    } else {
        button.addAction(inputAction, for: .touchUpInside)
    }
}

// ButtonStateController 클래스의 일부
func setFeedbackActionToButtons(_ buttonList: [BaseKeyboardButton]) {
    buttonList.forEach { button in
        let playFeedbackAndSetPressed: UIAction
        if button is ShiftButton {
            playFeedbackAndSetPressed = UIAction { [weak self] action in
                guard let senderButton = action.sender as? BaseKeyboardButton else { return }
                
                if let previousButton = self?.currentPressedButton, previousButton != senderButton {
                    previousButton.sendActions(for: .touchUpInside)
                }
                
                self?.isShiftButtonPressed = true
                senderButton.playFeedback()
            }
        } else {
            playFeedbackAndSetPressed = UIAction { [weak self] action in
                guard let senderButton = action.sender as? BaseKeyboardButton else { return }
                
                if let previousButton = self?.currentPressedButton, previousButton != senderButton {
                    previousButton.sendActions(for: .touchUpInside)
                }
                
                self?.currentPressedButton = senderButton
                senderButton.playFeedback()
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
            backgroundView.backgroundColor = isGesturing ? .primaryButtonPressed : .primaryButton
        case .highlighted:
            backgroundView.backgroundColor = isPressed || isGesturing ? .primaryButtonPressed : .primaryButton
        default:
            break
        }
    }
}
```
</details>

<br>

#### 결론 및 회고
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 리팩토링 이전 | <img height="500" alt="SY키보드 구버전 입력 처리 시간" src="https://github.com/user-attachments/assets/0586e311-26e5-461d-bb1d-afdaf133696f" /> |
| 리팩토링 이후 | <img height="500" alt="SY키보드 신버전 입력 처리 시간" src="https://github.com/user-attachments/assets/ce6d53a4-b30f-4535-9aa0-b4adc0c0d6d6" /> |
> 실기기에 리팩토링 이전과 이후 버전을 Release 빌드로 설치 후 "동해물과 백두산이 마르고 닳도록"을 입력, 키보드의 입력 처리 시간을 측정한 결과이다.

<br>

명령형 프레임워크인 UIKit으로 리팩토링하면서 복잡한 버튼, 제스처 로직을 효율적으로 처리할 수 있었지만, 선언형 프레임워크인 SwiftUI보다 UI 구현 코드는 더 길어지게 되었다.  
하지만 리팩토링 이후 키보드 입력 처리 시간이 이전보다 1/3 정도로 단축되어 성능이 높아지는 이점을 얻을 수 있었다.  
또한, 현재로선 UIKit이 SwiftUI보다 세밀한 커스텀이 가능한 장점이 있어 SY키보드에는 UIKit이 좀더 적합하다고 생각된다.  
최근 WWDC에서 SwiftUI 위주의 업데이트가 계속 발표되고 있으니, 나중에 커스텀하기 더 편하게 SwiftUI가 업데이트된다면 그때 다시 SwiftUI로 리팩토링을 해봐야겠다.

<br>

---

<br>

### 메모리 누수로 인한 크래시
#### 문제 상황
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| Crashlytics | <img src = "https://github.com/user-attachments/assets/98888ed5-0803-40d2-b69f-daea116388e0" width ="1000"> |
| Instruments<br>Allocations | <img src = "https://github.com/user-attachments/assets/b1984b51-6bcf-4e50-88de-a31dd5a8d5ee" width ="1000"> |
| Instruments<br>Generations | <img src = "https://github.com/user-attachments/assets/c0cebf30-cf81-459f-a0db-e351c250128f" width ="1000"> |

Crashlytics에 `didReceiveMemoryWarning` 로그와 크래시가 발생하는 것을 보고, Profile을 실행하여 다음 사항을 확인했다.
- Allocations 그래프를 통해 키보드 dismiss 이후에도 인스턴스가 메모리에서 해제되지 않음
- 키보드 dismiss 이후 Generation에 키보드 관련 인스턴스 존재
- 키보드를 표시할때마다 새로운 인스턴스가 쌓이다가 임계점을 넘어가면 크래시가 발생

<br>

#### 원인 분석
- `KeyboardView`가 `deinit`되지 않음
1. iOS 버그로 인해 코드 베이스 레이아웃 작성 시 `BaseKeyboardViewController`(`UIInputViewController`)의 `view`(`UIInputView`)가 메모리에서 해제되지 않는다.
2. `view`의 `subview`인 `KeyboardView` 또한 해제되지 않게 된다.
 
- 버튼이 순환 참조로 인해 `deinit`되지 않음
1. `BaseKeyboardViewController`와 `ButtonStateController`에서 버튼에 액션을 할당할 때, 클로저 내부에서 인자로 들어온 버튼을 강하게 참조
2. 버튼 -> `UIAction` -> 클로저 -> 버튼 순환 참조
3. `UIAction` 클로저 내부 `[weak self]`는 해당 인스턴스와의 연결만 약한 참조로 변경
 
```swift
// BaseKeyboardViewController (UIInputViewController)

func addInputActionToTextInterableButton(_ button: TextInteractable) {
    let inputAction = UIAction { [weak self] action in
        guard let self, let currentButton = action.sender as? TextInteractable else { return }
        
        if currentButton.isProgrammaticCall {
            // 메서드 인자인 'button'을 클로저가 강하게 참조(캡처)
            performTextInteraction(for: button)
    // ...
```

<br>

#### 해결 과정
- `KeyboardView`를 Storyboard(xib)로 초기화하고, `loadView` 시점에 할당하도록 수정
- `UIAction` 클로저의 매개변수를 활용하여 버튼 객체에 대한 강한 참조 제거

```swift
// BaseKeyboardViewController (UIInputViewController)

deinit {
    logger.debug("\(String(describing: type(of: self))) deinit")
    keyboardView.removeFromSuperview()
}

func addInputActionToTextInterableButton(_ button: TextInteractable) {
    let inputAction = UIAction { [weak self] action in
        guard let self, let currentButton = action.sender as? TextInteractable else { return }
        
        if currentButton.isProgrammaticCall {
            // UIAction 클로저의 매개변수를 활용, 버튼에 대한 강한 참조(캡처) 제거
            performTextInteraction(for: currentButton)
    // ...
```


|    설명    |   스크린샷   |
| :-------------: | :----------: |
| Instruments<br>Allocations | <img src = "https://github.com/user-attachments/assets/831cdd9d-310b-4e3c-aa11-0e2a970c35f8" width ="1000"> |
| Instruments<br>Generations | <img src = "https://github.com/user-attachments/assets/7a79b68e-cf66-499b-9cbd-076e2082a15e" width ="1000"> |

Instruments의 Allocations 그래프와 Generations 표를 통해 키보드 dismiss 이후에 인스턴스가 메모리에서 해제되는 것을 확인하였다.  

출처: [Apple Developer Forums - UIInputView is not deallocated from memory](https://developer.apple.com/forums/thread/807619)

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

    namespace KeyboardLayoutProtocol {
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
      class DubeolsikKeyboardView
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
    StandardKeyboardView <|-- DubeolsikKeyboardView: Inheritance
    HangeulKeyboardLayoutProvider <|.. DubeolsikKeyboardView: Implementation

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

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="나랏글" src="https://github.com/user-attachments/assets/15493bed-ac5e-4a2c-899b-47d856f40364"> | <img width="300" alt="나랏글 - 영어" src="https://github.com/user-attachments/assets/97685cc5-8b97-4698-9715-586f860199c3"> |

<br><br>


2. **천지인 키보드**  
입력이 편리한 천지인 키보드입니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="천지인" src="https://github.com/user-attachments/assets/ca129e21-e852-4ae3-b377-78402414b42f"> | <img width="300" alt="천지인 - 영어" src="https://github.com/user-attachments/assets/9326e623-c338-4473-bf1a-ab9282d8e7dd"> |

<br><br>


3. **두벌식 키보드**  
대중적인 두벌식(한글 쿼티) 키보드입니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="두벌식" src="https://github.com/user-attachments/assets/aaf9392b-9e2b-4d84-ae08-d74af635c531"> | <img width="300" alt="두벌식 - 영어" src="https://github.com/user-attachments/assets/615421f0-780d-422b-8c9e-761303092058"> |

<br><br>


4. **영어 키보드**  
대중적인 영어(QWERTY) 키보드입니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="쿼티" src="https://github.com/user-attachments/assets/b121994d-4ff6-4050-a5f4-c26706a8ebde"> | <img width="300" alt="쿼티 - 영어" src="https://github.com/user-attachments/assets/5ed489c4-6538-4be9-b00d-cc860ef172c3"> |

<br><br>


5. **숫자 키패드 탑재**  
숫자를 입력할 때 큰 버튼으로 편하게 입력할 수 있는 숫자 입력 전용 키패드를 탑재했습니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="숫자 키패드" src="https://github.com/user-attachments/assets/2c68169f-4dcb-4732-90a2-fa415885cd0e"> | <img width="300" alt="숫자 키패드 - 영어" src="https://github.com/user-attachments/assets/4c48f4fa-d50a-49bf-8e72-479aa9185a25"> |

<br><br>


6. **한 손 키보드 모드**  
한 손으로 폰을 들고 있는 상태에서도 입력하기 수월하도록 한 손 키보드 모드를 제공합니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="한 손 키보드" src="https://github.com/user-attachments/assets/fbb6019e-dbd5-4bb4-9d83-c4164a9502d4"> | <img width="300" alt="한 손 키보드 - 영어" src="https://github.com/user-attachments/assets/764c0f9f-9296-4b7d-a5cc-125a113b6beb"> |

<br><br>


7. **자동완성 문구**  
입력한 단어에 맞는 자동완성 문구를 추천합니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="자동완성" src="https://github.com/user-attachments/assets/a6973023-601f-4310-82f3-a23c687805d8"> | <img width="300" alt="자동완성 - 영어" src="https://github.com/user-attachments/assets/2416ad73-b1c6-43f8-a1c7-b818a1224348"> |

<br><br>


8. **다양하고 디테일한 키보드 설정**  
길게 누르기 동작, 커서 이동, 키보드 높이 및 한 손 키보드 너비 조절 등 사용자의 편의에 맞게 키보드 설정이 가능합니다.

|    한국어    |   영어   |
| :-------------: | :----------: |
| <img width="300" alt="메인 앱 1" src="https://github.com/user-attachments/assets/bde6db7a-afdb-4e6a-a010-7509e312a251"> | <img width="300" alt="메인 앱 1 - 영어" src="https://github.com/user-attachments/assets/ebf5b3ca-3187-4c90-b058-1ae288f139a1"> |
| <img width="300" alt="메인 앱 2" src="https://github.com/user-attachments/assets/ddc33920-46bf-4834-8824-451686b71ab0" width="300"> | <img width="300" alt="메인 앱 2 - 영어" src="https://github.com/user-attachments/assets/a4d4fbfe-0718-4a2c-944e-4cb5c6c97e69" width="300"> |
| <img width="300" alt="메인 앱 3" src="https://github.com/user-attachments/assets/7cb7a502-c769-4fae-80e9-b83fce0886aa" width="300"> | <img width="300" alt="메인 앱 3 - 영어" src="https://github.com/user-attachments/assets/bc8d8ffe-a511-443c-a661-88438df14275" width="300"> |

<br><br>

