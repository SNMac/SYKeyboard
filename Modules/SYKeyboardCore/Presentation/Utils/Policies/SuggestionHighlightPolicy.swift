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
