//
//  KeyboardFrameInsetsPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/1/26.
//

import CoreGraphics
import Testing

@testable import SYKeyboardCore

@Suite("키보드 화면 여백 정책 검증")
struct KeyboardFrameInsetsPolicyTests {

    // iPhone Duo는 세로에서도 양옆을 비우고, 아래 자리도 기본 규칙과 다르다
    @Test("표에 있는 화면은 측정값을 쓴다",
          arguments: [
            // (화면 폭, 화면 높이, 양옆, 아래)
            (466.0, 678.0, 7.0, 32.0),
            (678.0, 466.0, 75.0, 16.0),
            (669.0, 951.0, 7.0, 70.0),
            (951.0, 669.0, 75.0, 16.0),
            (812.0, 375.0, 75.0, 21.0),
            // 소수점 크기는 pt 단위로 반올림해 찾는다
            (466.4, 677.6, 7.0, 32.0)
          ])
    func testMeasuredInsets(width: CGFloat, height: CGFloat, side: CGFloat, bottom: CGFloat) {
        let insets = KeyboardFrameInsetsPolicy.insets(
            screenSize: CGSize(width: width, height: height),
            hasHomeIndicator: true,
            sideSafeAreaInset: 62
        )

        #expect(insets == KeyboardFrameInsetsPolicy.Insets(leading: side, trailing: side, bottom: bottom))
    }

    @Test("표에 없는 화면은 홈 인디케이터 기기만 비우고, 가로 양옆은 설정 앱의 양옆 safe area로 기기 종류를 나눈다",
          arguments: [
            // (화면 폭, 화면 높이, 홈 인디케이터, 양옆 safe area, 양옆, 아래)
            // 노치 기기(iPhone 17e) 가로·세로
            (844.0, 390.0, true, 47.0, 75.0, 20.0),
            (390.0, 844.0, true, 0.0, 0.0, 75.0),
            // Dynamic Island 기기(iPhone Air) 가로. 경계값 55부터 넓게 비운다
            (912.0, 420.0, true, 62.0, 117.0, 20.0),
            (912.0, 420.0, true, 55.0, 117.0, 20.0),
            (912.0, 420.0, true, 54.0, 75.0, 20.0),
            // 홈 버튼 기기(iPhone SE)
            (667.0, 375.0, false, 0.0, 0.0, 0.0),
            (375.0, 667.0, false, 0.0, 0.0, 0.0)
          ])
    func testFallbackInsets(width: CGFloat, height: CGFloat, hasHomeIndicator: Bool,
                            sideSafeArea: CGFloat, side: CGFloat, bottom: CGFloat) {
        let insets = KeyboardFrameInsetsPolicy.insets(
            screenSize: CGSize(width: width, height: height),
            hasHomeIndicator: hasHomeIndicator,
            sideSafeAreaInset: sideSafeArea
        )

        #expect(insets == KeyboardFrameInsetsPolicy.Insets(leading: side, trailing: side, bottom: bottom))
    }
}
