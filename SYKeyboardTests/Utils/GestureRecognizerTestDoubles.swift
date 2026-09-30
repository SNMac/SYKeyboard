//
//  GestureRecognizerTestDoubles.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import UIKit

// Xcode Cloud의 x86_64 simulator에서는 UIGestureRecognizer.state 직접 대입이
// handler 호출 시점까지 안정적으로 유지되지 않아 종료 상태를 테스트 더블로 고정한다.
final class TestPanGestureRecognizer: UIPanGestureRecognizer {
    private var forcedState: UIGestureRecognizer.State
    var location: CGPoint = .zero

    init(state: UIGestureRecognizer.State = .possible) {
        self.forcedState = state
        super.init(target: nil, action: nil)
    }

    override var state: UIGestureRecognizer.State {
        get { forcedState }
        set { forcedState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        location
    }
}

final class TestLongPressGestureRecognizer: UILongPressGestureRecognizer {
    private var forcedState: UIGestureRecognizer.State

    init(state: UIGestureRecognizer.State = .possible) {
        self.forcedState = state
        super.init(target: nil, action: nil)
    }

    override var state: UIGestureRecognizer.State {
        get { forcedState }
        set { forcedState = newValue }
    }
}
