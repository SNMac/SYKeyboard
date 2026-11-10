//
//  SplitKeyboardLayoutTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 11/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore
@testable import HangeulKeyboardCore
@testable import EnglishKeyboardCore

/// 분할 자판 배치. 분할 조건·열 수 진리표는 `KeyboardSplitLayoutPolicyTests`가 갖고,
/// 여기서는 각 자판 뷰가 그 배치를 실제로 그리는지와 평소 배치로 되돌아오는지만 본다
@MainActor
@Suite("분할 자판 레이아웃")
struct SplitKeyboardLayoutTests {
    /// iPhone Duo 안쪽 화면 가로의 키보드 폭
    static let width: CGFloat = 801
    static let height: CGFloat = 236
    /// 분할 간격: 전체의 3/14. 가운데(400.5)에 놓인다
    static let gapMinX: CGFloat = width * 5.5 / 14
    static let gapMaxX: CGFloat = width * 8.5 / 14
    /// @3x 픽셀 반올림 오차보다 크게 잡는다
    static let tolerance: CGFloat = 1.0

    private func layOut<V: UIView & BaseKeyboardLayoutProvider>(_ view: V, split: Bool) -> V {
        view.frame = CGRect(x: 0, y: 0, width: Self.width, height: Self.height)
        view.updateSplitLayout(split)
        view.layoutIfNeeded()

        return view
    }

    private func makeDubeolsik(showsNumberRow: Bool = false) -> DubeolsikKeyboardView {
        let view = DubeolsikKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: true,
            showsNumberRow: showsNumberRow
        )
        view.updateNumberRowHeight(40)

