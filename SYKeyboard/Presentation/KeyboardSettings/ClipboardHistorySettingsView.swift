//
//  ClipboardHistorySettingsView.swift
//  SYKeyboard
//
//  Created by Claude on 9/8/26.
//

import SwiftUI

import SYKeyboardCore

/// 키보드 클립보드 패널과 같은 목록을 앱에서 관리하는 화면. 직접 입력한 텍스트를 고정 항목으로 추가할 수 있다
struct ClipboardHistorySettingsView: View {

    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase

    private let store = ClipboardHistoryStore()

    /// 저장 순서 그대로(고정 최신순 → 미고정 최신순). 텍스트는 정책상 중복이 없어 id로 쓴다
    @State private var items: [ClipboardHistoryItem] = []
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive
    @State private var isAddSheetPresented = false
    @State private var newText = ""

    private var canPin: Bool { ClipboardHistoryPolicy.canPin(items) }
    private var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }

    // MARK: - Content

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    Text("복사한 텍스트가 여기에 표시됩니다")
                        .foregroundStyle(.secondary)
                } else {
                    historyList
                }
            }
            .navigationTitle("클립보드 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $isAddSheetPresented) { addSheet }
            .onAppear(perform: reload)
            .onChange(of: scenePhase) { phase in
                if phase == .active { reload() }
            }
            .requestReviewOnDetailSettingsReturn()
        }
    }
}

// MARK: - UI Components

private extension ClipboardHistorySettingsView {
    var historyList: some View {
        List(selection: $selection) {
            ForEach(items, id: \.text) { item in
                NavigationLink {
                    ClipboardHistoryDetailView(text: item.text)
                } label: {
                    row(for: item)
                }
                .swipeActions(edge: .leading) {
                    if item.isPinned || canPin {
                        Button {
                            togglePin(item)
                        } label: {
                            Label(
                                item.isPinned ? "고정 해제" : "고정",
                                systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill"
                            )
                        }
                        .tint(.orange)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        remove([item])
                    } label: {
                        Label("삭제", systemImage: "trash.fill")
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
    }

    func row(for item: ClipboardHistoryItem) -> some View {
        HStack {
            Text(item.text)
                .lineLimit(2)
            if item.isPinned {
                Spacer()
                Image(systemName: "pin.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !items.isEmpty {
                EditButton()
            }
            Button {
                newText = ""
                isAddSheetPresented = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .disabled(!canPin)
        }
        ToolbarItemGroup(placement: .bottomBar) {
            if editMode.isEditing {
                Button(isAllSelected ? "선택 해제" : "전체 선택") {
                    selection = isAllSelected ? [] : Set(items.map(\.text))
                }
                Spacer()
                Button(role: .destructive) {
                    remove(items.filter { selection.contains($0.text) })
                } label: {
                    Text("\(selection.count)개 삭제")
                        .monospacedDigit()
                }
                .disabled(selection.isEmpty)
            }
        }
    }

    var addSheet: some View {
        NavigationStack {
            TextEditor(text: $newText)
                .padding(.horizontal)
                .navigationTitle("고정 항목 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isAddSheetPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") { saveNewItem() }
                            .disabled(!canSaveNewItem)
                    }
                }
        }
    }

    var canSaveNewItem: Bool {
        !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && newText.count <= ClipboardHistoryPolicy.maxTextLength
        && canPin
    }
}

// MARK: - Private Methods

private extension ClipboardHistorySettingsView {
    func reload() {
        items = store?.load() ?? []
        selection = selection.intersection(items.map(\.text))
        if items.isEmpty { editMode = .inactive }
    }

    func togglePin(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.text == item.text }) else { return }
        store?.togglePin(at: index)
        reload()
    }

    func remove(_ removing: [ClipboardHistoryItem]) {
        let texts = Set(removing.map(\.text))
        let indices = items.indices.filter { texts.contains(items[$0].text) }
        guard !indices.isEmpty else { return }
        if indices.count == items.count {
            store?.removeAll()
        } else {
            store?.remove(at: indices)
        }
        reload()
    }

    func saveNewItem() {
        store?.recordPinned(newText)
        isAddSheetPresented = false
        reload()
    }
}

// MARK: - Detail

/// 항목의 원문 전체를 스크롤로 보여주는 화면
private struct ClipboardHistoryDetailView: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("원문")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    ClipboardHistorySettingsView()
}
