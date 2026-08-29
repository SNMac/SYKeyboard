//
//  KeyboardFigure.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/2/25.
//

import CoreFoundation

/// 키보드 레이아웃 수치
public enum KeyboardLayoutFigure {
    /// 버튼 코너값
    static let buttonCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 8.5
        } else {
            return 4.6
        }
    }()
    /// 키보드 가로모드 높이
    public static let landscapeKeyboardHeight: CGFloat = 188.0
    /// 키보드 프레임 내부 간격
    public static let keyboardFrameSpacing: CGFloat = 4.0
    /// 키보드 자동완성 툴바 높이 (여백 포함)
    public static let suggestionBarHeightWithTopSpacing: CGFloat = 44.0
    /// 키보드 자동완성 버튼 구분선 높이
    static let suggestionButtonDividerHeight: CGFloat = 24.0
    /// Undo/Redo 버튼 너비
    static let undoRedoButtonWidth: CGFloat = 44.0
    /// Shift 버튼과 삭제 버튼 곱하기 계수
    static let shiftAndDeleteButtonWidthMultiplier: CGFloat = 1.35
    /// 리턴 버튼 영역이 차지하는 열 너비 비율
    static let returnButtonWidthMultiplier: CGFloat = 0.25
    /// 한영 전환 버튼 곱하기 계수. 글자 버튼과 같은 너비를 사용한다
    static let languageSwitchButtonWidthMultiplier: CGFloat = 1.0
    /// 4x4 계열 키보드의 열 개수
    static let fourColumnCount: Int = 4
    /// 4x4 계열 글자 열 너비 배율 범위.
    ///
    /// `1.0`이 현재의 균등 분할이고, 값이 커질수록 글자 열이 넓어지고 기능 열이 좁아진다.
    /// 상한 `1.15`는 한 손 키보드 기본 폭(320pt)에서 기능 열이 정확히 44pt로
    /// Apple HIG 최소 터치 타깃을 유지하는 값이다
    public static let letterColumnWidthMultiplierRange: ClosedRange<Double> = 1.0...1.15
    /// 슬라이더 표시용 정수 범위(100 단위).
    ///
    /// `0.01` 단위 실수 step은 이진 부동소수점 오차로 스텝 수가 잘려 상한에 닿지 못한다.
    /// 슬라이더는 정수 스텝을 쓰고 저장할 때 100으로 나눈다
    public static let letterColumnWidthPercentRange: ClosedRange<Double> = (letterColumnWidthMultiplierRange.lowerBound * 100).rounded()...(letterColumnWidthMultiplierRange.upperBound * 100).rounded()
    /// 지구본 버튼 곱하기 계수. 한영 전환 버튼과 같은 너비를 사용한다
    static let nextKeyboardButtonWidthMultiplier: CGFloat = languageSwitchButtonWidthMultiplier
    /// 통합 키보드에서 한영 전환 버튼과 합친 너비가 리턴 버튼과 같아지는 `switchButton` 곱하기 계수
    /// - Parameter columnCount: 글자 버튼 열 개수
    static func switchButtonWidthMultiplier(columnCount: Int) -> CGFloat {
        returnButtonWidthMultiplier * CGFloat(columnCount) - languageSwitchButtonWidthMultiplier
    }
    /// 기호 키보드 세번째 열 버튼 곱하기 계수
    static let symbolThirdRowButtonWidthMultiplier: CGFloat = 1.4
    /// 키보드 레이아웃 선택 오버레이의 목표(숫자·기호) 영역 너비.
    ///
    /// 취소 영역 너비는 `switchButton` 크기를 따라 변하므로, 목표 영역을 고정해
    /// 오버레이 전체 너비가 취소 영역만큼만 늘고 줄게 한다
    static let keyboardSelectTargetWidth: CGFloat = 78.0
    /// 선택 취소 영역의 경계선을 `switchButton` 바깥 모서리에서 안쪽으로 들여놓는 폭.
    ///
    /// 오버레이는 손가락이 `switchButton` 밖으로 나갈 때 열리므로, 경계선을 모서리에
    /// 정확히 맞추면 열리는 순간 손가락이 경계 위에 놓여 미세한 흔들림마다 선택이 뒤집힌다.
    /// 이만큼 들여놓으면 열리는 시점에 이미 목표 쪽으로 들어와 있다
    static let keyboardSelectBoundaryInset: CGFloat = 4.0
    /// 선택 취소 영역 최소 너비. `switchButton`이 좁아도 아이콘이 잘리지 않게 한다
    static let keyboardSelectCancelMinWidth: CGFloat = 32.0
    /// 한 손 키보드 선택 오버레이 너비
    static let oneHandedModeSelectOverlayWidth: CGFloat = 240.0
    /// 선택 오버레이 높이
    static let selectOverlayHeight: CGFloat = 60.0
    /// 선택 오버레이 코너값
    static let selectOverlayCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 8.5
        } else {
            return 4.6
        }
    }()
    // 기타 오버레이 코너값
    static let otherOverlayCornerRadius: CGFloat = {
        if #available(iOS 26, *) {
            return 12.0
        } else {
            return 0.0
        }
    }()
}

/// 키보드 버튼  `font`, `image` 크기
enum FontSize {
    static let charKeyMedium: CGFloat = 20.0
    static let charKeyLarge: CGFloat = 22.0
    static let stringKeyMedium: CGFloat = 16.0
    static let stringKeySmall: CGFloat = 8.0
    static let imageLarge: CGFloat = 32.0
    static let imageMedium: CGFloat = 14.0
    static let overlayLarge: CGFloat = 26.0
    static let overlayMedium: CGFloat = 20.0
}
