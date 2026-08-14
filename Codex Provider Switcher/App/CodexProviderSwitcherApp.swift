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
