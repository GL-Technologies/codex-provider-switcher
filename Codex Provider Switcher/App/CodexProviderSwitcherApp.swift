import SwiftUI

@main
struct CodexProviderSwitcherApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup(L10n.text("app.name"), id: "main") {
            MainView()
                .environmentObject(store)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.text("action.add_provider")) {
                    NotificationCenter.default.post(name: .addProviderRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }

            CommandMenu(L10n.text("details.provider")) {
                Button {
                    NotificationCenter.default.post(name: .editSelectedProviderRequested, object: nil)
                } label: {
                    Label(L10n.text("action.edit"), systemImage: "pencil")
                }
                .disabled(store.commandProfile == nil)

                Button {
                    NotificationCenter.default.post(name: .duplicateSelectedProviderRequested, object: nil)
                } label: {
                    Label(L10n.text("action.duplicate"), systemImage: "plus.square.on.square")
                }
                .disabled(store.commandProfile == nil)

                Divider()

                Button(role: .destructive) {
                    NotificationCenter.default.post(name: .deleteSelectedProviderRequested, object: nil)
                } label: {
                    Label(L10n.text("action.delete"), systemImage: "trash")
                }
                .disabled(store.commandProfile == nil)
            }

            CommandGroup(after: .sidebar) {
                Button(L10n.text("action.refresh")) { store.refresh() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
        } label: {
            Image(systemName: store.bridgedProfileID != nil ? "arrow.triangle.branch" : "arrow.triangle.2.circlepath")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
