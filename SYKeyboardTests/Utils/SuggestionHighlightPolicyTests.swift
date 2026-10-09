import Testing
import CoreFoundation

@testable import SYKeyboardCore

@Suite("자동완성 divider 개수 정책 검증")
struct SuggestionDividerPolicyTests {

    @Test("후보가 열 격자를 채우지 못해도 divider는 3칸 격자를 따름")
    func test후보가열격자를채우지못해도_divider는3칸격자를따름() {
        // 빈 칸에 divider가 없으면 그 자리를 눌렀을 때 앞 후보가 적용될 것처럼 보인다
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 0) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 1) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 2) == 2)
    }

    @Test("후보가 열 격자를 채우면 후보 사이에만 divider를 둠")
    func test후보가열격자를채우면_후보사이에만divider를둠() {
        // 맨 앞과 맨 뒤에는 divider를 두지 않는다
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 3) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 10) == 9)
    }

    @Test("하이라이트된 후보·기능 버튼에 붙은 divider만 지우되, 경계 divider는 인접한 후보가 뷰포트 안에 보일 때만 지움",
          arguments: [
            // (suggestion, action, suggestionCount, isVisible, cleared)
            // 하이라이트된 후보 양옆 divider를 지우고, 첫·마지막 후보면 경계 divider도 지움
            (Int?.some(1), Int?.none, 3, true,
             SuggestionDividerPolicy.ClearedDividers(leadingBoundary: false, trailingBoundary: false, undoRedoMiddle: false, pooled: [0, 1])),
            (0, nil, 3, true,
             .init(leadingBoundary: true, trailingBoundary: false, undoRedoMiddle: false, pooled: [0])),
            (2, nil, 3, true,
             .init(leadingBoundary: false, trailingBoundary: true, undoRedoMiddle: false, pooled: [1, 2])),
            (9, nil, 10, true,
             .init(leadingBoundary: false, trailingBoundary: true, undoRedoMiddle: false, pooled: [8, 9])),
            // 후보가 3칸을 채우지 못하면 마지막 후보는 오른쪽 끝 divider와 인접하지 않음.
            // 후보 1개: 0번 열이라 왼쪽 경계만 지운다
            (0, nil, 1, true,
             .init(leadingBoundary: true, trailingBoundary: false, undoRedoMiddle: false, pooled: [0])),
            (1, nil, 2, true,
             .init(leadingBoundary: false, trailingBoundary: false, undoRedoMiddle: false, pooled: [0, 1])),
            // 뷰포트 밖에 나간 후보는 경계 divider를 지우지 않지만 후보 사이 divider는 지움
            (9, nil, 10, false,
             .init(leadingBoundary: false, trailingBoundary: false, undoRedoMiddle: false, pooled: [8, 9])),
            (0, nil, 10, false,
             .init(leadingBoundary: false, trailingBoundary: false, undoRedoMiddle: false, pooled: [0])),
            // 기능 버튼이 눌리면 그 버튼에 붙은 divider만 지움
            (nil, 0, 3, true,
             .init(leadingBoundary: true, trailingBoundary: false, undoRedoMiddle: false, pooled: [])),
            (nil, 1, 3, true,
             .init(leadingBoundary: false, trailingBoundary: true, undoRedoMiddle: true, pooled: [])),
            (nil, 2, 3, true,
             .init(leadingBoundary: false, trailingBoundary: false, undoRedoMiddle: true, pooled: [])),
            (nil, nil, 3, true, .init())
          ])
    func test하이라이트에따라지울divider(
        suggestion: Int?,
        action: Int?,
        suggestionCount: Int,
        isVisible: Bool,
        cleared: SuggestionDividerPolicy.ClearedDividers
    ) {
        #expect(
            SuggestionDividerPolicy.clearedDividers(
                highlight: .init(highlightedSuggestionIndex: suggestion, highlightedActionIndex: action),
                isHighlightedSuggestionVisible: isVisible,
                suggestionCount: suggestionCount
            ) == cleared
        )
    }
}

@Suite("자동완성 highlight 정책 검증")
struct SuggestionHighlightPolicyTests {

    @Test("touch 중인 후보·기능 버튼이 preview보다 우선하고, nil이거나 범위 밖 index는 강조하지 않음",
          arguments: [
            // (preview, touchedSuggestion, touchedAction, suggestionCount, actionCount, state)
            // preview는 해당 후보만 강조
            (Int?.some(1), Int?.none, Int?.none, 3, 2,
             SuggestionHighlightPolicy.State(highlightedSuggestionIndex: 1, highlightedActionIndex: nil)),
            // 후보 touch는 preview를 일시 대체한다. touch가 끝나 touched가 nil로 돌아가면 위 preview 행과 같은 입력이라 preview가 복원된다
            (1, 2, nil, 3, 2, .init(highlightedSuggestionIndex: 2, highlightedActionIndex: nil)),
            // action touch는 preview를 가리고 action만 강조
            (1, nil, 0, 3, 2, .init(highlightedSuggestionIndex: nil, highlightedActionIndex: 0)),
            // nil과 범위 밖 index는 강조하지 않음
            (nil, nil, nil, 3, 2, .none),
            (3, -1, 2, 3, 2, .none),
            // 후보가 10개면 9번 후보도 하이라이트 대상
            (nil, 9, nil, 10, 3, .init(highlightedSuggestionIndex: 9, highlightedActionIndex: nil)),
            // 후보 수가 줄면 범위를 벗어난 preview 하이라이트는 무시
            (9, nil, nil, 3, 3, .none)
          ])
    func testResolve(
        preview: Int?,
        touchedSuggestion: Int?,
        touchedAction: Int?,
        suggestionCount: Int,
        actionCount: Int,
        state: SuggestionHighlightPolicy.State
    ) {
        #expect(
            SuggestionHighlightPolicy.resolve(
                previewSuggestionIndex: preview,
                touchedSuggestionIndex: touchedSuggestion,
                touchedActionIndex: touchedAction,
                suggestionCount: suggestionCount,
                actionCount: actionCount
            ) == state
        )
    }
}
