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
    /// 원문 시트에 표시할 항목
    @State private var detailItem: ClipboardHistoryItem?

    private var canPin: Bool { ClipboardHistoryPolicy.canPin(items) }
    private var pinnedCount: Int { items.filter(\.isPinned).count }
    private var recentCount: Int { items.count - pinnedCount }
    private var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }
    private var selectedItems: [ClipboardHistoryItem] { items.filter { selection.contains($0.text) } }
    /// 선택이 전부 고정이면 해제, 아니면 미고정만 고정한다
    private var isUnpinningSelection: Bool { !selectedItems.isEmpty && selectedItems.allSatisfy(\.isPinned) }
    private var pinTargets: [ClipboardHistoryItem] {
        isUnpinningSelection ? selectedItems : selectedItems.filter { !$0.isPinned }
    }
    private var canPinTargets: Bool {
        !pinTargets.isEmpty
        && (isUnpinningSelection || pinnedCount + pinTargets.count <= ClipboardHistoryPolicy.maxPinnedCount)
    }

    // MARK: - Content

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Text("복사한 텍스트가 여기에 표시됩니다.")
                        limitDescription
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                } else {
                    historyList
                }
            }
            .navigationTitle("클립보드 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            // iOS 16은 bottomBar 항목을 나중에 추가하면 바가 안 뜨므로 항목은 두고 표시만 토글한다
            .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
            // 편집 버튼과 List가 같은 편집 상태를 보도록 toolbar 바깥에 둔다
            .environment(\.editMode, $editMode)
            // 시트가 떠 있는 동안 키보드가 기록을 바꿀 수 있으므로 닫힐 때 다시 읽는다
            .sheet(isPresented: $isAddSheetPresented, onDismiss: reload) { addSheet }
            .sheet(item: $detailItem) { item in
                ClipboardHistoryDetailView(text: item.text)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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
            Section {
                itemRows
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("고정 \(pinnedCount)/\(ClipboardHistoryPolicy.maxPinnedCount) · 최근 \(recentCount)/\(ClipboardHistoryPolicy.maxItemCount)")
                        .monospacedDigit()
                    limitDescription
                }
            }
        }
    }

    /// 개수 제한 규칙 안내. 목록 footer와 빈 상태에서 함께 쓴다
    var limitDescription: some View {
        Text("고정 항목은 직접 삭제할 때까지 유지되고, 최근 항목은 \(ClipboardHistoryPolicy.maxItemCount)개를 넘으면 오래된 것부터 지워집니다.")
    }

    var itemRows: some View {
        ForEach(items) { item in
            Button {
                detailItem = item
            } label: {
                row(for: item)
            }
            .buttonStyle(.plain)
            // 편집 모드에서는 탭이 행 선택으로 가도록 버튼이 터치를 가로채지 않게 한다
            .allowsHitTesting(!editMode.isEditing)
            .swipeActions(edge: .leading) {
                if item.isPinned || canPin {
                    Button {
                        togglePins([item])
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

    func row(for item: ClipboardHistoryItem) -> some View {
        HStack {
            Text(item.text)
                .lineLimit(2)
            Spacer()
            if item.isPinned {
                Image(systemName: "pin.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !items.isEmpty {
                Button(editMode.isEditing ? "완료" : "편집") {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                    selection.removeAll()
                }
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
            Button(isAllSelected ? "선택 해제" : "전체 선택") {
                selection = isAllSelected ? [] : Set(items.map(\.text))
            }
            Spacer()
            Button {
                togglePins(pinTargets)
            } label: {
                Text(isUnpinningSelection ? "\(pinTargets.count)개 고정 해제" : "\(pinTargets.count)개 고정")
                    .monospacedDigit()
            }
            .disabled(!canPinTargets)
            Button(role: .destructive) {
                remove(selectedItems)
            } label: {
                Text("\(selection.count)개 삭제")
                    .monospacedDigit()
            }
            .disabled(selection.isEmpty)
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
        // 앱 활성화 알림과 순서가 보장되지 않으므로 화면에서도 먼저 동기화한다. changeCount가 같으면 즉시 반환한다
        if let store, UserDefaultsManager.shared.isClipboardHistoryEnabled {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: store)
        }
        // SwiftUI가 id(텍스트) 차이로 행 삽입·삭제·이동을 애니메이션한다
        withAnimation {
            items = store?.load() ?? []
        }
        selection = selection.intersection(items.map(\.text))
        if items.isEmpty { editMode = .inactive }
    }

    /// 인덱스는 파일 순서 기준이므로 조작 직전에 다시 읽어 키보드가 바꾼 내용과 어긋나지 않게 한다.
    /// 토글할 때마다 정렬이 바뀌므로 매번 다시 읽은 목록에서 인덱스를 찾는다
    func togglePins(_ toggling: [ClipboardHistoryItem]) {
        guard let store else { return }
        reload()
        for item in toggling {
            guard let index = store.load().firstIndex(where: { $0.text == item.text }) else { continue }
            store.togglePin(at: index)
        }
        reload()
    }

    func remove(_ removing: [ClipboardHistoryItem]) {
        reload()
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

/// 항목의 원문 전체를 하프 시트에서 스크롤로 보여주는 화면. 위로 밀어 올리면 전체 높이가 된다
private struct ClipboardHistoryDetailView: View {
    let text: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("원문")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIPasteboard.general.string = text
                    } label: {
                        Label("복사", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ClipboardHistorySettingsView()
}
