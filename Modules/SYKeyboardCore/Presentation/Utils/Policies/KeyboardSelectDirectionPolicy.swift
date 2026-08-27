//
//  KeyboardSelectDirectionPolicy.swift
//  SYKeyboardCore
//

/// 키보드 선택 오버레이가 `switchButton` 기준 어느 쪽으로 열리는지 결정한다.
///
/// 이 방향은 네 곳이 함께 지켜야 한다.
/// 제스처 판정(`SwitchGestureController`), 오버레이 내부 배치(`KeyboardSelectOverlayView`),
/// 코너 힌트 라벨(`SwitchButton`), 오버레이 앵커(`FourByFourPlusKeyboardView`).
/// 어긋나면 힌트와 실제 제스처 방향이 달라지므로 한 곳에서만 정한다
enum KeyboardSelectDirectionPolicy {
    /// - Parameters:
    ///   - keyboard: 현재 키보드 종류
    ///   - usesBottomSpaceLayout: 천지인 스페이스 하단 배치 사용 여부
    static func targetDirection(for keyboard: SYKeyboardType,
                                usesBottomSpaceLayout: Bool) -> PanDirection {
        switch keyboard {
        case .cheonjiin:
            // 하단 배치에서는 `switchButton`이 4행 좌측 끝으로 가므로
            // 오버레이가 펼쳐질 공간이 오른쪽밖에 없다
            return usesBottomSpaceLayout ? .right : .left
        case .naratgeul, .numeric:
            return .left
        case .dubeolsik, .qwerty, .symbol:
            return .right
        case .tenKey:
            // 텐키에는 키보드 선택 제스처가 없다. 기존 기본값을 유지한다
            return .left
        }
    }
}
