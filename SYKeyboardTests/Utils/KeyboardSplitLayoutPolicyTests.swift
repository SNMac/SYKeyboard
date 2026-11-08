//
//  KeyboardSplitLayoutPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/8/26.
//

import CoreFoundation
import Testing

@testable import SYKeyboardCore

@Suite("분할 자판 정책")
struct KeyboardSplitLayoutPolicyTests {
    private static let tolerance: CGFloat = 0.0001

    // MARK: - 분할 조건

    @Test("분할 조건은 반쯤 펼친 가로에서만 충족",
          arguments: [
            (KeyboardSplitLayoutPolicy.FoldState.partiallyOpen, true, true),
            (.partiallyOpen, false, false),
            (.fullyOpen, true, false),
            (.fullyOpen, false, false),
            (.closed, true, false),
            (.closed, false, false),
            (.unknown, true, false),
            (.unknown, false, false)
          ])
    func test분할조건(foldState: KeyboardSplitLayoutPolicy.FoldState, isLandscape: Bool, expected: Bool) {
        #expect(KeyboardSplitLayoutPolicy.isSplitConditionMet(foldState: foldState, isLandscape: isLandscape) == expected)
    }

    @Test("한 손 모드가 켜져 있으면 분할 조건을 충족해도 나누지 않음",
          arguments: [
            (true, OneHandedMode.center, true),
            (true, .left, false),
            (true, .right, false),
            (false, .center, false),
            (false, .left, false)
          ])
    func test분할여부_한손모드(isSplitConditionMet: Bool, oneHandedMode: OneHandedMode, expected: Bool) {
        #expect(KeyboardSplitLayoutPolicy.usesSplitLayout(
            isSplitConditionMet: isSplitConditionMet,
            oneHandedMode: oneHandedMode
        ) == expected)
    }

    // MARK: - 열 배치

    @Test("분할 자판은 반쪽 5.5열 + 간격 3열 = 14열이고 반쪽은 전체의 5.5/14")
    func test열수() {
        #expect(KeyboardSplitLayoutPolicy.totalColumnCount == 14)
        #expect(abs(KeyboardSplitLayoutPolicy.halfWidthRatio - 5.5 / 14) < Self.tolerance)
        // 가장자리 키로 시작하는 줄은 간격 양쪽에 반 열씩 더 비운다
        #expect(KeyboardSplitLayoutPolicy.edgeAlignedRowGapColumnCount == 4)
    }

    @Test("4열 격자와 10열 숫자 행의 간격 폭이 표준 자판 간격(전체의 3/14)과 같음",
          arguments: [4, 10])
    func test간격폭_자판간일치(columnCount: Int) {
        let rowWidth: CGFloat = 801
        let ratio = KeyboardSplitLayoutPolicy.gapToColumnRatio(columnCount: columnCount)
        // 열 n개 + 간격(열 폭 × ratio)이 행 폭을 채운다
        let columnWidth = rowWidth / (CGFloat(columnCount) + ratio)
        let gapWidth = columnWidth * ratio

        #expect(abs(gapWidth - rowWidth * 3 / 14) < Self.tolerance)
    }

    @Test("안쪽 화면 가로(801pt)에서 한 열은 iOS 기본 키보드 키 간격(약 57pt)과 같음")
    func test안쪽화면가로_열폭() {
        let columnWidth = 801 / KeyboardSplitLayoutPolicy.totalColumnCount

        #expect(abs(columnWidth - 57) < 0.5)
    }

    @Test("기호 자판 셋째 줄 키는 분할하면 양 끝 키 터치 영역보다 좁아짐")
    func test기호셋째줄배율() {
        let normal = KeyboardSplitLayoutPolicy.symbolThirdRowButtonWidthMultiplier(usesSplitLayout: false)
        let split = KeyboardSplitLayoutPolicy.symbolThirdRowButtonWidthMultiplier(usesSplitLayout: true)
        // 반쪽 5.5열 = shift(1.35) + 양 끝 키 + 가운데 키 둘
        let edgeKeyWidth = KeyboardSplitLayoutPolicy.halfColumnCount
        - KeyboardLayoutFigure.shiftAndDeleteButtonWidthMultiplier - split * 2

        #expect(normal == KeyboardLayoutFigure.symbolThirdRowButtonWidthMultiplier)
        #expect(edgeKeyWidth >= split)
    }
}
