//
//  KeyboardFrameInsetsPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 11/1/26.
//

import CoreGraphics

/// 실제 키보드가 화면 안에서 비우는 여백. 설정 앱 미리보기가 같은 자리에 키를 놓는 데 쓴다.
///
/// 가로 화면에서 iOS는 키보드 뷰를 화면보다 좁게 가운데에 준다(양옆은 지구본·받아쓰기 자리). iPhone Duo는 세로에서도
/// 양옆을 조금 비운다. 키보드 뷰 아래에는 홈 인디케이터 자리와, 세로에서는 지구본·받아쓰기 줄 자리를 비운다.
/// 설정 앱은 이 값을 읽을 API가 없다. 키보드가 기록해 두는 방식은 하드웨어 키보드처럼
/// 키보드가 화면에 보이지 않을 때도 extension이 다른 크기로 레이아웃되어 틀린 값이 남으므로 쓰지 않고,
/// 시뮬레이터에서 측정한 값을 화면 크기별로 둔다
public enum KeyboardFrameInsetsPolicy {

    /// 화면 끝에서 키보드 뷰까지의 여백
    public struct Insets: Equatable {
        public let leading: CGFloat
        public let trailing: CGFloat
        /// 화면 아래 끝에서 키보드 뷰 아래 끝까지. 홈 인디케이터 자리와 세로의 지구본·받아쓰기 줄 자리다
        public let bottom: CGFloat

        public static let zero = Insets(leading: 0, trailing: 0, bottom: 0)

        public init(leading: CGFloat, trailing: CGFloat, bottom: CGFloat) {
            self.leading = leading
            self.trailing = trailing
            self.bottom = bottom
        }
    }

    /// 측정값 표의 키. 현재 방향 기준 화면 크기를 pt 단위 정수로 반올림한다
    struct ScreenSize: Hashable {
        let width: Int
        let height: Int

        init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }

        init(_ size: CGSize) {
            self.init(width: Int(size.width.rounded()), height: Int(size.height.rounded()))
        }
    }

    /// 홈 인디케이터 기기의 가로 화면에서 키보드가 양옆에 비우는 여백.
    /// iPhone 13 mini, iPhone 17e, iPhone Duo 바깥·안쪽 화면에서 모두 같았다
    public static let landscapeSideInset: CGFloat = 75

    /// Dynamic Island 기기의 가로 화면에서 키보드가 양옆에 비우는 여백. iPhone Air, iPhone 18 Pro Max 측정값
    public static let wideLandscapeSideInset: CGFloat = 117

    /// 가로 화면에서 설정 앱 창의 양옆 safe area가 이 값 이상이면 Dynamic Island 기기로 본다.
    /// 노치 기기는 47pt에서 50pt, Dynamic Island 기기는 59pt 이상이다
    static let wideSideSafeAreaThreshold: CGFloat = 55

    /// 홈 인디케이터 기기의 세로 화면에서 키보드 아래에 비우는 자리(지구본·받아쓰기 줄과 홈 인디케이터). iPhone 13 mini 측정값
    public static let portraitBottomInset: CGFloat = 75

    /// 홈 인디케이터 기기의 가로 화면에서 키보드 아래에 비우는 자리(홈 인디케이터). iPhone 17e, Air, 18 Pro Max 측정값
    public static let landscapeBottomInset: CGFloat = 20

    /// 기본 규칙과 다른 화면의 측정값
    static let measuredInsets: [ScreenSize: Insets] = [
        // iPhone 13 mini 가로는 아래가 기본값보다 1pt 크다
        ScreenSize(width: 812, height: 375): Insets(leading: landscapeSideInset, trailing: landscapeSideInset, bottom: 21),
        // iPhone Duo 바깥·안쪽 화면 세로. 키보드에 지구본 키가 있어도 아래를 비운다
        ScreenSize(width: 466, height: 678): Insets(leading: 7, trailing: 7, bottom: 32),
        ScreenSize(width: 669, height: 951): Insets(leading: 7, trailing: 7, bottom: 70),
        // iPhone Duo 바깥·안쪽 화면 가로
        ScreenSize(width: 678, height: 466): Insets(leading: landscapeSideInset, trailing: landscapeSideInset, bottom: 16),
        ScreenSize(width: 951, height: 669): Insets(leading: landscapeSideInset, trailing: landscapeSideInset, bottom: 16)
    ]

    /// 화면 크기(현재 방향 기준, pt)에 맞는 여백.
    /// 표에 없으면 홈 인디케이터 기기만 비운다. 가로는 양옆과 홈 인디케이터 자리, 세로는 지구본·받아쓰기 줄까지 아래를 비운다.
    /// 가로 양옆은 설정 앱 창의 양옆 safe area(`sideSafeAreaInset`)로 노치 기기와 Dynamic Island 기기를 나눈다
    public static func insets(screenSize: CGSize, hasHomeIndicator: Bool, sideSafeAreaInset: CGFloat) -> Insets {
        if let measured = measuredInsets[ScreenSize(screenSize)] {
            return measured
        }

        guard hasHomeIndicator else { return .zero }

        if screenSize.width > screenSize.height {
            let side = sideSafeAreaInset >= wideSideSafeAreaThreshold ? wideLandscapeSideInset : landscapeSideInset
            return Insets(leading: side, trailing: side, bottom: landscapeBottomInset)
        }
        return Insets(leading: 0, trailing: 0, bottom: portraitBottomInset)
    }
}
