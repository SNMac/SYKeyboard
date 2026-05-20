# SYKeyboard Coding Conventions

이 문서는 실제 코드 파일을 훑어 파악한 SYKeyboard의 코딩 관례를 정리한다. 새 코드를 작성하거나 기존 코드를 고칠 때는 아래 패턴을 우선 따른다.

## 공통 Swift 스타일

- 파일 상단은 Xcode 기본 헤더 주석을 유지한다.
- import는 표준/Apple 프레임워크, 빈 줄, 외부 라이브러리, 빈 줄, 내부 모듈 순서로 그룹화한다.
- 타입 내부는 `// MARK: - Properties`, `// MARK: - UI Components`, `// MARK: - Initializer`, `// MARK: - Lifecycle`, `// MARK: - Content`, `// MARK: - Private Methods` 같은 섹션으로 나눈다.
- 구현 보조 메서드는 타입 본문 아래 `private extension TypeName`으로 분리한다.
- UIKit UI 구성 메서드는 `setupUI()`, `setStyles()`, `setActions()`, `setHierarchy()`, `setConstraints()` 순서를 따른다. 필요 없는 단계는 생략할 수 있다.
- `required init?(coder:)`를 지원하지 않는 UIKit 타입은 기존처럼 `fatalError("init(coder:) has not been implemented")`를 사용한다.
- 의도상 구현되어야 하는 override 지점은 `fatalError("프로퍼티가 오버라이딩 되지 않았습니다.")` 또는 `assertionFailure(...)`로 드러낸다.
- 주석은 한국어를 기본으로 한다. 도메인 의도가 중요한 한글 조합, 확정/조합 버퍼, 제스처 순서, UserDefaults 설정에는 짧은 설명 주석을 남긴다.

## 접근 제어와 타입 설계

- 앱/extension 내부 전용 타입은 기본 internal 또는 `final class`를 우선한다.
- Core 모듈에서 다른 타깃이 사용해야 하는 타입, 프로토콜, View는 `public` 또는 `open`으로 공개한다.
- 상속이 필요한 베이스 타입은 `open class`와 `open var`/`open func`를 사용하고, 상속이 필요 없는 공개 타입은 `final public class` 패턴을 따른다.
- 외부에서 읽어야 하지만 수정은 내부에서만 해야 하는 UI 구성 요소는 `public private(set)`을 사용한다.
- delegate 프로토콜은 `AnyObject`를 채택하고, delegate 프로퍼티는 `weak var delegate`로 둔다.
- UIKit controller/view 간 상태 주입은 delegate 또는 closure injection을 사용한다. 기존 코드의 `get...`, `set...` 클로저 패턴을 따른다.

## SwiftUI 설정 화면

- 설정 화면은 작은 `View` 단위로 나누고 `body`에는 List/Section/Toggle/Picker/NavigationLink 중심의 선언형 구성을 둔다.
- 앱 그룹 설정값은 `@AppStorage(UserDefaultsKeys..., store: UserDefaultsManager.shared.storage)`로 연결한다.
- 설정값 기본값은 `DefaultValues`를 사용한다.
- 설정 변경 시 기존 패턴처럼 `Analytics.setUserProperty`, `Analytics.logEvent`, `hideKeyboard()` 호출 여부를 확인한다.
- 설정 화면에서 enum을 정의할 때는 `Int, CaseIterable`을 주로 사용하고, 표시 문자열은 `displayStr`, Analytics 값은 `analyticsValue`처럼 분리한다.
- `#Preview`는 파일 하단에 `// MARK: - Preview` 섹션으로 둔다.

## UIKit 키보드 UI

