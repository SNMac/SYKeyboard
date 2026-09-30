//
//  CursorDragAccelerationPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/4/26.
//

import CoreGraphics
import Testing

@testable import SYKeyboardCore

@Suite("커서 드래그 가속 정책 검증")
struct CursorDragAccelerationPolicyTests {

    @Test("느린 드래그는 cursorMoveInterval마다 1칸 이동")
    func test느린드래그_기본간격_1칸이동() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 25,
            previousVelocity: 20,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 1)
        #expect(result?.velocity == 25)
    }

    @Test("한 업데이트에서 여러 interval이 누적되면 기본 tick이 여러 칸이 됨")
    func test여러Interval누적_기본Tick반영() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: -12,
            velocity: 60,
            previousVelocity: 55,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .left)
        #expect(result?.steps == 2)
    }

    @Test("커서 활성화 첫 이동은 활성화 누적 거리를 가속 step으로 사용하지 않음")
    func test커서활성화_첫이동_1칸() {
        let result = CursorDragAccelerationPolicy.initialMovement(
            deltaX: 40,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 1)
        #expect(result?.velocity == 0)
    }

    @Test("빠른 드래그는 cursorMoveInterval 기본 tick에 속도 보정을 더함")
    func test빠른드래그_속도보정() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 10,
            velocity: 1000,
            previousVelocity: 900,
            cursorMoveInterval: 5
        )

        #expect(result?.direction == .right)
        #expect(result?.steps == 3)
    }

    @Test("속도 보정은 900pt/s에서 +1, 1600pt/s에서 +2로 바뀜",
          arguments: [(899, 1), (900, 2), (1599, 2), (1600, 3)])
    func test속도보정_경계(velocity: Int, expectedSteps: Int) {
        // 직전 속도를 10pt/s 아래로 두어 가속 보정이 섞이지 않게 한다
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: CGFloat(velocity),
            previousVelocity: CGFloat(velocity - 10),
            cursorMoveInterval: 5
        )

        #expect(result?.steps == expectedSteps)
    }

    @Test("직전 측정보다 900pt/s 이상 빨라지면 가속 보정 +1을 더함",
          arguments: [(101, 2), (100, 3)])
    func test가속보정_경계(previousVelocity: Int, expectedSteps: Int) {
        // 1000pt/s는 fast 보정(+1)만 받는 속도라 차이는 가속 보정에서만 나온다
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 1000,
            previousVelocity: CGFloat(previousVelocity),
            cursorMoveInterval: 5
        )

        #expect(result?.steps == expectedSteps)
    }

    @Test("첫 속도 측정은 가속 증가 보정을 적용하지 않음")
    func test첫속도측정_가속증가보정없음() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 5,
            velocity: 1000,
            previousVelocity: 0,
            cursorMoveInterval: 5
        )

        #expect(result?.steps == 2)
    }

    @Test("가속 구간은 추가 보정을 적용하되 최대 step을 넘지 않음")
    func test가속구간_최대Step제한() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 10,
            velocity: 2000,
            previousVelocity: 1000,
            cursorMoveInterval: 5
        )

        // 기본 2칸 + very fast 2 + 가속 1 = 5칸이 상한 4칸으로 잘린다
        #expect(result?.direction == .right)
        #expect(result?.steps == 4)
    }

    @Test("가장 민감한 interval에서도 최대 step을 넘지 않음")
    func test민감한Interval_최대Step제한() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: 8,
            velocity: 2000,
            previousVelocity: 1000,
            cursorMoveInterval: 1
        )

        #expect(result?.steps == 4)
    }

    @Test("방향 전환 중 interval 미만 이동은 step을 만들지 않음")
    func testInterval미만이동_이동없음() {
        let result = CursorDragAccelerationPolicy.movement(
            deltaX: -4,
            velocity: -1000,
            previousVelocity: 1000,
            cursorMoveInterval: 5
        )

        #expect(result == nil)
    }

    @Test("왼쪽 커서 이동 적용 step은 요청 step과 앞 문맥 길이 중 작은 값")
    func test왼쪽커서이동_적용Step계산() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .left,
            requestedSteps: 4,
            documentContextBeforeInput: "가나",
            documentContextAfterInput: "다라마"
        )

        #expect(steps == 2)
    }

    @Test("오른쪽 커서 이동 적용 step은 요청 step과 뒤 문맥 길이 중 작은 값")
    func test오른쪽커서이동_적용Step계산() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가나다",
            documentContextAfterInput: "라마"
        )

        #expect(steps == 2)
    }

    @Test("오른쪽 문맥이 빈 문자열이면 경계 이동을 위해 1칸 요청")
    func test오른쪽커서이동_빈문맥_1Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가",
            documentContextAfterInput: ""
        )

        #expect(steps == 1)
    }

    @Test("오른쪽 문맥이 nil이면 경계 이동을 위해 1칸 요청")
    func test오른쪽커서이동_nil문맥_1Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .right,
            requestedSteps: 4,
            documentContextBeforeInput: "가",
            documentContextAfterInput: nil
        )

        #expect(steps == 1)
    }

    @Test("커서 이동 적용 step은 nil 문맥이면 0")
    func test커서이동_nil문맥_0Step() {
        let steps = CursorDragAccelerationPolicy.applicableSteps(
            to: .left,
            requestedSteps: 4,
            documentContextBeforeInput: nil,
            documentContextAfterInput: "라마"
        )

        #expect(steps == 0)
    }
}
