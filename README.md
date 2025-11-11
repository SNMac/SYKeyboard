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

### KeyboardInputViewController에서 높이 지정 시 키보드 표시 애니메이션 글리칭 현상
|    설명    |   스크린샷   |    설명    |   스크린샷   |
| :-------------: | :----------: | :-------------: | :----------: |
| 문제 상황 | <img src = "https://github.com/user-attachments/assets/4a33c68c-40f8-43d7-a968-d539f51a7ccf" width ="250"> | 해결 이후 | <img src = "https://github.com/user-attachments/assets/be7f5279-7b22-4dcd-830e-85a98ad7141a" width ="250"> |

<br><br>

### 키보드 가장자리 터치 딜레이
|    설명    |   스크린샷   |
| :-------------: | :----------: |
| 문제 상황 | <img src = "https://github.com/user-attachments/assets/31aed9f1-ac3b-4839-aa42-b7a21e0693ab" width ="250"> |

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

