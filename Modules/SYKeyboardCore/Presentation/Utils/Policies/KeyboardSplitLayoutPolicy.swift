//
//  KeyboardSplitLayoutPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 11/8/26.
//

import CoreFoundation

/// 분할 자판을 쓸지와 분할 자판의 열 배치를 정한다.
///
/// 분할 자판은 자판을 좌우 반쪽으로 나누고 가운데를 비운 배치다.
/// iPhone Duo를 반쯤 펼친 상태에서 안쪽 화면이 가로일 때 쓴다(iOS 기본 키보드와 같음).
///
/// 열 배치는 표준 자판(10열)을 기준으로 한 열 단위로 잰다.
/// 반쪽은 5.5열, 가운데 간격은 3열이라 분할 자판 전체는 14열이다.
/// 안쪽 화면 가로(801pt)에서 한 열이 약 57pt로 iOS 기본 키보드의 키 간격과 같다
public enum KeyboardSplitLayoutPolicy {

    /// 기기의 접힘 상태. iOS 27.1+ `UIHinge.Status`를 버전과 무관하게 다루려고 옮겨 둔 값이다
    public enum FoldState: Equatable, Sendable {
        case unknown
        case closed
        case partiallyOpen
        case fullyOpen
    }

    // MARK: - 분할 조건

    /// 분할 조건을 충족하는지.
    ///
    /// 반쯤 펼친 상태에서 화면이 가로일 때만 충족한다. 반쯤 펼친 세로(접히는 선이 가로로
    /// 지나가는 자세)는 iOS 기본 키보드도 나누지 않고 높이만 키운다.
    /// 나중에 iPad 가로 분할 설정이 생기면 그 값도 같은 자리(`usesSplitLayout`의 입력)로 들어온다
    static func isSplitConditionMet(foldState: FoldState, isLandscape: Bool) -> Bool {
        return foldState == .partiallyOpen && isLandscape
    }

    /// 분할 자판을 쓸지. 한 손 모드가 켜져 있으면 사용자가 고른 한 손 키보드를 그대로 둔다.
    ///
    /// 한 손 키보드 설정이 꺼져 있으면 마지막으로 쓴 한 손 모드가 남아 있어도 한 손 모드가 아니다
    static func usesSplitLayout(
        isSplitConditionMet: Bool,
        isOneHandedKeyboardEnabled: Bool,
        oneHandedMode: OneHandedMode
    ) -> Bool {
        guard isSplitConditionMet else { return false }
        return !isOneHandedKeyboardEnabled || oneHandedMode == .center
    }

    // MARK: - 열 배치

    /// 반쪽 하나의 열 수
    static let halfColumnCount: CGFloat = 5.5
    /// 가운데 간격의 열 수
    static let gapColumnCount: CGFloat = 3
    /// 분할 자판 전체 열 수
    static var totalColumnCount: CGFloat { halfColumnCount * 2 + gapColumnCount }

    /// 가장자리 키로 시작하는 줄(표준 자판 첫 줄, 숫자 행, 기호 자판 첫·둘째 줄)의 간격 열 수.
    ///
    /// 둘째 줄은 반 열 들여 시작하고 경계 키를 양쪽에 하나씩 둬서 반쪽 5.5열을 채운다.
    /// 첫 줄은 5열뿐이라 남는 반 열씩을 간격 쪽에 붙여 가장자리를 둘째 줄과 맞춘다
    static var edgeAlignedRowGapColumnCount: CGFloat { gapColumnCount + 1 }

    /// 반쪽 하나가 전체 폭에서 차지하는 비율. 텐키와 자동완성 바를 오른쪽 반쪽에 둘 때 쓴다
    static var halfWidthRatio: CGFloat { halfColumnCount / totalColumnCount }

    /// 같은 폭의 열 `columnCount`개를 둘로 나눌 때 간격이 열 하나의 몇 배인지.
    ///
    /// 간격 폭을 표준 자판과 같게(전체 폭의 3/14) 맞춘다. 4열 격자는 12/11, 10열 숫자 행은 30/11이다.
    /// 자판을 바꿔도 가운데 간격이 같은 자리에 같은 폭으로 남는다
    static func gapToColumnRatio(columnCount: Int) -> CGFloat {
        return CGFloat(columnCount) * gapColumnCount / (totalColumnCount - gapColumnCount)
    }

    /// 기호 자판 셋째 줄 키('.', ',', '?', '!', '’')의 폭 배율(표준 자판 한 열 기준).
    ///
    /// 분할하면 반쪽에 shift와 키 셋이 들어가야 해서 평소(1.4)보다 좁힌다. 1.4를 그대로 쓰면
    /// 양 끝 키의 터치 영역(1.35열)이 그려지는 키보다 좁아진다
    static func symbolThirdRowButtonWidthMultiplier(usesSplitLayout: Bool) -> CGFloat {
        return usesSplitLayout ? 1.3 : KeyboardLayoutFigure.symbolThirdRowButtonWidthMultiplier
    }
}
