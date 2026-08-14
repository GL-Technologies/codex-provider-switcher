import SwiftUI

extension Notification.Name {
    static let addProviderRequested = Notification.Name("CodexProviderSwitcher.addProvider")
}

struct MainView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: SidebarSelection = .openAI
    @State private var isAdding = false
    @State private var editingProfile: ProviderProfile?
    @State private var deleteTarget: ProviderProfile?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 210, ideal: 245, max: 300)
        } detail: {
            detail
        }
        .frame(minWidth: 820, minHeight: 540)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAdding = true
                } label: {
                    Label(L10n.text("action.add_provider"), systemImage: "plus")
                }
                .help(L10n.text("action.add_provider"))
            }
        }
        .sheet(isPresented: $isAdding) {
            ProviderEditorView(profile: nil)
                .environmentObject(store)
        }
        .sheet(item: $editingProfile) { profile in
            ProviderEditorView(profile: profile)
                .environmentObject(store)
        }
        .alert(item: $store.notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text(L10n.text("action.ok"))))
        }
        .confirmationDialog(
            L10n.text("restart.title"),
            isPresented: $store.shouldOfferRestart,
            titleVisibility: .visible
        ) {
            Button(L10n.text("restart.now")) { store.restartCodex() }
            Button(L10n.text("restart.later"), role: .cancel) {}
        } message: {
            Text(L10n.text("restart.message"))
        }
        .confirmationDialog(
            L10n.text("delete.title"),
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: deleteTarget
        ) { profile in
            Button(L10n.text("action.delete"), role: .destructive) {
                store.delete(profile)
                selection = .openAI
                deleteTarget = nil
            }
            Button(L10n.text("action.cancel"), role: .cancel) { deleteTarget = nil }
        } message: { _ in
            Text(L10n.text("delete.message"))
        }
        .onAppear {
            syncSelectionToActiveProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addProviderRequested)) { _ in
            isAdding = true
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .openAI:
            OpenAIDetailView().environmentObject(store)
        case .provider(let id):
            if let profile = store.profile(id: id) {
                ProviderDetailView(
                    profile: profile,
                    onEdit: { editingProfile = profile },
                    onDuplicate: {
                        if let copy = store.duplicate(profile) {
                            selection = .provider(copy.id)
                            editingProfile = copy
                        }
                    },
                    onDelete: { deleteTarget = profile }
                )
                .environmentObject(store)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "network.slash").font(.title)
                    Text(L10n.text("provider.not_found"))
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func syncSelectionToActiveProfile() {
        if let id = store.activeProfileID, store.profile(id: id) != nil, !store.isOpenAIActive {
            selection = .provider(id)
        } else {
            selection = .openAI
        }
    }
}
