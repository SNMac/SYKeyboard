//
//  ClipboardHistoryPanelViewTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import UIKit
import Testing

@testable import SYKeyboardCore

@Suite("클립보드 기록 패널 편집 동작 검증")
@MainActor
struct ClipboardHistoryPanelViewTests {

    @Test("행 탭은 해당 인덱스의 붙여넣기를 요청")
    func test행탭은_인덱스전달() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(spy.selectedIndices == [1])
    }

    @Test("편집 모드에서 행 탭은 선택만 하고 붙여넣기를 요청하지 않음")
    func test편집모드행탭은_붙여넣기요청없음() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(panel.tableView.isEditing)
        #expect(spy.selectedIndices.isEmpty)
    }

    @Test("편집 모드에서 전체 선택 후 삭제하면 전체 삭제를 요청")
    func test전체선택후삭제는_전체삭제요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.toggleSelectAll()
        panel.deleteSelectedItems()

        #expect(spy.deleteAllCount == 1)
        #expect(spy.deletedIndices.isEmpty)
    }

    @Test("편집 모드에서 일부 선택 후 삭제하면 선택 인덱스만 오름차순으로 요청")
    func test일부선택후삭제는_선택인덱스만요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
        panel.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices == [[0, 2]])
        #expect(spy.deleteAllCount == 0)
    }

    @Test("고정 항목이 섞인 삭제는 확인 전에는 요청하지 않고, 확인하면 요청")
    func test고정포함삭제는_확인후요청() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])

        panel.requestDelete(at: [0, 1], deleteAll: true)
        #expect(spy.deleteAllCount == 0)
        #expect(spy.deletedIndices.isEmpty)

        panel.confirmPendingDeletion()
        #expect(spy.deleteAllCount == 1)
    }

    @Test("고정 항목이 섞인 삭제를 취소하면 요청하지 않고 다시 확인해도 없음")
    func test고정포함삭제_취소하면_요청없음() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])

        panel.requestDelete(at: [0], deleteAll: false)
        panel.cancelPendingDeletion()
        panel.confirmPendingDeletion()

        #expect(spy.deletedIndices.isEmpty)
        #expect(spy.deleteAllCount == 0)
    }

    @Test("미고정만 삭제하면 확인 없이 바로 요청")
    func test미고정만삭제는_바로요청() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])

        panel.requestDelete(at: [1], deleteAll: false)

        #expect(spy.deletedIndices == [[1]])
    }

    @Test("스와이프로 tableView가 편집 상태여도 configure 뒤 편집 모드로 들어가지 않음")
    func test스와이프중configure는_편집모드로바뀌지않음() {
        let (panel, spy) = makePanel(texts: ["a", "b"])

        // UIKit은 스와이프 액션이 열려 있는 동안 tableView.isEditing을 true로 둔다
        panel.tableView.setEditing(true, animated: false)
        panel.configure(state: .items([unpinned("a")]))
        panel.deleteSelectedItems()

        #expect(panel.isItemEditing == false)
        #expect(spy.deletedIndices.isEmpty)
    }

    @Test("선택이 없으면 삭제를 요청하지 않음")
    func test선택없으면_삭제요청없음() {
        let (panel, spy) = makePanel(texts: ["a"])

        panel.beginItemEditing()
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices.isEmpty)
        #expect(spy.deleteAllCount == 0)
    }

    @Test("항목이 없으면 편집 모드로 들어가지 않음")
    func test항목없으면_편집모드진입없음() {
        let (panel, _) = makePanel(texts: [])
        panel.configure(state: .empty)

        panel.beginItemEditing()

        #expect(panel.tableView.isEditing == false)
    }

    @Test("leading swipe는 고정 여부와 무관하게 고정 토글 액션 하나를 제공")
    func testLeadingSwipe는_고정토글액션제공() {
        let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        panel.configure(state: .items([
            ClipboardHistoryItem(text: "p", createdAt: Date(), pinnedAt: Date()),
            ClipboardHistoryItem(text: "a", createdAt: Date())
        ]))
        panel.layoutIfNeeded()

        let pinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let unpinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 0))

        #expect(pinnedActions?.actions.count == 1)
        #expect(unpinnedActions?.actions.count == 1)
    }

    @Test("고정 한도가 차면 미고정 행에는 leading swipe가 없고 고정 행에는 있음")
    func test고정한도차면_미고정행은_leadingSwipe없음() {
        let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let pinned = (0..<ClipboardHistoryPolicy.maxPinnedCount).map {
            ClipboardHistoryItem(text: "p\($0)", createdAt: Date(), pinnedAt: Date(timeIntervalSince1970: TimeInterval($0)))
        }
        panel.configure(state: .items(pinned + [ClipboardHistoryItem(text: "a", createdAt: Date())]))
        panel.layoutIfNeeded()

        let pinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let unpinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: pinned.count, section: 0))

        #expect(pinnedActions?.actions.count == 1)
        #expect(unpinnedActions == nil)
    }

    @Test("다시 configure하면 남은 행 수와 인덱스가 새 목록을 따름")
    func test다시configure하면_행수와인덱스가새목록기준() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.configure(state: .items(["b", "c"].map { ClipboardHistoryItem(text: $0, createdAt: Date()) }))
        panel.layoutIfNeeded()
        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
        #expect(spy.selectedIndices == [0])
        #expect(panel.items[0].text == "b")
    }

    @Test("resetPresentation은 편집 모드를 해제")
    func testResetPresentation은_편집모드해제() {
        let (panel, _) = makePanel(texts: ["a"])
        panel.beginItemEditing()

        panel.resetPresentation()

        #expect(panel.tableView.isEditing == false)
    }
}

@MainActor
private func makePanel(texts: [String]) -> (ClipboardHistoryPanelView, ClipboardHistoryPanelDelegateSpy) {
    makePanel(items: texts.map(unpinned))
}

@MainActor
private func makePanel(items: [ClipboardHistoryItem]) -> (ClipboardHistoryPanelView, ClipboardHistoryPanelDelegateSpy) {
    let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let spy = ClipboardHistoryPanelDelegateSpy()
    panel.delegate = spy
    panel.configure(state: items.isEmpty ? .empty : .items(items))
    panel.layoutIfNeeded()
    return (panel, spy)
}

private func unpinned(_ text: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(text: text, createdAt: Date())
}

private func pinned(_ text: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(text: text, createdAt: Date(), pinnedAt: Date())
}

@MainActor
private final class ClipboardHistoryPanelDelegateSpy: ClipboardHistoryPanelDelegate {
    private(set) var selectedIndices: [Int] = []
    private(set) var deletedIndices: [[Int]] = []
    private(set) var deleteAllCount = 0
    private(set) var toggledPinIndices: [Int] = []
    private(set) var copiedIndices: [Int] = []

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        selectedIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        deletedIndices.append(indices)
    }

    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        deleteAllCount += 1
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int) {
        toggledPinIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestCopyAt index: Int) {
        copiedIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestOpenURLAt index: Int) {}
}
