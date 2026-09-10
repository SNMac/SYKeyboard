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

    /// 이미지 제약 안내는 "이미지도 기록"이 켜져 있을 때만 보인다
    @AppStorage(UserDefaultsKeys.isClipboardImageHistoryEnabled, store: UserDefaultsManager.shared.storage)
    private var isClipboardImageHistoryEnabled = DefaultValues.isClipboardImageHistoryEnabled

    /// 저장 순서 그대로(고정 최신순 → 미고정 최신순). id는 정책상 중복이 없다.
    /// 화면 전환 중 빈 상태와 편집 버튼 없는 툴바가 먼저 보이지 않도록 첫 렌더링 전에 읽는다
    @State private var items: [ClipboardHistoryItem]
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive
    @State private var isAddSheetPresented = false
    @State private var newText = ""
    /// 원문 시트에 표시할 항목. 시트 안에서 내용을 편집하면 바뀌므로 identity가 아니라 표시 여부로 시트를 연다
    @State private var detailItem: ClipboardHistoryItem?
    /// 고정 항목이 포함돼 확인 알림을 기다리는 삭제 대상
    @State private var pendingDeletion: PendingDeletion?

    /// 확인 시트를 어디에 붙일지. 스와이프 삭제는 그 행에서, 편집 모드 삭제는 하단 바 삭제 버튼에서 뜬다
    fileprivate enum DeletionSource: Equatable {
        case row(String)
        case toolbar
    }

    fileprivate struct PendingDeletion {
        let items: [ClipboardHistoryItem]
        let source: DeletionSource
    }
    /// 시트 문구에 쓰는 개수. 시트가 닫히는 동안 `pendingDeletion`이 먼저 비워져도 제목이 "0개"로 바뀌지 않게 따로 둔다
    @State private var deletionCounts = (pinned: 0, total: 0)

    // MARK: - Initializer

    init() {
        _items = State(initialValue: store?.load() ?? [])
    }

    private var canPin: Bool { ClipboardHistoryPolicy.canPin(items) }
    private var pinnedCount: Int { items.filter(\.isPinned).count }
    private var recentCount: Int { items.count - pinnedCount }
    private var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }
    private var selectedItems: [ClipboardHistoryItem] { items.filter { selection.contains($0.id) } }
    private var pinBatch: ClipboardHistoryPolicy.PinBatch {
        ClipboardHistoryPolicy.pinBatch(selectedIDs: selection, in: items)
    }

    // MARK: - Content

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Text("복사한 텍스트나 이미지가 여기에 표시됩니다.")
                        limitDescription
                        if isClipboardImageHistoryEnabled { imageLimitDescription }
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
                        imageStore: store?.imageStore,
                        canPin: canPin,
                        // 저장 가능 여부만 보므로 시각은 결과에 영향이 없다. body마다 Date()를 만들지 않도록 고정값을 넘긴다
                        canSave: { newText in item.text.flatMap { ClipboardHistoryPolicy.replacingText($0, with: newText, in: items, now: .distantPast) } != nil },
                        onTogglePin: { togglePinFromDetail(item) },
                        onCopy: { copyFromDetail(item) },
                        onSave: { replaceText(of: item, with: $0) }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            // 스와이프·편집 모드 삭제는 사용자가 의도한 동작이므로 HIG대로 알림이 아니라 action sheet로 확인한다. 취소는 시스템이 붙인다
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
                    if isClipboardImageHistoryEnabled { imageLimitDescription }
                }
            }
        }
    }

    /// 개수 제한 규칙 안내. 목록 footer와 빈 상태에서 함께 쓴다
    var limitDescription: some View {
        Text("고정 항목은 직접 삭제할 때까지 유지되고, 최근 항목은 \(ClipboardHistoryPolicy.maxItemCount)개를 넘으면 오래된 것부터 지워집니다.")
    }

    /// 이미지 저장 한도와 토글 OFF 규칙 안내. 목록 최하단(footer)과 빈 상태에서 "이미지도 기록"이 켜져 있을 때만 보인다
    var imageLimitDescription: some View {
        Text("이미지는 한 장에 \(ClipboardImagePolicy.maxByteSize / (1_024 * 1_024)) MB · \(ClipboardImagePolicy.maxPixelCount / 1_000_000)메가픽셀까지 저장합니다. '이미지도 기록'을 끄면 새로 복사한 이미지는 저장하지 않으며, 이미 저장된 이미지는 여기서 삭제할 수 있습니다.")
    }

    var itemRows: some View {
        ForEach(items) { item in
            // Button으로 두면 시트를 띄우는 탭 뒤에 눌린 표시가 남는 일이 있어 탭 제스처만 받는다
            row(for: item)
                .onTapGesture { detailItem = item }
                // Button이 아니므로 보조 기술에 탭 가능함을 알린다
                .accessibilityAddTraits(.isButton)
                // 편집 모드에서는 탭이 행 선택으로 가도록 제스처가 터치를 가로채지 않게 한다
                .allowsHitTesting(!editMode.isEditing)
                .swipeActions(edge: .leading) {
                    if item.isPinned || canPin {
                        Button {
                            togglePins(selectedIDs: [item.id])
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
                    // destructive role은 누르는 순간 행 제거 애니메이션을 시작해 행에 붙인 확인 시트를 닫아 버린다.
                    // 삭제 여부는 확인 시트가 결정하므로 role 없이 색만 준다
                    Button {
                        requestRemove([item], source: .row(item.id))
                    } label: {
                        Label("삭제", systemImage: "trash.fill")
                    }
                    .tint(.red)
                }
                // 스와이프 삭제의 확인 시트는 그 행에 붙여, 지원하는 OS에서는 행 근처에서 뜬다.
                // 행마다 하나씩 설치되지만 한 번에 하나만 열리고, 표시 시점에 조건부로 붙이면 SwiftUI가 띄우지 못한다
                .deletionConfirmation(self, source: .row(item.id))
        }
    }

    func row(for item: ClipboardHistoryItem) -> some View {
        HStack {
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(2)
            case .image(let reference):
                thumbnail(for: reference)
                VStack(alignment: .leading, spacing: 2) {
                    Text("이미지")
                    Text(reference.sizeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.isPinned {
                Image(systemName: "pin.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    /// 썸네일 파일만 읽는다. 앱 프로세스는 메모리 여유가 있어 캐시 없이 동기 로드한다
    @ViewBuilder
    func thumbnail(for reference: ClipboardImageReference) -> some View {
        if let url = store?.imageStore?.thumbnailURL(for: reference),
           let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: "photo")
                .frame(width: 44, height: 44)
        }
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
                        Text("선택").hidden()
                        Text("완료").fontWeight(.semibold).hidden()
                        Text(editMode.isEditing ? "완료" : "선택")
                            .fontWeight(editMode.isEditing ? .semibold : .regular)
                    }
                }
            }
        }
        // 툴바의 Label은 아이콘만 보이고 제목은 접근성에 쓰인다. 개수는 제목의 "n개 선택"이 보여준다
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                selection = isAllSelected ? [] : Set(items.map(\.id))
            } label: {
                Label(
                    isAllSelected ? "선택 해제" : "전체 선택",
                    systemImage: isAllSelected ? "checklist.unchecked" : "checklist.checked"
                )
            }
            Spacer()
            Button {
                togglePins(selectedIDs: selection)
            } label: {
                Label(
                    pinBatch.isUnpinning ? "\(pinBatch.targets.count)개 고정 해제" : "\(pinBatch.targets.count)개 고정",
                    systemImage: pinBatch.isUnpinning ? "pin.slash" : "pin"
                )
            }
            .disabled(!pinBatch.isAllowed)
            Button(role: .destructive) {
                requestRemove(selectedItems, source: .toolbar)
            } label: {
                Label("\(selection.count)개 삭제", systemImage: "trash")
            }
            .disabled(selection.isEmpty)
            // 편집 모드 삭제의 확인 시트는 삭제 버튼에 붙인다
            .deletionConfirmation(self, source: .toolbar)
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

    var pendingDeletionItems: [ClipboardHistoryItem]? { pendingDeletion?.items }

    /// 전부 고정이면 고정 항목 개수를, 미고정이 섞였으면 전체 개수를 제목에 쓰고 고정 개수는 설명에 쓴다
    var deletionTitle: Text {
        deletionCounts.pinned == deletionCounts.total
        ? Text("고정 항목 \(deletionCounts.pinned)개를 삭제할까요?")
        : Text("항목 \(deletionCounts.total)개를 삭제할까요?")
    }

    var deletionMessage: Text {
        deletionCounts.pinned == deletionCounts.total
        ? Text("삭제한 고정 항목은 복구할 수 없습니다.")
        : Text("고정 항목 \(deletionCounts.pinned)개가 포함되어 있습니다. 삭제한 고정 항목은 복구할 수 없습니다.")
    }

    var isDetailPresented: Binding<Bool> {
        Binding(get: { detailItem != nil }, set: { if !$0 { detailItem = nil } })
    }

    /// 해당 출처의 확인 시트 표시 여부. 닫히면 대기 중인 삭제를 버린다
    func isDeletionPresented(for source: DeletionSource) -> Binding<Bool> {
        Binding(
            get: { pendingDeletion?.source == source },
            set: { isPresented in
                if !isPresented, pendingDeletion?.source == source { pendingDeletion = nil }
            }
        )
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
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: store, onImageRecorded: reload)
        }
        reload()
    }

    /// 파일을 다시 읽는다. 조작 경로에서는 동기화하지 않아 새 항목이 끼어들며 대상이 밀려나지 않게 한다
    func reload() {
        // SwiftUI가 id(텍스트) 차이로 행 삽입·삭제·이동을 애니메이션한다
        withAnimation {
            items = store?.load() ?? []
        }
        selection = selection.intersection(items.map(\.id))
        if items.isEmpty { editMode = .inactive }
        // 시트를 띄운 행이 다시 읽는 사이 사라졌으면 대기 중인 삭제도 버린다. 같은 id가 돌아올 때 시트가 저절로 뜨지 않게 한다
        if case .row(let id)? = pendingDeletion?.source, !items.contains(where: { $0.id == id }) {
            pendingDeletion = nil
        }
    }

    /// 저장소가 파일을 다시 읽어 판단하므로 키보드가 그사이 바꾼 내용과 어긋나지 않는다
    func togglePins(selectedIDs: Set<String>) {
        store?.togglePins(selectedIDs: selectedIDs)
        reload()
    }

    /// 고정 항목이 섞여 있으면 알림으로 확인받고, 아니면 바로 지운다
    func requestRemove(_ removing: [ClipboardHistoryItem], source: DeletionSource) {
        if removing.contains(where: \.isPinned) {
            deletionCounts = (removing.filter(\.isPinned).count, removing.count)
            pendingDeletion = PendingDeletion(items: removing, source: source)
        } else {
            remove(removing)
        }
    }

    /// 저장소가 id로 지우므로 파일을 미리 다시 읽을 필요가 없다
    func remove(_ removing: [ClipboardHistoryItem]) {
        guard !removing.isEmpty else { return }
        store?.remove(ids: Set(removing.map(\.id)))
        reload()
    }

    /// 원문 시트에서 편집한 내용을 저장하고, 시트가 새 내용을 보이도록 표시 항목을 바꾼다
    func replaceText(of item: ClipboardHistoryItem, with newText: String) {
        guard let oldText = item.text else { return }
        store?.replaceText(oldText, with: newText)
        reload()
        refreshDetailItem(id: newText)
    }

    func togglePinFromDetail(_ item: ClipboardHistoryItem) {
        store?.togglePins(selectedIDs: [item.id])
        reload()
        refreshDetailItem(id: item.id)
    }

    /// 복사한 항목을 최근 복사한 것처럼 목록 맨 위로 올린다. 동기화가 방금 쓴 pasteboard를 다시 읽지 않도록 changeCount를 맞춘다.
    /// 이미지는 원본 바이트를 그대로 pasteboard에 놓는다. 파일이 없으면 아무것도 하지 않는다
    func copyFromDetail(_ item: ClipboardHistoryItem) {
        let pasteboard = UIPasteboard.general
        switch item.content {
        case .text(let text):
            pasteboard.string = text
        case .image(let reference):
            guard let url = store?.imageStore?.originalURL(for: reference),
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
            pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        }
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = pasteboard.changeCount
        store?.record(item.content)
        reload()
        refreshDetailItem(id: item.id)
    }

    /// 시트가 열린 채로 저장소가 바뀌면 표시 항목을 새 값으로 바꾼다. 항목이 사라졌으면 그대로 둔다
    func refreshDetailItem(id: String) {
        detailItem = items.first { $0.id == id } ?? detailItem
    }

    func saveNewItem() {
        store?.recordPinned(newText)
        isAddSheetPresented = false
        reload()
    }
}

