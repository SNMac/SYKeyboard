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

    /// 저장 순서 그대로(고정 최신순 → 미고정 최신순). 텍스트는 정책상 중복이 없어 id로 쓴다.
    /// 화면 전환 중 빈 상태와 편집 버튼 없는 툴바가 먼저 보이지 않도록 첫 렌더링 전에 읽는다
    @State private var items: [ClipboardHistoryItem]
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive
    @State private var isAddSheetPresented = false
    @State private var newText = ""
    /// 원문 시트에 표시할 항목. 시트 안에서 내용을 편집하면 바뀌므로 identity가 아니라 표시 여부로 시트를 연다
    @State private var detailItem: ClipboardHistoryItem?
    /// 고정 항목이 포함돼 확인 알림을 기다리는 삭제 대상
    @State private var pendingDeletion: [ClipboardHistoryItem]?

    // MARK: - Initializer

    init() {
        _items = State(initialValue: store?.load() ?? [])
    }

    private var canPin: Bool { ClipboardHistoryPolicy.canPin(items) }
    private var pinnedCount: Int { items.filter(\.isPinned).count }
    private var recentCount: Int { items.count - pinnedCount }
    private var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }
    private var selectedItems: [ClipboardHistoryItem] { items.filter { selection.contains($0.text) } }
    private var pinBatch: ClipboardHistoryPolicy.PinBatch {
        ClipboardHistoryPolicy.pinBatch(selectedTexts: selection, in: items)
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
            // 편집 모드에서 선택이 있으면 제목이 선택 수를 보여준다
            .navigationTitle(
                editMode.isEditing && !selection.isEmpty
                ? Text("\(selection.count)개 선택")
                : Text("클립보드 기록")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            // iOS 16은 bottomBar 항목을 나중에 추가하면 바가 안 뜨므로 항목은 두고 표시만 토글한다
            .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
            // 편집 버튼과 List가 같은 편집 상태를 보도록 toolbar 바깥에 둔다
            .environment(\.editMode, $editMode)
            // 시트가 떠 있는 동안 키보드가 기록을 바꿀 수 있으므로 닫힐 때 다시 읽는다
            .sheet(isPresented: $isAddSheetPresented, onDismiss: synchronizeAndReload) { addSheet }
            .sheet(isPresented: isDetailPresented) {
                if let item = detailItem {
                    ClipboardHistoryDetailView(
                        item: item,
                        canSave: { ClipboardHistoryPolicy.replacingText(item.text, with: $0, in: items) != nil },
                        onSave: { replaceText(of: item, with: $0) }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert(
                Text("고정 항목 \(pendingDeletion?.filter(\.isPinned).count ?? 0)개를 삭제할까요?"),
                isPresented: isDeletionAlertPresented,
                presenting: pendingDeletion
            ) { removing in
                Button("삭제", role: .destructive) { remove(removing) }
                Button("취소", role: .cancel) {}
            } message: { _ in
                Text("삭제한 고정 항목은 복구할 수 없습니다.")
            }
            .onAppear(perform: synchronizeAndReload)
            .onChange(of: scenePhase) { phase in
                if phase == .active { synchronizeAndReload() }
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
                        togglePins(selectedTexts: [item.text])
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
                    requestRemove([item])
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
            Button {
                newText = ""
                isAddSheetPresented = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .disabled(!canPin)
            if !items.isEmpty {
                Button {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                    selection.removeAll()
                } label: {
                    // 두 문구의 폭이 달라 버튼 위치가 흔들리지 않도록 넓은 쪽으로 폭을 고정한다
                    ZStack {
                        Text("편집").hidden()
                        Text("완료").fontWeight(.semibold).hidden()
                        Text(editMode.isEditing ? "완료" : "편집")
                            .fontWeight(editMode.isEditing ? .semibold : .regular)
                    }
                }
            }
        }
        // 툴바의 Label은 아이콘만 보이고 제목은 접근성에 쓰인다. 개수는 제목의 "n개 선택"이 보여준다
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                selection = isAllSelected ? [] : Set(items.map(\.text))
            } label: {
                Label(
                    isAllSelected ? "선택 해제" : "전체 선택",
                    systemImage: isAllSelected ? "checklist.unchecked" : "checklist.checked"
                )
            }
            Spacer()
            Button {
                togglePins(selectedTexts: selection)
            } label: {
                Label(
                    pinBatch.isUnpinning ? "\(pinBatch.targets.count)개 고정 해제" : "\(pinBatch.targets.count)개 고정",
                    systemImage: pinBatch.isUnpinning ? "pin.slash" : "pin"
                )
            }
            .disabled(!pinBatch.isAllowed)
            Button(role: .destructive) {
                requestRemove(selectedItems)
            } label: {
                Label("\(selection.count)개 삭제", systemImage: "trash")
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

    var isDetailPresented: Binding<Bool> {
        Binding(get: { detailItem != nil }, set: { if !$0 { detailItem = nil } })
    }

    var isDeletionAlertPresented: Binding<Bool> {
        Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    var canSaveNewItem: Bool {
        !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && newText.count <= ClipboardHistoryPolicy.maxTextLength
        && canPin
    }
}

// MARK: - Private Methods

private extension ClipboardHistorySettingsView {
    /// 화면에 들어오거나 돌아올 때. 앱 활성화 알림과 순서가 보장되지 않으므로 여기서도 동기화한다
    func synchronizeAndReload() {
        if let store, UserDefaultsManager.shared.isClipboardHistoryEnabled {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: store)
        }
        reload()
    }

    /// 파일을 다시 읽는다. 조작 경로에서는 동기화하지 않아 새 항목이 끼어들며 대상이 밀려나지 않게 한다
    func reload() {
        // SwiftUI가 id(텍스트) 차이로 행 삽입·삭제·이동을 애니메이션한다
        withAnimation {
            items = store?.load() ?? []
        }
        selection = selection.intersection(items.map(\.text))
        if items.isEmpty { editMode = .inactive }
    }

    /// 저장소가 파일을 다시 읽어 판단하므로 키보드가 그사이 바꾼 내용과 어긋나지 않는다
    func togglePins(selectedTexts: Set<String>) {
        store?.togglePins(selectedTexts: selectedTexts)
        reload()
    }

    /// 인덱스는 파일 순서 기준이므로 조작 직전에 다시 읽어 키보드가 바꾼 내용과 어긋나지 않게 한다
    /// 고정 항목이 섞여 있으면 알림으로 확인받고, 아니면 바로 지운다
    func requestRemove(_ removing: [ClipboardHistoryItem]) {
        if removing.contains(where: \.isPinned) {
            pendingDeletion = removing
        } else {
            remove(removing)
        }
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

    /// 원문 시트에서 편집한 내용을 저장하고, 시트가 새 내용을 보이도록 표시 항목을 바꾼다
    func replaceText(of item: ClipboardHistoryItem, with newText: String) {
        store?.replaceText(item.text, with: newText)
        reload()
        detailItem = items.first { $0.text == newText } ?? detailItem
    }

    func saveNewItem() {
        store?.recordPinned(newText)
        isAddSheetPresented = false
        reload()
    }
}

// MARK: - Detail

/// 항목의 원문 전체를 하프 시트에서 스크롤로 보여주는 화면. 위로 밀어 올리면 전체 높이가 된다.
/// "편집"을 누르면 같은 시트 안에서 내용을 고쳐 저장한다. 키보드 패널에는 편집이 없다
private struct ClipboardHistoryDetailView: View {
    let item: ClipboardHistoryItem
    /// 정책상 저장할 수 있는 내용인지(빈 값·길이·중복·원문과 같음)
    let canSave: (String) -> Bool
    let onSave: (String) -> Void

    @Environment(\.openURL) private var openURL
    @State private var isEditing = false
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    TextEditor(text: $draft)
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        Text(item.text)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(isEditing ? "원문 편집" : "원문")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            onSave(draft)
                            isEditing = false
                        }
                        .disabled(!canSave(draft))
                    }
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ShareLink(item: item.text) {
                            Label("공유", systemImage: "square.and.arrow.up")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if let url = ClipboardHistoryPolicy.openableURL(in: item.text) {
                            Button {
                                openURL(url)
                            } label: {
                                Label("브라우저에서 열기", systemImage: "safari")
                            }
                        }
                        Button {
                            UIPasteboard.general.string = item.text
                        } label: {
                            Label("복사", systemImage: "doc.on.doc")
                        }
                        Button {
                            draft = item.text
                            isEditing = true
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }
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
