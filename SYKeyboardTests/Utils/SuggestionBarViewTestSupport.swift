//
//  SuggestionBarViewTestSupport.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/22/26.
//

import UIKit

@testable import SYKeyboardCore

/// bar 안의 후보 버튼을 화면 왼쪽부터 돌려준다
func typedSuggestionButtonViews(in view: UIView) -> [SuggestionButtonView] {
    var result: [SuggestionButtonView] = []
    for subview in view.subviews {
        if let button = subview as? SuggestionButtonView {
            result.append(button)
        }
        result.append(contentsOf: typedSuggestionButtonViews(in: subview))
    }
    return result.sorted {
        $0.convert($0.bounds, to: view).minX
            < $1.convert($1.bounds, to: view).minX
    }
}

/// bar 좌표계에서 본 버튼 중심. 터치 위치로 쓴다
func center(of button: UIView, in bar: UIView) -> CGPoint {
    let frame = button.convert(button.bounds, to: bar)
    return CGPoint(x: frame.midX, y: frame.midY)
}

/// bar가 delegate로 알린 선택·삭제 요청·기능 버튼 탭을 기록한다
@MainActor
final class SuggestionBarDelegateSpy: SuggestionBarDelegate {
    private let acceptsRemoval: Bool
    private(set) var removalRequestIndexes: [Int] = []
    private(set) var selectedIndexes: [Int] = []
    private(set) var undoTapCount = 0
    private(set) var clipboardTapCount = 0

    init(acceptsRemoval: Bool = false) {
        self.acceptsRemoval = acceptsRemoval
    }

    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        selectedIndexes.append(index)
    }

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        removalRequestIndexes.append(index)
        return acceptsRemoval
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {
        undoTapCount += 1
    }

    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}

    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {
        clipboardTapCount += 1
    }
}
