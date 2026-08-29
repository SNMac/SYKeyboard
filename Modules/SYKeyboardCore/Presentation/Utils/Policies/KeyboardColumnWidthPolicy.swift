//
//  KeyboardColumnWidthPolicy.swift
//  SYKeyboardCore
//

import CoreFoundation

/// 4열 격자 키보드(나랏글·천지인·숫자 키패드)의 열 너비 비율을 계산한다.
///
/// 모든 반환값은 행 전체 폭 대비 비율이다
enum KeyboardColumnWidthPolicy {

    /// 배율을 허용 범위로 자른다
    static func clamped(_ multiplier: Double) -> Double {
        let range = KeyboardLayoutFigure.letterColumnWidthMultiplierRange
        return min(max(multiplier, range.lowerBound), range.upperBound)
    }

    /// 글자 열 하나가 차지하는 비율
    static func letterColumnRatio(multiplier: Double) -> CGFloat {
        CGFloat(clamped(multiplier)) / CGFloat(KeyboardLayoutFigure.fourColumnCount)
    }

    /// 기능 열(4열)이 차지하는 비율. 글자 열 3개가 쓰고 남은 폭이다
    static func functionColumnRatio(multiplier: Double) -> CGFloat {
        let letterColumnCount = CGFloat(KeyboardLayoutFigure.fourColumnCount - 1)
        return 1.0 - letterColumnCount * letterColumnRatio(multiplier: multiplier)
    }
}