- 키보드 view/controller는 UIKit 기반이다. SwiftUI 패턴을 extension 런타임으로 가져오지 않는다.
- UI 하위 뷰는 `private let` 또는 `private lazy var`로 선언하고, 외부 접근이 필요한 버튼/오버레이는 `public private(set)`을 사용한다.
- 스택/버튼 hierarchy는 배열과 `forEach`로 반복 추가하는 패턴을 따른다.
- Auto Layout은 `translatesAutoresizingMaskIntoConstraints = false` 후 `NSLayoutConstraint.activate`를 사용한다.
- 버튼/제스처 상태는 `ButtonStateController`, `TextInteractionGestureController`, `SwitchGestureController`의 책임을 유지한다.
- gesture handler에서는 `.began`, `.changed`, `.ended/.cancelled/.failed` 순서의 상태 전이를 명시하고, 코드에 적힌 “순서 중요” 주석이 있는 흐름은 임의로 재배치하지 않는다.
- `UIAction` 클로저에서는 `[weak self]`를 사용하고, 필요한 경우 `guard let self else { return }`로 강하게 잡는다.
- preview 경로는 `BaseKeyboardViewController.isPreview`로 분기한다.

## 한글 입력 로직

- 입력 조합 규칙은 UI가 아니라 `Modules/HangeulKeyboardCore/Domain/`에 둔다.
- `HangeulAutomata`는 표준 조합/분해를 담당하고, 나랏글/천지인/두벌식의 키보드별 차이는 각 Processor가 담당한다.
- `HangeulProcessable`의 기본 구현인 `inputWithRestore종성`, `deleteWithRestore종성`을 우회하지 않는다.
- 결과 타입은 `CompositionResult`, `DeleteResult`, `SpaceInputResult`를 사용해 확정(`committed`)과 조합 중(`composing`)을 분리한다.
- 한글 도메인 변수명은 기존 코드처럼 `글자Input`, `초성Index`, `중성Table`, `종성Table`, `한글조합` 등 한국어 식별자를 사용할 수 있다.
- 스페이스 확정 보호, `committedTail`, `consumedCommittedCount`, `protectedCommittedCount`와 관련된 변경은 컨트롤러 통합 테스트까지 확인한다.

## UserDefaults와 설정값

- 새 설정값은 최소한 다음 위치를 함께 확인한다.
  - `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
  - `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
  - `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
  - 앱 타깃 확장 파일(`SYKeyboard/Storage/*+Extension.swift`)
  - 키보드별 Core 확장 파일(`Modules/HangeulKeyboardCore/Storage/*+Extension.swift`, `Modules/EnglishKeyboardCore/Storage/*+Extension.swift`)
- `UserDefaultsKeys`와 `DefaultValues`는 설정 그룹별 주석을 유지한다.
- RawRepresentable 설정은 rawValue 저장/복원 실패 시 기본값으로 fallback하는 패턴을 따른다.
- 설정값 추가 후 앱 설정 화면, 키보드 런타임 반영, Analytics user property 초기화 여부를 함께 확인한다.

## 로깅, Analytics, 오류 처리

- `Logger`는 `Bundle.main.bundleIdentifier ?? "Unknown Bundle"`과 타입명을 category로 사용하는 패턴을 따른다.
- 인스턴스 구분이 필요한 UIKit/Core 객체는 category에 `Unmanaged.passUnretained(self).toOpaque()`를 포함한다.
- extension의 Firebase 초기화는 `FirebaseApp.app() == nil` 확인 후 수행한다.
- Crashlytics 기록은 extension에서 메모리 경고, 잘못된 URL 등 실제 오류 맥락이 있을 때 사용한다.
- 사용자 설정 변경 이벤트는 `Analytics.setUserProperty`와 `Analytics.logEvent`를 함께 쓰는 기존 설정 화면 패턴을 따른다.

## 테스트 스타일

- 테스트는 Swift Testing을 사용한다.
- 테스트 파일은 `@Suite("... 검증")`와 `@Test("...")`의 한국어 설명을 사용한다.
- 입력기 테스트는 `HangeulProcessorTestable`의 `applyInput`, `applyDelete` 헬퍼를 재사용한다.
- 컨트롤러 레벨 동작은 `KeyboardControllerSimulator`를 사용하는 통합 테스트로 검증한다.
- 한글 조합 변경은 단일 케이스뿐 아니라 삭제, 재입력, 반복 입력, 확정 보호, 11,172자 heavy test 영향을 확인한다.