        return view
    }

    private func makeEnglish() -> EnglishKeyboardView {
        EnglishKeyboardView(
            getIsShiftedLetterInput: { false },
            setIsShiftedLetterInput: { _ in },
            showsLanguageSwitchButton: false,
            showsNumberRow: false
        )
    }

    /// 화면에 보이는 버튼 중 글자가 `key`인 버튼의 터치 영역
    private func visibleFrames(of key: String, in view: UIView & BaseKeyboardLayoutProvider) -> [CGRect] {
        view.primaryButtonList
            .compactMap { $0 as? TextInteractable & UIView }
            .filter { !$0.isHidden && $0.type.primaryKeyList == [key] && $0.bounds.width > 0 }
            .map { $0.convert($0.bounds, to: view) }
            .sorted { $0.minX < $1.minX }
    }

    /// 보이는 버튼 중 간격 안에 걸친 것. 분할 자판에서는 하나도 없어야 한다
    private func buttonsInGap(_ view: UIView & BaseKeyboardLayoutProvider) -> [CGRect] {
        view.allButtonList
            .filter { !$0.isHidden && $0.bounds.width > 0 }
            .map { $0.convert($0.bounds, to: view) }
            .filter { $0.maxX > Self.gapMinX + Self.tolerance && $0.minX < Self.gapMaxX - Self.tolerance }
    }

    // MARK: - 표준 자판

    @Test("두벌식 분할: 가운데가 비고 ㅎ·ㅍ·스페이스가 양쪽 반쪽에 하나씩")
    func test두벌식_분할() throws {
        let view = layOut(makeDubeolsik(showsNumberRow: true), split: true)

        #expect(buttonsInGap(view).isEmpty)
        for key in ["ㅎ", "ㅍ", " "] {
            let frames = visibleFrames(of: key, in: view)
            try #require(frames.count == 2, "\(key)")
            #expect(frames[0].maxX <= Self.gapMinX + Self.tolerance)
            #expect(frames[1].minX >= Self.gapMaxX - Self.tolerance)
        }
        // 한 열은 안쪽 화면 가로에서 iOS 기본 키보드 키 간격과 같은 801/14
        let column = try #require(visibleFrames(of: "ㅂ", in: view).first)
        #expect(abs(column.width - Self.width / 14) < Self.tolerance)
    }

    @Test("두벌식 분할을 끄면 평소 10열 배치로 돌아오고 복제 키가 사라짐")
    func test두벌식_분할해제() throws {
        let view = layOut(makeDubeolsik(showsNumberRow: true), split: true)
        _ = layOut(view, split: false)

        #expect(visibleFrames(of: "ㅎ", in: view).count == 1)
        #expect(visibleFrames(of: " ", in: view).count == 1)
        let column = try #require(visibleFrames(of: "ㅂ", in: view).first)
        #expect(abs(column.width - Self.width / 10) < Self.tolerance)
    }

    @Test("shift를 바꿔도 분할하지 않은 동안 복제 키는 숨겨진 채로 남음")
    func test영문_shift후_복제키숨김() {
        let view = layOut(makeEnglish(), split: false)
        view.isShifted = true
        view.layoutIfNeeded()

        #expect(visibleFrames(of: "G", in: view).count == 1)
        #expect(visibleFrames(of: "V", in: view).count == 1)
    }

    @Test("스페이스가 없는 URL 자판은 분할해도 왼쪽 반쪽에 스페이스를 만들지 않음")
    func test영문URL_분할() {
        let view = makeEnglish()
        view.currentEnglishKeyboardMode = .URL
        _ = layOut(view, split: true)

        #expect(visibleFrames(of: " ", in: view).isEmpty)
        #expect(buttonsInGap(view).isEmpty)
        // 오른쪽 반쪽은 '.', '/', '.com', 리턴이 채운다
        let period = visibleFrames(of: ".", in: view)
        #expect(period.count == 1)
        #expect((period.first?.minX ?? 0) >= Self.gapMaxX - Self.tolerance)
    }

    // MARK: - 기호 자판

    @Test("기호 자판 분할: '?'가 양쪽에 하나씩이고 셋째 줄 양 끝 키가 터치 영역 안에 그려짐")
    func test기호_분할() throws {
        let view = layOut(SymbolKeyboardView(showsLanguageSwitchButton: true), split: true)

        #expect(buttonsInGap(view).isEmpty)
        #expect(visibleFrames(of: "?", in: view).count == 2)
        for button in view.thirdRowPrimaryKeyButtonList + [view.thirdRowSplitDuplicateButton] {
            let visual = button.backgroundView.convert(button.backgroundView.bounds, to: button)
            #expect(visual.minX >= 0 && visual.maxX <= button.bounds.width + 0.01,
                    "\(button.type.primaryKeyList) 그려지는 키가 터치 영역 밖으로 나감")
        }
    }

    // MARK: - 4열 격자

    @Test("천지인·나랏글 분할: 2열과 3열 사이가 표준 자판과 같은 자리로 비고 네 열이 등폭",
          arguments: [true, false])
    func test4열격자_분할(isCheonjiin: Bool) throws {
        let view: UIView & BaseKeyboardLayoutProvider = isCheonjiin
        ? CheonjiinKeyboardView(showsLanguageSwitchButton: true, usesBottomSpaceLayout: false, showsNumberRow: false)
        : NaratgeulKeyboardView(showsLanguageSwitchButton: true, showsNumberRow: false)
        // 배율이 커도 분할 중에는 등폭이라 간격이 가운데에 남는다
        (view as? NormalKeyboardLayoutProvider)?.updateLetterColumnWidthMultiplier(1.15)
        _ = layOut(view, split: true)

        #expect(buttonsInGap(view).isEmpty)
        let deleteFrame = view.deleteButton.convert(view.deleteButton.bounds, to: view)
        #expect(abs(deleteFrame.width - (Self.width - Self.width * 3 / 14) / 4) < Self.tolerance)
        #expect(abs(deleteFrame.maxX - Self.width) < Self.tolerance)
    }

    // MARK: - 숫자 패드·자동완성 바

    @Test("텐키는 나누지 않고 오른쪽 반쪽으로 옮겨 감")
    func test텐키_오른쪽반쪽() {
        let view = layOut(TenkeyKeyboardView(), split: true)
        let frames = view.allButtonList.filter { !$0.isHidden }.map { $0.convert($0.bounds, to: view) }

        #expect(!frames.isEmpty)
        #expect(frames.allSatisfy { $0.minX >= Self.gapMaxX - Self.tolerance })
        #expect(abs((frames.map(\.maxX).max() ?? 0) - Self.width) < Self.tolerance)
    }

    @Test("자동완성 바는 분할하면 오른쪽 반쪽 위로 줄고 끄면 전체 폭으로 돌아옴")
    func test자동완성바_오른쪽반쪽() throws {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        bar.frame = CGRect(x: 0, y: 0, width: Self.width, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["오늘", "날씨", "좋다"])
        bar.updateSplitLayout(true)
        bar.layoutIfNeeded()

        let splitButtons = typedSuggestionButtonViews(in: bar).map { $0.convert($0.bounds, to: bar) }
        try #require(splitButtons.count == 3)
        #expect(splitButtons.allSatisfy { $0.minX >= Self.gapMaxX - Self.tolerance })

        bar.updateSplitLayout(false)
        bar.layoutIfNeeded()
        let fullButtons = typedSuggestionButtonViews(in: bar).map { $0.convert($0.bounds, to: bar) }
        #expect((fullButtons.first?.minX ?? .infinity) < Self.gapMinX)
    }
}