// MARK: - Deletion Confirmation

private extension View {
    /// 고정 항목이 섞인 삭제의 확인 시트. `source`에 해당하는 요청일 때만 이 뷰에서 뜬다
    func deletionConfirmation(
        _ screen: ClipboardHistorySettingsView,
        source: ClipboardHistorySettingsView.DeletionSource
    ) -> some View {
        confirmationDialog(
            screen.deletionTitle,
            isPresented: screen.isDeletionPresented(for: source),
            titleVisibility: .visible,
            presenting: screen.pendingDeletionItems
        ) { removing in
            Button("삭제", role: .destructive) { screen.remove(removing) }
        } message: { _ in
            screen.deletionMessage
        }
    }
}

// MARK: - Detail

/// 항목의 원문 전체를 하프 시트에서 스크롤로 보여주는 화면. 위로 밀어 올리면 전체 높이가 된다.
/// "편집"을 누르면 같은 시트 안에서 내용을 고쳐 저장한다. 키보드 패널에는 편집이 없다
private struct ClipboardHistoryDetailView: View {
    let item: ClipboardHistoryItem
    let imageStore: ClipboardImageStore?
    /// 고정 한도에 여유가 있는지. 없으면 미고정 항목의 고정 버튼을 숨긴다
    let canPin: Bool
    /// 정책상 저장할 수 있는 내용인지(빈 값·길이·중복·원문과 같음)
    let canSave: (String) -> Bool
    let onTogglePin: () -> Void
    let onCopy: () -> Void
    let onSave: (String) -> Void

