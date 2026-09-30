// MARK: - SuggestionDividerPolicy

/// 후보 사이 divider 개수를 정하는 정책
enum SuggestionDividerPolicy {

    /// 화면에 한 번에 보이는 후보 칸 수
    static let visibleColumnCount = 3

    /// 후보 `count`개를 그릴 때 필요한 divider 개수.
    ///
    /// 후보가 3개보다 적어도 후보 영역은 3칸으로 보여야 한다. 빈 칸에 divider가 없으면 그 자리를
    /// 눌렀을 때 앞 후보가 적용될 것처럼 보인다. 맨 앞과 맨 뒤에는 그리지 않는다
    static func dividerCount(forSuggestionCount count: Int) -> Int {
        return max(count, visibleColumnCount) - 1
    }

    /// 하이라이트된 버튼과 인접해 지울 divider. 어느 쪽 끝 후보를 누르고 있는지 구분되게 하려는 것이다
    struct ClearedDividers: Equatable {
        /// 클립보드 버튼과 후보 영역 사이
        var leadingBoundary = false
        /// 후보 영역과 undo 버튼 사이
        var trailingBoundary = false
        /// undo와 redo 사이
        var undoRedoMiddle = false
        /// 후보 사이. `i`는 `i`번과 `i+1`번 후보 사이 divider
        var pooled: Set<Int> = []
    }

    /// 하이라이트 상태에서 지울 divider를 정한다.
    ///
    /// 경계 divider는 첫 후보·마지막 후보가 하이라이트될 때만 지운다. 다만 후보가 3칸을 채우지 못하면
    /// 마지막 후보는 오른쪽 끝 divider와 인접하지 않으므로 경계 판정에 쓰지 않는다.
    /// 스크롤로 뷰포트 밖에 나간 후보 때문에 보이지도 않는 경계 divider가 사라지지 않도록
    /// `isHighlightedSuggestionVisible`이 `false`면 경계 divider는 남긴다.
    /// action 인덱스는 `SuggestionHighlightPolicy`와 같다(0 클립보드, 1 undo, 2 redo)
    static func clearedDividers(
        highlight: SuggestionHighlightPolicy.State,
        isHighlightedSuggestionVisible: Bool,
        suggestionCount: Int
    ) -> ClearedDividers {
        var cleared = ClearedDividers()

        if let index = highlight.highlightedSuggestionIndex {
            let isLast = index == suggestionCount - 1 && suggestionCount >= visibleColumnCount
            cleared.leadingBoundary = index == 0 && isHighlightedSuggestionVisible
            cleared.trailingBoundary = isLast && isHighlightedSuggestionVisible
            cleared.pooled = Set([index - 1, index].filter { $0 >= 0 })
        }

        switch highlight.highlightedActionIndex {
        case 0:
            cleared.leadingBoundary = true
        case 1:
            cleared.trailingBoundary = true
            cleared.undoRedoMiddle = true
        case 2:
            cleared.undoRedoMiddle = true
        default:
            break
        }

        return cleared
    }
}

// MARK: - SuggestionHighlightPolicy

enum SuggestionHighlightPolicy {

    struct State: Equatable {
        let highlightedSuggestionIndex: Int?
        let highlightedActionIndex: Int?

        static let none = State(
            highlightedSuggestionIndex: nil,
            highlightedActionIndex: nil
        )
    }

    static func resolve(
        previewSuggestionIndex: Int?,
        touchedSuggestionIndex: Int?,
        touchedActionIndex: Int?,
        suggestionCount: Int,
        actionCount: Int
    ) -> State {
        if let touchedSuggestionIndex,
           (0..<suggestionCount).contains(touchedSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: touchedSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        if let touchedActionIndex,
           (0..<actionCount).contains(touchedActionIndex) {
            return State(
                highlightedSuggestionIndex: nil,
                highlightedActionIndex: touchedActionIndex
            )
        }

        if let previewSuggestionIndex,
           (0..<suggestionCount).contains(previewSuggestionIndex) {
            return State(
                highlightedSuggestionIndex: previewSuggestionIndex,
                highlightedActionIndex: nil
            )
        }

        return .none
    }
}
