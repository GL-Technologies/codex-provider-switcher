import SwiftUI

extension Notification.Name {
    static let addProviderRequested = Notification.Name("CodexProviderSwitcher.addProvider")
    static let editSelectedProviderRequested = Notification.Name("CodexProviderSwitcher.editSelectedProvider")
    static let duplicateSelectedProviderRequested = Notification.Name("CodexProviderSwitcher.duplicateSelectedProvider")
    static let deleteSelectedProviderRequested = Notification.Name("CodexProviderSwitcher.deleteSelectedProvider")
}

struct MainView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: SidebarSelection = .openAI
    @State private var isAdding = false
    @State private var editingProfile: ProviderProfile?
    @State private var deleteTarget: ProviderProfile?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                onAdd: { isAdding = true },
                onEdit: edit,
                onDuplicate: duplicate,
                onDelete: requestDelete
            )
            .navigationSplitViewColumnWidth(min: 230, ideal: 258, max: 300)
        } detail: {
            detail
        }
        .frame(minWidth: 980, idealWidth: 1120, minHeight: 650, idealHeight: 720)
        .sheet(isPresented: $isAdding) {
            ProviderEditorView(profile: nil)
                .environmentObject(store)
        }
        .sheet(item: $editingProfile) { profile in
            ProviderEditorView(profile: profile)
                .environmentObject(store)
        }
        .sheet(isPresented: $store.shouldShowAccessSetup) {
            AccessSetupView()
                .environmentObject(store)
                .interactiveDismissDisabled(!store.preferences.accessSetupCompleted)
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
                if selection == .provider(profile.id) {
                    selection = .openAI
                }
                deleteTarget = nil
            }
            Button(L10n.text("action.cancel"), role: .cancel) { deleteTarget = nil }
        } message: { _ in
            Text(L10n.text("delete.message"))
        }
        .onAppear {
            syncSelectionToActiveProfile()
            syncCommandSelection()
        }
        .onChange(of: selection) { _ in
            syncCommandSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addProviderRequested)) { _ in
            isAdding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .editSelectedProviderRequested)) { _ in
            if let profile = selectedProfile { edit(profile) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .duplicateSelectedProviderRequested)) { _ in
            if let profile = selectedProfile { duplicate(profile) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedProviderRequested)) { _ in
            if let profile = selectedProfile { requestDelete(profile) }
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
                    onEdit: { edit(profile) }
                )
                .environmentObject(store)
            } else {
                AppEmptyState(
                    systemImage: "network.slash",
                    title: L10n.text("provider.not_found")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppDesign.pageBackground)
            }
        }
    }

    private var selectedProfile: ProviderProfile? {
        guard case .provider(let id) = selection else { return nil }
        return store.profile(id: id)
    }

    private func edit(_ profile: ProviderProfile) {
        selection = .provider(profile.id)
        editingProfile = profile
    }

    private func duplicate(_ profile: ProviderProfile) {
        guard let copy = store.duplicate(profile) else { return }
        selection = .provider(copy.id)
    }

    private func requestDelete(_ profile: ProviderProfile) {
        selection = .provider(profile.id)
        deleteTarget = profile
    }

    private func syncSelectionToActiveProfile() {
        if let id = store.activeProfileID, store.profile(id: id) != nil, !store.isOpenAIActive {
            selection = .provider(id)
        } else {
            selection = .openAI
        }
    }

    private func syncCommandSelection() {
        if case .provider(let id) = selection {
            store.commandProfileID = id
        } else {
            store.commandProfileID = nil
        }
    }
}