    @State private var isEditing = false
    @State private var draft = ""

    private var text: String { item.text ?? "" }

    /// 원본을 시트 폭에 맞는 크기까지만 디코드한다
    private var previewImage: UIImage? {
        guard let reference = item.image else { return nil }
        return imageStore?
            .previewImage(for: reference, maxPixelSize: ClipboardImagePolicy.appPreviewMaxPixelSize)
            .map { UIImage(cgImage: $0) }
    }

    private var linkStyledText: AttributedString {
        var attributed = AttributedString(text)
        if let url = ClipboardHistoryPolicy.openableURL(in: text) {
            attributed.link = url
            attributed.underlineStyle = .single
        }
        return attributed
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    TextEditor(text: $draft)
                        // 시트 배경 위에 흰 사각형이 뜨지 않도록 편집기 배경을 비운다
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                } else if item.image != nil {
                    ScrollView {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                } else {
                    ScrollView {
                        // 텍스트 전체가 URL이면 일반 링크처럼 파란 밑줄로 보이고 탭하면 브라우저로 연다
                        Text(linkStyledText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(isEditing ? "원문 편집" : (item.image != nil ? "이미지" : "원문"))
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
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if item.isPinned || canPin {
                            Button(action: onTogglePin) {
                                // 현재 상태를 보여준다: 고정이면 채운 핀, 아니면 빈 핀
                                Label(
                                    item.isPinned ? "고정 해제" : "고정",
                                    systemImage: item.isPinned ? "pin.fill" : "pin"
                                )
                            }
                        }
                        if let reference = item.image, let url = imageStore?.originalURL(for: reference) {
                            ShareLink(item: url) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            ShareLink(item: text) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: onCopy) {
                            Label("복사", systemImage: "doc.on.doc")
                        }
                        // 이미지는 편집하지 않는다
                        if item.image == nil {
                            Button {
                                draft = text
                                isEditing = true
                            } label: {
                                Label("편집", systemImage: "pencil.line")
                            }
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
