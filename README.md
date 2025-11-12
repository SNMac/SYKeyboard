<img src="https://github.com/user-attachments/assets/fb7e719e-7353-4649-8ecc-a11058a6c3d6" width="200">

# SY키보드
> SY키보드는 가볍고, 사용하기 간편한 나랏글 키보드입니다. (추후 천지인 키보드 추가 예정)  
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
- 필수적인 기능들을 포함하되 가벼운 키보드 앱을 찾는 사람

<br><br>


## 👨‍💻 트러블 슈팅
### SwiftUI -> UIKit 리팩토링 이유

<br><br>

### `BaseKeyboardViewController`에서 키보드 높이 제약조건 지정 시 키보드 표시 애니메이션 글리칭 현상
#### 문제 상황
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 애니메이션 글리칭 | <img src = "https://github.com/user-attachments/assets/4a33c68c-40f8-43d7-a968-d539f51a7ccf" width ="250"> |
- 애플 공식 문서([레거시](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [최신](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface#Adapt-to-different-layouts)) 기반으로 키보드 높이 조절 코드를 구현했을 때 왼쪽 GIF처럼 키보드가 잠깐동안 높이 튀어오르는 현상 발생
    - view를 위한 애니메이션이 구성되기 직전인 `viewWillAppear` 메서드에 높이 제약조건 코드 구현
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

<br>

#### 원인 분석
- 문제 해결을 위해 찾아보던 중 Stack Overflow의 한 [질문글의 답변](https://stackoverflow.com/a/62114742)에서 힌트를 얻음
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
1. 제약조건이 설정되었는지를 판단하는 플래그 변수 `constraintsHaveBeenAdded` 설정
2. 제약조건이 이미 설정되었거나, 상위 view가 설정되지 않은 경우 실행 X (방어 코드)
3. **view의 모든 edge에 대해 상위 view와 같도록 제약조건 설정**
4. `constraintsHaveBeenAdded`를 true로 설정

> - 이전 코드에선 view의 모든 edge에 대해 상위 view와 같도록 제약조건을 설정하는 코드(`$0.edges.equalToSuperview()`)와 `translatesAutoresizingMaskIntoConstraints`를 `false`로 설정하는 코드가 없었음
> - 이로 인해 Autoresizing Mask로 view의 크기와 위치를 정하려 하는 과정에서 Auto Layout의 높이 제약조건이 충돌을 일으켜 애니메이션에 글리칭이 발생한 것으로 추측
> - `translatesAutoresizingMaskIntoConstraints`만 `false`로 설정하는 경우 아래 사진처럼 UI가 치우치는 현상이 발생함
>   
> |    설명    |   스크린샷   |
> | :-------------: | :----------: |
> | UI 치우침 현상 | <img src = "https://github.com/user-attachments/assets/5198d906-e813-4e79-b537-300e96bb52c2" width ="250"> |

<br>

#### 해결 과정
위 답변을 토대로 높이 제약조건 코드 수정 및 방어코드 추가
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

<br><br>


### 키보드 가장자리 터치 딜레이
#### 문제 상황
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 터치 딜레이 영역 | <img src = "https://github.com/user-attachments/assets/31aed9f1-ac3b-4839-aa42-b7a21e0693ab" width ="250"> |

#### 원인 분석

#### 해결 과정


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

